#!/usr/bin/env bash
# Shared by run-comparison.sh, claude-with-skills.sh and claude-without-skills.sh. Source it, don't run it.
DEMO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DEMO/env.sh"
FLAGS=(--allow-file-sources --instance ai-demo)
# Only project settings (incl. .claude/settings.local.json with the hook) and no MCP servers, so the
# repos differ only by the installed skills. No --mcp-config is passed, so nothing is loaded.
CLAUDE=(claude --setting-sources project,local --strict-mcp-config)
PROMPT="Add a function in src/refunds.ts that issues a refund for a payment through our Payments Gateway, and add tests for it in src/refunds.test.ts. Follow this project's conventions."

reset_repo() { # dir: back to the committed starting point, no skills/hooks
  git -C "$1" reset -q --hard HEAD; git -C "$1" clean -qfdx -e node_modules
  rm -rf "$1/.claude" "$1/.agents" "$1/.codex" "$1/skills-lock.json"
}

print_prompt() {
  printf '\nPaste this prompt into Claude Code:\n\n%s\n\n' "$PROMPT"
}
