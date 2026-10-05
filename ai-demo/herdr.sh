#!/usr/bin/env bash
# Opens an "ai-demo" herdr tab: backend log (top left), frontend log (bottom left), and two stacked
# Claude Code panes on the right: "with skills" (top) and "without skills" (bottom).
# Does not start or stop servers: run `bash ai-demo/setup.sh` first. Requires jq, curl and herdr.
set -euo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
. "$DEMO/lib.sh"

if ! backend_ready || ! frontend_ready; then
  echo "The demo servers are not running. Run \`bash ai-demo/setup.sh\` first." >&2
  exit 1
fi

tab=$(herdr tab create --label ai-demo --cwd "$DEMO" --focus)
be=$(jq -r '.result.root_pane.pane_id' <<<"$tab")
ws=$(herdr pane split --pane "$be" --direction right --cwd "$DEMO/repo" --no-focus | jq -r '.result.pane.pane_id')
wo=$(herdr pane split --pane "$ws" --direction down --cwd "$DEMO/baseline-repo" --no-focus | jq -r '.result.pane.pane_id')
fe=$(herdr pane split --pane "$be" --direction down --cwd "$DEMO" --no-focus | jq -r '.result.pane.pane_id')

herdr pane rename "$ws" "with skills"
herdr pane rename "$wo" "without skills"

herdr pane run "$be" "tail -n 100 -f $DEMO/logs/backend.log"
herdr pane run "$fe" "tail -n 100 -f $DEMO/logs/frontend.log"
# With skills: setup.sh already logged in; keep the guard as a fallback if the session is gone.
herdr pane run "$ws" "source $DEMO/env.sh && { backstage-cli auth show --instance ai-demo >/dev/null 2>&1 || backstage-cli auth login --backend-url http://localhost:7107 --instance ai-demo; } && bash $DEMO/claude-with-skills.sh"
herdr pane run "$wo" "bash $DEMO/claude-without-skills.sh"
