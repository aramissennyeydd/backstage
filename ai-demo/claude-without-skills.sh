#!/usr/bin/env bash
# Manual demo: interactive Claude Code in the baseline repo, which never gets team skills.
# Needs no backend or login.
set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"

reset_repo "$DEMO/baseline-repo"
echo "Baseline repo reset: no skills, no hooks."
print_prompt
cd "$DEMO/baseline-repo"
exec "${CLAUDE[@]}"
