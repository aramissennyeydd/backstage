#!/usr/bin/env bash
# Replays the catalog-scoped skills comparison. Requires: `backstage-cli auth login --instance ai-demo`
# done once (see env.sh), backend on :7107 loaded with backend-config/catalog-demo.yaml.
set -uo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"
OUT="$DEMO/results"; rm -rf "$OUT"; mkdir -p "$OUT"

run_repo() { # name dir with_skills
  local name=$1 dir=$2 skills=$3
  reset_repo "$dir"; cd "$dir"
  if [ "$skills" = yes ]; then
    # stderr goes into the result files too, and a failed resolve stops the script.
    ai resolve --agent claude-code "${FLAGS[@]}" 2>&1 | tee "$OUT/$name.resolve.txt"
    [ "${PIPESTATUS[0]}" -eq 0 ] || { echo "ai resolve failed for $name, see $OUT/$name.resolve.txt" >&2; exit 1; }
    ai resolve --agent claude-code "${FLAGS[@]}" --output json > "$OUT/$name.resolve.json" 2>&1 \
      || { echo "ai resolve --output json failed for $name, see $OUT/$name.resolve.json" >&2; exit 1; }
    ai hooks install --agent claude-code "${FLAGS[@]}" | tee "$OUT/$name.hooks.txt"
    # Headless start: the SessionStart hook installs the skills.
    "${CLAUDE[@]}" -p "Reply with OK." --max-turns 1 > "$OUT/$name.start.txt" 2>&1
    find .claude/skills -name SKILL.md 2>/dev/null | sort > "$OUT/$name.skills.txt"
  fi
  if [ "$name" = payments ]; then
    # Payments also gets the Backstage MCP server (CLI login token). stream-json keeps the tool calls
    # so they can be listed in results/payments.mcp.txt.
    mcp_flags || exit 1
    "${CLAUDE[@]}" "${MCP_ARGS[@]}" -p "$PROMPT" --permission-mode acceptEdits \
      --allowedTools "Read,Write,Edit,Glob,Grep" --max-turns 25 \
      --output-format stream-json --verbose > "$OUT/$name.stream.jsonl" 2>&1
    jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and (.name|startswith("mcp__"))) | "\(.name) \(.input|tostring)"' \
      "$OUT/$name.stream.jsonl" > "$OUT/$name.mcp.txt" 2>/dev/null
    jq -r 'select(.type=="result") | .result' "$OUT/$name.stream.jsonl" > "$OUT/$name.claude.txt" 2>/dev/null
  else
    "${CLAUDE[@]}" -p "$PROMPT" --permission-mode acceptEdits \
      --allowedTools "Read,Write,Edit,Glob,Grep" --max-turns 15 > "$OUT/$name.claude.txt" 2>&1
  fi
  git add -A -- src; git diff --cached > "$OUT/$name.diff"
  cp -R src "$OUT/$name.src"
}
run_repo payments "$DEMO/repo" yes
run_repo growth "$DEMO/growth-repo" yes
run_repo baseline "$DEMO/baseline-repo" no
echo "Results in $OUT"
