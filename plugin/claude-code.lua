-- claude-code.nvim plugin initialization file
-- This file is automatically loaded by Neovim when the plugin is in the runtimepath

-- Only load once
if vim.g.loaded_claude_code then
  return
end
vim.g.loaded_claude_code = 1

-- Auto-setup with MCP properly configured
-- Important: MCP server runs as part of Claude Code, NOT in Neovim
-- This avoids the performance issues you're experiencing
require('claude-code').setup({
  mcp = {
    auto_start = false,  -- Don't auto-start to avoid lag
    auto_server_start = true  -- Just prepare the socket
  }
})