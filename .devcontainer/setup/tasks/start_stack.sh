#!/bin/bash
# Start the development stack using build-one

# Source common utilities
source "$(dirname "$0")/../common.sh"

log INFO "Starting development stack"

# Validate required commands
require_command "build-one" "Install @buildone/swat-cli"

# Start the stack
log INFO "Running 'build-one up' (this may take a while...)"
if build-one up 2>&1 | tee -a "${LOGFILE}"; then
  log SUCCESS "Development stack started successfully"
else
  log ERROR "Failed to start development stack"
  exit 1
fi

