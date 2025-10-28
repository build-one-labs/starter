#!/bin/bash
# Import data and workflows into the database

# Source common utilities
source "$(dirname "$0")/../common.sh"

# Validate required commands
require_command "b1" "Install @buildone/swat-cli or check PATH"

# Wait for stack
log INFO "Waiting for stack to be operational"
if b1 wait-for-stack 2>&1 | tee -a "$LOGFILE"; then
  log SUCCESS "Stack is up and running"
else
  log ERROR "Stack timeout"
  exit 1
fi

# Run Postgres import
log INFO "Running Postgres import"
if b1 import-vanguard true 2>&1 | tee -a "$LOGFILE"; then
  log SUCCESS "Postgres import completed"
else
  log ERROR "Postgres import failed"
  exit 1
fi

# Import automation workflows
log INFO "Importing automation workflows"
if b1 import-automation workflows 2>&1 | tee -a "$LOGFILE"; then
  log SUCCESS "Automation workflows imported"
else
  log ERROR "Automation workflows import failed"
  exit 1
fi

log SUCCESS "All data import tasks completed successfully"

