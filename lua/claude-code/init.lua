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
local file_reference = require('claude-code.file_reference')

local M = {}

-- Private module storage (not exposed to users)
local _internal = {
  config = config,
  commands = commands,
  keymaps = keymaps,
  file_refresh = file_refresh,
  terminal = terminal,
  git = git,
  version = version,
  file_reference = file_reference,
}

--- Plugin configuration (merged from defaults and user input)
M.config = {}

-- Terminal buffer and window management
--- @type table
M.claude_code = _internal.terminal.terminal

--- Force insert mode when entering the Claude Code window
--- This is a public function used in keymaps
function M.force_insert_mode()
  _internal.terminal.force_insert_mode(M, M.config)
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
      if buf_name:match('term://.*claude') then
        return bufnr
      end
    end
  end
  return nil
end

--- Toggle the Claude Code terminal window
--- This is a public function used by commands
function M.toggle()
  _internal.terminal.toggle(M, M.config, _internal.git)

  -- Set up terminal navigation keymaps after toggling
  local bufnr = get_current_buffer_number()
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    _internal.keymaps.setup_terminal_navigation(M, M.config)
  end
end

--- Toggle the Claude Code terminal window with a specific command variant
--- @param variant_name string The name of the command variant to use
function M.toggle_with_variant(variant_name)
  if not variant_name or not M.config.command_variants[variant_name] then
    vim.notify('Invalid command variant: ' .. (variant_name or 'nil'), vim.log.levels.ERROR)
    return
  end

  _internal.terminal.toggle_with_variant(M, M.config, _internal.git, variant_name)

  -- Set up terminal navigation keymaps after toggling
  local bufnr = get_current_buffer_number()
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    _internal.keymaps.setup_terminal_navigation(M, M.config)
  end
end

--- Toggle the Claude Code terminal window with context awareness
--- @param context_type string|nil The context type ("file", "selection", "auto")
function M.toggle_with_context(context_type)
  _internal.terminal.toggle_with_context(M, M.config, _internal.git, context_type)

  -- Set up terminal navigation keymaps after toggling
  local bufnr = get_current_buffer_number()
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    _internal.keymaps.setup_terminal_navigation(M, M.config)
  end
end

--- Safe toggle that hides/shows Claude Code window without stopping execution
function M.safe_toggle()
  _internal.terminal.safe_toggle(M, M.config, _internal.git)

  -- Set up terminal navigation keymaps after toggling (if window is now visible)
  local bufnr = get_current_buffer_number()
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    _internal.keymaps.setup_terminal_navigation(M, M.config)
  end
end

--- Get process status for current or specified Claude Code instance
--- @param instance_id string|nil The instance identifier (uses current if nil)
--- @return table Process status information
function M.get_process_status(instance_id)
  return _internal.terminal.get_process_status(M, instance_id)
end

--- List all Claude Code instances and their states
--- @return table List of all instance states
function M.list_instances()
  return _internal.terminal.list_instances(M)
end

