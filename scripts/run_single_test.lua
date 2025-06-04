-- Single test runner that properly exits with verbose logging
local test_file = os.getenv('TEST_FILE')

if not test_file then
  print("Error: No test file specified via TEST_FILE environment variable")
  vim.cmd('cquit 1')
  return
end

print("=== VERBOSE TEST RUNNER ===")
print("Test file: " .. test_file)
print("Environment:")
print("  CI: " .. tostring(os.getenv('CI')))
print("  GITHUB_ACTIONS: " .. tostring(os.getenv('GITHUB_ACTIONS')))
print("  CLAUDE_CODE_TEST_MODE: " .. tostring(os.getenv('CLAUDE_CODE_TEST_MODE')))
print("  PLUGIN_ROOT: " .. tostring(os.getenv('PLUGIN_ROOT')))
print("Working directory: " .. vim.fn.getcwd())
print("Neovim version: " .. tostring(vim.version()))

-- Set up verbose logging for plenary
local original_print = print
local test_output = {}
_G.print = function(...)
  local args = {...}
  local output = table.concat(args, " ")
  table.insert(test_output, output)
  original_print(...)
end

print("Starting test execution...")
local start_time = vim.loop.now()

-- Run the test and capture results
local ok, result = pcall(require('plenary.test_harness').test_file, test_file, {
  minimal_init = 'tests/minimal-init.lua'
})

local end_time = vim.loop.now()
local duration = end_time - start_time

-- Restore original print
_G.print = original_print

print("=== TEST EXECUTION COMPLETE ===")
print("Duration: " .. duration .. "ms")
print("Success: " .. tostring(ok))

if not ok then
  print("Error details: " .. tostring(result))
  print("=== TEST OUTPUT CAPTURE ===")
  for i, line in ipairs(test_output) do
    print(string.format("%d: %s", i, line))
  end
  print("=== END OUTPUT CAPTURE ===")
  vim.cmd('cquit 1')
else
  print("Test completed successfully")
  print("=== FINAL TEST OUTPUT ===")
  -- Show last 20 lines of output
  local start_idx = math.max(1, #test_output - 19)
  for i = start_idx, #test_output do
    print(string.format("%d: %s", i, test_output[i]))
  end
  print("=== END FINAL OUTPUT ===")
  vim.cmd('qa!')
end