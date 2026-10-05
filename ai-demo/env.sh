# Source this to get the demo env: `source ai-demo/env.sh`
# WT is the checkout root and DEMO is this directory, both derived from this file's location.
if [ -n "${BASH_VERSION:-}" ]; then
  _demo_src="${BASH_SOURCE[0]}"
else
  _demo_src="${(%):-%x}"
fi
export DEMO="$(cd "$(dirname "$_demo_src")" && pwd)"
export WT="$(cd "$DEMO/.." && pwd)"
unset _demo_src
export BACKEND_URL=http://localhost:7107
export XDG_CONFIG_HOME=$DEMO/xdg-config
export XDG_DATA_HOME=$DEMO/xdg-data
ai()   { node "$WT/packages/cli-module-ai/bin/backstage-cli-module-ai" ai "$@"; }
auth() { node "$WT/packages/cli-module-auth/bin/backstage-cli-module-auth" auth "$@"; }
backstage-cli() { node "$WT/packages/cli/bin/backstage-cli" "$@"; }
