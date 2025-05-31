# MCP Hub Architecture for claude-code.nvim

## Overview

Instead of building everything from scratch, we leverage the existing mcp-hub ecosystem:

```
┌─────────────┐     ┌─────────────┐     ┌──────────────────┐     ┌────────────┐
│ Claude Code │ ──► │   mcp-hub   │ ──► │ nvim-mcp-server  │ ──► │   Neovim   │
│     CLI     │     │(coordinator)│     │   (our server)   │     │  Instance  │
└─────────────┘     └─────────────┘     └──────────────────┘     └────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ Other MCP    │
                    │ Servers      │
                    └──────────────┘
```

## Components

### 1. mcphub.nvim (Already Exists)

- Neovim plugin that manages MCP servers
- Provides UI for server configuration
- Handles server lifecycle
- REST API at `http://localhost:37373`

### 2. Our MCP Server (To Build)

- Exposes Neovim capabilities as MCP tools/resources
- Connects to Neovim via RPC/socket
- Registers with mcp-hub
- Handles enterprise security requirements

### 3. Claude Code CLI Integration

- Configure Claude Code to use mcp-hub
- Access all registered MCP servers
- Including our Neovim server

## Implementation Strategy

### Phase 1: Build MCP Server

Create a robust MCP server that:

- Implements MCP protocol (tools, resources)
- Connects to Neovim via socket/RPC
- Provides enterprise security features
- Works with mcp-hub

### Phase 2: Integration

1. Users install mcphub.nvim
2. Users install our MCP server
3. Register server with mcp-hub
4. Configure Claude Code to use mcp-hub

## Advantages

1. **Ecosystem Integration**
   - Leverage existing infrastructure
   - Work with other MCP servers
   - Standard configuration

2. **User Experience**
   - Single UI for all MCP servers
   - Easy server management
   - Works with multiple chat plugins

3. **Development Efficiency**
   - Don't reinvent coordination layer
   - Focus on Neovim-specific features
   - Benefit from mcp-hub improvements

## Server Configuration

### In mcp-hub servers.json

```json
{
  "claude-code-nvim": {
    "command": "claude-code-mcp-server",
    "args": ["--socket", "/tmp/nvim.sock"],
    "env": {
      "NVIM_LISTEN_ADDRESS": "/tmp/nvim.sock"
    }
  }
}
```

### In Claude Code

```bash
# Configure Claude Code to use mcp-hub
claude mcp add mcp-hub http://localhost:37373 --transport sse

# Now Claude can access all servers managed by mcp-hub
claude "Edit the current buffer in Neovim"
```

## MCP Server Implementation

### Core Features to Implement

#### 1. Tools

```typescript
// Essential editing tools
- edit_buffer: Modify buffer content
- read_buffer: Get buffer content
- list_buffers: Show open buffers
- execute_command: Run Vim commands
- search_project: Find in files
- get_diagnostics: LSP diagnostics
```

#### 2. Resources

```typescript
// Contextual information
- current_buffer: Active buffer info
- project_structure: File tree
- git_status: Repository state
- lsp_symbols: Code symbols
```

#### 3. Security

```typescript
// Enterprise features
- Permission model
- Audit logging
- Path restrictions
- Operation limits
```

## Benefits Over Direct Integration

1. **Standardization**: Use established mcp-hub patterns
2. **Flexibility**: Users can add other MCP servers
3. **Maintenance**: Leverage mcp-hub updates
4. **Discovery**: Servers visible in mcp-hub UI
5. **Multi-client**: Multiple tools can access same servers

## Next Steps

1. **Study mcp-neovim-server**: Understand implementation
2. **Design our server**: Plan improvements and features
3. **Build MVP**: Focus on core editing capabilities
4. **Test with mcp-hub**: Ensure smooth integration
5. **Add enterprise features**: Security, audit, etc.

## Example User Flow

```bash
# 1. Install mcphub.nvim (already has mcp-hub)
:Lazy install mcphub.nvim

# 2. Install our MCP server
npm install -g @claude-code/nvim-mcp-server

# 3. Start Neovim with socket
nvim --listen /tmp/nvim.sock myfile.lua

# 4. Register our server with mcp-hub (automatic or manual)
# This happens via mcphub.nvim UI or config

# 5. Use Claude Code with full Neovim access
claude "Refactor this function to use async/await"
```

## Conclusion

By building on top of mcp-hub, we get:

- Proven infrastructure
- Better user experience  
- Ecosystem compatibility
- Faster time to market

We focus our efforts on making the best possible Neovim MCP server while leveraging existing coordination infrastructure.
