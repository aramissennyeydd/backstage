#!/usr/bin/env bash
# Runs `ai resolve` for a demo repo and keeps the pane open so the output stays visible.
# Usage: show-resolve.sh <repo-dir>
set -uo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
. "$DEMO/lib.sh"

cd "${1:?usage: show-resolve.sh <repo-dir>}"
FORCE_COLOR=1 ai resolve --agent claude-code "${FLAGS[@]}"
status=$?
echo
echo "(ai resolve exited with status $status)"
# Keep the pane open with an interactive shell, like a normal herdr pane.
exec "${SHELL:-zsh}" -i
