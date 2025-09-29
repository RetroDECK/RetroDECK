#!/bin/bash

# RetroDECK Library Hunter
# This script helps determine which libraries for a component do not exist in the base flatpak and need to be included in some way.
# The script will identify the dependencies of the given binary via objdump, then generate a JSON file containing the libraries that must be found.
#
# Optionally a Qt version (-q) can be supplied which will be included in the library JSON object for future reference and processing, if a Qt version cannot be otherwise automatically determined.
# A path (-p) to the libraries (such as ones included in an AppImage) can also optionally be specified for future reference and processing.
# A path (-o) for the subsequent output file can also optionally be supplied, otherwise the file will be output into the directory from which the script was run.
# USAGE: hunt_libraries.sh [-qpo] /path/to/binary
#
# MODES:
# 1. Manual mode (default): Analyze a single binary and generate component_libs.json
# 2. CI/CD mode (--cicd): Automatically process all components and commit changes
#
# USAGE: 
#   Manual: hunt_libraries.sh [-qpo] /path/to/binary
#   CI/CD:  hunt_libraries.sh --cicd [hunt]
#
# OPTIONS:
#   -q, --qt-version   Qt version for Qt libraries
#   -p, --path         Path to search for libraries  
#   -o, --output       Output file path
#   --cicd             Enable CI/CD mode for automated processing
#
# NOTE: The script should be run OUTSIDE of the Flatpak environment, and it will search through any installed Flatpak runtimes, so you should have a semi-similar environment to the build environment for best accuracy.

# Default configuration
flatpak_runtimes_root="/var/lib/flatpak/runtime"
flatpak_user_runtimes_root="$HOME/.local/share/flatpak/runtime"
flatpak_freedesktop_runtime_root="$flatpak_runtimes_root/org.freedesktop.Platform"
flatpak_kde_runtime_root="$flatpak_runtimes_root/org.kde.Platform"
flatpak_user_freedesktop_runtime_root="$flatpak_user_runtimes_root/org.freedesktop.Platform"
flatpak_user_kde_runtime_root="$flatpak_user_runtimes_root/org.kde.Platform"

component_libs_file="./component_libs.json"
component_libs='[]'

fallback_runtime_version="24.08"

# Extract runtime version from RetroDECK manifest
MANIFEST_PATH="$RETRODECK_REPO_DIR/net.retrodeck.retrodeck.yml"
if [ -f "$MANIFEST_PATH" ]; then
    retrodeck_runtime_version=$(grep '^runtime-version:' "$MANIFEST_PATH" | sed "s/runtime-version: *['\"]*\([^'\"]*\)['\"]*$/\1/")
    if [ -z "$retrodeck_runtime_version" ]; then
        if [ "$cicd_mode" = true ]; then
            log w "MAIN" "Failed to extract runtime version from manifest, using fallback: $fallback_runtime_version"
        else
            echo "Warning: Failed to extract runtime version from manifest, using fallback: $fallback_runtime_version" >&2
        fi
        retrodeck_runtime_version="$fallback_runtime_version"
    fi
else
    # Fallback to hardcoded version if manifest not found
    if [ "$cicd_mode" = true ]; then
        log w "MAIN" "Manifest not found at $MANIFEST_PATH, using fallback runtime version: $fallback_runtime_version"
    else
        echo "Warning: Manifest not found at $MANIFEST_PATH, using fallback runtime version: $fallback_runtime_version" >&2
    fi
    retrodeck_runtime_version="$fallback_runtime_version"
fi

# Update these variables over time as needed  
latest_kde5_runtime_version="5.15-$retrodeck_runtime_version"
latest_kde6_runtime_version="6.9"

# CI/CD mode variables
cicd_mode=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RETRODECK_REPO_DIR="${RETRODECK_REPO_DIR:-$(dirname "$SCRIPT_DIR")}"
COMPONENTS_REPO_DIR="${COMPONENTS_REPO_DIR:-$HOME/temp-components}"
FLATPAK_DIR="${FLATPAK_DIR:-$HOME/.local/share/flatpak/app/net.retrodeck.retrodeck/current/active/files/retrodeck/components}"

