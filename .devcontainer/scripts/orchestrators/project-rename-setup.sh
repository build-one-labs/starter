#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Project Rename Setup
# =============================================================================
# This script provides an interactive wizard for renaming the project from
# the template name to the actual project name.
#
# Usage: ./project-rename-setup.sh [--force]
#   --force: Run setup even if previously completed
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source project configuration
source "$SCRIPT_DIR/../lib/project-config.sh"
init_paths

RENAME_COMPLETE_MARKER="${SECRETS_STATE_DIR}/project_rename_complete.marker"

# =============================================================================
# Rename Functions
# =============================================================================

rename_in_file() {
  local file="$1"
  local old_name="$2"
  local new_name="$3"
  local workspace_root="$SECRETS_WORKSPACE_ROOT"
  local full_path="$workspace_root/$file"

  if [ ! -f "$full_path" ]; then
    print_warning "File not found: $file (skipping)"
    return 0
  fi

  # Check if file contains the old name
  if ! grep -q "$old_name" "$full_path" 2>/dev/null; then
    print_info "No changes needed in: $file"
    return 0
  fi

  # Perform the replacement
  if sed -i "s/${old_name}/${new_name}/g" "$full_path"; then
    print_success "Updated: $file"
    return 0
  else
    print_error "Failed to update: $file"
    return 1
  fi
}

prompt_for_project_name() {
  local suggested_name="$1"
  local project_name=""

  echo "" >&2
  echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}" >&2
  echo -e "${COLOR_BOLD}Enter New Project Name${COLOR_NC}" >&2
  echo -e "${COLOR_CYAN}Use lowercase letters, numbers, and hyphens only.${COLOR_NC}" >&2
  echo -e "${COLOR_CYAN}Example: my-awesome-app, client-portal, inventory-system${COLOR_NC}" >&2
  echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_NC}" >&2
  echo "" >&2

  if [ -n "$suggested_name" ]; then
    echo -e "Suggested name: ${COLOR_GREEN}${suggested_name}${COLOR_NC}" >&2
    read -p "Press Enter to use '$suggested_name', or type a different name: " project_name </dev/tty
    if [ -z "$project_name" ]; then
      project_name="$suggested_name"
      print_info "Using suggested name: $project_name" >&2
    fi
  else
    read -p "Project name: " project_name </dev/tty
  fi

  # Validate and re-prompt if needed
  while ! validate_project_name "$project_name"; do
    echo "" >&2
    print_error "Invalid project name: '$project_name'" >&2
    echo -e "${COLOR_YELLOW}Requirements:${COLOR_NC}" >&2
    echo "  • Start with a lowercase letter" >&2
    echo "  • Use only lowercase letters, numbers, and hyphens" >&2
    echo "  • No consecutive hyphens" >&2
    echo "  • End with a letter or number" >&2
    echo "" >&2
    read -p "Project name: " project_name </dev/tty
  done

  echo "$project_name"
}

# =============================================================================
# Main Setup Logic
# =============================================================================

check_prerequisites() {
  print_section "Checking Prerequisites"

  if ! is_codespace; then
    print_error "This script is designed for GitHub Codespaces only."
    print_info "Current environment: ${CODESPACES:-not-set}"
    return 1
  fi
  print_success "Running in GitHub Codespace"

  # Check if sed is available
  if ! command -v sed &> /dev/null; then
    print_error "sed is not installed."
    return 1
  fi
  print_success "Required tools available"

  return 0
}

perform_rename() {
  local new_name="$1"
  local success_count=0
  local fail_count=0

  print_section "Renaming Project"

  echo -e "${COLOR_CYAN}Replacing '${TEMPLATE_PROJECT_NAME}' with '${new_name}' in configuration files...${COLOR_NC}"
  echo ""

  for file in "${PROJECT_NAME_FILES[@]}"; do
    if rename_in_file "$file" "$TEMPLATE_PROJECT_NAME" "$new_name"; then
      ((success_count++))
    else
      ((fail_count++))
    fi
  done

  echo ""
  print_header "Rename Complete"
  print_success "Updated $success_count file(s)"

  if [ $fail_count -gt 0 ]; then
    print_warning "Failed to update $fail_count file(s)"
    return 1
  fi

  return 0
}

show_next_steps() {
  print_section "Next Steps"

  echo -e "${COLOR_CYAN}The project has been renamed in the configuration files.${COLOR_NC}"
  echo ""
  echo -e "${COLOR_BOLD}You may also want to:${COLOR_NC}"
  echo "  1. Update the app title in src/web-app/nuxt.config.ts"
  echo "  2. Update the README.md with your project description"
  echo "  3. Commit the changes to your repository"
  echo ""
  print_info "Run 'git diff' to review the changes."
}

main() {
  local force_setup=false

  while [[ $# -gt 0 ]]; do
    case $1 in
      --force)
        force_setup=true
        shift
        ;;
      *)
        print_error "Unknown option: $1"
        echo "Usage: $0 [--force]"
        exit 1
        ;;
    esac
  done

  print_header "Project Rename Wizard"

  # Check if already completed
  if [ -f "$RENAME_COMPLETE_MARKER" ] && [ "$force_setup" = "false" ]; then
    if ! is_template_project; then
      print_info "Project has already been renamed."
      print_info "Use --force to run setup again."
      exit 0
    fi
  fi

  # Check prerequisites
  if ! check_prerequisites; then
    print_error "Prerequisites check failed. Exiting."
    exit 1
  fi

  # Verify project still needs renaming
  if ! is_template_project; then
    print_success "Project has already been renamed from template."
    touch "$RENAME_COMPLETE_MARKER"
    exit 0
  fi

  # Show what will be changed
  print_section "Project Rename"
  show_project_rename_instructions
  echo ""

  read -p "Press Enter to continue..."

  # Get new project name
  local suggested_name=$(get_suggested_project_name)
  local new_name=$(prompt_for_project_name "$suggested_name")

  echo ""
  echo -e "${COLOR_BOLD}Confirm rename:${COLOR_NC}"
  echo -e "  From: ${COLOR_RED}${TEMPLATE_PROJECT_NAME}${COLOR_NC}"
  echo -e "  To:   ${COLOR_GREEN}${new_name}${COLOR_NC}"
  echo ""

  read -p "Proceed with rename? (Y/n): " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Nn]$ ]]; then
    print_warning "Rename cancelled."
    exit 1
  fi

  # Perform the rename
  if ! perform_rename "$new_name"; then
    print_error "Rename failed."
    exit 1
  fi

  # Mark as complete
  touch "$RENAME_COMPLETE_MARKER"

  # Show next steps
  show_next_steps

  print_success "Project rename completed successfully!"
}

main "$@"
