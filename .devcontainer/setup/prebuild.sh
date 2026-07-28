#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(git rev-parse --show-toplevel)}"
export WORKSPACE_ROOT

# >>> b1-user-secret-fetch (managed by @buildone/swat-cli migration; safe to re-run) >>>
# Pull the credentials needed to INSTALL PACKAGES from the auth server, using a
# single API key, so they need not be set as individual GitHub Codespaces
# secrets. Accepts a personal B1_USER_API_KEY or a shared organization
# B1_ORG_API_KEY; a personal key wins when both are set, and the server decides
# what each can see from the key's owner.
#
# Only the CodeArtifact credentials are fetched here, deliberately. This runs
# before `yarn install`, so node_modules does not exist and this block cannot
# read the workspace manifest (workspace/secrets.json) that lists every secret —
# hence the two keys are written out literally. Everything else a workspace uses
# (Neon, LLM keys, ...) is needed at stack start, not at install time, and is
# fetched there by orchestrators/fetch-user-secrets.sh straight from the
# manifest. So adding a secret never means touching this block: the list here is
# pinned to what package installation needs, which is these two.
#
# Self-contained (curl + jq only); a no-op when no key / AUTH_URL is unset or the
# tools are unavailable. Wrapped in a function invoked via `|| true` so `set -e`
# cannot abort the prebuild on a transient fetch failure.
# Resolve this workspace's repository as `owner/name`, for use as a secret
# scope; empty when it cannot be determined, which means unscoped.
# GITHUB_REPOSITORY is set in a Codespace but not in a local devcontainer, so
# the git remote is the fallback — it needs no network, no gh CLI and no
# authentication, and yields the identical string, which matters because a
# scope that differed between the two would silently resolve to nothing.
# Kept in step with repo_scope() in the CLI's devcontainer/lib/common.sh.
_b1_repo_scope() {
  local scope="${GITHUB_REPOSITORY:-}" root="${WORKSPACE_ROOT:-$PWD}" url owner name
  if [ -z "$scope" ] && url=$(git -C "$root" remote get-url origin 2>/dev/null) && [ -n "$url" ]; then
    url="${url%.git}"; url="${url%/}"
    # A URL keeps the host as a path segment; the scp-like form ends it at ':'.
    case "$url" in
      *://*) url="${url#*://}"; url="${url#*@}"; url="${url#*/}" ;;
      *:*)   url="${url#*@}"; url="${url#*:}" ;;
    esac
    name="${url##*/}"; owner="${url%/*}"; owner="${owner##*/}"
    if [ -n "$owner" ] && [ -n "$name" ] && [ "$owner" != "$name" ]; then scope="${owner}/${name}"; fi
  fi
  # Mirror the auth server's scope rules: an unexpected remote yields no scope
  # rather than a request the server rejects.
  if [ -n "$scope" ] && [[ "$scope" =~ ^[A-Za-z0-9._/-]{1,200}$ ]] && [[ ! "$scope" =~ (^|/)\.\.?(/|$) ]]; then
    printf '%s' "$scope"
  fi
}

