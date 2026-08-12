#!/bin/bash
set -euo pipefail

echo "=== 1. Установка пакетов разработчика (Внутри контейнера) ==="
sudo dnf install -y \
  git curl wget vim neovim tmux htop \
  unzip p7zip p7zip-plugins \
  fzf zsh fastfetch \
  nodejs npm python3 python3-pip python3-devel \
  gcc gcc-c++ make cmake lazygit

echo "=== 2. Установка uv и Python ==="
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
uv python install 3.14

echo "=== 3. Настройка терминального окружения ==="
# Neovim (LazyVim)
git clone https://github.com/LazyVim/starter ~/.config/nvim 2>/dev/null || true
rm -rf ~/.config/nvim/.git

# Tmux
mkdir -p ~/.config/tmux
cat > ~/.config/tmux/tmux.conf <<'EOF'
bind '"' split-window -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"
bind 'c' new-window -c "#{pane_current_path}"
EOF

# Starship
curl -sS https://starship.rs/install.sh | sh -s -- -y
grep -qxF 'eval "$(starship init bash)"' ~/.bashrc || echo 'eval "$(starship init bash)"' >> ~/.bashrc

echo "=== 4. Развертывание рабочих проектов ==="
mkdir -p ~/Code
cd ~/Code

# --- Проект: Spendings (Django + React) ---
if [ ! -d "django_react_spendings" ]; then
  git clone git@github.com:KonuhovAND/django_react_spendings.git
fi
cd django_react_spendings
uv venv
# ПРАВИЛЬНЫЙ СИНТАКСИС uv: флаг -r и фоллбэк на requirements.txt
uv pip install -r req.txt 2>/dev/null || uv pip install -r requirements.txt 2>/dev/null || echo "Внимание: req.txt не найден"

if [ -d "frontend" ]; then
  cd frontend/
  npm install
  cd ..
fi

cd ~/Code/
# --- Проект: Python Machine Learning ---
if [ ! -d "PythonML" ]; then
  git clone git@github.com:KonuhovAND/PythonML.git
fi
cd PythonML
uv venv
uv pip install -r req.txt 2>/dev/null || uv pip install -r requirements.txt 2>/dev/null || echo "Внимание: req.txt не найден"
cd ~

echo "=============================================================================="
echo "СРЕДА РАЗРАБОТКИ УСПЕШНО ИНИЦИАЛИЗИРОВАНА!"
echo "=============================================================================="