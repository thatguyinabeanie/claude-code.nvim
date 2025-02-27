-- Claude Code Neovim Integration
-- A plugin for seamless integration between Claude Code AI assistant and Neovim

local M = {}

-- Default configuration options
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
      normal = '<leader>ac', -- Normal mode keymap for toggling Claude Code
      terminal = '<C-,>', -- Terminal mode keymap for toggling Claude Code
    },
    window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
    scrolling = true, -- Enable scrolling keymaps (<C-f/b>) for page up/down
  },
}

-- Holds the current configuration
M.config = {}

-- Terminal buffer and window management
M.claude_code = {
  bufnr = nil, -- Buffer number of the Claude Code terminal
  saved_updatetime = nil, -- Original updatetime before Claude Code was opened
}

-- Set up function to force insert mode when entering the Claude Code window
function M.force_insert_mode()
  local bufnr = M.claude_code.bufnr
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.fn.bufnr '%' == bufnr then
    -- Only enter insert mode if we're in the terminal buffer and not already in insert mode
    local mode = vim.api.nvim_get_mode().mode
    if vim.bo.buftype == 'terminal' and mode ~= 't' and mode ~= 'i' then
      vim.cmd 'silent! stopinsert'
      vim.schedule(function()
        vim.cmd 'silent! startinsert'
      end)
    end
  end
end

-- Setup autocommands for file change detection
local function setup_file_refresh(config)
  if not config.refresh.enable then
    return
  end

  local augroup = vim.api.nvim_create_augroup('ClaudeCodeFileRefresh', { clear = true })

  -- Create an autocommand that checks for file changes more frequently
  vim.api.nvim_create_autocmd({
    'CursorHold',
    'CursorHoldI',
    'FocusGained',
    'BufEnter',
    'InsertLeave',
    'TextChanged',
    'TermLeave',
    'TermEnter',
    'BufWinEnter',
  }, {
    group = augroup,
    pattern = '*',
    callback = function()
      if vim.fn.filereadable(vim.fn.expand '%') == 1 then
        vim.cmd 'checktime'
      end
    end,
    desc = 'Check for file changes on disk',
  })

  -- Create a timer to check for file changes periodically
  local timer = vim.loop.new_timer()
  if timer then
    timer:start(
      0,
      config.refresh.timer_interval,
      vim.schedule_wrap(function()
        -- Only check time if there's an active Claude Code terminal
        local bufnr = M.claude_code.bufnr
        if bufnr and vim.api.nvim_buf_is_valid(bufnr) and #vim.fn.win_findbuf(bufnr) > 0 then
          vim.cmd 'silent! checktime'
        end
      end)
    )
  end

  -- Create an autocommand that notifies when a file has been changed externally
  if config.refresh.show_notifications then
    vim.api.nvim_create_autocmd('FileChangedShellPost', {
      group = augroup,
      pattern = '*',
      callback = function()
        vim.notify('File changed on disk. Buffer reloaded.', vim.log.levels.INFO)
      end,
      desc = 'Notify when a file is changed externally',
    })
  end

  -- Set a shorter updatetime while Claude Code is open
  M.claude_code.saved_updatetime = vim.o.updatetime

  -- When Claude Code opens, set a shorter updatetime
  vim.api.nvim_create_autocmd('TermOpen', {
    group = augroup,
    pattern = '*',
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match 'claude%-code$' then
        M.claude_code.saved_updatetime = vim.o.updatetime
        vim.o.updatetime = config.refresh.updatetime
      end
    end,
    desc = 'Set shorter updatetime when Claude Code is open',
  })

  -- When Claude Code closes, restore normal updatetime
  vim.api.nvim_create_autocmd('TermClose', {
    group = augroup,
    pattern = '*',
    callback = function()
      local buf_name = vim.api.nvim_buf_get_name(0)
      if buf_name:match 'claude%-code$' then
        vim.o.updatetime = M.claude_code.saved_updatetime
      end
    end,
    desc = 'Restore normal updatetime when Claude Code is closed',
  })
end

-- Helper function to get git root directory
function M.get_git_root()
  -- Check if we're in a git repository
  local handle = io.popen 'git rev-parse --is-inside-work-tree 2>/dev/null'
  if not handle then
    return nil
  end

  local result = handle:read '*a'
  handle:close()

  if result:match 'true' then
    -- Get the git root path
    local root_handle = io.popen 'git rev-parse --show-toplevel 2>/dev/null'
    if not root_handle then
      return nil
    end

    local git_root = root_handle:read('*a'):gsub('%s+$', '')
    root_handle:close()

    return git_root
  end

  return nil
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
      vim.cmd(M.config.window.position .. ' split')
      vim.cmd('resize ' .. math.floor(vim.o.lines * M.config.window.height_ratio))
      vim.cmd('buffer ' .. bufnr)
      -- Force insert mode more aggressively
      vim.schedule(function()
        vim.cmd 'stopinsert | startinsert'
      end)
    end
  else
    -- Claude Code is not running, start it in a new split
    vim.cmd(M.config.window.position .. ' split')
    vim.cmd('resize ' .. math.floor(vim.o.lines * M.config.window.height_ratio))

    -- Determine if we should use the git root directory
    local cmd = 'terminal claude'
    if M.config.git and M.config.git.use_git_root then
      local git_root = M.get_git_root()
      if git_root then
        cmd = 'terminal claude --cwd ' .. git_root
      end
    end

    vim.cmd(cmd)
    vim.cmd 'setlocal bufhidden=hide'
    vim.cmd 'file claude-code'

    if M.config.window.hide_numbers then
      vim.cmd 'setlocal nonumber norelativenumber'
    end

    if M.config.window.hide_signcolumn then
      vim.cmd 'setlocal signcolumn=no'
    end

    -- Store buffer number for future reference
    M.claude_code.bufnr = vim.fn.bufnr '%'

    -- Set up window navigation keymaps for this buffer
    M.setup_terminal_navigation()

    -- Automatically enter insert mode in terminal
    if M.config.window.enter_insert then
      vim.cmd 'startinsert'
    end
  end
