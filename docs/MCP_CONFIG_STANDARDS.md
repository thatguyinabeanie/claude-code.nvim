# MCP Configuration Standards

## Overview

The Model Context Protocol (MCP) is an open standard by Anthropic that standardizes how AI applications connect with external tools and data sources. Different tools use slightly different configuration formats.

## Configuration Formats by Tool

### 1. Claude Code CLI

**File locations:**
- `.claude.json` (project-specific) - Full Claude Code CLI config
- `~/.claude.json` (global) - User's Claude Code CLI config
- `.mcp.json` (project-specific) - MCP-only config

**Format for .claude.json:**
```json
{
  "numStartups": 34,
  "theme": "dark",
  "projects": {
    "/path/to/project": {
      "mcpServers": {
        "server-name": {
          "command": "command",
          "args": [],
          "env": {}
        }
      }
    }
  },
  "mcpServers": {
    "global-server": {
      "command": "/path/to/server",
      "args": [],
      "env": {}
    }
  }
}
```

**Format for .mcp.json (MCP-only):**
```json
{
  "mcpServers": {
    "server-name": {
      "command": "/path/to/server",
      "args": [],
      "env": {}
    }
  }
}
```

### 2. Claude Desktop

**File location:** 
- `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS)

**Format:** Same as .mcp.json above

### 3. VS Code

**File location:** `.vscode/mcp.json`

**Format:**

```json
{
  "servers": {
    "server-name": {
      "type": "stdio",
      "command": "command-to-run",
      "args": ["arg1", "arg2"],
      "env": {
        "ENV_VAR": "value"
      }
    }
  }
}
```

### 4. Cursor

**File locations:**

- `.cursor/mcp.json` (project-specific)
- `~/.cursor/mcp.json` (global)

**Format:** Same as Claude (uses `mcpServers` wrapper)

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "mcp-server"],
      "env": {
        "API_KEY": "value"
      }
    }
  }
}
```

## Key Differences

1. **Root Property:**
   - Claude/Cursor: `"mcpServers"`
   - VS Code: `"servers"`

2. **Transport Type:**
   - Claude/Cursor: Implicit (defaults to stdio)
   - VS Code: Explicit `"type"` field ("stdio", "sse", "http")

3. **Additional VS Code Fields:**
   - `cwd`: Working directory
   - `url`: For HTTP connections
   - `headers`: For HTTP connections

## Format Examples for mcp-neovim-server

### Claude/Cursor Format (.claude.json, .mcp.json, .cursor/mcp.json)
```json
{
  "mcpServers": {
    "neovim": {
      "command": "mcp-neovim-server",
      "args": [],
      "env": {
        "NVIM": "/var/folders/.../nvim.12345.0"
      }
    }
  }
}
```

### VS Code Format (.vscode/mcp.json)
```json
{
  "servers": {
    "neovim": {
      "type": "stdio",
      "command": "mcp-neovim-server",
      "args": [],
      "env": {
        "NVIM": "/var/folders/.../nvim.12345.0"
      }
    }
  }
}
```

## Recommended Approach for claude-code.nvim

### 1. Primary Format
Use the Claude/Cursor format with `mcpServers` wrapper as the standard.

### 2. Configuration Loading Order

All configuration files are loaded and merged together:

#### Global Configs (Lower Priority)
Loaded first, can be overridden by project configs:
1. `~/.claude.json` - Claude Code CLI global config
2. `~/.mcp.json` - Generic MCP global config  
3. `~/.cursor/mcp.json` - Cursor editor global config
4. `~/Library/Application Support/Claude/claude_desktop_config.json` - Claude Desktop (macOS)

#### Project Configs (Higher Priority)
Loaded after global configs, override any conflicting settings:
1. `.vscode/mcp.json` - VS Code workspace config (format converted)
2. `.cursor/mcp.json` - Cursor workspace config
3. `.mcp.json` - Generic MCP project config
4. `.claude.json` - Claude Code CLI project config (highest priority)

**Note:** Within each category, later files in the list have higher precedence.

### 3. Auto-Configuration File Selection

When the plugin needs to add `mcp-neovim-server` configuration:

1. **If existing config files are found**, adds to the first one in this order:
   - `.claude.json` (preferred for Claude Code integration)
   - `.mcp.json`
   - `.cursor/mcp.json`
   - `.vscode/mcp.json`

2. **If no config files exist**, creates `.claude.json` by default

### 4. Merge Strategy
- All available configs are loaded
- Global configs provide base settings
- Project configs override global configs
- For the same server name, later configs override earlier ones
- Server configurations are deep-merged (nested properties are preserved)

### 5. Generated Config
Always generate in standard format:

```json
{
  "mcpServers": {
    "neovim": {
      "command": "mcp-neovim-server",
      "args": [],
      "env": {}
    }
  }
}
```

## Implementation Notes

- Load configurations from ALL available sources, not just the first found
- When loading `.vscode/mcp.json`, convert from `"servers"` to `"mcpServers"` format internally
- Merge configurations with project configs taking precedence over global configs
- Support both formats for maximum compatibility
- Always generate the standard format to avoid confusion
- Include all fields (`args`, `env`) even if empty for consistency
- When adding to existing files, use the appropriate format:
  - VS Code files: Include `"type": "stdio"` field
  - Claude/Cursor files: No type field needed
  - All formats: Include NVIM socket in env when available

## Commands

- `:ClaudeCodeMCPConfig` - Generate a new MCP configuration file
- `:ClaudeCodeMCPDetect` - Detect existing MCP configuration files
- `:ClaudeCodeMCPShow` - Show the merged configuration from all sources
- `:ClaudeCodeMCPStart` - Setup MCP integration and display instructions
