#!/bin/bash
set -e

NVIM_URL="https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.appimage"

# Optional sudo: use sudo only when not root and sudo is available
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

# Check if Neovim exists
if command -v nvim &>/dev/null; then
  echo "Neovim detected. Updating..."
else
  echo "Neovim not found. Installing..."
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo "Installing Neovim (Linux AppImage)..."

  curl -L "$NVIM_URL" -o /tmp/nvim.appimage
  chmod +x /tmp/nvim.appimage
  cd /tmp

  if ./nvim.appimage --version >/dev/null 2>&1; then
    echo "FUSE available; installing AppImage directly."
    $SUDO mv ./nvim.appimage /opt/nvim.appimage
    $SUDO ln -sf /opt/nvim.appimage /usr/local/bin/nvim
  else
    echo "FUSE unavailable; falling back to --appimage-extract."
    ./nvim.appimage --appimage-extract >/dev/null
    $SUDO rm -rf /opt/nvim-squashfs
    $SUDO mv ./squashfs-root /opt/nvim-squashfs
    $SUDO ln -sf /opt/nvim-squashfs/AppRun /usr/local/bin/nvim
  fi
  cd -

  echo "Neovim installed/updated successfully."

elif [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Installing/Updating Neovim via Homebrew..."

  if command -v brew &>/dev/null; then
    brew update
    brew install neovim || brew upgrade neovim
  else
    echo "Homebrew not installed. Please install Homebrew first."
    exit 1
  fi

else
  echo "Unsupported OS. Install Neovim manually."
  exit 1
fi

echo "Done. Current version:"
nvim --version | head -n 1
