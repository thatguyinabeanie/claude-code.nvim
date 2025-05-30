---@mod claude-code Claude Code Neovim Integration
---@brief [[
--- A plugin for seamless integration between Claude Code AI assistant and Neovim.
--- This plugin provides both a terminal-based interface and MCP server for Claude Code within Neovim.
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

-- Make imported modules available
M._config = config
M.commands = commands
M.keymaps = keymaps
M.file_refresh = file_refresh
M.terminal = terminal
M.git = git
M.version = version

--- Plugin configuration (merged from defaults and user input)
M.config = {}

-- Terminal buffer and window management
--- @type table
M.claude_code = terminal.terminal

--- Force insert mode when entering the Claude Code window
--- This is a public function used in keymaps
function M.force_insert_mode()
  terminal.force_insert_mode(M, M.config)
end

--- Check if a buffer is a valid Claude Code terminal buffer
--- @return number|nil buffer number if valid, nil otherwise
local function get_current_buffer_number()
  -- Get all buffers
  local buffers = vim.api.nvim_list_bufs()
  
  for _, bufnr in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local buf_name = vim.api.nvim_buf_get_name(bufnr)
      -- Check if this buffer name contains the Claude Code identifier
      if buf_name:match("term://.*claude") then
        return bufnr
      end
    end
  end
  return nil
end

--- Toggle the Claude Code terminal window
--- This is a public function used by commands
function M.toggle()
  terminal.toggle(M, M.config, git)

  -- Set up terminal navigation keymaps after toggling
  local bufnr = get_current_buffer_number()
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    keymaps.setup_terminal_navigation(M, M.config)
  end
end

--- Toggle the Claude Code terminal window with a specific command variant
--- @param variant_name string The name of the command variant to use
function M.toggle_with_variant(variant_name)
  if not variant_name or not M.config.command_variants[variant_name] then
    vim.notify("Invalid command variant: " .. (variant_name or "nil"), vim.log.levels.ERROR)
    return
  end

  terminal.toggle_with_variant(M, M.config, git, variant_name)

  -- Set up terminal navigation keymaps after toggling
  local bufnr = get_current_buffer_number()
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    keymaps.setup_terminal_navigation(M, M.config)
  end
end

--- Toggle the Claude Code terminal window with context awareness
--- @param context_type string|nil The context type ("file", "selection", "auto")
function M.toggle_with_context(context_type)
  terminal.toggle_with_context(M, M.config, git, context_type)

  -- Set up terminal navigation keymaps after toggling
  local bufnr = get_current_buffer_number()
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    keymaps.setup_terminal_navigation(M, M.config)
  end
end

--- Setup function for the plugin
--- @param user_config table|nil Optional user configuration
function M.setup(user_config)
  -- Validate and merge configuration
  M.config = M._config.parse_config(user_config)
  
  -- Debug logging
  if not M.config then
    vim.notify("Config parsing failed!", vim.log.levels.ERROR)
    return
  end
  
  if not M.config.refresh then
    vim.notify("Config missing refresh settings!", vim.log.levels.ERROR)
    return
  end
  
  -- Set up commands and keymaps
  commands.register_commands(M)
  keymaps.register_keymaps(M, M.config)

  -- Initialize file refresh functionality
  file_refresh.setup(M, M.config)

  -- Initialize MCP server if enabled
  if M.config.mcp and M.config.mcp.enabled then
    local ok, mcp = pcall(require, 'claude-code.mcp')
    if ok then
      mcp.setup()
      
      -- Initialize MCP Hub integration
      local hub_ok, hub = pcall(require, 'claude-code.mcp.hub')
      if hub_ok then
        hub.setup()
      end
      
      -- Auto-start if configured
      if M.config.mcp.auto_start then
        mcp.start()
      end
      
      -- Create MCP-specific commands
      vim.api.nvim_create_user_command('ClaudeCodeMCPStart', function()
        mcp.start()
      end, {
        desc = 'Start Claude Code MCP server'
      })
      
      vim.api.nvim_create_user_command('ClaudeCodeMCPStop', function()
        mcp.stop()
      end, {
        desc = 'Stop Claude Code MCP server'
      })
      
      vim.api.nvim_create_user_command('ClaudeCodeMCPStatus', function()
        local status = mcp.status()
        
        local msg = string.format(
          "MCP Server: %s v%s\nInitialized: %s\nTools: %d\nResources: %d",
          status.name,
          status.version,
          status.initialized and "Yes" or "No",
          status.tool_count,
          status.resource_count
        )
        
        vim.notify(msg, vim.log.levels.INFO)
      end, {
        desc = 'Show Claude Code MCP server status'
      })
      
      vim.api.nvim_create_user_command('ClaudeCodeMCPConfig', function(opts)
        local args = vim.split(opts.args, "%s+")
        local config_type = args[1] or "claude-code"
        local output_path = args[2]
        mcp.generate_config(output_path, config_type)
      end, {
        desc = 'Generate MCP configuration file (usage: :ClaudeCodeMCPConfig [claude-code|workspace|custom] [path])',
        nargs = '*',
        complete = function(ArgLead, CmdLine, CursorPos)
          if ArgLead == "" or not vim.tbl_contains({"claude-code", "workspace", "custom"}, ArgLead:sub(1, #ArgLead)) then
            return {"claude-code", "workspace", "custom"}
          end
          return {}
        end
      })
      
      vim.api.nvim_create_user_command('ClaudeCodeSetup', function(opts)
        local config_type = opts.args ~= "" and opts.args or "claude-code"
        mcp.setup_claude_integration(config_type)
      end, {
        desc = 'Setup MCP integration (usage: :ClaudeCodeSetup [claude-code|workspace])',
        nargs = '?',
        complete = function()
          return {"claude-code", "workspace"}
        end
      })
    else
      vim.notify("MCP module not available", vim.log.levels.WARN)
    end
  end

  vim.notify("Claude Code plugin loaded", vim.log.levels.INFO)
end

--- Get the current plugin configuration
--- @return table The current configuration
function M.get_config()
  return M.config
end

--- Get the current plugin version
--- @return string The version string
function M.get_version()
  return version.string()
end

--- Get the current plugin version (alias for compatibility)
--- @return string The version string
function M.version()
  return version.string()
end

return M