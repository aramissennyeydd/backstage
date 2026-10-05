#!/usr/bin/env bash
# Generates the gitignored working copies for the demo from the committed templates.
# Safe to re-run: it recreates the demo repos, team-skills and generated configs from scratch.
set -euo pipefail

DEMO="$(cd "$(dirname "$0")" && pwd)"
WT="$(cd "$DEMO/.." && pwd)"
TEMPLATES="$DEMO/templates"

git_demo() { # git with a fixed identity so setup works without a global git config
  git -c user.name="Demo" -c user.email="demo@example.com" -c commit.gpgsign=false "$@"
}

make_repo() { # name origin message
  local name=$1 origin=$2 message=$3 dir="$DEMO/$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  cp -R "$TEMPLATES/$name/." "$dir/"
  git -C "$dir" init -q -b main
  if [ -n "$origin" ]; then
    git -C "$dir" remote add origin "$origin"
  fi
  git -C "$dir" add -A
  git_demo -C "$dir" commit -q -m "$message"
  if [ -n "$origin" ]; then
    mkdir -p "$dir/node_modules/@backstage"
    ln -s "$WT/packages/cli-module-ai" "$dir/node_modules/@backstage/cli-module-ai"
    ln -s "$WT/packages/cli-module-auth" "$dir/node_modules/@backstage/cli-module-auth"
  fi
}

make_repo repo https://github.com/acme-demo/payments-service.git "starting point"
make_repo growth-repo https://github.com/acme-demo/growth-service.git "starting point"
make_repo baseline-repo https://github.com/acme-demo/payments-service.git "starting point"
make_repo team-skills "" "Demo team skills"

for name in catalog-demo app-config.demo; do
  sed "s|@@DEMO@@|$DEMO|g" "$DEMO/backend-config/$name.template.yaml" > "$DEMO/backend-config/$name.yaml"
done

echo "Demo set up in $DEMO"
echo "Next: follow DEMO.md (start the backend and frontend, then 'source $DEMO/env.sh')."
