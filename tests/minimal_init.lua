-- Minimal init.lua for tests
-- This configuration is used by test scripts to set up a minimal Neovim environment

-- Get the absolute path to the plugin root
local plugin_root = vim.fn.fnamemodify(vim.fn.expand('%:p'), ':h:h')

-- Setup runtime path properly
vim.cmd('set runtimepath=$VIMRUNTIME')
vim.opt.runtimepath:append(plugin_root)
vim.opt.runtimepath:append(plugin_root .. '/tests')

-- Set packpath for plugins
vim.cmd('set packpath=/tmp/nvim/site')

-- Add Plenary to runtime path (for tests)
local plenary_root = vim.fn.expand('~/.local/share/nvim/site/pack/vendor/start/plenary.nvim')
vim.opt.runtimepath:append(plenary_root)
vim.opt.packpath:prepend(vim.fn.fnamemodify(plenary_root, ":h:h:h"))

-- Print some debug information
print("Runtime path: " .. vim.o.runtimepath)
print("Pack path: " .. vim.o.packpath)
print("Checking for plenary.nvim...")

-- Try to load plenary
local has_plenary, plenary = pcall(require, 'plenary')
print("Plenary available: " .. tostring(has_plenary))

-- Try to load plenary.busted explicitly
local has_busted, busted = pcall(require, 'plenary.busted')
print("Plenary.busted available: " .. tostring(has_busted))

if not has_plenary or not has_busted then
  print("ERROR: Plenary or busted not available!")
  vim.cmd("qa!")
end

-- Optional: Set up some basic vim options
vim.o.termguicolors = true
vim.o.swapfile = false
vim.o.hidden = true

-- Load the plugin
local status_ok, claude_code = pcall(require, 'claude-code')
if status_ok then
  -- Set up the plugin with minimal config for testing
  claude_code.setup({
    window = {
      height_ratio = 0.3,
    },
    -- Disable keymaps for testing
    keymaps = {
      toggle = {
        normal = false,
        terminal = false,
      },
      window_navigation = false,
      scrolling = false,
    },
  })
end

return {
  plugin_root = plugin_root,
}