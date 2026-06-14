#!/bin/bash
set -eo pipefail

NVM_VERSION="v0.40.3"

echo "==> Setting up Node.js via nvm"

# Always pin NVM_DIR to the user-local install. Without this, a system-wide nvm
# (e.g. a stray /usr/bin/nvm binary, or an inherited NVM_DIR pointing elsewhere)
# can shadow the real one and make this script behave unpredictably.
export NVM_DIR="$HOME/.nvm"

# Install only when our own copy is missing. Key off nvm.sh, not just the
# directory: a half-populated ~/.nvm (dir exists, script absent) would otherwise
# skip install and then fall through to whatever `nvm` happens to be on PATH.
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  echo "Installing nvm ${NVM_VERSION}..."
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
else
  echo "nvm already installed"
fi

# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# nvm is a shell function once sourced. If `nvm` resolves to anything else (a
# system binary like /usr/bin/nvm), bail out instead of driving the wrong tool.
if [ "$(command -v nvm 2>/dev/null)" != "nvm" ] || [ "$(type -t nvm 2>/dev/null)" != "function" ]; then
  echo "error: user-local nvm did not load from $NVM_DIR (a system nvm may be interfering)" >&2
  exit 1
fi

echo "==> Installing latest LTS Node.js"
nvm install --lts
nvm use --lts
nvm alias default "lts/*"

echo "==> Node versions"
node --version
npm --version

# Install globals into a shell- and version-independent prefix instead of the
# active nvm node's prefix. Both zsh (paths.zsh) and fish (config.fish) already
# put ~/.npm-global/bin on PATH, so CLIs land somewhere every shell can see them
# — fish in particular uses its own node (jorgebucaran/nvm.fish) and would never
# see packages installed into ~/.nvm. Passing --prefix per command (rather than
# setting it in ~/.npmrc) keeps nvm happy: nvm refuses to load with a global npm
# "prefix" configured.
NPM_GLOBAL="$HOME/.npm-global"
mkdir -p "$NPM_GLOBAL"

install_if_missing() {
  local pkg="$1"
  if ! npm list -g --prefix "$NPM_GLOBAL" --depth=0 2>/dev/null | grep -q " ${pkg}@"; then
    echo "Installing ${pkg}..."
    npm install -g --prefix "$NPM_GLOBAL" "$pkg"
  else
    echo "${pkg} already installed"
  fi
}

echo "==> Installing global npm packages"
install_if_missing "@google/gemini-cli"
install_if_missing "@openai/codex"
install_if_missing "@github/copilot"
# Installing claude with npm is deprecated use shell script instead
# Currently installing with other llm tools
curl -fsSL https://claude.ai/install.sh | bash

echo "==> Done"
