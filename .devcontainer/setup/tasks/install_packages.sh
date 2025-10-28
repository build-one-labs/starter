#!/bin/bash
# Install monorepo packages and clean old artifacts

# Source common utilities
source "$(dirname "$0")/../common.sh"

log INFO "Starting package installation"

# Validate required commands
require_command "yarn" "Install Node.js and yarn"

# Install monorepo packages
log INFO "Installing monorepo packages (this may take a while...)"
if yarn 2>&1 | tee -a "$LOGFILE"; then
  log SUCCESS "Monorepo packages installed successfully"
else
  log ERROR "Failed to install monorepo packages"
  exit 1
fi

# Clear yarn cache
log INFO "Clearing yarn cache..."
yarn cache clear

log SUCCESS "Package installation completed"
