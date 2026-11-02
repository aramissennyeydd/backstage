#!/usr/bin/env bash
# Act 1 of the herdr demo: title card, then the baseline Claude Code session (no skills, no Backstage).
set -uo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
. "$DEMO/card.sh"
. "$DEMO/lib.sh"

card "ACT 1 of 2: The baseline" "Claude Code with no team skills and no Backstage" \
  "What you see: one Claude Code session in the payments repo, with nothing installed." \
  "What to do:  copy the prompt below, press Enter, paste it into Claude Code." \
  "Watch for:   it guesses at the gateway API, error handling and test style." \
  "             Keep this result in mind: Act 2 runs the same prompt." \
  "" \
  "Nothing here talks to Backstage." \
  "" \
  "Prompt:" \
  "$PROMPT"
header "Act 1: baseline (no skills, no Backstage MCP)"
# Hold the screen: the act ends only when the presenter says so. If Claude exits within seconds
# (crash, bad stdin, accidental Ctrl-C), say so and offer a restart instead of moving on.
while true; do
  started=$SECONDS
  bash "$DEMO/claude-without-skills.sh"
  status=$?
  if [ $((SECONDS - started)) -lt 10 ]; then
    printf '\n%sClaude exited after %ss (status %s), which looks unintended.%s\n' "$C_BOLD" "$((SECONDS - started))" "$status" "$C_RESET"
    read -r -p "Press Enter to restart Act 1's Claude session, or Ctrl-C to stop... " || exit "$status"
    continue
  fi
  break
done

CARD_PROMPT="Press Enter to open Act 2, Ctrl-C to stay here... " card "ACT 1 done: the baseline" "No skills, no Backstage: it works from guesses" \
  "Look at what Claude produced, or asked about, before moving on." \
  "Everything it knew about the gateway, error handling and test style came" \
  "from the prompt and the repo alone." \
  "" \
  "Next: Act 2 runs the same prompt with team skills and the Backstage MCP server." \
  "Act 2 needs bash ai-demo/setup.sh to have run."
bash "$DEMO/herdr.sh" 2
