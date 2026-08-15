#!/bin/bash
set -e

echo "==> 1. Updating system and installing base dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential python3 python3-pip python3-venv \
    tmux snapd feh ripgrep fd-find unzip tar

# Install Node.js LTS (Required for many Neovim LSP servers)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

echo "==> 2. Installing DBeaver..."
sudo snap install dbeaver-ce --classic


echo "==> 3. Installing Kitty Terminal..."
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
mkdir -p ~/.local/bin
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
ln -sf ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten

echo "==> 4. Installing Astral UV (Fast Python package manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh

echo "==> 5. Installing Lazygit (Latest release)..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar -xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm lazygit lazygit.tar.gz

echo "==> 6. Installing Latest Neovim..."
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz

echo "==> 7. Installing LazyVim..."
# Backup existing neovim config if present
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
mv ~/.local/share/nvim ~/.local/share/nvim.bak 2>/dev/null || true
mv ~/.local/state/nvim ~/.local/state/nvim.bak 2>/dev/null || true
mv ~/.cache/nvim ~/.cache/nvim.bak 2>/dev/null || true

# Clone LazyVim starter
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

echo "==> 8. Configuring Git & SSH..."
git config --global user.name 'KonuhovAND'
git config --global user.email 'andreykonuhov8@gmail.com'

if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "andreykonuhov8@gmail.com" -N "" -f ~/.ssh/id_ed25519
fi

echo "===================================================="
echo " Setup complete! Here is your public SSH key: "
echo "===================================================="
cat ~/.ssh/id_ed25519.pub
echo "===================================================="
echo "TIP: To get icons in Kitty & Neovim, install a Nerd Font (e.g., JetBrainsMono Nerd Font)."
