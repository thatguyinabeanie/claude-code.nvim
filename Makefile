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

# Comprehensive linting for all file types
lint: lint-lua lint-shell lint-markdown lint-stylua

# Lint Lua files with luacheck
lint-lua:
	@echo "Linting Lua files..."
	@if command -v luacheck > /dev/null 2>&1; then \
		luacheck $(LUA_PATH); \
	else \
		echo "luacheck not found. Install with: luarocks install luacheck"; \
		exit 1; \
	fi

# Check Lua formatting with stylua
lint-stylua:
	@echo "Checking Lua formatting..."
	@if command -v stylua > /dev/null 2>&1; then \
		stylua --check $(LUA_PATH); \
	else \
		echo "stylua not found. Install with: cargo install stylua"; \
		exit 1; \
	fi

# Lint shell scripts with shellcheck
lint-shell:
	@echo "Linting shell scripts..."
	@if command -v shellcheck > /dev/null 2>&1; then \
		find . -name "*.sh" -type f ! -path "./.git/*" ! -path "./node_modules/*" ! -path "./.vscode/*" -print0 | \
		xargs -0 -I {} sh -c 'echo "Checking {}"; shellcheck "{}"'; \
	else \
		echo "shellcheck not found. Install with your package manager (apt install shellcheck, brew install shellcheck, etc.)"; \
		exit 1; \
	fi

# Lint markdown files
lint-markdown:
	@echo "Linting markdown files..."
	@if command -v markdownlint-cli2 > /dev/null 2>&1; then \
		markdownlint-cli2 '*.md' 'doc/**/*.md' 'docs/**/*.md' 'tests/**/*.md' 'mcp-server/**/*.md' --config .markdownlint.json; \
	elif command -v markdownlint > /dev/null 2>&1; then \
		markdownlint '*.md' 'doc/**/*.md' 'docs/**/*.md' 'tests/**/*.md' 'mcp-server/**/*.md' --config .markdownlint.json; \
	else \
		echo "markdownlint not found. Install with: npm install -g markdownlint-cli2"; \
		exit 1; \
	fi

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

# Check if development dependencies are installed
check-dependencies:
	@echo "Checking development dependencies..."
	@echo "=================================="
	@failed=0; \
	echo "Essential tools:"; \
	if command -v nvim > /dev/null 2>&1; then \
		echo "  ✓ neovim: $$(nvim --version | head -1)"; \
	else \
		echo "  ✗ neovim: not found"; \
		failed=1; \
	fi; \
	if command -v lua > /dev/null 2>&1 || command -v lua5.1 > /dev/null 2>&1 || command -v lua5.3 > /dev/null 2>&1; then \
		lua_ver=$$(lua -v 2>/dev/null || lua5.1 -v 2>/dev/null || lua5.3 -v 2>/dev/null || echo "unknown version"); \
		echo "  ✓ lua: $$lua_ver"; \
	else \
		echo "  ✗ lua: not found"; \
		failed=1; \
	fi; \
	if command -v luarocks > /dev/null 2>&1; then \
		echo "  ✓ luarocks: $$(luarocks --version | head -1)"; \
	else \
		echo "  ✗ luarocks: not found"; \
		failed=1; \
	fi; \
	echo; \
	echo "Linting tools:"; \
	if command -v luacheck > /dev/null 2>&1; then \
		echo "  ✓ luacheck: $$(luacheck --version)"; \
	else \
		echo "  ✗ luacheck: not found"; \
		failed=1; \
	fi; \
	if command -v stylua > /dev/null 2>&1; then \
		echo "  ✓ stylua: $$(stylua --version)"; \
	else \
		echo "  ✗ stylua: not found"; \
		failed=1; \
	fi; \
	if command -v shellcheck > /dev/null 2>&1; then \
		echo "  ✓ shellcheck: $$(shellcheck --version | grep version:)"; \
	else \
		echo "  ✗ shellcheck: not found"; \
		failed=1; \
	fi; \
	if command -v markdownlint-cli2 > /dev/null 2>&1; then \
		echo "  ✓ markdownlint-cli2: $$(markdownlint-cli2 --version)"; \
	elif command -v markdownlint > /dev/null 2>&1; then \
		echo "  ✓ markdownlint: $$(markdownlint --version)"; \
	else \
		echo "  ✗ markdownlint: not found"; \
		failed=1; \
	fi; \
	echo; \
	echo "Optional tools:"; \
	if command -v ldoc > /dev/null 2>&1; then \
		echo "  ✓ ldoc: available"; \
	else \
		echo "  ○ ldoc: not found (optional for documentation)"; \
	fi; \
	if command -v git > /dev/null 2>&1; then \
		echo "  ✓ git: $$(git --version)"; \
	else \
		echo "  ○ git: not found (recommended)"; \
	fi; \
	echo; \
	if [ $$failed -eq 0 ]; then \
		echo "✅ All required dependencies are installed!"; \
	else \
		echo "❌ Some dependencies are missing. Run 'make install-dependencies' to install them."; \
		exit 1; \
	fi

