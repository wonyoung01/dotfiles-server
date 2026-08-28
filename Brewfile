# Homebrew packages for macOS.
# This is the macOS counterpart of the apt list in scripts/pre-install.sh
# (Linux branch); keep the two in sync. Installed by `brew bundle` from the
# Darwin branch of scripts/pre-install.sh.
#
# Not here on purpose: neovim (scripts/nvim.sh), rust/zoxide/yazi/broot
# (scripts/cargo.sh), node (scripts/node.sh), uv/oh-my-zsh/p10k (pre-install).

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
brew "ffmpeg"
brew "sevenzip"        # apt: 7zip (`7zz`)
brew "jq"
brew "poppler"         # apt: poppler-utils (pdftotext, pdftoppm, ...)
brew "direnv"
brew "duf"
brew "pkgconf"         # apt: pkg-config
brew "openssl@3"       # apt: libssl-dev; needed by cargo-update (openssl-sys) in scripts/cargo.sh
brew "python"          # apt: python3-pip / python3-venv
brew "fish"            # apt: fish PPA
brew "fzf"             # Linux uses the git install in ~/.fzf
brew "gh"              # Linux uses the GitHub apt repo
brew "bat"             # apt: bat (binary `batcat`); brew ships it as `bat`
brew "universal-ctags"
brew "pandoc"
brew "lazygit"         # `lg` alias
brew "kubernetes-cli"  # kubectl

# --- fonts used by kitty/kitty.conf ---
cask "font-meslo-for-powerlevel10k"   # "MesloLGS NF"
cask "font-symbols-only-nerd-font"    # "Symbols Nerd Font Mono"

# --- apps ---
cask "kitty"
