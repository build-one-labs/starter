#!/usr/bin/env bash
set -euo pipefail

# Set lifecycle hook for logging
export DEVCONTAINER_LIFECYCLE="prebuild"

# Ensure logs directory exists
mkdir -p "${WORKSPACE_ROOT}/logs/workspace"

# Redirect all output to lifecycle-specific log file
exec 1> >(tee -a "${WORKSPACE_ROOT}/logs/workspace/${DEVCONTAINER_LIFECYCLE}.log")
exec 2>&1

# Check if running in devcontainer
if [ "${REMOTE_CONTAINERS:-}" != "true" ] && [ -z "${CODESPACES:-}" ]; then
  echo "[INFO] Not running in devcontainer, skipping prebuild..."
  exit 0
fi

# Source the task runner to use run_task function and shared state
source "${WORKSPACE_ROOT}/node_modules/@buildone/swat-cli/scripts/devcontainer/lib/task-runner.sh"

run_prebuild() {
  (
    flock -n 9 || {
      echo "[INFO] Another window is running prebuild, waiting..."
      while [ ! -f "$DONE_FILE" ]; do sleep 2; done
      echo "[INFO] Prebuild already completed by leader."
      return 0
    }

    echo "[INFO] This window is leader, running prebuild tasks..."
    local start_time=$(date +%s)

    run_task pull_stack

    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    local minutes=$((total_time / 60))
    local seconds=$((total_time % 60))

    touch "$DONE_FILE"
    echo "[INFO] Prebuild finished in ${minutes}m ${seconds}s."
  ) 9>"$LOCK_FILE"
}

# Check if already completed
if [ -f "$DONE_FILE" ]; then
  echo "[INFO] Prebuild already completed, skipping..."
  exit 0
fi

# Run the prebuild
run_prebuild
