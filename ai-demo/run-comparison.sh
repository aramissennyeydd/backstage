#!/usr/bin/env bash
# Replays the catalog-scoped skills comparison. Requires: `backstage-cli auth login --instance ai-demo`
# done once (see env.sh), backend on :7107 loaded with backend-config/catalog-demo.yaml.
set -uo pipefail
DEMO="$(cd "$(dirname "$0")" && pwd)"
. "$DEMO/env.sh"
OUT="$DEMO/results"; rm -rf "$OUT"; mkdir -p "$OUT"
FLAGS=(--allow-file-sources --instance ai-demo)
PROMPT="Add a function in src/refunds.ts that issues a refund for a payment through our Payments Gateway, and add tests for it in src/refunds.test.ts. Follow this project's conventions."

reset_repo() { # dir: back to the committed starting point, no skills/hooks
  git -C "$1" reset -q --hard HEAD; git -C "$1" clean -qfdx -e node_modules
  rm -rf "$1/.claude" "$1/.agents" "$1/.codex" "$1/skills-lock.json"
}
run_repo() { # name dir with_skills
  local name=$1 dir=$2 skills=$3
  reset_repo "$dir"; cd "$dir"
  if [ "$skills" = yes ]; then
    ai resolve "${FLAGS[@]}" | tee "$OUT/$name.resolve.txt"
    ai resolve "${FLAGS[@]}" --output json > "$OUT/$name.resolve.json"
    ai hooks install --agent claude-code "${FLAGS[@]}" | tee "$OUT/$name.hooks.txt"
    # Headless start: the SessionStart hook installs the skills.
    claude -p "Reply with OK." --max-turns 1 > "$OUT/$name.start.txt" 2>&1
    find .claude/skills -name SKILL.md 2>/dev/null | sort > "$OUT/$name.skills.txt"
  fi
  claude -p "$PROMPT" --permission-mode acceptEdits \
    --allowedTools "Read,Write,Edit,Glob,Grep" --max-turns 15 > "$OUT/$name.claude.txt" 2>&1
  git add -A -- src; git diff --cached > "$OUT/$name.diff"
  cp -R src "$OUT/$name.src"
}
run_repo payments "$DEMO/repo" yes
run_repo growth "$DEMO/growth-repo" yes
run_repo baseline "$DEMO/baseline-repo" no
echo "Results in $OUT"
