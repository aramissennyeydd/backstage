#!/usr/bin/env bash
# Act 1 of the herdr demo: title card, then the baseline Claude Code session (no skills, no Backstage).
set -uo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
. "$DEMO/card.sh"

card "ACT 1 of 2: The baseline" "Claude Code with no team skills and no Backstage" \
  "What you see: one Claude Code session in the payments repo, with nothing installed." \
  "What to do:  paste the prompt it prints, let it write the refund function and tests." \
  "Watch for:   it guesses at the gateway API, error handling and test style." \
  "             Keep this result in mind: Act 2 runs the same prompt." \
  "" \
  "Nothing here talks to Backstage."
header "Act 1: baseline (no skills, no Backstage MCP)"
bash "$DEMO/claude-without-skills.sh"
echo
echo "Act 1 done. Next, run: bash $DEMO/herdr.sh 2"
