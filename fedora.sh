#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# Fedora Setup
# Ryzen 7 7730U
# ==========================================

echo "=== Updating system ==="
sudo dnf upgrade --refresh -y

# ==========================================
# RPM Fusion
# ==========================================

echo "=== Enabling RPM Fusion ==="

sudo dnf install -y \
  "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
# ==========================================
# Happ Desktop
# ==========================================

echo "=== Installing Happ Desktop 4.1.1 ==="

if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "Error: this Happ package is for x86_64 systems."
    echo "Detected architecture: $(uname -m)"
    exit 1
fi

HAPP_VERSION="4.1.1"
HAPP_RPM="/tmp/Happ.linux.x64.rpm"
HAPP_URL="https://github.com/Happ-proxy/happ-desktop/releases/download/${HAPP_VERSION}/Happ.linux.x64.rpm"

curl -fL "$HAPP_URL" -o "$HAPP_RPM"
sudo dnf install -y "$HAPP_RPM"
rm -f "$HAPP_RPM"
# ==========================================
# Core packages
# ==========================================

echo "=== Installing core tools ==="

sudo dnf install -y \
  git \
  curl \
  wget \
  vim \
  neovim \
  htop \
  fontconfig \
  unzip \
  p7zip \
  p7zip-plugins \
  fzf \
  jq \
  zsh \
  feh \
  fastfetch \
  kitty \
  nodejs \
  npm \
  python3 \
  python3-pip \
  gcc \
  gcc-c++ \
  make \
  cmake

# ==========================================
# LazyVim
# ==========================================

echo "=== Configuring Neovim ==="

if [[ ! -d "$HOME/.config/nvim" ]]; then
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
else
    echo "Neovim configuration already exists; skipping LazyVim setup."
fi

# ==========================================
# Python uv
# ==========================================

echo "=== Installing uv ==="

if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

export PATH="$HOME/.local/bin:$PATH"

# Install Python 3.14 if uv supports it
uv python install 3.14 || true

# ==========================================
# AMD graphics and virtualization
# ==========================================

echo "=== Configuring AMD graphics ==="

sudo dnf install -y \
  mesa-dri-drivers \
  mesa-va-drivers-freeworld \
  mesa-vulkan-drivers \
  vulkan-loader \
  vulkan-loader.i686 \
  amd-gpu-firmware \
  thermald

sudo dnf install -y @virtualization

sudo systemctl enable --now thermald

# Gaming tools
sudo dnf install -y gamemode mangohud

# ==========================================
# Applications
# ==========================================

echo "=== Installing applications ==="

sudo dnf install -y qbittorrent mpv

sudo dnf copr enable -y atim/lazygit
sudo dnf install -y lazygit

# ==========================================
# Google Chrome
# ==========================================

echo "=== Installing Google Chrome ==="

sudo dnf install -y fedora-workstation-repositories
sudo dnf config-manager setopt google-chrome.enabled=1
sudo dnf install -y google-chrome-stable

# ==========================================
# Fonts
# ==========================================

echo "=== Installing JetBrains Mono Nerd Font ==="

sudo dnf install -y jetbrains-mono-fonts

mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"

curl -fL \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
  -o /tmp/JetBrainsMono.zip

unzip -o /tmp/JetBrainsMono.zip \
  -d "$HOME/.local/share/fonts/JetBrainsMono"

fc-cache -f

# ==========================================
# Kitty configuration
# ==========================================

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
color0                  #45475A
color1                  #F38BA8
color2                  #A6E3A1
color3                  #F9E2AF
color4                  #89B4FA
color5                  #F5C2E7
color6                  #94E2D5
color7                  #BAC2DE
color8                  #585B70
color9                  #F38BA8
color10                 #A6E3A1
color11                 #F9E2AF
color12                 #89B4FA
color13                 #F5C2E7
color14                 #94E2D5
color15                 #A6ADC8
EOF

# ==========================================
# Kitty helper commands
# ==========================================

echo "=== Installing Kitty helper commands ==="

mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/tabswitcher" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if ! command -v kitty >/dev/null 2>&1; then
    echo "Error: kitty is not installed."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is not installed."
    exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
    echo "Error: fzf is not installed."
    exit 1
fi

if [[ -z "${KITTY_WINDOW_ID:-}" ]]; then
    echo "Error: tabswitcher must be run inside Kitty."
    exit 1
fi

selected="$(
    kitty @ ls |
        jq -r '
            .[] |
            .tabs[] |
            [
                .id,
                (.title // "Untitled")
            ] |
            @tsv
        ' |
        fzf --height=40% --layout=reverse --border --prompt="Tabs> "
)" || exit 0

tab_id="${selected%%$'\t'*}"

if [[ -n "$tab_id" ]]; then
    kitty @ focus-tab --match "id:$tab_id"
fi
EOF

chmod +x "$HOME/.local/bin/tabswitcher"

# Add shell commands to Bash and Zsh
for shell_rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    touch "$shell_rc"

    if ! grep -q 'function new_tab_parent' "$shell_rc"; then
        cat >> "$shell_rc" <<'EOF'

# Kitty helpers
new_tab() {
    kitty @ launch --type=tab --cwd="$PWD"
}

new_tab_parent() {
    kitty @ launch --type=tab --cwd="$(dirname "$PWD")"
}

