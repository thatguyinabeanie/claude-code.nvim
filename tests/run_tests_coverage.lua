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

-- Track test completion
local test_completed = false
local exit_code = 0

-- Function to force exit after tests
local function force_exit()
  if not test_completed then
    test_completed = true
    print('Tests completed - forcing exit with code ' .. exit_code)
    if exit_code == 0 then
      vim.cmd('qa!')
    else
      vim.cmd('cquit ' .. exit_code)
    end
  end
end

-- Run tests
print('Starting test run...')
require('plenary.test_harness').test_directory('tests/spec/', {
  minimal_init = 'tests/minimal-init.lua',
  sequential = false
})

-- The test harness should have printed results by now
-- Parse the output to determine exit code
vim.schedule(function()
  vim.defer_fn(function()
    -- Look for test results in messages
    local messages = vim.api.nvim_exec('messages', true)
    if messages:match('Failed%s*:%s*[1-9]') or messages:match('Errors%s*:%s*[1-9]') then
      exit_code = 1
    end
    
    -- Force exit
    force_exit()
  end, 1000) -- Give 1 second for results to be printed
end)