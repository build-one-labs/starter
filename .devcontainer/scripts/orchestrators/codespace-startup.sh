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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}"

# Source common utilities
source "$SCRIPT_DIR/../lib/secrets-config.sh"
init_paths

# =============================================================================
# Step 1: Secrets Setup
# =============================================================================
# Returns 0 if secrets are configured, 1 if secrets are missing (needs new Codespace)
run_secrets_setup() {
  if ! is_codespace; then
    return 0
  fi

  print_section "Step 1: Checking Secrets"

  "$SCRIPT_DIR/codespace-secrets-init.sh"

  # Check if secrets are still missing after running setup
  # If missing, user needs to create a new Codespace - don't continue
  local missing_secrets=()
  get_missing_secrets missing_secrets

  if [ ${#missing_secrets[@]} -gt 0 ]; then
    return 1  # Secrets missing - stop here
  fi

  return 0
}

# =============================================================================
# Step 2: Project Rename
# =============================================================================
run_project_setup() {
  if ! is_codespace; then
    return 0
  fi

  print_section "Step 2: Checking Project Configuration"

  "$SCRIPT_DIR/project-rename-init.sh"
}

# =============================================================================
# Step 3: Stack Startup
# =============================================================================
run_stack_startup() {
  print_section "Step 3: Starting Stack"

  local task_runner="$WORKSPACE_ROOT/node_modules/@buildone/swat-cli/scripts/devcontainer/lib/task-runner.sh"

  if [ -f "$task_runner" ]; then
    "$task_runner" start_stack
  else
    print_warning "Task runner not found. Stack startup skipped."
    print_info "Run 'yarn install' and restart the Codespace."
  fi
}

# =============================================================================
# Main
# =============================================================================
main() {
  echo ""
  print_header "Codespace Startup"

  # Step 1: Secrets setup - stop if secrets are missing
  if ! run_secrets_setup; then
    echo ""
    print_warning "Startup paused - secrets need to be configured."
    print_info "Create a new Codespace after configuring secrets."
    exit 0
  fi

  # Step 2: Project rename (only if secrets are configured)
  run_project_setup

  # Step 3: Start the stack
  run_stack_startup
}

main "$@"
