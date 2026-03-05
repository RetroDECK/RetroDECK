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

get_all_helper_files() {
  # Gather all helper file information from all component manifests, including the source path for each file.
  # Returns a JSON array of helper file objects with filename, location, and source_path.
  # USAGE: get_all_helper_files

  get_component_manifest_cache | jq '
    [.[] | .component_path as $component_path |
     .manifest | .. | objects | select(has("helper_files")) |
     .helper_files | to_entries[].value |
     . + {source_path: ($component_path + "/helper_files")}]
  '
}

deploy_helper_files() {
  # Distribute helper documentation files throughout the filesystem according to component manifest configurations.
  # USAGE: deploy_helper_files

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    read -r file dest source_path < <(jq -r '[.filename, .location, .source_path] | @tsv' <<< "$entry")
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
  done < <(get_all_helper_files | jq -c '.[]')
}

source_component_functions() {
  # Source component_functions.sh files from installed components, making their variables and functions globally available.
  # Framework is always sourced first as it provides core application infrastructure.
  # A specific component name can be given to source only that component.
  # USAGE: source_component_functions "[$component] (optional, default: all)"

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
    while IFS= read -r func_file; do
      [[ -z "$func_file" ]] && continue
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

  if [[ "$1" == "factory-reset" ]]; then
    log i "User requested full RetroDECK reset"
    rm -f "$rd_lockfile" && log d "Lockfile removed"
    retrodeck
    return
  fi

  local action="$1"
  local component="$2"

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
