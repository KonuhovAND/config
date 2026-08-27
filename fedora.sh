#!/usr/bin/env bash
set -euo pipefail
# Fedora Setup — Ryzen 7 7730U (compact)

echo "=== Updating system ==="
sudo dnf upgrade --refresh -y

# ============ Happ Desktop (first) ============
echo "=== Installing Happ Desktop 4.1.1 ==="
if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "Error: Happ is x86_64 only. Detected: $(uname -m)"; exit 1
fi
HAPP_URL="https://github.com/Happ-proxy/happ-desktop/releases/download/4.1.1/Happ.linux.x64.rpm"
curl -fL "$HAPP_URL" -o /tmp/Happ.linux.x64.rpm
sudo dnf install -y /tmp/Happ.linux.x64.rpm
rm -f /tmp/Happ.linux.x64.rpm

# ============ GitHub CLI + account ============
echo "=== Installing GitHub CLI ==="
sudo dnf install -y gh
if ! gh auth status >/dev/null 2>&1; then
    echo "Login or register a GitHub account (choose 'Login with a web browser',")
    echo "then use 'Create an account' on the opened page if you don't have one):"
    gh auth login -p https -w
    gh auth setup-git
fi

# ============ RPM Fusion ============
echo "=== Enabling RPM Fusion ==="
sudo dnf install -y \
  "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# ============ Core packages (reduced) ============
echo "=== Installing core tools ==="
sudo dnf install -y \
  git curl neovim fontconfig unzip \
  fzf jq kitty nodejs npm python3 \
  gcc make

# ============ LazyVim ============
echo "=== Configuring Neovim ==="
if [[ ! -d "$HOME/.config/nvim" ]]; then
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
else
    echo "Neovim config exists; skipping."
fi

# ============ uv ============
echo "=== Installing uv ==="
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"
uv python install 3.14 || true

# ============ AMD graphics + gaming ============
echo "=== Configuring AMD graphics ==="
sudo dnf install -y \
  mesa-dri-drivers mesa-va-drivers-freeworld \
  mesa-vulkan-drivers vulkan-loader \
  gamemode mangohud

# ============ Applications ============
echo "=== Installing applications ==="
sudo dnf install -y qbittorrent mpv
sudo dnf copr enable -y atim/lazygit
sudo dnf install -y lazygit

# ============ Google Chrome ============
echo "=== Installing Google Chrome ==="
sudo dnf install -y fedora-workstation-repositories
sudo dnf config-manager setopt google-chrome.enabled=1
sudo dnf install -y google-chrome-stable

# ============ Fonts ============
echo "=== Installing JetBrains Mono Nerd Font ==="
sudo dnf install -y jetbrains-mono-fonts
mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"
curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o /tmp/JetBrainsMono.zip
unzip -o /tmp/JetBrainsMono.zip -d "$HOME/.local/share/fonts/JetBrainsMono"
fc-cache -f

# ============ Kitty config ============
echo "=== Configuring Kitty ==="
mkdir -p "$HOME/.config/kitty"
cat > "$HOME/.config/kitty/kitty.conf" <<'EOF'
font_family JetBrainsMono Nerd Font
bold_font JetBrainsMono Nerd Font
italic_font JetBrainsMono Nerd Font
bold_italic_font JetBrainsMono Nerd Font
font_size 13.0
enable_audio_bell no
confirm_os_window_close 0
allow_remote_control yes
map ctrl+shift+t launch --type=tab --cwd=current
map ctrl+shift+shift+t launch --type=tab --cwd=last_reported
map ctrl+shift+v launch --location=vsplit --cwd=current
map ctrl+shift+h launch --location=hsplit --cwd=current
map alt+1 goto_tab 1
map alt+2 goto_tab 2
map alt+3 goto_tab 3
map alt+4 goto_tab 4
map alt+5 goto_tab 5
map alt+6 goto_tab 6
map alt+7 goto_tab 7
map alt+8 goto_tab 8
map alt+9 goto_tab 9
map alt+0 launch --type=background $HOME/.local/bin/tabswitcher
disable_ligatures never
background_opacity 0.94
dynamic_background_opacity yes
window_padding_width 12
window_padding_height 10
hide_window_decorations yes
draw_minimal_borders yes
cursor_shape beam
cursor_beam_thickness 2.0
cursor_blink_interval 0.6
tab_bar_edge top
tab_bar_style powerline
tab_powerline_style slanted
tab_title_template "{index}: {title}"
active_tab_font_style bold
inactive_tab_font_style normal
visual_bell_duration 0.0
foreground              #CDD6F4
background              #1E1E2E
selection_foreground    #1E1E2E
selection_background    #F5E0E6
cursor                  #F5E0E6
cursor_text_color       #1E1E2E
url_color               #89B4FA
active_tab_foreground   #1E1E2E
active_tab_background   #CBA6F7
inactive_tab_foreground #A6ADC8
inactive_tab_background #313244
color0  #45475A
color1  #F38BA8
color2  #A6E3A1
color3  #F9E2AF
color4  #89B4FA
color5  #F5C2E7
color6  #94E2D5
color7  #BAC2DE
color8  #585B70
color9  #F38BA8
color10 #A6E3A1
color11 #F9E2AF
color12 #89B4FA
color13 #F5C2E7
color14 #94E2D5
color15 #A6ADC8
EOF

