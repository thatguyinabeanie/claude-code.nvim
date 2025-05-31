-- Test runner for Plenary-based tests
local ok, plenary = pcall(require, 'plenary')
if not ok then
  print('ERROR: Could not load plenary')
  vim.cmd('qa!')
  return
end

-- Run the tests using plenary's built-in test runner
require('plenary.test_harness').test_directory('tests/spec/', {
  minimal_init = 'tests/minimal-init.lua',
  sequential = false
})