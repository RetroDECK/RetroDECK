#!/bin/bash

sed_escape_pattern() {
  # Escape a string for safe use in a sed pattern/match context, using ^ as the delimiter.
  # USAGE: escaped=$(sed_escape_pattern "$string")

  local input="$1"
  input="${input//\\/\\\\}"
  input="${input//./\\.}"
  input="${input//\*/\\*}"
  input="${input//\[/\\[}"
  input="${input//^/\\^}"
  input="${input//$/\\$}"
  printf '%s' "$input"
}

sed_escape_replacement() {
  # Escape a string for safe use in a sed replacement context, using ^ as the delimiter.
  # USAGE: escaped=$(sed_escape_replacement "$string")

  local input="$1"
  input="${input//\\/\\\\}"  # backslashes first
  input="${input//&/\\&}"    # ampersand
  input="${input//^/\\^}"    # delimiter
  printf '%s' "$input"
}

set_setting_value() {
  # Function for editing settings
  # This function acts as a router for individual component pair functions
  # The component should provide a _set_setting_value::<component name> function in its component_functions.sh file
  # USAGE: set_setting_value "$setting_file" "$setting_name" "$new_setting_value" "$system" ["$section_name"]

  local file="$1" setting="$2" value="$3" component="$4" section="${5:-}"

  log d "Setting $setting=$value in $file"

  if [[ ! -f "$file" ]]; then
    log e "File $file does not exist, cannot set setting $setting"
    return 1
  fi

  local set_handler="_set_setting_value::${component}"
  local get_handler="_get_setting_value::${component}"

  if ! declare -F "$set_handler" > /dev/null; then
    log e "No _set_setting_value handler found for component: $component"
    return 1
  fi

  if ! declare -F "$get_handler" > /dev/null; then
    log e "No _get_setting_value handler found for component: $component"
    return 1
  fi

  "$set_handler" "$file" "$setting" "$value" "$section"

  local result
  result=$("$get_handler" "$file" "$setting" "$section")

  if [[ "$result" != "$value" ]]; then
    log e "Failed to set $setting=$value in $file (got: $result)"
    return 1
  else
    log d "Successfully set $setting=$value in $file"
    return
  fi
}

get_setting_value() {
  # Function for getting the current value of a setting from a config file
  # This function acts as a router for individual component pair functions
  # The component should provide a _get_setting_value::<component name> function in its component_functions.sh file
  # USAGE: get_setting_value $setting_file "$setting_name" $system [$section]

  local file="$1" setting="$2" component="$3" section="${4:-}"

  if [[ ! -f "$file" ]]; then
    log e "File $file does not exist, cannot get setting $setting"
    return 1
  fi

  local handler="_get_setting_value::${component}"
  if ! declare -F "$handler" > /dev/null; then
    log e "No _get_setting_value handler found for component: $component"
    return 1
  fi

  local result
  result=$("$handler" "$file" "$setting" "$section")

  if [[ -n "$result" ]]; then
    echo "$result"
    return
  else
    log e "Failed to get setting $setting value from $file"
    return 1
  fi
}

get_setting_name() {
  # Function for getting the current name of a setting from a provided full config line
  # This function acts as a router for individual component pair functions
  # The component should provide a _get_setting_name::<component name> function in its component_functions.sh file
  # USAGE: get_setting_name "$setting_line" "$system" ["$section"]

  local line="$1" component="$2" section="${3:-}"

  if [[ ! -f "$line" ]]; then
    log e "No setting line provided, cannot perform name extraction"
    return 1
  fi

  local handler="_get_setting_name::${component}"
  if ! declare -F "$handler" > /dev/null; then
    log e "No _get_setting_name handler found for component: $component"
    return 1
  fi

  local result
  result=$("$handler" "$line" "$section")

  if [[ -n "$result" ]]; then
    echo "$result"
    return
  else
    log e "Failed to get setting name from $line"
    return 1
  fi  
}

add_setting() {
  # Function for adding a setting name and value to a file. This is useful for dynamically generated config files where a setting line may not exist until the setting is changed from the default.
  # This function acts as a router for individual component pair functions
  # The component should provide a _add_setting::<component name> function in its component_functions.sh file
  # USAGE: add_setting $setting_file $setting_name $setting_value $system [$section]

  local file="$1" setting="$2" value="$3" component="$4" section="${5:-}"

  if [[ ! -f "$file" ]]; then
    log e "File $file does not exist, cannot get setting $setting"
    return 1
  fi

  local handler="_add_setting::${component}"
  if ! declare -F "$handler" > /dev/null; then
    log e "No _add_setting handler found for component: $component"
    return 1
  fi

  "$handler" "$file" "$setting" "$value" "$section"
}

