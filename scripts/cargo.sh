#!/bin/bash
set -euo pipefail

echo "==> Setting up Rust toolchain"

if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

export PATH="$HOME/.cargo/bin:$PATH"

rustup update stable
rustup default stable

echo "==> Rust versions"
rustc --version
cargo --version

echo "==> Installing cargo-update"
cargo install cargo-update --locked

echo "==> Updating installed Cargo packages only when needed"
cargo install-update -a

install_if_missing() {
  local crate="$1"
  if ! cargo install --list | grep -q "^${crate} "; then
    echo "Installing $crate..."
    cargo install "$crate" --locked
  else
    echo "$crate already installed"
  fi
}

echo "==> Ensuring required tools are installed"
install_if_missing zoxide
install_if_missing tree-sitter-cli
install_if_missing yazi-build
ya pkg install
ya pkg upgrade
# WARN: Not using them really much.
install_if_missing zellij
install_if_missing broot

echo "==> Done"
