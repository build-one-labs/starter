#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Codespace Secrets Guided Setup
# =============================================================================
# This script provides an interactive guided setup for configuring required
# GitHub Codespace secrets. It detects missing secrets, prompts for values,
# auto-generates where appropriate, and sets them using the GitHub CLI.
#
# Usage: ./codespace-setup.sh [--force]
#   --force: Run setup even if previously completed
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common secrets configuration
source "$SCRIPT_DIR/../lib/secrets-config.sh"
init_paths

# =============================================================================
# Secret Metadata (loaded from secrets.json)
# =============================================================================
SECRETS_JSON_FILE="${SCRIPT_DIR}/../config/secrets.json"

declare -A SECRET_DESCRIPTIONS
declare -A SECRET_NOTES
declare -A SECRET_CAN_GENERATE
declare -a SECRET_ORDER

load_secret_metadata() {
  local json_file="$SECRETS_JSON_FILE"

  if [ ! -f "$json_file" ]; then
    print_error "secrets.json not found at $json_file"
    exit 1
  fi

  # Load secret order (all secrets in array order)
  mapfile -t SECRET_ORDER < <(jq -r '.secrets[].name' "$json_file")

  # Load metadata into associative arrays
  while IFS=$'\t' read -r name desc note can_gen; do
    SECRET_DESCRIPTIONS["$name"]="$desc"
    SECRET_NOTES["$name"]="$note"
    SECRET_CAN_GENERATE["$name"]="$can_gen"
  done < <(jq -r '.secrets[] | [.name, .description, .note, (.canGenerate | tostring)] | @tsv' "$json_file")
}

# Load metadata on source
load_secret_metadata

# =============================================================================
# Helper Functions
# =============================================================================

generate_random_string() {
  local length="${1:-32}"
  openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

generate_db_credentials() {
  local db_name="$1"
  local username="${db_name}_user"
  local password=$(generate_random_string 24)
  echo "${username}:${password}"
}

generate_default_value() {
  local secret_name="$1"
  case "$secret_name" in
    APP_DATABASE_CREDENTIALS)  generate_db_credentials "app_db" ;;
    B1_DATABASE_CREDENTIALS)   generate_db_credentials "b1_db" ;;
    AUTH_DATABASE_CREDENTIALS) generate_db_credentials "auth_db" ;;
    B1_AUTOMATION_HUB_PASSWORD) generate_random_string 16 ;;
    BETTER_AUTH_SECRET)        generate_random_string 32 ;;
    *) echo "" ;;
  esac
}

set_codespace_secret() {
  local secret_name="$1"
  local secret_value="$2"
  if ! gh secret set "$secret_name" --app codespaces --body "$secret_value" 2>/dev/null; then
    print_error "Failed to set secret: $secret_name"
    return 1
  fi
  return 0
}

# Note: All display output goes to stderr so only the value goes to stdout
prompt_for_value() {
  local prompt_text="$1"
  local default_value="${2:-}"
  local is_password="${3:-false}"
  local value=""

  if [ -n "$default_value" ]; then
    echo -e "${prompt_text} ${COLOR_CYAN}[auto-generated]${COLOR_NC}" >&2
    read -p "Press Enter to use auto-generated value, or type a custom value: " value </dev/tty
    if [ -z "$value" ]; then
      value="$default_value"
      print_info "Using auto-generated value" >&2
    fi
  else
    if [ "$is_password" = "true" ]; then
      read -s -p "$prompt_text: " value </dev/tty
      echo "" >&2
    else
      read -p "$prompt_text: " value </dev/tty
    fi
  fi

  echo "$value"
}

prompt_for_secret() {
  local secret_name="$1"
  local description="${SECRET_DESCRIPTIONS[$secret_name]}"
  local note="${SECRET_NOTES[$secret_name]}"
  local can_generate="${SECRET_CAN_GENERATE[$secret_name]}"
  local default_value=""
  local secret_value=""

  # All display output goes to stderr so only the value goes to stdout
  echo "" >&2
  echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}" >&2
  echo -e "${COLOR_BOLD}$secret_name${COLOR_NC}" >&2
  echo -e "${COLOR_CYAN}$description${COLOR_NC}" >&2
  echo -e "${COLOR_YELLOW}Note: $note${COLOR_NC}" >&2
  echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}" >&2
  echo "" >&2

  if [ "$can_generate" = "true" ]; then
    default_value=$(generate_default_value "$secret_name")
  fi

  local is_password="false"
  [[ "$secret_name" == *"PASSWORD"* ]] || [[ "$secret_name" == *"SECRET"* ]] || [[ "$secret_name" == *"TOKEN"* ]] && is_password="true"

  secret_value=$(prompt_for_value "Enter value for $secret_name" "$default_value" "$is_password")

  while [ -z "$secret_value" ]; do
    print_error "Value cannot be empty" >&2
    secret_value=$(prompt_for_value "Enter value for $secret_name" "$default_value" "$is_password")
  done

  echo "$secret_value"
}

