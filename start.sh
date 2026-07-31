git config --global user.name 'KonuhovAND'
git config --global user.email 'andreykonuhov8@gmail.com'
ssh-keygen -t ed25519 -C "andreykonuhov8@mail.com"
cat ~/.ssh/id_ed25519.pub

sudo apt update && sudo apt install -y curl git build-essential python3 python3-pip python3-venv npm tmux
sudo snap install nvim --classic
sudo snap install dbeaver-ce
curl -LsSf https://astral.sh/uv/install.sh | sh

git clone --separate-git-dir=$HOME/.cfg git@github.com:KonuhovAND/config.git ~/.config
