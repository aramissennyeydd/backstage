---
on:
  workflow_dispatch:
  push:
    branches: [gh-aw-test]
permissions:
  contents: read
engine:
  id: copilot
  env:
    COPILOT_GITHUB_TOKEN: ${{ secrets.GH_AW_TOKEN }}
timeout-minutes: 10
safe-outputs:
  create-pull-request:
    title-prefix: '[gh-aw] '
    base-branch: gh-aw-test
    draft: true
    max: 1
---

# Hello gh-aw

Create a new file named `gh-aw-hello.txt` in the repository root containing one sentence that summarizes what this repository is, based on README.md. Do not modify any other file. Then open a pull request with that single change.
