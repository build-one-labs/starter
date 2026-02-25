#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Codespace Startup Orchestrator
# =============================================================================
# This script orchestrates the Codespace startup sequence:
# 1. Secrets setup (if needed)
# 2. Project rename (if needed)
# 3. Stack startup
#
# All steps run sequentially in the same terminal for a clean UX.
# =============================================================================

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}"

# Source secrets configuration from swat-cli
SWAT_SECRETS_CONFIG="${WORKSPACE_ROOT}/node_modules/@buildone/swat-cli/scripts/devcontainer/lib/secrets-config.sh"
if [ -f "$SWAT_SECRETS_CONFIG" ]; then
  source "$SWAT_SECRETS_CONFIG"
  secrets_init_paths
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# Step 1: Secrets Setup
# =============================================================================
# Returns 0 if secrets are configured, 1 if secrets are missing (needs new Codespace)
run_secrets_setup() {
  if ! secrets_is_codespace; then
    return 0
  fi

  secrets_print_section "Step 1: Checking Secrets"

  "${WORKSPACE_ROOT}/node_modules/@buildone/swat-cli/scripts/devcontainer/orchestrators/codespace-secrets-init.sh"

  # Check if secrets are still missing after running setup
  # If missing, user needs to create a new Codespace - don't continue
  local missing_secrets=()
  secrets_get_missing missing_secrets

  if [ ${#missing_secrets[@]} -gt 0 ]; then
    return 1  # Secrets missing - stop here
  fi

  return 0
}

# =============================================================================
# Step 2: Project Rename
# =============================================================================
run_project_setup() {
  if ! secrets_is_codespace; then
    return 0
  fi

  secrets_print_section "Step 2: Checking Project Configuration"

  "$SCRIPT_DIR/project-rename-init.sh"
}

# =============================================================================
# Step 3: Stack Startup
# =============================================================================
run_stack_startup() {
  secrets_print_section "Step 3: Starting Stack"

  local task_runner="$WORKSPACE_ROOT/node_modules/@buildone/swat-cli/scripts/devcontainer/lib/task-runner.sh"

  if [ -f "$task_runner" ]; then
    "$task_runner" start_stack
  else
    secrets_print_warning "Task runner not found. Stack startup skipped."
    secrets_print_info "Run 'yarn install' and restart the Codespace."
  fi
}

# =============================================================================
# Main
# =============================================================================
main() {
  echo ""
  secrets_print_header "Codespace Startup"

  # Step 1: Secrets setup - stop if secrets are missing
  if ! run_secrets_setup; then
    echo ""
    secrets_print_warning "Startup paused - secrets need to be configured."
    secrets_print_info "Create a new Codespace after configuring secrets."
    exit 0
  fi

  # Step 2: Project rename (only if secrets are configured)
  run_project_setup

  # Step 3: Start the stack
  run_stack_startup
}

main "$@"
