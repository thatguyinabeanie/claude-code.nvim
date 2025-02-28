-- Tests for the git module
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

local git = require('claude-code.git')

describe('git', function()
  describe('get_git_root', function()
    it('should handle io.popen errors gracefully', function()
      -- Save the original io.popen
      local original_popen = io.popen
      
      -- Replace io.popen with a mock that returns nil
      io.popen = function()
        return nil
      end
      
      -- Call the function and check that it returns nil
      local result = git.get_git_root()
      assert.is_nil(result)
      
      -- Restore the original io.popen
      io.popen = original_popen
    end)
    
    it('should handle non-git directories', function()
      -- Save the original io.popen
      local original_popen = io.popen
      
      -- Mock io.popen to simulate a non-git directory
      local mock_called = 0
      io.popen = function(cmd)
        mock_called = mock_called + 1
        
        -- Return a file handle that returns "false" for the first call
        return {
          read = function()
            return "false"
          end,
          close = function() end
        }
      end
      
      -- Call the function and check that it returns nil
      local result = git.get_git_root()
      assert.is_nil(result)
      assert.are.equal(1, mock_called, "io.popen should be called exactly once")
      
      -- Restore the original io.popen
      io.popen = original_popen
    end)
    
    it('should extract git root in a git directory', function()
      -- Save the original io.popen
      local original_popen = io.popen
      
      -- Mock io.popen to simulate a git directory
      local mock_called = 0
      io.popen = function(cmd)
        mock_called = mock_called + 1
        
        if cmd:match("rev%-parse %-%-%is%-inside%-work%-tree") then
          -- First call checks if we're in a git repo
          return {
            read = function()
              return "true\n"
            end,
            close = function() end
          }
        elseif cmd:match("rev%-parse %-%-%show%-toplevel") then
          -- Second call gets the git root
          return {
            read = function()
              return "/home/user/project\n"
            end,
            close = function() end
          }
        end
        
        return nil
      end
      
      -- Call the function and check the result
      local result = git.get_git_root()
      assert.are.equal("/home/user/project", result)
      assert.are.equal(2, mock_called, "io.popen should be called exactly twice")
      
      -- Restore the original io.popen
      io.popen = original_popen
    end)
  end)
end)