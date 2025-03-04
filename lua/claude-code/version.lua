---@mod claude-code.version Version information for claude-code.nvim
---@brief [[
--- This module provides version information for claude-code.nvim.
---@brief ]]

--- @table M
--- Version information for Claude Code
--- @field major number Major version (breaking changes)
--- @field minor number Minor version (new features)
--- @field patch number Patch version (bug fixes)
--- @field string function Returns formatted version string

local M = {
  major = 0,
  minor = 4,
  patch = 2,
}

--- Returns the formatted version string
--- @return string Version string in format "major.minor.patch"
function M.string()
  return string.format('%d.%d.%d', M.major, M.minor, M.patch)
end

--- Prints the current version of the plugin
function M.print_version()
  vim.notify('Claude Code version: ' .. M.string(), vim.log.levels.INFO)
end

return M
