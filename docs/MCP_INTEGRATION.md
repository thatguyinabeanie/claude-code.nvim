# MCP Integration with Claude Code CLI

## Overview

Claude Code Neovim plugin implements Model Context Protocol (MCP) server capabilities that enable seamless integration with Claude Code CLI. This document details the MCP integration specifics, configuration options, and usage instructions.

## MCP Server Implementation

The plugin provides a pure Lua HTTP server that implements the following MCP endpoints:

- `GET /mcp/config` - Returns server metadata, available tools, and resources
- `POST /mcp/session` - Creates a new session for the Claude Code CLI
- `DELETE /mcp/session/{session_id}` - Terminates an active session

## Tool Naming Convention

All tools follow the Claude/Anthropic naming convention:

```text
mcp__{server-name}__{tool-name}
```

For example:

- `mcp__neovim-lua__vim_buffer`
- `mcp__neovim-lua__vim_command`
- `mcp__neovim-lua__vim_edit`

This naming convention ensures that tools are properly identified and can be allowed via the `--allowedTools` CLI flag.

## Available Tools

| Tool | Description | Schema |
|------|-------------|--------|
| `mcp__neovim-lua__vim_buffer` | Read/write buffer content | `{ "filename": "string" }` |
| `mcp__neovim-lua__vim_command` | Execute Vim commands | `{ "command": "string" }` |
| `mcp__neovim-lua__vim_status` | Get current editor status | `{}` |
| `mcp__neovim-lua__vim_edit` | Edit buffer content | `{ "filename": "string", "mode": "string", "text": "string" }` |
| `mcp__neovim-lua__vim_window` | Manage windows | `{ "action": "string", "filename": "string?" }` |
| `mcp__neovim-lua__analyze_related` | Analyze related files | `{ "filename": "string", "depth": "number?" }` |
| `mcp__neovim-lua__search_files` | Search files by pattern | `{ "pattern": "string", "content_pattern": "string?" }` |

## Available Resources

| Resource URI | Description | MIME Type |
|--------------|-------------|-----------|
| `mcp__neovim-lua://current-buffer` | Contents of the current buffer | text/plain |
| `mcp__neovim-lua://buffers` | List of all open buffers | application/json |
| `mcp__neovim-lua://project` | Project structure and files | application/json |
| `mcp__neovim-lua://git-status` | Git status of current repository | application/json |
| `mcp__neovim-lua://lsp-diagnostics` | LSP diagnostics for workspace | application/json |

## Starting the MCP Server

Start the MCP server using the Neovim command:

```vim
:ClaudeCodeMCPStart
```

Or programmatically in Lua:

```lua
require('claude-code.mcp').start()
```

The server automatically starts on `127.0.0.1:27123` by default, but can be configured through options.

## Using with Claude Code CLI

### Basic Usage

```sh
claude code --mcp-config http://localhost:27123/mcp/config -e "Describe the current buffer"
```

### Restricting Tool Access

```sh
claude code --mcp-config http://localhost:27123/mcp/config --allowedTools mcp__neovim-lua__vim_buffer -e "What's in the buffer?"
```

### Using with Recent Claude Models

```sh
claude code --mcp-config http://localhost:27123/mcp/config --model claude-3-opus-20240229 -e "Help me refactor this Neovim plugin"
```

## Session Management

Each interaction with Claude Code CLI creates a unique session that can be tracked by the plugin. Sessions include:

- Session ID
- Creation timestamp
- Last activity time
- Client IP address

Sessions can be terminated manually using the DELETE endpoint or will timeout after a period of inactivity.

## Permissions Model

The plugin implements a permissions model that respects the `--allowedTools` flag from the CLI. When specified, only the tools explicitly allowed will be executed. This provides a security boundary for sensitive operations.

## Troubleshooting

### Connection Issues

If you encounter connection issues:

1. Verify the MCP server is running using `:ClaudeCodeMCPStatus`
2. Check firewall settings to ensure port 27123 is open
3. Try restarting the MCP server with `:ClaudeCodeMCPRestart`

### Permission Issues

If tool execution fails due to permissions:

1. Verify the tool name matches exactly the expected format
2. Check that the tool is included in `--allowedTools` if that flag is used
3. Review the plugin logs for specific error messages

## Advanced Configuration

### Custom Port

```lua
require('claude-code').setup({
  mcp = {
    http_server = {
      port = 8080
    }
  }
})
```

### Custom Host

```lua
require('claude-code').setup({
  mcp = {
    http_server = {
      host = "0.0.0.0"  -- Allow external connections
    }
  }
})
```

### Session Timeout

```lua
require('claude-code').setup({
  mcp = {
    session_timeout_minutes = 60  -- Default: 30
  }
})
```
