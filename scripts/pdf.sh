#!/bin/bash
# PDF tooling: pandoc, poppler, a PDF viewer, a full TeX distribution and tdf.
# Ubuntu: zathura + texlive-full via apt.
# macOS:  Skim + MacTeX via Homebrew (zathura isn't in Homebrew core).
#         ~/.config/nvim (vimtex) picks skim on macOS, zathura elsewhere.

OS="$(uname)"

if [ "$OS" = "Linux" ]; then
  sudo apt update
  # Install pandoc and zathura for PDF viewing and conversion
  sudo apt install -y pandoc zathura poppler-utils
  # Install LaTeX for PDF generation
  # Note: This will install a large number of packages, so you may want to customize this based on your needs
  sudo apt install -y texlive-full

  # tdf build deps
  sudo apt update
  sudo apt install -y pkg-config libfontconfig1-dev

elif [ "$OS" = "Darwin" ]; then
  # brew may not be on PATH in the calling shell (see pre-install.sh).
  for __brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$__brew" ] && eval "$("$__brew" shellenv bash)" && break
  done
  unset __brew
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not installed. Run ./install (scripts/pre-install.sh) first." >&2
    exit 1
  fi

  # pandoc/poppler are also in the Brewfile; repeated here so this script is
  # self-contained.
  brew install pandoc poppler

  # Viewer: Skim (--adopt reuses a hand-installed /Applications/Skim.app).
  brew install --cask --adopt skim

  # Full TeX Live: MacTeX (~5 GB download). The .pkg installer asks for your
  # password. Binaries land in /Library/TeX/texbin, which zshrc / config.fish
  # add to PATH on macOS.
  brew install --cask mactex

  # tdf build deps (apt: pkg-config libfontconfig1-dev)
  brew install pkgconf fontconfig

else
  echo "Unsupported OS: $OS" >&2
  exit 1
fi

# Install tdf (both OSes)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
cargo install --git https://github.com/itsjunetime/tdf.git tdf-viewer