# CI/CD counters
components_processed=0
components_updated=0
components_failed=0

# Logging function for CI/CD mode
log() {
    if [ "$cicd_mode" = true ]; then
        local level="$1"
        local component="${2:-MAIN}"
        local message="$3"
        
        case "$level" in
            i|info)  echo "[INFO] [$component] $message" ;;
            d|debug) echo "[DEBUG] [$component] $message" ;;
            w|warn)  echo "[WARN] [$component] $message" ;;
            e|error) echo "[ERROR] [$component] $message" ;;
        esac
    fi
}

# Simple logging for manual mode
log_manual() {
    echo "$@"
}

# Helper function to search for libraries in both system and user runtime paths
search_flatpak_runtimes() {
  local search_pattern="$1"
  local result=""
  
  # First try system runtime path
  if [[ -d "$flatpak_runtimes_root" ]]; then
    result=$(find "$flatpak_runtimes_root" -name "$search_pattern" 2>/dev/null)
  fi
  
  # If not found or system path doesn't exist, try user runtime path
  if [[ -z "$result" && -d "$flatpak_user_runtimes_root" ]]; then
    result=$(find "$flatpak_user_runtimes_root" -name "$search_pattern" 2>/dev/null)
  fi
  
  echo "$result"
}

# Helper function to get the correct runtime path (system or user)
get_runtime_path() {
  if [[ -d "$flatpak_runtimes_root" ]]; then
    echo "$flatpak_runtimes_root"
  elif [[ -d "$flatpak_user_runtimes_root" ]]; then
    echo "$flatpak_user_runtimes_root"
  else
    echo ""
  fi
}

# Helper function to get the correct freedesktop runtime path
get_freedesktop_runtime_path() {
  if [[ -d "$flatpak_freedesktop_runtime_root" ]]; then
    echo "$flatpak_freedesktop_runtime_root"
  elif [[ -d "$flatpak_user_freedesktop_runtime_root" ]]; then
    echo "$flatpak_user_freedesktop_runtime_root"
  else
    echo ""
  fi
}

# Helper function to get the correct KDE runtime path
get_kde_runtime_path() {
  if [[ -d "$flatpak_kde_runtime_root" ]]; then
    echo "$flatpak_kde_runtime_root"
  elif [[ -d "$flatpak_user_kde_runtime_root" ]]; then
    echo "$flatpak_user_kde_runtime_root"
  else
    echo ""
  fi
}

# Helper function to check if specific runtime version exists and return the path
check_freedesktop_runtime_version() {
  local version="$1"
  if [[ -d "$flatpak_freedesktop_runtime_root/x86_64/$version/active/files" ]]; then
    echo "$flatpak_freedesktop_runtime_root/x86_64/$version/active/files"
  elif [[ -d "$flatpak_user_freedesktop_runtime_root/x86_64/$version/active/files" ]]; then
    echo "$flatpak_user_freedesktop_runtime_root/x86_64/$version/active/files"
  else
    echo ""
  fi
}

# Helper function to check if specific KDE runtime version exists and return the path
check_kde_runtime_version() {
  local version="$1"
  if [[ -d "$flatpak_kde_runtime_root/x86_64/$version/active/files" ]]; then
    echo "$flatpak_kde_runtime_root/x86_64/$version/active/files"
  elif [[ -d "$flatpak_user_kde_runtime_root/x86_64/$version/active/files" ]]; then
    echo "$flatpak_user_kde_runtime_root/x86_64/$version/active/files"
  else
    echo ""
  fi
}

# CI/CD Functions

