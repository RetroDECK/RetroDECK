#!/bin/bash

build_retrodeck_current_presets() {
  # This function will read the presets sections of the retrodeck.cfg file and build the default state if it is anything other than disabled
  # This can also be used to build the "current" state post-update after adding new systems
  # USAGE: build_retrodeck_current_presets

  while IFS= read -r preset # Iterate all presets listed in retrodeck.cfg
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
                                if $core != "" then
                                  .[$component].compatible_presets[$core][$preset].[0] // empty
                                else
                                  .[$component].compatible_presets[$preset].[0] // empty
                                end
                              ' "$rd_components/$component/component_manifest.json")
      
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
