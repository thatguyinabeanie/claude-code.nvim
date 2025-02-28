---@mod claude-code.commands Command registration for claude-code.nvim
---@brief [[
--- This module provides command registration and handling for claude-code.nvim.
--- It defines user commands and command handlers.
---@brief ]]

local M = {}

--- @type table<string, function> List of available commands and their handlers
M.commands = {}

--- Register commands for the claude-code plugin
--- @param claude_code table The main plugin module
function M.register_commands(claude_code)
  -- Create the user command for toggling Claude Code
  vim.api.nvim_create_user_command('ClaudeCode', function()
    claude_code.toggle()
  end, { desc = 'Toggle Claude Code terminal' })
  
  -- Add version command
  vim.api.nvim_create_user_command('ClaudeCodeVersion', function()
    vim.notify('Claude Code version: ' .. claude_code.version(), vim.log.levels.INFO)
  end, { desc = 'Display Claude Code version' })
end

return M