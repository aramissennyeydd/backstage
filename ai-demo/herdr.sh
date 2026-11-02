#!/usr/bin/env bash
# Opens the demo in herdr, one act per tab so each version is shown on its own:
#   bash ai-demo/herdr.sh 1   Act 1: baseline Claude Code, no skills, no Backstage (the default)
#   bash ai-demo/herdr.sh 2   Act 2: team skills + Backstage MCP, with live skills status and MCP calls panes
#   bash ai-demo/herdr.sh all open both tabs (Act 1 focused)
# Each act starts with a title card in its main pane that waits for Enter. Every pane has a name and a header.
# Does not start or stop servers: run `bash ai-demo/setup.sh` first for Act 2. Requires jq, curl and herdr.
set -euo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
. "$DEMO/lib.sh"

act=${1:-1}
case "$act" in 1 | 2 | all) ;; *)
  echo "usage: herdr.sh [1|2|all]" >&2
  exit 2
  ;;
esac

if [ "$act" != 1 ] && { ! backend_ready || ! frontend_ready; }; then
  echo "The demo servers are not running. Run \`bash ai-demo/setup.sh\` first." >&2
  exit 1
fi

act1() {
  local tab pane
  tab=$(herdr tab create --label "act 1: baseline" --cwd "$DEMO/baseline-repo" --focus)
  pane=$(jq -r '.result.root_pane.pane_id' <<<"$tab")
  herdr pane rename "$pane" "Act 1: no skills, no Backstage" >/dev/null
  herdr pane run "$pane" "bash $DEMO/act1-baseline.sh" >/dev/null
}

act2() {
  local focus=$1 tab claude status mcp
  tab=$(herdr tab create --label "act 2: skills + MCP" --cwd "$DEMO" "$focus")
  status=$(jq -r '.result.root_pane.pane_id' <<<"$tab")
  claude=$(herdr pane split --pane "$status" --direction right --cwd "$DEMO/repo" --no-focus | jq -r '.result.pane.pane_id')
  mcp=$(herdr pane split --pane "$status" --direction down --cwd "$DEMO/repo" --no-focus | jq -r '.result.pane.pane_id')
  herdr pane rename "$status" "skills status (live)" >/dev/null
  herdr pane rename "$mcp" "Backstage MCP calls (live)" >/dev/null
  herdr pane rename "$claude" "Act 2: skills + Backstage MCP" >/dev/null
  herdr pane run "$status" "bash $DEMO/watch-skills.sh $DEMO/repo" >/dev/null
  herdr pane run "$mcp" "bash $DEMO/watch-mcp.sh" >/dev/null
  herdr pane run "$claude" "bash $DEMO/act2-skills.sh" >/dev/null
}

case "$act" in
  1) act1 ;;
  2) act2 --focus ;;
  all) act2 --no-focus; act1 ;;
esac
