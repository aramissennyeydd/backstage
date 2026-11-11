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
---

# Hello gh-aw

Read the README.md in the repository root and reply with a one-sentence summary of what this repository is. Do not modify any files.
