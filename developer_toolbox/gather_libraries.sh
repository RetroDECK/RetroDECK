#!/bin/bash

# Only download logger if not already sourced (e.g., when called from assembler.sh)
if [[ ! -f ".tmpfunc/logger.sh" ]] && ! declare -f log > /dev/null; then
    mkdir -p ".tmpfunc"
    wget -q https://raw.githubusercontent.com/RetroDECK/RetroDECK/main/functions/logger.sh -O ".tmpfunc/logger.sh"
fi

# Source logger if available and not already sourced
if [[ -f ".tmpfunc/logger.sh" ]] && ! declare -f log > /dev/null; then
    # Set up logging variables for the external logger BEFORE sourcing
    export logging_level="${logging_level:-debug}"
    if [[ -z "$rd_logs_folder" ]]; then
        export rd_logs_folder="$(dirname "${logfile:-assemble.log}")"
    fi
    source ".tmpfunc/logger.sh"
fi

logfile="assemble.log"

# This script is meant to process component_libs.json files created by the build_missing_libs_json.sh script.
# It will iterate all the objects in the output JSON files, search for the defined libraries and copy them to the specified locations if they do not already exist there.
# A path to search for component_libs.json files can optionally be specified. The script will search this path 1 level deep, so will investigate any direct sub-folders of the supplied path. Otherwise the script will search the directory from which it was run.
# A destination path can be specified which will override the "shared-libs" destination, which is used when any specific destination is not defined for a given library in the component_libs.json file.

# USAGE: gather_libraries [-p|--path <path>] [-d|--dest <dest>] [-w|--work-dir <work_dir>]
# Can be sourced and called as a function or executed directly as a script.
# When called from assembler.sh, it will use WORK_DIR before it's disposed.

