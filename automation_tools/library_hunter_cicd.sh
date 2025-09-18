#!/bin/bash

# RetroDECK Library Hunter - CI/CD Script
# This script analyzes component binaries for library dependencies
# and updates component_libs.json files in the components repository

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RETRODECK_REPO_DIR="${RETRODECK_REPO_DIR:-$(dirname "$SCRIPT_DIR")}"
COMPONENTS_REPO_DIR="${COMPONENTS_REPO_DIR:-$HOME/temp-components}"
FLATPAK_DIR="${FLATPAK_DIR:-$HOME/.local/share/flatpak/app/net.retrodeck.retrodeck/current/active/retrodeck/components}"

# Import RetroDECK logging system
source "$SCRIPT_DIR/../functions/logger.sh" || {
    echo "Error: Cannot source logger.sh from $SCRIPT_DIR/../functions/logger.sh"
    exit 1
}

# Configure logging
rd_logging_level="${RD_LOGGING_LEVEL:-info}"
rd_xdg_config_logs_path="${RD_XDG_CONFIG_LOGS_PATH:-$HOME}"

# Function to extract exec command from component launcher
extract_exec_command() {
    local launcher_script="$1"
    local component_path="$2"
    
    if [ ! -f "$launcher_script" ]; then
        log e "Launcher script not found: $launcher_script"
        return 1
    fi
    
    # Extract exec command from launcher script
    local exec_command
    exec_command=$(grep -E "^exec " "$launcher_script" | head -n 1)
    
    if [ -z "$exec_command" ]; then
        log w "No exec command found in $launcher_script"
        return 1
    fi
    
    log d "Found exec command: $exec_command"
    
    # Extract binary path from exec command and expand variables
    # Replace $component_path with actual path
    local binary_path
    binary_path=$(echo "$exec_command" | sed "s|^exec ||" | sed "s|\$component_path|$component_path|g" | cut -d' ' -f1)
    binary_path=$(eval echo "$binary_path")  # Expand any remaining variables
    
    echo "$binary_path"
}

# Function to process a single component
process_component() {
    local launcher_script="$1"
    local component_dir component_name component_path binary_path
    
    # Extract component information
    component_dir=$(dirname "$launcher_script")
    component_name=$(basename "$component_dir")
    component_path="$component_dir"
    
    log i "Processing component: $component_name"
    log d "  Launcher script: $launcher_script"
    log d "  Component path: $component_path"
    
    # Extract binary path
    if ! binary_path=$(extract_exec_command "$launcher_script" "$component_path"); then
        return 1
    fi
    
    log d "  Binary path: $binary_path"
    
    # Check if binary exists
    if [ ! -f "$binary_path" ]; then
        log w "Binary not found: $binary_path"
        return 1
    fi
    
    # Check if component directory exists in components repo
    local components_component_dir="$COMPONENTS_REPO_DIR/$component_name"
    if [ ! -d "$components_component_dir" ]; then
        log w "Component directory not found in components repo: $components_component_dir"
        return 1
    fi
    
    # Change to component directory in components repo
    cd "$components_component_dir"
    log d "  Working in: $(pwd)"
    
    # Run hunt_libraries.sh with the binary path
    local hunt_script="$RETRODECK_REPO_DIR/developer_toolbox/hunt_libraries.sh"
    if [ ! -f "$hunt_script" ]; then
        log e "hunt_libraries.sh not found: $hunt_script"
        return 1
    fi
    
    log i "  Running hunt_libraries.sh for binary: $binary_path"
    
    # Run the hunt script and capture its output
    if /bin/bash "$hunt_script" "$binary_path" 2>&1 | log d; then
        log i "  Library hunting completed successfully for $component_name"
        
        # Check if component_libs.json was created/updated
        if [ -f "component_libs.json" ]; then
            log i "  component_libs.json updated for $component_name"
            return 0  # Success - component was updated
        else
            log d "  No component_libs.json created for $component_name"
            return 2  # No update needed
        fi
    else
        log w "hunt_libraries.sh failed for $component_name"
        return 1  # Error
    fi
}

# Function to commit changes for a component
commit_component_changes() {
    local component_name="$1"
    local components_component_dir="$COMPONENTS_REPO_DIR/$component_name"
    
    cd "$components_component_dir"
    
    # Check if there are changes to commit
    if git diff --quiet && git diff --staged --quiet; then
        log d "No changes to commit for $component_name"
        return 1
    fi
    
    # Add and commit changes
    git add component_libs.json
    git commit -m "chore($component_name): updated library listing component_libs.json for $component_name [AUTOMATED]"
    
    log i "Committed changes for $component_name"
    return 0
}