# ============ Kitty helpers ============
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/tabswitcher" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
for cmd in kitty jq fzf; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd not installed."; exit 1; }
done
[[ -n "${KITTY_WINDOW_ID:-}" ]] || { echo "Error: run inside Kitty."; exit 1; }
selected="$(kitty @ ls | jq -r '.[] | .tabs[] | [.id, (.title // "Untitled")] | @tsv' |
    fzf --height=40% --layout=reverse --border --prompt="Tabs> ")" || exit 0
tab_id="${selected%%$'\t'*}"
[[ -n "$tab_id" ]] && kitty @ focus-tab --match "id:$tab_id"
EOF
chmod +x "$HOME/.local/bin/tabswitcher"

for shell_rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    touch "$shell_rc"
    grep -q 'function new_tab_parent' "$shell_rc" || cat >> "$shell_rc" <<'EOF'

# Kitty helpers
new_tab() { kitty @ launch --type=tab --cwd="$PWD"; }
new_tab_parent() { kitty @ launch --type=tab --cwd="$(dirname "$PWD")"; }
alias tabswitcher="$HOME/.local/bin/tabswitcher"
EOF
done

# ============ Syncthing ============
echo "=== Installing Syncthing ==="
sudo dnf install -y syncthing
systemctl --user enable --now syncthing

# ============ Flatpak ============
echo "=== Configuring Flatpak ==="
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
  com.spotify.Client com.discordapp.Discord org.telegram.desktop \
  md.obsidian.Obsidian com.jeffser.Alpaca io.dbeaver.DBeaverCommunity

# ============ RyzenAdj ============
echo "=== Installing RyzenAdj ==="
sudo dnf copr enable -y shdwchn10/ryzenadj
sudo dnf install -y ryzenadj
RYZENADJ_BIN="$(command -v ryzenadj)"
[[ -n "$RYZENADJ_BIN" ]] || { echo "Error: ryzenadj not found."; exit 1; }

