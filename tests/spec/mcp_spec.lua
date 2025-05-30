local assert = require('luassert')

describe("MCP Integration", function()
  local mcp

  before_each(function()
    -- Reset package loaded state
    package.loaded['claude-code.mcp'] = nil
    package.loaded['claude-code.mcp.init'] = nil
    package.loaded['claude-code.mcp.tools'] = nil
    package.loaded['claude-code.mcp.resources'] = nil
    package.loaded['claude-code.mcp.server'] = nil
    package.loaded['claude-code.mcp.hub'] = nil
    
    -- Load the MCP module
    local ok, module = pcall(require, 'claude-code.mcp')
    if ok then
      mcp = module
    end
  end)

  describe("Module Loading", function()
    it("should load MCP module without errors", function()
      assert.is_not_nil(mcp)
      assert.is_table(mcp)
    end)

    it("should have required functions", function()
      assert.is_function(mcp.setup)
      assert.is_function(mcp.start)
      assert.is_function(mcp.stop)
      assert.is_function(mcp.status)
      assert.is_function(mcp.generate_config)
      assert.is_function(mcp.setup_claude_integration)
    end)
  end)

  describe("Configuration Generation", function()
    it("should generate claude-code config format", function()
      local temp_file = vim.fn.tempname() .. ".json"
      local success, path = mcp.generate_config(temp_file, "claude-code")
      
      assert.is_true(success)
      assert.equals(temp_file, path)
      assert.equals(1, vim.fn.filereadable(temp_file))
      
      -- Verify JSON structure
      local file = io.open(temp_file, "r")
      local content = file:read("*all")
      file:close()
      
      local config = vim.json.decode(content)
      assert.is_table(config.mcpServers)
      assert.is_table(config.mcpServers.neovim)
      assert.is_string(config.mcpServers.neovim.command)
      
      -- Cleanup
      vim.fn.delete(temp_file)
    end)

    it("should generate workspace config format", function()
      local temp_file = vim.fn.tempname() .. ".json"
      local success, path = mcp.generate_config(temp_file, "workspace")
      
      assert.is_true(success)
      
      local file = io.open(temp_file, "r")
      local content = file:read("*all")
      file:close()
      
      local config = vim.json.decode(content)
      assert.is_table(config.neovim)
      assert.is_string(config.neovim.command)
      
      -- Cleanup
      vim.fn.delete(temp_file)
    end)
  end)

  describe("Server Management", function()
    it("should initialize without errors", function()
      local success = pcall(mcp.setup)
      assert.is_true(success)
    end)

    it("should return server status", function()
      mcp.setup()
      local status = mcp.status()
      
      assert.is_table(status)
      assert.is_string(status.name)
      assert.is_string(status.version)
      assert.is_boolean(status.initialized)
      assert.is_number(status.tool_count)
      assert.is_number(status.resource_count)
    end)
  end)
end)

describe("MCP Tools", function()
  local tools

  before_each(function()
    package.loaded['claude-code.mcp.tools'] = nil
    local ok, module = pcall(require, 'claude-code.mcp.tools')
    if ok then
      tools = module
    end
  end)

  it("should load tools module", function()
    assert.is_not_nil(tools)
    assert.is_table(tools)
  end)

  it("should have expected tools", function()
    local expected_tools = {
      "vim_buffer", "vim_command", "vim_status", "vim_edit",
      "vim_window", "vim_mark", "vim_register", "vim_visual"
    }
    
    for _, tool_name in ipairs(expected_tools) do
      assert.is_table(tools[tool_name], "Tool " .. tool_name .. " should exist")
      assert.is_string(tools[tool_name].name)
      assert.is_string(tools[tool_name].description)
      assert.is_table(tools[tool_name].inputSchema)
      assert.is_function(tools[tool_name].handler)
    end
  end)

  it("should have valid tool schemas", function()
    for tool_name, tool in pairs(tools) do
      assert.is_table(tool.inputSchema)
      assert.equals("object", tool.inputSchema.type)
      assert.is_table(tool.inputSchema.properties)
    end
  end)
end)

describe("MCP Resources", function()
  local resources

  before_each(function()
    package.loaded['claude-code.mcp.resources'] = nil
    local ok, module = pcall(require, 'claude-code.mcp.resources')
    if ok then
      resources = module
    end
  end)

  it("should load resources module", function()
    assert.is_not_nil(resources)
    assert.is_table(resources)
  end)

  it("should have expected resources", function()
    local expected_resources = {
      "current_buffer", "buffer_list", "project_structure",
      "git_status", "lsp_diagnostics", "vim_options"
    }
    
    for _, resource_name in ipairs(expected_resources) do
      assert.is_table(resources[resource_name], "Resource " .. resource_name .. " should exist")
      assert.is_string(resources[resource_name].uri)
      assert.is_string(resources[resource_name].description)
      assert.is_string(resources[resource_name].mimeType)
      assert.is_function(resources[resource_name].handler)
    end
  end)
end)

describe("MCP Hub", function()
  local hub

  before_each(function()
    package.loaded['claude-code.mcp.hub'] = nil
    local ok, module = pcall(require, 'claude-code.mcp.hub')
    if ok then
      hub = module
    end
  end)

  it("should load hub module", function()
    assert.is_not_nil(hub)
    assert.is_table(hub)
  end)

  it("should have required functions", function()
    assert.is_function(hub.setup)
    assert.is_function(hub.register_server)
    assert.is_function(hub.get_server)
    assert.is_function(hub.list_servers)
    assert.is_function(hub.generate_config)
  end)

  it("should list default servers", function()
    local servers = hub.list_servers()
    assert.is_table(servers)
    assert.is_true(#servers > 0)
    
    -- Check for claude-code-neovim server
    local found_native = false
    for _, server in ipairs(servers) do
      if server.name == "claude-code-neovim" then
        found_native = true
        assert.is_true(server.native)
        break
      end
    end
    assert.is_true(found_native, "Should have claude-code-neovim server")
  end)

  it("should register and retrieve servers", function()
    local test_server = {
      command = "test-command",
      description = "Test server",
      tags = {"test"}
    }
    
    local success = hub.register_server("test-server", test_server)
    assert.is_true(success)
    
    local retrieved = hub.get_server("test-server")
    assert.is_table(retrieved)
    assert.equals("test-command", retrieved.command)
    assert.equals("Test server", retrieved.description)
  end)
end)