delete_setting() {
  # Function for removing a setting from a file. This is useful for dynamically generated config files where a setting line may not exist until the setting is changed from the default.
  # This function acts as a router for individual component pair functions
  # The component should provide a _delete_setting::<component name> function in its component_functions.sh file
  # USAGE: delete_setting $setting_file $setting_name $system [$section]

  local file="$1" setting="$2" component="$3" section="${4:-}"

  if [[ ! -f "$file" ]]; then
    log e "File $file does not exist, cannot get setting $setting"
    return 1
  fi

  local handler="_delete_setting::${component}"
  if ! declare -F "$handler" > /dev/null; then
    log e "No _delete_setting handler found for component: $component"
    return 1
  fi

  "$handler" "$file" "$setting" "$section"
}

disable_setting() {
  # Function for disabling a setting (via #) from a file.
  # This function acts as a router for individual component pair functions
  # The component should provide a _disable_setting::<component name> function in its component_functions.sh file
  # USAGE: disable_setting $setting_file $setting_line $system [$section]

  local file="$1" line="$2" component="$3" section="${4:-}"

  if [[ ! -f "$file" ]]; then
    log e "File $file does not exist, cannot get setting $setting"
    return 1
  fi

  local handler="_disable_setting::${component}"
  if ! declare -F "$handler" > /dev/null; then
    log e "No _disable_setting handler found for component: $component"
    return 1
  fi

  "$handler" "$file" "$line" "$section"
}

enable_setting() {
  # Function for enabling a setting (via removing a #) from a file.
  # This function acts as a router for individual component pair functions
  # The component should provide a _enable_setting::<component name> function in its component_functions.sh file
  # USAGE: enable_setting $setting_file $setting_line $system [$section]

  local file="$1" line="$2" component="$3" section="${4:-}"

  if [[ ! -f "$file" ]]; then
    log e "File $file does not exist, cannot get setting $setting"
    return 1
  fi

  local handler="_enable_setting::${component}"
  if ! declare -F "$handler" > /dev/null; then
    log e "No _enable_setting handler found for component: $component"
    return 1
  fi

  "$handler" "$file" "$line" "$section"
}

disable_file() {
  # This function adds the suffix ".disabled" to the end of a file to prevent it from being used entirely.
  # USAGE: disable_file $file_name

  mv "$(realpath "$1")" "$(realpath "$1")".disabled
}

enable_file() {
  # This function removes the suffix ".disabled" to the end of a file to allow it to be used.
  # USAGE: enable_file $file_name

  mv "$(realpath "$1".disabled)" "$(realpath "$(echo "$1" | sed -e 's/\.disabled//')")"
}

install_preset_files() {
  # Copy files from a source to a destination for use by a preset.
  # The destination path must be the FULL destination, even if it does not currently exist.
  # If the destination path does not exist it will be created.
  # USAGE: install_preset_files "$source" "$destination"

  local source="$1"
  local dest="$2"

  if [[ -d "$source" ]]; then
    [[ "$source" != */ ]] && source="${source}/"
  elif [[ ! -f "$source" ]]; then
    log d "Provided source $source is neither a valid file or directory"
    return 1
  fi

  if [[ -d "$dest" ]]; then
    [[ "$dest" != */ ]] && dest="${dest}/"
  fi

  log d "Installing files from $source to $dest"
  rsync -rlD --mkpath "$source" "$dest"
}

remove_preset_files() {
  # This function will remove installed preset files from a given destination.
  # If the source (the installed file/folder from its "shipped" location) is a file and the dest a file path to wherever it was installed when enabled, it will be removed.
  # If the source is a file and the dest is a directory (meaning the file would have been installed into a folder with other files in it), the specific file will be removed from the dest directory.
  # If the source is a directory and the dest is also a directory (meaning multiple files were installed somewhere), the function will compare all files in the source and remove them from the dest,
  # meaning even if multiple preset files were installed into a location containing non-preset files, only the correct ones (the ones that exist in the "shipped" location) will be removed.
  # In all cases, if the destination contains one or more subfolders which are empty after the files have been removed, they will be pruned as well.
  # Optionally, the mode can be set to "purge" and the dest will be removed regardless of other contents, so should only be used if there are no non-preset-related files there.
  # USAGE: remove_preset_files "$source" "$dest" ["$mode"]

  local source="$1"
  local dest="$2"
  local mode="${3:-}"

  if [[ ! -e "$source" ]]; then
    log d "Source location $source does not exist."
    return 1
  fi

  local dest_root
  if [[ -d "${dest%/}" ]]; then
    dest_root="${dest%/}"
  else
    dest_root=$(dirname "$dest")
  fi

  if [[ -f "$source" && -f "$dest" ]]; then # If source and dest are both single files
    log d "Removing preset file $(basename "$source") from location $dest_root"
    rm -f "$dest"
    prune_empty_parents "$dest_root" "$dest_root"
    return 0
  fi

  if [[ -f "$source" && -d "${dest%/}" ]]; then
    local base target
    base=$(basename "$source")
    target="${dest%/}/$base"
    if [[ -f "$target" ]]; then
      log d "Removing file $base from destination directory $dest"
      rm -f "$target"
      prune_empty_parents "$(dirname "$target")" "${dest%/}"
    fi
    prune_empty_parents "${dest%/}" "${dest%/}"
    return 0
  fi

  if [[ -d "${source%/}" && -d "${dest%/}" ]]; then # If both source and dest are directories
    if [[ "$mode" == "purge" ]]; then # Delete entire dest directory without checking contents
      log d "Purging preset file location $dest"
      rm -rf "$dest"
    else
      local source_dir="${source%/}"
      local dest_dir="${dest%/}"

      while IFS= read -r -d '' source_file; do
        local relative_path="${source_file#$source_dir/}"
        local target="$dest_dir/$relative_path"
        if [[ -f "$target" ]]; then
          log d "Preset file $target found, removing."
          rm -f "$target"
          prune_empty_parents "$(dirname "$target")" "$dest_dir"
        fi
      done < <(find "$source_dir" -type f -print0)

      prune_empty_parents "$dest_dir" "$dest_dir"
    fi
    return 0
  fi

  return 1
}