_b1_fetch_user_secrets() {
  local b1_api_key="${B1_USER_API_KEY:-${B1_ORG_API_KEY:-}}"
  [ -n "$b1_api_key" ] || return 0

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
  local var key cur resp code body val

  # Secrets may be stored for a specific repository as well as generally; the
  # scope is this workspace's repository. Empty means unscoped — exactly the
  # pre-scope behaviour.
  local scope query=''
  scope=$(_b1_repo_scope)
  if [ -n "$scope" ]; then
    # Percent-encode the '/' so it cannot be read as a path segment.
    query="?scope=${scope//\//%2F}"
    echo "[INFO] Resolving secrets for scope ${scope}"
  fi
  # Keep in step with the `critical` entries in workspace/secrets.json; the test
  # suite asserts the two lists match. A secret is stored under its variable
  # name lowercased with dashes, so only the variable is named here.
  for var in \
    "B1_ACCESS_KEY_ID" \
    "B1_SECRET_ACCESS_KEY"; do
    key=$(printf '%s' "$var" | tr 'A-Z_' 'a-z-')
    eval "cur=\${${var}:-}"
    # Never overwrite a value the developer already set explicitly in the environment.
    [ -z "$cur" ] || continue
    # /resolve/ walks user -> organization -> global for a user key (a personal
    # value wins) and organization -> global for an org key, so a shared credential
    # set once at org (or global) level serves every developer. With ?scope=, each
    # level prefers a value stored for this repository over its general one.
    resp=$(curl -sS -w '\n%{http_code}' -H "x-api-key: ${b1_api_key}" \
      "${auth}/api/secrets/resolve/${key}${query}" 2>/dev/null) || continue
    code="${resp##*$'\n'}"; body="${resp%$'\n'*}"
    # 404 = no secret at user, org or global level (not an error); non-200 is skipped.
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

    # >>> b1-codeartifact-auth (managed by @buildone/swat-cli migration; safe to re-run) >>>
    # Map B1_* credentials to the AWS_* names the AWS CLI requires. Only export
    # when a value is actually present: exporting empty strings makes the AWS CLI
    # fail with NoCredentials even when a cached token could have been used.
    if [[ -z "${AWS_ACCESS_KEY_ID:-}" && -n "${B1_ACCESS_KEY_ID:-}" ]]; then
        export AWS_ACCESS_KEY_ID="${B1_ACCESS_KEY_ID}"
        export AWS_SECRET_ACCESS_KEY="${B1_SECRET_ACCESS_KEY:-}"
    fi

    # Obtain the CodeArtifact auth token for the private @buildone registry
    # (required by .yarnrc.yml). Guarded so a Codespace without credentials cannot
    # abort container creation (this script runs under `set -e` as onCreateCommand):
    # fall back to a previously cached token, and otherwise skip the install with
    # instructions naming the API key that fetches them.
    if [[ -z "${CODEARTIFACT_AUTH_TOKEN:-}" ]]; then
        if command -v aws >/dev/null 2>&1 && [[ -n "${AWS_ACCESS_KEY_ID:-}" && -n "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
            echo "[INFO] Obtaining CodeArtifact auth token..."
            if CODEARTIFACT_AUTH_TOKEN=$(aws codeartifact get-authorization-token \
                --domain buildone --domain-owner 653306034207 \
                --region "${AWS_REGION:-eu-central-1}" --query authorizationToken --output text) \
                && [[ -n "${CODEARTIFACT_AUTH_TOKEN}" ]]; then
                export CODEARTIFACT_AUTH_TOKEN
                echo "export CODEARTIFACT_AUTH_TOKEN=${CODEARTIFACT_AUTH_TOKEN}" > "${WORKSPACE_ROOT}/.aws-token.env"
                echo "[INFO] CodeArtifact token obtained"
            else
                CODEARTIFACT_AUTH_TOKEN=""
                echo "[WARN] Could not obtain a CodeArtifact token with the provided credentials"
            fi
        fi
        if [[ -z "${CODEARTIFACT_AUTH_TOKEN:-}" && -f "${WORKSPACE_ROOT}/.aws-token.env" ]]; then
            source "${WORKSPACE_ROOT}/.aws-token.env" || true
            if [[ -n "${CODEARTIFACT_AUTH_TOKEN:-}" ]]; then
                echo "[INFO] Using cached CodeArtifact token"
            fi
        fi
    fi

    if [[ -z "${CODEARTIFACT_AUTH_TOKEN:-}" ]]; then
        echo ""
        echo "============================================================================="
        echo "  NPM CREDENTIALS NOT CONFIGURED - SKIPPING PACKAGE INSTALL"
        echo "============================================================================="
        echo ""
        echo "  No CodeArtifact token could be obtained, so private @buildone packages"
        echo "  cannot be downloaded."
        if [[ -n "${B1_USER_API_KEY:-}${B1_ORG_API_KEY:-}" && -z "${AUTH_URL:-}" ]]; then
            echo ""
            echo "  Note: a B1 API key is set, but AUTH_URL is not, so the automatic"
            echo "  secret fetch could not contact the auth server. Set AUTH_URL as a"
            echo "  Codespaces secret alongside the key."
        fi
        echo ""
        echo "  These credentials are provisioned for you. Set ONE API key as a"
        echo "  Codespaces secret and rebuild the container:"
        echo ""
        echo "    B1_ORG_API_KEY   organization-level - every repository, every"
        echo "                     member, and what CI workflows use"
        echo "    B1_USER_API_KEY  user-level - your own key, takes precedence"
        echo ""
        echo "  Mint one in the web app: Account -> API keys, or"
        echo "  My Organization -> API keys."
        echo ""
        echo "  Setting B1_ACCESS_KEY_ID and B1_SECRET_ACCESS_KEY directly still"
        echo "  works and always wins over a fetched value."
        echo "============================================================================="
        echo ""
        exit 0
    fi
    # <<< b1-codeartifact-auth <<<

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