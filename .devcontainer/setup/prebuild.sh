#!/usr/bin/env bash
set -euo pipefail

# Check if running in devcontainer
if [ "${REMOTE_CONTAINERS:-}" != "true" ] && [ -z "${CODESPACES:-}" ]; then
  echo "[INFO] Not running in devcontainer, skipping prebuild..."
  exit 0
fi

# Source the task runner to use run_task function and shared state
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/run_task.sh"

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

    run_task install_packages
    run_task pull_stack

    wait

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
