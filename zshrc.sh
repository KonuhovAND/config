cat > ~/.zshrc <<'ZEOF'
# history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_dups hist_reduce_blanks prompt_subst

# completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

# autosuggestions / syntax highlighting / fzf
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh

# prompt: path (~ for home) + git branch
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b)%f'
PROMPT='%F{cyan}%~%f${vcs_info_msg_0_} %# '

# PATH + editor
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim

# auto-start tmux in new terminal windows
if [ -z "$TMUX" ] && [[ $- == *i* ]] && command -v tmux >/dev/null; then
  tmux new-session -A -s main
fi
ZEOF
sed -i 's/\r$//' ~/.zshrc
exec zsh
