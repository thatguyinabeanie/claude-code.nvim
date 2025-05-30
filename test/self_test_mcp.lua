-- Claude Code Neovim MCP-Specific Self-Test
-- This script will specifically test MCP server functionality

local M = {}

-- Test state to store results
M.results = {
  mcp_server_start = false,
  mcp_server_status = false,
  mcp_resources = false,
  mcp_tools = false,
}

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

-- Test MCP server start
function M.test_mcp_server_start()
  cprint("cyan", "🚀 Testing MCP server start")
  
  local success = pcall(function()
    -- Try to start MCP server
    vim.cmd("ClaudeCodeMCPStart")
    -- Wait briefly to ensure it's started
    vim.cmd("sleep 500m")
  end)
  
  if success then
    cprint("green", "✅ Successfully started MCP server")
    M.results.mcp_server_start = true
  else
    cprint("red", "❌ Failed to start MCP server")
  end
end

-- Test MCP server status
function M.test_mcp_server_status()
  cprint("cyan", "📊 Testing MCP server status")
  
  local status_output = nil
  
  -- Capture the output of ClaudeCodeMCPStatus
  local success = pcall(function()
    -- Use exec2 to capture output
    local result = vim.api.nvim_exec2("ClaudeCodeMCPStatus", { output = true })
    status_output = result.output
  end)
  
  if success and status_output and string.find(status_output, "running") then
    cprint("green", "✅ MCP server is running")
    cprint("blue", "   " .. status_output:gsub("\n", " | "))
    M.results.mcp_server_status = true
  else
    cprint("red", "❌ Failed to get MCP server status or server not running")
  end
end

-- Test MCP resources
function M.test_mcp_resources()
  cprint("cyan", "📚 Testing MCP resources")
  
  local mcp_module = require("claude-code.mcp")
  
  if mcp_module and mcp_module.resources then
    local resource_names = {}
    for name, _ in pairs(mcp_module.resources) do
      table.insert(resource_names, name)
    end
    
    if #resource_names > 0 then
      cprint("green", "✅ MCP resources available: " .. table.concat(resource_names, ", "))
      M.results.mcp_resources = true
    else
      cprint("red", "❌ No MCP resources found")
    end
  else
    cprint("red", "❌ Failed to access MCP resources module")
  end
end

-- Test MCP tools
function M.test_mcp_tools()
  cprint("cyan", "🔧 Testing MCP tools")
  
  local mcp_module = require("claude-code.mcp")
  
  if mcp_module and mcp_module.tools then
    local tool_names = {}
    for name, _ in pairs(mcp_module.tools) do
      table.insert(tool_names, name)
    end
    
    if #tool_names > 0 then
      cprint("green", "✅ MCP tools available: " .. table.concat(tool_names, ", "))
      M.results.mcp_tools = true
    else
      cprint("red", "❌ No MCP tools found")
    end
  else
    cprint("red", "❌ Failed to access MCP tools module")
  end
end

-- Check MCP server config
function M.test_mcp_config_generation()
  cprint("cyan", "📝 Testing MCP config generation")
  
  -- Test generating a config file to a temporary location
  local temp_file = os.tmpname()
  
  local success = pcall(function()
    vim.cmd("ClaudeCodeMCPConfig custom " .. temp_file)
  end)
  
  -- Check if file was created and contains the expected content
  local file_exists = vim.fn.filereadable(temp_file) == 1
  
  if success and file_exists then
    local content = vim.fn.readfile(temp_file)
    local has_expected_content = false
    
    for _, line in ipairs(content) do
      if string.find(line, "neovim%-server") then
        has_expected_content = true
        break
      end
    end
    
    if has_expected_content then
      cprint("green", "✅ Successfully generated MCP config")
    else
      cprint("yellow", "⚠️  Generated MCP config but content may be incorrect")
    end
    
    -- Clean up
    os.remove(temp_file)
  else
    cprint("red", "❌ Failed to generate MCP config")
  end
end

-- Stop MCP server
function M.stop_mcp_server()
  cprint("cyan", "🛑 Stopping MCP server")
  
  local success = pcall(function()
    vim.cmd("ClaudeCodeMCPStop")
  end)
  
  if success then
    cprint("green", "✅ Successfully stopped MCP server")
  else
    cprint("red", "❌ Failed to stop MCP server")
  end
end

-- Run all tests
function M.run_all_tests()
  cprint("magenta", "======================================")
  cprint("magenta", "🔌 CLAUDE CODE MCP SERVER TEST 🔌")
  cprint("magenta", "======================================")
  
  M.test_mcp_server_start()
  M.test_mcp_server_status()
  M.test_mcp_resources()
  M.test_mcp_tools()
  M.test_mcp_config_generation()
  
  -- Print summary
  cprint("magenta", "\n======================================")
  cprint("magenta", "📊 MCP TEST RESULTS SUMMARY 📊")
  cprint("magenta", "======================================")
  
  local all_passed = true
  local total_tests = 0
  local passed_tests = 0
  
  for test, result in pairs(M.results) do
    total_tests = total_tests + 1
    if result then
      passed_tests = passed_tests + 1
      cprint("green", "✅ " .. test .. ": PASSED")
    else
      all_passed = false
      cprint("red", "❌ " .. test .. ": FAILED")
    end
  end
  
  cprint("magenta", "--------------------------------------")
  if all_passed then
    cprint("green", "🎉 ALL TESTS PASSED! 🎉")
  else
    cprint("yellow", "⚠️  " .. passed_tests .. "/" .. total_tests .. " tests passed")
  end
  
  -- Stop the server before finishing
  M.stop_mcp_server()
  
  cprint("magenta", "======================================")
  
  return all_passed, passed_tests, total_tests
end

return M
