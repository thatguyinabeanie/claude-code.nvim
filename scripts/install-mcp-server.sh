#!/usr/bin/env bash

# Install script for mcp-neovim-server
# Used by plugin managers during the build step

set -e

echo "Installing mcp-neovim-server for claude-code.nvim..."

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed. Please install Node.js/npm first."
    exit 1
fi

# Check if already installed
if command -v mcp-neovim-server &> /dev/null; then
    echo "mcp-neovim-server is already installed."
    exit 0
fi

# Install the package
echo "Running: npm install -g github:thatguyinabeanie/mcp-neovim-server"
npm install -g github:thatguyinabeanie/mcp-neovim-server

# Verify installation
if command -v mcp-neovim-server &> /dev/null; then
    echo "✓ Successfully installed mcp-neovim-server"
    exit 0
else
    echo "✗ Installation failed. Please try manually: npm install -g github:thatguyinabeanie/mcp-neovim-server"
    exit 1
fi