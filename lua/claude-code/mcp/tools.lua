local M = {}

-- Tool: Edit buffer content
M.vim_buffer = {
    name = "vim_buffer",
    description = "View or edit buffer content in Neovim",
    inputSchema = {
        type = "object",
        properties = {
            filename = {
                type = "string",
                description = "Optional file name to view a specific buffer"
            }
        },
        additionalProperties = false
    },
    handler = function(args)
        local filename = args.filename
        local bufnr
        
        if filename then
            -- Find buffer by filename
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                local buf_name = vim.api.nvim_buf_get_name(buf)
                if buf_name:match(vim.pesc(filename) .. "$") then
                    bufnr = buf
                    break
                end
            end
            
            if not bufnr then
                return "Buffer not found: " .. filename
            end
        else
            -- Use current buffer
            bufnr = vim.api.nvim_get_current_buf()
        end
        
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        local line_count = #lines
        
        local result = string.format("Buffer: %s (%d lines)\n\n", buf_name, line_count)
        
        for i, line in ipairs(lines) do
            result = result .. string.format("%4d\t%s\n", i, line)
        end
        
        return result
    end
}

-- Tool: Execute Vim command
M.vim_command = {
    name = "vim_command",
    description = "Execute a Vim command in Neovim",
    inputSchema = {
        type = "object",
        properties = {
            command = {
                type = "string",
                description = "Vim command to execute (use ! prefix for shell commands if enabled)"
            }
        },
        required = {"command"},
        additionalProperties = false
    },
    handler = function(args)
        local command = args.command
        
        local ok, result = pcall(vim.cmd, command)
        if not ok then
            return "Error executing command: " .. result
        end
        
        return "Command executed successfully: " .. command
    end
}

-- Tool: Get Neovim status
M.vim_status = {
    name = "vim_status",
    description = "Get current Neovim status and context",
    inputSchema = {
        type = "object",
        properties = {
            filename = {
                type = "string",
                description = "Optional file name to get status for a specific buffer"
            }
        },
        additionalProperties = false
    },
    handler = function(args)
        local filename = args.filename
        local bufnr
        
        if filename then
            -- Find buffer by filename
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                local buf_name = vim.api.nvim_buf_get_name(buf)
                if buf_name:match(vim.pesc(filename) .. "$") then
                    bufnr = buf
                    break
                end
            end
            
            if not bufnr then
                return "Buffer not found: " .. filename
            end
        else
            bufnr = vim.api.nvim_get_current_buf()
        end
        
        local cursor_pos = {1, 0}  -- Default to line 1, column 0
        local mode = vim.api.nvim_get_mode().mode
        
        -- Find window ID for the buffer
        local wins = vim.api.nvim_list_wins()
        for _, win in ipairs(wins) do
            if vim.api.nvim_win_get_buf(win) == bufnr then
                cursor_pos = vim.api.nvim_win_get_cursor(win)
                break
            end
        end
        
        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        local modified = vim.api.nvim_buf_get_option(bufnr, "modified")
        local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
        
        local result = {
            buffer = {
                number = bufnr,
                name = buf_name,
                filetype = filetype,
                line_count = line_count,
                modified = modified
            },
            cursor = {
                line = cursor_pos[1],
                column = cursor_pos[2]
            },
            mode = mode,
            window = winnr
        }
        
        return vim.json.encode(result)
    end
}

