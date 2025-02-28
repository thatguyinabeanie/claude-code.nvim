-- Tests for the config module

local config = require('claude-code.config')

describe('config', function()
  describe('parse_config', function()
    it('should return default config when no user config is provided', function()
      local result = config.parse_config()
      assert.same(config.default_config, result)
    end)

    it('should merge user config with default config', function()
      local user_config = {
        window = {
          height_ratio = 0.5,
        },
      }
      local result = config.parse_config(user_config)
      assert.equal(0.5, result.window.height_ratio)
      
      -- Other values should be set to defaults
      assert.equal('botright', result.window.position)
      assert.equal(true, result.window.enter_insert)
    end)

    it('should validate config values', function()
      -- This config has an invalid height_ratio (should be between 0 and 1)
      local invalid_config = {
        window = {
          height_ratio = 2,
        },
      }
      
      -- When validation fails, it should return the default config
      local result = config.parse_config(invalid_config)
      assert.equal(config.default_config.window.height_ratio, result.window.height_ratio)
    end)
  end)
end)