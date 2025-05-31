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
  return { started = false, status = "No action", port = nil }
end

return M 