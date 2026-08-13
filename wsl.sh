sudo apt update && sudo apt upgrade -y && sudo apt install -y curl git build-essential python3 python3-pip python3-venv tmux snapd feh && curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt install -y nodejs && sudo snap install dbeaver-ce --classic


git config --global user.name 'KonuhovAND'
git config --global user.email 'andreykonuhov8@gmail.com'
ssh-keygen -t ed25519 -C "andreykonuhov8@mail.com" -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
