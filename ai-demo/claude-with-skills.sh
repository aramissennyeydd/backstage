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
# Claude Code registers skills by scanning .claude/skills at startup, before the SessionStart hook runs.
# Install them now so they load as real skills; the hook then finds them installed and skips them.
if ! ai skills sync --agent claude-code "${FLAGS[@]}"; then
  echo "ai skills sync failed. Check that the backend is running and you are logged in (see above)." >&2
  exit 1
fi
count=$(find .claude/skills -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
echo "Installed $count skills from Backstage; they load when Claude starts."
echo
echo "Skills that apply to this repo:"
ai resolve --agent claude-code "${FLAGS[@]}" || echo "ai resolve failed, continuing." >&2
print_prompt
exec "${CLAUDE[@]}"
