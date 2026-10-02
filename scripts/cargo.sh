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

# cargo-binstall fetches prebuilt release binaries instead of compiling;
# it only falls back to building from source when none exist.
echo "==> Setting up cargo-binstall"
if ! command -v cargo-binstall >/dev/null 2>&1; then
  curl -L --proto '=https' --tlsv1.2 -sSf \
    https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
else
  cargo binstall -y cargo-binstall
fi

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
# Replaced by cargo-binstall, which skips up-to-date crates and upgrades the rest.
uninstall_if_present cargo-update

if [ "$(uname)" = "Darwin" ]; then
  # These come from brew on macOS (Brewfile). ~/.cargo/bin is first on PATH,
  # so remove any old cargo builds that would shadow the brew binaries.
  echo "==> macOS: zoxide/tree-sitter/zellij/broot come from brew, skipping cargo"
  uninstall_if_present zoxide
  uninstall_if_present tree-sitter-cli
  uninstall_if_present zellij
  uninstall_if_present broot
else
  # Installs missing crates, upgrades outdated ones, skips the rest.
  echo "==> Installing/updating tools (prebuilt binaries)"
  # WARN: Not using zellij/broot really much.
  cargo binstall -y --locked zoxide tree-sitter-cli zellij broot
fi

echo "==> Done"
