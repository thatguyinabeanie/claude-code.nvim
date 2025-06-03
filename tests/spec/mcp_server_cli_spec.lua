local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local assert = require('luassert')

-- Mock system/Neovim API as needed for CLI invocation
local mcp_server = require('claude-code.mcp_server')

-- Helper to simulate CLI args
local function run_with_args(args)
  -- This would call the plugin's CLI entrypoint with args
  -- For now, just call the function directly
  return mcp_server.cli_entry(args)
end

describe('MCP Server CLI Integration', function()
  it('starts MCP server with --start-mcp-server', function()
    local result = run_with_args({ '--start-mcp-server' })
    assert.is_true(result.started)
  end)

  it('outputs ready status message', function()
    local result = run_with_args({ '--start-mcp-server' })
    assert.is_truthy(result.status and result.status:match('MCP server ready'))
  end)

  it('listens on expected port/socket', function()
    local result = run_with_args({ '--start-mcp-server' })

    -- Use flexible port validation instead of hardcoded value
    assert.is_number(result.port)
    assert.is_true(result.port > 1024, 'Port should be above reserved range')
    assert.is_true(result.port < 65536, 'Port should be within valid range')
  end)
end)

describe('MCP Server CLI Integration (Remote Attach)', function()
  it('attempts to discover a running Neovim MCP server', function()
    local result = run_with_args({ '--remote-mcp' })
    assert.is_true(result.discovery_attempted)
  end)

  it('connects successfully if a compatible instance is found', function()
    local result = run_with_args({ '--remote-mcp', '--mock-found' })
    assert.is_true(result.connected)
  end)

  it("outputs a 'connected' status message", function()
    local result = run_with_args({ '--remote-mcp', '--mock-found' })
    assert.is_truthy(
      result.status and result.status:match('Connected to running Neovim MCP server')
    )
  end)

  it('outputs a clear error if no instance is found', function()
    local result = run_with_args({ '--remote-mcp', '--mock-not-found' })
    assert.is_false(result.connected)
    assert.is_truthy(result.status and result.status:match('No running Neovim MCP server found'))
  end)

  it('outputs a relevant error if connection fails', function()
    local result = run_with_args({ '--remote-mcp', '--mock-conn-fail' })
    assert.is_false(result.connected)
    assert.is_truthy(
      result.status and result.status:match('Failed to connect to Neovim MCP server')
    )
  end)
end)

describe('MCP Server Shell Function/Alias Integration', function()
  it('launches the MCP server if none is running', function()
    local result = run_with_args({ '--shell-mcp', '--mock-no-server' })
    assert.equals('launched', result.action)
    assert.is_truthy(result.status and result.status:match('MCP server launched'))
  end)

  it('attaches to an existing MCP server if one is running', function()
    local result = run_with_args({ '--shell-mcp', '--mock-server-running' })
    assert.equals('attached', result.action)
    assert.is_truthy(result.status and result.status:match('Attached to running MCP server'))
  end)

  it('provides clear feedback about the action taken', function()
    local result1 = run_with_args({ '--shell-mcp', '--mock-no-server' })
    assert.is_truthy(result1.status and result1.status:match('MCP server launched'))
    local result2 = run_with_args({ '--shell-mcp', '--mock-server-running' })
    assert.is_truthy(result2.status and result2.status:match('Attached to running MCP server'))
  end)
end)

describe('Neovim Ex Commands for MCP Server', function()
  it(':ClaudeMCPStart starts the MCP server and shows a success notification', function()
    local result = run_with_args({ '--ex-cmd', 'start' })
    assert.equals(':ClaudeMCPStart', result.cmd)
    assert.is_true(result.started)
    assert.is_truthy(result.notify and result.notify:match('MCP server started'))
  end)

  it(
    ':ClaudeMCPAttach attaches to a running MCP server and shows a success notification',
    function()
      local result = run_with_args({ '--ex-cmd', 'attach', '--mock-server-running' })
      assert.equals(':ClaudeMCPAttach', result.cmd)
      assert.is_true(result.attached)
      assert.is_truthy(result.notify and result.notify:match('Attached to MCP server'))
    end
  )

  it(':ClaudeMCPStatus displays the current MCP server status', function()
    local result = run_with_args({ '--ex-cmd', 'status', '--mock-server-running' })
    assert.equals(':ClaudeMCPStatus', result.cmd)
    assert.is_truthy(result.status and result.status:match('MCP server running on port'))
  end)

  it(':ClaudeMCPStatus displays not running if no server', function()
    local result = run_with_args({ '--ex-cmd', 'status', '--mock-no-server' })
    assert.equals(':ClaudeMCPStatus', result.cmd)
    assert.is_truthy(result.status and result.status:match('MCP server not running'))
  end)

  it(':ClaudeMCPStart shows error notification if start fails', function()
    local result = run_with_args({ '--ex-cmd', 'start', '--mock-fail' })
    assert.equals(':ClaudeMCPStart', result.cmd)
    assert.is_false(result.started)
    assert.is_truthy(result.notify and result.notify:match('Failed to start MCP server'))
  end)

  it(':ClaudeMCPAttach shows error notification if attach fails', function()
    local result = run_with_args({ '--ex-cmd', 'attach', '--mock-fail' })
    assert.equals(':ClaudeMCPAttach', result.cmd)
    assert.is_false(result.attached)
    assert.is_truthy(result.notify and result.notify:match('Failed to attach to MCP server'))
  end)
end)
