#!/bin/bash
set -euo pipefail

# ==========================================
# 11. Throne Proxy
# ==========================================
echo "=== Installing Throne ==="
#curl -fsSL https://raw.githubusercontent.com/throneproj/Throne/dev/script/install_linux.py | sudo python3

# ==========================================
# 5. Git Identity & SSH
# ==========================================
git config --global user.name 'KonuhovAND'
git config --global user.email 'andreykonuhov8@gmail.com'

if [ ! -f ~/.ssh/id_ed25519 ]; then
  ssh-keygen -t ed25519 -C "andreykonuhov8@mail.com" -N "" -f ~/.ssh/id_ed25519
fi

echo "=== YOUR PUBLIC SSH KEY (Add to GitHub) ==="
cat ~/.ssh/id_ed25519.pub
echo "==========================================="

sleep 30
git clone --separate-git-dir=$HOME/.cfg https://github.com/KonuhovAND/config.git ~/config_files
# ==========================================
# Fedora Setup for AMD Ryzen 7 7330U
# ==========================================

echo "=== Updating System ==="
sudo dnf upgrade --refresh -y

# ==========================================
# 1. Enable RPM Fusion (Free & Non-Free)
# Required for Steam, FFmpeg codecs, and drivers
# ==========================================
echo "=== Enabling RPM Fusion ==="
sudo dnf install -y \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# ==========================================
# 2. Core Development & CLI Tools
# ==========================================
echo "=== Installing Core Tools ==="
sudo dnf install -y \
  git curl wget vim neovim tmux htop \
  fontconfig unzip p7zip p7zip-plugins \
  fzf zsh \
  feh \
  fastfetch || sudo dnf install -y neofetch

# ==========================================
# 3. Languages & Runtimes
# ==========================================
echo "=== Installing Node.js, Python, and Build Tools ==="
sudo dnf install -y \
  nodejs npm \
  python3 python3-pip \
  gcc gcc-c++ make cmake

# Install uv (Python version & package manager)
echo "=== Installing uv ==="
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

# Install Python 3.14 via uv (Fedora repos may lag behind latest CPython)
uv python install 3.14

# ==========================================
# 4. AMD Ryzen 7330U / Radeon Graphics Setup
# ==========================================
echo "=== Configuring AMD Radeon Graphics ==="
sudo dnf install -y \
  mesa-dri-drivers \
  mesa-va-drivers-freeworld \
  mesa-vulkan-drivers \
  vulkan-loader vulkan-loader.i686 \
  amd-gpu-firmware \
  thermald

# Enable thermal management
sudo systemctl enable --now thermald

# Gaming performance tools
sudo dnf install -y gamemode mangohud

# ==========================================
# 6. Terminal / CLI Apps from Repos
# ==========================================
echo "=== Installing Lazygit, qBittorrent, mpv ==="
sudo dnf install -y qbittorrent mpv
sudo dnf copr enable -y atim/lazygit
sudo dnf install -y lazygit

# ==========================================
# 7. Google Chrome
# ==========================================
echo "=== Installing Google Chrome ==="
sudo dnf install -y fedora-workstation-repositories
sudo dnf config-manager setopt google-chrome.enabled=1
sudo dnf install -y google-chrome-stable


# ==========================================
# 9. Fonts
# ==========================================
echo "=== Installing JetBrains Mono ==="
sudo dnf install -y jetbrains-mono-fonts
fc-cache -f -v
sudo dnf install -y alacritty

mkdir -p ~/.config/alacritty && cat > ~/.config/alacritty/alacritty.toml <<'EOF'
[font]
size = 12.0

[font.normal]
family = "JetBrainsMono Nerd Font"
style = "Regular"

[font.bold]
family = "JetBrains Mono"
style = "Bold"

[font.italic]
family = "JetBrains Mono"
style = "Italic"

[font.bold_italic]
family = "JetBrains Mono"
style = "Bold Italic"

# Optional: a bit of extra line spacing looks nicer for coding
[font.offset]
x = 0
y = 1
EOF


mkdir -p ~/.local/share/fonts
cd /tmp
curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
fc-cache -f
cd

# ==========================================
# 10. Syncthing
# ==========================================
echo "=== Installing Syncthing ==="
sudo dnf install -y syncthing
systemctl --user enable --now syncthing

# ==========================================
# 12. Ollama (Local LLMs)
# ==========================================
echo "=== Installing Ollama ==="
curl -fsSL https://ollama.com/install.sh | sh

# ==========================================
# 13. Flatpak Setup & GUI Apps
# ==========================================
echo "=== Setting up Flatpak ==="
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "=== Installing Flatpak Apps ==="
flatpak install -y flathub \
  com.spotify.Client \
  com.discordapp.Discord \
  org.telegram.desktop \
  md.obsidian.Obsidian \
  com.usebottles.bottles \
  org.vinegarhq.Sober \
  io.dbeaver.DBeaverCommunity

sudo dnf copr enable shdwchn10/ryzenadj
sudo dnf install ryzenadj
sudo ryzenadj --stapm-limit=14500 --fast-limit=15000 --slow-limit=15000 --tctl-temp=85

sudo tee /etc/systemd/system/ryzenadj.service > /dev/null <<'EOF'
[Unit]
Description=RyzenAdj Power Management
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ryzenadj --stapm-limit=15000 --fast-limit=15000 --slow-limit=15000 --tctl-temp=85
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl daemon-reload
sudo systemctl enable --now ryzenadj.service

sudo systemctl enable --now tuned
tuned-adm active
