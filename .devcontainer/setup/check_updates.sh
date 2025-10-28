#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Checking for updates on branch..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${WORKSPACE_ROOT}/tmp/locks"
mkdir -p "$STATE_DIR"

PREBUILD_NEEDED_MARKER="$STATE_DIR/prebuild_needed.marker"
UPDATE_INFO_FILE="$STATE_DIR/update_info.txt"

# Get current commit
CURRENT_COMMIT=$(git rev-parse HEAD)

# Fetch latest from remote
git fetch --prune

# Get latest commit on current branch
BRANCH=$(git branch --show-current)
LATEST_COMMIT=$(git rev-parse origin/"$BRANCH")

if [ "$CURRENT_COMMIT" = "$LATEST_COMMIT" ]; then
  echo "[INFO] Already on latest commit ($CURRENT_COMMIT)"
  rm -f "$PREBUILD_NEEDED_MARKER" "$UPDATE_INFO_FILE"
  exit 0
fi

echo "[INFO] New commits detected!"
echo "[INFO] Current: $CURRENT_COMMIT"
echo "[INFO] Latest:  $LATEST_COMMIT"

# Pull latest changes
echo "[INFO] Pulling latest changes..."
git pull --ff-only

# Leave marker for prebuild_check task
touch "$PREBUILD_NEEDED_MARKER"
cat > "$UPDATE_INFO_FILE" <<EOF
Previous commit: $CURRENT_COMMIT
Updated to: $LATEST_COMMIT
Branch: $BRANCH
EOF

echo "[INFO] Update marker created for prebuild_check task"
