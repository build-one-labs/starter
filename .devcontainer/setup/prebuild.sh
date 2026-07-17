#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(git rev-parse --show-toplevel)}"
export WORKSPACE_ROOT

# >>> b1-user-secret-fetch (managed by @buildone/swat-cli migration; safe to re-run) >>>
# Pull per-user secrets from the auth server using a single B1_USER_API_KEY, BEFORE
# packages are installed, so credentials such as B1_ACCESS_KEY_ID need not be set as
# individual GitHub Codespaces secrets. Self-contained (curl + jq only, no node_modules
# — which is not installed yet at this point); a no-op when B1_USER_API_KEY / AUTH_URL
# is unset or the tools are unavailable. Wrapped in a function invoked via `|| true` so
# `set -e` cannot abort the prebuild on a transient fetch failure.
_b1_fetch_user_secrets() {
  [ -n "${B1_USER_API_KEY:-}" ] || return 0

  local root="${WORKSPACE_ROOT:-$PWD}"

  # AUTH_URL usually lives in .env; load it non-fatally if not already exported.
  if [ -z "${AUTH_URL:-}" ] && [ -f "${root}/.env" ]; then
    set -a; . "${root}/.env" 2>/dev/null || true; set +a
  fi
  [ -n "${AUTH_URL:-}" ] || return 0
  command -v curl >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0

  local auth="${AUTH_URL%/}"
  local env_local="${root}/.env.local"
  local pair var key cur resp code body val
  for pair in \
    "B1_ACCESS_KEY_ID:b1-access-key-id" \
    "B1_SECRET_ACCESS_KEY:b1-secret-access-key" \
    "NEON_API_KEY:neon-api-key" \
    "ANTHROPIC_API_KEY:anthropic-api-key" \
    "OPENAI_API_KEY:openai-api-key" \
    "MOONSHOT_API_KEY:moonshot-api-key"; do
    var="${pair%%:*}"; key="${pair##*:}"
    eval "cur=\${${var}:-}"
    # Never overwrite a value the developer already set explicitly in the environment.
    [ -z "$cur" ] || continue
    resp=$(curl -sS -w '\n%{http_code}' -H "x-api-key: ${B1_USER_API_KEY}" \
      "${auth}/api/secrets/key/${key}" 2>/dev/null) || continue
    code="${resp##*$'\n'}"; body="${resp%$'\n'*}"
    # 404 = user hasn't stored this secret (not an error); anything non-200 is skipped.
    [ "$code" = "200" ] || continue
    # `.secret` may be a plain string, a JSON-encoded string, or an object wrapping
    # { secret | value }. Normalise all of these to the raw value.
    val=$(printf '%s' "$body" | jq -r '.secret as $s
      | if ($s|type)=="object" then ($s.secret // $s.value // "")
        elif ($s|type)=="string" then ((try ($s|fromjson) catch null) as $i
          | if ($i|type)=="object" then ($i.secret // $i.value // $s) else $s end)
        else ($s|tostring) end' 2>/dev/null)
    { [ -n "$val" ] && [ "$val" != "null" ]; } || continue
    touch "$env_local"
    if grep -q "^${var}=" "$env_local" 2>/dev/null; then
      grep -v "^${var}=" "$env_local" > "${env_local}.tmp" && mv "${env_local}.tmp" "$env_local"
    fi
    printf '%s=%s\n' "$var" "$val" >> "$env_local"
    export "${var}=${val}"
    echo "[INFO] Fetched ${var} from the auth server"
  done
}
_b1_fetch_user_secrets || true
# <<< b1-user-secret-fetch <<<


# =============================================================================
# Codespace Secrets Check
# =============================================================================
# In GitHub Codespaces, check if required secrets are configured.
# If missing, skip the prebuild entirely - the secrets setup wizard will run
# during postAttach to guide the user through configuration.
# =============================================================================

# Source secrets configuration from swat-cli (available after yarn install)
SECRETS_CONFIG="${WORKSPACE_ROOT}/node_modules/@buildone/swat-cli/scripts/devcontainer/lib/secrets-config.sh"
if [ -f "$SECRETS_CONFIG" ]; then
    source "$SECRETS_CONFIG"
    secrets_init_paths

    if secrets_is_codespace; then
        missing_secrets=()
        secrets_get_missing missing_secrets

        if [ ${#missing_secrets[@]} -gt 0 ]; then
            echo ""
            echo "============================================================================="
            echo "  CODESPACE SECRETS NOT CONFIGURED"
            echo "============================================================================="
            echo ""
            echo "  Missing ${#missing_secrets[@]} required secret(s):"
            for secret in "${missing_secrets[@]}"; do
                echo "    - $secret"
            done
            echo ""
            echo "  Skipping prebuild. The secrets setup wizard will run when you attach."
            echo "============================================================================="
            echo ""
            exit 0
        fi

        echo "[INFO] All required secrets are configured, proceeding with prebuild..."
    fi
fi

# Ensure packages are installed before running prebuild
# Skip install during prebuild check (triggered at stack startup) - will be installed by dedicated task
if [[ "${PREBUILD_CHECK:-}" != "true" ]]; then
    cd "${WORKSPACE_ROOT}"

    # Map B1 credentials to AWS CLI environment variables if not already set
    export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-${B1_ACCESS_KEY_ID:-}}"
    export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-${B1_SECRET_ACCESS_KEY:-}}"

    # Obtain CodeArtifact auth token for private @buildone registry (required by .yarnrc.yml)
    if [[ -z "${CODEARTIFACT_AUTH_TOKEN:-}" ]]; then
        echo "[INFO] Obtaining CodeArtifact auth token..."
        CODEARTIFACT_AUTH_TOKEN=$(aws codeartifact get-authorization-token \
            --domain buildone --domain-owner 653306034207 \
            --region "${AWS_REGION:-eu-central-1}" --query authorizationToken --output text)
        export CODEARTIFACT_AUTH_TOKEN
    fi

    echo "[INFO] Installing packages..."
    yarn install

    echo "[INFO] Clearing yarn cache..."
    yarn cache clear
else
    echo "[INFO] Skipping package install during prebuild check"
fi

# Ensure the workspace scripts are executable
find "${WORKSPACE_ROOT}/node_modules/@buildone/swat-cli/scripts/devcontainer" -type f -name "*.sh" -exec chmod +x {} \;

# Now call the actual prebuild script from the installed package
exec "${WORKSPACE_ROOT}/node_modules/@buildone/swat-cli/scripts/devcontainer/orchestrators/prebuild.sh" "$@"