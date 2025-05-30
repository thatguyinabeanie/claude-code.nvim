local M = {}

-- Resource: Current buffer content
M.current_buffer = {
    uri = "neovim://current-buffer",
    name = "Current Buffer",
    description = "Content of the currently active buffer",
    mimeType = "text/plain",
    handler = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
        
        local header = string.format("File: %s\nType: %s\nLines: %d\n\n", buf_name, filetype, #lines)
        return header .. table.concat(lines, "\n")
    end
}

-- Resource: Buffer list
M.buffer_list = {
    uri = "neovim://buffers",
    name = "Buffer List",
    description = "List of all open buffers with metadata",
    mimeType = "application/json",
    handler = function()
        local buffers = {}
        
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(bufnr) then
                local buf_name = vim.api.nvim_buf_get_name(bufnr)
                local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
                local modified = vim.api.nvim_buf_get_option(bufnr, "modified")
                local line_count = vim.api.nvim_buf_line_count(bufnr)
                local listed = vim.api.nvim_buf_get_option(bufnr, "buflisted")
                
                table.insert(buffers, {
                    number = bufnr,
                    name = buf_name,
                    filetype = filetype,
                    modified = modified,
                    line_count = line_count,
                    listed = listed,
                    current = bufnr == vim.api.nvim_get_current_buf()
                })
            end
        end
        
        return vim.json.encode({
            buffers = buffers,
            total_count = #buffers,
            current_buffer = vim.api.nvim_get_current_buf()
        })
    end
}

-- Resource: Project structure
M.project_structure = {
    uri = "neovim://project",
    name = "Project Structure",
    description = "File tree of the current working directory",
    mimeType = "text/plain",
    handler = function()
        local cwd = vim.fn.getcwd()
        
        -- Simple directory listing (could be enhanced with tree structure)
        local handle = io.popen("find " .. vim.fn.shellescape(cwd) .. " -type f -name '*.lua' -o -name '*.vim' -o -name '*.js' -o -name '*.ts' -o -name '*.py' -o -name '*.md' | head -50")
        if not handle then
            return "Error: Could not list project files"
        end
        
        local result = handle:read("*a")
        handle:close()
        
        local header = string.format("Project: %s\n\nRecent files:\n", cwd)
        return header .. result
    end
}

-- Resource: Git status
M.git_status = {
    uri = "neovim://git-status",
    name = "Git Status",
    description = "Current git repository status",
    mimeType = "text/plain",
    handler = function()
        local handle = io.popen("git status --porcelain 2>/dev/null")
        if not handle then
            return "Not a git repository or git not available"
        end
        
        local status = handle:read("*a")
        handle:close()
        
        if status == "" then
            return "Working tree clean"
        end
        
        local lines = vim.split(status, "\n", { plain = true })
        local result = "Git Status:\n\n"
        
        for _, line in ipairs(lines) do
            if line ~= "" then
                local status_code = line:sub(1, 2)
                local file = line:sub(4)
                local status_desc = ""
                
                if status_code:match("^M") then
                    status_desc = "Modified"
                elseif status_code:match("^A") then
                    status_desc = "Added"
                elseif status_code:match("^D") then
                    status_desc = "Deleted"
                elseif status_code:match("^R") then
                    status_desc = "Renamed"
                elseif status_code:match("^C") then
                    status_desc = "Copied"
                elseif status_code:match("^U") then
                    status_desc = "Unmerged"
                elseif status_code:match("^%?") then
                    status_desc = "Untracked"
                else
                    status_desc = "Unknown"
                end
                
                result = result .. string.format("%s: %s\n", status_desc, file)
            end
        end
        
        return result
    end
}

-- Resource: LSP diagnostics
M.lsp_diagnostics = {
    uri = "neovim://lsp-diagnostics",
    name = "LSP Diagnostics",
    description = "Language server diagnostics for current buffer",
    mimeType = "application/json",
    handler = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local diagnostics = vim.diagnostic.get(bufnr)
        
        local result = {
            buffer = bufnr,
            file = vim.api.nvim_buf_get_name(bufnr),
            diagnostics = {}
        }
        
        for _, diag in ipairs(diagnostics) do
            table.insert(result.diagnostics, {
                line = diag.lnum + 1,  -- Convert to 1-indexed
                column = diag.col + 1, -- Convert to 1-indexed
                severity = diag.severity,
                message = diag.message,
                source = diag.source,
                code = diag.code
            })
        end
        
        result.total_count = #result.diagnostics
        
        return vim.json.encode(result)
    end
}

-- Resource: Vim options
M.vim_options = {
    uri = "neovim://options",
    name = "Vim Options",
    description = "Current Neovim configuration and options",
    mimeType = "application/json",
    handler = function()
        local options = {
            global = {},
            buffer = {},
            window = {}
        }
        
        -- Common global options
        local global_opts = {
            "background", "colorscheme", "encoding", "fileformat",
            "hidden", "ignorecase", "smartcase", "incsearch",
            "number", "relativenumber", "wrap", "scrolloff"
        }
        
        for _, opt in ipairs(global_opts) do
            local ok, value = pcall(vim.api.nvim_get_option, opt)
            if ok then
                options.global[opt] = value
            end
        end
        
        -- Buffer-local options
        local bufnr = vim.api.nvim_get_current_buf()
        local buffer_opts = {
            "filetype", "tabstop", "shiftwidth", "expandtab",
            "autoindent", "smartindent", "modified", "readonly"
        }
        
        for _, opt in ipairs(buffer_opts) do
            local ok, value = pcall(vim.api.nvim_buf_get_option, bufnr, opt)
            if ok then
                options.buffer[opt] = value
            end
        end
        
        -- Window-local options
        local winnr = vim.api.nvim_get_current_win()
        local window_opts = {
            "number", "relativenumber", "wrap", "cursorline",
            "cursorcolumn", "foldcolumn", "signcolumn"
        }
        
        for _, opt in ipairs(window_opts) do
            local ok, value = pcall(vim.api.nvim_win_get_option, winnr, opt)
            if ok then
                options.window[opt] = value
            end
        end
        
        return vim.json.encode(options)
    end
}

return M