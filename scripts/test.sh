#!/bin/bash

# Change to the directory of this script
cd "$(dirname "$0")/.."

# Find nvim 
NVIM=${NVIM:-$(which nvim)}

if [ -z "$NVIM" ]; then
  echo "Error: nvim not found in PATH"
  exit 1
fi

echo "Running tests with $NVIM"

# Run tests with nvim headless mode
$NVIM --headless --noplugin -u tests/minimal_init.lua -c "lua require('plenary.busted').run('./tests')" -c "qa!"