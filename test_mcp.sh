#!/bin/bash

# Test script for Claude Code MCP server

SERVER="./bin/claude-code-mcp-server"

echo "Testing Claude Code MCP Server"
echo "==============================="

# Test 1: Initialize
echo "1. Testing initialization..."
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | $SERVER 2>/dev/null | head -1

echo ""

# Test 2: List tools
echo "2. Testing tools list..."
(
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}'
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
) | $SERVER 2>/dev/null | tail -1 | jq '.result.tools[] | .name' 2>/dev/null || echo "jq not available - raw output needed"

echo ""

# Test 3: List resources
echo "3. Testing resources list..."
(
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}'
echo '{"jsonrpc":"2.0","id":3,"method":"resources/list","params":{}}'
) | $SERVER 2>/dev/null | tail -1

echo ""
echo "MCP Server test completed"