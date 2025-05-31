local test = require("tests.run_tests")

-- Mock system/Neovim API as needed for CLI invocation
local mcp_server = require("claude-code.mcp_server")

-- Helper to simulate CLI args
local function run_with_args(args)
  -- This would call the plugin's CLI entrypoint with args
  -- For now, just call the function directly
  return mcp_server.cli_entry(args)
end

test.describe("MCP Server CLI Integration", function()
  test.it("starts MCP server with --start-mcp-server", function()
    local result = run_with_args({"--start-mcp-server"})
    test.expect(result.started).to_be(true)
  end)

  test.it("outputs ready status message", function()
    local result = run_with_args({"--start-mcp-server"})
    test.expect(result.status):to_contain("MCP server ready")
  end)

  test.it("listens on expected port/socket", function()
    local result = run_with_args({"--start-mcp-server"})
    test.expect(result.port):to_be(9000) -- or whatever default port/socket
  end)
end) 