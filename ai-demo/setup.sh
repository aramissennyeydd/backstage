#!/usr/bin/env bash
# Generates the gitignored working copies for the demo from the committed templates, then starts the
# backend (:7107) and frontend (:3100) detached and does the one-time CLI login.
# Safe to re-run: it recreates the demo repos, team-skills and generated configs from scratch and
# restarts the servers. It never deletes db/ or the CLI login state (xdg-config, xdg-data).
# Usage: setup.sh [--no-servers]   (--no-servers only generates files)
set -euo pipefail

START_SERVERS=1
case "${1:-}" in
  "") ;;
  --no-servers) START_SERVERS=0 ;;
  *) echo "Usage: $0 [--no-servers]" >&2; exit 2 ;;
esac

DEMO="$(cd "$(dirname "$0")" && pwd)"
WT="$(cd "$DEMO/.." && pwd)"
TEMPLATES="$DEMO/templates"

git_demo() { # git with a fixed identity so setup works without a global git config
  git -c user.name="Demo" -c user.email="demo@example.com" -c commit.gpgsign=false "$@"
}

make_repo() { # name origin message
  local name=$1 origin=$2 message=$3 dir="$DEMO/$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  cp -R "$TEMPLATES/$name/." "$dir/"
  git -C "$dir" init -q -b main
  if [ -n "$origin" ]; then
    git -C "$dir" remote add origin "$origin"
  fi
  git -C "$dir" add -A
  git_demo -C "$dir" commit -q -m "$message"
  if [ -n "$origin" ]; then
    mkdir -p "$dir/node_modules/@backstage"
    ln -s "$WT/packages/cli-module-ai" "$dir/node_modules/@backstage/cli-module-ai"
    ln -s "$WT/packages/cli-module-auth" "$dir/node_modules/@backstage/cli-module-auth"
  fi
}

make_repo repo https://github.com/acme-demo/payments-service.git "starting point"
make_repo growth-repo https://github.com/acme-demo/growth-service.git "starting point"
make_repo baseline-repo https://github.com/acme-demo/payments-service.git "starting point"
make_repo team-skills "" "Demo team skills"

for name in catalog-demo app-config.demo; do
  sed "s|@@DEMO@@|$DEMO|g" "$DEMO/backend-config/$name.template.yaml" > "$DEMO/backend-config/$name.yaml"
done

echo "Demo files generated in $DEMO"

if [ "$START_SERVERS" = 0 ]; then
  echo "Skipped servers (--no-servers). Rerun without the flag to start them and log in."
  exit 0
fi

. "$DEMO/lib.sh"
LOGS="$DEMO/logs"
mkdir -p "$LOGS"

free_port "$BACKEND_PORT"
free_port "$FRONTEND_PORT"

CFG="--config ../../app-config.yaml --config $DEMO/backend-config/app-config.demo.yaml"

# env -u keeps the CLI login dirs from env.sh (sourced by lib.sh) out of the dev servers.
start_server() { # name dir envprefix...
  local name=$1 dir=$2
  shift 2
  (
    cd "$dir"
    # shellcheck disable=SC2086
    nohup env -u XDG_CONFIG_HOME -u XDG_DATA_HOME "$@" yarn start $CFG \
      >"$LOGS/$name.log" 2>&1 </dev/null &
    echo $! >"$LOGS/$name.pid"
  )
}
start_server backend "$WT/packages/backend"
start_server frontend "$WT/packages/app" BROWSER=none
echo "Started backend (pid $(cat "$LOGS/backend.pid")) and frontend (pid $(cat "$LOGS/frontend.pid")), logs in $LOGS"

echo "Waiting for the servers (up to 5 minutes)..."
deadline=$((SECONDS + 300))
until backend_ready && frontend_ready; do
  if [ "$SECONDS" -ge "$deadline" ]; then
    echo "Timed out waiting for the servers." >&2
    for name in backend frontend; do
      echo "--- tail of $name.log" >&2
      tail -n 30 "$LOGS/$name.log" >&2
    done
    exit 1
  fi
  sleep 2
done
echo "Backend and frontend are ready."

# shellcheck disable=SC1091
. "$DEMO/env.sh"
if backstage-cli auth show --instance ai-demo >/dev/null 2>&1; then
  echo "Already logged in (instance ai-demo)."
else
  echo "Logging in: approve the consent page in the browser."
  backstage-cli auth login --backend-url "$BACKEND_URL" --instance ai-demo
fi

cat <<EOT

Demo is ready. Backend :$BACKEND_PORT, frontend :$FRONTEND_PORT (logs in $LOGS).
Next:
  bash ai-demo/herdr.sh                  # herdr tab with logs, "with skills" and "without skills" panes
  bash ai-demo/claude-with-skills.sh     # or run the panes by hand, plus claude-without-skills.sh
  bash ai-demo/stop.sh                   # stop the servers when done
EOT
