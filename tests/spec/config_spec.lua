-- Tests for the config module
local assert = require('luassert')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local before_each = require('plenary.busted').before_each

describe('config', function()
  local config

  before_each(function()
    -- Clear module cache to ensure fresh state
    package.loaded['claude-code.config'] = nil
    config = require('claude-code.config')
  end)

  describe('parse_config', function()
    it('should return default config when no user config is provided', function()
      local result = config.parse_config(nil, true) -- silent mode
      -- Check specific values to avoid floating point comparison issues
      assert.are.equal('current', result.window.position)
      assert.are.equal(true, result.window.enter_insert)
      assert.are.equal(true, result.refresh.enable)
      -- Use near equality for floating point values
      assert.is.near(0.3, result.window.split_ratio, 0.0001)
    end)

    it('should merge user config with default config', function()
      local user_config = {
        window = {
          split_ratio = 0.5,
        },
      }
      local result = config.parse_config(user_config, true) -- silent mode
      assert.is.near(0.5, result.window.split_ratio, 0.0001)

      -- Other values should be set to defaults
      assert.are.equal('current', result.window.position)
      assert.are.equal(true, result.window.enter_insert)
    end)

    it('should validate config values', function()
      -- This config has an invalid split_ratio (should be between 0 and 1)
      local invalid_config = {
        window = {
          split_ratio = 2,
        },
      }

      -- When validation fails, it should return the default config
      local result = config.parse_config(invalid_config, true) -- silent mode
      assert.are.equal(config.default_config.window.split_ratio, result.window.split_ratio)
    end)

    it('should maintain backward compatibility with height_ratio', function()
      -- Config using the legacy height_ratio instead of split_ratio
      local legacy_config = {
        window = {
          height_ratio = 0.7,
          -- split_ratio not specified
        },
      }

      local result = config.parse_config(legacy_config, true) -- silent mode

      -- split_ratio should be set to the height_ratio value
      -- The backward compatibility should copy height_ratio to split_ratio
      assert.is_not_nil(result.window.split_ratio)
      assert.is.near(result.window.height_ratio or 0.7, result.window.split_ratio, 0.0001)
    end)
  end)
end)
