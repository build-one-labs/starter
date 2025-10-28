#!/bin/bash
# Install VSCode extensions

# Source common utilities
source "$(dirname "$0")/../common.sh"

log INFO "Installing VSCode extensions"

# Validate required commands
require_command "build-one" "Install @buildone/swat-cli"

# Generate deployment configuration
log INFO "Generating deployment configuration"
if build-one extension 2>&1 | tee -a "${LOGFILE}"; then
  log SUCCESS "Deployment configuration generated"
else
  log ERROR "Failed to generate deployment configuration"
  exit 1
fi