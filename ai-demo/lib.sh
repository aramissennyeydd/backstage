#!/usr/bin/env bash
# Shared by run-comparison.sh, claude-with-skills.sh and claude-without-skills.sh. Source it, don't run it.
DEMO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DEMO/env.sh"
FLAGS=(--allow-file-sources --instance ai-demo)
# Only project settings (incl. .claude/settings.local.json with the hook) and only the MCP servers
# passed with --mcp-config (--strict-mcp-config). Without mcp_flags nothing is loaded, so the repos
# differ only by the installed skills and, for the payments run, the Backstage MCP server.
CLAUDE=(claude --setting-sources project,local --strict-mcp-config)
# DEMO_MODEL=haiku (or any `claude --model` value) runs every demo session on that model.
if [ -n "${DEMO_MODEL:-}" ]; then
  CLAUDE+=(--model "$DEMO_MODEL")
fi
PROMPT="Add a function in src/refunds.ts that refunds a batch of payments through our Payments Gateway (after an outage, support sometimes needs to refund a few thousand at once), and add tests for it in src/refunds.test.ts. Follow this project's conventions."

reset_repo() { # dir: back to the committed starting point, no skills/hooks
  git -C "$1" reset -q --hard HEAD; git -C "$1" clean -qfdx -e node_modules
  rm -rf "$1/.claude" "$1/.agents" "$1/.codex" "$1/skills-lock.json"
}

MCP_URL="http://localhost:7107/api/mcp-actions/v1/backstage"

# Exports BACKSTAGE_TOKEN (the CLI login token, short-lived, never written to disk; mcp.json expands
# it) and sets MCP_ARGS to the claude flags that load the Backstage MCP server. Call it directly, not
# in $(...), so the export and the array survive.
MCP_ARGS=()
mcp_flags() {
  local token
  if ! token="$(backstage-cli auth print-token --instance ai-demo 2>/dev/null)" || [ -z "$token" ]; then
    echo "Could not get a token. Log in first: backstage-cli auth login --backend-url $BACKEND_URL --instance ai-demo" >&2
    return 1
  fi
  export BACKSTAGE_TOKEN="$token"
  MCP_ARGS=(--mcp-config "$DEMO/mcp.json" --allowedTools "mcp__backstage__*")
}

# Prints "Backstage MCP: N tools" (MCP tools/list over HTTP) so a broken server shows before the demo.
mcp_tool_count() {
  local n
  n=$(curl -sf -X POST "$MCP_URL" -H "Authorization: Bearer $BACKSTAGE_TOKEN" \
    -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | sed 's/^data: //' | grep '^{' | jq '.result.tools | length') || n=""
  [ -n "$n" ] || { echo "Backstage MCP: not reachable at $MCP_URL" >&2; return 1; }
  echo "Backstage MCP: $n tools"
}

print_prompt() {
  printf '\nPaste this prompt into Claude Code:\n\n%s\n\n' "$PROMPT"
}

# Demo servers (used by setup.sh, stop.sh and herdr.sh)
BACKEND_PORT=7107
FRONTEND_PORT=3100
BACKEND_READY_URL="http://localhost:$BACKEND_PORT/.backstage/health/v1/readiness"
FRONTEND_READY_URL="http://localhost:$FRONTEND_PORT"

listeners() {
  # `|| true` so an empty result does not trip `set -e`/pipefail
  lsof -ti "tcp:$1" -sTCP:LISTEN 2>/dev/null || true
}

free_port() {
  local port=$1 pids
  pids=$(listeners "$port")
  [ -z "$pids" ] && return 0
  echo "Stopping process(es) on port $port: $(echo $pids)"
  # shellcheck disable=SC2086
  kill $pids 2>/dev/null || true
  for _ in $(seq 20); do
    [ -z "$(listeners "$port")" ] && return 0
    sleep 0.5
  done
  pids=$(listeners "$port")
  if [ -n "$pids" ]; then
    echo "Port $port still busy, sending SIGKILL to: $(echo $pids)"
    # shellcheck disable=SC2086
    kill -9 $pids 2>/dev/null || true
    sleep 1
  fi
}

backend_ready() { curl -sf "$BACKEND_READY_URL" >/dev/null 2>&1; }
frontend_ready() { curl -sf "$FRONTEND_READY_URL" >/dev/null 2>&1; }
