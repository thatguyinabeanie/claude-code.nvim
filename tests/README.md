# Tests for claude-code.nvim

This directory contains the test suite for claude-code.nvim.

## Structure

- `minimal_init.lua`: Minimal Neovim configuration to run tests
- `spec/`: Directory containing test files
  - All test files must end with `_spec.lua`

## Running Tests

Run all tests using:

```bash
./scripts/test.sh
```

Tests use the [plenary.busted](https://github.com/nvim-lua/plenary.nvim) framework.

## Writing Tests

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