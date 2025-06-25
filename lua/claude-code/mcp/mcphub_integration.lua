-- MCPHub.nvim Integration for Claude Code
-- This module integrates claude-code.nvim with the MCPHub.nvim plugin

local M = {}

-- Check if MCPHub is available
local function has_mcphub()
  local ok, _ = pcall(require, 'mcphub')
  return ok
end

-- Register claude-code.nvim's MCP server with MCPHub
function M.register_with_mcphub()
  if not has_mcphub() then
    return false, "MCPHub.nvim is not installed"
  end
  
  local mcphub = require('mcphub')
  
  -- Server configuration for MCPHub
  local server_config = {
    name = "claude-code-neovim",
    command = "mcp-neovim-server",
    args = {},
    env = {
      NVIM = vim.v.servername,
    },
    description = "Neovim integration for Claude Code via MCP",
    homepage = "https://github.com/greggh/claude-code.nvim",
    tags = { "neovim", "editor", "claude" },
  }
  
  -- Register our server with MCPHub
  -- MCPHub will manage the server lifecycle
  local success, err = pcall(function()
    -- MCPHub expects servers to be added to its configuration
    local mcphub_config = vim.fn.expand("~/.config/mcphub/servers.json")
    local config = {}
    
    -- Load existing config if it exists
    if vim.fn.filereadable(mcphub_config) == 1 then
      local file = io.open(mcphub_config, 'r')
      if file then
        local content = file:read('*all')
        file:close()
        local ok, data = pcall(vim.json.decode, content)
        if ok and data then
          config = data
        end
      end
    end
    
    -- Ensure mcpServers section exists
    config.mcpServers = config.mcpServers or {}
    
    -- Add our server configuration
    config.mcpServers["claude-code-neovim"] = {
      command = server_config.command,
      args = server_config.args,
      env = server_config.env,
    }
    
    -- Ensure directory exists
    vim.fn.mkdir(vim.fn.fnamemodify(mcphub_config, ':h'), 'p')
    
    -- Write updated config
    local file = io.open(mcphub_config, 'w')
    if file then
      file:write(vim.json.encode(config))
      file:close()
      return true
    end
    
    return false
  end)
  
  if success then
    vim.notify("[claude-code.nvim] Registered with MCPHub", vim.log.levels.INFO)
    return true
  else
    return false, err
  end
end

-- Setup MCPHub integration
function M.setup(opts)
  opts = opts or {}
  
  -- Auto-register on setup if MCPHub is available
  if opts.auto_register ~= false and has_mcphub() then
    vim.defer_fn(function()
      M.register_with_mcphub()
    end, 100)
  end
  
  -- Create command for manual registration
  vim.api.nvim_create_user_command('ClaudeCodeMCPHubRegister', function()
    local success, err = M.register_with_mcphub()
    if not success then
      vim.notify("[claude-code.nvim] Failed to register with MCPHub: " .. (err or "Unknown error"), vim.log.levels.ERROR)
    end
  end, {
    desc = 'Register claude-code.nvim with MCPHub'
  })
  
  -- Create command to check MCPHub status
  vim.api.nvim_create_user_command('ClaudeCodeMCPHubStatus', function()
    if has_mcphub() then
      vim.notify("[claude-code.nvim] MCPHub.nvim is installed and available", vim.log.levels.INFO)
      
      -- Check if we're registered
      local mcphub_config = vim.fn.expand("~/.config/mcphub/servers.json")
      if vim.fn.filereadable(mcphub_config) == 1 then
        local file = io.open(mcphub_config, 'r')
        if file then
          local content = file:read('*all')
          file:close()
          local ok, data = pcall(vim.json.decode, content)
          if ok and data and data.mcpServers and data.mcpServers["claude-code-neovim"] then
            vim.notify("[claude-code.nvim] Registered with MCPHub", vim.log.levels.INFO)
          else
            vim.notify("[claude-code.nvim] Not registered with MCPHub", vim.log.levels.WARN)
          end
        end
      end
    else
      vim.notify("[claude-code.nvim] MCPHub.nvim is not installed", vim.log.levels.WARN)
    end
  end, {
    desc = 'Check MCPHub integration status'
  })
end

-- Get MCPHub configuration path for Claude Code
function M.get_mcphub_config_path()
  if has_mcphub() then
    -- MCPHub serves its configuration via HTTP
    return "http://localhost:3000/mcp/config"
  end
  return nil
end

-- Launch Claude with MCPHub configuration
function M.launch_with_mcphub(prompt)
  local config_path = M.get_mcphub_config_path()
  if not config_path then
    vim.notify("[claude-code.nvim] MCPHub is not available", vim.log.levels.WARN)
    return false
  end
  
  -- Ensure our server is registered
  M.register_with_mcphub()
  
  -- Launch Claude with MCPHub config
  local cmd = {
    "claude",
    "--mcp-config", config_path,
  }
  
  if prompt then
    table.insert(cmd, "-e")
    table.insert(cmd, prompt)
  end
  
  vim.fn.system(cmd)
  return true
end

return M