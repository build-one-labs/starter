#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(git rev-parse --show-toplevel)}"
export WORKSPACE_ROOT

# =============================================================================
# Codespace Secrets Check
# =============================================================================
# In GitHub Codespaces, check if required secrets are configured.
# If missing, skip the prebuild entirely - the secrets setup wizard will run
# during postAttach to guide the user through configuration.
# =============================================================================

# Source secrets configuration from swat-cli (available after yarn install)
SECRETS_CONFIG="${WORKSPACE_ROOT}/node_modules/@buildone/swat-cli/scripts/devcontainer/lib/secrets-config.sh"
if [ -f "$SECRETS_CONFIG" ]; then
    source "$SECRETS_CONFIG"
    secrets_init_paths

    if secrets_is_codespace; then
        missing_secrets=()
        secrets_get_missing missing_secrets

        if [ ${#missing_secrets[@]} -gt 0 ]; then
            echo ""
            echo "============================================================================="
            echo "  CODESPACE SECRETS NOT CONFIGURED"
            echo "============================================================================="
            echo ""
            echo "  Missing ${#missing_secrets[@]} required secret(s):"
            for secret in "${missing_secrets[@]}"; do
                echo "    - $secret"
            done
            echo ""
            echo "  Skipping prebuild. The secrets setup wizard will run when you attach."
            echo "============================================================================="
            echo ""
            exit 0
        fi

        echo "[INFO] All required secrets are configured, proceeding with prebuild..."
    fi
fi

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