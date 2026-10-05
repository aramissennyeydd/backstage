#!/usr/bin/env bash
# Opens an "ai-demo" herdr tab: backend (top left), frontend (bottom left) and a demo shell (right).
# Stops anything already listening on the demo ports (7107, 3100) first.
# Run from inside a herdr session after `bash setup.sh`. Requires jq and lsof.
set -euo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
WT="$(dirname "$DEMO")"
CFG="--config ../../app-config.yaml --config $DEMO/backend-config/app-config.demo.yaml"

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

free_port 7107
free_port 3100

tab=$(herdr tab create --label ai-demo --cwd "$WT/packages/backend" --focus)
be=$(jq -r '.result.root_pane.pane_id' <<<"$tab")
sh=$(herdr pane split --pane "$be" --direction right --cwd "$DEMO/repo" --no-focus | jq -r '.result.pane.pane_id')
fe=$(herdr pane split --pane "$be" --direction down --cwd "$WT/packages/app" --no-focus | jq -r '.result.pane.pane_id')

herdr pane run "$be" "yarn start $CFG"
herdr pane run "$fe" "yarn start $CFG"
herdr pane run "$sh" "until curl -sf localhost:7107/.backstage/health/v1/readiness >/dev/null && curl -sf localhost:3100 >/dev/null; do sleep 2; done; source $DEMO/env.sh && backstage-cli auth login --backend-url http://localhost:7107 --instance ai-demo"
