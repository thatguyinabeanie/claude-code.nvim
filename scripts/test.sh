#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Change to the directory of this script
cd "$(dirname "$0")/.."

# Find nvim 
NVIM=${NVIM:-$(which nvim)}

if [ -z "$NVIM" ]; then
  echo "Error: nvim not found in PATH"
  exit 1
fi

echo "Running tests with $NVIM"

# Check if plenary.nvim is installed
PLENARY_DIR=~/.local/share/nvim/site/pack/vendor/start/plenary.nvim
if [ ! -d "$PLENARY_DIR" ]; then
  echo "Plenary.nvim not found at $PLENARY_DIR"
  echo "Installing plenary.nvim..."
  mkdir -p ~/.local/share/nvim/site/pack/vendor/start
  git clone --depth 1 https://github.com/nvim-lua/plenary.nvim "$PLENARY_DIR"
fi

# Run tests with nvim headless mode
$NVIM --headless --noplugin -u tests/minimal_init.lua -c "lua require('plenary.busted').run('./tests')" -c "qa!"

echo "Test run completed successfully"