# Function to recursively search for exec commands in scripts
find_exec_in_script() {
    local script_file="$1"
    local component_path="$2"
    local max_depth="${3:-3}"  # Prevent infinite recursion
    
    if [ ! -f "$script_file" ]; then
        return 1
    fi
    
    if [ "$max_depth" -le 0 ]; then
        log w "FIND_EXEC_IN_SCRIPT" "Maximum recursion depth reached while searching for exec in $script_file"
        return 1
    fi
    
    log d "FIND_EXEC_IN_SCRIPT" "Searching for exec command in: $script_file (depth: $((4-max_depth)))"
    
    # First, try to find exec at the beginning of a line
    local exec_command
    exec_command=$(grep -E "^exec " "$script_file" | head -n 1)
    
    # If not found, try fallback: search for " exec " anywhere in the line
    if [ -z "$exec_command" ]; then
        exec_command=$(grep -E " exec " "$script_file" | head -n 1)
        log d "FIND_EXEC_IN_SCRIPT" "Using fallback search for ' exec ' in $script_file"
    fi
    
    if [ -n "$exec_command" ]; then
        log d "FIND_EXEC_IN_SCRIPT" "Found exec command: $exec_command"
        
        # Extract binary path from exec command and expand variables
        # Replace $component_path with actual path
        local binary_path
        binary_path=$(echo "$exec_command" | sed -E 's/.*exec +//' | sed "s|\$component_path|$component_path|g" | cut -d' ' -f1)
        
        # Skip if binary_path is empty or contains only whitespace
        if [ -z "$binary_path" ] || [[ "$binary_path" =~ ^[[:space:]]*$ ]]; then
            log w "FIND_EXEC_IN_SCRIPT" "Empty or whitespace-only binary path extracted from: $exec_command"
            return 1
        fi
        
        binary_path=$(eval echo "$binary_path" 2>/dev/null)  # Expand any remaining variables, suppress errors
        
        # Double-check after variable expansion
        if [ -z "$binary_path" ] || [[ "$binary_path" =~ ^[[:space:]]*$ ]]; then
            log w "FIND_EXEC_IN_SCRIPT" "Binary path became empty after variable expansion"
            return 1
        fi
        
        # Check if the extracted path is a binary or another script
        if [ -f "$binary_path" ]; then
            # Check if it's executable
            if [ -x "$binary_path" ]; then
                # Check if it's an AppRun file or appears to be a script
                local filename=$(basename "$binary_path")
                local is_script=false
                
                # Check if it's AppRun or has shebang or contains shell script patterns
                if [[ "$filename" == "AppRun" ]] || head -n 1 "$binary_path" | grep -q "^#!" || head -n 5 "$binary_path" | grep -qE "(exec |/bin/|/usr/bin/)"; then
                    is_script=true
                fi
                
                if [ "$is_script" = true ]; then
                    # It's a script (including AppRun), search recursively
                    log d "FIND_EXEC_IN_SCRIPT" "Target is a script/AppRun, searching recursively: $binary_path"
                    find_exec_in_script "$binary_path" "$component_path" $((max_depth - 1))
                    return $?
                else
                    # It's likely a binary, return it
                    echo "$binary_path"
                    return 0
                fi
            else
                # File exists but not executable, return it anyway
                echo "$binary_path"
                return 0
            fi
        else
            log w "FIND_EXEC_IN_SCRIPT" "Extracted binary path does not exist: '$binary_path' (from exec: $exec_command)"
            return 1
        fi
    else
        log w "FIND_EXEC_IN_SCRIPT" "No exec command found in $script_file"
        # Log first few lines for debugging
        log d "FIND_EXEC_IN_SCRIPT" "Script content preview:"
        head -n 10 "$script_file" | while IFS= read -r line; do
            log d "FIND_EXEC_IN_SCRIPT" "  $line"
        done
        return 1
    fi
}

# Function to extract exec command from component launcher
extract_exec_command() {
    local launcher_script="$1"
    local component_path="$2"
    
    if [ ! -f "$launcher_script" ]; then
        log e "EXTRACT_EXEC_COMMAND" "Launcher script not found: $launcher_script"
        return 1
    fi
    
    # Use the recursive helper function to find the actual binary
    find_exec_in_script "$launcher_script" "$component_path"
}

