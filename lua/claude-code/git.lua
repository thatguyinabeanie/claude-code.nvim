---@mod claude-code.git Git integration for claude-code.nvim
---@brief [[
--- This module provides git integration functionality for claude-code.nvim.
--- It detects git repositories and can set the working directory to the git root.
---@brief ]]

local M = {}

--- Helper function to get git root directory
--- @return string|nil git_root The git root directory path or nil if not in a git repo
function M.get_git_root()
  -- Check if we're in a git repository
  local handle = io.popen 'git rev-parse --is-inside-work-tree 2>/dev/null'
  if not handle then
    return nil
  end

  local result = handle:read '*a'
  handle:close()

  if result:match 'true' then
    -- Get the git root path
    local root_handle = io.popen 'git rev-parse --show-toplevel 2>/dev/null'
    if not root_handle then
      return nil
    end

    local git_root = root_handle:read('*a'):gsub('%s+$', '')
    root_handle:close()

    return git_root
  end

  return nil
end

return M
