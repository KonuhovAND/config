# ==========================================
# 1. Enable Systemd for WSL (Services & Flatpak)
# ==========================================
sudo bash -c 'cat <<EOF >> /etc/wsl.conf
[boot]
systemd=true
EOF'

# ==========================================
# 2. System Update & Apt Packages
# ==========================================
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  curl wget git build-essential tmux \
  python3 python3-pip python3-venv npm \
  htop mpv qbittorrent syncthing gnome-tweaks \
  flatpak alacritty chromium-browser fontconfig unzip

# Install System Info Tool (Fastfetch or Neofetch fallback)
sudo apt install -y fastfetch || sudo apt install -y neofetch

# ==========================================
# 3. Snap & Tool Installations
# ==========================================
# Install Neovim & DBeaver
sudo snap install nvim --classic
sudo snap install dbeaver-ce

# Install Lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -sLo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xzf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm lazygit lazygit.tar.gz

# Install uv (Python Package Manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# ==========================================
# 4. Install JetBrains Mono Font
# ==========================================
mkdir -p ~/.local/share/fonts
wget -q https://github.com/jetbrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip -O /tmp/jbmono.zip
unzip -o /tmp/jbmono.zip -d ~/.local/share/fonts/
fc-cache -f -v
rm /tmp/jbmono.zip

# ==========================================
# 5. Install Proxies (Throne & HappProxy)
# ==========================================
# Throne Installer
curl -fsSL https://raw.githubusercontent.com/throneproj/Throne/dev/script/install_linux.py | sudo python3

# HappProxy Debian Package
HAPP_URL=$(curl -s https://api.github.com/repos/Happ-proxy/happ-desktop/releases/latest | grep -oP 'https://[^\"]*amd64\.deb')
wget -q "$HAPP_URL" -O /tmp/happ.deb && sudo apt install -y /tmp/happ.deb && rm /tmp/happ.deb

# ==========================================
# 6. Flatpak Setup & Apps
# ==========================================
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.discordapp.Discord
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub org.telegram.desktop
flatpak install -y flathub md.obsidian.Obsidian

# Enable & Start Syncthing Service
systemctl --user enable --now syncthing

# ==========================================
# 7. Git Identity & SSH Key Generation
# ==========================================
git config --global user.name 'KonuhovAND'
git config --global user.email 'andreykonuhov8@gmail.com'

# Generate SSH Key (Press Enter when prompted if using defaults/no passphrase)
ssh-keygen -t ed25519 -C "andreykonuhov8@mail.com"

# Display Public Key (Copy this into GitHub Settings -> SSH and GPG keys)
echo "=== YOUR PUBLIC SSH KEY (Add to GitHub) ==="
cat ~/.ssh/id_ed25519.pub
echo "==========================================="

# Note: Add the SSH key to GitHub before running the dotfiles clone line below!
# git clone --separate-git-dir=$HOME/.cfg git@github.com:KonuhovAND/config.git ~/.config
