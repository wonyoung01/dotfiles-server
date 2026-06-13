# ~/.config/fish/config.fish
# Translated from ~/dotfiles/zshrc and ~/.config/zsh/*.zsh

################################
# Language / Editor
################################
set -gx LANG en_US.UTF-8
set -gx LC_CTYPE en_US.UTF-8

if command -q nvim
    set -gx EDITOR nvim
    set -gx VISUAL nvim
else
    set -gx EDITOR vim
    set -gx VISUAL vim
end

################################
# PATH
################################
fish_add_path -gP $HOME/.cargo/bin
fish_add_path -gP $HOME/.local/bin
fish_add_path -gP $HOME/.npm-global/bin

################################
# NVM — jorgebucaran/nvm.fish plugin (bootstrapped below).
# Uses the plugin's own store (~/.local/share/nvm); the default version is
# installed on first run and activated eagerly in the interactive section.
################################

################################
# Conda (managed block — re-run `conda init fish` to regenerate)
# Supports either miniconda3 or anaconda3 (miniconda preferred). Set $CONDADIR
# to point at the parent directory of the install (defaults to $HOME).
################################
if test -z "$CONDADIR"
    set -gx CONDADIR $HOME
end
for __conda_base in "$CONDADIR/miniconda3" "$CONDADIR/anaconda3"
    if test -f "$__conda_base/etc/fish/conf.d/conda.fish"
        source "$__conda_base/etc/fish/conf.d/conda.fish"
        break
    else if test -d "$__conda_base/bin"
        fish_add_path -gP "$__conda_base/bin"
        break
    end
end
set -e __conda_base

################################
# Interactive-only below
################################
if not status is-interactive
    exit
end

################################
# Fisher (plugin manager) + plugins
# Bootstraps fisher on a fresh machine, then ensures each plugin is present.
# Idempotent: skips anything already installed.
################################
if not functions -q fisher
    echo "fish: installing fisher…" >&2
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    and fisher install jorgebucaran/fisher
end

# edc/bass — run bash scripts/utilities inside fish
functions -q bass; or fisher install edc/bass
# jorgebucaran/nvm.fish — fish-native nvm (manages its own ~/.local/share/nvm)
functions -q nvm; or fisher install jorgebucaran/nvm.fish

# Always load the default Node version (install it once on a fresh machine)
if functions -q nvm
    test -z (nvm list 2>/dev/null | string collect); and nvm install lts
    nvm use lts >/dev/null 2>&1
end

################################
# Vi mode (replaces zsh vi-mode plugin)
################################
fish_vi_key_bindings

################################
# Aliases (from ~/dotfiles/aliases)
# Use functions with `command` for self-wrapping aliases to avoid recursion.
################################
function mkdir
    command mkdir -p $argv
end
function mv
    command mv -i $argv
end
function cp
    command cp -i $argv
end
function rm
    command rm -i $argv
end
function df
    command df -h $argv
end
function du
    command du -h $argv
end

################################
# FZF configuration
################################
set -gx FZF_DEFAULT_COMMAND 'fdfind --type f --exclude .git --exclude Library'
set -gx FZF_DEFAULT_OPTS "
  --height 90%
  --tmux bottom,90%
  --layout reverse
  --border top
  --style full
  --preview 'fzf-preview.sh {}'
  --bind 'ctrl-o:become(xdg-open {}),ctrl-e:become(nvim {})'
"
set -gx FZF_CTRL_T_COMMAND 'fdfind --hidden --exclude .git --exclude Library --no-ignore'
set -gx FZF_CTRL_T_OPTS "
  --header 'Press CTRL-Y to copy command into clipboard'
  --bind 'ctrl-y:execute-silent(echo -n {1..} | xclip -selection clipboard)'
  --walker-skip .git,node_modules,target
  --preview 'fzf-preview.sh {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
"
set -gx FZF_CTRL_R_OPTS "
  --bind 'ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'
  --preview-window hidden
"
set -gx FZF_ALT_C_COMMAND 'fdfind --type d --hidden --exclude .git --exclude Library'
set -gx FZF_ALT_C_OPTS "
  --walker-skip .git,node_modules,target,Library
  --preview 'tree -C {}'
"

if command -q fzf
    fzf --fish | source
end

################################
# Tool integrations
################################
if command -q direnv
    direnv hook fish | source
end

if command -q zoxide
    zoxide init fish | source
end

if test -f "$HOME/.local/bin/env.fish"
    source "$HOME/.local/bin/env.fish"
end

