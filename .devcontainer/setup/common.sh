#!/bin/bash
# Common utilities for devcontainer setup scripts
# Source this file at the beginning of each setup script

# Strict error handling
set -euo pipefail

# Colors for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Workspace root validation
if [[ -z "${WORKSPACE_ROOT:-}" ]]; then
  echo -e "${COLOR_RED}ERROR: WORKSPACE_ROOT environment variable is not set${COLOR_RESET}" >&2
  exit 1
fi

# Ensure tmp directory exists
mkdir -p "${WORKSPACE_ROOT}/tmp"

# Log file location
readonly LOGFILE="${WORKSPACE_ROOT}/tmp/install.log"

# Ensure PATH includes node_modules/.bin
export PATH="${PATH}:${WORKSPACE_ROOT}/node_modules/.bin"

# Function: Log message with timestamp
log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  case "$level" in
    INFO)
      echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} ${timestamp} - ${message}" | tee -a "$LOGFILE"
      ;;
    SUCCESS)
      echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} ${timestamp} - ${message}" | tee -a "$LOGFILE"
      ;;
    WARN)
      echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} ${timestamp} - ${message}" | tee -a "$LOGFILE" >&2
      ;;
    ERROR)
      echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} ${timestamp} - ${message}" | tee -a "$LOGFILE" >&2
      ;;
    *)
      echo "${timestamp} - ${level} ${message}" | tee -a "$LOGFILE"
      ;;
  esac
}

# Function: Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function: Require command to exist
require_command() {
  local cmd="$1"
  local install_hint="${2:-}"

  if ! command_exists "$cmd"; then
    log ERROR "Required command '$cmd' not found"
    if [[ -n "$install_hint" ]]; then
      log INFO "Install hint: $install_hint"
    fi
    exit 1
  fi
}

# Function: Validate required commands
validate_environment() {
  local required_commands=("$@")
  local missing_commands=()

  for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
      missing_commands+=("$cmd")
    fi
  done

  if [[ ${#missing_commands[@]} -gt 0 ]]; then
    log ERROR "Missing required commands: ${missing_commands[*]}"
    return 1
  fi

  return 0
}

# Function: Safe cleanup on error
cleanup_on_error() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log ERROR "Script failed with exit code $exit_code"
    # Add any cleanup logic here
  fi
}

# Register cleanup trap
trap cleanup_on_error EXIT

# Function: Remove directory safely
safe_remove() {
  local dir="$1"

  if [[ -z "$dir" ]] || [[ "$dir" == "/" ]]; then
    log ERROR "Refusing to remove invalid directory: '$dir'"
    return 1
  fi

  if [[ -d "$dir" ]]; then
    log INFO "Removing directory: $dir"
    sudo rm -rf "$dir"
  else
    log INFO "Directory does not exist, skipping: $dir"
  fi
}

# Function: Run yarn workspace command with logging
yarn_workspace() {
  local workspace="$1"
  shift
  local cmd=("$@")

  log INFO "Running 'yarn workspace $workspace ${cmd[*]}'"
  yarn workspace "$workspace" "${cmd[@]}" 2>&1 | tee -a "$LOGFILE"
  local result=${PIPESTATUS[0]}

  if [[ $result -eq 0 ]]; then
    log SUCCESS "Completed 'yarn workspace $workspace ${cmd[*]}'"
  else
    log ERROR "Failed 'yarn workspace $workspace ${cmd[*]}' (exit code: $result)"
    return $result
  fi
}
# Function: Get Docker container name by service
get_container_name() {
  local service="$1"
  local compose_file="${2:-.deploy/workspace.docker-compose.yml}"

  if [[ ! -f "$compose_file" ]]; then
    log WARN "Docker compose file not found: $compose_file"
    return 1
  fi

  # Try to get container name from docker compose
  local container_name
  container_name=$(docker compose -f "$compose_file" ps -q "$service" 2>/dev/null | head -n1)

  if [[ -n "$container_name" ]]; then
    docker inspect --format '{{.Name}}' "$container_name" | sed 's/^\///'
  else
    log WARN "Could not find container for service: $service"
    return 1
  fi
}

# Function: Check if running in devcontainer
is_devcontainer() {
  [[ "${REMOTE_CONTAINERS:-}" == "true" ]] || [[ -n "${CODESPACES:-}" ]]
}

# Export functions for use in other scripts
export -f log
export -f command_exists
export -f require_command
export -f validate_environment
export -f cleanup_on_error
export -f safe_remove
export -f yarn_workspace
export -f get_container_name
export -f is_devcontainer