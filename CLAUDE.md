
# Project: claude code plugin

## Overview

Claude Code Plugin provides seamless integration between the Claude Code AI assistant and Neovim. It enables direct communication with the Claude Code command-line tool from within the editor, context-aware interactions, and various utilities to enhance AI-assisted development within Neovim.

## Essential commands

- Run Tests: `env -C /home/gregg/Projects/neovim/plugins/claude-code lua tests/run_tests.lua`
- Check Formatting: `env -C /home/gregg/Projects/neovim/plugins/claude-code stylua lua/ -c`
- Format Code: `env -C /home/gregg/Projects/neovim/plugins/claude-code stylua lua/`
- Run Linter: `env -C /home/gregg/Projects/neovim/plugins/claude-code luacheck lua/`
- Build Documentation: `env -C /home/gregg/Projects/neovim/plugins/claude-code mkdocs build`

## Project structure

- `/lua/claude-code`: Main plugin code
- `/lua/claude-code/cli`: Claude Code command-line tool integration
- `/lua/claude-code/ui`: UI components for interactions
- `/lua/claude-code/context`: Context management utilities
- `/after/plugin`: Plugin setup and initialization
- `/tests`: Test files for plugin functionality
- `/doc`: Vim help documentation

## MCP Server Architecture History

**IMPORTANT ARCHITECTURAL DECISION CONTEXT:**

This project originally attempted to implement a native pure Lua MCP (Model Context Protocol) server within Neovim to replace the external `mcp-neovim-server`. The goals were:

- Eliminate external Node.js dependency
- Add additional features not available in the original `mcp-neovim-server`
- Provide tighter integration with Neovim's internal state

**Why we moved away from the native Lua implementation:**

The native Lua MCP server caused severe performance degradation in Neovim because:
- Neovim had to run both the editor and the MCP server simultaneously
- This created significant resource contention and blocking operations
- User experience became unacceptably slow and sluggish
- The performance cost outweighed the benefits of native integration

**Current approach:**

We now use a **forked version of `mcp-neovim-server`** that includes the additional features we needed. This fork:
- Runs as an external process (no performance impact on Neovim)
- Maintains the same MCP protocol compatibility
- Includes enhanced features not in the upstream version
- Is a work in progress with plans to contribute changes back to upstream

**Future plans:**
- Merge our enhancements into the main `mcp-neovim-server` repository
- Publish improvements for the broader community
- Continue using external MCP server approach for optimal performance

## Current focus

- Using forked mcp-neovim-server with enhanced features
- Enhancing bidirectional communication with Claude Code command-line tool
- Implementing better context synchronization
- Adding buffer-specific context management
- Contributing improvements back to upstream mcp-neovim-server

## Multi-instance support

The plugin supports running multiple Claude Code instances, one per git repository root:

- Each git repository maintains its own Claude instance
- Works across multiple Neovim tabs with different projects
- Allows working on multiple projects in parallel
- Configurable via `git.multi_instance` option (defaults to `true`)
- Instances remain in their own directory context when switching between tabs
- Buffer names include the git root path for easy identification

Example configuration to disable multi-instance mode:

```lua
require('claude-code').setup({
  git = {
    multi_instance = false  -- Use a single global Claude instance
  }
})

```text

## Documentation links

- Tasks: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/tasks/claude-code-tasks.md`
- Project Status: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/project-status.md`

