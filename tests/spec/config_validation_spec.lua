-- Tests for the config validation
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local before_each = require('plenary.busted').before_each

describe('config validation', function()
  local config

  before_each(function()
    -- Clear module cache to ensure fresh state
    package.loaded['claude-code.config'] = nil
    config = require('claude-code.config')
  end)
  -- Tests for each config section
  describe('window validation', function()
    it('should validate window.position must be a string', function()
      local invalid_config = vim.deepcopy(config.default_config)
      invalid_config.window.position = 123 -- Not a string

      local result = config.parse_config(invalid_config, true) -- silent mode
      assert.are.equal(config.default_config.window.position, result.window.position)
    end)

    it('should validate window.enter_insert must be a boolean', function()
      local invalid_config = vim.deepcopy(config.default_config)
      invalid_config.window.enter_insert = 'true' -- String instead of boolean

      local result = config.parse_config(invalid_config, true) -- silent mode
      assert.are.equal(config.default_config.window.enter_insert, result.window.enter_insert)
    end)

    it('should validate window.hide_numbers must be a boolean', function()
      local invalid_config = vim.deepcopy(config.default_config)
      invalid_config.window.hide_numbers = 1 -- Number instead of boolean

      local result = config.parse_config(invalid_config, true) -- silent mode
      assert.are.equal(config.default_config.window.hide_numbers, result.window.hide_numbers)
    end)
  end)

  describe('refresh validation', function()
    it('should validate refresh.enable must be a boolean', function()
      local invalid_config = vim.deepcopy(config.default_config)
      invalid_config.refresh.enable = 'yes' -- String instead of boolean

      local result = config.parse_config(invalid_config, true) -- silent mode
      assert.are.equal(config.default_config.refresh.enable, result.refresh.enable)
    end)

    it('should validate refresh.updatetime must be a positive number', function()
      local invalid_config = vim.deepcopy(config.default_config)
      invalid_config.refresh.updatetime = -100 -- Negative number

      local result = config.parse_config(invalid_config, true) -- silent mode
      assert.are.equal(config.default_config.refresh.updatetime, result.refresh.updatetime)
    end)

    it('should validate refresh.timer_interval must be a positive number', function()
      local invalid_config = vim.deepcopy(config.default_config)
      invalid_config.refresh.timer_interval = 0 -- Zero is not positive

      local result = config.parse_config(invalid_config, true) -- silent mode
      assert.are.equal(config.default_config.refresh.timer_interval, result.refresh.timer_interval)
    end)
  end)

  describe('git validation', function()
    it('should validate git.use_git_root must be a boolean', function()
      local invalid_config = vim.deepcopy(config.default_config)
      invalid_config.git.use_git_root = 'yes' -- String instead of boolean

      local result = config.parse_config(invalid_config, true) -- silent mode
      assert.are.equal(config.default_config.git.use_git_root, result.git.use_git_root)
    end)
  end)

  describe('keymaps validation', function()
    it('should validate keymaps.toggle.normal can be a string or false', function()
      -- Valid cases
      local valid_config1 = vim.deepcopy(config.default_config)
      valid_config1.keymaps.toggle.normal = '<leader>cc'

      local valid_config2 = vim.deepcopy(config.default_config)
      valid_config2.keymaps.toggle.normal = false

      -- Invalid case
      local invalid_config = vim.deepcopy(config.default_config)
      invalid_config.keymaps.toggle.normal = 123

      local result1 = config.parse_config(valid_config1, true) -- silent mode
      local result2 = config.parse_config(valid_config2, true) -- silent mode
      local result3 = config.parse_config(invalid_config, true) -- silent mode

      -- First config should have custom keymap
      assert.is_not_nil(result1.keymaps.toggle.normal)
      assert.are.equal(valid_config1.keymaps.toggle.normal, result1.keymaps.toggle.normal)

      -- Second config should have false
      assert.are.equal(false, result2.keymaps.toggle.normal)

      -- Third config (invalid) should fall back to default
      assert.are.equal(config.default_config.keymaps.toggle.normal, result3.keymaps.toggle.normal)
    end)

    it('should validate keymaps.window_navigation must be a boolean', function()
      -- Simplify this test to match others
      local invalid_config = vim.deepcopy(config.default_config)
      invalid_config.keymaps.window_navigation = 'enabled' -- String instead of boolean

      -- Use silent mode to avoid pollution
      local result = config.parse_config(invalid_config, true)

      assert.are.equal(
        config.default_config.keymaps.window_navigation,
        result.keymaps.window_navigation
      )
    end)
  end)
end)
