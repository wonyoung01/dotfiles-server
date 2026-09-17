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

uninstall_if_present() {
  local crate="$1"
  if cargo install --list | grep -q "^${crate} "; then
    echo "Removing cargo-installed $crate (now installed elsewhere)"
    cargo uninstall "$crate"
  fi
}

# yazi moved to scripts/pre-install.sh (brew on macOS, apt repo on Ubuntu).
# Drop the old cargo build so it stops shadowing the system binary on PATH.
uninstall_if_present yazi-build

if [ "$(uname)" = "Darwin" ]; then
  # These come from brew on macOS (Brewfile). ~/.cargo/bin is first on PATH,
  # so remove any old cargo builds that would shadow the brew binaries.
  echo "==> macOS: zoxide/tree-sitter/zellij/broot come from brew, skipping cargo"
  uninstall_if_present zoxide
  uninstall_if_present tree-sitter-cli
  uninstall_if_present zellij
  uninstall_if_present broot
else
  echo "==> Ensuring required tools are installed"
  install_if_missing zoxide
  install_if_missing tree-sitter-cli
  # WARN: Not using them really much.
  install_if_missing zellij
  install_if_missing broot
fi

echo "==> Done"
