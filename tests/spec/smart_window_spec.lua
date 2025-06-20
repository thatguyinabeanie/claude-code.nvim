-- Tests for smart window management in Claude Code
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local before_each = require('plenary.busted').before_each

local terminal = require('claude-code.terminal')

describe('smart window management', function()
  local config
  local claude_code
  local git
  local vim_cmd_calls = {}
  local current_buffer_name = ''
  local current_buffer_lines = { '' }
  local current_buffer_modified = false
  local current_buffer_type = ''
  local window_count = 1

  before_each(function()
    -- Reset tracking variables
    vim_cmd_calls = {}
    current_buffer_name = ''
    current_buffer_lines = { '' }
    current_buffer_modified = false
    current_buffer_type = ''
    window_count = 1

    -- Mock vim functions
    _G.vim = _G.vim or {}
    _G.vim.api = _G.vim.api or {}
    _G.vim.fn = _G.vim.fn or {}
    _G.vim.bo = _G.vim.bo or {}
    _G.vim.o = _G.vim.o or { lines = 100, columns = 100 }

    -- Mock vim.cmd
    _G.vim.cmd = function(cmd)
      table.insert(vim_cmd_calls, cmd)
      return true
    end

    -- Mock buffer-related functions
    _G.vim.api.nvim_get_current_buf = function()
      return 1
    end

    _G.vim.api.nvim_buf_get_name = function(bufnr)
      return current_buffer_name
    end

    _G.vim.api.nvim_buf_get_lines = function(bufnr, start, end_line, strict_indexing)
      return current_buffer_lines
    end

    _G.vim.bo = setmetatable({}, {
      __index = function(t, k)
        if type(k) == 'number' then
          -- Return a table for buffer-specific options
          return {
            modified = current_buffer_modified,
            buftype = current_buffer_type,
          }
        end
        return nil
      end,
    })

    -- Mock window-related functions
    _G.vim.api.nvim_list_wins = function()
      local wins = {}
      for i = 1, window_count do
        table.insert(wins, i)
      end
      return wins
    end

    _G.vim.api.nvim_win_get_config = function(win)
      -- All windows are non-floating in these tests
      return { relative = '' }
    end

    -- Mock other required functions
    _G.vim.api.nvim_buf_is_valid = function(bufnr)
      return bufnr ~= nil
    end

    _G.vim.fn.win_findbuf = function(bufnr)
      return {}
    end

    _G.vim.fn.bufnr = function(pattern)
      return 42
    end

    _G.vim.fn.getcwd = function()
      return '/test/current/dir'
    end

    _G.vim.api.nvim_win_close = function(win_id, force)
      return true
    end

    _G.vim.api.nvim_get_mode = function()
      return { mode = 'n' }
    end

    _G.vim.api.nvim_create_autocmd = function(event, opts)
      return true
    end

    _G.vim.defer_fn = function(fn, delay)
      fn()
    end

    _G.vim.schedule = function(fn)
      fn()
    end

    _G.vim.notify = function(msg, level)
      return true
    end

    -- Setup config
    config = {
      command = 'claude',
      window = {
        split_ratio = 0.3,
        position = 'botright',
        enter_insert = true,
        start_in_normal_mode = false,
        hide_numbers = true,
        hide_signcolumn = true,
        smart_window = true, -- Enable smart window management
        float = {
          relative = 'editor',
          width = 0.8,
          height = 0.8,
          row = 0.1,
          col = 0.1,
          border = 'rounded',
          title = ' Claude Code ',
          title_pos = 'center',
        },
      },
      git = {
        use_git_root = true,
        multi_instance = true,
      },
      refresh = {
        enable = true,
        updatetime = 100,
        timer_interval = 1000,
        show_notifications = true,
      },
    }

    -- Setup claude_code mock
    claude_code = {
      claude_code = {
        instances = {},
        current_instance = nil,
        floating_windows = {},
      },
    }

    -- Setup git mock
    git = {
      get_git_root = function()
        return '/test/git/root'
      end,
    }
  end)

  describe('when smart_window is enabled', function()
    it('should use current window when only one window with empty buffer', function()
      -- Setup: single window with empty buffer
      window_count = 1
      current_buffer_name = ''
      current_buffer_lines = { '' }
      current_buffer_modified = false
      current_buffer_type = ''

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Should have 'enew' command (which is used for current window)
      local enew_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'enew' then
          enew_found = true
        end
      end

      assert.is_true(enew_found, 'Should use current window (enew command)')

      -- Should NOT have split command
      local split_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd:match('split') then
          split_found = true
        end
      end

      assert.is_false(split_found, 'Should not create a split')
    end)

    it('should create split when window has content', function()
      -- Setup: single window with content
      window_count = 1
      current_buffer_name = '/test/file.lua'
      current_buffer_lines = { 'local M = {}', 'return M' }
      current_buffer_modified = false
      current_buffer_type = ''

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Should have split command
      local split_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'botright split' then
          split_found = true
        end
      end

      assert.is_true(split_found, 'Should create a split when buffer has content')
    end)

    it('should create split when buffer is modified', function()
      -- Setup: single window with modified empty buffer
      window_count = 1
      current_buffer_name = ''
      current_buffer_lines = { '' }
      current_buffer_modified = true
      current_buffer_type = ''

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Should have split command
      local split_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'botright split' then
          split_found = true
        end
      end

      assert.is_true(split_found, 'Should create a split when buffer is modified')
    end)

    it('should create split when multiple windows exist', function()
      -- Setup: multiple windows
      window_count = 2
      current_buffer_name = ''
      current_buffer_lines = { '' }
      current_buffer_modified = false
      current_buffer_type = ''

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Should have split command
      local split_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'botright split' then
          split_found = true
        end
      end

      assert.is_true(split_found, 'Should create a split when multiple windows exist')
    end)

    it('should respect position=current setting', function()
      -- Setup: force current window position
      config.window.position = 'current'
      window_count = 1
      current_buffer_name = '/test/file.lua'
      current_buffer_lines = { 'content' }

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Should NOT have split command even with content
      local split_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd:match('split') then
          split_found = true
        end
      end

      assert.is_false(split_found, 'Should respect position=current setting')
    end)

    it('should respect smart_window=false setting', function()
      -- Setup: disable smart window
      config.window.smart_window = false
      window_count = 1
      current_buffer_name = ''
      current_buffer_lines = { '' }
      current_buffer_modified = false

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Should have split command even with empty buffer
      local split_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'botright split' then
          split_found = true
        end
      end

      assert.is_true(split_found, 'Should create split when smart_window is disabled')
    end)

    it('should handle scratch buffers as empty', function()
      -- Setup: scratch buffer
      window_count = 1
      current_buffer_name = ''
      current_buffer_lines = { '' }
      current_buffer_modified = false
      current_buffer_type = 'scratch'

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Should use current window for scratch buffer
      local enew_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'enew' then
          enew_found = true
        end
      end

      assert.is_true(enew_found, 'Should treat scratch buffer as empty')
    end)

    it('should handle nofile buffers as empty', function()
      -- Setup: nofile buffer
      window_count = 1
      current_buffer_name = ''
      current_buffer_lines = { '' }
      current_buffer_modified = false
      current_buffer_type = 'nofile'

      -- Call toggle
      terminal.toggle(claude_code, config, git)

      -- Should use current window for nofile buffer
      local enew_found = false
      for _, cmd in ipairs(vim_cmd_calls) do
        if cmd == 'enew' then
          enew_found = true
        end
      end

      assert.is_true(enew_found, 'Should treat nofile buffer as empty')
    end)
  end)
end)