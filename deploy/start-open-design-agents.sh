#!/usr/bin/env sh
set -eu

export HOME="${HOME:-/app/.od/home}"

CODEX_DIR="$HOME/.codex"
CLAUDE_DIR="$HOME/.claude"
CODEX_ENV_FILE="$CODEX_DIR/.env"
CODEX_CONFIG_FILE="$CODEX_DIR/config.toml"

mkdir -p "$CODEX_DIR" "$CLAUDE_DIR" /app/.od

# Prefer CODEX_API_KEY, fallback to OPENAI_API_KEY.
# This lets you use CODEX_API_KEY in Dokploy but still expose OPENAI_API_KEY to Codex.
if [ -n "${CODEX_API_KEY:-}" ] && [ -z "${OPENAI_API_KEY:-}" ]; then
  export OPENAI_API_KEY="$CODEX_API_KEY"
fi

CODEX_BASE_URL="${CODEX_BASE_URL:-${CODEX_OPENAI_BASE_URL:-https://api.openai.com/v1}}"
CODEX_MODEL="${CODEX_MODEL:-gpt-5.5}"
CODEX_REASONING_EFFORT="${CODEX_REASONING_EFFORT:-high}"
CODEX_MODEL_VERBOSITY="${CODEX_MODEL_VERBOSITY:-high}"

# Create persistent Codex .env file.
# Warning: this stores the API key as plaintext inside the Docker volume.
cat > "$CODEX_ENV_FILE" <<EOF
OPENAI_API_KEY=${OPENAI_API_KEY:-}
CODEX_BASE_URL=${CODEX_BASE_URL}
CODEX_MODEL=${CODEX_MODEL}
CODEX_REASONING_EFFORT=${CODEX_REASONING_EFFORT}
CODEX_MODEL_VERBOSITY=${CODEX_MODEL_VERBOSITY}
EOF

chmod 700 "$CODEX_DIR"
chmod 600 "$CODEX_ENV_FILE"

# Load .env into the current process environment.
# Open Design will inherit this env, and spawned Codex CLI processes inherit it too.
set -a
. "$CODEX_ENV_FILE"
set +a

cat > "$CODEX_CONFIG_FILE" <<EOF
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

chmod 600 "$CODEX_CONFIG_FILE"

echo "Codex .env written to $CODEX_ENV_FILE"
echo "Codex config written to $CODEX_CONFIG_FILE"
echo "Codex provider base URL: $CODEX_BASE_URL"
echo "Codex model: $CODEX_MODEL"

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "WARNING: OPENAI_API_KEY is empty. Codex will not start until CODEX_API_KEY or OPENAI_API_KEY is set."
else
  echo "OPENAI_API_KEY loaded for Codex."
fi

exec node apps/daemon/dist/cli.js --no-open