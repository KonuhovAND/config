#!/bin/bash
set -euo pipefail

echo "=== 1. Подготовка хоста Silverblue ==="
sudo umount /mnt/data 2>/dev/null || true

echo "=== 2. Установка Flatpak-приложений ==="
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
  com.spotify.Client \
  dev.vencord.Vesktop \
  org.telegram.desktop \
  md.obsidian.Obsidian \
  com.usebottles.bottles \
  com.jeffser.Alpaca \
  io.dbeaver.DBeaverCommunity

echo "=== 3. Установка базовых утилит на хост (rpm-ostree) ==="
# distrobox и podman в Silverblue часто уже есть, но для верности ставим
sudo rpm-ostree install alacritty distrobox syncthing || true

echo "=== 4. Настройка умного питания Ryzen 7 7730U ==="
# КРИТИЧНО: Подгружаем модуль MSR, иначе ryzenadj не сможет управлять ваттами!
echo "msr" | sudo tee /etc/modules-load.d/msr.conf > /dev/null
sudo modprobe msr

sudo wget -q https://copr.fedorainfracloud.org/coprs/shdwchn10/ryzenadj/repo/fedora-$(rpm -E %fedora)/shdwchn10-ryzenadj-fedora-$(rpm -E %fedora).repo -O /etc/yum.repos.d/ryzenadj.repo
sudo rpm-ostree install ryzenadj || true

sudo tee /usr/local/bin/ryzen-power.sh > /dev/null <<'EOF'
#!/bin/bash
# Ищем любой контроллер сети (AC, ACAD, ADP0...)
# Если не нашли, считаем что от сети (1).
STATUS=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -n 1 || echo 1)

if [ "$STATUS" -eq 0 ]; then
    # 🔋 БАТАРЕЯ: Номинальный TDP (15W). Холодно и тихо.
    /usr/bin/ryzenadj --stapm-limit=15000 --fast-limit=15000 --slow-limit=15000 --tctl-temp=85
else
    # 🔌 СЕТЬ: Буст до 25W. Выжимаем мощь для компиляции и ML.
    /usr/bin/ryzenadj --stapm-limit=25000 --fast-limit=28000 --slow-limit=25000 --tctl-temp=90
fi
EOF
sudo chmod +x /usr/local/bin/ryzen-power.sh

sudo tee /etc/udev/rules.d/99-ryzen-power.rules > /dev/null <<'EOF'
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="/usr/local/bin/ryzen-power.sh"
EOF

sudo tee /etc/systemd/system/ryzen-power.service > /dev/null <<'EOF'
[Unit]
Description=Ryzen Dynamic Power Management
After=multi-user.target
[Service]
Type=oneshot
ExecStart=/usr/local/bin/ryzen-power.sh
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ryzen-power.service
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "=== 5. Настройка диска (fstab БЕЗ КИРПИЧА) ==="
sudo mkdir -p /mnt/data
if ! grep -q "F4C0-4BAE" /etc/fstab; then
  sudo tee -a /etc/fstab > /dev/null <<'EOF'
UUID=F4C0-4BAE  /mnt/data  exfat  defaults,uid=1000,gid=1000,rw,umask=000,nofail,x-systemd.automount  0  2
EOF
fi

echo "=== 6. Создание Distrobox контейнера ==="
distrobox create --name fedora-dev --image registry.fedoraproject.org/fedora:latest --yes

echo "=============================================================================="
echo "ХОСТ НАСТРОЕН! ПЕРЕЗАГРУЗИ СИСТЕМУ."
echo "После ребута зайди в контейнер: distrobox enter fedora-dev"
echo "И запусти внутри свой toolbox.sh"
echo "=============================================================================="