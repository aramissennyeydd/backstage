#!/usr/bin/env bash
# Stops the demo backend and frontend started by setup.sh: PID files first, then whatever still
# listens on the demo ports. Keeps db/ and the CLI login state.
set -euo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
. "$DEMO/lib.sh"

for name in backend frontend; do
  pidfile="$DEMO/logs/$name.pid"
  [ -f "$pidfile" ] || continue
  pid=$(cat "$pidfile")
  if kill -0 "$pid" 2>/dev/null; then
    echo "Stopping $name (pid $pid)"
    pkill -P "$pid" 2>/dev/null || true
    kill "$pid" 2>/dev/null || true
  fi
  rm -f "$pidfile"
done

free_port "$BACKEND_PORT"
free_port "$FRONTEND_PORT"
echo "Demo servers stopped."
