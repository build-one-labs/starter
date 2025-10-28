#!/bin/bash
# Generate deployment configuration and pull Docker images

# Source common utilities
source "$(dirname "$0")/../common.sh"

log INFO "Generating deployment configuration and pulling images"

# Validate required commands
require_command "build-one" "Install @buildone/swat-cli"
require_command "docker" "Install Docker"

# Generate deployment configuration
log INFO "Generating deployment configuration"
if build-one generate deployment 2>&1 | tee -a "${LOGFILE}"; then
  log SUCCESS "Deployment configuration generated"
else
  log ERROR "Failed to generate deployment configuration"
  exit 1
fi

# Pull Docker images
log INFO "Pulling Docker images (this may take a while...)"
if build-one pull 2>&1 | tee -a "${LOGFILE}"; then
  log SUCCESS "Docker images pulled successfully"
else
  log ERROR "Failed to pull Docker images"
  exit 1
fi