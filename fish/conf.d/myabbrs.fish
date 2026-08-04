# myabbrs.fish — personal fish abbreviations
# Sourced automatically by fish from conf.d.

if status is-interactive
    # system
    abbr -a fd fdfind
    abbr -a open xdg-open
    abbr -a bat batcat
    abbr -a lg lazygit
    abbr -a pbcopy 'xclip -in -sel clip'
    abbr -a pbpaste 'xclip -out -sel clip'

    # yy: copy the current directory path to the clipboard.
    # Falls back to OSC 52 when there is no X display (ssh, tty), which
    # hands the text to the outer terminal emulator instead.
    function yy --description 'Copy the current directory path to the clipboard'
        set -l dir (realpath .)
        if test -n "$DISPLAY"
            printf '%s' $dir | xclip -in -sel clip
        else
            printf '\e]52;c;%s\a' (printf '%s' $dir | base64 -w0)
        end
    end

    # git
    abbr -a gs git status
    abbr -a gdiff git diff
    abbr -a glola 'git log --graph --pretty=\'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset\' --all'
    abbr -a gco git checkout
    abbr -a grv git remote -v

    # navigation
    abbr -a .. cd ..
    abbr -a ... cd ../..
    abbr -a .... cd ../../..

    # listing
    abbr -a l ls
    abbr -a ll ls -lh
    abbr -a la ls -lah

    # docker
    abbr -a drm docker rm
    abbr -a drmi docker rmi
    abbr -a dps docker ps
    abbr -a dpsa docker ps -a
    abbr -a dxcit docker exec -it

    # kitty
    abbr -a kssh 'kitten ssh'
    abbr -a kicat 'kitten icat'

    # conda
    abbr -a ca 'conda activate'
    abbr -a cda 'conda deactivate'
end