--- Setup function for the plugin
--- @param user_config table|nil Optional user configuration
function M.setup(user_config)
  -- Validate and merge configuration
  M.config = _internal.config.parse_config(user_config)

  -- Debug logging
  if not M.config then
    vim.notify('Config parsing failed!', vim.log.levels.ERROR)
    return
  end

  if not M.config.refresh then
    vim.notify('Config missing refresh settings!', vim.log.levels.ERROR)
    return
  end

  -- Set up commands and keymaps
  _internal.commands.register_commands(M)
  _internal.keymaps.register_keymaps(M, M.config)

  -- Initialize file refresh functionality
  _internal.file_refresh.setup(M, M.config)

  -- Initialize MCP server if enabled
  if M.config.mcp and M.config.mcp.enabled then
    local ok, mcp = pcall(require, 'claude-code.mcp')
    if ok and mcp and type(mcp.setup) == 'function' then
      mcp.setup(M.config)

      -- Initialize MCP Hub integration
      local hub_ok, hub = pcall(require, 'claude-code.mcp.hub')
      if hub_ok and hub and type(hub.setup) == 'function' then
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
        desc = 'Start Claude Code MCP server',
      })

      vim.api.nvim_create_user_command('ClaudeCodeMCPStop', function()
        mcp.stop()
      end, {
        desc = 'Stop Claude Code MCP server',
      })

      vim.api.nvim_create_user_command('ClaudeCodeMCPStatus', function()
        local status = mcp.status()

        local msg = string.format(
          'MCP Server: %s v%s\nInitialized: %s\nTools: %d\nResources: %d',
          status.name,
          status.version,
          status.initialized and 'Yes' or 'No',
          status.tool_count,
          status.resource_count
        )

        vim.notify(msg, vim.log.levels.INFO)
      end, {
        desc = 'Show Claude Code MCP server status',
      })

      vim.api.nvim_create_user_command('ClaudeCodeMCPConfig', function(opts)
        local args = vim.split(opts.args, '%s+')
        local config_type = args[1] or 'claude-code'
        local output_path = args[2]
        mcp.generate_config(output_path, config_type)
      end, {
        desc = 'Generate MCP configuration file (usage: :ClaudeCodeMCPConfig [claude-code|workspace|custom] [path])',
        nargs = '*',
        complete = function(ArgLead, CmdLine, CursorPos)
          if
            ArgLead == ''
            or not vim.tbl_contains(
              { 'claude-code', 'workspace', 'custom' },
              ArgLead:sub(1, #ArgLead)
            )
          then
            return { 'claude-code', 'workspace', 'custom' }
          end
          return {}
        end,
      })

      vim.api.nvim_create_user_command('ClaudeCodeSetup', function(opts)
        local config_type = opts.args ~= '' and opts.args or 'claude-code'
        mcp.setup_claude_integration(config_type)
      end, {
        desc = 'Setup MCP integration (usage: :ClaudeCodeSetup [claude-code|workspace])',
        nargs = '?',
        complete = function()
          return { 'claude-code', 'workspace' }
        end,
      })
    elseif not ok then
      -- MCP module failed to load, but don't error out in tests
      if
        not (os.getenv('CI') or os.getenv('GITHUB_ACTIONS') or os.getenv('CLAUDE_CODE_TEST_MODE'))
      then
        vim.notify('MCP module failed to load: ' .. tostring(mcp), vim.log.levels.WARN)
      end
    else
      vim.notify('MCP module not available', vim.log.levels.WARN)
    end
  end

  -- Setup keymap for file reference shortcut
  vim.keymap.set(
    { 'n', 'v' },
    '<leader>cf',
    _internal.file_reference.insert_file_reference,
    { desc = 'Insert @File#L1-99 reference for Claude prompt' }
  )

  -- Auto-start Neovim server socket for MCP connection
  if M.config.mcp and M.config.mcp.enabled and M.config.mcp.auto_server_start ~= false then
    local server_socket = vim.fn.expand('~/.cache/nvim/claude-code-' .. vim.fn.getpid() .. '.sock')
    
    -- Check if we're already listening on a socket
    if not vim.v.servername or vim.v.servername == '' then
      -- Start server socket
      pcall(vim.fn.serverstart, server_socket)
      
      -- Set environment variable for MCP server to find us
      vim.fn.setenv('NVIM', server_socket)
      
      -- Clean up socket on exit
      vim.api.nvim_create_autocmd('VimLeavePre', {
        callback = function()
          pcall(vim.fn.delete, server_socket)
        end,
        desc = 'Clean up Claude Code server socket',
      })
      
      if M.config.startup_notification and M.config.startup_notification.enabled then
        vim.notify('Claude Code: Server socket started at ' .. server_socket, vim.log.levels.DEBUG)
      end
    else
      -- Already have a server, just set the environment variable
      vim.fn.setenv('NVIM', vim.v.servername)
    end
  end

  -- Show configurable startup notification
  if M.config.startup_notification and M.config.startup_notification.enabled then
    vim.notify(M.config.startup_notification.message, M.config.startup_notification.level)
  end
end

--- Get the current plugin configuration
--- @return table The current configuration
function M.get_config()
  return M.config
end

--- Get the current plugin version
--- @return string The version string
function M.get_version()
  return _internal.version.string()
end

--- Get the current plugin version (alias for compatibility)
--- @return string The version string
function M.version()
  return _internal.version.string()
end

--- Get the current prompt input buffer content, or an empty string if not available
--- @return string The current prompt input buffer content
function M.get_prompt_input()
  -- Stub for test: return last inserted text or command line
  -- In real plugin, this should return the current prompt input buffer content
  return vim.fn.getcmdline() or ''
end

-- Lazy.nvim integration
M.lazy = true -- Mark as lazy-loadable

return M
