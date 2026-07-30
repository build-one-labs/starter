#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(git rev-parse --show-toplevel)}"
export WORKSPACE_ROOT

# >>> b1-user-secret-fetch (managed by @buildone/swat-cli migration; safe to re-run) >>>
# Pull this workspace's secrets from the auth server using a single API key, so
# they need not be set as individual GitHub Codespaces secrets. Accepts a
# personal B1_USER_API_KEY or a shared organization B1_ORG_API_KEY; a personal
# key wins when both are set, and the server decides what each can see from the
# key's owner.
#
# This block runs before `yarn install`, so node_modules does not exist and it
# cannot read the workspace manifest — but it no longer needs to. One request to
# /api/secrets/resolve-all returns every secret the caller can see, so there is
# no list here to keep in step with anything: adding a secret means storing it
# on the server, and neither this block nor the repository changes.
#
# The variable *name* therefore comes from the server too, and this file is
# sourced by the shell. Every name is accepted, by design — so whoever can write
# a global or organization secret can set PATH, NODE_OPTIONS, BASH_ENV or
# LD_PRELOAD here. Write access to shared secrets is write access to the
# workspaces that read them. Kept in step with env_name_from_secret_key() in the
# CLI's devcontainer/lib/common.sh.
#
# Values land in .env.fetched, rewritten whole on each successful run and loaded
# before .env.local, as `NAME=${NAME:-'value'}` so an explicitly-set environment
# variable still wins. Self-contained (curl + jq + base64); a no-op when no key
# / AUTH_URL is unset or the tools are unavailable. Wrapped in a function
# invoked via `|| true` so `set -e` cannot abort the prebuild on a transient
# fetch failure.
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

# Map a secret key (lowercase with dashes) to the environment variable name it
# is exposed as. The only rejection is a key that could not be a variable name:
# an '=' or a space would put two lines into a sourced file, and a leading digit
# cannot be assigned. No list beyond that — every secret becomes a variable.
_b1_env_name() {
  local name
  name=$(printf '%s' "$1" | tr 'a-z.-' 'A-Z__')
  [[ "$name" =~ ^[A-Z][A-Z0-9_]*$ ]] || return 1
  printf '%s' "$name"
}

# Single-quote a value for a file that will be sourced: '\'' closes, escapes and
# reopens around an embedded quote. Without this a value containing $(…), a
# backtick or a newline would be executed rather than assigned.
_b1_quote() {
  printf "'%s'" "${1//\'/\'\\\'\'}"
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
  command -v base64 >/dev/null 2>&1 || return 0

  local auth="${AUTH_URL%/}"
  local env_fetched="${root}/.b1/env/.env.fetched"
  mkdir -p "${root}/.b1/env" 2>/dev/null || true
  local key encoded var val resp code body tmp n=0

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

  # /resolve-all walks user -> organization -> global for a user key (a personal
  # value wins) and organization -> global for an org key, so a shared credential
  # set once at org (or global) level serves every developer. With ?scope=, each
  # level prefers a value stored for this repository over its general one.
  resp=$(curl -sS -w '\n%{http_code}' -H "x-api-key: ${b1_api_key}" \
    "${auth}/api/secrets/resolve-all${query}" 2>/dev/null) || return 0
  code="${resp##*$'\n'}"; body="${resp%$'\n'*}"
  # Anything but success leaves any existing file alone: an expired key or an
  # auth server still starting must not empty a workspace's secrets.
  [ "$code" = "200" ] || { echo "[WARN] Secret fetch returned HTTP ${code}"; return 0; }

  tmp="${env_fetched}.tmp.$$"
  : > "$tmp"; chmod 600 "$tmp" 2>/dev/null || true
  echo "# Secrets fetched from ${auth} - rewritten on every start, do not edit." >> "$tmp"

  # `.secret` may be a plain string, a JSON-encoded string, or an object wrapping
  # { secret | value }. Normalise all of these to the raw value, and carry it as
  # base64 so spaces and newlines survive the read loop. Tab-separated: the
  # server's key charset has no tab, so a malformed key stays whole and gets
  # reported rather than being cut in half by the split.
  while IFS=$'\t' read -r key encoded; do
    [ -n "$key" ] || continue
    var=$(_b1_env_name "$key") || { echo "[WARN] Skipped secret '${key}': not usable as a variable name"; continue; }
    val=$(printf '%s' "$encoded" | base64 -d 2>/dev/null) || continue
    [ -n "$val" ] || continue
    printf '%s=${%s:-%s}\n' "$var" "$var" "$(_b1_quote "$val")" >> "$tmp"
    n=$((n + 1))
  done < <(printf '%s' "$body" | jq -r '
    .secrets[] | .key as $k | .secret as $s
    | ( if ($s|type)=="object" then ($s.secret // $s.value // "")
        elif ($s|type)=="string" then ((try ($s|fromjson) catch null) as $i
          | if ($i|type)=="object" then ($i.secret // $i.value // $s) else $s end)
        else ($s|tostring) end ) as $v
    | select($v != null and $v != "")
    | "\($k)\t\($v|@base64)"' 2>/dev/null)

  mv "$tmp" "$env_fetched" 2>/dev/null || { rm -f "$tmp"; return 0; }
  echo "[INFO] Fetched ${n} secret(s) into .env.fetched"
}
_b1_fetch_user_secrets || true

# Load what the fetch just wrote into this shell. The block above only *writes*
# .env.fetched, while everything below still reads the environment — including
# the CodeArtifact step, which needs B1_ACCESS_KEY_ID to obtain the token that
# lets `yarn install` see the private @buildone packages. Until 24.3.0-VG.375
# this was implicit: the older block exported each secret as it fetched it.
#
# `set -a` because .env.fetched assigns `NAME=${NAME:-'value'}` without export,
# and .env.local second so a local override still wins — the precedence
# start_stack.sh and build-one apply. Sourced with `|| true` so a malformed file
# cannot abort the prebuild. .b1/env/ first, the workspace root second, for a
# workspace that predates 24.3.0-VG.376.
_b1_load_env_files() {
  local root="${WORKSPACE_ROOT:-$PWD}" env_file resolved
  for env_file in .env.fetched .env.local; do
    resolved="${root}/.b1/env/${env_file}"
    [ -f "$resolved" ] || resolved="${root}/${env_file}"
    if [ -f "$resolved" ]; then
      set -a; . "$resolved" || true; set +a
    fi
  done
}
_b1_load_env_files || true
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
                mkdir -p "${WORKSPACE_ROOT}/.b1/env" 2>/dev/null || true
            echo "export CODEARTIFACT_AUTH_TOKEN=${CODEARTIFACT_AUTH_TOKEN}" > "${WORKSPACE_ROOT}/.b1/env/.aws-token.env"
                echo "[INFO] CodeArtifact token obtained"
            else
                CODEARTIFACT_AUTH_TOKEN=""
                echo "[WARN] Could not obtain a CodeArtifact token with the provided credentials"
            fi
        fi
        if [[ -z "${CODEARTIFACT_AUTH_TOKEN:-}" && -f "${WORKSPACE_ROOT}/.b1/env/.aws-token.env" ]]; then
            source "${WORKSPACE_ROOT}/.b1/env/.aws-token.env" || true
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