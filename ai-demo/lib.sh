#!/usr/bin/env bash
# Shared by run-comparison.sh, claude-with-skills.sh and claude-without-skills.sh. Source it, don't run it.
DEMO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DEMO/env.sh"
FLAGS=(--allow-file-sources --instance ai-demo)
# Only project settings (incl. .claude/settings.local.json with the hook) and no MCP servers, so the
# repos differ only by the installed skills. No --mcp-config is passed, so nothing is loaded.
CLAUDE=(claude --setting-sources project,local --strict-mcp-config)
PROMPT="Add a function in src/refunds.ts that issues a refund for a payment through our Payments Gateway, and add tests for it in src/refunds.test.ts. Follow this project's conventions."

reset_repo() { # dir: back to the committed starting point, no skills/hooks
  git -C "$1" reset -q --hard HEAD; git -C "$1" clean -qfdx -e node_modules
  rm -rf "$1/.claude" "$1/.agents" "$1/.codex" "$1/skills-lock.json"
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
