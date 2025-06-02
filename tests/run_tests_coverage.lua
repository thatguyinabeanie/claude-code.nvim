-- Test runner for Plenary-based tests with coverage support
local ok, plenary = pcall(require, 'plenary')
if not ok then
  print('ERROR: Could not load plenary')
  vim.cmd('qa!')
  return
end

-- Load luacov for coverage - must be done before loading any modules to test
local has_luacov, luacov = pcall(require, 'luacov')
if has_luacov then
  print('LuaCov loaded - coverage will be collected')
  -- Start luacov if not already started
  if type(luacov.init) == 'function' then
    luacov.init()
  end
else
  print('Warning: LuaCov not found - coverage will not be collected')
  -- Try alternative loading methods
  local alt_paths = {
    '/usr/local/share/lua/5.1/luacov.lua',
    '/usr/share/lua/5.1/luacov.lua'
  }
  for _, path in ipairs(alt_paths) do
    local f = io.open(path, 'r')
    if f then
      f:close()
      package.path = package.path .. ';' .. path:gsub('/[^/]*$', '/?.lua')
      local success = pcall(require, 'luacov')
      if success then
        print('LuaCov loaded from alternative path: ' .. path)
        break
      end
    end
  end
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