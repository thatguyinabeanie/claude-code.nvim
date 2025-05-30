---@mod claude-code.config Configuration management for claude-code.nvim
---@brief [[
--- This module handles configuration management and validation for claude-code.nvim.
--- It provides the default configuration, validation, and merging of user config.
---@brief ]]

local M = {}

--- ClaudeCodeWindow class for window configuration
-- @table ClaudeCodeWindow
-- @field split_ratio number Percentage of screen for the terminal window (height for horizontal, width for vertical splits)
-- @field position string Position of the window: "botright", "topleft", "vertical", etc.
-- @field enter_insert boolean Whether to enter insert mode when opening Claude Code
-- @field start_in_normal_mode boolean Whether to start in normal mode instead of insert mode when opening Claude Code
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
-- @field multi_instance boolean Use multiple Claude instances (one per git root)

--- ClaudeCodeKeymapsToggle class for toggle keymap configuration
-- @table ClaudeCodeKeymapsToggle
-- @field normal string|boolean Normal mode keymap for toggling Claude Code, false to disable
-- @field terminal string|boolean Terminal mode keymap for toggling Claude Code, false to disable

--- ClaudeCodeKeymaps class for keymap configuration
-- @table ClaudeCodeKeymaps
-- @field toggle ClaudeCodeKeymapsToggle Keymaps for toggling Claude Code
-- @field window_navigation boolean Enable window navigation keymaps
-- @field scrolling boolean Enable scrolling keymaps

--- ClaudeCodeCommandVariants class for command variant configuration
-- @table ClaudeCodeCommandVariants
-- Conversation management:
-- @field continue string|boolean Resume the most recent conversation
-- @field resume string|boolean Display an interactive conversation picker
-- Output options:
-- @field verbose string|boolean Enable verbose logging with full turn-by-turn output
-- Additional options can be added as needed

--- ClaudeCodeConfig class for main configuration
-- @table ClaudeCodeConfig
-- @field window ClaudeCodeWindow Terminal window settings
-- @field refresh ClaudeCodeRefresh File refresh settings
-- @field git ClaudeCodeGit Git integration settings
-- @field command string Command used to launch Claude Code
-- @field command_variants ClaudeCodeCommandVariants Command variants configuration
-- @field keymaps ClaudeCodeKeymaps Keymaps configuration