end

-- Set up terminal keymaps for window navigation
function M.setup_terminal_navigation()
  local buf = M.claude_code.bufnr
  if buf and vim.api.nvim_buf_is_valid(buf) then
    -- Create autocommand to enter insert mode when the terminal window gets focus
    local augroup = vim.api.nvim_create_augroup('ClaudeCodeTerminalFocus', { clear = true })

    -- Set up multiple events for more reliable focus detection
    vim.api.nvim_create_autocmd(
      { 'WinEnter', 'BufEnter', 'WinLeave', 'FocusGained', 'CmdLineLeave' },
      {
        group = augroup,
        callback = function()
          vim.schedule(M.force_insert_mode)
        end,
        desc = 'Auto-enter insert mode when focusing Claude Code terminal',
      }
    )

    -- Window navigation keymaps
    if M.config.keymaps.window_navigation then
      -- Window navigation keymaps with special handling to force insert mode in the target window
      vim.api.nvim_buf_set_keymap(
        buf,
        't',
        '<C-h>',
        [[<C-\><C-n><C-w>h:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move left' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        't',
        '<C-j>',
        [[<C-\><C-n><C-w>j:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move down' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        't',
        '<C-k>',
        [[<C-\><C-n><C-w>k:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move up' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        't',
        '<C-l>',
        [[<C-\><C-n><C-w>l:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move right' }
      )

      -- Also add normal mode mappings for when user is in normal mode in the terminal
      vim.api.nvim_buf_set_keymap(
        buf,
        'n',
        '<C-h>',
        [[<C-w>h:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move left' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        'n',
        '<C-j>',
        [[<C-w>j:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move down' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        'n',
        '<C-k>',
        [[<C-w>k:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move up' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        'n',
        '<C-l>',
        [[<C-w>l:lua require("claude-code").force_insert_mode()<CR>]],
        { noremap = true, silent = true, desc = 'Window: move right' }
      )
    end

    -- Add scrolling keymaps
    if M.config.keymaps.scrolling then
      vim.api.nvim_buf_set_keymap(
        buf,
        't',
        '<C-f>',
        [[<C-\><C-n><C-f>i]],
        { noremap = true, silent = true, desc = 'Scroll full page down' }
      )
      vim.api.nvim_buf_set_keymap(
        buf,
        't',
        '<C-b>',
        [[<C-\><C-n><C-b>i]],
        { noremap = true, silent = true, desc = 'Scroll full page up' }
      )
    end
  end
end

-- Setup function for the plugin
function M.setup(user_config)
  -- Merge default config with user config
  M.config = vim.tbl_deep_extend('force', {}, M.default_config, user_config or {})

  -- Set up autoread option
  vim.o.autoread = true

  -- Set up file refresh functionality
  setup_file_refresh(M.config)

  -- Create the user command for toggling Claude Code
  vim.api.nvim_create_user_command('ClaudeCode', function()
    M.toggle()
  end, { desc = 'Toggle Claude Code terminal' })

  -- Set up keymaps
  local map_opts = { noremap = true, silent = true }

  -- Normal mode toggle keymaps
  vim.api.nvim_set_keymap(
    'n',
    M.config.keymaps.toggle.normal,
    [[<cmd>ClaudeCode<CR>]],
    vim.tbl_extend('force', map_opts, { desc = 'Claude Code: Toggle' })
  )

  -- Add <C-,> for normal mode
  vim.api.nvim_set_keymap(
    'n',
    '<C-,>',
    [[<cmd>ClaudeCode<CR>]],
    vim.tbl_extend('force', map_opts, { desc = 'Claude Code: Toggle' })
  )

  -- Terminal mode toggle keymap
  -- In terminal mode, special keys like Ctrl need different handling
  -- We use a direct escape sequence approach for more reliable terminal mappings
  vim.api.nvim_set_keymap(
    't',
    '<C-,>',
    [[<C-\><C-n>:ClaudeCode<CR>]],
    vim.tbl_extend('force', map_opts, { desc = 'Claude Code: Toggle' })
  )

  -- Apply buffer-specific keymaps if claude code is already running
  if M.claude_code.bufnr and vim.api.nvim_buf_is_valid(M.claude_code.bufnr) then
    M.setup_terminal_navigation()
  end

  -- Register with which-key if it's available
  vim.defer_fn(function()
    local status_ok, which_key = pcall(require, 'which-key')
    if status_ok then
      which_key.add {
        mode = 'n',
        { M.config.keymaps.toggle.normal, desc = 'Claude Code: Toggle', icon = '🤖' },
        { '<C-,>', desc = 'Claude Code: Toggle', icon = '🤖' },
      }
    end
  end, 100)
end

return M
