#!/usr/bin/env bash
# Live view of the Backstage MCP calls the "with skills" agent makes: tails the backend log and shows
# only /api/mcp-actions requests and tool invocations. Usage: watch-mcp.sh
set -uo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
LOG="$DEMO/logs/backend.log"
echo "Backstage MCP calls (from $LOG)"
echo
# The backend writes one audit line per tool call: mcp-actions.tool-execution with meta={"toolName":...}.
tail -n 0 -F "$LOG" | grep --line-buffered 'mcp-actions.tool-execution' \
  | perl -ne 'BEGIN { $| = 1 } s/\e\[[0-9;]*m//g; print "$1  $3  $2\n" if /(\d\d:\d\d:\d\d)\.\d+Z.*?toolName":"([^"]+).*?status="(\w+)"/'
