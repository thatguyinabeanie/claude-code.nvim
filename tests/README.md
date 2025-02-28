# Claude Code Manual Testing

This directory contains resources for testing the Claude Code plugin.

## Overview

There are two main components:

1. **Automated Tests**: Unit and integration tests using the Plenary test framework.
2. **Manual Testing**: A minimal configuration for reproducing issues and testing features.

## Minimal Test Configuration

The `minimal_init.lua` file provides a minimal Neovim configuration for testing the Claude Code plugin in isolation. This is useful for:

1. Reproducing and debugging issues
2. Testing new features in a clean environment
3. Providing minimal reproducible examples when reporting bugs

## Usage

### Option 1: Run directly from the plugin directory

```bash
# From the plugin root directory
nvim --clean -u tests/minimal_init.lua
```

### Option 2: Copy to a separate directory for testing

```bash
# Create a test directory
mkdir ~/claude-test
cp tests/minimal_init.lua ~/claude-test/
cd ~/claude-test

# Run Neovim with the minimal config
nvim --clean -u minimal_init.lua
```

## Automated Tests

The `spec/` directory contains automated tests for the plugin using the [plenary.busted](https://github.com/nvim-lua/plenary.nvim) framework.

### Running Tests

Run all automated tests using:

```bash
./scripts/test.sh
```

### Writing Tests

Test files should follow the plenary.busted structure:

```lua
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

describe('module_name', function()
  describe('function_name', function()
    it('should do something', function()
      -- Test code here
      assert.are.equal(expected, actual)
    end)
  end)
end)
```

## Troubleshooting

The minimal configuration:
- Attempts to auto-detect the plugin directory
- Sets up basic Neovim settings (no swap files, etc.)
- Prints available commands for reference
- Shows line numbers and sign column

To see error messages:
```
:messages
```

## Reporting Issues

When reporting issues, please include the following information:
1. Steps to reproduce the issue using this minimal config
2. Any error messages from `:messages`
3. The exact Neovim and Claude Code plugin versions