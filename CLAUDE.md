# Project: Claude Code Plugin

## Overview
Claude Code Plugin provides seamless integration between the Claude Code AI assistant and Neovim. It enables direct communication with the Claude Code CLI from within the editor, context-aware interactions, and various utilities to enhance AI-assisted development within Neovim.

## Essential Commands
- Run Tests: `env -C /home/gregg/Projects/neovim/plugins/claude-code lua tests/run_tests.lua`
- Check Formatting: `env -C /home/gregg/Projects/neovim/plugins/claude-code stylua lua/ -c`
- Format Code: `env -C /home/gregg/Projects/neovim/plugins/claude-code stylua lua/`
- Run Linter: `env -C /home/gregg/Projects/neovim/plugins/claude-code luacheck lua/`
- Build Documentation: `env -C /home/gregg/Projects/neovim/plugins/claude-code mkdocs build`

## Project Structure
- `/lua/claude-code`: Main plugin code
- `/lua/claude-code/cli`: Claude Code CLI integration
- `/lua/claude-code/ui`: UI components for interactions
- `/lua/claude-code/context`: Context management utilities
- `/after/plugin`: Plugin setup and initialization
- `/tests`: Test files for plugin functionality
- `/doc`: Vim help documentation

## Current Focus
- Integrating nvim-toolkit for shared utilities
- Adding hooks-util as git submodule for development workflow
- Enhancing bidirectional communication with Claude Code CLI
- Implementing better context synchronization
- Adding buffer-specific context management

## Documentation Links
- Tasks: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/tasks/claude-code-tasks.md`
- Project Status: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/project-status.md`