################################
# Wrapper functions (from zsh/wrappers.zsh)
################################
function mkcd
    command mkdir -p $argv[1]; and cd $argv[1]
end

function bigfiles
    du -ah . | sort -rh | head -20
end

function serve
    set -l port $argv[1]
    test -z "$port"; and set port 8000
    python3 -m http.server $port
end

function git-init
    test -d .git; or git init
    git add .
    git commit -m "Initial commit"
end

function git-submodule-delete
    git submodule deinit -f -- $argv[1]
    git rm -f $argv[1]
    rm -rf .git/modules/$argv[1]
end

function myrun
    $argv
    printf '\a'
end

# Yazi: cd into directory yazi exits at
function y
    set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    set -l cwd (command cat -- "$tmp")
    if test -n "$cwd"; and test "$cwd" != "$PWD"; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    command rm -f -- "$tmp"
end

# tmux-window-run: run a command in a new tmux window
# Usage: tmux-window-run [-L socket] [-t session] [-n name] -- <cmd...>
function tmux-window-run
    set -l socket ""
    set -l name run
    set -l target ""
    while test (count $argv) -gt 0
        switch $argv[1]
            case -L
                set socket $argv[2]
                set -e argv[1..2]
            case -n
                set name $argv[2]
                set -e argv[1..2]
            case -t
                set target $argv[2]
                set -e argv[1..2]
            case --
                set -e argv[1]
                break
            case '*'
                break
        end
    end
    if test -z "$TMUX"; and test -z "$target"
        echo "tmux-window-run: not inside a tmux session (use -t <session> to target one)" >&2
        return 1
    end
    set -l cmd (string join ' ' -- $argv)
    set -l tmux_cmd tmux
    test -n "$socket"; and set tmux_cmd $tmux_cmd -L $socket
    set -l new_window_args new-window
    test -n "$target"; and set new_window_args $new_window_args -t "$target:"
    set new_window_args $new_window_args -n $name
    set -l notify
    if test -n "$SSH_CONNECTION"; or test -n "$SSH_TTY"
        set notify "printf '\\a'"
    else
        set notify "command -v notify-send >/dev/null && notify-send 'tmux-window-run' \"done: $cmd\" || printf '\\a'"
    end
    $tmux_cmd $new_window_args "$cmd; $notify; tmux display-message 'done: $cmd'; exec $SHELL"
end

# tmux-session-run: run a command in a new tmux session
function tmux-session-run
    set -l socket ""
    set -l target ""
    set -l name run
    while test (count $argv) -gt 0
        switch $argv[1]
            case -L
                set socket $argv[2]
                set -e argv[1..2]
            case -t
                set target $argv[2]
                set -e argv[1..2]
            case -n
                set name $argv[2]
                set -e argv[1..2]
            case --
                set -e argv[1]
                break
            case '*'
                break
        end
    end
    test -z "$target"; and set target "run-$fish_pid-"(random)
    set -l cmd (string join ' ' -- $argv)
    set -l tmux_cmd tmux
    test -n "$socket"; and set tmux_cmd $tmux_cmd -L $socket
    set -l notify
    if test -n "$SSH_CONNECTION"; or test -n "$SSH_TTY"
        set notify "printf '\\a'"
    else
        set notify "command -v notify-send >/dev/null && notify-send 'tmux-session-run' \"done: $cmd\" || printf '\\a'"
    end
    if not $tmux_cmd new-session -d -s $target -n $name "$cmd; $notify; tmux display-message 'done: $cmd'; exec $SHELL"
        return 1
    end
    set -l attach tmux
    test -n "$socket"; and set attach "$attach -L $socket"
    echo "started tmux session: $target (attach with: $attach attach -t $target)"
end

# FZF helpers (from fzf_config.zsh)
function frgit
    command fzf --height 60% --reverse --inline-info \
        --preview 'git log --full-history --graph --all --color -p {1}' \
        --preview-window right:50%:wrap $argv
end

function rfv
    command rg --color=always --line-number --no-heading --smart-case "$argv" \
        | command fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --delimiter : \
        --preview 'batcat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind 'enter:become(nvim {1} +{2})'
end

################################
# Local overrides
################################
if test -f $HOME/.config/fish/config_local.fish
    source $HOME/.config/fish/config_local.fish
end

################################
# Prompt
# Fish has no oh-my-zsh / powerlevel10k. Options:
#   - Tide (closest to p10k):  fisher install IlanCosman/tide@v6 ; tide configure
#   - Starship:                set -gx STARSHIP_CONFIG ~/.config/starship.toml
#                              starship init fish | source
# Built-in fish_prompt is used by default.
################################
