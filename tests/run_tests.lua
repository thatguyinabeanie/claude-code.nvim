-- Test runner for Plenary-based tests
local ok, plenary = pcall(require, 'plenary')
if not ok then
  print('ERROR: Could not load plenary')
  vim.cmd('qa!')
  return
end

-- Run tests
print('Starting test run...')
require('plenary.test_harness').test_directory('tests/spec/', {
  minimal_init = 'tests/minimal-init.lua',
  sequential = false
})

-- Force exit after a very short delay to allow output to be flushed
vim.defer_fn(function()
  -- Check if any tests failed by looking at the output
  local messages = vim.api.nvim_exec('messages', true)
  local exit_code = 0
  
  if messages:match('Failed%s*:%s*[1-9]') or messages:match('Errors%s*:%s*[1-9]') then
    exit_code = 1
    print('Tests failed - exiting with code 1')
    vim.cmd('cquit 1')
  else
    print('All tests passed - exiting with code 0')
    vim.cmd('qa!')
  end
end, 100) -- 100ms delay should be enough for output to flush