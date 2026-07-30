#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Codespace Startup Orchestrator
# =============================================================================
# This script orchestrates the Codespace startup sequence:
# 1. Project rename (if needed)
# 2. Stack startup
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
# Step 1: Project Rename
# =============================================================================
run_project_setup() {
  if ! secrets_is_codespace; then
    return 0
  fi

  secrets_print_section "Step 1: Checking Project Configuration"

  "$SCRIPT_DIR/project-rename-init.sh"
}

# =============================================================================
# Step 2: Stack Startup
# =============================================================================
run_stack_startup() {
  secrets_print_section "Step 2: Starting Stack"

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

  # Step 1: Project rename (only if secrets are configured)
  run_project_setup

  # Step 2: Start the stack
  run_stack_startup
}

main "$@"
