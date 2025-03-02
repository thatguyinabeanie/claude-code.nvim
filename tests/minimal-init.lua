-- Minimal configuration for testing the Claude Code plugin
-- Used for bug reproduction and testing

-- Detect the plugin directory (works whether run from plugin root or a different directory)
local function get_plugin_path()
  local debug_info = debug.getinfo(1, 'S')
  local source = debug_info.source

  if string.sub(source, 1, 1) == '@' then
    source = string.sub(source, 2)
    -- If we're running directly from the plugin
    if string.find(source, '/tests/minimal-init%.lua$') then
      local plugin_dir = string.gsub(source, '/tests/minimal-init%.lua$', '')
      return plugin_dir
    else
      -- For a copied version, assume it's run directly from the dir it's in
      return vim.fn.getcwd()
    end
  end
  return vim.fn.getcwd()
end

local plugin_dir = get_plugin_path()
print('Plugin directory: ' .. plugin_dir)

-- Basic settings
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = false
vim.opt.hidden = true
vim.opt.termguicolors = true

-- Add the plugin directory to runtimepath
vim.opt.runtimepath:append(plugin_dir)

-- Add Plenary to the runtime path (for tests)
local plenary_path = vim.fn.expand('~/.local/share/nvim/site/pack/vendor/start/plenary.nvim')
vim.opt.runtimepath:append(plenary_path)

-- Make sure plenary plugins are loaded first
local ok, _ = pcall(require, 'plenary')
if not ok then
  print('❌ Error: plenary.nvim not found. Tests will fail!')
end

-- Load plenary test libraries
pcall(require, 'plenary.async')
pcall(require, 'plenary.busted')

-- Print current runtime path for debugging
print('Runtime path: ' .. vim.o.runtimepath)

-- Load the plugin
local status_ok, claude_code = pcall(require, 'claude-code')
if status_ok then
  print('✓ Successfully loaded Claude Code plugin')

  -- First create a validated config (in silent mode)
  local config_module = require('claude-code.config')
  local test_config = config_module.parse_config({
    window = {
      height_ratio = 0.3,
      position = 'botright',
      enter_insert = true,
      hide_numbers = true,
      hide_signcolumn = true,
    },
    -- Disable keymaps for testing
    keymaps = {
      toggle = {
        normal = false,
        terminal = false,
      },
      window_navigation = false,
      scrolling = false,
    },
    -- Additional required config sections
    refresh = {
      enable = true,
      updatetime = 1000,
      timer_interval = 1000,
      show_notifications = false,
    },
    git = {
      use_git_root = true,
    },
  }, true) -- Use silent mode for tests

  -- Print available commands for user reference
  print('\nAvailable Commands:')
  print('  :ClaudeCode             - Start a new Claude Code session')
  print('  :ClaudeCodeToggle       - Toggle the Claude Code terminal')
  print('  :ClaudeCodeRestart      - Restart the Claude Code session')
  print('  :ClaudeCodeSuspend      - Suspend the current Claude Code session')
  print('  :ClaudeCodeResume       - Resume the suspended Claude Code session')
  print('  :ClaudeCodeQuit         - Quit the current Claude Code session')
  print('  :ClaudeCodeRefreshFiles - Refresh the current working directory information')
else
  print('✗ Failed to load Claude Code plugin: ' .. tostring(claude_code))
end

-- Set up minimal UI elements
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'

print('\nClaude Code minimal test environment loaded.')
print('- Type :messages to see any error messages')
print("- Try ':ClaudeCode' to start a new session")
