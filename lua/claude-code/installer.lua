-- Installer module for claude-code.nvim dependencies
local M = {}

local utils = require('claude-code.utils')

-- Check if mcp-neovim-server is installed
function M.check_mcp_server()
  return vim.fn.executable('mcp-neovim-server') == 1
end

-- Install mcp-neovim-server
function M.install_mcp_server()
  if M.check_mcp_server() then
    utils.notify('mcp-neovim-server is already installed', vim.log.levels.INFO)
    return true
  end

  utils.notify('Installing mcp-neovim-server...', vim.log.levels.INFO)

  -- Check if npm is available
  if vim.fn.executable('npm') == 0 then
    utils.notify('npm is not installed. Please install Node.js/npm first', vim.log.levels.ERROR)
    return false
  end

  -- Check if there's a broken symlink or existing installation
  local npm_prefix = vim.fn.system('npm config get prefix'):gsub('\n', '')
  local mcp_path = npm_prefix .. '/lib/node_modules/mcp-neovim-server'
  local stat = vim.loop.fs_lstat(mcp_path)

  if stat then
    -- Remove broken symlink or corrupted installation
    vim.fn.system('rm -rf ' .. vim.fn.shellescape(mcp_path))
  end

  -- Install the package
  -- TODO: Update to 'npm install -g mcp-neovim-server' once PR is merged
  local cmd = 'npm install -g github:thatguyinabeanie/mcp-neovim-server'
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    utils.notify('Failed to install mcp-neovim-server: ' .. output, vim.log.levels.ERROR)
    return false
  end

  utils.notify('Successfully installed mcp-neovim-server', vim.log.levels.INFO)
  return true
end

-- Auto-install on setup if configured
function M.auto_install(config)
  if config.auto_install_mcp_server == false then
    return
  end

  if not M.check_mcp_server() then
    -- Defer installation to avoid blocking startup
    vim.defer_fn(function()
      M.install_mcp_server()
    end, 100)
  end
end

return M