# Function to process a single component
process_component() {
    local launcher_script="$1"
    local component_dir component_name component_path binary_path
    
    # Extract component information
    component_dir=$(dirname "$launcher_script")
    component_name=$(basename "$component_dir")
    component_path="$component_dir"
    
    log i "PROCESS_COMPONENT" "Processing component: $component_name"
    log d "PROCESS_COMPONENT" "  Launcher script: $launcher_script"
    log d "PROCESS_COMPONENT" "  Component path: $component_path"
    
    # Extract binary path
    if ! binary_path=$(extract_exec_command "$launcher_script" "$component_path"); then
        log w "PROCESS_COMPONENT" "Failed to extract binary path from launcher script"
        return 1
    fi

    # Validate binary path is not empty
    if [ -z "$binary_path" ] || [[ "$binary_path" =~ ^[[:space:]]*$ ]]; then
        log w "PROCESS_COMPONENT" "Empty binary path extracted from launcher script"
        return 1
    fi

    log d "PROCESS_COMPONENT" "  Binary path: $binary_path"

    # Check if binary exists
    if [ ! -f "$binary_path" ]; then
        log w "PROCESS_COMPONENT" "Binary not found: $binary_path"
        return 1
    fi
    
    # Check if binary is readable and appears to be a valid ELF file
    if ! file "$binary_path" | grep -q "ELF"; then
        log w "PROCESS_COMPONENT" "Binary does not appear to be a valid ELF file: $binary_path"
        # Still continue as some binaries might not be detected properly
    fi

    # Check if component directory exists in components repo
    local components_component_dir="$COMPONENTS_REPO_DIR/$component_name"
    if [ ! -d "$components_component_dir" ]; then
        log w "PROCESS_COMPONENT" "Component directory not found in components repo: $components_component_dir"
        return 1
    fi
    
    # Change to component directory in components repo
    cd "$components_component_dir"
    log d "PROCESS_COMPONENT" "  Working in: $(pwd)"
    
    log i "PROCESS_COMPONENT" "  Running library analysis for binary: $binary_path"
    
    # Final validation before running analysis
    if [ ! -f "$binary_path" ] || [ ! -r "$binary_path" ]; then
        log e "PROCESS_COMPONENT" "Binary is not readable or does not exist: $binary_path"
        return 1
    fi
    
    # Test if objdump can process the binary
    if ! objdump -p "$binary_path" >/dev/null 2>&1; then
        log w "PROCESS_COMPONENT" "objdump cannot process binary (not an ELF file?): $binary_path"
        return 2  # No update needed - binary not compatible
    fi
    
    # Run library analysis using the main hunt function with filtered output
    local old_cicd_mode="$cicd_mode"
    local old_component_libs_file="$component_libs_file"
    
    # Temporarily disable cicd mode for the main analysis to avoid recursive logging
    cicd_mode=false
    component_libs_file="./component_libs.json"
    
    # Capture the analysis output and filter objdump errors
    if hunt_output=$(hunt_single_binary "$binary_path" 2>&1); then
        # Filter and log the output
        echo "$hunt_output" | while IFS= read -r line; do
            if [ -n "$line" ]; then
                # Skip objdump errors for empty file paths (these are expected)
                if [[ "$line" =~ objdump.*\'\'.*No\ such\ file ]] || [[ "$line" =~ ^objdump:.*\'\'.*No\ such\ file ]]; then
                    continue  # Skip these specific objdump errors
                fi
                log d "PROCESS_COMPONENT" "$line"
            fi
        done
        
        # Restore cicd mode and file path
        cicd_mode="$old_cicd_mode"
        component_libs_file="$old_component_libs_file"
        
        log i "PROCESS_COMPONENT" "  Library hunting completed successfully for $component_name"
        
        # Check if component_libs.json was created/updated
        if [ -f "component_libs.json" ]; then
            log i "PROCESS_COMPONENT" "  component_libs.json updated for $component_name"
            return 0  # Success - component was updated
        else
            log d "PROCESS_COMPONENT" "  No component_libs.json created for $component_name"
            return 2  # No update needed
        fi
    else
        # Restore cicd mode and file path
        cicd_mode="$old_cicd_mode"
        component_libs_file="$old_component_libs_file"
        
        # Log errors but filter out objdump empty file errors
        echo "$hunt_output" | while IFS= read -r line; do
            if [ -n "$line" ]; then
                if [[ "$line" =~ objdump.*\'\'.*No\ such\ file ]] || [[ "$line" =~ ^objdump:.*\'\'.*No\ such\ file ]]; then
                    continue  # Skip these specific objdump errors even in error case
                fi
                log w "PROCESS_COMPONENT" "$line"
            fi
        done
        log w "PROCESS_COMPONENT" "Library analysis failed for $component_name"
        return 1  # Error
    fi
}

# Function to commit changes for a component
commit_component_changes() {
    local component_name="$1"
    local components_component_dir="$COMPONENTS_REPO_DIR/$component_name"
    
    cd "$components_component_dir"
    
    # Check if there are changes to commit
    if git diff --quiet component_libs.json; then
        log d "COMMIT_COMPONENT_CHANGES" "No changes to commit for $component_name"
        return 1
    fi
    
    # Add and commit changes
    git add component_libs.json
    git commit -m "chore($component_name): update $component_name libraries [AUTOMATED]"
    
    log i "COMMIT_COMPONENT_CHANGES" "Committed changes for $component_name"
    return 0
}

# Function to run CI/CD mode
run_cicd_mode() {
    local action="${1:-hunt}"
    
    log i "MAIN" "Starting Library Hunter in CI/CD mode..."
    log i "MAIN" "RetroDECK repo: $RETRODECK_REPO_DIR"
    log i "MAIN" "Components repo: $COMPONENTS_REPO_DIR"
    log i "MAIN" "Flatpak directory: $FLATPAK_DIR"
    
    # Validate required directories
    if [ ! -d "$RETRODECK_REPO_DIR" ]; then
        log e "MAIN" "RetroDECK repository directory not found: $RETRODECK_REPO_DIR"
        exit 1
    fi
    
    if [ ! -d "$COMPONENTS_REPO_DIR" ]; then
        log e "MAIN" "Components repository directory not found: $COMPONENTS_REPO_DIR"
        exit 1
    fi
    
    log i "MAIN" "Searching for component launchers in: $FLATPAK_DIR"
    
    # Configure git for components repo
    cd "$COMPONENTS_REPO_DIR"
    git config --global user.name "RetroDECK Library Hunter"
    git config --global user.email "retrodeck@retrodeck.net"
    
    # Iterate through all component launcher scripts
    for launcher_script in "$FLATPAK_DIR"/*/component_launcher.sh; do
        if [ ! -f "$launcher_script" ]; then
            log d "MAIN" "Skipping non-existent launcher: $launcher_script"
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
                log d "MAIN" "No update needed for component"
                ;;
        esac
        
        log d "MAIN" "Completed processing component"
    done
    
    # Summary
    log i "MAIN" "Library hunting completed."
    log i "MAIN" "Components processed: $components_processed"
    log i "MAIN" "Components updated: $components_updated"
    log i "MAIN" "Components failed: $components_failed"
    
    # Export results for CI/CD systems
    echo "COMPONENTS_PROCESSED=$components_processed"
    echo "COMPONENTS_UPDATED=$components_updated"
    echo "COMPONENTS_FAILED=$components_failed"
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -q|--qt-version)
      if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
        qt_version="$2"
        shift 2
      else
        echo "Error: --qt-version requires a value"
        exit 1
      fi
    ;;
    -p|--path)
      if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
        path_to_search="$2"
        shift 2
      else
        echo "Error: --path requires a value"
        exit 1
      fi
    ;;
    -o|--output)
      if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
        component_libs_file="$2"
        shift 2
      else
        echo "Error: --output requires a value"
        exit 1
      fi
    ;;
    --cicd)
      cicd_mode=true
      shift
    ;;
    --help|-h)
      echo "RetroDECK Library Hunter"
      echo ""
      echo "USAGE:"
      echo "  Manual: $0 [-qpo] /path/to/binary"
      echo "  CI/CD:  $0 --cicd [hunt]"
      echo ""
      echo "OPTIONS:"
      echo "  -q, --qt-version VERSION  Qt version for Qt libraries"
      echo "  -p, --path PATH          Path to search for libraries"  
      echo "  -o, --output FILE        Output file path"
      echo "  --cicd                   Enable CI/CD mode for automated processing"
      echo "  -h, --help               Show this help message"
      exit 0
    ;;
    -*)
      echo "Error: Unknown option $1"
      echo "Use --help for usage information"
      exit 1
    ;;
    *)
      # Non-option argument
      if [ "$cicd_mode" = false ]; then
        # In manual mode, this should be the binary path
        if [ -z "$binary_path" ]; then
          binary_path="$1"
        else
          echo "Error: Multiple binary paths specified"
          exit 1
        fi
      else
        # In CICD mode, this could be the action (hunt)
        cicd_action="$1"
      fi
      shift
    ;;
  esac
done

# Function to analyze a single binary (core functionality)
hunt_single_binary() {
  local target_binary="$1"
  
  # Validate target binary
  if [ -z "$target_binary" ]; then
    echo "Error: No binary specified"
    return 1
  fi
  
  if [ ! -f "$target_binary" ]; then
    echo "Error: Binary not found: $target_binary"
    return 1
  fi
  
  # Test if objdump can process the binary
  if ! objdump -p "$target_binary" >/dev/null 2>&1; then
    echo "Error: objdump cannot process binary (not an ELF file?): $target_binary"
    return 1
  fi
  
  # Reset component_libs for this analysis
  component_libs='[]'
  
  while read -r lib; do
    # Skip empty libraries
    if [ -z "$lib" ]; then
      continue
    fi
    
    if [[ -n $(jq -r '.[].library' <<< "$component_libs") ]]; then # If component_libs list is not empty
    if jq -e --arg lib "$lib" '.[] | select(.library == $lib)' <<< "$component_libs" >/dev/null; then # Check if lib dep is already on the list
      echo "Library $lib already added, skipping..."
      continue
    fi
  fi

  shared_libs_subfolder="UNKNOWN"
  lib_found="false"

  # PHASE 1 - Locating component dependency

  freedesktop_runtime_files_path=$(check_freedesktop_runtime_version "$retrodeck_runtime_version")
  if [[ -n "$freedesktop_runtime_files_path" && -n $(find "$freedesktop_runtime_files_path" -name "$lib" 2>/dev/null) ]]; then # Check if lib is already provided by RetroDECK runtime
    echo "Library $lib found in RetroDECK base runtime, skipping..."
    continue
  fi

  if [[ "$lib" =~ "libQt" ]]; then # If library is a Qt lib
    if [[ "$lib" =~ "libQt5" ]]; then
      shared_libs_subfolder="qt5"
      if [[ ! -n "$qt_version" ]]; then
        qt_version="$latest_kde5_runtime_version"
      fi
    elif [[ "$lib" =~ "libQt6" ]]; then
      shared_libs_subfolder="qt6"
      if [[ ! -n "$qt_version" ]]; then
        qt_version="$latest_kde6_runtime_version"
      fi
    fi
    kde_runtime_files_path=$(check_kde_runtime_version "$qt_version")
    if [[ -n "$kde_runtime_files_path" ]]; then
      found_lib_path=$(find "$kde_runtime_files_path" -name "$lib" 2>/dev/null)
      json_obj=$(jq -n --arg lib "$lib" --arg qt_ver "$qt_version" --arg subfolder "$shared_libs_subfolder" '{ library: $lib, qt_version: $qt_ver, subfolder: $subfolder }')
      component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
      lib_found="true"
    fi
  else # If library is not a Qt lib
    found_lib_all_runtimes=$(search_flatpak_runtimes "$lib") # Check if lib is provided by any installed runtime
    if [[ -n "$found_lib_all_runtimes" ]]; then # Library was found in at least one Flatpak runtime
      found_lib_runtime=$(echo "$found_lib_all_runtimes" | awk -F/ '{print $6, $8}' | sort -k1,1 -k2,2Vr | head -n1) # Find latest version of runtime that contains that library
      read runtime_name runtime_version <<< "$found_lib_runtime"
      runtime_root=$(get_runtime_path)
      if [[ -n "$runtime_root" ]]; then
        found_lib_path=$(find "$runtime_root/$runtime_name/x86_64/$runtime_version/active/files" -name "$lib" 2>/dev/null)
        json_obj=$(jq -n --arg lib "$lib" --arg runtime_name "$runtime_name" --arg runtime_version "$runtime_version" '{ library: $lib, runtime_name: $runtime_name, subfolder: $runtime_version }')
        component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
        lib_found="true"
      fi
    elif [[ -n "$path_to_search" ]]; then # Search optional provided path
      found_lib_custom_path=$(find "$path_to_search" -name "$lib")
      if [[ -n "$found_lib_custom_path" ]]; then # Library was found in provided path
        found_lib_path="$found_lib_custom_path"
        json_obj=$(jq -n --arg lib "$lib" --arg subfolder "$shared_libs_subfolder" --arg source "$found_lib_path" '{ library: $lib, subfolder: $subfolder, source: $source }')
        component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
        lib_found="true"
      fi
    fi
    if [[ "$lib_found" == "false" ]]; then # Library could not be found automatically
      echo "Library $lib could not be found at all, skipping further search..."
      json_obj=$(jq -n --arg lib "$lib" --arg subfolder "$shared_libs_subfolder" '{ library: $lib, subfolder: $subfolder }')
      component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
      continue
    fi
  fi

  # PHASE 2 - Locating dependency dependencies

  # Only proceed if we have a valid library path to analyze
  if [[ -n "$found_lib_path" && -f "$found_lib_path" ]]; then
    while read -r lib_dep; do
      # Skip empty library dependencies
      if [[ -z "$lib_dep" ]]; then
        echo "Skipping empty library dependency..."
        continue
      fi
      
      if jq -e --arg lib_dep "$lib_dep" '.[] | select(.library == $lib_dep)' <<< "$component_libs" >/dev/null; then # Check if library dependency is already on the list
        echo "Library dependency $lib_dep already added, skipping..."
        continue
      fi

    shared_libs_subfolder="UNKNOWN"
    lib_dep_found="false"

    freedesktop_runtime_files_path=$(check_freedesktop_runtime_version "$retrodeck_runtime_version")
    if [[ -n "$freedesktop_runtime_files_path" && -n $(find "$freedesktop_runtime_files_path" -name "$lib_dep" 2>/dev/null) ]]; then # Check if library dependency is already provided by RetroDECK runtime
      echo "Library dependency $lib_dep found in RetroDECK base runtime, skipping..."
      continue
    fi

    if [[ "$lib_dep" =~ "libQt" ]]; then # If library dependency is a Qt lib
      if [[ "$lib_dep" =~ "libQt5" ]]; then
        shared_libs_subfolder="qt5"
        if [[ ! -n "$qt_version" ]]; then
          qt_version="$latest_kde5_runtime_version"
        fi
      elif [[ "$lib_dep" =~ "libQt6" ]]; then
        shared_libs_subfolder="qt6"
        if [[ ! -n "$qt_version" ]]; then
          qt_version="$latest_kde6_runtime_version"
        fi
      fi
      kde_runtime_files_path=$(check_kde_runtime_version "$qt_version")
      if [[ -n "$kde_runtime_files_path" ]]; then
        found_lib_dep_path=$(find "$kde_runtime_files_path" -name "$lib_dep" 2>/dev/null)
        json_obj=$(jq -n --arg lib_dep "$lib_dep" --arg qt_ver "$qt_version" --arg subfolder "$shared_libs_subfolder" '{ library: $lib_dep, qt_version: $qt_ver, subfolder: $subfolder }')
        component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
        lib_dep_found="true"
      fi
    else # If library dependency is not a Qt lib
      found_lib_dep_all_runtimes=$(search_flatpak_runtimes "$lib_dep") # Check if lib is provided by any installed runtime
      if [[ -n "$found_lib_dep_all_runtimes" ]]; then # Library was found in at least one Flatpak runtime
        found_lib_dep_runtime=$(echo "$found_lib_dep_all_runtimes" | awk -F/ '{print $6, $8}' | sort -k1,1 -k2,2Vr | head -n1) # Find latest version of runtime that contains that library
        read dep_runtime_name dep_runtime_version <<< "$found_lib_dep_runtime"
        runtime_root=$(get_runtime_path)
        if [[ -n "$runtime_root" ]]; then
          found_lib_dep_path=$(find "$runtime_root/$dep_runtime_name/x86_64/$dep_runtime_version/active/files" -name "$lib_dep" 2>/dev/null)
          json_obj=$(jq -n --arg lib_dep "$lib_dep" --arg runtime_name "$dep_runtime_name" --arg runtime_version "$dep_runtime_version" '{ library: $lib_dep, runtime_name: $runtime_name, subfolder: $runtime_version }')
          component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
          lib_dep_found="true"
        fi
      elif [[ -n "$path_to_search" ]]; then # Search optional provided path
        found_lib_dep_custom_path=$(find "$path_to_search" -name "$lib_dep")
        if [[ -n "$found_lib_dep_custom_path" ]]; then # Library dependency was found in provided path
          json_obj=$(jq -n --arg lib_dep "$lib_dep" --arg subfolder "$shared_libs_subfolder" --arg source "$found_lib_dep_custom_path" '{ library: $lib_dep, subfolder: $subfolder, source: $source }')
          component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
          lib_dep_found="true"
        fi
      fi
      if [[ "$lib_dep_found" == "false" ]]; then # Library could not be found automatically
        echo "Library dependency $lib_dep could not be found at all, skipping further search..."
        json_obj=$(jq -n --arg lib_dep "$lib_dep" --arg subfolder "$shared_libs_subfolder" '{ library: $lib_dep, subfolder: $subfolder }')
        component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
        continue
      fi
    fi
    done < <(objdump -p "$found_lib_path" 2>/dev/null | awk '/NEEDED/ {print $2}')
  else
    if [ "$cicd_mode" = true ]; then
      log w "HUNT_SINGLE_BINARY" "Library path '$found_lib_path' is empty or file does not exist, skipping dependency analysis for this library"
    else
      echo "Warning: Library path '$found_lib_path' is empty or file does not exist, skipping dependency analysis for this library"
    fi
  fi
  done < <(objdump -p "$target_binary" 2>/dev/null | awk '/NEEDED/ {print $2}')

  # Output results
  if [ "$cicd_mode" = true ]; then
    echo "$component_libs" | jq > "$component_libs_file"
  else
    echo "$component_libs" | jq > "$component_libs_file"
    echo "Library analysis completed. Results saved to: $component_libs_file"
  fi
  
  return 0
}

# Main script logic
main() {
  # Check if running in CI/CD mode
  if [ "$cicd_mode" = true ]; then
    run_cicd_mode "${cicd_action:-hunt}"
  else
    # Manual mode - analyze single binary
    if [ -z "$binary_path" ]; then
      echo "Error: No binary specified for analysis"
      echo "Use --help for usage information"
      exit 1
    fi
    
    hunt_single_binary "$binary_path"
  fi
}

# Run main function
main
