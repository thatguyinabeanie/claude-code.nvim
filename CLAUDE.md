# Claude Code Plugin Information

## Useful Commands

### Git Commands
- `git -C /home/gregg/Projects/neovim/plugins/claude-code commit -am "message"` - Add all changes and commit
- `git -C /home/gregg/Projects/neovim/plugins/claude-code push` - Push changes to remote
- `git -C /home/gregg/Projects/neovim/plugins/claude-code status` - Check current status
- `git -C /home/gregg/Projects/neovim/plugins/claude-code diff` - Show changes
- `git -C /home/gregg/Projects/neovim/plugins/claude-code log -n 5` - Show last 5 commits

### Development Commands
- `stylua lua/ -c` - Check Lua formatting
- `stylua lua/` - Format Lua code
- `luacheck lua/` - Run Lua linter
- `nvim --headless -c "lua require('claude-code.test').run()"` - Run tests

## Codebase Information

### Config Options
The plugin supports the following configuration options:

```lua
require("claude-code").setup({
  -- Terminal window settings
  window = {
    height_ratio = 0.3,     -- Percentage of screen height for the terminal window
    position = "botright",  -- Position of the window: "botright", "topleft", etc.
    enter_insert = true,    -- Whether to enter insert mode when opening Claude Code
    hide_numbers = true,    -- Hide line numbers in the terminal window
    hide_signcolumn = true, -- Hide the sign column in the terminal window
  },
  -- File refresh settings
  refresh = {
    enable = true,           -- Enable file change detection
    updatetime = 100,        -- updatetime when Claude Code is active (milliseconds)
    timer_interval = 1000,   -- How often to check for file changes (milliseconds)
    show_notifications = true, -- Show notification when files are reloaded
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = "<leader>ac",  -- Normal mode keymap for toggling Claude Code
      terminal = "<C-.>",     -- Terminal mode keymap for toggling Claude Code
    },
    window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
    scrolling = true,         -- Enable scrolling keymaps (<C-f/b>) for page up/down
  }
})
```

### Project Structure
- `lua/claude-code/init.lua` - Main plugin file
- `lua/claude-code/config.lua` - Configuration module
- `lua/claude-code/terminal.lua` - Terminal management
- `lua/claude-code/buffer.lua` - Buffer utilities
- `lua/claude-code/autocmds.lua` - Autocommands for file refresh
- `lua/claude-code/version.lua` - Version information

### Features
- Seamless Neovim integration with Claude Code AI
- Terminal-based interface for Claude interaction
- File change detection and auto-refresh
- Customizable window positioning and appearance
- Integration with file context and projects
- Convenient keymaps for toggling and navigation

### Version Management
- Current version: v0.4.2
- Version file: `lua/claude-code/version.lua`

### Key Files
- `README.md` - Plugin documentation
- `CLAUDE.md` - Internal notes and info for Claude Code
- `LICENSE` - MIT License