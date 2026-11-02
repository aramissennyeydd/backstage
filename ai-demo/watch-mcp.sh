#!/usr/bin/env bash
# Live view of the Backstage MCP calls the "with skills" agent makes: tails the backend log and shows
# only /api/mcp-actions requests and tool invocations. Usage: watch-mcp.sh
set -uo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
LOG="$DEMO/logs/backend.log"
echo "Backstage MCP calls (from $LOG)"
echo
tail -n 0 -F "$LOG" | grep --line-buffered -iE 'mcp-actions|mcp.*(tools/call|tool)|actions.*invoke' \
  | sed -E 's/\x1b\[[0-9;]*m//g'
