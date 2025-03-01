#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# If we're in the tests directory, go up one level
if [ "$(basename "$(pwd)")" = "tests" ]; then
  cd ..
elif [ "$(basename "$(pwd)")" = "scripts" ]; then
  # If we're in the scripts directory, go up one level
  cd ..
fi

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
# Timeout after 60 seconds to prevent hanging in CI
echo "Running tests with a 60 second timeout..."
timeout 60 $NVIM --headless --noplugin -u tests/minimal_init.lua -c "luafile tests/run_tests.lua"

# Check exit code
EXIT_CODE=$?
if [ $EXIT_CODE -eq 124 ]; then
  echo "Error: Test execution timed out after 60 seconds"
  exit 1
elif [ $EXIT_CODE -ne 0 ]; then
  echo "Error: Tests failed with exit code $EXIT_CODE"
  exit $EXIT_CODE
else
  echo "Test run completed successfully"
fi