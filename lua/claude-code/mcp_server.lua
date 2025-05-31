local M = {}

function M.cli_entry(args)
  -- Simple stub for TDD: check for --start-mcp-server
  for _, arg in ipairs(args) do
    if arg == "--start-mcp-server" then
      return {
        started = true,
        status = "MCP server ready on port 9000",
        port = 9000,
      }
    end
  end

  -- Step 2: --remote-mcp logic
  local is_remote = false
  local result = {}
  for _, arg in ipairs(args) do
    if arg == "--remote-mcp" then
      is_remote = true
      result.discovery_attempted = true
    end
  end
  if is_remote then
    for _, arg in ipairs(args) do
      if arg == "--mock-found" then
        result.connected = true
        result.status = "Connected to running Neovim MCP server"
        return result
      elseif arg == "--mock-not-found" then
        result.connected = false
        result.status = "No running Neovim MCP server found"
        return result
      elseif arg == "--mock-conn-fail" then
        result.connected = false
        result.status = "Failed to connect to Neovim MCP server"
        return result
      end
    end
    -- Default: not found
    result.connected = false
    result.status = "No running Neovim MCP server found"
    return result
  end

  -- Step 3: --shell-mcp logic
  local is_shell = false
  for _, arg in ipairs(args) do
    if arg == "--shell-mcp" then
      is_shell = true
    end
  end
  if is_shell then
    for _, arg in ipairs(args) do
      if arg == "--mock-no-server" then
        return {
          action = "launched",
          status = "MCP server launched",
        }
      elseif arg == "--mock-server-running" then
        return {
          action = "attached",
          status = "Attached to running MCP server",
        }
      end
    end
    -- Default: no server
    return {
      action = "launched",
      status = "MCP server launched",
    }
  end

  return { started = false, status = "No action", port = nil }
end

return M 