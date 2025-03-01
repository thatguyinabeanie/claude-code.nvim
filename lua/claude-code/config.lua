---@mod claude-code.config Configuration management for claude-code.nvim
---@brief [[
--- This module handles configuration management and validation for claude-code.nvim.
--- It provides the default configuration, validation, and merging of user config.
---@brief ]]

local M = {}

--- ClaudeCodeWindow class for window configuration
-- @table ClaudeCodeWindow
-- @field height_ratio number Percentage of screen height for the terminal window
-- @field position string Position of the window: "botright", "topleft", "vertical", etc.
-- @field enter_insert boolean Whether to enter insert mode when opening Claude Code
-- @field hide_numbers boolean Hide line numbers in the terminal window
-- @field hide_signcolumn boolean Hide the sign column in the terminal window

--- ClaudeCodeRefresh class for file refresh configuration
-- @table ClaudeCodeRefresh
-- @field enable boolean Enable file change detection
-- @field updatetime number updatetime when Claude Code is active (milliseconds)
-- @field timer_interval number How often to check for file changes (milliseconds)
-- @field show_notifications boolean Show notification when files are reloaded

--- ClaudeCodeGit class for git integration configuration
-- @table ClaudeCodeGit
-- @field use_git_root boolean Set CWD to git root when opening Claude Code (if in git project)

--- ClaudeCodeKeymapsToggle class for toggle keymap configuration
-- @table ClaudeCodeKeymapsToggle
-- @field normal string|boolean Normal mode keymap for toggling Claude Code, false to disable
-- @field terminal string|boolean Terminal mode keymap for toggling Claude Code, false to disable

--- ClaudeCodeKeymaps class for keymap configuration
-- @table ClaudeCodeKeymaps
-- @field toggle ClaudeCodeKeymapsToggle Keymaps for toggling Claude Code
-- @field window_navigation boolean Enable window navigation keymaps
-- @field scrolling boolean Enable scrolling keymaps

--- ClaudeCodeConfig class for main configuration
-- @table ClaudeCodeConfig
-- @field window ClaudeCodeWindow Terminal window settings
-- @field refresh ClaudeCodeRefresh File refresh settings
-- @field git ClaudeCodeGit Git integration settings
-- @field keymaps ClaudeCodeKeymaps Keymaps configuration

--- Default configuration options
--- @type ClaudeCodeConfig
M.default_config = {
  -- Terminal window settings
  window = {
    height_ratio = 0.3, -- Percentage of screen height for the terminal window
    position = 'botright', -- Position of the window: "botright", "topleft", "vertical", etc.
    enter_insert = true, -- Whether to enter insert mode when opening Claude Code
    hide_numbers = true, -- Hide line numbers in the terminal window
    hide_signcolumn = true, -- Hide the sign column in the terminal window
  },
  -- File refresh settings
  refresh = {
    enable = true, -- Enable file change detection
    updatetime = 100, -- updatetime to use when Claude Code is active (milliseconds)
    timer_interval = 1000, -- How often to check for file changes (milliseconds)
    show_notifications = true, -- Show notification when files are reloaded
  },
  -- Git integration settings
  git = {
    use_git_root = true, -- Set CWD to git root when opening Claude Code (if in git project)
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = '<C-,>', -- Normal mode keymap for toggling Claude Code
      terminal = '<C-,>', -- Terminal mode keymap for toggling Claude Code
    },
    window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
    scrolling = true, -- Enable scrolling keymaps (<C-f/b>) for page up/down
  },
}

--- Validate the configuration
--- @param config ClaudeCodeConfig
--- @return boolean valid
--- @return string? error_message
local function validate_config(config)
  -- Validate window settings
  if type(config.window) ~= 'table' then
    return false, 'window config must be a table'
  end

  if
    type(config.window.height_ratio) ~= 'number'
    or config.window.height_ratio <= 0
    or config.window.height_ratio > 1
  then
    return false, 'window.height_ratio must be a number between 0 and 1'
  end

  if type(config.window.position) ~= 'string' then
    return false, 'window.position must be a string'
  end

  if type(config.window.enter_insert) ~= 'boolean' then
    return false, 'window.enter_insert must be a boolean'
  end

  if type(config.window.hide_numbers) ~= 'boolean' then
    return false, 'window.hide_numbers must be a boolean'
  end

  if type(config.window.hide_signcolumn) ~= 'boolean' then
    return false, 'window.hide_signcolumn must be a boolean'
  end

  -- Validate refresh settings
  if type(config.refresh) ~= 'table' then
    return false, 'refresh config must be a table'
  end

  if type(config.refresh.enable) ~= 'boolean' then
    return false, 'refresh.enable must be a boolean'
  end

  if type(config.refresh.updatetime) ~= 'number' or config.refresh.updatetime <= 0 then
    return false, 'refresh.updatetime must be a positive number'
  end

  if type(config.refresh.timer_interval) ~= 'number' or config.refresh.timer_interval <= 0 then
    return false, 'refresh.timer_interval must be a positive number'
  end

  if type(config.refresh.show_notifications) ~= 'boolean' then
    return false, 'refresh.show_notifications must be a boolean'
  end

  -- Validate git settings
  if type(config.git) ~= 'table' then
    return false, 'git config must be a table'
  end

  if type(config.git.use_git_root) ~= 'boolean' then
    return false, 'git.use_git_root must be a boolean'
  end

  -- Validate keymaps settings
  if type(config.keymaps) ~= 'table' then
    return false, 'keymaps config must be a table'
  end

  if type(config.keymaps.toggle) ~= 'table' then
    return false, 'keymaps.toggle must be a table'
  end

  if
    not (config.keymaps.toggle.normal == false or type(config.keymaps.toggle.normal) == 'string')
  then
    return false, 'keymaps.toggle.normal must be a string or false'
  end

  if
    not (
      config.keymaps.toggle.terminal == false or type(config.keymaps.toggle.terminal) == 'string'
    )
  then
    return false, 'keymaps.toggle.terminal must be a string or false'
  end

  if type(config.keymaps.window_navigation) ~= 'boolean' then
    return false, 'keymaps.window_navigation must be a boolean'
  end

  if type(config.keymaps.scrolling) ~= 'boolean' then
    return false, 'keymaps.scrolling must be a boolean'
  end

  return true, nil
end

--- Parse user configuration and merge with defaults
--- @param user_config? table
--- @param silent? boolean Set to true to suppress error notifications (for tests)
--- @return ClaudeCodeConfig
function M.parse_config(user_config, silent)
  local config = vim.tbl_deep_extend('force', {}, M.default_config, user_config or {})

  local valid, err = validate_config(config)
  if not valid then
    -- Only notify if not in silent mode
    if not silent then
      vim.notify('Claude Code: ' .. err, vim.log.levels.ERROR)
    end
    -- Fall back to default config in case of error
    return vim.deepcopy(M.default_config)
  end

  return config
end

return M