# Main function
main() {
    local components_updated=0
    local components_processed=0
    local components_failed=0
    
    log i "Starting Library Hunter..."
    log i "RetroDECK repo: $RETRODECK_REPO_DIR"
    log i "Components repo: $COMPONENTS_REPO_DIR"
    log i "Flatpak directory: $FLATPAK_DIR"
    
    # Validate directories
    if [ ! -d "$FLATPAK_DIR" ]; then
        log e "Flatpak components directory not found: $FLATPAK_DIR"
        exit 1
    fi
    
    if [ ! -d "$RETRODECK_REPO_DIR" ]; then
        log e "RetroDECK repository directory not found: $RETRODECK_REPO_DIR"
        exit 1
    fi
    
    if [ ! -d "$COMPONENTS_REPO_DIR" ]; then
        log e "Components repository directory not found: $COMPONENTS_REPO_DIR"
        exit 1
    fi
    
    log i "Searching for component launchers in: $FLATPAK_DIR"
    
    # Configure git for components repo
    cd "$COMPONENTS_REPO_DIR"
    git config --global user.name "RetroDECK Library Hunter"
    git config --global user.email "retrodeck@retrodeck.net"
    
    # Iterate through all component launcher scripts
    for launcher_script in "$FLATPAK_DIR"/*/component_launcher.sh; do
        if [ ! -f "$launcher_script" ]; then
            log d "Skipping non-existent launcher: $launcher_script"
            continue
        fi
        
        components_processed=$((components_processed + 1))
        
        # Process component
        local result=0
        process_component "$launcher_script" || result=$?
        
        case $result in
            0)
                # Component was updated successfully
                component_name=$(basename "$(dirname "$launcher_script")")
                if commit_component_changes "$component_name"; then
                    components_updated=$((components_updated + 1))
                fi
                ;;
            1)
                # Error occurred
                components_failed=$((components_failed + 1))
                ;;
            2)
                # No update needed
                log d "No update needed for component"
                ;;
        esac
        
        log d "Completed processing component"
    done
    
    # Summary
    log i "Library hunting completed."
    log i "Components processed: $components_processed"
    log i "Components updated: $components_updated"
    log i "Components failed: $components_failed"
    
    # Export results for CI/CD systems
    echo "COMPONENTS_PROCESSED=$components_processed"
    echo "COMPONENTS_UPDATED=$components_updated"
    echo "COMPONENTS_FAILED=$components_failed"
    
    # Exit with appropriate code
    if [ "$components_failed" -gt 0 ]; then
        log w "Some components failed processing"
        exit 2  # Warning
    elif [ "$components_updated" -eq 0 ]; then
        log i "No components needed updates"
        exit 0  # Success, no updates
    else
        log i "Successfully updated $components_updated components"
        exit 0  # Success with updates
    fi
}

# Function to create PR (platform-agnostic preparation)
prepare_pr_changes() {
    cd "$COMPONENTS_REPO_DIR"
    
    # Check if there are any changes
    if git diff --quiet && git diff --staged --quiet; then
        log i "No changes detected in components repository"
        echo "PR_NEEDED=false"
        return 1
    fi
    
    # Create branch name
    local branch_name="automated/library-hunter-$(date +%Y%m%d-%H%M%S)"
    log i "Creating branch: $branch_name"
    
    # Create and switch to new branch
    git checkout -b "$branch_name"
    
    # Export branch name for CI/CD systems
    echo "PR_BRANCH=$branch_name"
    echo "PR_NEEDED=true"
    
    return 0
}

# Function to cleanup
cleanup() {
    log i "Cleaning up temporary directories..."
    rm -rf temp-retrodeck temp-components || true
    log i "Cleanup completed"
}

# Help function
show_help() {
    cat << EOF
RetroDECK Library Hunter - CI/CD Script

Usage: $0 [OPTIONS] [COMMAND]

Commands:
    hunt        Run the library hunting process (default)
    prepare-pr  Prepare changes for PR creation
    cleanup     Clean up temporary directories
    help        Show this help message

Options:
    --retrodeck-repo DIR    RetroDECK repository directory (default: script parent directory)
    --components-repo DIR   Components repository directory (default: $HOME/temp-components)
    --flatpak-dir DIR       Flatpak installation directory (default: ~/.local/share/flatpak/app/net.retrodeck.retrodeck/current/active/retrodeck/components)

Environment Variables:
    RETRODECK_REPO_DIR      Override RetroDECK repository directory
    COMPONENTS_REPO_DIR     Override components repository directory
    FLATPAK_DIR             Override flatpak directory
    RD_LOGGING_LEVEL        Set logging level (debug, info, warn, error, none)
    RD_XDG_CONFIG_LOGS_PATH Override log directory path

Examples:
    $0                      # Run library hunting with default settings
    $0 hunt                 # Same as above
    $0 prepare-pr           # Prepare PR after hunting
    $0 cleanup              # Clean up temporary files
    RD_LOGGING_LEVEL=debug $0 hunt    # Run with debug logging

EOF
}

# Parse command line arguments
COMMAND="hunt"
while [[ $# -gt 0 ]]; do
    case $1 in
        --retrodeck-repo)
            RETRODECK_REPO_DIR="$2"
            shift 2
            ;;
        --components-repo)
            COMPONENTS_REPO_DIR="$2"
            shift 2
            ;;
        --flatpak-dir)
            FLATPAK_DIR="$2"
            shift 2
            ;;
        hunt|prepare-pr|cleanup|help)
            COMMAND="$1"
            shift
            ;;
        -h|--help)
            COMMAND="help"
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

# Execute command
case $COMMAND in
    hunt)
        main
        ;;
    prepare-pr)
        prepare_pr_changes
        ;;
    cleanup)
        cleanup
        ;;
    help)
        show_help
        ;;
    *)
        echo "Unknown command: $COMMAND" >&2
        echo "Use --help for usage information" >&2
        exit 1
        ;;
esac
