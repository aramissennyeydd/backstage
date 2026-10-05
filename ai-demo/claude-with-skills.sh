#!/usr/bin/env bash
# Manual demo: interactive Claude Code in the payments repo. The SessionStart hook installs the team
# skills at startup. Needs the demo backend on :7107 and a prior `auth login --instance ai-demo`.
set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

reset_repo "$DEMO/repo"
cd "$DEMO/repo"
if ! ai hooks install --agent claude-code "${FLAGS[@]}"; then
  echo "ai hooks install failed. Make sure the demo backend is running on $BACKEND_URL and log in first:" >&2
  echo "  source $DEMO/env.sh && backstage-cli auth login --backend-url $BACKEND_URL --instance ai-demo" >&2
  exit 1
fi
echo
echo "Skills that apply to this repo:"
ai resolve --agent claude-code "${FLAGS[@]}" || echo "ai resolve failed, continuing." >&2
print_prompt
exec "${CLAUDE[@]}"
