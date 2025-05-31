local test = require("tests.run_tests")

test.describe("File Reference Shortcut", function()
  test.it("inserts @File#L10 for cursor line", function()
    -- Setup: open buffer, move cursor to line 10
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "line 1", "line 2", "line 3", "line 4", "line 5", "line 6", "line 7", "line 8", "line 9", "line 10"
    })
    vim.api.nvim_win_set_cursor(0, {10, 0})
    -- Simulate shortcut
    vim.cmd("normal! <leader>cf")
    -- Assert: Claude prompt buffer contains @<filename>#L10
    local prompt = require('claude-code').get_prompt_input()
    local fname = vim.fn.expand('%:t')
    assert(prompt:find("@" .. fname .. "#L10"), "Prompt should contain @file#L10")
  end)

  test.it("inserts @File#L5-7 for visual selection", function()
    -- Setup: open buffer, select lines 5-7
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "line 1", "line 2", "line 3", "line 4", "line 5", "line 6", "line 7", "line 8", "line 9", "line 10"
    })
    vim.api.nvim_win_set_cursor(0, {5, 0})
    vim.cmd("normal! Vjj") -- Visual select lines 5-7
    vim.cmd("normal! <leader>cf")
    -- Assert: Claude prompt buffer contains @<filename>#L5-7
    local prompt = require('claude-code').get_prompt_input()
    local fname = vim.fn.expand('%:t')
    assert(prompt:find("@" .. fname .. "#L5-7"), "Prompt should contain @file#L5-7")
  end)
end) 