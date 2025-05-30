# Claude Code Neovim Plugin

[![GitHub License](https://img.shields.io/github/license/greggh/claude-code.nvim?style=flat-square)](https://github.com/greggh/claude-code.nvim/blob/main/LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/greggh/claude-code.nvim?style=flat-square)](https://github.com/greggh/claude-code.nvim/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/greggh/claude-code.nvim?style=flat-square)](https://github.com/greggh/claude-code.nvim/issues)
[![CI](https://img.shields.io/github/actions/workflow/status/greggh/claude-code.nvim/ci.yml?branch=main&style=flat-square&logo=github)](https://github.com/greggh/claude-code.nvim/actions/workflows/ci.yml)
[![Neovim Version](https://img.shields.io/badge/Neovim-0.7%2B-blueviolet?style=flat-square&logo=neovim)](https://github.com/neovim/neovim)
[![Tests](https://img.shields.io/badge/Tests-44%20passing-success?style=flat-square&logo=github-actions)](https://github.com/greggh/claude-code.nvim/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/Version-0.4.2-blue?style=flat-square)](https://github.com/greggh/claude-code.nvim/releases/tag/v0.4.2)
[![Discussions](https://img.shields.io/github/discussions/greggh/claude-code.nvim?style=flat-square&logo=github)](https://github.com/greggh/claude-code.nvim/discussions)

_A seamless integration between [Claude Code](https://github.com/anthropics/claude-code) AI assistant and Neovim with pure Lua MCP server_

[Features](#features) •
[Requirements](#requirements) •
[Installation](#installation) •
[MCP Server](#mcp-server) •
[Configuration](#configuration) •
[Usage](#usage) •
[Contributing](#contributing) •
[Discussions](https://github.com/greggh/claude-code.nvim/discussions)

![Claude Code in Neovim](https://github.com/greggh/claude-code.nvim/blob/main/assets/claude-code.png?raw=true)

This plugin provides both a traditional terminal interface and a native **MCP (Model Context Protocol) server** that allows Claude Code to directly read and edit your Neovim buffers, execute commands, and access project context.

## Features

### Terminal Interface

- 🚀 Toggle Claude Code in a terminal window with a single key press
- 🧠 Support for command-line arguments like `--continue` and custom variants
- 🔄 Automatically detect and reload files modified by Claude Code
- ⚡ Real-time buffer updates when files are changed externally
- 📱 Customizable window position and size
- 🤖 Integration with which-key (if available)
- 📂 Automatically uses git project root as working directory (when available)

### MCP Server (NEW!)

- 🔌 **Pure Lua MCP server** - No Node.js dependencies required
- 📝 **Direct buffer editing** - Claude Code can read and modify your Neovim buffers directly
- ⚡ **Real-time context** - Access to cursor position, buffer content, and editor state
- 🛠️ **Vim command execution** - Run any Vim command through Claude Code
- 📊 **Project awareness** - Access to git status, LSP diagnostics, and project structure
- 🎯 **Resource providers** - Expose buffer list, current file, and project information
- 🔒 **Secure by design** - All operations go through Neovim's API

### Development

- 🧩 Modular and maintainable code structure
- 📋 Type annotations with LuaCATS for better IDE support
- ✅ Configuration validation to prevent errors
- 🧪 Testing framework for reliability (44 comprehensive tests)

## Requirements

- Neovim 0.7.0 or later
- [Claude Code CLI](https://github.com/anthropics/claude-code) tool installed and available in your PATH
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (dependency for git operations)

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

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

## MCP Server

The plugin includes a pure Lua implementation of an MCP (Model Context Protocol) server that allows Claude Code to directly interact with your Neovim instance.

### Quick Start

1. **Add to Claude Code MCP configuration:**

   ```bash
   # Add the MCP server to Claude Code
   claude mcp add neovim-server /path/to/claude-code.nvim/bin/claude-code-mcp-server
   ```

2. **Start Neovim and the plugin will automatically set up the MCP server:**

   ```lua
   require('claude-code').setup({
     mcp = {
       enabled = true,
       auto_start = false  -- Set to true to auto-start with Neovim
     }
   })
   ```

3. **Use Claude Code with full Neovim integration:**
   ```bash
   claude "refactor this function to use async/await"
   # Claude can now see your current buffer, edit it directly, and run Vim commands
   ```

### Available Tools

The MCP server provides these tools to Claude Code:

- **`vim_buffer`** - View buffer content with optional filename filtering
- **`vim_command`** - Execute any Vim command (`:w`, `:bd`, custom commands, etc.)
- **`vim_status`** - Get current editor status (cursor position, mode, buffer info)
- **`vim_edit`** - Edit buffer content with insert/replace/replaceAll modes
- **`vim_window`** - Manage windows (split, close, navigate)
- **`vim_mark`** - Set marks in buffers
- **`vim_register`** - Set register content
- **`vim_visual`** - Make visual selections

### Available Resources

The MCP server exposes these resources:

- **`neovim://current-buffer`** - Content of the currently active buffer
- **`neovim://buffers`** - List of all open buffers with metadata
- **`neovim://project`** - Project file structure
- **`neovim://git-status`** - Current git repository status
- **`neovim://lsp-diagnostics`** - LSP diagnostics for current buffer
- **`neovim://options`** - Current Neovim configuration and options

### Commands

- `:ClaudeCodeMCPStart` - Start the MCP server
- `:ClaudeCodeMCPStop` - Stop the MCP server
- `:ClaudeCodeMCPStatus` - Show server status and information

### Standalone Usage

You can also run the MCP server standalone:

```bash
# Start standalone MCP server
./bin/claude-code-mcp-server

# Test the server
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | ./bin/claude-code-mcp-server
```

## Configuration

The plugin can be configured by passing a table to the `setup` function. Here's the default configuration:

```lua
require("claude-code").setup({
  -- MCP server settings
  mcp = {
    enabled = true,          -- Enable MCP server functionality
    auto_start = false,      -- Automatically start MCP server with Neovim
    tools = {
      buffer = true,         -- Enable buffer viewing tool
      command = true,        -- Enable Vim command execution tool
      status = true,         -- Enable status information tool
      edit = true,           -- Enable buffer editing tool
      window = true,         -- Enable window management tool
      mark = true,           -- Enable mark setting tool
      register = true,       -- Enable register operations tool
      visual = true          -- Enable visual selection tool
    },
    resources = {
      current_buffer = true,    -- Expose current buffer content
      buffer_list = true,       -- Expose list of all buffers
      project_structure = true, -- Expose project file structure
      git_status = true,        -- Expose git repository status
      lsp_diagnostics = true,   -- Expose LSP diagnostics
      vim_options = true        -- Expose Neovim configuration
    }
  },
  -- Terminal window settings
  window = {
    split_ratio = 0.3,      -- Percentage of screen for the terminal window (height for horizontal, width for vertical splits)
    position = "botright",  -- Position of the window: "botright", "topleft", "vertical", "rightbelow vsplit", etc.
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
  -- Command settings
  command = "claude",        -- Command used to launch Claude Code
  -- Command variants
  command_variants = {
    -- Conversation management
    continue = "--continue", -- Resume the most recent conversation
    resume = "--resume",     -- Display an interactive conversation picker

    -- Output options
    verbose = "--verbose",   -- Enable verbose logging with full turn-by-turn output
  },
  -- Keymaps
  keymaps = {
    toggle = {
      normal = "<C-,>",       -- Normal mode keymap for toggling Claude Code, false to disable
      terminal = "<C-,>",     -- Terminal mode keymap for toggling Claude Code, false to disable
      variants = {
        continue = "<leader>cC", -- Normal mode keymap for Claude Code with continue flag
        verbose = "<leader>cV",  -- Normal mode keymap for Claude Code with verbose flag
      },
    },
    window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
    scrolling = true,         -- Enable scrolling keymaps (<C-f/b>) for page up/down
  }
})
```

## Claude Code Integration

The plugin provides seamless integration with the Claude Code CLI through MCP (Model Context Protocol):

### Quick Setup

1. **Generate MCP Configuration:**

   ```vim
   :ClaudeCodeSetup
   ```

   This creates `claude-code-mcp-config.json` in your current directory with usage instructions.

2. **Use with Claude Code CLI:**
   ```bash
   claude --mcp-config claude-code-mcp-config.json --allowedTools "mcp__neovim__*" "Your prompt here"
   ```

### Available Commands

- `:ClaudeCodeSetup [type]` - Generate MCP config with instructions (claude-code|workspace)
- `:ClaudeCodeMCPConfig [type] [path]` - Generate MCP config file (claude-code|workspace|custom)
- `:ClaudeCodeMCPStart` - Start the MCP server
- `:ClaudeCodeMCPStop` - Stop the MCP server
- `:ClaudeCodeMCPStatus` - Show server status

### Configuration Types

- **`claude-code`** - Creates `.claude.json` for Claude Code CLI
- **`workspace`** - Creates `.vscode/mcp.json` for VS Code MCP extension
- **`custom`** - Creates `mcp-config.json` for other MCP clients

### MCP Tools & Resources

**Tools** (Actions Claude Code can perform):

- `mcp__neovim__vim_buffer` - Read/write buffer contents
- `mcp__neovim__vim_command` - Execute Vim commands
- `mcp__neovim__vim_edit` - Edit text in buffers
- `mcp__neovim__vim_status` - Get editor status
- `mcp__neovim__vim_window` - Manage windows
- `mcp__neovim__vim_mark` - Manage marks
- `mcp__neovim__vim_register` - Access registers
- `mcp__neovim__vim_visual` - Visual selections

**Resources** (Information Claude Code can access):

- `mcp__neovim__current_buffer` - Current buffer content
- `mcp__neovim__buffer_list` - List of open buffers
- `mcp__neovim__project_structure` - Project file tree
- `mcp__neovim__git_status` - Git repository status
- `mcp__neovim__lsp_diagnostics` - LSP diagnostics
- `mcp__neovim__vim_options` - Vim configuration options

## Usage

### Quick Start

```vim
" In your Vim/Neovim commands or init file:
:ClaudeCode
```

```lua
-- Or from Lua:
vim.cmd[[ClaudeCode]]

-- Or map to a key:
vim.keymap.set('n', '<leader>cc', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code' })
```

### Commands

Basic command:

- `:ClaudeCode` - Toggle the Claude Code terminal window

Conversation management commands:

- `:ClaudeCodeContinue` - Resume the most recent conversation
- `:ClaudeCodeResume` - Display an interactive conversation picker

Output options command:

- `:ClaudeCodeVerbose` - Enable verbose logging with full turn-by-turn output

Note: Commands are automatically generated for each entry in your `command_variants` configuration.

### Key Mappings

Default key mappings:

- `<leader>ac` - Toggle Claude Code terminal window (normal mode)
- `<C-,>` - Toggle Claude Code terminal window (both normal and terminal modes)

Variant mode mappings (if configured):

- `<leader>cC` - Toggle Claude Code with --continue flag
- `<leader>cV` - Toggle Claude Code with --verbose flag

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

## Development

For a complete guide on setting up a development environment, installing all required tools, and understanding the project structure, please refer to [DEVELOPMENT.md](DEVELOPMENT.md).

### Development Setup

The project includes comprehensive setup for development:

- Complete installation instructions for all platforms in [DEVELOPMENT.md](DEVELOPMENT.md)
- Pre-commit hooks for code quality
- Testing framework with 44 comprehensive tests
- Linting and formatting tools
- Weekly dependency updates workflow for Claude CLI and actions

```bash
# Run tests
make test

# Check code quality
make lint

# Set up pre-commit hooks
scripts/setup-hooks.sh

# Format code
make format
```

## Community

- [GitHub Discussions](https://github.com/greggh/claude-code.nvim/discussions) - Get help, share ideas, and connect with other users
- [GitHub Issues](https://github.com/greggh/claude-code.nvim/issues) - Report bugs or suggest features
- [GitHub Pull Requests](https://github.com/greggh/claude-code.nvim/pulls) - Contribute to the project

## Acknowledgements

- [Claude Code](https://github.com/anthropics/claude-code) by Anthropic - This plugin was entirely built using Claude Code. Development cost: $5.42 with 17m 12.9s of API time
- [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Core dependency for testing framework and Git operations
- [Semantic Versioning](https://semver.org/) - Versioning standard used in this project
- [Contributor Covenant](https://www.contributor-covenant.org/) - Code of Conduct standard
- [Keep a Changelog](https://keepachangelog.com/) - Changelog format
- [LuaCATS](https://luals.github.io/wiki/annotations/) - Type annotations for better IDE support
- [StyLua](https://github.com/JohnnyMorganz/StyLua) - Lua code formatter
- [Luacheck](https://github.com/lunarmodules/luacheck) - Lua static analyzer and linter

---

Made with ❤️ by [Gregg Housh](https://github.com/greggh)

---

## claude smoke test

okay. i need you to come u with a idea for a
"live test" i am going to open neovim ON the
local claude-code.nvim repository that neovim is
loading for the plugin. that means the claude
code chat (you) are going to be using this
functionality we've been developing. i need you
to come up with a solution that when prompted can
validate if things are working correct
