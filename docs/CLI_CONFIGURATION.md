# CLI Configuration and Detection

## Overview

The claude-code.nvim plugin provides flexible configuration options for Claude CLI detection and usage. This document details the configuration system, detection logic, and available options.

## CLI Detection Order

The plugin uses a prioritized detection system to find the Claude CLI executable:

### 1. Custom Path (Highest Priority)
If a custom CLI path is specified in the configuration:
```lua
require('claude-code').setup({
  cli_path = "/custom/path/to/claude"
})
```

### 2. Local Installation (Preferred Default)
Checks for Claude CLI at: `~/.claude/local/claude`
- This is the recommended installation location
- Provides user-specific Claude installations
- Avoids PATH conflicts with system installations

### 3. PATH Fallback (Last Resort)
Falls back to `claude` command in system PATH
- Works with global installations
- Compatible with package manager installations

## Configuration Options

### Basic Configuration

```lua
require('claude-code').setup({
  -- Custom Claude CLI path (optional)
  cli_path = nil,  -- Default: auto-detect

  -- Standard Claude CLI command (auto-detected if not provided)
  command = "claude",  -- Default: auto-detected
  
  -- Other configuration options...
})
```

### Advanced Examples

#### Development Environment
```lua
-- Use development build of Claude CLI
require('claude-code').setup({
  cli_path = "/home/user/dev/claude-code/target/debug/claude"
})
```

#### Enterprise Environment
```lua
-- Use company-specific Claude installation
require('claude-code').setup({
  cli_path = "/opt/company/tools/claude"
})
```

#### Explicit Command Override
```lua
-- Override auto-detection completely
require('claude-code').setup({
  command = "/usr/local/bin/claude-beta"
})
```

## Detection Behavior

### Robust Validation
The detection system performs comprehensive validation:

1. **File Readability Check** - Ensures the file exists and is readable
2. **Executable Permission Check** - Verifies the file has execute permissions
3. **Fallback Logic** - Tries next option if current fails

### User Notifications

The plugin provides clear feedback about CLI detection:

#### Successful Custom Path
```
Claude Code: Using custom CLI at /custom/path/claude
```

#### Successful Local Installation
```
Claude Code: Using local installation at ~/.claude/local/claude
```

#### PATH Installation
```
Claude Code: Using 'claude' from PATH
```

#### Warning Messages
```
Claude Code: Custom CLI path not found: /invalid/path - falling back to default detection
Claude Code: CLI not found! Please install Claude Code or set config.command
```

## Testing

### Test-Driven Development
The CLI detection feature was implemented using TDD with comprehensive test coverage:

#### Test Categories
1. **Custom Path Tests** - Validate custom CLI path handling
2. **Default Detection Tests** - Test standard detection order
3. **Error Handling Tests** - Verify graceful failure modes
4. **Notification Tests** - Confirm user feedback messages

#### Running CLI Detection Tests
```bash
# Run all tests
nvim --headless -c "lua require('tests.run_tests')" -c "qall"

# Run specific CLI detection tests
nvim --headless -c "lua require('tests.run_tests').run_specific('cli_detection_spec')" -c "qall"
```

### Test Scenarios Covered

1. **Valid Custom Path** - Custom CLI path exists and is executable
2. **Invalid Custom Path** - Custom path doesn't exist, falls back to defaults
3. **Local Installation Present** - Default ~/.claude/local/claude works
4. **PATH Installation Only** - Only system PATH has Claude CLI
5. **No CLI Found** - No Claude CLI available anywhere
6. **Permission Issues** - File exists but not executable
7. **Notification Behavior** - Correct messages for each scenario

## Troubleshooting

### CLI Not Found
If you see: `Claude Code: CLI not found! Please install Claude Code or set config.command`

**Solutions:**
1. Install Claude CLI: `curl -sSL https://claude.ai/install.sh | bash`
2. Set custom path: `cli_path = "/path/to/claude"`
3. Override command: `command = "/path/to/claude"`

### Custom Path Not Working
If custom path fails to work:

1. **Check file exists:** `ls -la /your/custom/path`
2. **Verify permissions:** `chmod +x /your/custom/path`
3. **Test execution:** `/your/custom/path --version`

### Permission Issues
If file exists but isn't executable:

```bash
# Make executable
chmod +x ~/.claude/local/claude

# Or for custom path
chmod +x /your/custom/path/claude
```

## Implementation Details

### Configuration Validation
The plugin validates CLI configuration:

```lua
-- Validates cli_path if provided
if config.cli_path ~= nil and type(config.cli_path) ~= 'string' then
  return false, 'cli_path must be a string or nil'
end
```

### Detection Function
Core detection logic:

```lua
local function detect_claude_cli(custom_path)
  -- Check custom path first
  if custom_path then
    if vim.fn.filereadable(custom_path) == 1 and vim.fn.executable(custom_path) == 1 then
      return custom_path
    end
  end
  
  -- Check local installation
  local local_claude = vim.fn.expand("~/.claude/local/claude")
  if vim.fn.filereadable(local_claude) == 1 and vim.fn.executable(local_claude) == 1 then
    return local_claude
  end
  
  -- Fall back to PATH
  if vim.fn.executable("claude") == 1 then
    return "claude"
  end
  
  -- Nothing found
  return nil
end
```

### Silent Mode
For testing and programmatic usage:

```lua
-- Skip CLI detection in silent mode
local config = require('claude-code.config').parse_config({}, true)  -- silent = true
```

## Best Practices

### Recommended Setup
1. **Use local installation** (`~/.claude/local/claude`) for most users
2. **Use custom path** for development or enterprise environments
3. **Avoid hardcoding command** unless necessary for specific use cases

### Enterprise Deployment
```lua
-- Centralized configuration
require('claude-code').setup({
  cli_path = os.getenv("CLAUDE_CLI_PATH") or "/opt/company/claude",
  -- Fallback to company standard path
})
```

### Development Workflow
```lua
-- Switch between versions easily
local claude_version = os.getenv("CLAUDE_VERSION") or "stable"
local cli_paths = {
  stable = "~/.claude/local/claude",
  beta = "/home/user/claude-beta/claude",
  dev = "/home/user/dev/claude-code/target/debug/claude"
}

require('claude-code').setup({
  cli_path = vim.fn.expand(cli_paths[claude_version])
})
```

## Migration Guide

### From Previous Versions
If you were using command override:

```lua
-- Old approach
require('claude-code').setup({
  command = "/custom/path/claude"
})

-- New recommended approach
require('claude-code').setup({
  cli_path = "/custom/path/claude"  -- Preferred for custom paths
})
```

The `command` option still works and takes precedence over auto-detection, but `cli_path` is preferred for custom installations as it provides better error handling and user feedback.

### Backward Compatibility
- All existing configurations continue to work
- `command` option still overrides auto-detection
- No breaking changes to existing functionality

## Future Enhancements

Potential future improvements to CLI configuration:

1. **Version Detection** - Automatically detect and display Claude CLI version
2. **Health Checks** - Built-in CLI health and compatibility checking
3. **Multiple CLI Support** - Support for multiple Claude CLI versions simultaneously
4. **Auto-Update Integration** - Automatic CLI update notifications and handling
5. **Configuration Profiles** - Named configuration profiles for different environments