# Install development dependencies
install-dependencies:
	@echo "Installing development dependencies..."
	@echo "====================================="
	@echo "Note: This will attempt to install dependencies using available package managers."
	@echo "You may be prompted for your password for system package installations."
	@echo
	@if command -v brew > /dev/null 2>&1; then \
		echo "📦 Using Homebrew (macOS)..."; \
		echo "Installing system dependencies..."; \
		brew install neovim lua luarocks shellcheck || true; \
		brew install stylua || echo "stylua not available via brew, will try cargo"; \
		echo "Installing Node.js dependencies..."; \
		npm install -g markdownlint-cli2 || echo "npm not available or failed"; \
		echo "Installing Lua dependencies..."; \
		luarocks install luacheck || echo "luacheck installation failed"; \
		luarocks install ldoc || echo "ldoc installation failed (optional)"; \
	elif command -v apt-get > /dev/null 2>&1; then \
		echo "📦 Using APT (Ubuntu/Debian)..."; \
		echo "Updating package list..."; \
		sudo apt-get update; \
		echo "Installing system dependencies..."; \
		sudo apt-get install -y neovim lua5.3 luarocks shellcheck || true; \
		echo "Installing Node.js dependencies..."; \
		if command -v npm > /dev/null 2>&1; then \
			npm install -g markdownlint-cli2 || echo "markdownlint-cli2 installation failed"; \
		else \
			echo "npm not found. Please install Node.js first."; \
		fi; \
		echo "Installing Lua dependencies..."; \
		luarocks install luacheck || echo "luacheck installation failed"; \
		luarocks install ldoc || echo "ldoc installation failed (optional)"; \
		echo "Installing stylua..."; \
		if command -v cargo > /dev/null 2>&1; then \
			cargo install stylua; \
		else \
			echo "cargo not found. Installing stylua manually..."; \
			curl -L -o stylua.zip $$(curl -s https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest | grep "browser_download_url.*linux.*zip" | cut -d '"' -f 4); \
			unzip stylua.zip; \
			chmod +x stylua; \
			sudo mv stylua /usr/local/bin/; \
			rm stylua.zip; \
		fi; \
	elif command -v dnf > /dev/null 2>&1; then \
		echo "📦 Using DNF (Fedora)..."; \
		echo "Installing system dependencies..."; \
		sudo dnf install -y neovim lua luarocks ShellCheck || true; \
		echo "Installing Node.js dependencies..."; \
		if command -v npm > /dev/null 2>&1; then \
			npm install -g markdownlint-cli2 || echo "markdownlint-cli2 installation failed"; \
		else \
			echo "npm not found. Please install Node.js first."; \
		fi; \
		echo "Installing Lua dependencies..."; \
		luarocks install luacheck || echo "luacheck installation failed"; \
		luarocks install ldoc || echo "ldoc installation failed (optional)"; \
		echo "Installing stylua..."; \
		if command -v cargo > /dev/null 2>&1; then \
			cargo install stylua; \
		else \
			echo "Please install stylua manually or install Rust/Cargo first."; \
		fi; \
	elif command -v pacman > /dev/null 2>&1; then \
		echo "📦 Using Pacman (Arch Linux)..."; \
		echo "Installing system dependencies..."; \
		sudo pacman -S --noconfirm neovim lua luarocks shellcheck || true; \
		echo "Installing Node.js dependencies..."; \
		if command -v npm > /dev/null 2>&1; then \
			npm install -g markdownlint-cli2 || echo "markdownlint-cli2 installation failed"; \
		else \
			echo "npm not found. Please install Node.js first."; \
		fi; \
		echo "Installing Lua dependencies..."; \
		luarocks install luacheck || echo "luacheck installation failed"; \
		luarocks install ldoc || echo "ldoc installation failed (optional)"; \
		echo "Installing stylua from AUR..."; \
		if command -v yay > /dev/null 2>&1; then \
			yay -S stylua; \
		elif command -v paru > /dev/null 2>&1; then \
			paru -S stylua; \
		elif command -v cargo > /dev/null 2>&1; then \
			cargo install stylua; \
		else \
			echo "Please install stylua manually or install an AUR helper/Rust."; \
		fi; \
	else \
		echo "🤔 No recognized package manager found."; \
		echo "Please install dependencies manually:"; \
		echo "  - neovim (0.8+)"; \
		echo "  - lua (5.1, 5.3, or 5.4)"; \
		echo "  - luarocks"; \
		echo "  - shellcheck"; \
		echo "  - stylua (via cargo install stylua)"; \
		echo "  - markdownlint-cli2 (via npm install -g markdownlint-cli2)"; \
		echo "  - luacheck (via luarocks install luacheck)"; \
		echo ""; \
		echo "Or try running parts of this installation manually."; \
		exit 1; \
	fi; \
	echo; \
	echo "🔍 Checking installation results..."; \
	$(MAKE) check-dependencies

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
	@echo "  make lint         - Run comprehensive linting (Lua, shell, markdown)"
	@echo "  make lint-lua     - Lint only Lua files with luacheck"
	@echo "  make lint-stylua  - Check Lua formatting with stylua"
	@echo "  make lint-shell   - Lint shell scripts with shellcheck"
	@echo "  make lint-markdown - Lint markdown files with markdownlint"
	@echo "  make format       - Format Lua files with stylua"
	@echo "  make docs         - Generate documentation"
	@echo "  make clean        - Remove generated files"
	@echo "  make all          - Run lint, format, test, and docs"
	@echo ""
	@echo "Development setup:"
	@echo "  make check-dependencies   - Check if dev dependencies are installed"
	@echo "  make install-dependencies - Install missing dev dependencies"