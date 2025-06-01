-- Test runner for Plenary-based tests
local ok, plenary = pcall(require, 'plenary')
if not ok then
  print('ERROR: Could not load plenary')
  vim.cmd('qa!')
  return
end

-- Function to ensure proper exit after tests
local function run_tests_and_exit()
  -- Set up timeout to prevent hanging
  local timeout_timer = vim.loop.new_timer()
  local timeout_ms = 60000 -- 60 second timeout
  
  timeout_timer:start(timeout_ms, 0, function()
    print('ERROR: Test execution timed out after ' .. (timeout_ms / 1000) .. ' seconds')
    vim.schedule(function()
      vim.cmd('cquit 1')
    end)
  end)
  
  local success, result = pcall(function()
    local test_result = require('plenary.test_harness').test_directory('tests/spec/', {
      minimal_init = 'tests/minimal-init.lua',
      sequential = false
    })
    
    -- Cancel timeout timer if tests complete successfully
    timeout_timer:stop()
    timeout_timer:close()
    
    -- Debug: Print test result structure
    print('Test result structure:')
    if test_result then
      for k, v in pairs(test_result) do
        print('  ' .. tostring(k) .. ': ' .. tostring(v))
      end
    else
      print('  test_result is nil')
    end
    
    -- Exit with appropriate code based on test results
    local exit_code = 0
    if test_result and test_result.errors and test_result.errors > 0 then
      print('Exiting with code 1 due to errors: ' .. test_result.errors)
      exit_code = 1
    elseif test_result and test_result.fail and test_result.fail > 0 then
      print('Exiting with code 1 due to failures: ' .. test_result.fail)
      exit_code = 1
    else
      print('No errors or failures detected, exiting with code 0')
    end
    
    -- Force exit after a short delay to ensure output is flushed
    vim.defer_fn(function()
      if exit_code == 0 then
        print('All tests passed - exiting successfully')
        vim.cmd('qa!')
      else
        print('Some tests failed - exiting with error code')
        vim.cmd('cquit ' .. exit_code)
      end
    end, 50)
    
    return test_result
  end)
  
  if not success then
    timeout_timer:stop()
    timeout_timer:close()
    print('ERROR: Test execution failed: ' .. tostring(result))
    vim.defer_fn(function()
      vim.cmd('cquit 1')
    end, 50)
    return
  end
end

-- Run tests in a protected environment
run_tests_and_exit()