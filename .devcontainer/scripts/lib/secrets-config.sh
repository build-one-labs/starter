#!/usr/bin/env bash
# =============================================================================
# Codespace Secrets Configuration
# =============================================================================
# Central definition of required secrets for GitHub Codespaces.
# Source this file from any script that needs to check or configure secrets.
# =============================================================================

# =============================================================================
# Terminal Colors
# =============================================================================
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_NC='\033[0m' # No Color

# =============================================================================
# Print Helper Functions
# =============================================================================
print_header() {
  echo ""
  echo -e "${COLOR_BOLD}${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
  echo -e "${COLOR_BOLD}${COLOR_CYAN}  $1${COLOR_NC}"
  echo -e "${COLOR_BOLD}${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}"
  echo ""
}

print_section() {
  echo ""
  echo -e "${COLOR_BOLD}${COLOR_BLUE}▶ $1${COLOR_NC}"
  echo ""
}

print_success() {
  echo -e "${COLOR_GREEN}✓${COLOR_NC} $1"
}

print_warning() {
  echo -e "${COLOR_YELLOW}⚠${COLOR_NC} $1"
}

print_error() {
  echo -e "${COLOR_RED}✗${COLOR_NC} $1"
}

print_info() {
  echo -e "${COLOR_CYAN}ℹ${COLOR_NC} $1"
}

# =============================================================================
# Common Paths
# =============================================================================
init_paths() {
  SECRETS_WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "/workspaces/starter")}"
  SECRETS_STATE_DIR="${SECRETS_WORKSPACE_ROOT}/tmp/workspace/markers"
  SECRETS_SETUP_COMPLETE_MARKER="${SECRETS_STATE_DIR}/codespace_setup_complete.marker"
  mkdir -p "$SECRETS_STATE_DIR"
}

# =============================================================================
# Required Secrets (loaded from secrets.json)
# =============================================================================
SCRIPT_DIR_SECRETS_CONFIG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_JSON_FILE="${SCRIPT_DIR_SECRETS_CONFIG}/../config/secrets.json"

load_secrets_from_json() {
  if [ ! -f "$SECRETS_JSON_FILE" ]; then
    echo "Error: secrets.json not found at $SECRETS_JSON_FILE" >&2
    exit 1
  fi

  # Load required secrets into array
  mapfile -t REQUIRED_SECRETS < <(jq -r '.secrets[] | select(.required == true) | .name' "$SECRETS_JSON_FILE")
}

# Load secrets on source
load_secrets_from_json

# Check if a secret is set in the environment
is_secret_set() {
  local secret_name="$1"
  [ -n "${!secret_name:-}" ]
}

# Check if we're in a GitHub Codespace
is_codespace() {
  [ "${CODESPACES:-false}" = "true" ]
}

# Get list of missing secrets
# Usage: get_missing_secrets missing_array
# Returns: populates the passed array with missing secret names
get_missing_secrets() {
  local -n result=$1
  result=()
  for secret_name in "${REQUIRED_SECRETS[@]}"; do
    if ! is_secret_set "$secret_name"; then
      result+=("$secret_name")
    fi
  done
}

# =============================================================================
# Next Steps Message
# =============================================================================
show_create_codespace_instructions() {
  echo -e "${COLOR_BOLD}${COLOR_YELLOW}IMPORTANT: You must create a NEW Codespace to apply the secrets.${COLOR_NC}"
  echo ""
  echo -e "${COLOR_CYAN}Codespace secrets are only injected at creation time, not during rebuilds.${COLOR_NC}"
  echo ""
  echo -e "${COLOR_BOLD}To create a new Codespace:${COLOR_NC}"
  echo "  1. Go to the repository on GitHub.com"
  echo "  2. Click 'Code' → 'Codespaces' tab"
  echo "  3. Click 'Create codespace on <branch>'"
  echo ""
  echo -e "${COLOR_YELLOW}You can delete this Codespace after the new one is ready.${COLOR_NC}"
}
