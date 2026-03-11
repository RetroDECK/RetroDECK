#!/bin/bash

# Component-parsing-related variables
component_manifest_cache=""

find_component_files() {
  # Find files of a given name across all component directories, with external components taking precedence over internal ones when both exist.
  # Returns a newline-separated list of file paths where the requested file was found.
  # USAGE: find_component_files "$filename" ["$component_name"]

  local filename="$1"
  local component="${2:-all}"
  local -a result_files=()

  if [[ "$component" == "all" ]]; then
    local -A seen_components

    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      seen_components["$(basename "$(dirname "$file")")"]=1
      result_files+=("$file")
    done < <(find "$rd_external_components" -maxdepth 2 -mindepth 2 -type f -name "$filename" 2>/dev/null)

    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      local component_name
      component_name=$(basename "$(dirname "$file")")
      if [[ -z "${seen_components[$component_name]+x}" ]]; then
        result_files+=("$file")
      fi
    done < <(find "$rd_components" -maxdepth 2 -mindepth 2 -type f -name "$filename" 2>/dev/null)
  else
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      result_files+=("$file")
    done < <(find "$rd_external_components/$component" -maxdepth 1 -mindepth 1 -type f -name "$filename" 2>/dev/null)

    if [[ ${#result_files[@]} -eq 0 ]]; then
      while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        result_files+=("$file")
      done < <(find "$rd_components/$component" -maxdepth 1 -mindepth 1 -type f -name "$filename" 2>/dev/null)
    fi
  fi

  if [[ ${#result_files[@]} -gt 0 ]]; then
    printf '%s\n' "${result_files[@]}"
  fi
}

build_component_manifest_cache() {
  # Build the component manifest cache from all installed component manifests.
  # Should be called once during application startup. Cache remains valid for the session.
  # USAGE: build_component_manifest_cache

  local -a manifest_files=()
  while IFS= read -r manifest_file; do
    [[ -n "$manifest_file" ]] && manifest_files+=("$manifest_file")
  done < <(find_component_files "component_manifest.json")

  if [[ ${#manifest_files[@]} -eq 0 ]]; then
    component_manifest_cache='[]'
    return
  fi

  component_manifest_cache=$(
    for manifest_file in "${manifest_files[@]}"; do
      jq -c --arg path "$(dirname "$manifest_file")" \
        '{component_path: $path, manifest: .}' "$manifest_file"
    done | jq -s '.'
  )
}

get_component_manifest_cache() {
  # Return the cached component manifest data. Requires build_component_manifest_cache to have been called.
  # USAGE: get_component_manifest_cache

  if [[ -z "$component_manifest_cache" ]]; then
    log e "Component manifest cache is empty. Was build_component_manifest_cache called?"
    return 1
  fi

  echo "$component_manifest_cache"
}

get_helper_files() {
  # Gather helper file information from component manifests, including the source path for each file.
  # Optionally filtered to a specific component.
  # Returns a JSON array of helper file objects with filename, location, and source_path.
  # USAGE: get_helper_files "[$component_name]"

  local component="${1:-all}"

  if [[ "$component" == "all" ]]; then
    get_component_manifest_cache | jq '
      [.[] | .component_path as $component_path |
       .manifest | .. | objects | select(has("helper_files")) |
       .helper_files | to_entries[].value |
       . + {source_path: ($component_path + "/rd_assets/helper_files")}]
    '
  else
    get_component_manifest_cache | jq --arg component "$component" '
      [.[] | select(.manifest | has($component)) |
       .component_path as $component_path |
       .manifest[$component] | select(has("helper_files")) |
       .helper_files | to_entries[].value |
       . + {source_path: ($component_path + "/rd_assets/helper_files")}]
    '
  fi
}

deploy_helper_files() {
  # Distribute helper documentation files throughout the filesystem according to component manifest configurations.
  # Optionally limited to a specific component.
  # USAGE: deploy_helper_files "[$component_name]"

  local component="${1:-all}"

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    IFS=$'\t' read -r file dest source_path < <(jq -r '[.filename, .location, .source_path] | @tsv' <<< "$entry")
    dest=$(envsubst <<< "$dest")

    if [[ -z "$file" || -z "$dest" ]]; then
      continue
    fi

    if [[ ! -f "$source_path/$file" ]]; then
      log d "Helper file $file not found at $source_path, skipping..."
      continue
    fi

    if [[ -d "$dest" ]]; then
      log d "Copying helper file $file from $source_path to $dest"
      cp -f "$source_path/$file" "$dest/$file"
    else
      log d "Helper file location $dest does not exist, component may not be installed. Skipping..."
    fi
  done < <(get_helper_files "$component" | jq -c '.[]')
}

source_component_functions() {
  # Source component_functions.sh files from installed components, making their variables and functions globally available.
  # Framework is always sourced first as it provides core application infrastructure.
  # A specific component name can be given to source only that component.
  # USAGE: source_component_functions "[$component]"

  local choice="${1:-all}"

  if [[ "$choice" == "all" ]]; then
    # Framework always sources first
    local framework_file
    framework_file=$(find_component_files "component_functions.sh" "framework")
    if [[ -n "$framework_file" ]]; then
      log d "Sourcing framework: $framework_file"
      source "$framework_file"
    fi

    # Source all other components
    while IFS= read -r function_file; do
      [[ -z "$function_file" ]] && continue
      local component_name
      component_name=$(basename "$(dirname "$function_file")")
      [[ "$component_name" == "framework" ]] && continue
      log d "Sourcing component: $function_file"
      source "$function_file"
    done < <(find_component_files "component_functions.sh")
  else
    local function_file
    function_file=$(find_component_files "component_functions.sh" "$choice")
    if [[ -n "$function_file" ]]; then
      log d "Sourcing component: $function_file"
      source "$function_file"
    else
      log e "component_functions.sh for component $choice could not be found"
      return 1
    fi
  fi
}

prepare_component() {
  # Perform one of several actions on one or more components.
  # Actions include "reset" (initialize component), "postmove" (update paths after folder move), and "startup" (run startup actions).
  # A component can be called by name or "all" to perform the action on all components. Framework always runs first.
  # USAGE: prepare_component "$action" "$component"

  local action="$1"
  local component="$2"

  if [[ "$action" == "factory-reset" ]]; then
    # REBUILD
    log i "User requested full RetroDECK reset"
    rm -rf "$XDG_CONFIG_HOME"
    quit_retrodeck
    source /app/libexec/global.sh
  fi

  if [[ -z "$component" || -z "$action" ]]; then
    log e "No component or action specified."
    return 1
  fi

  log d "Preparing component: \"$component\", action: \"$action\""

  if [[ "$component" == "all" ]]; then
    # Framework always runs first
    local framework_handler="_prepare_component::framework"
    if declare -F "$framework_handler" > /dev/null; then
      log d "Running prepare handler for framework"
      "$framework_handler" "$action"
    fi

    # Build a priority-sorted list of remaining handlers
    local manifest_cache
    manifest_cache=$(get_component_manifest_cache)

    while IFS=$'\t' read -r priority comp_name; do
      [[ "$comp_name" == "framework" ]] && continue
      local handler="_prepare_component::${comp_name}"
      if declare -F "$handler" > /dev/null; then
        log d "Running prepare handler for $comp_name (priority: $priority)"
        "$handler" "$action"
      fi
    done < <(jq -r --arg action "$action" '
      [.[] | .manifest | to_entries[] |
       {name: .key, priority: (
         .value.prepare_priority
         | if type == "object" then
             .[$action] // .default // 50
           elif type == "number" then
             .
           else
             50
           end
       )}]
      | sort_by(.priority)
      | .[]
      | [(.priority | tostring), .name]
      | @tsv
    ' <<< "$manifest_cache")
  fi

  # Reset presets to their disabled state for affected components
  if [[ "$action" == "reset" ]]; then
    local manifest_cache
    manifest_cache=$(get_component_manifest_cache)

    # Deploy helper files for the reset components
    deploy_helper_files "$component"

    while IFS= read -r preset; do
      while IFS= read -r preset_component; do
        if [[ "$component" != "all" && "$preset_component" != *"$component"* ]]; then
          continue
        fi

        local parent_component
        parent_component=$(jq -r --arg preset "$preset" --arg component "$preset_component" '
          .presets[$preset]
          | paths(scalars)
          | select(.[-1] == $component)
          | if length > 1 then .[-2] else $preset end
        ' "$rd_conf")

        local child_component=""
        local manifest_component="$preset_component"
        if [[ "$parent_component" != "$preset" ]]; then
          child_component="$preset_component"
          parent_component="${parent_component%_cores}"
          manifest_component="$parent_component"
        fi

        local preset_disabled_state
        preset_disabled_state=$(jq -r --arg comp "$manifest_component" \
          --arg core "$child_component" --arg preset "$preset" '
          .[] | .manifest | select(has($comp)) | .[$comp] |
          if $core != "" then
            .compatible_presets[$core][$preset][0] // empty
          else
            .compatible_presets[$preset][0] // empty
          end
        ' <<< "$manifest_cache")

        local preset_current_state
        preset_current_state=$(get_setting_value "$rd_conf" "$preset_component" "retrodeck" "$preset")

        if [[ "$preset_current_state" != "$preset_disabled_state" && -n "$preset_disabled_state" ]]; then
          log d "Disabling preset $preset for component $preset_component"
          set_setting_value "$rd_conf" "$preset_component" "$preset_disabled_state" "retrodeck" "$preset"
        fi
      done < <(jq -r --arg preset "$preset" '.presets[$preset] | to_entries[] |
        if (.key | endswith("_cores")) then
          .value | keys[]
        else
          .key
        end' "$rd_conf")
    done < <(jq -r '.presets | keys[]' "$rd_conf")
  fi
}

get_component_path() {
  # Return the installation path for a given component, resolving internal vs external automatically.
  # USAGE: get_component_path "$component_name"

  local component="$1"

  get_component_manifest_cache | jq -r --arg component "$component" '
    .[] | select(.manifest | has($component)) | .component_path
  ' | head -1
}

get_own_component_path() {
  # Return the installation path for the calling component, derived from the function name.
  # Expects to be called from a function named "something::component_name".
  # USAGE: get_own_component_path

  local caller="${FUNCNAME[1]}"
  local component="${caller##*::}"
  get_component_path "$component"
}

get_all_preset_definitions() {
  # Gather preset class definitions from all component manifests.
  # Framework definitions take precedence for shared preset classes.
  # Returns a JSON object keyed by preset name with name and description.
  # USAGE: get_all_preset_definitions

  get_component_manifest_cache | jq '
    reduce (.[] | .manifest | .. | objects | select(has("preset_definitions")) | .preset_definitions | to_entries[]) as $entry (
      {};
      if has($entry.key) then . else . + {($entry.key): $entry.value} end
    )
  '
}

get_component_version() {
  # Get the declared version of a component from its manifest.
  # Framework always returns the core application version.
  # USAGE: get_component_version "$component_name"

  local component="$1"

  if [[ "$component" == "retrodeck" ]]; then
    echo "$hard_version"
    return
  fi

  get_component_manifest_cache | jq -r --arg component "$component" '
    .[] | .manifest | select(has($component)) | .[$component].component_version // "0"
  ' | head -1
}

get_installed_component_version() {
  # Get the previously recorded version of a component from the config file.
  # Returns "0" if the component has never been initialized.
  # USAGE: get_installed_component_version "$component_name"

  local component="$1"

  jq -r --arg component "$component" '
    .component_versions[$component] // "0"
  ' "$rd_conf"
}

set_installed_component_version() {
  # Record a component's current version in the config file after successful update.
  # USAGE: set_installed_component_version "$component_name" "$version"

  local component="$1"
  local version="$2"

  if [[ ! "$component" == "retrodeck" ]]; then
    # Ensure the component_versions section exists
    if ! jq -e '.component_versions' "$rd_conf" > /dev/null 2>&1; then
      jq '. + {component_versions: {}}' "$rd_conf" > "$rd_conf.tmp" && mv "$rd_conf.tmp" "$rd_conf"
    fi

    jq --arg comp "$component" --arg ver "$version" \
      '.component_versions[$comp] = $ver' "$rd_conf" > "$rd_conf.tmp" && mv "$rd_conf.tmp" "$rd_conf"
  fi
}

check_component_compatibility() {
  # Check if a component is compatible with the current core API version.
  # USAGE: check_component_compatibility "$component_name"

  local component="$1"

  local manifest_cache
  manifest_cache=$(get_component_manifest_cache)

  local core_framework_version
  core_framework_version=$(jq -r '
    .[] | .manifest | select(has("framework")) | .framework.core_framework_version // "0"
  ' <<< "$manifest_cache" | head -1)

  local component_framework_compat
  component_framework_compat=$(jq -r --arg component "$component" '
    .[] | .manifest | select(has($component)) | .[$component].core_framework_compatibility // "0"
  ' <<< "$manifest_cache" | head -1)

  if [[ "$component_framework_compat" != "$core_framework_version" ]]; then
    log e "Component $component requires core API version $component_framework_compat but current is $core_framework_version"
    return 1
  fi

  return 0
}

validate_component_archive() {
  # Validate that a component archive contains the required files and a well-formed manifest.
  # Returns 0 if valid, 1 if not. Logs specific issues found.
  # USAGE: validate_component_archive "$archive_path"

  local archive="$1"
  local valid="true"

  if [[ ! -f "$archive" ]]; then
    log e "Archive not found: $archive"
    return 1
  fi

  # Check for required files in the archive
  local archive_contents
  archive_contents=$(tar -tzf "$archive" 2>/dev/null)

  if [[ $? -ne 0 ]]; then
    log e "Failed to read archive: $archive"
    return 1
  fi

  if ! grep -q 'component_manifest.json$' <<< "$archive_contents"; then
    log e "Archive missing required file: component_manifest.json"
    valid="false"
  fi

  if ! grep -q 'component_launcher.sh$' <<< "$archive_contents"; then
    log e "Archive missing required file: component_launcher.sh"
    valid="false"
  fi

  if [[ "$valid" == "false" ]]; then
    return 1
  fi

  # Extract and validate the manifest
  local tmp_dir
  tmp_dir=$(mktemp -d)

  tar -xzf "$archive" -C "$tmp_dir" --wildcards '*/component_manifest.json' 2>/dev/null \
    || tar -xzf "$archive" -C "$tmp_dir" 'component_manifest.json' 2>/dev/null

  local manifest_file
  manifest_file=$(find "$tmp_dir" -name "component_manifest.json" -type f | head -1)

  if [[ -z "$manifest_file" ]]; then
    log e "Could not extract component_manifest.json from archive"
    rm -rf "$tmp_dir"
    return 1
  fi

  # Validate JSON structure
  if ! jq empty "$manifest_file" 2>/dev/null; then
    log e "component_manifest.json is not valid JSON"
    rm -rf "$tmp_dir"
    return 1
  fi

  # Extract component name and check required manifest fields
  local comp_name
  comp_name=$(jq -r 'keys[0]' "$manifest_file")

  if [[ -z "$comp_name" || "$comp_name" == "null" ]]; then
    log e "component_manifest.json does not contain a valid component name"
    rm -rf "$tmp_dir"
    return 1
  fi

  local missing_fields=()

  if [[ $(jq -r --arg comp "$comp_name" '.[$comp].name // empty' "$manifest_file") == "" ]]; then
    missing_fields+=("name")
  fi

  if [[ $(jq -r --arg comp "$comp_name" '.[$comp].component_version // empty' "$manifest_file") == "" ]]; then
    missing_fields+=("component_version")
  fi

  if [[ $(jq -r --arg comp "$comp_name" '.[$comp].core_framework_compatibility // empty' "$manifest_file") == "" ]]; then
    missing_fields+=("core_framework_compatibility")
  fi

  if [[ ${#missing_fields[@]} -gt 0 ]]; then
    log e "Manifest for $comp_name is missing required fields: ${missing_fields[*]}"
    rm -rf "$tmp_dir"
    return 1
  fi

  # Check Framework compatibility
  local manifest_cache
  manifest_cache=$(get_component_manifest_cache)

  local core_framework_version
  core_framework_version=$(jq -r '
    .[] | .manifest | select(has("framework")) | .framework.core_framework_version // "0"
  ' <<< "$manifest_cache" | head -1)

  local component_framework_compat
  component_framework_compat=$(jq -r --arg comp "$comp_name" '.[$comp].core_framework_compatibility // "0"' "$manifest_file")

  if [[ "$component_framework_compat" != "$core_framework_version" ]]; then
    log e "Component $comp_name requires core Framework version $component_framework_compat but current is $core_framework_version"
    rm -rf "$tmp_dir"
    return 1
  fi

  # Lint shell scripts
  local lint_failed=false
  for script_name in component_launcher.sh component_functions.sh; do
    tar -xzf "$archive" -C "$tmp_dir" --wildcards "*/$script_name" 2>/dev/null \
      || tar -xzf "$archive" -C "$tmp_dir" "$script_name" 2>/dev/null
    local script_file
    script_file=$(find "$tmp_dir" -name "$script_name" -type f | head -1)
    if [[ -n "$script_file" ]]; then
      if ! bash -n "$script_file" 2>/dev/null; then
        log e "Linting errors found in $script_name"
        lint_failed=true
      fi
    fi
  done
  if [[ "$lint_failed" == true ]]; then
    log e "Component $comp_name has linting issues, cannot install."
    rm -rf "$tmp_dir"
    return 1
  fi

  rm -rf "$tmp_dir"
  log i "Component archive validated successfully: $comp_name"
  return 0
}

get_component_name_from_archive() {
  # Extract the component name from an archive's manifest without fully extracting the archive.
  # USAGE: get_component_name_from_archive "$archive_path"

  local archive="$1"
  local tmp_dir
  tmp_dir=$(mktemp -d)

  tar -xzf "$archive" -C "$tmp_dir" --wildcards '*/component_manifest.json' 2>/dev/null \
    || tar -xzf "$archive" -C "$tmp_dir" 'component_manifest.json' 2>/dev/null

  local manifest_file
  manifest_file=$(find "$tmp_dir" -name "component_manifest.json" -type f | head -1)

  if [[ -n "$manifest_file" ]]; then
    jq -r 'keys[0]' "$manifest_file"
  fi

  rm -rf "$tmp_dir"
}

install_external_component() {
  # Install an external component from a tar.gz archive into the external components directory.
  # Validates the archive, checks compatibility, handles shared libs/data, sources functions, and runs initialization.
  # USAGE: install_external_component "$archive_path"

  local archive="$1"

  log i "Installing external component from $archive"

  # Validate the archive
  if ! validate_component_archive "$archive"; then
    log e "Component archive validation failed, aborting installation"
    return 1
  fi

  local component_name
  component_name=$(get_component_name_from_archive "$archive")

  if [[ -z "$component_name" ]]; then
    log e "Could not determine component name from archive"
    return 1
  fi

  # Check if component already exists (internal or external)
  local existing_path
  existing_path=$(find_component_files "component_manifest.json" "$component_name")

  if [[ -n "$existing_path" ]]; then
    local existing_dir
    existing_dir=$(dirname "$existing_path")
    if [[ "$existing_dir" == "$rd_components/"* ]]; then
      log e "Component $component_name is already installed as an internal component and cannot be overridden"
      return 1
    else
      log w "Component $component_name is already installed externally, upgrading"
      _remove_external_component_files "$component_name"
    fi
  fi

  local component_path="$rd_external_components_path/$component_name"
  log d "Extracting $archive to $component_path"
  create_dir "$component_path"

  if ! tar -xzf "$archive" -C "$component_path"; then
    log e "Failed to extract archive"
    rm -rf "$component_path"
    return 1
  fi

  # Handle shared libs
  if [[ -d "$component_path/shared-libs" ]]; then
    log d "Merging shared-libs for $component_name"
    create_dir "$rd_external_components_path/shared-libs"
    cp -a --no-clobber "$component_path/shared-libs/." "$rd_external_components_path/shared-libs/"
    rm -rf "$component_path/shared-libs"
  fi

  # Handle shared data
  if [[ -d "$component_path/shared-data" ]]; then
    log d "Merging shared-data for $component_name"
    create_dir "$rd_external_components_path/shared-data"
    cp -a --no-clobber "$component_path/shared-data/." "$rd_external_components_path/shared-data/"
    rm -rf "$component_path/shared-data"
  fi

  # Rebuild the manifest cache to include the new component
  build_component_manifest_cache

  # Source the component's functions
  if [[ -f "$component_path/component_functions.sh" ]]; then
    log d "Sourcing component functions for $component_name"
    source "$component_path/component_functions.sh"
  fi

  # Initialize component options from manifest defaults
  init_component_options "$component_name"

  # Update presets for the new component
  update_component_presets

  # Run initialization
  local prepare_handler="_prepare_component::${component_name}"
  if declare -F "$prepare_handler" > /dev/null; then
    log d "Running initial setup for $component_name"
    "$prepare_handler" "reset"
  fi

  # Record the installed version
  local component_version
  component_version=$(get_component_version "$component_name")
  set_installed_component_version "$component_name" "$component_version"

  # Deploy helper files for the new component
  deploy_helper_files

  log i "Component $component_name installed successfully"
  return 0
}

remove_external_component_files() {
  # Remove an external component's files from the external components directory.
  # USAGE: remove_external_component_files "$component_name"

  local component_name="$1"
  local component_path="$rd_external_components_path/$component_name"

  if [[ -d "$component_path" ]]; then
    rm -rf "$component_path"
    log d "Removed component files at $component_path"
  fi
}

remove_external_component() {
  # Remove an installed external component, running cleanup hooks and removing config entries.
  # USAGE: remove_external_component "$component_name"

  local component_name="$1"
  local component_path="$rd_external_components_path/$component_name"

  if [[ ! -d "$component_path" ]]; then
    log e "External component $component_name is not installed"
    return 1
  fi

  # Verify this is actually an external component
  if [[ "$component_path" != "$rd_external_components_path/"* ]]; then
    log e "Component $component_name is not an external component and cannot be removed this way"
    return 1
  fi

  log i "Removing external component: $component_name"

  # Run the component's uninstall hook if it has one
  local prepare_handler="_prepare_component::${component_name}"
  if declare -F "$prepare_handler" > /dev/null; then
    log d "Running uninstall hook for $component_name"
    "$prepare_handler" "uninstall"
  fi

  # Remove component's preset entries from the config
  local presets_to_clean
  presets_to_clean=$(jq -r --arg component "$component_name" --arg component_cores "${component_name}_cores" '
    .presets | to_entries[] |
    select(.value | has($component) or has($component_cores)) |
    .key
  ' "$rd_conf")

  if [[ -n "$presets_to_clean" ]]; then
    local tmp
    tmp=$(mktemp)
    jq --arg component "$component_name" --arg component_cores "${component_name}_cores" '
      .presets |= with_entries(
        .value |= (del(.[$component]) | del(.[$component_cores]))
      )
      | .presets |= with_entries(select(.value | length > 0))
    ' "$rd_conf" > "$tmp" && mv "$tmp" "$rd_conf"
    log d "Cleaned up preset entries for $component_name"
  fi

  # Remove version tracking entry
  if jq -e --arg component "$component_name" '.component_versions | has($component)' "$rd_conf" > /dev/null 2>&1; then
    local tmp
    tmp=$(mktemp)
    jq --arg component "$component_name" 'del(.component_versions[$component])' "$rd_conf" > "$tmp" && mv "$tmp" "$rd_conf"
  fi

  # Remove component options from config
  remove_component_options "$component_name"

  # Remove the component files
  remove_external_component_files "$component_name"

  # Rebuild caches and re-source
  build_component_manifest_cache
  build_compression_lookups

  log i "Component $component_name removed successfully"
  return 0
}

check_component_for_update() {
  # Check if an external component has an update available.
  # Supports GitHub, GitLab, and Codeberg/Gitea release checking via update_url in the manifest, or a custom check function.
  # The update_url can be either a direct API URL or a repository URL (platform will be auto-detected).
  # Returns 0 if update available, 1 if not or unable to check.
  # Echoes the download URL if an update is available.
  # USAGE: check_component_for_update "$component_name"

  local component_name="$1"

  local manifest_cache
  manifest_cache=$(get_component_manifest_cache)

  local component_manifest
  component_manifest=$(jq -c --arg component "$component_name" '
    .[] | .manifest | select(has($component)) | .[$component]
  ' <<< "$manifest_cache" | head -1)

  if [[ -z "$component_manifest" || "$component_manifest" == "null" ]]; then
    log e "Manifest not found for component $component_name"
    return 1
  fi

  # Check for a custom update check function first
  local custom_checker="_check_update::${component_name}"
  if declare -F "$custom_checker" > /dev/null; then
    log d "Using custom update checker for $component_name"
    "$custom_checker"
    return $?
  fi

  # Fall back to update_url based checking
  local update_url
  update_url=$(jq -r '.update_url // empty' <<< "$component_manifest")

  if [[ -z "$update_url" ]]; then
    log d "No update_url or custom checker defined for $component_name, cannot check for updates"
    return 1
  fi

  local current_version
  current_version=$(jq -r '.component_version // "0"' <<< "$component_manifest")

  # Resolve the API URL and platform from the provided URL
  local resolved_api_url resolved_platform
  resolve_release_api_url "$update_url" resolved_api_url resolved_platform

  if [[ -z "$resolved_api_url" ]]; then
    log w "Could not determine API URL from update_url: $update_url"
    return 1
  fi

  log d "Checking for updates from $resolved_platform: $resolved_api_url"

  local latest_info
  latest_info=$(curl --silent --max-time 10 "$resolved_api_url" 2>/dev/null)

  if [[ -z "$latest_info" ]]; then
    log w "Failed to fetch update information for $component_name"
    return 1
  fi

  local latest_version download_url
  extract_release_info "$resolved_platform" "$latest_info" latest_version download_url

  if [[ -z "$latest_version" ]]; then
    log w "Could not determine latest version for $component_name"
    return 1
  fi

  if check_version_is_older_than "$current_version" "$latest_version"; then
    log i "Update available for $component_name: $current_version upgrades to $latest_version"
    echo "$download_url"
    return 0
  else
    log d "Component $component_name is up to date at $current_version"
    return 1
  fi
}

resolve_release_api_url() {
  # Resolve a repository or API URL into a platform-specific latest release API endpoint.
  # Supports GitHub, GitLab, and Codeberg/Gitea platforms.
  # USAGE: resolve_release_api_url "$url" "$api_url" "$platform"

  local url="$1"
  local -n api_url="$2"
  local -n platform="$3"

  # Already a direct API URL
  if [[ "$url" == *"/api/"* ]]; then
    api_url="$url"
    if [[ "$url" == *"api.github.com"* ]]; then
      platform="github"
    elif [[ "$url" == *"/api/v4/"* ]]; then
      platform="gitlab"
    elif [[ "$url" == *"/api/v1/"* ]]; then
      platform="codeberg"
    else
      platform="unknown"
    fi
    return
  fi

  # GitHub repository URL
  if [[ "$url" =~ ^https?://github\.com/([^/]+)/([^/]+) ]]; then
    local owner="${BASH_REMATCH[1]}"
    local repo="${BASH_REMATCH[2]}"
    repo="${repo%.git}"
    api_url="https://api.github.com/repos/$owner/$repo/releases/latest"
    platform="github"
    return
  fi

  # GitLab repository URL (gitlab.com or self-hosted)
  if [[ "$url" =~ ^(https?://[^/]*gitlab[^/]*)/([^/]+)/([^/]+) ]]; then
    local host="${BASH_REMATCH[1]}"
    local owner="${BASH_REMATCH[2]}"
    local repo="${BASH_REMATCH[3]}"
    repo="${repo%.git}"
    local encoded_path
    encoded_path=$(printf '%s' "$owner/$repo" | jq -sRr @uri)
    api_url="$host/api/v4/projects/$encoded_path/releases/permalink/latest"
    platform="gitlab"
    return
  fi

  # Codeberg repository URL
  if [[ "$url" =~ ^https?://codeberg\.org/([^/]+)/([^/]+) ]]; then
    local owner="${BASH_REMATCH[1]}"
    local repo="${BASH_REMATCH[2]}"
    repo="${repo%.git}"
    api_url="https://codeberg.org/api/v1/repos/$owner/$repo/releases/latest"
    platform="codeberg"
    return
  fi

  # Generic Gitea/Forgejo instance (has /api/v1 convention)
  if [[ "$url" =~ ^(https?://[^/]+)/([^/]+)/([^/]+) ]]; then
    local host="${BASH_REMATCH[1]}"
    local owner="${BASH_REMATCH[2]}"
    local repo="${BASH_REMATCH[3]}"
    repo="${repo%.git}"
    api_url="$host/api/v1/repos/$owner/$repo/releases/latest"
    platform="codeberg"
    log d "Assuming Gitea/Forgejo API for $host"
    return
  fi

  api_url=""
  platform=""
}

extract_release_info() {
  # Extract the version and download URL from a platform-specific API response.
  # USAGE: extract_release_info "$platform" "$api_response" "$version" "$download_url"

  local platform="$1"
  local response="$2"
  local -n version="$3"
  local -n download_url="$4"

  version=""
  download_url=""

  case "$platform" in

    "github" | "codeberg")
      # GitHub and Codeberg/Gitea share the same response format
      version=$(jq -r '.tag_name // empty' <<< "$response")
      version="${version#v}"
      download_url=$(jq -r '
        .assets // [] |
        map(select(.name | test("\\.(tar\\.gz|tgz)$"))) |
        first | .browser_download_url // empty
      ' <<< "$response")
      # Fall back to first asset if no tar.gz found
      if [[ -z "$download_url" ]]; then
        download_url=$(jq -r '.assets[0].browser_download_url // empty' <<< "$response")
      fi
      ;;

    "gitlab")
      version=$(jq -r '.tag_name // empty' <<< "$response")
      version="${version#v}"
      download_url=$(jq -r '
        .assets.links // [] |
        map(select(.name | test("\\.(tar\\.gz|tgz)$"))) |
        first | .direct_asset_url // empty
      ' <<< "$response")
      if [[ -z "$download_url" ]]; then
        download_url=$(jq -r '.assets.links[0].direct_asset_url // empty' <<< "$response")
      fi
      ;;

    *)
      # Try common field names as a fallback
      version=$(jq -r '.tag_name // .version // empty' <<< "$response")
      version="${version#v}"
      download_url=$(jq -r '.assets[0].browser_download_url // .download_url // empty' <<< "$response")
      ;;

  esac
}

update_external_component() {
  # Update an external component by downloading and installing a new version.
  # USAGE: update_external_component "$component_name"

  local component_name="$1"

  local download_url
  download_url=$(check_component_for_update "$component_name")

  if [[ $? -ne 0 || -z "$download_url" ]]; then
    log d "No update available or no download URL for $component_name"
    return 1
  fi

  log i "Downloading update for $component_name from $download_url"

  local tmp_archive
  tmp_archive=$(mktemp --suffix=".tar.gz")

  if ! curl --silent --location --output "$tmp_archive" "$download_url"; then
    log e "Failed to download update for $component_name"
    rm -f "$tmp_archive"
    return 1
  fi

  # install_external_component handles upgrading existing components
  if install_external_component "$tmp_archive"; then
    log i "Component $component_name updated successfully"
    rm -f "$tmp_archive"

    # Run post-update handler
    local installed_version
    installed_version=$(get_installed_component_version "$component_name")
    local handler="_post_update::${component_name}"
    if declare -F "$handler" > /dev/null; then
      "$handler" "$installed_version"
    fi

    # Record new version
    local new_version
    new_version=$(get_component_version "$component_name")
    set_installed_component_version "$component_name" "$new_version"

    return 0
  else
    log e "Failed to update component $component_name"
    rm -f "$tmp_archive"
    return 1
  fi
}

check_all_external_component_updates() {
  # Check all installed external components for available updates.
  # Returns a JSON array of components with updates available.
  # USAGE: check_all_external_component_updates

  local -a updatable=()

  while IFS= read -r component_dir; do
    [[ -z "$component_dir" ]] && continue
    local component_name
    component_name=$(basename "$component_dir")

    local download_url
    download_url=$(check_component_for_update "$component_name")
    if [[ $? -eq 0 && -n "$download_url" ]]; then
      local current_version
      current_version=$(get_component_version "$component_name")
      updatable+=("$component_name"$'\t'"$current_version"$'\t'"$download_url")
    fi
  done < <(find "$rd_external_components_path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

  if [[ ${#updatable[@]} -gt 0 ]]; then
    printf '%s\n' "${updatable[@]}" | jq -R 'split("\t") | {component: .[0], current_version: .[1], download_url: .[2]}' | jq -s '.'
  else
    echo '[]'
  fi
}

run_component_updates() {
  # Check all installed components for version changes and run their update handlers as needed.
  # For the transition from pre-0.11.0, legacy handlers are run once for all components.
  # USAGE: run_component_updates "$previous_app_version"

  local previous_app_version="$1"

  local manifest_cache
  manifest_cache=$(get_component_manifest_cache)

  local component_updated=false

  # Determine if this is a legacy upgrade (pre-component-versioning)
  local is_legacy_upgrade=false
  if check_version_is_older_than "$previous_app_version" "0.11.0"; then
    is_legacy_upgrade=true
    log i "Legacy upgrade detected from $previous_app_version, running legacy migration handlers"
  fi

  # All non-Framework components
  while IFS=$'\t' read -r component_name manifest_version; do
    [[ -z "$component_name" || "$component_name" == "framework" ]] && continue

    if ! check_component_compatibility "$component_name"; then
      log w "Skipping update for incompatible component: $component_name"
      continue
    fi

    # Run legacy handler if transitioning from pre-0.11.0
    if [[ "$is_legacy_upgrade" == true ]]; then
      local legacy_handler="_post_update_legacy::${component_name}"
      if declare -F "$legacy_handler" > /dev/null; then
        log d "Running legacy update handler for $component_name"
        component_updated=true
        "$legacy_handler" "$previous_app_version"
      fi
    fi

    local installed_version
    installed_version=$(get_installed_component_version "$component_name")

    # On legacy upgrade, component has no recorded version yet, so always run
    if [[ "$is_legacy_upgrade" == true || "$manifest_version" != "$installed_version" ]]; then
      local handler="_post_update::${component_name}"
      if declare -F "$handler" > /dev/null; then
        log d "Running post-update handler for $component_name (installed: $installed_version, manifest: $manifest_version)"
        component_updated=true
        "$handler" "$installed_version"
      fi
      set_installed_component_version "$component_name" "$manifest_version"
    else
      log d "Component $component_name is up to date at version $manifest_version"
    fi
  done < <(jq -r '
    .[] | .manifest | to_entries[] |
    [.key, (.value.component_version // "0")] | @tsv
  ' <<< "$manifest_cache")

  if [[ "$component_updated" == true ]]; then
    update_component_options
    update_component_presets
    deploy_helper_files
    build_retrodeck_current_presets
  fi
}

init_component_options() {
  # Initialize component options in the config file from the component's manifest defaults.
  # Only adds settings that don't already exist, preserving any existing values.
  # The manifest should declare defaults under a "component_options" key.
  # USAGE: init_component_options "$component_name"

  local component_name="$1"

  local manifest_cache
  manifest_cache=$(get_component_manifest_cache)

  local default_options
  default_options=$(jq -c --arg component "$component_name" '
    .[] | .manifest | select(has($component)) | .[$component].component_options // null
  ' <<< "$manifest_cache" | head -1)

  if [[ -z "$default_options" || "$default_options" == "null" ]]; then
    log d "No component_options defined in manifest for $component_name"
    return
  fi

  # Ensure the component_options section exists
  if ! jq -e '.component_options' "$rd_conf" > /dev/null 2>&1; then
    jq '. + {component_options: {}}' "$rd_conf" > "$rd_conf.tmp" && mv "$rd_conf.tmp" "$rd_conf"
  fi

  # Merge defaults without overwriting existing values
  jq --arg component "$component_name" --argjson defaults "$default_options" '
    .component_options[$component] = (
      ($defaults) as $d |
      (.component_options[$component] // {}) as $existing |
      reduce ($d | to_entries[]) as $entry (
        $existing;
        if has($entry.key) then . else . + {($entry.key): $entry.value} end
      )
    )
  ' "$rd_conf" > "$rd_conf.tmp" && mv "$rd_conf.tmp" "$rd_conf"

  log d "Component options initialized for $component_name"
}

update_component_options() {
  # Update component_options in the config file with any new defaults from component manifests.
  # Existing values are not modified.
  # USAGE: update_component_options

  local manifest_cache
  manifest_cache=$(get_component_manifest_cache)

  while IFS=$'\t' read -r component_name; do
    [[ -z "$component_name" ]] && continue
    init_component_options "$component_name"
  done < <(jq -r '
    .[] | .manifest | to_entries[] |
    select(.value.component_options != null) |
    .key
  ' <<< "$manifest_cache")

  log d "Component options updated from manifests"
}

remove_component_options() {
  # Remove all options for a component from the config file.
  # USAGE: remove_component_options "$component_name"

  local component_name="$1"

  if ! jq -e --arg component "$component_name" '.component_options | has($component)' "$rd_conf" > /dev/null 2>&1; then
    log d "No component_options to remove for $component_name"
    return
  fi

  jq --arg component "$component_name" '
    del(.component_options[$component])
    | if (.component_options | length) == 0 then del(.component_options) else . end
  ' "$rd_conf" > "$rd_conf.tmp" && mv "$rd_conf.tmp" "$rd_conf"

  log d "Component options removed for $component_name"
}

get_component_option() {
  # Get a component-specific option value from the config file.
  # USAGE: get_component_option "$component_name" "$setting_name"

  local component_name="$1"
  local setting_name="$2"

  jq -r --arg component "$component_name" --arg setting "$setting_name" '
    .component_options[$component][$setting] // empty
  ' "$rd_conf"
}

set_component_option() {
  # Set a component-specific option value in the config file. Only updates existing settings.
  # USAGE: set_component_option "$component_name" "$setting_name" "$value"

  local component_name="$1"
  local setting_name="$2"
  local value="$3"

  if ! jq -e --arg component "$component_name" --arg setting "$setting_name" '
    .component_options[$component] | has($setting)
  ' "$rd_conf" > /dev/null 2>&1; then
    log w "Setting $setting_name not found in component_options for $component_name, skipping"
    return 1
  fi

  jq --arg component "$component_name" --arg setting "$setting_name" --arg val "$value" '
    .component_options[$component][$setting] = $val
  ' "$rd_conf" > "$rd_conf.tmp" && mv "$rd_conf.tmp" "$rd_conf"

  log d "Set component option $component_name.$setting_name = $value"
}
