-- Test runner for Plenary-based tests
local ok, plenary = pcall(require, 'plenary')
if not ok then
  print('ERROR: Could not load plenary')
  vim.cmd('qa!')
  return
end

-- Track test completion
local tests_started = false
local last_output_time = vim.loop.now()
local test_results = { success = 0, failed = 0, errors = 0 }

-- Hook into print to detect test output
local original_print = print
_G.print = function(...)
  original_print(...)
  last_output_time = vim.loop.now()
  
  local output = table.concat({...}, " ")
  -- Check for test completion patterns
  if output:match("Success:%s*(%d+)") then
    tests_started = true
    test_results.success = tonumber(output:match("Success:%s*(%d+)")) or 0
  end
  if output:match("Failed%s*:%s*(%d+)") then
    tests_started = true
    test_results.failed = tonumber(output:match("Failed%s*:%s*(%d+)")) or 0
  end
  if output:match("Errors%s*:%s*(%d+)") then
    tests_started = true
    test_results.errors = tonumber(output:match("Errors%s*:%s*(%d+)")) or 0
  end
end

-- Function to check if all tests have completed
local function check_completion()
  local now = vim.loop.now()
  local idle_time = now - last_output_time
  
  -- If we've seen test output and no new output for 2 seconds, assume tests are done
  if tests_started and idle_time > 2000 then
    -- Restore original print
    _G.print = original_print
    
    if test_results.failed > 0 or test_results.errors > 0 then
      print(string.format('Tests completed with failures - Success: %d, Failed: %d, Errors: %d',
        test_results.success, test_results.failed, test_results.errors))
      vim.cmd('cquit 1')
    else
      print(string.format('All tests passed - Success: %d', test_results.success))
      vim.cmd('qa!')
    end
    return true
  end
  
  -- Keep checking
  return false
end

-- Run tests
print('Starting test run...')
require('plenary.test_harness').test_directory('tests/spec/', {
  minimal_init = 'tests/minimal-init.lua',
  sequential = false,
})

-- Monitor for completion
local timer = vim.loop.new_timer()
timer:start(500, 500, vim.schedule_wrap(function()
  if check_completion() then
    timer:stop()
    timer:close()
  end
end))

-- Failsafe: Exit after 30 seconds regardless
vim.defer_fn(function()
  print('Warning: Test runner timeout - force exiting')
  if test_results.failed > 0 or test_results.errors > 0 then
    vim.cmd('cquit 1')
  else
    vim.cmd('qa!')
  end
end, 30000)