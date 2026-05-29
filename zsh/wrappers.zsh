# ~/.config/zsh/wrappers.zsh
# Shell wrapper functions

# safer scripting defaults
setopt NO_NOMATCH

################################
# Utilities
################################

# make directory and cd
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# show largest files
bigfiles() {
  du -ah . | sort -rh | head -20
}

# quick HTTP server
serve() {
  python3 -m http.server "${1:-8000}"
}

# init the git repository (if not already) and add all files
git-init() {
  [ -d .git ] || git init
  git add .
  git commit -m "Initial commit"
}

# delete submodules and commit
git-submodule-delete() {
  git submodule deinit -f -- "$1"
  git rm -f "$1"
  rm -rf .git/modules/"$1"
}

# Simple runner
myrun() {
    "$@"
    printf "\a"
}

# Run a command in a new tmux window
# Inside tmux: creates a window in the current session (or -t target)
# Outside tmux: requires -t <session> to target an existing session
# Usage: tmux-window-run [-L socket] [-t session] [-n name] -- <cmd...>
tmux-window-run() {
    local socket="" name="run" target=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -L) socket="$2"; shift 2 ;;
            -n) name="$2"; shift 2 ;;
            -t) target="$2"; shift 2 ;;
            --) shift; break ;;
            *) break ;;
        esac
    done
    if [ -z "$TMUX" ] && [ -z "$target" ]; then
        echo "tmux-window-run: not inside a tmux session (use -t <session> to target one)" >&2
        return 1
    fi
    local cmd="$*"
    local tmux_cmd=(tmux)
    [ -n "$socket" ] && tmux_cmd+=(-L "$socket")
    local new_window_args=(new-window)
    [ -n "$target" ] && new_window_args+=(-t "${target}:")
    new_window_args+=(-n "$name")
    local notify
    if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
        notify="printf '\\a'"
    else
        notify="command -v notify-send >/dev/null && notify-send 'tmux-window-run' \"done: $cmd\" || printf '\\a'"
    fi
    "${tmux_cmd[@]}" "${new_window_args[@]}" "$cmd; $notify; tmux display-message 'done: $cmd'; exec $SHELL"
}

# Run a command in a new tmux session (works outside tmux)
# Usage: tmux-session-run [-L socket] [-t session] [-n window] -- <cmd...>
tmux-session-run() {
    local socket="" target="" name="run"
    while [ $# -gt 0 ]; do
        case "$1" in
            -L) socket="$2"; shift 2 ;;
            -t) target="$2"; shift 2 ;;
            -n) name="$2"; shift 2 ;;
            --) shift; break ;;
            *) break ;;
        esac
    done
    [ -z "$target" ] && target="run-$$-$RANDOM"
    local cmd="$*"
    local tmux_cmd=(tmux)
    [ -n "$socket" ] && tmux_cmd+=(-L "$socket")
    local notify
    if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
        notify="printf '\\a'"
    else
        notify="command -v notify-send >/dev/null && notify-send 'tmux-session-run' \"done: $cmd\" || printf '\\a'"
    fi
    if ! "${tmux_cmd[@]}" new-session -d -s "$target" -n "$name" "$cmd; $notify; tmux display-message 'done: $cmd'; exec $SHELL"; then
        return 1
    fi
    local attach="tmux"
    [ -n "$socket" ] && attach="$attach -L $socket"
    echo "started tmux session: $target (attach with: $attach attach -t $target)"
}

################################
# Yazi
################################

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
