-- Tests for the version module
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local version = require('claude-code.version')

describe('version', function()
  describe('get_version', function()
    it('should return the correct version string', function()
      local result = version.get_version()
      assert.are.equal('0.2.0', result)
      assert.are.equal(version.version, result)
    end)
  end)
  
  describe('version constant', function()
    it('should follow semantic versioning format', function()
      -- Check that version matches the pattern x.y.z
      -- where x, y, z are numbers
      local major, minor, patch = version.version:match("^(%d+)%.(%d+)%.(%d+)$")
      
      assert.is_not_nil(major, "Major version should be a number")
      assert.is_not_nil(minor, "Minor version should be a number")
      assert.is_not_nil(patch, "Patch version should be a number")
    end)
  end)
  
  describe('print_version', function()
    it('should call vim.notify with correct message', function()
      -- Save original vim.notify
      local original_notify = vim.notify
      
      -- Create a mock for vim.notify
      local was_called = false
      local message_received = nil
      local level_received = nil
      
      vim.notify = function(msg, level)
        was_called = true
        message_received = msg
        level_received = level
      end
      
      -- Call the function
      version.print_version()
      
      -- Restore original vim.notify
      vim.notify = original_notify
      
      -- Check if vim.notify was called with correct parameters
      assert.is_true(was_called, "vim.notify should have been called")
      assert.are.equal("Claude Code version: " .. version.version, message_received)
      assert.are.equal(vim.log.levels.INFO, level_received)
    end)
  end)
end)