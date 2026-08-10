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
  gnome-tweaks fontconfig unzip p7zip p7zip-plugins \
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
# 8. Wine & Native Steam (RPM Fusion)
# ==========================================
echo "=== Installing Wine & Steam ==="
sudo dnf install -y \
  wine \
  steam \
  steam-devices \
  protontricks

# ==========================================
# 9. Fonts
# ==========================================
echo "=== Installing JetBrains Mono ==="
sudo dnf install -y jetbrains-mono-fonts
fc-cache -f -v

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
#curl -fsSL https://ollama.com/install.sh | sh

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
  io.dbeaver.DBeaverCommunity \ 

# ==========================================
# 16. Post-Install Notes
# ==========================================
echo "=== Setup Complete ==="
echo ""
echo "Installed apps summary:"
echo "  Browsers:     Google Chrome, Zen Browser"
echo "  Chat:         Discord, Telegram, Spotify"
echo "  Dev:          Git, Neovim, Tmux, Lazygit, Node.js, Python 3.14 (via uv), uv"
echo "  Gaming:       Steam, Wine, Bottles, MangoHud, GameMode, Roblox (Sober)"
echo "  Tools:        Obsidian, Syncthing, qBittorrent, mpv, Ollama"
echo "  Proxy:        Throne"
echo "  AMD GPU:      Mesa Vulkan/VA-API drivers, Thermald"
echo ""
echo "Next steps:"
echo "  1. Add your SSH key to GitHub (printed above)"
echo "  2. Download LM Studio from https://lmstudio.ai"
echo "  3. Log out and back in for Steam/Flatpak permissions to fully apply"
echo "  4. For Roblox, launch 'Sober' from your app menu"
echo "  5. To use Python 3.14: uv venv --python 3.14"
