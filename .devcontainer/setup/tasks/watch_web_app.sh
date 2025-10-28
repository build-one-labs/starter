#!/bin/bash
# Watch swat-web_app container logs

# Source common utilities
source "$(dirname "$0")/../common.sh"

log INFO "Watching web-app container logs"

# Validate required commands
require_command "docker" "Install Docker"

# Get container name dynamically
CONTAINER_NAME=$(get_container_name "web-app" ".deploy/workspace.docker-compose.yml" || true)

if [[ -z "$CONTAINER_NAME" ]]; then
  # Fallback: try to find container by name pattern
  log WARN "Could not find container via compose, trying pattern match..."
  CONTAINER_NAME=$(docker ps --filter "name=web-app" --format "{{.Names}}" | head -n1)
fi

if [[ -z "$CONTAINER_NAME" ]]; then
  log ERROR "Could not find web-app container. Is the stack running?"
  log INFO "Run 'docker ps' to see running containers"
  exit 1
fi

log INFO "Following logs for container: $CONTAINER_NAME"
docker logs -f "$CONTAINER_NAME"