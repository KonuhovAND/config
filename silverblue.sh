#!/bin/bash
set -euo pipefail
#curl -fsSL https://raw.githubusercontent.com/throneproj/Throne/dev/script/install_linux.py | sudo python3

# ==========================================
# 5. Git Identity & SSH
# ==========================================
#git config --global user.name 'KonuhovAND'
#git config --global user.email 'andreykonuhov8@gmail.com'
#ssh-keygen -t ed25519 -C "andreykonuhov8@mail.com" -N "" -f ~/.ssh/id_ed25519
#cat ~/.ssh/id_ed25519.pub
echo "=== System Check & Preparation ==="
# Убираем остановку при неудачном отмонтировании
sudo umount /mnt/data || true

# ==========================================
# 11. Throne Proxy & Git Identity
# (Препод в курсе, пропускаем)
# ==========================================

# ==========================================
# OS Setup for Fedora Silverblue (AMD Ryzen 7 7730U)
# ==========================================

echo "=== Updating Immutable System ==="
sudo rpm-ostree upgrade

# В Silverblue репозитории RPM Fusion ставятся тоже через rpm-ostree
echo "=== Enabling RPM Fusion ==="
sudo rpm-ostree install \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true

# ==========================================
# Core Utilities (Layered)
# Старайтесь минимизировать количество слоев в Silverblue!
# ==========================================
echo "=== Layering Core Tools ==="
sudo rpm-ostree install \
  git curl wget vim neovim tmux htop \
  fontconfig unzip p7zip p7zip-plugins \
  fzf zsh feh fastfetch \
  nodejs npm python3 pip \
  gcc gcc-c++ make cmake \
  syncthing alacritty lazygit qbittorrent mpv

echo "=== Installing uv ==="
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
uv python install 3.14

# ==========================================
# Terminal & CLI Configs
# ==========================================
echo "=== Configuring Neovim, Tmux, Starship ==="
git clone https://github.com/LazyVim/starter ~/.config/nvim || true
rm -rf ~/.config/nvim/.git

# Исправлена ошибка вызова файла
mkdir -p ~/.config/tmux
cat > ~/.config/tmux/tmux.conf <<'EOF'
bind '"' split-window -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"
bind 'c' new-window -c "#{pane_current_path}"
EOF

# Добавляем ваш любимый Starship
curl -sS https://starship.rs/install.sh | sh -s -- -y
echo 'eval "$(starship init bash)"' >> ~/.bashrc

# ==========================================
# Fonts
# ==========================================
echo "=== Installing JetBrains Mono Nerd Font ==="
mkdir -p ~/.local/share/fonts
cd /tmp
curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
fc-cache -f
cd ~

mkdir -p ~/.config/alacritty
cat > ~/.config/alacritty/alacritty.toml <<'EOF'
[font]
size = 13.0
[font.normal]
family = "JetBrainsMono Nerd Font"
style = "Regular"
EOF

# ==========================================
# Flatpak Setup (The Silverblue Way)
# ==========================================
echo "=== Setting up Flatpak Apps ==="
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Исправлен лишний пробел после слэша
flatpak install -y flathub \
  com.spotify.Client \
  com.discordapp.Discord \
  org.telegram.desktop \
  md.obsidian.Obsidian \
  com.usebottles.bottles \
  org.winehq.Wine \
  com.jeffser.Alpaca \
  io.dbeaver.DBeaverCommunity

# ==========================================
# Power Management (Ryzen 7 7730U)
# ==========================================
# В Silverblue лучше использовать встроенный power-profiles-daemon.
# Но если сильно хочется ryzenadj, его придется собирать или брать из COPR.
# В Silverblue COPR добавляется так:
sudo wget https://copr.fedorainfracloud.org/coprs/shdwchn10/ryzenadj/repo/fedora-$(rpm -E %fedora)/shdwchn10-ryzenadj-fedora-$(rpm -E %fedora).repo -O /etc/yum.repos.d/ryzenadj.repo
sudo rpm-ostree install ryzenadj

# Создаем службу (будет резать частоты всегда, подумайте над правилами udev!)
sudo tee /etc/systemd/system/ryzenadj.service > /dev/null <<'EOF'
[Unit]
Description=RyzenAdj Power Management (15W Limit)
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ryzenadj --stapm-limit=15000 --fast-limit=15000 --slow-limit=15000 --tctl-temp=85
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ryzenadj.service

# ==========================================
# FSTAB & Disks
# ==========================================
sudo mkdir -p /mnt/data
# Проверяем, есть ли уже запись, чтобы не дублировать
if ! grep -q "F4C0-4BAE" /etc/fstab; then
  sudo tee -a /etc/fstab > /dev/null <<'EOF'
UUID=F4C0-4BAE  /mnt/data  exfat  defaults,uid=1000,gid=1000,rw,umask=000  0  0
EOF
fi
sudo systemctl daemon-reload
sudo mount -a

# ==========================================
# Repositories & Projects
# ==========================================
echo "=== Setting up Projects ==="
mkdir -p ~/Code
cd ~/Code 

if [ ! -d "django_react_spendings" ]; then
  git clone git@github.com:KonuhovAND/django_react_spendings.git 
fi
cd django_react_spendings
uv venv 
# Исправлен флаг -r
uv pip install -r req.txt || echo "No req.txt found or install failed"

cd frontend/
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
# npm start УБРАНО, иначе скрипт зависнет здесь

cd ~/Code/
if [ ! -d "PythonML" ]; then
  git clone git@github.com:KonuhovAND/PythonML.git
fi
cd PythonML
uv venv
uv pip install -r req.txt || echo "No req.txt found"
cd ~

echo "=== DONE! REBOOT REQUIRED FOR RPM-OSTREE CHANGES ==="
