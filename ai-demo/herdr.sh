#!/usr/bin/env bash
# Opens an "ai-demo" herdr tab with three panes: backend, frontend, and a demo shell.
# Run from inside a herdr session after `bash setup.sh`. Requires jq.
set -euo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
WT="$(dirname "$DEMO")"
CFG="--config ../../app-config.yaml --config $DEMO/backend-config/app-config.demo.yaml"

tab=$(herdr tab create --label ai-demo --cwd "$WT/packages/backend" --focus)
be=$(jq -r '.result.root_pane.pane_id' <<<"$tab")
fe=$(herdr pane split --pane "$be" --direction right --cwd "$WT/packages/app" --no-focus | jq -r '.result.pane.pane_id')
sh=$(herdr pane split --pane "$be" --direction down --cwd "$DEMO/repo" | jq -r '.result.pane.pane_id')

herdr pane run "$be" "yarn start $CFG"
herdr pane run "$fe" "yarn start $CFG"
herdr pane run "$sh" "until curl -sf localhost:7107/.backstage/health/v1/readiness >/dev/null && curl -sf localhost:3100 >/dev/null; do sleep 2; done; source $DEMO/env.sh && backstage-cli auth login --backend-url http://localhost:7107 --instance ai-demo"
