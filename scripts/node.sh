#!/bin/bash
set -eo pipefail

NVM_VERSION="v0.40.3"

echo "==> Setting up Node.js via nvm"

if [ ! -d "$HOME/.nvm" ]; then
  echo "Installing nvm ${NVM_VERSION}..."
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
else
  echo "nvm already installed"
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "==> Installing latest LTS Node.js"
nvm install --lts
nvm use --lts
nvm alias default "lts/*"

echo "==> Node versions"
node --version
npm --version

install_if_missing() {
  local pkg="$1"
  if ! npm list -g --depth=0 2>/dev/null | grep -q " ${pkg}@"; then
    echo "Installing ${pkg}..."
    npm install -g "$pkg"
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
