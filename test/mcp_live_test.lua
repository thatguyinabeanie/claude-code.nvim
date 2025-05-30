-- Claude Code MCP Live Test
-- This file provides a quick live test that Claude can use to demonstrate its ability
-- to interact with Neovim through the MCP server.

local M = {}

-- Colors for output
local colors = {
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  magenta = "\27[35m",
  cyan = "\27[36m",
  reset = "\27[0m",
}

-- Print colored text
local function cprint(color, text)
  print(colors[color] .. text .. colors.reset)
end

-- Create a test file for Claude to modify
function M.setup_test_file()
  -- Create a temp file in the project directory
  local file_path = "test/claude_live_test_file.txt"
  
  -- Check if file exists
  local exists = vim.fn.filereadable(file_path) == 1
  
  if exists then
    -- Delete existing file
    vim.fn.delete(file_path)
  end
  
  -- Create the file with test content
  local file = io.open(file_path, "w")
  if file then
    file:write("This is a test file for Claude Code MCP.\n")
    file:write("Claude should be able to read and modify this file.\n")
    file:write("\n")
    file:write("TODO: Claude should add content here to demonstrate MCP functionality.\n")
    file:write("\n")
    file:write("The current date and time is: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
    file:close()
    
    cprint("green", "✅ Created test file at: " .. file_path)
    return file_path
  else
    cprint("red", "❌ Failed to create test file")
    return nil
  end
end

-- Open the test file in a new buffer
function M.open_test_file(file_path)
  if not file_path then
    file_path = "test/claude_live_test_file.txt"
  end
  
  if vim.fn.filereadable(file_path) == 1 then
    -- Open the file in a new buffer
    vim.cmd("edit " .. file_path)
    cprint("green", "✅ Opened test file in buffer")
    return true
  else
    cprint("red", "❌ Test file not found: " .. file_path)
    return false
  end
end

-- Run a simple live test that Claude can use
function M.run_live_test()
  cprint("magenta", "======================================")
  cprint("magenta", "🔌 CLAUDE CODE MCP LIVE TEST 🔌")
  cprint("magenta", "======================================")
  
  -- Create a test file
  local file_path = M.setup_test_file()
  
  if not file_path then
    cprint("red", "❌ Cannot continue with live test, file creation failed")
    return false
  end
  
  -- Start MCP server if not already running
  local mcp_status = vim.api.nvim_exec2("ClaudeCodeMCPStatus", { output = true }).output
  if not string.find(mcp_status, "running") then
    cprint("yellow", "⚠️ MCP server not running, starting it now...")
    vim.cmd("ClaudeCodeMCPStart")
    -- Wait briefly to ensure it's started
    vim.cmd("sleep 500m")
  end
  
  -- Check if server started
  mcp_status = vim.api.nvim_exec2("ClaudeCodeMCPStatus", { output = true }).output
  if string.find(mcp_status, "running") then
    cprint("green", "✅ MCP server is running")
  else
    cprint("red", "❌ Failed to start MCP server")
    return false
  end
  
  -- Open the test file
  if not M.open_test_file(file_path) then
    return false
  end
  
  -- Instructions for Claude
  cprint("cyan", "\n=== INSTRUCTIONS FOR CLAUDE ===")
  cprint("yellow", "1. I've created a test file for you to modify")
  cprint("yellow", "2. Use the vim_buffer tool to read the file content")
  cprint("yellow", "3. Use the vim_edit tool to modify the file by:")
  cprint("yellow", "   - Replacing the TODO line with some actual content")
  cprint("yellow", "   - Adding a new section showing the capabilities you're testing")
  cprint("yellow", "4. Use the vim_command tool to save the file")
  cprint("yellow", "5. Describe what you did and what tools you used")
  
  -- Output additional context
  cprint("blue", "\n=== CONTEXT ===")
  cprint("blue", "Test file: " .. file_path)
  cprint("blue", "MCP server status: " .. mcp_status:gsub("\n", " "))
  
  cprint("magenta", "======================================")
  cprint("magenta", "🎬 TEST READY - CLAUDE CAN PROCEED 🎬")
  cprint("magenta", "======================================")
  
  return true
end

-- Register commands - these are already being registered in plugin/self_test_command.lua
-- We're keeping the function here for reference
function M.setup_commands()
  -- Commands are now registered in plugin/self_test_command.lua
end

return M