# =============================================================================
# Main Setup Logic
# =============================================================================

check_prerequisites() {
  print_section "Checking Prerequisites"

  if ! is_codespace; then
    print_error "This script is designed for GitHub Codespaces only."
    print_info "Current environment: ${CODESPACES:-not-set}"
    return 1
  fi
  print_success "Running in GitHub Codespace"

  if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed."
    return 1
  fi
  print_success "GitHub CLI is available"

  if ! gh auth status &> /dev/null; then
    print_error "GitHub CLI is not authenticated."
    print_info "Run: gh auth login"
    return 1
  fi
  print_success "GitHub CLI is authenticated"

  return 0
}

scan_missing_secrets() {
  local -n missing_secrets_ref=$1
  local count=0

  print_section "Scanning for Missing Secrets"

  for secret_name in "${SECRET_ORDER[@]}"; do
    if is_secret_set "$secret_name"; then
      print_success "$secret_name is configured"
    else
      print_warning "$secret_name is NOT configured"
      missing_secrets_ref+=("$secret_name")
      ((count++))
    fi
  done

  echo ""
  if [ $count -eq 0 ]; then
    print_success "All required secrets are configured!"
    return 1
  else
    print_info "Found $count missing secret(s)"
    return 0
  fi
}

configure_secrets() {
  local -n missing_secrets_ref=$1
  local configured_count=0
  local failed_count=0

  print_section "Configuring Secrets"

  echo -e "${COLOR_CYAN}This process will guide you through setting up each required secret.${COLOR_NC}"
  echo -e "${COLOR_CYAN}Values will be securely stored as GitHub Codespace secrets.${COLOR_NC}"
  echo ""

  read -p "Press Enter to continue..."

  for secret_name in "${missing_secrets_ref[@]}"; do
    local secret_value=$(prompt_for_secret "$secret_name")

    print_info "Setting secret in GitHub Codespaces..."
    if set_codespace_secret "$secret_name" "$secret_value"; then
      print_success "Successfully configured $secret_name"
      ((configured_count++))
    else
      print_error "Failed to configure $secret_name"
      ((failed_count++))
    fi
  done

  echo ""
  print_header "Configuration Complete"
  print_success "Configured $configured_count secret(s)"

  if [ $failed_count -gt 0 ]; then
    print_warning "Failed to configure $failed_count secret(s)"
    return 1
  fi

  return 0
}

show_next_steps() {
  print_section "Next Steps"
  show_create_codespace_instructions
  echo ""
  print_info "The new Codespace will have all secrets available automatically."
}

main() {
  local force_setup=false

  while [[ $# -gt 0 ]]; do
    case $1 in
      --force)
        force_setup=true
        shift
        ;;
      *)
        print_error "Unknown option: $1"
        echo "Usage: $0 [--force]"
        exit 1
        ;;
    esac
  done

  print_header "GitHub Codespace Secrets - Guided Setup"

  if [ -f "$SECRETS_SETUP_COMPLETE_MARKER" ] && [ "$force_setup" = "false" ]; then
    print_info "Guided setup was previously completed."
    print_info "Use --force to run setup again."
    echo ""
    read -p "Do you want to run setup again? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      print_info "Setup skipped."
      exit 0
    fi
  fi

  if ! check_prerequisites; then
    print_error "Prerequisites check failed. Exiting."
    exit 1
  fi

  local missing_secrets=()
  if ! scan_missing_secrets missing_secrets; then
    print_info "No configuration needed."
    touch "$SECRETS_SETUP_COMPLETE_MARKER"
    exit 0
  fi

  if ! configure_secrets missing_secrets; then
    print_error "Secret configuration failed."
    exit 1
  fi

  touch "$SECRETS_SETUP_COMPLETE_MARKER"

  show_next_steps

  print_success "Guided setup completed successfully!"
}

main "$@"