-- Tool: Edit buffer content
M.vim_edit = {
    name = "vim_edit",
    description = "Edit buffer content in Neovim",
    inputSchema = {
        type = "object",
        properties = {
            startLine = {
                type = "number",
                description = "The line number where editing should begin (1-indexed)"
            },
            mode = {
                type = "string",
                enum = {"insert", "replace", "replaceAll"},
                description = "Whether to insert new content, replace existing content, or replace entire buffer"
            },
            lines = {
                type = "string",
                description = "The text content to insert or use as replacement"
            }
        },
        required = {"startLine", "mode", "lines"},
        additionalProperties = false
    },
    handler = function(args)
        local start_line = args.startLine
        local mode = args.mode
        local lines_text = args.lines
        
        -- Convert text to lines array
        local lines = vim.split(lines_text, "\n", { plain = true })
        
        local bufnr = vim.api.nvim_get_current_buf()
        
        if mode == "replaceAll" then
            -- Replace entire buffer
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
            return "Buffer content replaced entirely"
        elseif mode == "insert" then
            -- Insert lines at specified position
            vim.api.nvim_buf_set_lines(bufnr, start_line - 1, start_line - 1, false, lines)
            return string.format("Inserted %d lines at line %d", #lines, start_line)
        elseif mode == "replace" then
            -- Replace lines starting at specified position
            local end_line = start_line - 1 + #lines
            vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, lines)
            return string.format("Replaced %d lines starting at line %d", #lines, start_line)
        else
            return "Invalid mode: " .. mode
        end
    end
}

-- Tool: Window management
M.vim_window = {
    name = "vim_window",
    description = "Manage Neovim windows",
    inputSchema = {
        type = "object",
        properties = {
            command = {
                type = "string",
                enum = {"split", "vsplit", "only", "close", "wincmd h", "wincmd j", "wincmd k", "wincmd l"},
                description = "Window manipulation command"
            }
        },
        required = {"command"},
        additionalProperties = false
    },
    handler = function(args)
        local command = args.command
        
        local ok, result = pcall(vim.cmd, command)
        if not ok then
            return "Error executing window command: " .. result
        end
        
        return "Window command executed: " .. command
    end
}

-- Tool: Set marks
M.vim_mark = {
    name = "vim_mark",
    description = "Set marks in Neovim",
    inputSchema = {
        type = "object",
        properties = {
            mark = {
                type = "string",
                pattern = "^[a-z]$",
                description = "Single lowercase letter [a-z] to use as the mark name"
            },
            line = {
                type = "number",
                description = "The line number where the mark should be placed (1-indexed)"
            },
            column = {
                type = "number",
                description = "The column number where the mark should be placed (0-indexed)"
            }
        },
        required = {"mark", "line", "column"},
        additionalProperties = false
    },
    handler = function(args)
        local mark = args.mark
        local line = args.line
        local column = args.column
        
        local bufnr = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_mark(bufnr, mark, line, column, {})
        
        return string.format("Mark '%s' set at line %d, column %d", mark, line, column)
    end
}

-- Tool: Register operations
M.vim_register = {
    name = "vim_register",
    description = "Set register content in Neovim",
    inputSchema = {
        type = "object",
        properties = {
            register = {
                type = "string",
                pattern = "^[a-z\"]$",
                description = "Register name - a lowercase letter [a-z] or double-quote [\"] for the unnamed register"
            },
            content = {
                type = "string",
                description = "The text content to store in the specified register"
            }
        },
        required = {"register", "content"},
        additionalProperties = false
    },
    handler = function(args)
        local register = args.register
        local content = args.content
        
        vim.fn.setreg(register, content)
        
        return string.format("Register '%s' set with content", register)
    end
}

-- Tool: Visual selection
M.vim_visual = {
    name = "vim_visual",
    description = "Make visual selections in Neovim",
    inputSchema = {
        type = "object",
        properties = {
            startLine = {
                type = "number",
                description = "The starting line number for visual selection (1-indexed)"
            },
            startColumn = {
                type = "number",
                description = "The starting column number for visual selection (0-indexed)"
            },
            endLine = {
                type = "number",
                description = "The ending line number for visual selection (1-indexed)"
            },
            endColumn = {
                type = "number",
                description = "The ending column number for visual selection (0-indexed)"
            }
        },
        required = {"startLine", "startColumn", "endLine", "endColumn"},
        additionalProperties = false
    },
    handler = function(args)
        local start_line = args.startLine
        local start_col = args.startColumn
        local end_line = args.endLine
        local end_col = args.endColumn
        
        -- Set cursor to start position
        vim.api.nvim_win_set_cursor(0, {start_line, start_col})
        
        -- Enter visual mode
        vim.cmd("normal! v")
        
        -- Move to end position
        vim.api.nvim_win_set_cursor(0, {end_line, end_col})
        
        return string.format("Visual selection from %d:%d to %d:%d", start_line, start_col, end_line, end_col)
    end
}

return M