-- MCP (Model Context Protocol) integration for claude-code.nvim
-- This module handles MCP configuration detection and generation

local utils = require('claude-code.utils')

local M = {}

-- Track if we've already shown startup notifications
local startup_notified = false

-- Standard MCP config locations used by various editors
local MCP_CONFIG_PATHS = {
  { path = '.vscode/mcp.json', format = 'vscode' },
  { path = '.cursor/mcp.json', format = 'standard' },
  { path = '.mcp.json', format = 'standard' },
  { path = '.claude.json', format = 'claude' } -- Claude Code CLI config
}

-- Global config paths
local GLOBAL_CONFIG_PATHS = {
  { path = vim.fn.expand('~/.claude.json'), format = 'claude' }, -- Claude Code CLI global config
  { path = vim.fn.expand('~/.mcp.json'), format = 'standard' },
  { path = vim.fn.expand('~/.cursor/mcp.json'), format = 'standard' },
  { path = vim.fn.expand('~/Library/Application Support/Claude/claude_desktop_config.json'), format = 'standard' }
}

-- Use shared notification utility
local function notify(msg, level)
  utils.notify(msg, level, { prefix = 'MCP' })
end

-- Check if a specific MCP server is configured
function M.is_server_configured(server_name)
  local config, _ = M.load_all_configs()
  if config and config.mcpServers then
    return config.mcpServers[server_name] ~= nil
  end
  return false
end

-- Check if mcp-neovim-server is installed
local function is_mcp_neovim_server_installed()
  return vim.fn.executable('mcp-neovim-server') == 1
end

-- Initialize MCP configuration
function M.setup(config)
  -- Prevent duplicate notifications
  if startup_notified then
    return
  end
  startup_notified = true
  
  -- Check if mcp-neovim-server is configured anywhere
  local has_neovim_server = M.is_server_configured('neovim') or M.is_server_configured('mcp-neovim-server')
  local is_installed = is_mcp_neovim_server_installed()
  
  -- Determine if we should show notifications
  local mcp_config = config and config.mcp_startup_check or {}
  local should_notify = mcp_config.enabled
  if should_notify == nil then
    should_notify = true -- Default to true
  end
  
  if not has_neovim_server then
    if not is_installed and mcp_config.notify_not_installed ~= false then
      -- Not configured and not installed
      notify(
        'mcp-neovim-server not found. Install with: npm install -g github:thatguyinabeanie/mcp-neovim-server\nThen run :ClaudeCodeMCPConfig to set it up.',
        vim.log.levels.WARN
      )
    elseif is_installed then
      -- Installed but not configured
      vim.defer_fn(function()
        if mcp_config.auto_configure then
          -- Automatically configure without prompting
          local existing = M.find_best_config_file()
          local success, path = M.generate_config()
          
          if success and mcp_config.notify_missing ~= false then
            if path then
              -- New config was created
              notify('Automatically created MCP configuration at: ' .. path, vim.log.levels.INFO)
            elseif existing then
              -- Added to existing config
              notify('Automatically added mcp-neovim-server to: ' .. existing.path, vim.log.levels.INFO)
            end
          end
        elseif mcp_config.auto_prompt then
          -- Prompt the user
          local msg = 'mcp-neovim-server is installed but not configured.\nRun :ClaudeCodeMCPConfig to create configuration.'
          if mcp_config.notify_missing ~= false then
            notify(msg, vim.log.levels.INFO)
          end
          
          local existing = M.find_best_config_file()
          local prompt_msg = existing and 
            string.format('Add mcp-neovim-server to %s?', vim.fn.fnamemodify(existing.path, ':~:.')) or
            'Create MCP configuration for mcp-neovim-server?'
          
          vim.ui.select({'Yes', 'No'}, {
            prompt = prompt_msg,
          }, function(choice)
            if choice == 'Yes' then
              M.generate_config()
            end
          end)
        else
          -- Just notify
          if mcp_config.notify_missing ~= false then
            local msg = 'mcp-neovim-server is installed but not configured.\nRun :ClaudeCodeMCPConfig to create configuration.'
            notify(msg, vim.log.levels.INFO)
          end
        end
      end, 100) -- Small delay to ensure UI is ready
    end
  elseif has_neovim_server and not is_installed and mcp_config.notify_not_installed ~= false then
    -- Configured but not installed
    notify(
      'mcp-neovim-server is configured but not installed.\nInstall with: npm install -g github:thatgoyinabeanie/mcp-neovim-server',
      vim.log.levels.WARN
    )
  elseif config and config.startup_notification and config.startup_notification.enabled then
    -- Everything is good
    notify('MCP integration ready (mcp-neovim-server configured)', vim.log.levels.INFO)
  end
