#!/bin/bash
set -euo pipefail

sudo pacman -Syu --noconfirm

sudo pacman -S --needed --noconfirm \
  base-devel \
  git curl wget openssh \
  vim neovim tmux htop fzf zsh \
  feh fastfetch \
  unzip p7zip \
  nodejs npm \
  python python-pip \
  gcc gcc-c++ make cmake \
  mesa mesa-utils \
  vulkan-icd-loader \
  lib32-vulkan-icd-loader \
  vulkan-radeon \
  lib32-vulkan-radeon \
  amd-ucode \
  qbittorrent mpv \
  gamemode mangohud \
  kitty \
  syncthing \
  exfatprogs

if ! command -v paru >/dev/null 2>&1; then
  paru_dir="$(mktemp -d)"

  git clone https://aur.archlinux.org/paru.git "$paru_dir/paru"

  cd "$paru_dir/paru"
  makepkg -si --noconfirm

  cd -
  rm -rf "$paru_dir"
fi

paru -S --needed --noconfirm \
  google-chrome \
  lazygit \
  lazysql

happ_url="https://github.com/Happ-proxy/happ-desktop/releases/download/4.1.1/Happ.linux.x64.pkg.tar.zst"
happ_file="/tmp/Happ.linux.x64.pkg.tar.zst"

curl -L "$happ_url" -o "$happ_file"
sudo pacman -U --noconfirm "$happ_file"
rm -f "$happ_file"

curl -LsSf https://astral.sh/uv/install.sh | sh

export PATH="$HOME/.local/bin:$PATH"

uv python install 3.14

git config --global user.name "KonuhovAND"
git config --global user.email "andreykonuhov8@gmail.com"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  ssh-keygen \
    -t ed25519 \
    -C "andreykonuhov8@mail.com" \
    -N "" \
    -f "$HOME/.ssh/id_ed25519"
fi

echo
echo "Add this SSH key to https://github.com/settings/keys"
echo
cat "$HOME/.ssh/id_ed25519.pub"
echo
echo "You have 10 seconds to copy the SSH key"
sleep 10

if [[ ! -d "$HOME/config_files" ]]; then
  git clone \
    --separate-git-dir="$HOME/.cfg" \
    https://github.com/KonuhovAND/config.git \
    "$HOME/config_files"
fi

if [[ ! -d "$HOME/.config/nvim" ]]; then
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
fi

mkdir -p "$HOME/.config/tmux"

cat > "$HOME/.config/tmux/tmux.conf" <<'EOF'
bind '"' split-window -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"
EOF

mkdir -p "$HOME/.config/kitty"

kitty_conf="$HOME/.config/kitty/kitty.conf"

touch "$kitty_conf"

if ! grep -Fxq "map ctrl+shift+t new_tab_with_cwd" "$kitty_conf"; then
  printf '\nmap ctrl+shift+t new_tab_with_cwd\n' >> "$kitty_conf"
fi

systemctl --user enable --now syncthing.service

sudo mkdir -p /mnt/data

if ! grep -q "UUID=F4C0-4BAE" /etc/fstab; then
  echo "UUID=F4C0-4BAE /mnt/data exfat defaults,uid=$(id -u),gid=$(id -g),rw,umask=000 0 0" \
    | sudo tee -a /etc/fstab
fi

if ! mountpoint -q /mnt/data; then
  sudo mount /mnt/data || true
fi

mkdir -p "$HOME/Code"

cd "$HOME/Code"

if [[ ! -d "$HOME/Code/django_react_spendings" ]]; then
  git clone git@github.com:KonuhovAND/django_react_spendings.git
fi

cd "$HOME/Code/django_react_spendings"

uv venv
uv pip install -r req.txt

if [[ -d frontend ]]; then
  cd frontend

  rm -rf node_modules package-lock.json
  npm cache clean --force
  npm install
fi

cd "$HOME/Code"

if [[ ! -d "$HOME/Code/PythonML" ]]; then
  git clone git@github.com:KonuhovAND/PythonML.git
fi

cd "$HOME/Code/PythonML"

uv venv
uv pip install -r req.txt

echo
echo "Installation completed"
echo
echo "Kitty configuration:"
echo "$HOME/.config/kitty/kitty.conf"
echo
echo "Shortcut:"
echo "Ctrl+Shift+T - open a new Kitty tab in the current directory"
