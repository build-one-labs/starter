#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(git rev-parse --show-toplevel)}"
export WORKSPACE_ROOT

# Ensure packages are installed before running prebuild
# Skip install during prebuild check (triggered at stack startup) - will be installed by dedicated task
if [[ "${PREBUILD_CHECK:-}" != "true" ]]; then
    cd "${WORKSPACE_ROOT}"
    
    echo "[INFO] Installing packages..."
    yarn install

    echo "[INFO] Clearing yarn cache..."
    yarn cache clear
else
    echo "[INFO] Skipping package install during prebuild check"
fi

# Ensure the workspace scripts are executable
find "${WORKSPACE_ROOT}/node_modules/@buildone/swat-cli/scripts/devcontainer" -type f -name "*.sh" -exec chmod +x {} \;

# Now call the actual prebuild script from the installed package
exec "${WORKSPACE_ROOT}/node_modules/@buildone/swat-cli/scripts/devcontainer/orchestrators/prebuild.sh" "$@"