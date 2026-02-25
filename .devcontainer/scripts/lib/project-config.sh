#!/usr/bin/env bash
# =============================================================================
# Project Configuration
# =============================================================================
# Central definition for project rename detection and configuration.
# Source this file from any script that needs to check or rename the project.
# =============================================================================

# Source common utilities from swat-cli (colors, print functions, secrets helpers)
_WORKSPACE_ROOT_PROJECT_CONFIG="${WORKSPACE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
source "${_WORKSPACE_ROOT_PROJECT_CONFIG}/node_modules/@buildone/swat-cli/scripts/devcontainer/lib/secrets-config.sh"

# =============================================================================
# Project Name Detection
# =============================================================================

# The template project name that should be replaced
readonly TEMPLATE_PROJECT_NAME="starter"

# Files that contain the project name and need to be updated
readonly PROJECT_NAME_FILES=(
  "package.json"
  ".deploy/standalone.deployment.config.json"
  ".build/deploy/standalone.deployment.config.json"
  ".circleci/config.yml"
)

# Check if this is the original starter repository (not a fork)
is_original_starter_repo() {
  local repo_name=""

  # Get repo name from GITHUB_REPOSITORY (available in Codespaces)
  if [ -n "${GITHUB_REPOSITORY:-}" ]; then
    repo_name=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)
  else
    # Fall back to git remote
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$remote_url" ]; then
      repo_name=$(basename "$remote_url" .git)
    fi
  fi

  # If the repo is named "starter", this is the original template
  [ "$repo_name" = "$TEMPLATE_PROJECT_NAME" ]
}

# Check if project is a fork that still has template name and needs renaming
is_template_project() {
  # Don't prompt on the original starter repo
  if is_original_starter_repo; then
    return 1  # false - no rename needed
  fi

  local workspace_root="${SECRETS_WORKSPACE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}"

  # Check if package.json contains the template name in repository URL
  if [ -f "$workspace_root/package.json" ]; then
    if grep -q "/${TEMPLATE_PROJECT_NAME}\.git" "$workspace_root/package.json" 2>/dev/null; then
      return 0  # true - still template
    fi
    if grep -q "/${TEMPLATE_PROJECT_NAME}\"" "$workspace_root/package.json" 2>/dev/null; then
      return 0  # true - still template
    fi
  fi

  # Check CircleCI config for template app name
  if [ -f "$workspace_root/.circleci/config.yml" ]; then
    if grep -q "\"app-name\":\"${TEMPLATE_PROJECT_NAME}\"" "$workspace_root/.circleci/config.yml" 2>/dev/null; then
      return 0  # true - still template
    fi
  fi

  return 1  # false - already renamed
}

# Get the current repository name from git remote or GITHUB_REPOSITORY
get_suggested_project_name() {
  local suggested_name=""

  # Try GITHUB_REPOSITORY first (available in Codespaces)
  if [ -n "${GITHUB_REPOSITORY:-}" ]; then
    suggested_name=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)
  else
    # Fall back to git remote
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$remote_url" ]; then
      # Extract repo name from URL (handles both HTTPS and SSH)
      suggested_name=$(basename "$remote_url" .git)
    fi
  fi

  # Don't suggest "starter" as the new name
  if [ "$suggested_name" = "$TEMPLATE_PROJECT_NAME" ]; then
    suggested_name=""
  fi

  echo "$suggested_name"
}

# Validate project name (lowercase, alphanumeric, hyphens)
validate_project_name() {
  local name="$1"

  # Check not empty
  if [ -z "$name" ]; then
    return 1
  fi

  # Check format: lowercase letters, numbers, hyphens only
  if [[ ! "$name" =~ ^[a-z][a-z0-9-]*[a-z0-9]$ ]] && [[ ! "$name" =~ ^[a-z]$ ]]; then
    return 1
  fi

  # Check no consecutive hyphens
  if [[ "$name" =~ -- ]]; then
    return 1
  fi

  return 0
}

# =============================================================================
# Instructions
# =============================================================================
show_project_rename_instructions() {
  echo -e "${SECRETS_COLOR_BOLD}${SECRETS_COLOR_YELLOW}This repository was forked from the Build.One Starter template.${SECRETS_COLOR_NC}"
  echo ""
  echo -e "${SECRETS_COLOR_CYAN}The project name 'starter' appears in several configuration files${SECRETS_COLOR_NC}"
  echo -e "${SECRETS_COLOR_CYAN}and should be replaced with your project's actual name.${SECRETS_COLOR_NC}"
  echo ""
  echo -e "${SECRETS_COLOR_BOLD}Files that will be updated:${SECRETS_COLOR_NC}"
  for file in "${PROJECT_NAME_FILES[@]}"; do
    echo "  • $file"
  done
}
