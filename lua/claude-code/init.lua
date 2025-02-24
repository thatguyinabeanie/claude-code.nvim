-- Claude Code Neovim Integration
-- A plugin for seamless integration between Claude Code AI assistant and Neovim

local M = {}

-- Default configuration options
M.default_config = {
  -- Terminal window settings
  window = {
    height_ratio = 0.3,     -- Percentage of screen height for the terminal window
    position = "botright",  -- Position of the window: "botright", "topleft", "vertical", etc.
    enter_insert = true,    -- Whether to enter insert mode when opening Claude Code
    hide_numbers = true,    -- Hide line numbers in the terminal window
    hide_signcolumn = true, -- Hide the sign column in the terminal window
  },
  -- File refresh settings
  refresh = {
    enable = true,           -- Enable file change detection
    updatetime = 100,        -- updatetime to use when Claude Code is active (milliseconds)
    timer_interval = 1000,   -- How often to check for file changes (milliseconds)
    show_notifications = true, -- Show notification when files are reloaded
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = "<leader>ac",  -- Normal mode keymap for toggling Claude Code
      terminal = "<C-o>",     -- Terminal mode keymap for toggling Claude Code
    }
  }
}

-- Holds the current configuration
M.config = {}

-- Terminal buffer and window management
M.claude_code = {
  bufnr = nil,              -- Buffer number of the Claude Code terminal
  saved_updatetime = nil,   -- Original updatetime before Claude Code was opened
}

-- Setup autocommands for file change detection
local function setup_file_refresh(config)
  if not config.refresh.enable then return end
  
  local augroup = vim.api.nvim_create_augroup("ClaudeCodeFileRefresh", { clear = true })
  
  -- Create an autocommand that checks for file changes more frequently
  vim.api.nvim_create_autocmd({ 
    "CursorHold", "CursorHoldI", "FocusGained", "BufEnter", 
    "InsertLeave", "TextChanged", "TermLeave", "TermEnter", "BufWinEnter"
  }, {
    group = augroup,
    pattern = "*",
    callback = function()
      if vim.fn.filereadable(vim.fn.expand("%")) == 1 then
        vim.cmd("checktime")
      end
    end,
    desc = "Check for file changes on disk",
  })

  -- Create a timer to check for file changes periodically
  local timer = vim.loop.new_timer()
  if timer then
    timer:start(0, config.refresh.timer_interval, vim.schedule_wrap(function()
      -- Only check time if there's an active Claude Code terminal
      local bufnr = M.claude_code.bufnr
      if bufnr and vim.api.nvim_buf_is_valid(bufnr) and 
         #vim.fn.win_findbuf(bufnr) > 0 then
        vim.cmd("silent! checktime")
      end
    end))
  end
  
  -- Create an autocommand that notifies when a file has been changed externally
  if config.refresh.show_notifications then
    vim.api.nvim_create_autocmd("FileChangedShellPost", {
      group = augroup,
      pattern = "*",
      callback = function()
        vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
      end,
      desc = "Notify when a file is changed externally",
    })
  end
  
  -- Set a shorter updatetime while Claude Code is open
  M.claude_code.saved_updatetime = vim.o.updatetime
  
  -- When Claude Code opens, set a shorter updatetime
  vim.api.nvim_create_autocmd("TermOpen", {
    group = augroup,
    pattern = "*",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match("claude%-code$") then
        M.claude_code.saved_updatetime = vim.o.updatetime
        vim.o.updatetime = config.refresh.updatetime
      end
    end,
    desc = "Set shorter updatetime when Claude Code is open",
  })
  
  -- When Claude Code closes, restore normal updatetime
  vim.api.nvim_create_autocmd("TermClose", {
    group = augroup,
    pattern = "*",
    callback = function()
      local buf_name = vim.api.nvim_buf_get_name(0)
      if buf_name:match("claude%-code$") then
        vim.o.updatetime = M.claude_code.saved_updatetime
      end
    end,
    desc = "Restore normal updatetime when Claude Code is closed",
  })
end

-- Toggle the Claude Code terminal window
function M.toggle()
  -- Check if Claude Code is already running
  local bufnr = M.claude_code.bufnr
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    -- Check if there's a window displaying Claude Code buffer
    local win_ids = vim.fn.win_findbuf(bufnr)
    if #win_ids > 0 then
      -- Claude Code is visible, close the window
      for _, win_id in ipairs(win_ids) do
        vim.api.nvim_win_close(win_id, true)
      end
    else
      -- Claude Code buffer exists but is not visible, open it in a split
      vim.cmd(M.config.window.position .. " split")
      vim.cmd("resize " .. math.floor(vim.o.lines * M.config.window.height_ratio))
      vim.cmd("buffer " .. bufnr)
      if M.config.window.enter_insert then
        vim.cmd("startinsert")
      end
    end
  else
    -- Claude Code is not running, start it in a new split
    vim.cmd(M.config.window.position .. " split")
    vim.cmd("resize " .. math.floor(vim.o.lines * M.config.window.height_ratio))
    vim.cmd("terminal claude")
    vim.cmd("setlocal bufhidden=hide")
    vim.cmd("file claude-code")
    
    if M.config.window.hide_numbers then
      vim.cmd("setlocal nonumber norelativenumber")
    end
    
    if M.config.window.hide_signcolumn then
      vim.cmd("setlocal signcolumn=no")
    end
    
    -- Store buffer number for future reference
    M.claude_code.bufnr = vim.fn.bufnr("%")
    
    -- Automatically enter insert mode in terminal
    if M.config.window.enter_insert then
      vim.cmd("startinsert")
    end
  end
end

-- Setup function for the plugin
function M.setup(user_config)
  -- Merge default config with user config
  M.config = vim.tbl_deep_extend("force", {}, M.default_config, user_config or {})
  
  -- Set up autoread option
  vim.o.autoread = true
  
  -- Set up file refresh functionality
  setup_file_refresh(M.config)
  
  -- Create the user command for toggling Claude Code
  vim.api.nvim_create_user_command("ClaudeCode", function()
    M.toggle()
  end, { desc = "Toggle Claude Code terminal" })
  
  -- Set up keymaps
  local map_opts = { noremap = true, silent = true }
  
  -- Normal mode toggle keymap
  vim.api.nvim_set_keymap("n", M.config.keymaps.toggle.normal, 
    [[<cmd>ClaudeCode<CR>]], 
    vim.tbl_extend("force", map_opts, { desc = "Claude Code: Toggle" }))
  
  -- Terminal mode toggle keymap
  vim.api.nvim_set_keymap("t", M.config.keymaps.toggle.terminal, 
    [[<cmd>ClaudeCode<CR>]], 
    vim.tbl_extend("force", map_opts, { desc = "Claude Code: Toggle" }))
  
  -- Register with which-key if it's available
  vim.defer_fn(function()
    local status_ok, which_key = pcall(require, "which-key")
    if status_ok then
      which_key.register({
        [M.config.keymaps.toggle.normal] = { desc = "Claude Code: Toggle", icon = "🤖" }
      })
    end
  end, 100)
end

return M