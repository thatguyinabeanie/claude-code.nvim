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

# Create a simple runner script
cat > test_runner.lua << EOF
-- Test Runner script
local base_dir = vim.fn.getcwd()

-- Print debug info
print("Current working directory: " .. base_dir)
print("Plugin root: " .. base_dir)
print("Spec directory: " .. base_dir .. "/tests/spec")

-- Find test files
for _, file in ipairs(vim.fn.glob(base_dir .. "/tests/spec/*_spec.lua", false, true)) do
  print("Found test file: " .. file)
  dofile(file)
end

-- Exit with success
vim.cmd("qa!")
EOF

# Run tests with minimal Neovim configuration
$NVIM --headless --noplugin -u tests/minimal_init.lua -c "luafile test_runner.lua"

# Clean up
rm test_runner.lua

echo "Test run completed successfully"