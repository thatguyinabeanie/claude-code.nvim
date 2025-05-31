---@mod claude-code.commands Command registration for claude-code.nvim
---@brief [[
--- This module provides command registration and handling for claude-code.nvim.
--- It defines user commands and command handlers.
---@brief ]]

local M = {}

--- @type table<string, function> List of available commands and their handlers
M.commands = {}

local mcp_server = require('claude-code.mcp_server')

--- Register commands for the claude-code plugin
--- @param claude_code table The main plugin module
function M.register_commands(claude_code)
  -- Create the user command for toggling Claude Code
  vim.api.nvim_create_user_command('ClaudeCode', function()
    claude_code.toggle()
  end, { desc = 'Toggle Claude Code terminal' })

  -- Create commands for each command variant
  for variant_name, variant_args in pairs(claude_code.config.command_variants) do
    if variant_args ~= false then
      -- Convert variant name to PascalCase for command name (e.g., "continue" -> "Continue")
      local capitalized_name = variant_name:gsub('^%l', string.upper)
      local cmd_name = 'ClaudeCode' .. capitalized_name

      vim.api.nvim_create_user_command(cmd_name, function()
        claude_code.toggle_with_variant(variant_name)
      end, { desc = 'Toggle Claude Code terminal with ' .. variant_name .. ' option' })
    end
  end

  -- Add version command
  vim.api.nvim_create_user_command('ClaudeCodeVersion', function()
    vim.notify('Claude Code version: ' .. claude_code.version(), vim.log.levels.INFO)
  end, { desc = 'Display Claude Code version' })
  
  -- Add context-aware commands
  vim.api.nvim_create_user_command('ClaudeCodeWithFile', function()
    claude_code.toggle_with_context('file')
  end, { desc = 'Toggle Claude Code with current file context' })
  
  vim.api.nvim_create_user_command('ClaudeCodeWithSelection', function()
    claude_code.toggle_with_context('selection')
  end, { desc = 'Toggle Claude Code with visual selection', range = true })
  
  vim.api.nvim_create_user_command('ClaudeCodeWithContext', function()
    claude_code.toggle_with_context('auto')
  end, { desc = 'Toggle Claude Code with automatic context detection', range = true })
  
  vim.api.nvim_create_user_command('ClaudeCodeWithWorkspace', function()
    claude_code.toggle_with_context('workspace')
  end, { desc = 'Toggle Claude Code with enhanced workspace context including related files' })
  
  vim.api.nvim_create_user_command('ClaudeCodeWithProjectTree', function()
    claude_code.toggle_with_context('project_tree')
  end, { desc = 'Toggle Claude Code with project file tree structure' })
  
  -- Add safe window toggle commands
  vim.api.nvim_create_user_command('ClaudeCodeHide', function()
    claude_code.safe_toggle()
  end, { desc = 'Hide Claude Code window without stopping the process' })
  
  vim.api.nvim_create_user_command('ClaudeCodeShow', function()
    claude_code.safe_toggle()
  end, { desc = 'Show Claude Code window if hidden' })
  
  vim.api.nvim_create_user_command('ClaudeCodeSafeToggle', function()
    claude_code.safe_toggle()
  end, { desc = 'Safely toggle Claude Code window without interrupting execution' })
  
  -- Add status and management commands
  vim.api.nvim_create_user_command('ClaudeCodeStatus', function()
    local status = claude_code.get_process_status()
    vim.notify(status.message, vim.log.levels.INFO)
  end, { desc = 'Show current Claude Code process status' })
  
  vim.api.nvim_create_user_command('ClaudeCodeInstances', function()
    local instances = claude_code.list_instances()
    if #instances == 0 then
      vim.notify("No Claude Code instances running", vim.log.levels.INFO)
    else
      local msg = "Claude Code instances:\n"
      for _, instance in ipairs(instances) do
        msg = msg .. string.format("  %s: %s (%s)\n", 
          instance.instance_id, 
          instance.status,
          instance.visible and "visible" or "hidden")
      end
      vim.notify(msg, vim.log.levels.INFO)
    end
  end, { desc = 'List all Claude Code instances and their states' })

  -- MCP server Ex commands
  vim.api.nvim_create_user_command('ClaudeMCPStart', function()
    local ok, msg = mcp_server.start()
    if ok then
      vim.notify(msg or 'MCP server started', vim.log.levels.INFO)
    else
      vim.notify(msg or 'Failed to start MCP server', vim.log.levels.ERROR)
    end
  end, { desc = 'Start Claude MCP server' })

  vim.api.nvim_create_user_command('ClaudeMCPAttach', function()
    local ok, msg = mcp_server.attach()
    if ok then
      vim.notify(msg or 'Attached to MCP server', vim.log.levels.INFO)
    else
      vim.notify(msg or 'Failed to attach to MCP server', vim.log.levels.ERROR)
    end
  end, { desc = 'Attach to running Claude MCP server' })

  vim.api.nvim_create_user_command('ClaudeMCPStatus', function()
    local status = mcp_server.status()
    vim.notify(status, vim.log.levels.INFO)
  end, { desc = 'Show Claude MCP server status' })
end

return M