end

-- Convert VS Code format to standard format
local function convert_vscode_format(config)
  if config.servers then
    local converted = { mcpServers = {} }
    for name, server in pairs(config.servers) do
      converted.mcpServers[name] = {
        command = server.command,
        args = server.args or {},
        env = server.env or {}
      }
      -- Note: VS Code specific fields like type, cwd, url are not included
    end
    return converted
  end
  return config
end

-- Load and parse a config file
local function load_config_file(path, format)
  local file = io.open(path, 'r')
  if not file then
    return nil
  end
  
  local content = file:read('*all')
  file:close()
  
  local ok, config = pcall(vim.json.decode, content)
  if not ok then
    notify('Failed to parse config file: ' .. path, vim.log.levels.ERROR)
    return nil
  end
  
  -- Convert VS Code format if needed
  if format == 'vscode' then
    config = convert_vscode_format(config)
  elseif format == 'claude' then
    -- Claude CLI config might have mcpServers at root or nested in projects
    -- Extract just the mcpServers part
    if not config.mcpServers and config.projects then
      -- Look for mcpServers in individual projects
      local merged_servers = {}
      for _, project in pairs(config.projects) do
        if project.mcpServers then
          for name, server in pairs(project.mcpServers) do
            merged_servers[name] = server
          end
        end
      end
      if next(merged_servers) then
        config = { mcpServers = merged_servers }
      end
    end
    -- Ensure we only return the mcpServers part
    if config.mcpServers then
      config = { mcpServers = config.mcpServers }
    end
  end
  
  return config
end

-- Merge multiple MCP configurations
local function merge_configs(configs)
  local merged = { mcpServers = {} }
  
  for _, config in ipairs(configs) do
    if config.mcpServers then
      for name, server in pairs(config.mcpServers) do
        -- Later configs override earlier ones for the same server name
        merged.mcpServers[name] = vim.tbl_deep_extend('force', merged.mcpServers[name] or {}, server)
      end
    end
  end
  
  return merged
end

-- Load all available MCP configurations
function M.load_all_configs()
  local configs = {}
  local loaded_paths = {}
  
  -- Load global configs first (lower priority)
  for _, config_info in ipairs(GLOBAL_CONFIG_PATHS) do
    if vim.fn.filereadable(config_info.path) == 1 then
      local config = load_config_file(config_info.path, config_info.format)
      if config then
        table.insert(configs, config)
        table.insert(loaded_paths, config_info.path)
      end
    end
  end
  
  -- Load project configs (higher priority)
  local cwd = vim.fn.getcwd()
  for _, config_info in ipairs(MCP_CONFIG_PATHS) do
    local full_path = cwd .. '/' .. config_info.path
    if vim.fn.filereadable(full_path) == 1 then
      local config = load_config_file(full_path, config_info.format)
      if config then
        table.insert(configs, config)
        table.insert(loaded_paths, full_path)
      end
    end
  end
  
  if #configs == 0 then
    return nil, {}
  end
  
  -- Merge all configs
  local merged = merge_configs(configs)
  return merged, loaded_paths
end

