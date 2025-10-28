#!/usr/bin/env bash
set -euo pipefail

# Check if running in devcontainer
if [ "${REMOTE_CONTAINERS:-}" != "true" ] && [ -z "${CODESPACES:-}" ]; then
  echo "[INFO] Not running in devcontainer, skipping setup..."
  exit 0
fi

STATE_DIR="${WORKSPACE_ROOT}/tmp"
LOCK_FILE="$STATE_DIR/leader.lock"
DONE_FILE="$STATE_DIR/all.done"

mkdir -p "$STATE_DIR"

# Dependency graph: task -> array of dependencies
declare -A DEPS

# Prebuild tasks
DEPS[install_packages]=""
DEPS[pull_stack]=""

# Runtime tasks
DEPS[start_stack]="pull_stack"
DEPS[install_extensions]="install_packages"
DEPS[watch_app_server_ts]="start_stack"
DEPS[import_data]="start_stack"
DEPS[watch_web_app]="start_stack"

# Tasks that should always restart (never use done markers)
declare -A ALWAYS_RUN
ALWAYS_RUN[watch_app_server_ts]=1
ALWAYS_RUN[watch_web_app]=1

run_task() {
  local task=$1
  local force=${2:-false}  # Optional force parameter
  local done_marker="$STATE_DIR/${task}.done"
  local task_lock="$STATE_DIR/${task}.lock"
  
  # Check if this task should always run
  if [ "${ALWAYS_RUN[$task]:-0}" = "1" ]; then
    force=true
  fi
  
  # If force mode, clear existing locks and done markers
  if [ "$force" = "true" ]; then
    echo "[INFO] $task: force mode, clearing locks and done markers..."
    rm -f "$task_lock" "$done_marker"
  fi
  
  # Check if already done (skip in force mode)
  if [ "$force" != "true" ] && [ -f "$done_marker" ]; then
    return 0
  fi
  
  # Try to acquire task lock
  (
    if [ "$force" != "true" ]; then
      flock -n 200 || {
        # Another process is running this task, wait for it
        echo "[INFO] $task already running, waiting..."
        flock 200  # wait for lock (blocking)
        
        # Wait for done marker to appear
        local timeout=60
        local elapsed=0
        while [ ! -f "$done_marker" ] && [ $elapsed -lt $timeout ]; do
          sleep 1
          elapsed=$((elapsed + 1))
        done
        
        if [ -f "$done_marker" ]; then
          return 0
        fi
        
        echo "[ERROR] $task finished but no done marker found after ${timeout}s"
        return 1
      }
      
      # Check again after acquiring lock (maybe it completed while we waited)
      [ -f "$done_marker" ] && return 0
    else
      # In force mode, acquire lock without checking
      flock -n 200 || {
        echo "[INFO] $task: force mode, killing existing lock..."
        # Lock is held, but we're forcing, so just proceed
        flock 200
      }
    fi
    
    # Run dependencies first (not in force mode for dependencies)
    local deps="${DEPS[$task]:-}"
    for dep in $deps; do
      # Run the dependency and wait for it to complete
      if ! run_task "$dep" false; then
        echo "[ERROR] $task: dependency $dep failed"
        return 1
      fi
      
      # Wait for dependency's done marker to appear
      local timeout=60
      local elapsed=0
      while [ ! -f "$STATE_DIR/${dep}.done" ] && [ $elapsed -lt $timeout ]; do
        echo "[INFO] $task: waiting for $dep to complete..."
        sleep 1
        elapsed=$((elapsed + 1))
      done
      
      if [ ! -f "$STATE_DIR/${dep}.done" ]; then
        echo "[ERROR] $task: dependency $dep timed out waiting for completion"
        return 1
      fi
    done
    
    # Run the task
    echo "[INFO] $task started ..."
    if "./.devcontainer/setup/tasks/${task}.sh"; then
      sync  # Force filesystem sync
      echo "[INFO] $task complete"
      
      # Only create done marker if not in always-run mode
      if [ "${ALWAYS_RUN[$task]:-0}" != "1" ]; then
        touch "$done_marker"
      fi
    else
      echo "[ERROR] $task failed"
      return 1
    fi
    
  ) 200>"$task_lock"
}

# Only run main logic if script is executed (not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  # If called with a specific task name, run just that task
  if [ $# -gt 0 ]; then
    TASK_NAME="$1"
    FORCE_MODE=false

    # Check for --force flag
    if [ "$#" -gt 1 ] && [ "$2" = "--force" ]; then
      FORCE_MODE=true
    fi

    echo "[INFO] Running task: $TASK_NAME $([ "$FORCE_MODE" = "true" ] && echo "(force mode)")"
    run_task "$TASK_NAME" "$FORCE_MODE"
  else
    echo "[ERROR] No task name provided. Please specify a task to run."
    echo "[INFO] Prebuild tasks should be run via prebuild.sh"
    exit 1
  fi
fi