gather_libraries() {
  local root_to_search="."
  local gathered_libs_dest_root="./shared-libs"
  local flatpak_runtime_dir="/var/lib/flatpak/runtime"
  local current_rd_runtime="24.08"  # TODO: automate the extraction of the current RetroDECK runtime version
  local work_dir_override=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--path)
        root_to_search="$2"
        shift 2
      ;;
      -d|--dest)
        gathered_libs_dest_root="$2"
        shift 2
      ;;
      -w|--work-dir)
        work_dir_override="$2"
        shift 2
      ;;
      *)
        echo "Unknown option: $1"
        return 1
      ;;
    esac
  done
  
  # If WORK_DIR is set from assembler.sh and no override, search there first
  if [[ -n "$WORK_DIR" && -z "$work_dir_override" ]]; then
    work_dir_override="$WORK_DIR"
    log i  "Using WORK_DIR from assembler: $work_dir_override" "$logfile"
  fi
  
  # If work_dir_override is set, prioritize searching there
  if [[ -n "$work_dir_override" && -d "$work_dir_override" ]]; then
    log i  "Searching for component_libs.json in work directory: $work_dir_override" "$logfile"
    root_to_search="$work_dir_override"
  fi

  gathered_libs_dest_root=$(realpath $gathered_libs_dest_root)

  if [[ ! -e "$gathered_libs_dest_root" ]]; then
    mkdir -p "$gathered_libs_dest_root"
  fi

  # Also search in component directory if $component is set
  local search_paths=("$root_to_search")
  if [[ -n "$component" && -d "$component" ]]; then
    search_paths+=("$component")
    log i  "Also searching in component directory: $component" "$logfile"
  fi

  for search_path in "${search_paths[@]}"; do
    while IFS= read -r component_libs_file; do
    component_libs_file=$(realpath $component_libs_file)
    log i  "Found $component_libs_file" "$logfile"
    
    # Extract component name from the component_libs.json file path
    # The component name is the parent directory of the component_libs.json file
    local component_name=$(basename "$(dirname "$component_libs_file")")
    log i  "Processing libraries for component: $component_name" "$logfile"
    
    # Initialize counters for reporting
    local total_libs=0
    local copied_libs=0
    local skipped_libs=0
    local failed_libs=0
    local copied_list=""
    local skipped_list=""
    local failed_list=""
    
    while read -r lib; do
      ((total_libs++))
      log d "📚 Processing library: $lib" "$logfile"
      qt_version=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .qt_version // empty' "$component_libs_file")
      lib_type=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .type // empty' "$component_libs_file")
      lib_src=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .source // empty' "$component_libs_file")
      lib_dest=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .dest // empty' "$component_libs_file")
      lib_subfolder=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .subfolder // empty' "$component_libs_file")
      
      # Expand $component variable in source and subfolder paths
      if [[ -n "$lib_src" ]]; then
        lib_src=${lib_src//\$component/$component_name}
      fi
      if [[ -n "$lib_subfolder" ]]; then
        lib_subfolder=${lib_subfolder//\$component/$component_name}
      fi
      if [[ -n "$lib_dest" ]]; then
        lib_dest=${lib_dest//\$component/$component_name}
      fi
      if [[ -n $qt_version ]]; then
        if [[ $lib_type == "qt_plugin" ]]; then
          log i  "Looking for Qt plugin at $flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/plugins/$lib" "$logfile"
          if [[ -e "$flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/plugins/$lib" ]]; then
            if [[ ! -n "$lib_dest" ]]; then
                if [[ -n "$lib_subfolder" ]]; then
                  lib_dest="$gathered_libs_dest_root/$lib_subfolder/plugins/$lib/"
                else
                  lib_dest="$gathered_libs_dest_root/qt-$qt_version/plugins/$lib/"
                fi
            fi
            if [[ -e "$lib_dest" ]]; then
              log i  "Qt plugin folder already found in destination location $lib_dest, skipping..." "$logfile"
              ((skipped_libs++))
              skipped_list="$skipped_list$lib (Qt plugin already exists at $lib_dest)\n"
            else
              if [[ ! -e "$lib_dest" ]]; then
                mkdir -p "$lib_dest"
              fi
              log i  "Qt plugin not found in destination location $lib_dest, copying..." "$logfile"
              cp -ar "$flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/plugins/$lib/"* "$lib_dest"
              ((copied_libs++))
              copied_list="$copied_list$lib (Qt plugin copied to $lib_dest)\n"
            fi
          else
            log w  "ERROR: Qt plugin folder not found at expected location." "$logfile"
            ((failed_libs++))
            failed_list="$failed_list$lib (Qt plugin not found at $flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/plugins/$lib)\n"
          fi
        else
          log i  "Looking for Qt lib at $flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/x86_64-linux-gnu/$lib" "$logfile"
          if [[ -e "$flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/x86_64-linux-gnu/$lib" ]]; then
            if [[ ! -n "$lib_dest" ]]; then
                if [[ -n "$lib_subfolder" ]]; then
                  lib_dest="$gathered_libs_dest_root/$lib_subfolder"
                else
                  lib_dest="$gathered_libs_dest_root/qt-$qt_version"
                fi
            fi
            if [[ -e "$lib_dest/$lib" ]]; then
              log i  "Lib already found in destination location $lib_dest/$lib, skipping..." "$logfile"
              ((skipped_libs++))
              skipped_list="$skipped_list$lib (Qt lib already exists at $lib_dest/$lib)\n"
            else
              if [[ ! -e "$lib_dest" ]]; then
                mkdir -p "$lib_dest"
              fi
              log i  "Library not found in destination location $lib_dest, copying..."
              cp -a "$flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/x86_64-linux-gnu/$lib"* "$lib_dest/" "$logfile"
              ((copied_libs++))
              copied_list="$copied_list$lib (Qt lib copied to $lib_dest)\n"
            fi
          else
            log w  "\"$lib\" not found at expected location." "$logfile"
            ((failed_libs++))
            failed_list="$failed_list$lib (Qt lib not found at $flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/x86_64-linux-gnu/$lib)\n"
          fi
        fi
        continue
      fi
      # Handle custom source paths (e.g., from WORK_DIR or component-specific paths)
      if [[ -n "$lib_src" ]]; then
        # If lib_src is relative or contains $WORK_DIR reference, resolve it
        if [[ "$lib_src" =~ ^\$WORK_DIR || "$lib_src" =~ ^\$component ]]; then
          lib_src=${lib_src//\$WORK_DIR/$work_dir_override}
          lib_src=${lib_src//\$component/$component_name}
        fi
        # If path is not absolute and WORK_DIR is available, make it relative to WORK_DIR
        if [[ ! "$lib_src" =~ ^/ && -n "$work_dir_override" ]]; then
          lib_src="$work_dir_override/$lib_src"
        fi
      else
        lib_src="$flatpak_runtime_dir/$current_rd_runtime/active/files/lib/x86_64-linux-gnu"
      fi
      
      log i  "Looking for lib at $lib_src/$lib" "$logfile"
      if [[ -e "$lib_src/$lib" ]]; then
        if [[ ! -n "$lib_dest" ]]; then
          if [[ -n "$lib_subfolder" ]]; then
            lib_dest="$gathered_libs_dest_root/$lib_subfolder"
          else
            lib_dest="$gathered_libs_dest_root"
          fi
        fi
        if [[ -e "$lib_dest/$lib" ]]; then
            log i  "Lib already found in destination location $lib_dest, skipping..." "$logfile"
            ((skipped_libs++))
            skipped_list="$skipped_list$lib (already exists at $lib_dest)\n"
          else
            if [[ ! -e "$lib_dest" ]]; then
              mkdir -p "$lib_dest"
            fi
            log i  "Library not found in destination location $lib_dest, copying..." "$logfile"
            cp -a "$lib_src/$lib"* "$lib_dest/"
            ((copied_libs++))
            copied_list="$copied_list$lib (copied to $lib_dest)\n"
          fi
      else
        # Fallback for AppImage: check in squashfs-root if lib_src is under component dir
        local fallback_src=""
        if [[ -d "$work_dir_override/squashfs-root" && "$lib_src" =~ ^$work_dir_override/$component_name/ ]]; then
          fallback_src="$work_dir_override/squashfs-root/${lib_src#$work_dir_override/$component_name/}"
          log i  "Lib not found at $lib_src/$lib, trying AppImage fallback at $fallback_src/$lib" "$logfile"
          if [[ -e "$fallback_src/$lib" ]]; then
            lib_src="$fallback_src"
            # Retry the copy logic with fallback_src
            if [[ ! -n "$lib_dest" ]]; then
              if [[ -n "$lib_subfolder" ]]; then
                lib_dest="$gathered_libs_dest_root/$lib_subfolder"
              else
                lib_dest="$gathered_libs_dest_root"
              fi
            fi
            if [[ -e "$lib_dest/$lib" ]]; then
                log i  "Lib already found in destination location $lib_dest, skipping..." "$logfile"
                ((skipped_libs++))
                skipped_list="$skipped_list$lib (already exists at $lib_dest)\n"
              else
                if [[ ! -e "$lib_dest" ]]; then
                  mkdir -p "$lib_dest"
                fi
                log i  "Library not found in destination location $lib_dest, copying..." "$logfile"
                cp -a "$lib_src/$lib"* "$lib_dest/"
                ((copied_libs++))
                copied_list="$copied_list$lib (copied to $lib_dest)\n"
              fi
            continue
          fi
        fi
        log w  "ERROR: Lib not found at expected location." "$logfile"
        ((failed_libs++))
        failed_list="$failed_list$lib (not found at $lib_src/$lib)\n"
      fi
    done <<< "$(jq -r '.[].library' "$component_libs_file")"
    
    # Generate detailed report
    log i "📊 Library gathering report for $component_name:" "$logfile"
    log i "  Total libraries processed: $total_libs" "$logfile"
    log i "  Libraries copied: $copied_libs" "$logfile"
    log i "  Libraries skipped: $skipped_libs" "$logfile"
    log i "  Libraries failed: $failed_libs" "$logfile"

    if [[ $copied_libs -gt 0 ]]; then
      log i "  📋 Copied libraries:"  "$logfile"
      echo -e "$copied_list" | while read -r line; do
        [[ -n "$line" ]] && log i "    ✅ $line" "$logfile"
      done
    fi
    
    if [[ $skipped_libs -gt 0 ]]; then
      log i "  📋 Skipped libraries:" "$logfile"
      echo -e "$skipped_list" | while read -r line; do
        [[ -n "$line" ]] && log i "    ⏭️  $line" "$logfile"
      done
    fi
    
    if [[ $failed_libs -gt 0 ]]; then
      log w "  📋 Failed libraries:" "$logfile"
      echo -e "$failed_list" | while read -r line; do
        [[ -n "$line" ]] && log w "    ❌ $line" "$logfile"
      done
    fi
    
    # If in CI/CD, append to build report
    if [[ -n "$CI" || -n "$GITHUB_ACTIONS" || -n "$GITLAB_CI" ]]; then
      local build_report_file="${BUILD_REPORT_FILE:-build_report.md}"
      {
        echo "## Library Gathering Report for $component_name"
        echo ""
        echo "- **Total libraries processed:** $total_libs"
        echo "- **Libraries copied:** $copied_libs"
        echo "- **Libraries skipped:** $skipped_libs"
        echo "- **Libraries failed:** $failed_libs"
        echo ""
        if [[ $copied_libs -gt 0 ]]; then
          echo "### Copied Libraries"
          echo -e "$copied_list" | while read -r line; do
            [[ -n "$line" ]] && echo "- ✅ $line"
          done
          echo ""
        fi
        if [[ $skipped_libs -gt 0 ]]; then
          echo "### Skipped Libraries"
          echo -e "$skipped_list" | while read -r line; do
            [[ -n "$line" ]] && echo "- ⏭️  $line"
          done
          echo ""
        fi
        if [[ $failed_libs -gt 0 ]]; then
          echo "### Failed Libraries"
          echo -e "$failed_list" | while read -r line; do
            [[ -n "$line" ]] && echo "- ❌ $line"
          done
          echo ""
        fi
        echo "---"
        echo ""
      } >> "$build_report_file"
      log i "📄 Build report updated: $build_report_file" "$logfile"
    fi
    
    done < <(find "$search_path" -maxdepth 2 -type f -name "component_libs.json")
  done
}

# If script is executed directly (not sourced), call the function with all arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  gather_libraries "$@"
fi