-- Detect existing MCP configuration files (for backward compatibility)
function M.detect_config()
  local _, loaded_paths = M.load_all_configs()
  if #loaded_paths > 0 then
    notify('Found MCP configs: ' .. table.concat(loaded_paths, ', '), vim.log.levels.INFO)
    return loaded_paths[#loaded_paths] -- Return the highest priority config path
  end
  return nil
end

-- Find the best existing config file to update
function M.find_best_config_file()
  local cwd = vim.fn.getcwd()
  
  -- Priority order for existing files
  local priority_paths = {
    { path = cwd .. '/.claude.json', format = 'claude' },
    { path = cwd .. '/.mcp.json', format = 'standard' },
    { path = cwd .. '/.cursor/mcp.json', format = 'standard' },
    { path = cwd .. '/.vscode/mcp.json', format = 'vscode' },
  }
  
  -- Return the first existing file
  for _, config_info in ipairs(priority_paths) do
    if vim.fn.filereadable(config_info.path) == 1 then
      return config_info
    end
  end
  
  return nil
end

-- Add mcp-neovim-server to existing config file
local function add_to_existing_config(config_info)
  -- Read raw file to preserve structure and formatting
  local file = io.open(config_info.path, 'r')
  if not file then
    return false, 'Failed to read file'
  end
  local content = file:read('*all')
  file:close()
  
  local ok, config = pcall(vim.json.decode, content)
  if not ok then
    return false, 'Failed to parse JSON'
  end
  
  -- Check if already configured
  local already_configured = false
  
  if config_info.format == 'claude' then
    -- .claude.json can have mcpServers at root or in projects
    if config.mcpServers and (config.mcpServers.neovim or config.mcpServers['mcp-neovim-server']) then
      already_configured = true
    end
    if config.projects then
      for _, project in pairs(config.projects) do
        if project.mcpServers and (project.mcpServers.neovim or project.mcpServers['mcp-neovim-server']) then
          already_configured = true
          break
        end
      end
    end
  elseif config_info.format == 'vscode' then
    -- VS Code format uses 'servers' root key
    if config.servers and (config.servers.neovim or config.servers['mcp-neovim-server']) then
      already_configured = true
    end
  else
    -- Standard format uses 'mcpServers' root key
    if config.mcpServers and (config.mcpServers.neovim or config.mcpServers['mcp-neovim-server']) then
      already_configured = true
    end
  end
  
  if already_configured then
    -- Already configured, don't show notification (avoid duplicate messages)
    return true, nil
  end
  
  -- Add configuration based on format
  if config_info.format == 'claude' then
    -- For .claude.json, add to root mcpServers
    if not config.mcpServers then
      config.mcpServers = {}
    end
    config.mcpServers.neovim = {
      command = 'mcp-neovim-server',
      args = {},
      env = {}
    }
  elseif config_info.format == 'vscode' then
    -- For VS Code format, use servers with type field
    if not config.servers then
      config.servers = {}
    end
    config.servers.neovim = {
      type = 'stdio',
      command = 'mcp-neovim-server',
      args = {},
      env = {}
    }
  else
    -- Standard format (.mcp.json, .cursor/mcp.json)
    if not config.mcpServers then
      config.mcpServers = {}
    end
    config.mcpServers.neovim = {
      command = 'mcp-neovim-server',
      args = {},
      env = {}
    }
  end
  
  -- Ensure Neovim socket exists
  if not vim.v.servername or vim.v.servername == '' then
    local socket_path = vim.fn.tempname() .. '.nvim.sock'
    vim.fn.serverstart(socket_path)
  end
  
  -- Add NVIM socket to env
  local server_config = nil
  if config_info.format == 'vscode' then
    server_config = config.servers.neovim
  else
    server_config = config.mcpServers.neovim
  end
  
  server_config.env.NVIM = vim.v.servername
  
  -- Write back with proper formatting
  local json_str = vim.json.encode(config)
  -- Try to format JSON nicely if possible
  local formatted_json = vim.fn.system('python3 -m json.tool', json_str)
  if vim.v.shell_error == 0 then
    json_str = formatted_json
  end
  
  file = io.open(config_info.path, 'w')
  if not file then
    return false, 'Failed to write file'
  end
  file:write(json_str)
  file:close()
  
  return true, config_info.path
end

-- Generate MCP configuration following industry standards
function M.generate_config(output_path)
  -- Check if mcp-neovim-server is already configured
  if M.is_server_configured('neovim') or M.is_server_configured('mcp-neovim-server') then
    notify('mcp-neovim-server is already configured', vim.log.levels.INFO)
    return true, nil
  end
  
  -- If no output path specified, try to add to existing config
  if not output_path then
    local existing_config = M.find_best_config_file()
    if existing_config then
      -- Don't show redundant notification here, add_to_existing_config will handle it
      return add_to_existing_config(existing_config)
    end
    
    -- No existing config, create .claude.json as default
    -- Since this is THE claude-code.nvim plugin, we default to Claude's config format
    output_path = vim.fn.getcwd() .. '/.claude.json'
  end

  -- Use mcp-neovim-server (should be installed globally via npm)
  local mcp_server_command = 'mcp-neovim-server'

  -- Check if the server is installed
  if vim.fn.executable(mcp_server_command) == 0 and not os.getenv('CLAUDE_CODE_TEST_MODE') then
    notify(
      'mcp-neovim-server not found. Install with: npm install -g github:thatguyinabeanie/mcp-neovim-server',
      vim.log.levels.ERROR
    )
    return false
  end

  -- Create appropriate config based on file type
  local config
  if output_path:match('%.claude%.json$') then
    -- For .claude.json, create a minimal but valid Claude CLI config
    config = {
      mcpServers = {
        neovim = {
          command = mcp_server_command,
          args = {},
          env = {}
        }
      }
    }
  else
    -- For other formats (.mcp.json, etc), use standard MCP format
    config = {
      mcpServers = {
        neovim = {
          command = mcp_server_command,
          args = {},
          env = {}
        }
      }
    }
  end
  
  -- Ensure Neovim socket exists
  if not vim.v.servername or vim.v.servername == '' then
    local socket_path = vim.fn.tempname() .. '.nvim.sock'
    vim.fn.serverstart(socket_path)
  end
  
  -- Add NVIM socket to env
  config.mcpServers.neovim.env.NVIM = vim.v.servername

  -- Ensure output directory exists
  local output_dir = vim.fn.fnamemodify(output_path, ':h')
  if vim.fn.isdirectory(output_dir) == 0 then
    vim.fn.mkdir(output_dir, 'p')
  end

  local json_str = vim.json.encode(config)

  -- Write to file
  local file = io.open(output_path, 'w')
  if not file then
    notify('Failed to create MCP config at: ' .. output_path, vim.log.levels.ERROR)
    return false
  end

  file:write(json_str)
  file:close()

  -- Don't show redundant notification here, caller will handle it
  return true, output_path
end

-- Get merged MCP configuration
function M.get_merged_config()
  local config, loaded_paths = M.load_all_configs()
  if config then
    notify('Loaded MCP configs from: ' .. table.concat(loaded_paths, ', '), vim.log.levels.INFO)
    return config, loaded_paths
  end
  return nil, {}
end

-- Get active MCP config path (detect existing or generate new)
function M.get_config_path()
  local _, loaded_paths = M.load_all_configs()
  if #loaded_paths > 0 then
    return loaded_paths[#loaded_paths] -- Return highest priority path
  end
  
  -- No existing config, generate one
  local success, path = M.generate_config()
  if success then
    return path
  end
  
  return nil
end

-- Setup MCP integration
function M.setup_claude_integration()

  -- Check if mcp-neovim-server is installed
  if vim.fn.executable('mcp-neovim-server') == 0 then
    notify('Installing mcp-neovim-server...', vim.log.levels.INFO)
    local install_cmd = 'npm install -g github:thatguyinabeanie/mcp-neovim-server'
    local result = vim.fn.system(install_cmd)
    if vim.v.shell_error ~= 0 then
      notify('Failed to install mcp-neovim-server: ' .. result, vim.log.levels.ERROR)
      return false
    end
  end

  -- Get or create config
  local success, config_path = M.generate_config()
  if not success then
    notify('Failed to setup MCP configuration', vim.log.levels.ERROR)
    return false
  end
  
  -- If no new config was created (already configured), get the path
  if not config_path then
    config_path = M.get_config_path()
  end

  -- Create socket if needed
  if not vim.v.servername or vim.v.servername == '' then
    local socket_path = vim.fn.tempname() .. '.sock'
    vim.fn.serverstart(socket_path)
    notify('Started Neovim server at: ' .. socket_path, vim.log.levels.INFO)
  end

  -- Display current configuration status
  local merged_config, loaded_paths = M.load_all_configs()
  local config_sources = ''
  if #loaded_paths > 0 then
    config_sources = '\n\nLoaded configurations from:\n'
    for _, path in ipairs(loaded_paths) do
      config_sources = config_sources .. '  • ' .. path .. '\n'
    end
  end
  
  -- Display instructions
  local instructions = string.format([[
MCP Setup Complete!

1. Neovim socket: %s
2. MCP config: %s

Use with any MCP-compatible tool:
  • Claude: claude --mcp-config %s "Your prompt here"
  • VS Code: Detected automatically from .vscode/mcp.json
  • Cursor: Detected automatically from .cursor/mcp.json
  • Other tools: May use .mcp.json or mcp.json

Or set as environment variable:
  export MCP_CONFIG_PATH=%s
]]%s, vim.v.servername, config_path or 'Already configured', config_path or 'see existing config', config_path or 'see existing config', config_sources)

  notify(instructions, vim.log.levels.INFO)
  return true
end

return M