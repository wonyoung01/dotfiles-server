# Homebrew packages for macOS.
# This is the macOS counterpart of the apt list in scripts/pre-install.sh
# (Linux branch); keep the two in sync. Installed by `brew bundle` from the
# Darwin branch of scripts/pre-install.sh.
#
# Not here on purpose: neovim (scripts/nvim.sh), rust toolchain
# (scripts/cargo.sh), node (scripts/node.sh), uv/oh-my-zsh/p10k (pre-install).
# Tools that cargo.sh builds on Linux (zoxide, tree-sitter, zellij, broot) come
# from brew here; cargo.sh skips them on Darwin.

# --- core CLI (apt equivalents) ---
brew "git"
brew "curl"
brew "wget"
brew "vim"
brew "tmux"
brew "htop"
brew "tree"
brew "ripgrep"
brew "fd"              # apt: fd-find (binary `fdfind`); brew ships it as `fd`
brew "ffmpeg-full"    # yazi docs; conflicts with plain ffmpeg on link, pre-install force-links it
brew "sevenzip"        # apt: 7zip (`7zz`)
brew "jq"
brew "poppler"         # apt: poppler-utils (pdftotext, pdftoppm, ...)
brew "direnv"
brew "duf"
brew "pkgconf"         # apt: pkg-config
brew "openssl@3"       # apt: libssl-dev; for crates built from source that use openssl-sys
brew "python"          # apt: python3-pip / python3-venv
brew "fish"            # apt: fish PPA
brew "fzf"             # Linux uses the git install in ~/.fzf
brew "gh"              # Linux uses the GitHub apt repo
brew "bat"             # apt: bat (binary `batcat`); brew ships it as `bat`
brew "universal-ctags"
brew "pandoc"
brew "lazygit"         # `lg` alias
brew "kubernetes-cli"  # kubectl

# --- yazi (official brew list: https://yazi-rs.github.io/docs/installation) ---
# ffmpeg-full, sevenzip, jq, poppler, fd, ripgrep, fzf and the nerd font are
# already listed above. Linux installs yazi from the yazi apt repo instead
# (scripts/pre-install.sh, Linux branch).
brew "yazi"
brew "resvg"
brew "imagemagick-full" # pre-install force-links it (see ffmpeg-full)

# --- cargo tools on Linux (scripts/cargo.sh), brew on macOS ---
brew "zoxide"
brew "tree-sitter-cli"  # cargo: tree-sitter-cli (the `tree-sitter` formula is the library only)
brew "zellij"
brew "broot"

# --- fonts used by kitty/kitty.conf ---
cask "font-meslo-for-powerlevel10k"   # "MesloLGS NF"
cask "font-symbols-only-nerd-font"    # "Symbols Nerd Font Mono"

# --- apps ---
cask "kitty"
