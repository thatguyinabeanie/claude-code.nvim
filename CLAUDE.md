# Claude Code Plugin Information

## Useful Commands

### Git Commands
- `git commit -am "message"` - Add all changes and commit
- `git push` - Push changes to remote
- `git status` - Check current status
- `git diff` - Show changes
- `git log -n 5` - Show last 5 commits

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
- `lua/claude-code/init.lua` - Main plugin file with all functionality

### Key Files
- `README.md` - Plugin documentation
- `CLAUDE.md` - Internal notes and info for Claude Code
- `LICENSE` - MIT License