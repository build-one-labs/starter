#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${WORKSPACE_ROOT}/tmp/locks"
mkdir -p "$STATE_DIR"

PREBUILD_NEEDED_MARKER="$STATE_DIR/prebuild_needed.marker"
UPDATE_INFO_FILE="$STATE_DIR/update_info.txt"

# Check if prebuild is needed (marker left by check_updates.sh)
if [ ! -f "$PREBUILD_NEEDED_MARKER" ]; then
  echo "[INFO] No updates detected, prebuild not needed"
  exit 0
fi

echo "[INFO] Updates detected, prebuild required"
if [ -f "$UPDATE_INFO_FILE" ]; then
  cat "$UPDATE_INFO_FILE"
fi

# Rerun prebuild tasks
echo "[INFO] Running prebuild tasks for updated code..."

# Source the task runner to get lock/done file paths
source "$SCRIPT_DIR/run_task.sh"

# Remove done file and lock file to allow prebuild to run again
rm -f "$DONE_FILE"
rm -f "$LOCK_FILE"

# Call the prebuild script
"$SCRIPT_DIR/prebuild.sh"

# Remove the marker after successful prebuild
rm -f "$PREBUILD_NEEDED_MARKER" "$UPDATE_INFO_FILE"
echo "[INFO] Prebuild completed successfully"
