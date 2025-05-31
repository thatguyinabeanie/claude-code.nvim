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

test.describe("MCP Server CLI Integration (Remote Attach)", function()
  test.it("attempts to discover a running Neovim MCP server", function()
    local result = run_with_args({"--remote-mcp"})
    test.expect(result.discovery_attempted).to_be(true)
  end)

  test.it("connects successfully if a compatible instance is found", function()
    local result = run_with_args({"--remote-mcp", "--mock-found"})
    test.expect(result.connected).to_be(true)
  end)

  test.it("outputs a 'connected' status message", function()
    local result = run_with_args({"--remote-mcp", "--mock-found"})
    test.expect(result.status):to_contain("Connected to running Neovim MCP server")
  end)

  test.it("outputs a clear error if no instance is found", function()
    local result = run_with_args({"--remote-mcp", "--mock-not-found"})
    test.expect(result.connected).to_be(false)
    test.expect(result.status):to_contain("No running Neovim MCP server found")
  end)

  test.it("outputs a relevant error if connection fails", function()
    local result = run_with_args({"--remote-mcp", "--mock-conn-fail"})
    test.expect(result.connected).to_be(false)
    test.expect(result.status):to_contain("Failed to connect to Neovim MCP server")
  end)
end)

test.describe("MCP Server Shell Function/Alias Integration", function()
  test.it("launches the MCP server if none is running", function()
    local result = run_with_args({"--shell-mcp", "--mock-no-server"})
    test.expect(result.action).to_be("launched")
    test.expect(result.status):to_contain("MCP server launched")
  end)

  test.it("attaches to an existing MCP server if one is running", function()
    local result = run_with_args({"--shell-mcp", "--mock-server-running"})
    test.expect(result.action).to_be("attached")
    test.expect(result.status):to_contain("Attached to running MCP server")
  end)

  test.it("provides clear feedback about the action taken", function()
    local result1 = run_with_args({"--shell-mcp", "--mock-no-server"})
    test.expect(result1.status):to_contain("MCP server launched")
    local result2 = run_with_args({"--shell-mcp", "--mock-server-running"})
    test.expect(result2.status):to_contain("Attached to running MCP server")
  end)
end) 