sudo tee /usr/local/sbin/ryzen-power-limit >/dev/null <<EOF
#!/usr/bin/env bash
set -euo pipefail
RYZENADJ_BIN="$RYZENADJ_BIN"
AC_STAPM=10000; AC_FAST=18000; AC_SLOW=15000
BATTERY_STAPM=8000; BATTERY_FAST=15000; BATTERY_SLOW=12000
ON_AC=0
for supply in /sys/class/power_supply/*; do
    [[ -d "\$supply" ]] || continue
    type="\$(cat "\$supply/type" 2>/dev/null || true)"
    if [[ "\$type" != "Battery" ]] && [[ "\$(cat "\$supply/online" 2>/dev/null || echo 0)" == "1" ]]; then
        ON_AC=1; break
    fi
done
if [[ "\$ON_AC" == "1" ]]; then
    MODE="AC"; STAPM="\$AC_STAPM"; FAST="\$AC_FAST"; SLOW="\$AC_SLOW"
else
    MODE="Battery"; STAPM="\$BATTERY_STAPM"; FAST="\$BATTERY_FAST"; SLOW="\$BATTERY_SLOW"
fi
echo "Applying RyzenAdj limits for \$MODE: STAPM \$((STAPM/1000))W Fast \$((FAST/1000))W Slow \$((SLOW/1000))W"
"\$RYZENADJ_BIN" -a "\$STAPM" -b "\$FAST" -c "\$SLOW"
EOF
sudo chmod 755 /usr/local/sbin/ryzen-power-limit

sudo tee /etc/systemd/system/ryzen-power-limit.service >/dev/null <<'EOF'
[Unit]
Description=Set RyzenAdj power limits based on AC or battery state
After=multi-user.target
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/ryzen-power-limit
EOF

sudo tee /etc/udev/rules.d/99-ryzen-power-limit.rules >/dev/null <<'EOF'
ACTION=="change", SUBSYSTEM=="power_supply", TAG+="systemd", ENV{SYSTEMD_WANTS}+="ryzen-power-limit.service"
EOF

sudo systemctl daemon-reload
sudo udevadm control --reload-rules
sudo systemctl enable --now ryzen-power-limit.service
echo "=== Current Ryzen power settings ==="
sudo ryzenadj -i

# ============ tuned ============
sudo systemctl enable --now tuned
tuned-adm active || true

# ============ Monitoring tools ============
sudo dnf install -y lm_sensors snapper
sudo snapper -c root create-config /
sudo snapper -c root create --description "Before changes"
sudo sensors-detect --auto

# ============ Bash extras ============
grep -q 'snapshots-list' ~/.bashrc || cat >> ~/.bashrc <<'EOF'
alias snapshots-list='sudo snapper -c root list'
alias makesnap='sudo snapper -c root create --description '
alias deletesnap='sudo snapper -c root delete '

os-age-start() {
    date +%s > "$HOME/.os-start-time"
    echo "OS age counter started: $(date '+%Y-%m-%d %H:%M:%S')"
}
os-age() {
    [[ -f "$HOME/.os-start-time" ]] || { echo "Counter not started. Run: os-age-start"; return 1; }
    local start now days
    start=$(cat "$HOME/.os-start-time"); now=$(date +%s)
    days=$(( (now - start) / 86400 ))
    echo "OS age: $days days"
}

mtop() {
    IF=$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}')
    while true; do
        clear
        echo "=== Ryzen power ==="
        sudo ryzenadj --info | grep -E 'PPT VALUE|STAPM VALUE|THM VALUE'
        echo; echo "=== Temperatures ==="
        sensors 2>/dev/null | grep -Ei 'cpu|tctl|tdie|k10temp|edge|junction|amdgpu|gpu' || echo "No sensors found"
        echo; echo "=== RAM ==="
        free -h | awk '/Mem:/ {printf "Used: %s / %s (%.1f%%)\n", $3, $2, ($3/$2)*100}'
        echo; echo "=== CPU clock ==="
        awk -F: '/cpu MHz/ {s += $2; n++} END {printf "Average: %.0f MHz\n", s/n}' /proc/cpuinfo
        echo; echo "=== Network ($IF) ==="
        R1=$(cat "/sys/class/net/$IF/statistics/rx_bytes"); T1=$(cat "/sys/class/net/$IF/statistics/tx_bytes")
        sleep 5
        R2=$(cat "/sys/class/net/$IF/statistics/rx_bytes"); T2=$(cat "/sys/class/net/$IF/statistics/tx_bytes")
        awk -v r=$((R2-R1)) -v t=$((T2-T1)) 'BEGIN {printf "Download: %.1f KB/s | Upload: %.1f KB/s\n", r/1024, t/1024}'
        sleep 1
    done
}
EOF

# ============ Data partition ============
echo "=== Configuring /mnt/data ==="
DATA_UUID="93137e69-f559-468b-b045-57576895127c"
DATA_MOUNT="/mnt/data"
DATA_DEVICE="$(sudo blkid -U "$DATA_UUID" 2>/dev/null || true)"
[[ -n "$DATA_DEVICE" ]] || { echo "Error: no device with UUID $DATA_UUID. Check: lsblk -f"; exit 1; }
DATA_FS="$(sudo blkid -o value -s TYPE "$DATA_DEVICE")"
[[ "$DATA_FS" == "ext4" ]] || { echo "Error: $DATA_DEVICE is '$DATA_FS', not ext4."; exit 1; }
sudo mkdir -p "$DATA_MOUNT"
sudo cp /etc/fstab "/etc/fstab.backup.$(date +%Y%m%d-%H%M%S)"
sudo umount "$DATA_MOUNT" 2>/dev/null || true
sudo sed -i '\|[[:space:]]/mnt/data[[:space:]]|d' /etc/fstab
echo "UUID=$DATA_UUID $DATA_MOUNT ext4 defaults,nofail,x-gvfs-show 0 2" | sudo tee -a /etc/fstab >/dev/null
sudo findmnt --verify
sudo mount "$DATA_MOUNT"
findmnt "$DATA_MOUNT"

echo
echo "=== Setup completed ==="
git config --global user.name 'KonuhovAND'
git config --global user.email 'andreykonuhov8@gmail.com'
ssh-keygen -t ed25519 -C "andreykonuhov8@mail.com" -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
echo "Commands: tabswitcher | new_tab | new_tab_parent | mtop | os-age | makesnap"
