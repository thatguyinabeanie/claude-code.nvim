-- Test script for enhanced MCP server integration

print("Testing Enhanced MCP Server Integration")
print("=====================================")

-- 1. Check if mcp-neovim-server is installed
local mcp_installed = vim.fn.executable('mcp-neovim-server') == 1
print("1. MCP server installed:", mcp_installed)

-- 2. Check Neovim socket
local socket = vim.v.servername
print("2. Neovim socket:", socket ~= "" and socket or "Not available")

-- 3. Generate MCP config
local mcp = require('claude-code.mcp')
local success, config_path = mcp.generate_config(nil, 'claude-code')
print("3. MCP config generated:", success and config_path or "Failed")

-- 4. Test with the inspector (manual step)
if success then
  print("\n4. To test the enhanced server:")
  print("   a) In one terminal: nvim --listen /tmp/nvim")
  print("   b) In another terminal: cd to mcp-neovim-server directory")
  print("   c) Run: npm run inspector")
  print("   d) Test these enhanced tools:")
  print("      - vim_analyze_related")
  print("      - vim_find_symbols")
  print("      - vim_search_files") 
  print("      - vim_get_selection")
  print("   e) Test these enhanced resources:")
  print("      - nvim://project-structure")
  print("      - nvim://git-status")
  print("      - nvim://workspace-context")
end

-- 5. Quick functionality test
print("\n5. Quick functionality test:")
print("   Current buffer:", vim.api.nvim_buf_get_name(0))
print("   File type:", vim.bo.filetype)
print("   Modified:", vim.bo.modified)

print("\n✓ Basic setup complete!")
print("\nNext steps:")
print("1. Run :ClaudeCodeMCPStart")
print("2. Use: claude --mcp-config " .. (config_path or "~/.config/claude-code/neovim-mcp.json") .. " \"test the enhanced tools\"")