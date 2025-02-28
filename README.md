# Claude Code Neovim Plugin

A Neovim plugin for seamless integration between [Claude Code](https://github.com/anthropics/claude-code) AI assistant and Neovim.

This plugin was entirely built with Claude Code in a Neovim terminal, and then inside itself using Claude Code for everything.

![Claude Code in Neovim](https://github.com/greggh/claude-code.nvim/blob/main/assets/claude-code.png?raw=true)

## Features

- 🚀 Toggle Claude Code in a terminal window with a single key press
- 🔄 Automatically detect and reload files modified by Claude Code
- ⚡ Real-time buffer updates when files are changed externally
- 📱 Customizable window position and size
- 🤖 Integration with which-key (if available)
- 📂 Automatically uses git project root as working directory (when available)
- 🧩 Modular and maintainable code structure
- 📋 Type annotations with LuaCATS for better IDE support
- ✅ Configuration validation to prevent errors
- 🧪 Testing framework for reliability

## Requirements

- Neovim 0.7.0 or later
- [Claude Code CLI](https://github.com/anthropics/claude-code) tool installed and available in your PATH
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (dependency for git operations)

## Version

Current version: 0.2.0 - See [CHANGELOG.md](CHANGELOG.md) for details

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  "greggh/claude-code.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for git operations
  },
  config = function()
    require("claude-code").setup()
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'greggh/claude-code.nvim',
  requires = {
    'nvim-lua/plenary.nvim', -- Required for git operations
  },
  config = function()
    require('claude-code').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'greggh/claude-code.nvim'
" After installing, add this to your init.vim:
" lua require('claude-code').setup()
```

## Configuration

The plugin can be configured by passing a table to the `setup` function. Here's the default configuration:

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
  -- Git project settings
  git = {
    use_git_root = true,     -- Set CWD to git root when opening Claude Code (if in git project)
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = "<C-,>",       -- Normal mode keymap for toggling Claude Code, false to disable
      terminal = "<C-,>",     -- Terminal mode keymap for toggling Claude Code, false to disable
    },
    window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
    scrolling = true,         -- Enable scrolling keymaps (<C-f/b>) for page up/down
  }
})
```

## Usage

### Commands

- `:ClaudeCode` - Toggle the Claude Code terminal window

### Key Mappings

Default key mappings:

- `<leader>ac` - Toggle Claude Code terminal window (normal mode)
- `<C-,>` - Toggle Claude Code terminal window (both normal and terminal modes)

Additionally, when in the Claude Code terminal:

- `<C-h>` - Move to the window on the left
- `<C-j>` - Move to the window below
- `<C-k>` - Move to the window above
- `<C-l>` - Move to the window on the right
- `<C-f>` - Scroll full-page down
- `<C-b>` - Scroll full-page up

Note: After scrolling with `<C-f>` or `<C-b>`, you'll need to press the `i` key to re-enter insert mode so you can continue typing to Claude Code.

When Claude Code modifies files that are open in Neovim, they'll be automatically reloaded.

## How it Works

This plugin:

1. Creates a terminal buffer running the Claude Code CLI
2. Sets up autocommands to detect file changes on disk
3. Automatically reloads files when they're modified by Claude Code
4. Provides convenient keymaps and commands for toggling the terminal
5. Automatically detects git repositories and sets working directory to the git root

## Contributing

Contributions are welcome! Please check out our [contribution guidelines](CONTRIBUTING.md) for details on how to get started.

## License

MIT License - See [LICENSE](LICENSE) for more information.

## Development Cost

This entire plugin was developed using Claude Code. Here's what it cost to build the initial version:

```
Total cost: $5.42
Total duration (API): 17m 12.9s
Total duration (wall): 2h 29m 29.2s
```

---

💻 Created by [greggh](https://github.com/greggh)
