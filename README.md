# Claude Code Neovim Plugin

[![GitHub License](https://img.shields.io/github/license/greggh/claude-code.nvim?style=flat-square)](https://github.com/greggh/claude-code.nvim/blob/main/LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/greggh/claude-code.nvim?style=flat-square)](https://github.com/greggh/claude-code.nvim/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/greggh/claude-code.nvim?style=flat-square)](https://github.com/greggh/claude-code.nvim/issues)
[![CI](https://img.shields.io/github/actions/workflow/status/greggh/claude-code.nvim/ci.yml?branch=main&style=flat-square&logo=github)](https://github.com/greggh/claude-code.nvim/actions/workflows/ci.yml)
[![Neovim Version](https://img.shields.io/badge/Neovim-0.7%2B-blueviolet?style=flat-square&logo=neovim)](https://github.com/neovim/neovim)
[![Tests](https://img.shields.io/badge/Tests-44%20passing-success?style=flat-square&logo=github-actions)](https://github.com/greggh/claude-code.nvim/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/Version-0.4.2-blue?style=flat-square)](https://github.com/greggh/claude-code.nvim/releases/tag/v0.4.2)
[![Discussions](https://img.shields.io/github/discussions/greggh/claude-code.nvim?style=flat-square&logo=github)](https://github.com/greggh/claude-code.nvim/discussions)

_A seamless integration between [Claude Code](https://github.com/anthropics/claude-code) AI assistant and Neovim with context-aware commands and pure Lua MCP server_

[Features](#features) •
[Requirements](#requirements) •
[Installation](#installation) •
[MCP Server](#mcp-server) •
[Configuration](#configuration) •
[Usage](#usage) •
[Contributing](#contributing) •
[Discussions](https://github.com/greggh/claude-code.nvim/discussions)

![Claude Code in Neovim](https://github.com/greggh/claude-code.nvim/blob/main/assets/claude-code.png?raw=true)

This plugin provides:

- **Context-aware commands** that automatically pass file content, selections, and workspace context to Claude Code
- **Traditional terminal interface** for interactive conversations
- **Native MCP (Model Context Protocol) server** that allows Claude Code to directly read and edit your Neovim buffers, execute commands, and access project context

## Features

### Terminal Interface

- 🚀 Toggle Claude Code in a terminal window with a single key press
- 🔒 **Safe window toggle** - Hide/show window without interrupting Claude Code execution
- 🧠 Support for command-line arguments like `--continue` and custom variants
- 🔄 Automatically detect and reload files modified by Claude Code
- ⚡ Real-time buffer updates when files are changed externally
- 📊 Process status monitoring and instance management
- 📱 Customizable window position and size
- 🤖 Integration with which-key (if available)
- 📂 Automatically uses git project root as working directory (when available)

### Context-Aware Integration ✨

- 📄 **File Context** - Automatically pass current file with cursor position
- ✂️ **Selection Context** - Send visual selections directly to Claude
- 🔍 **Smart Context** - Auto-detect whether to send file or selection
- 🌐 **Workspace Context** - Enhanced context with related files through imports/requires
- 📚 **Recent Files** - Access to recently edited files in project
- 🔗 **Related Files** - Automatic discovery of imported/required files
- 🌳 **Project Tree** - Generate comprehensive file tree structures with intelligent filtering

### MCP Server (NEW!)

- 🔌 **Pure Lua MCP server** - No Node.js dependencies required
- 📝 **Direct buffer editing** - Claude Code can read and modify your Neovim buffers directly
- ⚡ **Real-time context** - Access to cursor position, buffer content, and editor state
- 🛠️ **Vim command execution** - Run any Vim command through Claude Code
- 📊 **Project awareness** - Access to git status, LSP diagnostics, and project structure
- 🎯 **Enhanced resource providers** - Buffer list, current file, related files, recent files, workspace context
- 🔍 **Smart analysis tools** - Analyze related files, search workspace symbols, find project files
- 🔒 **Secure by design** - All operations go through Neovim's API

### Development

- 🧩 Modular and maintainable code structure
- 📋 Type annotations with LuaCATS for better IDE support
- ✅ Configuration validation to prevent errors
- 🧪 Testing framework for reliability (44 comprehensive tests)

## Planned Features for IDE Integration Parity

To match the full feature set of GUI IDE integrations (VSCode, JetBrains, etc.), the following features are planned:

- **File Reference Shortcut:** Keyboard mapping to insert `@File#L1-99` style references into Claude prompts.
- **External `/ide` Command Support:** Ability to attach an external Claude Code CLI session to a running Neovim MCP server, similar to the `/ide` command in GUI IDEs.
- **User-Friendly Config UI:** A terminal-based UI for configuring plugin options, making setup more accessible for all users.

These features are tracked in the [ROADMAP.md](ROADMAP.md) and will ensure full parity with Anthropic's official IDE integrations.

## Requirements

- Neovim 0.7.0 or later
- [Claude Code CLI](https://github.com/anthropics/claude-code) installed
  - The plugin automatically detects Claude Code in the following order:
    1. Custom path specified in `config.cli_path` (if provided)
    2. Local installation at `~/.claude/local/claude` (preferred)
    3. Falls back to `claude` in PATH
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
- **`analyze_related`** - Analyze files related through imports/requires (NEW!)
- **`find_symbols`** - Search workspace symbols using LSP (NEW!)
- **`search_files`** - Find files by pattern with optional content preview (NEW!)

### Available Resources

The MCP server exposes these resources:

- **`neovim://current-buffer`** - Content of the currently active buffer
- **`neovim://buffers`** - List of all open buffers with metadata
- **`neovim://project`** - Project file structure
- **`neovim://git-status`** - Current git repository status
- **`neovim://lsp-diagnostics`** - LSP diagnostics for current buffer
- **`neovim://options`** - Current Neovim configuration and options
- **`neovim://related-files`** - Files related through imports/requires (NEW!)
- **`neovim://recent-files`** - Recently accessed project files (NEW!)
- **`neovim://workspace-context`** - Enhanced context with all related information (NEW!)
- **`neovim://search-results`** - Current search results and quickfix list (NEW!)

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
      visual = true,         -- Enable visual selection tool
      analyze_related = true,-- Enable related files analysis tool
      find_symbols = true,   -- Enable workspace symbol search tool
      search_files = true    -- Enable project file search tool
    },
    resources = {
      current_buffer = true,    -- Expose current buffer content
      buffer_list = true,       -- Expose list of all buffers
      project_structure = true, -- Expose project file structure
      git_status = true,        -- Expose git repository status
      lsp_diagnostics = true,   -- Expose LSP diagnostics
      vim_options = true,       -- Expose Neovim configuration
      related_files = true,     -- Expose files related through imports
      recent_files = true,      -- Expose recently accessed files
      workspace_context = true, -- Expose enhanced workspace context
      search_results = true     -- Expose search results and quickfix
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
  cli_path = nil,            -- Optional custom path to Claude CLI executable (e.g., "/custom/path/to/claude")
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
- `mcp__neovim__analyze_related` - Analyze related files through imports
- `mcp__neovim__find_symbols` - Search workspace symbols
- `mcp__neovim__search_files` - Find project files by pattern

**Resources** (Information Claude Code can access):

- `mcp__neovim__current_buffer` - Current buffer content
- `mcp__neovim__buffer_list` - List of open buffers
- `mcp__neovim__project_structure` - Project file tree
- `mcp__neovim__git_status` - Git repository status
- `mcp__neovim__lsp_diagnostics` - LSP diagnostics
- `mcp__neovim__vim_options` - Vim configuration options
- `mcp__neovim__related_files` - Files related through imports/requires
- `mcp__neovim__recent_files` - Recently accessed project files
- `mcp__neovim__workspace_context` - Enhanced workspace context
- `mcp__neovim__search_results` - Current search results and quickfix

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

### Context-Aware Usage Examples

```vim
" Pass current file with cursor position
:ClaudeCodeWithFile

" Send visual selection to Claude (select text first)
:'<,'>ClaudeCodeWithSelection

" Smart detection - uses selection if available, otherwise current file
:ClaudeCodeWithContext

" Enhanced workspace context with related files
:ClaudeCodeWithWorkspace

" Project file tree structure for codebase overview
:ClaudeCodeWithProjectTree
```

The context-aware commands automatically include relevant information:

- **File context**: Passes file path with line number (`file.lua#42`)
- **Selection context**: Creates a temporary markdown file with selected text
- **Workspace context**: Includes related files through imports, recent files, and current file content
- **Project tree context**: Provides a comprehensive file tree structure with configurable depth and filtering

### Commands

#### Basic Commands

- `:ClaudeCode` - Toggle the Claude Code terminal window
- `:ClaudeCodeVersion` - Display the plugin version

#### Context-Aware Commands ✨

- `:ClaudeCodeWithFile` - Toggle with current file and cursor position
- `:ClaudeCodeWithSelection` - Toggle with visual selection
- `:ClaudeCodeWithContext` - Smart context detection (file or selection)
- `:ClaudeCodeWithWorkspace` - Enhanced workspace context with related files
- `:ClaudeCodeWithProjectTree` - Toggle with project file tree structure

#### Conversation Management Commands

- `:ClaudeCodeContinue` - Resume the most recent conversation
- `:ClaudeCodeResume` - Display an interactive conversation picker

#### Output Options Command

- `:ClaudeCodeVerbose` - Enable verbose logging with full turn-by-turn output

#### Window Management Commands

- `:ClaudeCodeHide` - Hide Claude Code window without stopping the process
- `:ClaudeCodeShow` - Show Claude Code window if hidden
- `:ClaudeCodeSafeToggle` - Safely toggle window without interrupting execution
- `:ClaudeCodeStatus` - Show current Claude Code process status
- `:ClaudeCodeInstances` - List all Claude Code instances and their states

#### MCP Integration Commands

- `:ClaudeCodeMCPStart` - Start MCP server
- `:ClaudeCodeMCPStop` - Stop MCP server  
- `:ClaudeCodeMCPStatus` - Show MCP server status
- `:ClaudeCodeMCPConfig` - Generate MCP configuration
- `:ClaudeCodeSetup` - Setup MCP integration

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

This plugin provides two complementary ways to interact with Claude Code:

### Terminal Interface

1. Creates a terminal buffer running the Claude Code CLI
2. Sets up autocommands to detect file changes on disk
3. Automatically reloads files when they're modified by Claude Code
4. Provides convenient keymaps and commands for toggling the terminal
5. Automatically detects git repositories and sets working directory to the git root

### Context-Aware Integration

1. Analyzes your codebase to discover related files through imports/requires
2. Tracks recently accessed files within your project
3. Provides multiple context modes (file, selection, workspace)
4. Automatically passes relevant context to Claude Code CLI
5. Supports multiple programming languages (Lua, JavaScript, TypeScript, Python, Go)

### MCP Server

1. Runs a pure Lua MCP server exposing Neovim functionality
2. Provides tools for Claude Code to directly edit buffers and run commands
3. Exposes enhanced resources including related files and workspace context
4. Enables programmatic access to your development environment

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

### File Reference Shortcut ✨

- Quickly insert a file reference in the form `@File#L1-99` into the Claude prompt input.
- **How to use:**
  - Press `<leader>cf` in normal mode to insert the current file and line (e.g., `@myfile.lua#L10`).
  - In visual mode, `<leader>cf` inserts the current file and selected line range (e.g., `@myfile.lua#L5-7`).
- **Where it works:**
  - Inserts into the Claude prompt input buffer (or falls back to the command line if not available).
- **Why:**
  - Useful for referencing code locations in your Claude conversations, just like in VSCode/JetBrains integrations.

**Examples:**

- Normal mode, cursor on line 10: `@myfile.lua#L10`
- Visual mode, lines 5-7 selected: `@myfile.lua#L5-7`
