local uv = vim.loop
local M = {}

-- Simple HTTP server for MCP endpoints

function M.start(opts)
  opts = opts or {}
  local host = opts.host or "127.0.0.1"
  local port = opts.port or 27123

  local server = uv.new_tcp()
  server:bind(host, port)
  server:listen(128, function(err)
    assert(not err, err)
    local client = uv.new_tcp()
    server:accept(client)
    client:read_start(function(err, chunk)
      assert(not err, err)
      if chunk then
        local req = chunk
        -- Only handle GET /mcp/config and POST/DELETE /mcp/session
        if req:find("GET /mcp/config") then
          local body = vim.json.encode({
            name = "neovim-lua",
            version = "0.1.0",
            description = "Pure Lua MCP server for Neovim",
            capabilities = {
              tools = {
                {
                  name = "vim_buffer",
                  description = "Read/write buffer content"
                },
                {
                  name = "vim_command",
                  description = "Execute Vim commands"
                },
                {
                  name = "vim_status",
                  description = "Get current editor status"
                },
                {
                  name = "vim_edit",
                  description = "Edit buffer content with insert/replace/replaceAll modes"
                },
                {
                  name = "vim_window",
                  description = "Manage windows (split, close, navigate)"
                },
                {
                  name = "vim_mark",
                  description = "Set marks in buffers"
                },
                {
                  name = "vim_register",
                  description = "Set register content"
                },
                {
                  name = "vim_visual",
                  description = "Make visual selections"
                },
                {
                  name = "analyze_related",
                  description = "Analyze files related through imports/requires"
                },
                {
                  name = "find_symbols",
                  description = "Search workspace symbols using LSP"
                },
                {
                  name = "search_files",
                  description = "Find files by pattern with optional content preview"
                }
              },
              resources = {
                "neovim://current-buffer",
                "neovim://buffers",
                "neovim://project",
                "neovim://git-status",
                "neovim://lsp-diagnostics",
                "neovim://options",
                "neovim://related-files",
                "neovim://recent-files",
                "neovim://workspace-context",
                "neovim://search-results"
              }
            }
          })
          local resp = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: " .. #body .. "\r\n\r\n" .. body
          client:write(resp)
        elseif req:find("POST /mcp/session") then
          local body = vim.json.encode({ session_id = "nvim-session-" .. tostring(math.random(100000,999999)), status = "ok" })
          local resp = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: " .. #body .. "\r\n\r\n" .. body
          client:write(resp)
        elseif req:find("DELETE /mcp/session") then
          local body = vim.json.encode({ status = "closed" })
          local resp = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: " .. #body .. "\r\n\r\n" .. body
          client:write(resp)
        else
          local resp = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n"
          client:write(resp)
        end
        client:shutdown()
        client:close()
      end
    end)
  end)
  vim.notify("Claude Code MCP HTTP server started on http://" .. host .. ":" .. port, vim.log.levels.INFO)
end

return M