alias tabswitcher="$HOME/.local/bin/tabswitcher"
EOF
    fi
done



# ==========================================
# Syncthing
# ==========================================

echo "=== Installing Syncthing ==="

sudo dnf install -y syncthing
systemctl --user enable --now syncthing

# ==========================================
# Flatpak
# Wine, Bottles, and Sober intentionally removed
# ==========================================

echo "=== Configuring Flatpak ==="

sudo flatpak remote-add --if-not-exists \
  flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo

echo "=== Installing Flatpak applications ==="

flatpak install -y flathub \
  com.spotify.Client \
  com.discordapp.Discord \
  org.telegram.desktop \
  md.obsidian.Obsidian \
  com.jeffser.Alpaca \
  io.dbeaver.DBeaverCommunity

# ==========================================
# RyzenAdj
# ==========================================

echo "=== Installing RyzenAdj ==="

sudo dnf copr enable -y shdwchn10/ryzenadj
sudo dnf install -y ryzenadj

RYZENADJ_BIN="$(command -v ryzenadj)"

POWER_LIMIT=8000
POWER_LIMIT2=18000
POWER_LIMIT3=15000

echo "=== Applying Ryzen power limits ==="
echo "STAPM limit: ${POWER_LIMIT} mW"
echo "Fast limit:  ${POWER_LIMIT2} mW"
echo "Slow limit:  ${POWER_LIMIT3} mW"

sudo "$RYZENADJ_BIN" \
  -a "$POWER_LIMIT" \
  -b "$POWER_LIMIT2" \
  -c "$POWER_LIMIT3"

echo
echo "=== Current Ryzen power settings ==="
sudo "$RYZENADJ_BIN" -i

sudo tee /etc/systemd/system/ryzen-power-limit.service >/dev/null <<EOF
[Unit]
Description=Set RyzenAdj power limits
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$RYZENADJ_BIN -a $POWER_LIMIT -b $POWER_LIMIT2 -c $POWER_LIMIT3
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ryzen-power-limit.service

# ==========================================
# tuned
# ==========================================

echo "=== Enabling tuned ==="

sudo systemctl enable --now tuned
tuned-adm active || true

# ==========================================
# Mount data partition
# ==========================================

echo "=== Configuring /mnt/data ==="

DATA_UUID="93137e69-f559-468b-b045-57576895127c"
DATA_MOUNT="/mnt/data"

DATA_DEVICE="$(sudo blkid -U "$DATA_UUID" 2>/dev/null || true)"

if [[ -z "$DATA_DEVICE" ]]; then
    echo "Error: no block device was found with UUID $DATA_UUID"
    echo "Check the UUID with:"
    echo "  lsblk -f"
    echo "  sudo blkid"
    exit 1
fi

DATA_FILESYSTEM="$(sudo blkid -o value -s TYPE "$DATA_DEVICE")"

if [[ "$DATA_FILESYSTEM" != "ext4" ]]; then
    echo "Error: $DATA_DEVICE has filesystem type '$DATA_FILESYSTEM', not ext4."
    exit 1
fi

sudo mkdir -p "$DATA_MOUNT"

# Back up fstab before modifying it
sudo cp /etc/fstab "/etc/fstab.backup.$(date +%Y%m%d-%H%M%S)"

# Unmount it if an old entry is currently mounted
sudo umount "$DATA_MOUNT" 2>/dev/null || true

# Remove old /mnt/data entries, including the previous exFAT entry
sudo sed -i '\|[[:space:]]/mnt/data[[:space:]]|d' /etc/fstab

sudo tee -a /etc/fstab >/dev/null <<EOF
UUID=$DATA_UUID $DATA_MOUNT ext4 defaults,nofail,x-gvfs-show 0 2
EOF

echo "=== Checking /etc/fstab ==="
sudo findmnt --verify

echo "=== Mounting /mnt/data ==="
sudo mount "$DATA_MOUNT"

echo "=== Mounted data partition ==="
findmnt "$DATA_MOUNT"

echo
echo "Setup completed successfully."
echo
echo "Kitty commands:"
echo "  tabswitcher       - interactively switch Kitty tabs"
echo "  new_tab           - open a tab in the current directory"
echo "  new_tab_parent    - open a tab in the parent directory"
echo
echo "Data partition:"
echo "  $DATA_DEVICE -> $DATA_MOUNT"

cat >>  '~/.bashrc'  << 'EOF'
alias snapshots-list='sudo snapper -c root list'
alias makesnap='sudo snapper -c root create --description '
alias deletesnap='sudo snapper -c root delete '
EOF
cat >> ~/.bashrc <<'EOF'

os-age-start() {
    date +%s > "$HOME/.os-start-time"
    echo "OS age counter started: $(date '+%Y-%m-%d %H:%M:%S')"
}

os-age() {
    if [[ ! -f "$HOME/.os-start-time" ]]; then
        echo "Counter not started. Run: os-age-start"
        return 1
    fi

    local start now days
    start=$(cat "$HOME/.os-start-time")
    now=$(date +%s)
    days=$(( (now - start) / 86400 ))

    echo "OS age: $days days"
}
EOF
sudo dnf install snapper
sudo snapper -c root create-config /
sudo snapper -c root create --description "Before changes"
