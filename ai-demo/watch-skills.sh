#!/usr/bin/env bash
# Refreshes `ai skills status` for a demo repo every 2 seconds, so the skills can be seen going from
# missing to installed when the "with skills" Claude session starts. Usage: watch-skills.sh <repo-dir>
set -uo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
. "$DEMO/lib.sh"

cd "${1:?usage: watch-skills.sh <repo-dir>}"
while true; do
  out=$(FORCE_COLOR=1 ai skills status --agent claude-code "${FLAGS[@]}" 2>&1)
  clear
  echo "ai skills status ($(basename "$PWD"), refreshed $(date +%H:%M:%S))"
  echo
  echo "$out"
  sleep 2
done
