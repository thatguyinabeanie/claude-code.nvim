local uv = vim.loop or vim.uv

local M = {}

-- Safe notification function for headless mode
local function safe_notify(msg, level)
    level = level or vim.log.levels.INFO
    -- Always use stderr in server context to avoid UI issues
    io.stderr:write("[MCP] " .. msg .. "\n")
    io.stderr:flush()
end

-- MCP Server state
local server = {
    name = "claude-code-nvim",
    version = "1.0.0",
    initialized = false,
    tools = {},
    resources = {},
    request_id = 0
}

-- Generate unique request ID
local function next_id()
    server.request_id = server.request_id + 1
    return server.request_id
end

-- JSON-RPC message parser
local function parse_message(data)
    local ok, message = pcall(vim.json.decode, data)
    if not ok then
        return nil, "Invalid JSON"
    end
    
    if message.jsonrpc ~= "2.0" then
        return nil, "Invalid JSON-RPC version"
    end
    
    return message, nil
end

-- Create JSON-RPC response
local function create_response(id, result, error_obj)
    local response = {
        jsonrpc = "2.0",
        id = id
    }
    
    if error_obj then
        response.error = error_obj
    else
        response.result = result
    end
    
    return response
end

-- Create JSON-RPC error
local function create_error(code, message, data)
    return {
        code = code,
        message = message,
        data = data
    }
end

-- Handle MCP initialize method
local function handle_initialize(params)
    server.initialized = true
    
    return {
        protocolVersion = "2024-11-05",
        capabilities = {
            tools = {},
            resources = {}
        },
        serverInfo = {
            name = server.name,
            version = server.version
        }
    }
end

-- Handle tools/list method
local function handle_tools_list()
    local tools = {}
    
    for name, tool in pairs(server.tools) do
        table.insert(tools, {
            name = name,
            description = tool.description,
            inputSchema = tool.inputSchema
        })
    end
    
    return { tools = tools }
end

-- Handle tools/call method
local function handle_tools_call(params)
    local tool_name = params.name
    local arguments = params.arguments or {}
    
    local tool = server.tools[tool_name]
    if not tool then
        return nil, create_error(-32601, "Tool not found: " .. tool_name)
    end
    
    local ok, result = pcall(tool.handler, arguments)
    if not ok then
        return nil, create_error(-32603, "Tool execution failed", result)
    end
    
    return {
        content = {
            { type = "text", text = result }
        }
    }
end

-- Handle resources/list method
local function handle_resources_list()
    local resources = {}
    
    for name, resource in pairs(server.resources) do
        table.insert(resources, {
            uri = resource.uri,
            name = name,
            description = resource.description,
            mimeType = resource.mimeType
        })
    end
    
    return { resources = resources }
end

-- Handle resources/read method
local function handle_resources_read(params)
    local uri = params.uri
    
    -- Find resource by URI
    local resource = nil
    for _, res in pairs(server.resources) do
        if res.uri == uri then
            resource = res
            break
        end
    end
    
    if not resource then
        return nil, create_error(-32601, "Resource not found: " .. uri)
    end
    
    local ok, content = pcall(resource.handler)
    if not ok then
        return nil, create_error(-32603, "Resource read failed", content)
    end
    
    return {
        contents = {
            {
                uri = uri,
                mimeType = resource.mimeType,
                text = content
            }
        }
    }
end

-- Main message handler
local function handle_message(message)
    if not message.method then
        return create_response(message.id, nil, create_error(-32600, "Invalid Request"))
    end
    
    local result, error_obj
    
    if message.method == "initialize" then
        result, error_obj = handle_initialize(message.params)
    elseif message.method == "tools/list" then
        if not server.initialized then
            error_obj = create_error(-32002, "Server not initialized")
        else
            result, error_obj = handle_tools_list()
        end
    elseif message.method == "tools/call" then
        if not server.initialized then
            error_obj = create_error(-32002, "Server not initialized")
        else
            result, error_obj = handle_tools_call(message.params)
        end
    elseif message.method == "resources/list" then
        if not server.initialized then
            error_obj = create_error(-32002, "Server not initialized")
        else
            result, error_obj = handle_resources_list()
        end
    elseif message.method == "resources/read" then
        if not server.initialized then
            error_obj = create_error(-32002, "Server not initialized")
        else
            result, error_obj = handle_resources_read(message.params)
        end
    else
        error_obj = create_error(-32601, "Method not found: " .. message.method)
    end
    
    return create_response(message.id, result, error_obj)
end

-- Register a tool
function M.register_tool(name, description, inputSchema, handler)
    server.tools[name] = {
        description = description,
        inputSchema = inputSchema,
        handler = handler
    }
end

-- Register a resource
function M.register_resource(name, uri, description, mimeType, handler)
    server.resources[name] = {
        uri = uri,
        description = description,
        mimeType = mimeType,
        handler = handler
    }
end

-- Start the MCP server
function M.start()
    local stdin = uv.new_pipe(false)
    local stdout = uv.new_pipe(false)
    
    if not stdin or not stdout then
        safe_notify("Failed to create pipes for MCP server", vim.log.levels.ERROR)
        return false
    end
    
    -- Open stdin and stdout
    stdin:open(0)  -- stdin file descriptor
    stdout:open(1) -- stdout file descriptor
    
    local buffer = ""
    
    -- Read from stdin
    stdin:read_start(function(err, data)
        if err then
            safe_notify("MCP server stdin error: " .. err, vim.log.levels.ERROR)
            stdin:close()
            stdout:close()
            vim.cmd('quit')
            return
        end
        
        if not data then
            -- EOF received - client disconnected
            stdin:close()
            stdout:close()
            vim.cmd('quit')
            return
        end
        
        buffer = buffer .. data
        
        -- Process complete lines
        while true do
            local newline_pos = buffer:find("\n")
            if not newline_pos then
                break
            end
            
            local line = buffer:sub(1, newline_pos - 1)
            buffer = buffer:sub(newline_pos + 1)
            
            if line ~= "" then
                local message, parse_err = parse_message(line)
                if message then
                    local response = handle_message(message)
                    local json_response = vim.json.encode(response)
                    stdout:write(json_response .. "\n")
                else
                    safe_notify("MCP parse error: " .. (parse_err or "unknown"), vim.log.levels.WARN)
                end
            end
        end
    end)
    
    return true
end

-- Stop the MCP server
function M.stop()
    server.initialized = false
end

-- Get server info
function M.get_server_info()
    return {
        name = server.name,
        version = server.version,
        initialized = server.initialized,
        tool_count = vim.tbl_count(server.tools),
        resource_count = vim.tbl_count(server.resources)
    }
end

return M