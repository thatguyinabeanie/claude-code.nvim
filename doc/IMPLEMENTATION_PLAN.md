# Implementation Plan: Neovim MCP Server

## Decision Point: Language Choice

### Option A: TypeScript/Node.js
**Pros:**
- Can fork/improve mcp-neovim-server
- MCP SDK available for TypeScript
- Standard in MCP ecosystem
- Faster initial development

**Cons:**
- Requires Node.js runtime
- Not native to Neovim ecosystem
- Extra dependency for users

### Option B: Pure Lua
**Pros:**
- Native to Neovim (no extra deps)
- Better performance potential
- Tighter Neovim integration
- Aligns with plugin philosophy

**Cons:**
- Need to implement MCP protocol
- More initial work
- Less MCP tooling available

### Option C: Hybrid (Recommended)
**Start with TypeScript for MVP, plan Lua port:**
1. Fork/improve mcp-neovim-server
2. Add our enterprise features
3. Test with real users
4. Port to Lua once stable

## Integration into claude-code.nvim

We're extending the existing plugin with MCP server capabilities:

```
claude-code.nvim/                  # THIS REPOSITORY
├── lua/claude-code/               # Existing plugin code
│   ├── init.lua                  # Main plugin entry
│   ├── terminal.lua              # Current Claude CLI integration
│   ├── keymaps.lua              # Keybindings
│   └── mcp/                     # NEW: MCP integration
│       ├── init.lua             # MCP module entry
│       ├── server.lua           # Server lifecycle management
│       ├── config.lua           # MCP-specific config
│       └── health.lua           # Health checks
├── mcp-server/                   # NEW: MCP server component
│   ├── package.json
│   ├── tsconfig.json
│   ├── src/
│   │   ├── index.ts            # Entry point
│   │   ├── server.ts           # MCP server implementation
│   │   ├── neovim/
│   │   │   ├── client.ts       # Neovim RPC client
│   │   │   ├── buffers.ts      # Buffer operations
│   │   │   ├── commands.ts     # Command execution
│   │   │   └── lsp.ts          # LSP integration
│   │   ├── tools/
│   │   │   ├── edit.ts         # Edit operations
│   │   │   ├── read.ts         # Read operations
│   │   │   ├── search.ts       # Search tools
│   │   │   └── refactor.ts     # Refactoring tools
│   │   ├── resources/
│   │   │   ├── buffers.ts      # Buffer list resource
│   │   │   ├── diagnostics.ts  # LSP diagnostics
│   │   │   └── project.ts      # Project structure
│   │   └── security/
│   │       ├── permissions.ts   # Permission system
│   │       └── audit.lua        # Audit logging
│   └── tests/
└── doc/                          # Existing + new documentation
    ├── claude-code.txt          # Existing vim help
    └── mcp-integration.txt      # NEW: MCP help docs
```

## How It Works Together

1. **User installs claude-code.nvim** (this plugin)
2. **Plugin provides MCP server** as part of installation
3. **When user runs `:ClaudeCode`**, plugin:
   - Starts MCP server if needed
   - Configures Claude Code CLI to use it
   - Maintains existing CLI integration
4. **Claude Code gets IDE features** via MCP server

## Implementation Phases

### Phase 1: MVP (Week 1-2)
**Goal:** Basic working MCP server

1. **Setup Project**
   - Fork mcp-neovim-server
   - Set up TypeScript project
   - Add tests infrastructure

2. **Core Tools**
   - `edit_buffer`: Edit current buffer
   - `read_buffer`: Read buffer content
   - `list_buffers`: List open buffers
   - `execute_command`: Run Vim commands

3. **Basic Resources**
   - `current_buffer`: Active buffer info
   - `open_buffers`: List of buffers

4. **Integration**
   - Test with mcp-hub
   - Test with Claude Code CLI
   - Basic documentation

### Phase 2: Enhanced Features (Week 3-4)
**Goal:** Productivity features

1. **Advanced Tools**
   - `search_project`: Project-wide search
   - `rename_symbol`: LSP rename
   - `go_to_definition`: Navigation
   - `find_references`: Find usages

2. **Rich Resources**
   - `diagnostics`: LSP errors/warnings
   - `project_tree`: File structure
   - `git_status`: Repository state
   - `symbols`: Code outline

3. **UX Improvements**
   - Better error messages
   - Progress indicators
   - Operation previews

### Phase 3: Enterprise Features (Week 5-6)
**Goal:** Security and compliance

1. **Security**
   - Permission model
   - Path restrictions
   - Operation limits
   - Audit logging

2. **Performance**
   - Caching layer
   - Batch operations
   - Lazy loading

3. **Integration**
   - Neovim plugin helpers
   - Auto-configuration
   - Health checks

### Phase 4: Lua Port (Week 7-8)
**Goal:** Native implementation

1. **Port Core**
   - MCP protocol in Lua
   - Server infrastructure
   - Tool implementations

2. **Optimize**
   - Remove Node.js dependency
   - Improve performance
   - Reduce memory usage

## Next Immediate Steps

### 1. Validate Approach (Today)
```bash
# Test mcp-neovim-server with mcp-hub
npm install -g @bigcodegen/mcp-neovim-server
nvim --listen /tmp/nvim

# In another terminal
# Configure with mcp-hub and test
```

### 2. Setup Development (Today/Tomorrow)
```bash
# Create MCP server directory
mkdir mcp-server
cd mcp-server
npm init -y
npm install @modelcontextprotocol/sdk
npm install neovim-client
```

### 3. Create Minimal Server (This Week)
- Implement basic MCP server
- Add one tool (edit_buffer)
- Test with Claude Code

## Success Criteria

### MVP Success:
- [ ] Server starts and registers with mcp-hub
- [ ] Claude Code can connect and list tools
- [ ] Basic edit operations work
- [ ] No crashes or data loss

### Full Success:
- [ ] All planned tools implemented
- [ ] Enterprise features working
- [ ] Performance targets met
- [ ] Positive user feedback
- [ ] Lua port completed

## Questions to Resolve

1. **Naming**: What should we call our server?
   - `claude-code-mcp-server`
   - `nvim-mcp-server`
   - `neovim-claude-mcp`

2. **Distribution**: How to package?
   - npm package for TypeScript version
   - Built into claude-code.nvim for Lua
   - Separate repository?

3. **Configuration**: Where to store config?
   - Part of claude-code.nvim config
   - Separate MCP server config
   - Both with sync?

## Let's Start!

Ready to begin with:
1. Testing existing mcp-neovim-server
2. Setting up TypeScript project
3. Creating our first improved tool

What would you like to tackle first?