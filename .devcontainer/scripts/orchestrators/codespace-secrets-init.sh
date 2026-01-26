#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Codespace Secrets Initialization (Blocking)
# =============================================================================
# This script runs during postAttachCommand to ensure secrets are configured.
# It prompts the user to run the guided setup wizard if secrets are missing.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common secrets configuration
source "$SCRIPT_DIR/../lib/secrets-config.sh"
init_paths

main() {
  # Only run in Codespaces
  if ! is_codespace; then
    exit 0
  fi

  # If setup was already completed, skip
  if [ -f "$SECRETS_SETUP_COMPLETE_MARKER" ]; then
    exit 0
  fi

  # Check for missing secrets
  local missing_secrets=()
  get_missing_secrets missing_secrets

  # If all secrets are configured, mark as complete
  if [ ${#missing_secrets[@]} -eq 0 ]; then
    touch "$SECRETS_SETUP_COMPLETE_MARKER"
    print_success "All required secrets are configured"
    exit 0
  fi

  # Display critical warning about missing secrets
  echo ""
  echo -e "${COLOR_BOLD}${COLOR_RED}╔════════════════════════════════════════════════════════════════════════╗${COLOR_NC}"
  echo -e "${COLOR_BOLD}${COLOR_RED}║                                                                        ║${COLOR_NC}"
  echo -e "${COLOR_BOLD}${COLOR_RED}║  ⚠️  CRITICAL: REQUIRED SECRETS NOT CONFIGURED                        ║${COLOR_NC}"
  echo -e "${COLOR_BOLD}${COLOR_RED}║                                                                        ║${COLOR_NC}"
  echo -e "${COLOR_BOLD}${COLOR_RED}╚════════════════════════════════════════════════════════════════════════╝${COLOR_NC}"
  echo ""
  echo -e "${COLOR_YELLOW}Your GitHub Codespace is missing ${COLOR_BOLD}${#missing_secrets[@]} required secrets${COLOR_NC}${COLOR_YELLOW}.${COLOR_NC}"
  echo -e "${COLOR_YELLOW}Services CANNOT start without these secrets and will fail.${COLOR_NC}"
  echo ""
  echo -e "${COLOR_BOLD}Missing secrets:${COLOR_NC}"
  for secret in "${missing_secrets[@]}"; do
    echo -e "  ${COLOR_RED}✗${COLOR_NC} $secret"
  done
  echo ""
  echo -e "${COLOR_BOLD}${COLOR_CYAN}Would you like to run the guided setup wizard now?${COLOR_NC}"
  echo -e "${COLOR_CYAN}This will configure all required secrets interactively.${COLOR_NC}"
  echo ""

  # Prompt for guided setup
  read -p "Run guided setup? (Y/n): " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    print_warning "Setup skipped."
    echo ""
    echo -e "${COLOR_BOLD}To configure secrets later, run:${COLOR_NC}"
    echo -e "  ${COLOR_CYAN}.devcontainer/scripts/orchestrators/codespace-setup.sh${COLOR_NC}"
    echo ""
    print_error "WARNING: Stack startup will fail until secrets are configured!"
    echo ""
    exit 0
  fi

  # Run the guided setup
  echo ""
  print_info "Starting guided setup wizard..."
  echo ""

  "${SCRIPT_DIR}/codespace-setup.sh"

  local setup_exit_code=$?

  if [ $setup_exit_code -eq 0 ]; then
    echo ""
    print_success "Secrets configured successfully!"
    echo ""
    show_create_codespace_instructions
  else
    echo ""
    print_error "Guided setup failed or was cancelled."
    echo ""
    echo -e "${COLOR_BOLD}To try again, run:${COLOR_NC}"
    echo -e "  ${COLOR_CYAN}.devcontainer/scripts/orchestrators/codespace-setup.sh${COLOR_NC}"
    echo ""
    exit 1
  fi
}

main "$@"
