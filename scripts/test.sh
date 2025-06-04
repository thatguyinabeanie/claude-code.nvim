#!/bin/bash
set -euo pipefail -x  # Exit on errors, unset variables, pipe failures, and enable verbose logging

# Get the plugin directory from the script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Switch to the plugin directory
echo "Changing to plugin directory: $PLUGIN_DIR"
cd "$PLUGIN_DIR"

# Print current directory for debugging
echo "Running tests from: $(pwd)"

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

# Run tests with minimal Neovim configuration and add a timeout
# Timeout after 300 seconds to prevent hanging in CI (increased for complex tests)
echo "Running tests with a 300 second timeout..."
echo "Command: timeout --foreground 300 $NVIM --headless --noplugin -u tests/minimal-init.lua -c 'luafile tests/run_tests.lua'"
timeout --foreground 300 "$NVIM" --headless --noplugin -u tests/minimal-init.lua -c "luafile tests/run_tests.lua"
EXIT_CODE=$?

# Check exit code
if [ $EXIT_CODE -eq 124 ]; then
  echo "Error: Test execution timed out after 300 seconds"
  exit 1
elif [ $EXIT_CODE -ne 0 ]; then
  echo "Error: Tests failed with exit code $EXIT_CODE"
  exit $EXIT_CODE
else
  echo "Test run completed successfully"
fi