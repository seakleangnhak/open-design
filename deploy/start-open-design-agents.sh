#!/usr/bin/env sh
set -eu

export HOME="${HOME:-/app/.od/home}"

mkdir -p "$HOME/.codex" "$HOME/.claude" /app/.od

CODEX_BASE_URL="${CODEX_BASE_URL:-${CODEX_OPENAI_BASE_URL:-https://api.openai.com/v1}}"
CODEX_MODEL="${CODEX_MODEL:-gpt-5.5}"
CODEX_REASONING_EFFORT="${CODEX_REASONING_EFFORT:-high}"
CODEX_MODEL_VERBOSITY="${CODEX_MODEL_VERBOSITY:-high}"

cat > "$HOME/.codex/config.toml" <<EOF
model = "${CODEX_MODEL}"
model_provider = "slai"
model_reasoning_effort = "${CODEX_REASONING_EFFORT}"
model_verbosity = "${CODEX_MODEL_VERBOSITY}"

approval_policy = "never"
sandbox_mode = "workspace-write"

[sandbox_workspace_write]
network_access = true

[model_providers.slai]
name = "SLAI / OmniRoute"
base_url = "${CODEX_BASE_URL}"
env_key = "OPENAI_API_KEY"
wire_api = "responses"
supports_websockets = false
stream_idle_timeout_ms = 300000
stream_max_retries = 5
EOF

chmod 700 "$HOME/.codex"
chmod 600 "$HOME/.codex/config.toml"

echo "Codex config written to $HOME/.codex/config.toml"
echo "Codex provider base URL: $CODEX_BASE_URL"
echo "Codex model: $CODEX_MODEL"
echo "Codex supports_websockets: false"

exec node apps/daemon/dist/cli.js --no-open