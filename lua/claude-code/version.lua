---@mod claude-code.version Version information for claude-code.nvim
---@brief [[
--- This module provides version information for claude-code.nvim.
---@brief ]]

local M = {}

--- @type string Plugin version following semantic versioning (x.y.z)
M.version = '0.2.0'

--- @type string Plugin name
M.name = 'claude-code.nvim'

--- Returns the current version of the plugin
--- @return string version Current version string
function M.get_version()
  return M.version
end

--- Prints the current version of the plugin
function M.print_version()
  vim.notify('Claude Code version: ' .. M.version, vim.log.levels.INFO)
end

return M
