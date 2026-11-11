---
name: Documentation Updater
description: Automatically reviews and updates documentation based on recent code changes
on:
  schedule: every 3h
  workflow_dispatch:
  push:
    branches: [gh-aw-test]
  permissions:
    pull-requests: read
  steps:
    - id: check
      env:
        GH_TOKEN: ${{ github.token }}
      run: |
        MAX_OPEN_PRS=8
        if [[ "$GITHUB_EVENT_NAME" != "schedule" ]]; then exit 0; fi
        COUNT=$(gh pr list --repo "$GITHUB_REPOSITORY" --state open --search 'in:title "[docs]"' --json number --jq 'length')
        [[ "$COUNT" -lt "$MAX_OPEN_PRS" ]]
      # exits 0 if not scheduled or <MAX_OPEN_PRS open PRs, 1 if ≥MAX_OPEN_PRS

if: needs.pre_activation.outputs.check_result == 'success'

# Deterministic triage before the agent starts. It lists every changeset,
# drops the ones that an open [docs] pull request already names in its body,
# ranks the rest, and writes the result to /tmp/gh-aw/agent/doc-gaps.md.
steps:
  - name: Triage changesets against open docs pull requests
    env:
      GH_TOKEN: ${{ github.token }}
    run: |
      set -euo pipefail
      OUT_DIR=/tmp/gh-aw/agent
      mkdir -p "$OUT_DIR"
      gh pr list --repo "$GITHUB_REPOSITORY" --state open --search 'in:title "[docs]"' \
        --limit 100 --json number,title,body,url --jq . > "$OUT_DIR/open-docs-prs.json"
      node - "$OUT_DIR" <<'EOF'
      const fs = require('fs');
      const path = require('path');
      const outDir = process.argv[2];
      const prs = JSON.parse(fs.readFileSync(path.join(outDir, 'open-docs-prs.json'), 'utf8'));

      // Concatenated docs text, used to hint whether a changeset's terms are already documented.
      const skipDirs = new Set(['releases', 'reference', 'references', 'node_modules']);
      let docsText = '';
      const walk = dir => {
        for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
          const p = path.join(dir, entry.name);
          if (entry.isDirectory()) {
            if (!skipDirs.has(entry.name)) walk(p);
          } else if (/\.mdx?$/.test(entry.name)) {
            docsText += fs.readFileSync(p, 'utf8') + '\n';
          }
        }
      };
      walk('docs');

      const escape = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const bumpScore = { major: 30, minor: 20, patch: 0 };
      const rows = [];
      for (const file of fs.readdirSync('.changeset').sort()) {
        if (!file.endsWith('.md') || file === 'README.md') continue;
        const raw = fs.readFileSync(path.join('.changeset', file), 'utf8');
        const m = raw.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
        if (!m) continue;
        const releases = [...m[1].matchAll(/^['"]?([^'":]+)['"]?\s*:\s*(major|minor|patch)\s*$/gm)]
          .map(r => ({ pkg: r[1].trim(), bump: r[2] }));
        const body = m[2].trim();
        const bump = releases.some(r => r.bump === 'major') ? 'major'
          : releases.some(r => r.bump === 'minor') ? 'minor' : 'patch';

        // Covered when an open [docs] PR names the changeset file in its body.
        const nameRe = new RegExp(`(^|[^A-Za-z0-9_-])${escape(file)}`, 'm');
        const coveredBy = prs.filter(pr => nameRe.test(pr.body || '')).map(pr => pr.number);

        let score = bumpScore[bump];
        if (/\*\*BREAKING\*\*|breaking/i.test(body)) score += 15;
        if (/deprecat/i.test(body)) score += 15;
        if (/config|option|app-config/i.test(body)) score += 10;
        if (/\b(added|adds|new|introduc|support)/i.test(body)) score += 5;
        if (/\b(extension|API|service|hook|endpoint)\b/.test(body)) score += 5;
        if (bump === 'patch' && /\b(internal|refactor|dependenc|bump|test|typo|fix(ed|es)?)\b/i.test(body)) score -= 10;

        const terms = [...new Set([...body.matchAll(/`([^`\n]{4,60})`/g)].map(t => t[1]))]
          .filter(t => !t.startsWith('@backstage/'));
        const termsInDocs = terms.filter(t => docsText.includes(t));
        if (terms.length > 0 && termsInDocs.length === terms.length) score -= 10;

        rows.push({
          file: `.changeset/${file}`,
          bump,
          packages: releases.map(r => r.pkg),
          score,
          coveredBy,
          termsInDocs: `${termsInDocs.length}/${terms.length}`,
          summary: body.split('\n').find(l => l.trim()) || '',
        });
      }

      const covered = rows.filter(r => r.coveredBy.length > 0);
      const gaps = rows.filter(r => r.coveredBy.length === 0).sort((a, b) => b.score - a.score || a.file.localeCompare(b.file));
      fs.writeFileSync(path.join(outDir, 'doc-gaps.json'), JSON.stringify({ covered, gaps }, null, 2));

      const cell = s => String(s).replace(/\|/g, '\\|').slice(0, 200);
      const lines = [
        '# Changeset triage',
        '',
        `Total changesets: ${rows.length}. Covered by open [docs] pull requests: ${covered.length}. Uncovered: ${gaps.length}.`,
        '',
        '## Covered by open [docs] pull requests (do not pick)',
        '',
        ...(covered.length ? covered.map(r => `- ${r.file}: #${r.coveredBy.join(', #')}`) : ['- none']),
        '',
        '## Uncovered changesets, ranked by score',
        '',
        '| Rank | Changeset | Bump | Score | Terms already in docs | Packages | Summary |',
        '| --- | --- | --- | --- | --- | --- | --- |',
        ...gaps.map((r, i) => `| ${i + 1} | ${r.file} | ${r.bump} | ${r.score} | ${r.termsInDocs} | ${cell(r.packages.join(', '))} | ${cell(r.summary)} |`),
        '',
      ];
      fs.writeFileSync(path.join(outDir, 'doc-gaps.md'), lines.join('\n'));
      console.log(`changesets=${rows.length} covered=${covered.length} uncovered=${gaps.length}`);
      console.log(gaps.slice(0, 10).map((r, i) => `${i + 1}. ${r.file} (${r.bump}, score ${r.score})`).join('\n'));
      EOF

network:
  allowed:
    - defaults
    - dotnet
    - node
    - python
    - rust
    - java

permissions:
  contents: read
  issues: read
  pull-requests: read

tools:
  github:
    toolsets: [default]
  edit:
  bash: true

engine:
  id: copilot
  env:
    COPILOT_GITHUB_TOKEN: ${{ secrets.GH_AW_TOKEN }}
    GH_AW_HARNESS_WATCHDOG_TIMEOUT_MS: '600000'

timeout-minutes: 60

safe-outputs:
  create-pull-request:
    max: 1
    expires: 2d
    title-prefix: '[docs] '
    labels: [documentation, automation]
    draft: true
    base-branch: gh-aw-test
    protected-files: blocked

source: githubnext/agentics/workflows/doc-updater.md@main
source-sha: '139fa09ef17cde4135e696ff8e7af09bc5ddfa6e'
---

# Documentation Updater

You are an AI documentation agent for the Backstage repository. Each run, you document exactly one adopter-facing change that is not yet documented, and open exactly one draft pull request for it. The workflow runs every few hours, so other gaps are handled by later runs.

## Rules for this run

- Open at most one pull request. After you open it, finish the run.
- Never invent configuration keys, defaults, API names or behavior. Every option and example must be confirmed in the source code in the checkout.
- Read `docs/contribute/doc-style-guide.md` first and follow it.

## Step 1. Read the triage file

A setup step has already sorted every changeset before you started. Read `/tmp/gh-aw/agent/doc-gaps.md` with `cat`. It contains:

- The changesets that an open `[docs]` pull request on `${{ github.repository }}` already names. Never pick one of these, and never document the same behavior again.
- The uncovered changesets, ranked by adopter impact. The "Terms already in docs" column shows how many code terms from the changeset already appear in `docs/`. It is a hint, not a verdict.

Do not redo the triage, and do not list pull requests yourself to decide what is covered. The file is the source of truth for coverage.

## Step 2. Pick the top uncovered gap

Start with rank 1 and confirm that it is a real gap:

- It is adopter-facing: not internal refactoring, test-only or build-only changes, dependency bumps, or a bug fix that needs no explanation.
- It is not already documented. Search for its key terms, for example `grep -ril "<term>" docs/ plugins/*/README.md packages/*/README.md`.

If it is not a real gap, move to the next rank. Check at most 10 ranks. If none of them is a real gap, call `noop` and name the changesets you checked and why each was skipped.

You may include other uncovered changesets that describe the same feature as the one you picked, so that one pull request documents the feature completely. Never include a changeset from the covered list.

## Step 3. Gather context

- Source code in the checkout (`packages/`, `plugins/`, `config.d.ts` files and TSDoc comments). Use it to confirm option names, defaults and example snippets.
- Merged commits on the default branch of the upstream `backstage/backstage` repository, for context only. The upstream repository is public and read-only: never write to it. Use `list_commits` on `master`, then `get_commit` and `get_file_contents` at those commits or at `ref: master`. Never request PR head refs such as `refs/pull/<number>/head` or a PR head branch, and do not rely on `pull_request_read` bodies: content that is not yet merged is filtered out by the integrity policy. Do not try to work around a filtered result.

## Step 4. Choose where it goes

- Concepts, guides and configuration go in `docs/features`, `docs/backend-system`, `docs/frontend-system` or `docs/conf`.
- Package README files only get package-specific setup, and they link to the docs instead of duplicating them.
- Never edit `docs/releases/**`, `docs/reference/**`, `CHANGELOG.md` files or `*-api-report.md` files.
- Match the target page's heading and example style.
- When the change adds options or APIs, include a YAML configuration example or a TypeScript code example. Check every name in it against the source.
- You may touch up to about 3 files when they belong together.

## Step 5. Write the documentation

Edit the files with the edit tool. Write for adopters in plain language, in the style guide's voice. Link related pages instead of repeating them.

## Step 6. Self-check

- Run `npx prettier --check <edited files>`. Fix any formatting problem it reports.
- If `vale` is available on the path, run `node scripts/check-docs-quality.js <edited files>` and fix what it reports. Otherwise, write "Vale: not run" in the pull request body.
- If the self-check fails and you cannot fix it, do not open the pull request. Call `noop` with the reason.

## Step 7. Open one pull request

1. Create a branch with a descriptive name: `git checkout -b docs/<short-topic-name>`.
2. Stage exactly the edited files by name (never `git add -A`), check that `git status` shows nothing else, and commit.
3. Call the safe-outputs create-pull-request tool once, with `branch` set to the exact output of `git branch --show-current`. Do not push, and do not change git remotes.

**Title format**: `[docs] <short description of what is now documented>`

The body must start with one line per documented changeset, in exactly this form, so that later runs can tell the changeset is covered:

```text
Changeset: .changeset/<file name>.md
```

After those lines, the body must include:

- The rank and score of the picked changeset from the triage file, and any higher ranks you skipped with a few words of reason.
- Which page it edited, and why that page.
- What you checked in the source code.
- Anything that needs human review.
- The results of the self-check.

## Edge cases

- The triage file lists no uncovered changesets, or none of the ranks you checked is a real gap: call `noop` with the reason.
- Unclear behavior that you cannot confirm in the source: do not document it. Mention it in the pull request body under human review, or pick the next rank.
