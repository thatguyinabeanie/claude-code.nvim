# Claude Code Neovim Plugin: Enhanced Context Features Implementation

## Overview

This document summarizes the comprehensive enhancements made to the claude-code.nvim plugin, focusing on adding context-aware features that mirror Claude Code's built-in IDE integrations while maintaining the powerful MCP (Model Context Protocol) server capabilities.

## Background

The original plugin provided:

- Basic terminal interface to Claude Code CLI
- Traditional MCP server for programmatic control
- Simple buffer management and file refresh

**The Challenge:** Users wanted the same seamless context experience as Claude Code's built-in VS Code/Cursor integrations, where current file, selection, and project context are automatically included in conversations.

## Implementation Summary

### 1. Context Analysis Module (`lua/claude-code/context.lua`)

Created a comprehensive context analysis system supporting multiple programming languages:

#### **Language Support:**

- **Lua**: `require()`, `dofile()`, `loadfile()` patterns
- **JavaScript/TypeScript**: `import`/`require` with relative path resolution
- **Python**: `import`/`from` with module path conversion
- **Go**: `import` statements with relative path handling

#### **Key Functions:**

- `get_related_files(filepath, max_depth)` - Discovers files through import/require analysis
- `get_recent_files(limit)` - Retrieves recently accessed project files
- `get_workspace_symbols()` - LSP workspace symbol discovery
- `get_enhanced_context()` - Comprehensive context aggregation

#### **Smart Features:**

- **Dependency depth control** (default: 2 levels)
- **Project-aware filtering** (only includes current project files)
- **Module-to-path conversion** for each language's conventions
- **Relative vs absolute import handling**

### 2. Enhanced Terminal Interface (`lua/claude-code/terminal.lua`)

Extended the terminal interface with context-aware toggle functionality:

#### **New Function: `toggle_with_context(context_type)`**

**Context Types:**

- `"file"` - Current file with cursor position (`claude --file "path#line"`)
- `"selection"` - Visual selection as temporary markdown file
- `"workspace"` - Enhanced context with related files, recent files, and current file content
- `"auto"` - Smart detection (selection if in visual mode, otherwise file)

#### **Workspace Context Features:**

- **Context summary file** with current file info, cursor position, file type
- **Related files section** with dependency depth and import counts
- **Recent files list** (top 5 most recent)
- **Complete current file content** in proper markdown code blocks
- **Automatic cleanup** of temporary files after 10 seconds

### 3. Enhanced MCP Resources (`lua/claude-code/mcp/resources.lua`)

Added four new MCP resources for advanced context access:

#### **`neovim://related-files`**

```json
{
  "current_file": "lua/claude-code/init.lua",
  "related_files": [
    {
      "path": "lua/claude-code/config.lua",
      "depth": 1,
      "language": "lua",
      "import_count": 3
    }
  ]
}
```

#### **`neovim://recent-files`**

```json
{
  "project_root": "/path/to/project",
  "recent_files": [
    {
      "path": "/path/to/file.lua",
      "relative_path": "lua/file.lua",
      "last_used": 1
    }
  ]
}
```

#### **`neovim://workspace-context`**

Complete enhanced context including current file, related files, recent files, and workspace symbols.

#### **`neovim://search-results`**

```json
{
  "search_pattern": "function",
  "quickfix_list": [...],
  "readable_quickfix": [
    {
      "filename": "lua/init.lua",
      "lnum": 42,
      "text": "function M.setup()",
      "type": "I"
    }
  ]
}
```

### 4. Enhanced MCP Tools (`lua/claude-code/mcp/tools.lua`)

Added three new MCP tools for intelligent workspace analysis:

#### **`analyze_related`**

- Analyzes files related through imports/requires
- Configurable dependency depth
- Lists imports and dependency relationships
- Returns markdown formatted analysis

#### **`find_symbols`**

- LSP workspace symbol search
- Query filtering support
- Returns symbol locations and metadata
- Supports symbol type and container information

