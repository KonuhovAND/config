#!/usr/bin/env bash
# Debian WSL dev setup: nvim 0.11.2 + LazyVim, lazygit, lazysql, tmux,
# zsh (autosuggestions + completions), uv, node/npm, python
set -euo pipefail

TARGET_USER="${1:-root}"
export DEBIAN_FRONTEND=noninteractive

echo "==> [1/9] System update + base packages"
apt-get update -y
apt-get -y full-upgrade
apt-get install -y \
  ca-certificates curl wget git unzip zip tar less jq \
  build-essential pkg-config \
  tmux zsh fzf ripgrep fd-find bat \
  nodejs npm \
  python3 python3-pip python3-venv python3-dev \
  zsh-autosuggestions zsh-syntax-highlighting

# Debian binary names -> conventional names
[ -x /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind /usr/local/bin/fd
[ -x /usr/bin/batcat ] && ln -sf /usr/bin/batcat /usr/local/bin/bat

echo "==> [2/9] Neovim v0.11.2"
curl -fL --retry 3 -o /tmp/nvim.tar.gz \
  https://github.com/neovim/neovim/releases/download/v0.11.2/nvim-linux-x86_64.tar.gz
rm -rf /opt/nvim-linux-x86_64
tar -C /opt -xzf /tmp/nvim.tar.gz
ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm -f /tmp/nvim.tar.gz

echo "==> [3/9] lazygit"
LG_VER="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
  | sed -n 's/.*"tag_name": *"v\([0-9.]*\)".*/\1/p' | head -n1)"
[ -n "$LG_VER" ] || { echo "WARN: could not detect lazygit version (GitHub rate limit?)"; }
if [ -n "$LG_VER" ]; then
  curl -fL --retry 3 -o /tmp/lazygit.tar.gz \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_x86_64.tar.gz"
  tar -C /usr/local/bin -xzf /tmp/lazygit.tar.gz lazygit
  rm -f /tmp/lazygit.tar.gz
fi

echo "==> [4/9] lazysql"
LZ_URL="$(curl -fsSL https://api.github.com/repos/jorgerojas26/lazysql/releases/latest \
  | grep -io 'https://[^"]*linux[^"]*x86_64[^"]*\.tar\.gz' | head -n1)"
if [ -n "$LZ_URL" ]; then
  mkdir -p /tmp/lazysql
  curl -fL --retry 3 -o /tmp/lazysql.tar.gz "$LZ_URL"
  tar -C /tmp/lazysql -xzf /tmp/lazysql.tar.gz
  BIN="$(find /tmp/lazysql -type f -name lazysql | head -n1)"
  install -m 0755 "$BIN" /usr/local/bin/lazysql
  rm -rf /tmp/lazysql /tmp/lazysql.tar.gz
else
  echo "WARN: could not detect lazysql download URL (GitHub rate limit?)"
fi

echo "==> [5/9] Preparing user config for: $TARGET_USER"
if [ "$TARGET_USER" = "root" ] || [ -z "$TARGET_USER" ]; then
  USER_HOME="/root"
  run_as_user() { bash -c "$1"; }
else
  USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  run_as_user() { runuser -u "$TARGET_USER" -- bash -c "$1"; }
fi

echo "==> [6/9] LazyVim (lazy.nvim based)"
run_as_user "mkdir -p '$USER_HOME/.config'"
if [ -d "$USER_HOME/.config/nvim" ] && [ ! -d "$USER_HOME/.config/nvim.bak" ]; then
  mv "$USER_HOME/.config/nvim" "$USER_HOME/.config/nvim.bak"
fi
run_as_user "git clone https://github.com/LazyVim/starter '$USER_HOME/.config/nvim'"
run_as_user "rm -rf '$USER_HOME/.config/nvim/.git'"

echo "==> [7/9] zsh config (autosuggestions, syntax highlighting, fzf, completions)"
touch "$USER_HOME/.zshrc"
grep -q 'WSL-DEV-SETUP' "$USER_HOME/.zshrc" || cat >> "$USER_HOME/.zshrc" <<'EOF'

# >>> WSL-DEV-SETUP >>>
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim
autoload -Uz compinit && compinit
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
# <<< WSL-DEV-SETUP <<<
EOF

cat > "$USER_HOME/.tmux.conf" <<'EOF'
set -g mouse on
set -g history-limit 10000
setw -g mode-keys vi
EOF

echo "==> [8/9] uv (Python manager)"
run_as_user "curl -LsSf https://astral.sh/uv/install.sh | sh"

echo "==> [9/9] Fixing ownership + default shell"
if [ "$TARGET_USER" != "root" ] && [ -n "$TARGET_USER" ]; then
  chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.zshrc" "$USER_HOME/.tmux.conf" "$USER_HOME/.local" 2>/dev/null || true
fi
chsh -s /usr/bin/zsh "$TARGET_USER" 2>/dev/null || true

echo.
echo "Installed versions:"
nvim --version | head -n1
lazygit --version 2>/dev/null || true
lazysql --version 2>/dev/null || true
tmux -V
node --version
npm --version
python3 --version
echo "Done. Run 'nvim' once to let LazyVim install its plugins."