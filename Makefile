.PHONY: test test-debug test-legacy test-basic test-config test-mcp lint format docs clean

# Configuration
LUA_PATH ?= lua/
TEST_PATH ?= tests/
DOC_PATH ?= doc/

# Test command (runs only Plenary tests by default)
test:
	@echo "Running Plenary tests..."
	@./scripts/test.sh

# Debug test command - more verbose output
test-debug:
	@echo "Running tests in debug mode..."
	@echo "Path: $(PATH)"
	@echo "LUA_PATH: $(LUA_PATH)"
	@which nvim
	@nvim --version
	@echo "Running Plenary tests with debug output..."
	@PLENARY_DEBUG=1 ./scripts/test.sh

# Legacy test commands
test-legacy:
	@echo "Running legacy tests..."
	@nvim --headless --noplugin -u tests/legacy/minimal.vim -c "lua print('Running basic tests')" -c "source tests/legacy/basic_test.vim" -c "qa!"
	@nvim --headless --noplugin -u tests/legacy/minimal.vim -c "lua print('Running config tests')" -c "source tests/legacy/config_test.vim" -c "qa!"

# Individual test commands
test-basic:
	@echo "Running basic tests..."
	@nvim --headless --noplugin -u tests/legacy/minimal.vim -c "source tests/legacy/basic_test.vim" -c "qa!"

test-config:
	@echo "Running config tests..."
	@nvim --headless --noplugin -u tests/legacy/minimal.vim -c "source tests/legacy/config_test.vim" -c "qa!"

# MCP integration tests
test-mcp:
	@echo "Running MCP integration tests..."
	@./scripts/test_mcp.sh

# Lint Lua files
lint:
	@echo "Linting Lua files..."
	@luacheck $(LUA_PATH)

# Format Lua files with stylua
format:
	@echo "Formatting Lua files..."
	@stylua $(LUA_PATH)

# Generate documentation
docs:
	@echo "Generating documentation..."
	@if command -v ldoc > /dev/null 2>&1; then \
		ldoc $(LUA_PATH) -d $(DOC_PATH)luadoc -c .ldoc.cfg || true; \
	else \
		echo "ldoc not installed. Skipping documentation generation."; \
	fi

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -rf $(DOC_PATH)luadoc

# Default target
all: lint format test docs

help:
	@echo "Claude Code development commands:"
	@echo "  make test         - Run all tests (using Plenary test framework)"
	@echo "  make test-debug   - Run all tests with debug output"
	@echo "  make test-mcp     - Run MCP integration tests"
	@echo "  make test-legacy  - Run legacy tests (VimL-based)"
	@echo "  make test-basic   - Run only basic functionality tests (legacy)"
	@echo "  make test-config  - Run only configuration tests (legacy)"
	@echo "  make lint         - Lint Lua files"
	@echo "  make format       - Format Lua files with stylua"
	@echo "  make docs         - Generate documentation"
	@echo "  make clean        - Remove generated files"
	@echo "  make all          - Run lint, format, test, and docs"