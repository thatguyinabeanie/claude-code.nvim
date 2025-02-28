---@mod claude-code Claude Code Neovim Integration
---@brief [[
--- A plugin for seamless integration between Claude Code AI assistant and Neovim.
--- This plugin provides a terminal-based interface to Claude Code within Neovim.
--- 
--- Requirements:
--- - Neovim 0.7.0 or later
--- - Claude Code CLI tool installed and available in PATH
--- - plenary.nvim (dependency for git operations)
---
--- Usage:
--- ```lua
--- require('claude-code').setup({
---   -- Configuration options (optional)
--- })
--- ```
---@brief ]]

-- Import modules
local config = require('claude-code.config')
local commands = require('claude-code.commands')
local keymaps = require('claude-code.keymaps')
local file_refresh = require('claude-code.file_refresh')
local terminal = require('claude-code.terminal')
local git = require('claude-code.git')
local version = require('claude-code.version')

local M = {}

-- Store the current configuration
--- @type table
M.config = {}

-- Terminal buffer and window management
--- @type table
M.claude_code = terminal.terminal

--- Force insert mode when entering the Claude Code window
--- This is a public function used in keymaps
function M.force_insert_mode()
  terminal.force_insert_mode(M)
end

--- Toggle the Claude Code terminal window
--- This is a public function used by commands
function M.toggle()
  terminal.toggle(M, M.config, git)
  
  -- Set up terminal navigation keymaps after toggling
  if M.claude_code.bufnr and vim.api.nvim_buf_is_valid(M.claude_code.bufnr) then
    keymaps.setup_terminal_navigation(M, M.config)
  end
end

--- Get the current version of the plugin
--- @return string version Current version string
function M.version()
  return version.get_version()
end

--- Setup function for the plugin
--- @param user_config? table User configuration table (optional)
function M.setup(user_config)
  -- Parse and validate configuration
  M.config = config.parse_config(user_config)
  
  -- Set up autoread option
  vim.o.autoread = true
  
  -- Set up file refresh functionality
  file_refresh.setup(M, M.config)
  
  -- Register commands
  commands.register_commands(M)
  
  -- Register keymaps
  keymaps.register_keymaps(M, M.config)
end

return M