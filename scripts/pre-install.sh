#!/usr/bin/env bash
set -euo pipefail

OS="$(uname)"

# Optional sudo: use sudo only when not root and sudo is available
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

if [ "$OS" = "Darwin" ]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Updating Homebrew"
    brew update
  fi

  # Brewfile bundle
  if [ -f "Brewfile" ]; then
    brew bundle
  else
    echo "No Brewfile found in $(pwd) - skipping 'brew bundle'"
  fi

elif [ "$OS" = "Linux" ]; then
  installlist=(
    zsh
    git
    curl
    wget
    vim
    tmux
    htop
    tree
    ripgrep
    fd-find
    ffmpeg
    7zip
    jq
    poppler-utils
    xclip
    direnv
    duf
    build-essential
    pkg-config
    libssl-dev
    ca-certificates
    gcc
    file
    unzip
    sysstat
  )
  $SUDO apt-get update
  $SUDO apt-get install -y \
    "${installlist[@]}"
  # fdfind to fd to ~/.local/bin/fd
  # Added to PATH in path.zsh
  # -sfn: force replace, treat target as file — safe if link already exists
  if command -v fdfind >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi

  # fzf install (requires curl/wget, installed above)
  if [ ! -d "$HOME/.fzf" ]; then
    echo "Installing fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all
  else
    echo "fzf already installed, updating"
    git -C "$HOME/.fzf" pull --ff-only || true
    "$HOME/.fzf/install" --all
  fi

  # vim-plug install
  if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    echo "Installing vim-plug"
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi

  # GitHub CLI install (requires wget, installed above)
  if ! command -v gh >/dev/null 2>&1; then
    (type -p wget >/dev/null || ($SUDO apt-get update && $SUDO apt-get install -y wget)) &&
      $SUDO mkdir -p -m 755 /etc/apt/keyrings &&
      out="$(mktemp)" && wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg &&
      $SUDO tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null <"$out" &&
      $SUDO chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg &&
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
      $SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
      $SUDO apt-get update &&
      $SUDO apt-get install -y gh
  else
    echo "gh already installed"
  fi

  # fish install (via official PPA, Ubuntu)
  if ! command -v fish >/dev/null 2>&1; then
    echo "Installing fish"
    $SUDO apt-get install -y software-properties-common
    $SUDO add-apt-repository -y ppa:fish-shell/release-4
    $SUDO apt-get update
    $SUDO apt-get install -y fish
  else
    echo "fish already installed"
  fi

else
  echo "Unsupported OS: $OS" >&2
  exit 1
fi

# uv install/update
if ! command -v uv >/dev/null 2>&1; then
  echo "Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
else
  echo "Updating uv"
  uv self update || true
fi

# oh-my-zsh install/update
OMZDIR="$HOME/.oh-my-zsh"
if [ ! -d "$OMZDIR" ]; then
  echo "Installing oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Updating oh-my-zsh"
  "$OMZDIR/tools/upgrade.sh" || true
fi

# zsh-autosuggestions install/update
PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
if [ -d "$PLUGIN_DIR/zsh-autosuggestions/.git" ]; then
  echo "Updating zsh-autosuggestions"
  git -C "$PLUGIN_DIR/zsh-autosuggestions" pull --ff-only
else
  echo "Installing zsh-autosuggestions"
  mkdir -p "$(dirname "$PLUGIN_DIR/zsh-autosuggestions")"
  git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
fi

# zsh-syntax-highlighting install/update
if [ -d "$PLUGIN_DIR/zsh-syntax-highlighting/.git" ]; then
  echo "Updating zsh-syntax-highlighting"
  git -C "$PLUGIN_DIR/zsh-syntax-highlighting" pull --ff-only
else
  echo "Installing zsh-syntax-highlighting"
  mkdir -p "$(dirname "$PLUGIN_DIR/zsh-syntax-highlighting")"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR/zsh-syntax-highlighting"
fi

# powerlevel10k install/update
THEME_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes"
if [ -d "$THEME_DIR/powerlevel10k/.git" ]; then
  echo "Updating powerlevel10k"
  git -C "$THEME_DIR/powerlevel10k" pull --ff-only
else
  echo "Installing powerlevel10k"
  mkdir -p "$THEME_DIR"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR/powerlevel10k"
fi
