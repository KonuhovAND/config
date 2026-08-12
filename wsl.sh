#!/bin/bash

sudo apt update
sudo apt install snapd python3 tmux
sudo apt install -y npm feh
sudo snap install neovim --classic
git clone https://github.com/LazyVim/starter ~/.config/nvim
sudo snap install dbeaver-ce --classic
git clone https://github.com/KonuhovAND/config.git
