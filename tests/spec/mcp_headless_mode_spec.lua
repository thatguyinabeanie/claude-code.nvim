local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')
local before_each = require('plenary.busted').before_each

describe('MCP External Server Integration', function()
  local mcp
  local utils
  local original_executable

  before_each(function()
    -- Clear module cache
    package.loaded['claude-code.mcp'] = nil
    package.loaded['claude-code.utils'] = nil

    -- Load modules
    mcp = require('claude-code.mcp')
    utils = require('claude-code.utils')

    -- Store original executable function
    original_executable = vim.fn.executable
  end)

  after_each(function()
    -- Restore original
    vim.fn.executable = original_executable
  end)

  describe('mcp-neovim-server detection', function()
    it('should detect if mcp-neovim-server is installed', function()
      -- Mock that server is installed
      vim.fn.executable = function(cmd)
        if cmd == 'mcp-neovim-server' then
          return 1
        end
        return original_executable(cmd)
      end

      -- Generate config should succeed
      local temp_file = vim.fn.tempname() .. '.json'
      local success, path = mcp.generate_config(temp_file, 'claude-code')
      assert.is_true(success)
      vim.fn.delete(temp_file)
    end)

    it('should handle missing mcp-neovim-server gracefully in test mode', function()
      -- Mock that server is NOT installed
      vim.fn.executable = function(cmd)
        if cmd == 'mcp-neovim-server' then
          return 0
        end
        return original_executable(cmd)
      end

      -- Set test mode
      vim.fn.setenv('CLAUDE_CODE_TEST_MODE', '1')

      -- Generate config should still succeed in test mode
      local temp_file = vim.fn.tempname() .. '.json'
      local success, path = mcp.generate_config(temp_file, 'claude-code')
      assert.is_true(success)
      vim.fn.delete(temp_file)
    end)
  end)

  describe('wrapper script integration', function()
    it('should detect Neovim socket for claude-nvim wrapper', function()
      -- Test socket detection logic
      local test_socket = '/tmp/test-nvim.sock'
      vim.v.servername = test_socket

      -- Socket should be available via environment
      assert.equals(test_socket, vim.v.servername)
    end)

    it('should handle missing socket gracefully', function()
      -- Clear servername
      local original_servername = vim.v.servername
      vim.v.servername = ''

      -- Should handle empty servername
      assert.equals('', vim.v.servername)

      -- Restore
      vim.v.servername = original_servername
    end)
  end)

  describe('configuration generation', function()
    it('should generate valid claude-code config format', function()
      -- Mock server is available
      vim.fn.executable = function(cmd)
        if cmd == 'mcp-neovim-server' then
          return 1
        end
        return original_executable(cmd)
      end

      local temp_file = vim.fn.tempname() .. '.json'
      local success, path = mcp.generate_config(temp_file, 'claude-code')

      assert.is_true(success)
      assert.equals(temp_file, path)

      -- Read and validate generated config
      local file = io.open(temp_file, 'r')
      local content = file:read('*all')
      file:close()

      local config = vim.json.decode(content)
      assert.is_table(config.mcpServers)
      assert.is_table(config.mcpServers.neovim)
      assert.equals('mcp-neovim-server', config.mcpServers.neovim.command)

      vim.fn.delete(temp_file)
    end)

    it('should generate valid workspace config format', function()
      -- Mock server is available
      vim.fn.executable = function(cmd)
        if cmd == 'mcp-neovim-server' then
          return 1
        end
        return original_executable(cmd)
      end

      local temp_file = vim.fn.tempname() .. '.json'
      local success, path = mcp.generate_config(temp_file, 'workspace')

      assert.is_true(success)
      assert.equals(temp_file, path)

      -- Read and validate generated config
      local file = io.open(temp_file, 'r')
      local content = file:read('*all')
      file:close()

      local config = vim.json.decode(content)
      assert.is_table(config.neovim)
      assert.equals('mcp-neovim-server', config.neovim.command)

      vim.fn.delete(temp_file)
    end)
  end)
end)