--- Default configuration options
--- @type ClaudeCodeConfig
M.default_config = {
  -- Terminal window settings
  window = {
    split_ratio = 0.3, -- Percentage of screen for the terminal window (height or width)
    height_ratio = 0.3, -- DEPRECATED: Use split_ratio instead
    position = 'botright', -- Position of the window: "botright", "topleft", "vertical", etc.
    enter_insert = true, -- Whether to enter insert mode when opening Claude Code
    start_in_normal_mode = false, -- Whether to start in normal mode instead of insert mode
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
    multi_instance = true, -- Use multiple Claude instances (one per git root)
  },
  -- Command settings
  command = 'claude', -- Command used to launch Claude Code
  cli_path = nil, -- Optional custom path to Claude CLI executable
  -- Command variants
  command_variants = {
    -- Conversation management
    continue = '--continue', -- Resume the most recent conversation
    resume = '--resume', -- Display an interactive conversation picker

    -- Output options
    verbose = '--verbose', -- Enable verbose logging with full turn-by-turn output
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = '<C-,>', -- Normal mode keymap for toggling Claude Code
      terminal = '<C-,>', -- Terminal mode keymap for toggling Claude Code
      variants = {
        continue = '<leader>cC', -- Normal mode keymap for Claude Code with continue flag
        verbose = '<leader>cV', -- Normal mode keymap for Claude Code with verbose flag
      },
    },
    window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
    scrolling = true, -- Enable scrolling keymaps (<C-f/b>) for page up/down
  },
  -- MCP server settings
  mcp = {
    enabled = true, -- Enable MCP server functionality
    auto_start = false, -- Don't auto-start the MCP server by default
    tools = {
      buffer = true,
      command = true,
      status = true,
      edit = true,
      window = true,
      mark = true,
      register = true,
      visual = true
    },
    resources = {
      current_buffer = true,
      buffer_list = true,
      project_structure = true,
      git_status = true,
      lsp_diagnostics = true,
      vim_options = true
    }
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
    type(config.window.split_ratio) ~= 'number'
    or config.window.split_ratio <= 0
    or config.window.split_ratio > 1
  then
    return false, 'window.split_ratio must be a number between 0 and 1'
  end

  if type(config.window.position) ~= 'string' then
    return false, 'window.position must be a string'
  end

  if type(config.window.enter_insert) ~= 'boolean' then
    return false, 'window.enter_insert must be a boolean'
  end

  if type(config.window.start_in_normal_mode) ~= 'boolean' then
    return false, 'window.start_in_normal_mode must be a boolean'
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

  if type(config.git.multi_instance) ~= 'boolean' then
    return false, 'git.multi_instance must be a boolean'
  end

  -- Validate command settings
  if type(config.command) ~= 'string' then
    return false, 'command must be a string'
  end
  
  -- Validate cli_path if provided
  if config.cli_path ~= nil and type(config.cli_path) ~= 'string' then
    return false, 'cli_path must be a string or nil'
  end

  -- Validate command variants settings
  if type(config.command_variants) ~= 'table' then
    return false, 'command_variants config must be a table'
  end

  -- Check each command variant
  for variant_name, variant_args in pairs(config.command_variants) do
    if not (variant_args == false or type(variant_args) == 'string') then
      return false, 'command_variants.' .. variant_name .. ' must be a string or false'
    end
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

  -- Validate variant keymaps if they exist
  if config.keymaps.toggle.variants then
    if type(config.keymaps.toggle.variants) ~= 'table' then
      return false, 'keymaps.toggle.variants must be a table'
    end

    -- Check each variant keymap
    for variant_name, keymap in pairs(config.keymaps.toggle.variants) do
      if not (keymap == false or type(keymap) == 'string') then
        return false, 'keymaps.toggle.variants.' .. variant_name .. ' must be a string or false'
      end
      -- Ensure variant exists in command_variants
      if keymap ~= false and not config.command_variants[variant_name] then
        return false,
          'keymaps.toggle.variants.' .. variant_name .. ' has no corresponding command variant'
      end
    end
  end

  if type(config.keymaps.window_navigation) ~= 'boolean' then
    return false, 'keymaps.window_navigation must be a boolean'
  end

  if type(config.keymaps.scrolling) ~= 'boolean' then
    return false, 'keymaps.scrolling must be a boolean'
  end

  return true, nil
end

--- Detect Claude Code CLI installation
--- @param custom_path? string Optional custom CLI path to check first
--- @return string|nil The path to Claude Code executable, or nil if not found
local function detect_claude_cli(custom_path)
  -- First check custom path if provided
  if custom_path then
    if vim.fn.filereadable(custom_path) == 1 and vim.fn.executable(custom_path) == 1 then
      return custom_path
    end
    -- If custom path doesn't work, fall through to default search
  end
  
  -- Check for local installation in ~/.claude/local/claude
  local local_claude = vim.fn.expand("~/.claude/local/claude")
  if vim.fn.filereadable(local_claude) == 1 and vim.fn.executable(local_claude) == 1 then
    return local_claude
  end
  
  -- Fall back to 'claude' in PATH
  if vim.fn.executable("claude") == 1 then
    return "claude"
  end
  
  -- If nothing found, return nil to indicate failure
  return nil
end

--- Parse user configuration and merge with defaults
--- @param user_config? table
--- @param silent? boolean Set to true to suppress error notifications (for tests)
--- @return ClaudeCodeConfig
function M.parse_config(user_config, silent)
  -- Handle backward compatibility first
  if user_config and user_config.window then
    if user_config.window.height_ratio and not user_config.window.split_ratio then
      -- Copy height_ratio to split_ratio for backward compatibility
      user_config.window.split_ratio = user_config.window.height_ratio
    end
  end

  local config = vim.tbl_deep_extend('force', {}, M.default_config, user_config or {})
  
  -- Auto-detect Claude CLI if not explicitly set (skip in silent mode for tests)
  if not silent and (not user_config or not user_config.command) then
    local custom_path = config.cli_path
    local detected_cli = detect_claude_cli(custom_path)
    config.command = detected_cli or "claude"
    
    -- Notify user about the CLI selection
    if not silent then
      if custom_path then
        if detected_cli == custom_path then
          vim.notify("Claude Code: Using custom CLI at " .. custom_path, vim.log.levels.INFO)
        else
          vim.notify("Claude Code: Custom CLI path not found: " .. custom_path .. " - falling back to default detection", vim.log.levels.WARN)
          -- Continue with default detection notifications
          if detected_cli == vim.fn.expand("~/.claude/local/claude") then
            vim.notify("Claude Code: Using local installation at ~/.claude/local/claude", vim.log.levels.INFO)
          elseif detected_cli and vim.fn.executable(detected_cli) == 1 then
            vim.notify("Claude Code: Using 'claude' from PATH", vim.log.levels.INFO)
          else
            vim.notify("Claude Code: CLI not found! Please install Claude Code or set config.command", vim.log.levels.WARN)
          end
        end
      else
        -- No custom path, use standard detection notifications
        if detected_cli == vim.fn.expand("~/.claude/local/claude") then
          vim.notify("Claude Code: Using local installation at ~/.claude/local/claude", vim.log.levels.INFO)
        elseif detected_cli and vim.fn.executable(detected_cli) == 1 then
          vim.notify("Claude Code: Using 'claude' from PATH", vim.log.levels.INFO)
        else
          vim.notify("Claude Code: CLI not found! Please install Claude Code or set config.command", vim.log.levels.WARN)
        end
      end
    end
  end

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

-- Internal API for testing
M._internal = {
  detect_claude_cli = detect_claude_cli
}

return M