#### **`search_files`**

- File pattern searching across project
- Optional content inclusion
- Returns file paths with preview content
- Limited results for performance

### 5. Enhanced Commands (`lua/claude-code/commands.lua`)

Added new user commands for context-aware interactions:

```vim
:ClaudeCodeWithFile      " Current file + cursor position
:ClaudeCodeWithSelection " Visual selection
:ClaudeCodeWithContext   " Smart auto-detection
:ClaudeCodeWithWorkspace " Enhanced workspace context
```

### 6. Test Infrastructure Consolidation

Reorganized and enhanced the testing structure:

#### **Directory Consolidation:**

- Moved files from `test/` to organized `tests/` subdirectories
- Created `tests/legacy/` for VimL-based tests
- Created `tests/interactive/` for manual testing utilities
- Updated all references in Makefile, scripts, and CI

#### **Updated References:**

- Makefile test commands now use `tests/legacy/`
- MCP test script updated for new paths
- CI workflow enhanced with better directory verification
- README updated with new test structure documentation

### 7. Documentation Updates

Comprehensive documentation updates across multiple files:

#### **README.md Enhancements:**

- Added context-aware commands section
- Enhanced features list with new capabilities
- Updated MCP server description with new resources
- Added emoji indicators for new features

#### **ROADMAP.md Updates:**

- Marked context helper features as completed ✅
- Added context-aware integration goals
- Updated completion status for workspace context features

## Technical Details

### **Import/Require Pattern Matching**

The context analysis uses sophisticated regex patterns for each language:

```lua
-- Lua example
"require%s*%(?['\"]([^'\"]+)['\"]%)?",

-- JavaScript/TypeScript example  
"import%s+.-from%s+['\"]([^'\"]+)['\"]",

-- Python example
"from%s+([%w%.]+)%s+import",
```

### **Path Resolution Logic**

Smart path resolution handles different import styles:

- **Relative imports:** `./module` → `current_dir/module.ext`
- **Absolute imports:** `module.name` → `project_root/module/name.ext`
- **Module conventions:** `module.name` → both `module/name.ext` and `module/name/index.ext`

### **Context File Generation**

Workspace context generates comprehensive markdown files:

```markdown
# Workspace Context

**Current File:** lua/claude-code/init.lua
**Cursor Position:** Line 42
**File Type:** lua

## Related Files (through imports/requires)
- **lua/claude-code/config.lua** (depth: 1, language: lua, imports: 3)

## Recent Files
- lua/claude-code/terminal.lua

## Current File Content
```lua
-- Complete file content here
```

```

### **Temporary File Management**

Context-aware features use secure temporary file handling:
- Files created in system temp directory with `.md` extension
- Automatic cleanup after 10 seconds using `vim.defer_fn()`
- Proper error handling for file operations

## Benefits Achieved

### **For Users:**
1. **Seamless Context Experience** - Same automatic context as built-in IDE integrations
2. **Smart Context Detection** - Auto-detects whether to send file or selection
3. **Enhanced Workspace Awareness** - Related files discovered automatically
4. **Flexible Context Control** - Choose specific context type when needed

### **For Developers:**
1. **Comprehensive MCP Resources** - Rich context data for MCP clients
2. **Advanced Analysis Tools** - Programmatic access to workspace intelligence
3. **Language-Agnostic Design** - Extensible pattern system for new languages
4. **Robust Error Handling** - Graceful fallbacks when modules unavailable

### **For the Project:**
1. **Test Organization** - Cleaner, more maintainable test structure
2. **Documentation Quality** - Comprehensive usage examples and feature descriptions
3. **Feature Completeness** - Addresses all missing context features identified
4. **Backward Compatibility** - All existing functionality preserved

## Usage Examples

