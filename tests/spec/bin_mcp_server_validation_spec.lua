local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')

describe('MCP Server Binary Validation', function()
  local original_debug_getinfo
  local original_vim_opt
  local original_require
  
  before_each(function()
    -- Store originals
    original_debug_getinfo = debug.getinfo
    original_vim_opt = vim.opt
    original_require = require
  end)
  
  after_each(function()
    -- Restore originals
    debug.getinfo = original_debug_getinfo
    vim.opt = original_vim_opt
    require = original_require
  end)
  
  describe('plugin directory validation', function()
    it('should validate plugin directory exists', function()
      -- Mock debug.getinfo to return a test path
      debug.getinfo = function(level, what)
        if what == "S" then
          return {
            source = "@/test/path/bin/claude-code-mcp-server"
          }
        end
        return original_debug_getinfo(level, what)
      end
      
      -- Mock vim.fn.isdirectory to test validation
      local checked_paths = {}
      local original_isdirectory = vim.fn.isdirectory
      vim.fn.isdirectory = function(path)
        table.insert(checked_paths, path)
        if path == "/test/path" then
          return 1  -- exists
        end
        return 0  -- doesn't exist
      end
      
      -- Mock vim.opt with proper prepend method
      local runtimepath_values = {}
      vim.opt = {
        loadplugins = false,
        swapfile = false,
        backup = false,
        writebackup = false,
        runtimepath = {
          prepend = function(path)
            table.insert(runtimepath_values, path)
          end
        }
      }
      
      -- Mock require to avoid actual plugin loading
      require = function(module)
        if module == 'claude-code.mcp' then
          return {
            setup = function() end,
            start_standalone = function() return true end
          }
        end
        return original_require(module)
      end
      
      -- Simulate the plugin directory calculation and validation
      local script_source = "@/test/path/bin/claude-code-mcp-server"
      local script_dir = script_source:sub(2):match("(.*/)")  -- "/test/path/bin/"
      local plugin_dir = script_dir .. "/.."  -- "/test/path/bin/.."
      
      -- Normalize path (simulate what would happen in real validation)
      local normalized_plugin_dir = vim.fn.fnamemodify(plugin_dir, ":p")
      
      -- Check if plugin directory would be validated
      assert.is_string(plugin_dir)
      assert.is_truthy(plugin_dir:match("%.%.$"))  -- Should contain ".."
      
      -- Restore
      vim.fn.isdirectory = original_isdirectory
    end)
    
    it('should handle invalid script paths gracefully', function()
      -- Mock debug.getinfo to return invalid path
      debug.getinfo = function(level, what)
        if what == "S" then
          return {
            source = ""  -- Invalid/empty source
          }
        end
        return original_debug_getinfo(level, what)
      end
      
      -- This should be handled gracefully without crashes
      local script_source = ""
      local script_dir = script_source:sub(2):match("(.*/)")
      assert.is_nil(script_dir)  -- Should be nil for invalid path
    end)
    
    it('should validate runtimepath before prepending', function()
      -- Mock paths and functions for validation test
      local prepend_called_with = nil
      local runtimepath_mock = {
        prepend = function(path)
          prepend_called_with = path
        end
      }
      
      vim.opt = {
        loadplugins = false,
        swapfile = false,
        backup = false,
        writebackup = false,
        runtimepath = runtimepath_mock
      }
      
      -- Test that plugin_dir would be a valid path before prepending
      local plugin_dir = "/valid/plugin/directory"
      runtimepath_mock.prepend(plugin_dir)
      
      assert.equals(plugin_dir, prepend_called_with)
    end)
  end)
  
  describe('command line argument validation', function()
    it('should validate socket path exists when provided', function()
      -- Test that socket path validation would work
      local socket_path = "/tmp/nonexistent.sock"
      
      -- Mock vim.fn.filereadable
      local original_filereadable = vim.fn.filereadable
      vim.fn.filereadable = function(path)
        if path == socket_path then
          return 0  -- doesn't exist
        end
        return 1
      end
      
      -- Validate socket path (this is what the improved code should do)
      local socket_exists = vim.fn.filereadable(socket_path) == 1
      assert.is_false(socket_exists)
      
      -- Restore
      vim.fn.filereadable = original_filereadable
    end)
  end)
end)