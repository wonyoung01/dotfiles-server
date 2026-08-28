# FZF configuration

# Per-OS command names. fzf runs `become(...)`/`execute(...)` through
# `$SHELL -c`, where aliases from ~/.aliases don't exist, so the real binary
# names have to be baked into the options below.
#   Linux (Debian/Ubuntu): fd-find -> fdfind, bat -> batcat, xdg-open, xclip
#   macOS (Homebrew):      fd, bat, open, pbcopy
if [[ "$OSTYPE" == darwin* ]]; then
  _fzf_fd="fd"
  _fzf_bat="bat"
  _fzf_open="open"
  _fzf_clip="pbcopy"
else
  _fzf_fd="fdfind"
  _fzf_bat="batcat"
  _fzf_open="xdg-open"
  _fzf_clip="xclip -selection clipboard"
fi

# Default search command
export FZF_DEFAULT_COMMAND="$_fzf_fd --type f --exclude .git --exclude Library"

export FZF_DEFAULT_OPTS="
  --height 90%
  --tmux bottom,90%
  --layout reverse
  --border top
  --style full
  --preview 'fzf-preview.sh {}'
  --bind 'ctrl-o:become($_fzf_open {}),ctrl-e:become(nvim {})'
"

export FZF_CTRL_T_COMMAND="$_fzf_fd --hidden --exclude .git --exclude Library --no-ignore"

export FZF_CTRL_T_OPTS="
  --header 'Press CTRL-Y to copy command into clipboard'
  --bind 'ctrl-y:execute-silent(echo -n {1..} | $_fzf_clip)'
  --walker-skip .git,node_modules,target
  --preview 'fzf-preview.sh {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
"

export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | $_fzf_clip)'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'
  --preview-window hidden
"

export FZF_ALT_C_COMMAND="$_fzf_fd --type d --hidden --exclude .git --exclude Library"

export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target,Library
  --preview 'tree -C {}'
"

# Useful functions
frgit() {
  command fzf --height 60% --reverse --inline-info \
    --preview 'git log --full-history --graph --all --color -p {1}' \
    --preview-window right:50%:wrap "$@"
}

rfv() {
  command rg --color=always --line-number --no-heading --smart-case "${*:-}" |
  command fzf --ansi \
      --color "hl:-1:underline,hl+:-1:underline:reverse" \
      --delimiter : \
      --preview "$_fzf_bat --color=always {1} --highlight-line {2}" \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
      --bind 'enter:become(nvim {1} +{2})'
}
