-- Single test runner that properly exits
local test_file = os.getenv('TEST_FILE')

if not test_file then
  print("Error: No test file specified via TEST_FILE environment variable")
  vim.cmd('cquit 1')
  return
end

print("Running test file: " .. test_file)

-- Run the test and capture results
local ok, result = pcall(require('plenary.test_harness').test_file, test_file, {
  minimal_init = 'tests/minimal-init.lua'
})

if not ok then
  print("Error running test: " .. tostring(result))
  vim.cmd('cquit 1')
else
  print("Test completed successfully")
  vim.cmd('qa!')
end