### **Basic Context Commands:**
```vim
" Pass current file with cursor position
:ClaudeCodeWithFile

" Send visual selection (use in visual mode)
:ClaudeCodeWithSelection  

" Smart detection - file or selection
:ClaudeCodeWithContext

" Full workspace context with related files
:ClaudeCodeWithWorkspace
```

### **MCP Client Usage:**

```javascript
// Read related files through MCP
const relatedFiles = await client.readResource("neovim://related-files");

// Analyze dependencies programmatically  
const analysis = await client.callTool("analyze_related", { max_depth: 3 });

// Search workspace symbols
const symbols = await client.callTool("find_symbols", { query: "setup" });
```

## Latest Update: Configurable CLI Path Support (TDD Implementation)

### **CLI Configuration Enhancement**

Added robust configurable Claude CLI path support using Test-Driven Development:

#### **Key Features:**

- **`cli_path` Configuration Option** - Custom path to Claude CLI executable
- **Enhanced Detection Order:**
  1. Custom path from `config.cli_path` (if provided)
  2. Local installation at `~/.claude/local/claude` (preferred)
  3. Falls back to `claude` in PATH
- **Robust Error Handling** - Checks file readability before executability
- **User Notifications** - Informative messages about CLI detection results

#### **Configuration Example:**

```lua
require('claude-code').setup({
  cli_path = "/custom/path/to/claude",  -- Optional custom CLI path
  -- ... other config options
})
```

#### **Test-Driven Development:**

- **14 comprehensive test cases** covering all CLI detection scenarios
- **Custom path validation** with fallback behavior
- **Error handling tests** for invalid paths and missing CLI
- **Notification testing** for different detection outcomes

#### **Benefits:**

- **Enterprise Compatibility** - Custom installation paths supported
- **Development Flexibility** - Test different Claude CLI versions
- **Robust Detection** - Graceful fallbacks when CLI not found
- **Clear User Feedback** - Notifications explain which CLI is being used

## Files Modified/Created

### **New Files:**

- `lua/claude-code/context.lua` - Context analysis engine
- `tests/spec/cli_detection_spec.lua` - TDD test suite for CLI detection
- Various test files moved to organized structure

### **Enhanced Files:**

- `lua/claude-code/config.lua` - CLI detection and configuration validation
- `lua/claude-code/terminal.lua` - Context-aware toggle function
- `lua/claude-code/commands.lua` - New context commands
- `lua/claude-code/init.lua` - Expose context functions
- `lua/claude-code/mcp/resources.lua` - Enhanced resources
- `lua/claude-code/mcp/tools.lua` - Analysis tools
- `README.md` - Comprehensive documentation updates including CLI configuration
- `ROADMAP.md` - Progress tracking updates
- `Makefile` - Updated test paths
- `.github/workflows/ci.yml` - Enhanced CI verification
- `scripts/test_mcp.sh` - Updated module paths

## Testing and Validation

### **Automated Tests:**

- MCP integration tests verify new resources load correctly
- Context module functions validated for proper API exposure
- Command registration confirmed for all new commands

### **Manual Validation:**

- Context analysis tested with multi-language projects
- Related file discovery validated across different import styles
- Workspace context generation tested with various file types

## Future Enhancements

The implementation provides a solid foundation for additional features:

1. **Tree-sitter Integration** - Use AST parsing for more accurate import analysis
2. **Cache System** - Cache related file analysis for better performance  
3. **Custom Language Support** - User-configurable import patterns
4. **Context Filtering** - User preferences for context inclusion/exclusion
5. **Visual Context Selection** - UI for choosing specific context elements

## Conclusion

This implementation successfully bridges the gap between traditional MCP server functionality and the context-aware experience of Claude Code's built-in IDE integrations. Users now have:

- **Automatic context passing** like built-in integrations
- **Powerful programmatic control** through enhanced MCP resources
- **Intelligent workspace analysis** through import/require discovery
- **Flexible context options** for different use cases

The modular design ensures maintainability while the comprehensive test coverage and documentation provide a solid foundation for future development.
