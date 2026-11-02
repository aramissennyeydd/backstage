#!/usr/bin/env bash
# Act 2 of the herdr demo, main pane: title card, then the Claude Code session with team skills and the
# Backstage MCP server. Same prompt as Act 1. Needs the servers from setup.sh.
set -uo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
. "$DEMO/card.sh"
. "$DEMO/env.sh"

card "ACT 2 of 2: Skills + Backstage MCP" "The same prompt, now with team context from Backstage" \
  "What you see: the same payments repo, with the team skills still missing." \
  "Left panes:   'skills status' (top) and 'MCP calls' (bottom) update live." \
  "" \
  "Step 1  Press Enter in this pane: skills install from Backstage and the" \
  "        'skills status' pane flips from missing to installed." \
  "Step 2  Paste the prompt. Watch 'MCP calls' as the agent looks up the" \
  "        gateway API, its runbook and the owning team." \
  "Watch for: gateway-specific batching, error handling and tests that match the" \
  "           team conventions, compared with Act 1."
header "Act 2: team skills + Backstage MCP"
if ! { backstage-cli auth show --instance ai-demo >/dev/null 2>&1 || backstage-cli auth login --backend-url "$BACKEND_URL" --instance ai-demo; }; then
  echo "Backstage login failed. Run: bash $DEMO/setup.sh" >&2
  exit 1
fi
bash "$DEMO/claude-with-skills.sh"