compress_game() {
  # Compress a file to its compatible format and optionally clean up source files.
  # Dispatches to the appropriate component handler based on format.
  # USAGE: compress_game "$format" "$full_path_to_input_file" "$cleanup_choice"

  local format="$1"
  local file="$2"
  local post_compression_cleanup="$3"
  local filename_no_extension="${file%.*}"
  local source_file=$(dirname "$(realpath "$file")")"/"$(basename "$file")
  local dest_file=$(dirname "$(realpath "$file")")"/${filename_no_extension##*/}"

  local handler="_compress_game::${format}"
  if ! declare -F "$handler" > /dev/null; then
    log e "No compression handler found for format: $format"
    return 1
  fi

  "$handler" "$source_file" "$dest_file"

  if [[ "$post_compression_cleanup" == "true" && -f "${file%.*}.$format" ]]; then
    log i "Performing post-compression file cleanup"
    local cleanup_handler="_post_compression_cleanup::${format}"
    if ! declare -F "$cleanup_handler" > /dev/null; then
      log e "No compression cleanup handler found for format: $format"
      return 1
    fi

    "$cleanup_handler" "$source_file"
  elif [[ "$post_compression_cleanup" == "true" ]]; then
    log i "Compressed file ${file%.*}.$format not found, skipping original file deletion"
  fi
}

build_retrodeck_current_presets() {
  # REBUILD
  # This function will read the presets sections of the retrodeck.json file and build the default state if it is anything other than disabled
  # This can also be used to build the "current" state post-update after adding new systems
  # USAGE: build_retrodeck_current_presets

  while IFS= read -r preset # Iterate all presets listed in retrodeck.json
  do
    while IFS= read -r component # Iterate all system names in this preset
    do
      if [[ ! -f "$rd_components/$component/component_manifest.json" ]]; then
        log i "Component manifest $component not found, may have been removed. Skipping preset updates."
        continue
      fi

      local child_component=""
      local parent_component="$(jq -r --arg preset "$preset" --arg component "$component" '
                                                                                          .presets[$preset]
                                                                                          | paths(scalars)
                                                                                          | select(.[-1] == $component)
                                                                                          | if length > 1 then .[-2] else $preset end
                                                                                          ' "$rd_conf")"

      if [[ ! "$parent_component" == "$preset" ]]; then # If the given component is a nested core
        parent_component="${parent_component%_cores}"
        child_component="$component"
        component="$parent_component"
      fi

      local preset_disabled_state=$(jq -r --arg component "$component" --arg core "$child_component" --arg preset "$preset" '
        .[] | .manifest | select(has($component)) | .[$component] |
        if $core != "" then
          .compatible_presets[$core][$preset][0] // empty
        else
          .compatible_presets[$preset][0] // empty
        end
      ' "$component_manifest_cache_file")
      
      if [[ -n "$child_component" ]]; then
        component="$child_component"
      fi

      local preset_current_state=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset")
      
      if [[ ! "$preset_current_state" == "$preset_disabled_state" ]]; then
        api_set_preset_state "$component" "$preset" "$preset_current_state"
      fi
    done < <(jq -r --arg preset "$preset" '.presets[$preset] | to_entries[] |
                                          if (.key | endswith("_cores")) then
                                            .value | keys[]
                                          else
                                            .key
                                          end' "$rd_conf")
  done < <(jq -r '.presets | keys[]' "$rd_conf")
}
