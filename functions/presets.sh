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

fetch_all_presets() {
  # TODO: Remove, likely not needed anymore
  # This function fetches all possible presets from the presets directory
  # USAGE: fetch_all_presets [--pretty] [system_name]

  local rd_config_presets_path="$rd_core_files/presets"
  local presets=()
  local pretty_presets=()
  local pretty_output=false
  local system_name=""

  if [[ "$1" == "--pretty" ]]; then
    pretty_output=true
    system_name="$2"
  else
    system_name="$1"
  fi

  if [[ -n "$system_name" ]]; then
    preset_file="$rd_config_presets_path/${system_name}_presets.cfg"
    if [[ -f "$preset_file" ]]; then
      while IFS= read -r line; do
        if [[ $line =~ ^(change|enable)\^([a-zA-Z0-9_]+)\^ ]]; then
          preset="${BASH_REMATCH[2]}"
          if [[ ! " ${presets[*]} " =~ " ${preset} " ]]; then
            presets+=("$preset")
            if $pretty_output; then
              pretty_preset_name=${preset//_/ } # Preset name prettification
              pretty_preset_name=$(echo "$pretty_preset_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1') # Preset name prettification
              pretty_presets+=("$pretty_preset_name")
            fi
          fi
        fi
      done < "$preset_file"
    fi
  else
    for preset_file in "$rd_config_presets_path"/*_presets.cfg; do
      while IFS= read -r line; do
        if [[ $line =~ ^change\^([a-zA-Z0-9_]+)\^ ]]; then
          preset="${BASH_REMATCH[1]}"
          if [[ ! " ${presets[*]} " =~ " ${preset} " ]]; then
            presets+=("$preset")
            if $pretty_output; then
              pretty_preset_name=${preset//_/ } # Preset name prettification
              pretty_preset_name=$(echo "$pretty_preset_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1') # Preset name prettification
              pretty_presets+=("$pretty_preset_name")
            fi
          fi
        fi
      done < "$preset_file"
    done
  fi

  if $pretty_output; then
    printf "%s\n" "${pretty_presets[@]}"
  else
    echo "${presets[@]}"
  fi
}

change_presets_cli() {
  # TODO: Rebuild for API use
  # This function will allow a user to change presets either individually or all for a preset class from the CLI.
  # USAGE: change_presets_cli "$preset" "$system/all" "$on/off"

  local preset="$1"
  local system="$2"
  local value="$3"
  local section_results
  section_results=$(sed -n '/\['"$preset"'\]/, /\[/{ /\['"$preset"'\]/! { /\[/! p } }' "$rd_conf" | sed '/^$/d')
  local all_emulators_in_preset="" # A CSV string containing all emulators in a preset block
  local all_other_emulators_in_preset="" # A CSV string containing every emulator except the one provided by the user in a preset block

  log d "Changing settings for preset: $preset"

  while IFS= read -r config_line; do
    # Build a list of all emulators in the preset block
    system_name=$(get_setting_name "$config_line" "retrodeck")
    if [[ -n $all_emulators_in_preset ]]; then
      all_emulators_in_preset+=","
    fi
    all_emulators_in_preset+="$system_name" # Build a list of all emulators in case user provides "all" as the system name

    if [[ "$value" =~ (false|off) && ! "$system" == "all" ]]; then # If the user is disabling a specific emulator, check for any other already enabled and keep them enabled
      system_value=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$preset")
      if [[ ! "$system_name" == "$system" && "$system_value" == "true" ]]; then
        log d "Other system $system_name is enabled for preset $preset, retaining setting."
        if [[ -n $all_other_emulators_in_preset ]]; then
          all_other_emulators_in_preset+=","
        fi
        all_other_emulators_in_preset+="$system_name" # Build a list of all emulators that are currently enabled that aren't the one being disabled
      fi
    fi

  done < <(printf '%s\n' "$section_results")

  if [[ "$value" =~ (true|on) ]]; then # If user is enabling one or more systems in a preset
    if [[ "$system" == "all" ]]; then
      log d "Enabling all emualtors for preset $preset"
      choice="$all_emulators_in_preset" # All emulators in the preset will be enabled
    else
      if [[ "$all_emulators_in_preset" =~ "$system" ]]; then
        log d "Enabling preset $preset for $system"
        choice="$system"
      else
        log i "Emulator $system does not support preset $preset, please check the command options and try again."
      fi
    fi
  else # If user is disabling one or more systems in a preset
    if [[ "$system" == "all" ]]; then
      choice="" # Empty string means all systems in preset should be disabled
    else
      choice="$all_other_emulators_in_preset"
    fi
  fi

  # Call make_preset_changes if the user made a selection,
  # or if an extra button was clicked (even if the resulting choice is empty, meaning all systems are to be disabled).
    log d "Calling make_preset_changes with choice: $choice"
    make_preset_changes "$preset" "$choice"
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
  # meaning even if multipl preset files were installed into a location containing non-preset files, only the correct ones (the ones that exist in the "shipped" location) will be removed.
  # In all cases, if the destination contains one or more subfolders which are empty after the files have been removed, they will be pruned as well.
  # USAGE: remove_preset_files "$source" "$dest"
  local source="$1"
  local dest="$2"
  local mode="$3"

  source=$(echo "$source" | envsubst)
  dest=$(echo "$dest" | envsubst)

  if [[ ! -e "$source" ]]; then # Validate that source exists at all.
    log d "Source location $source does not exist."
    return 1
  fi

  local dest_root
  if [[ -d "${dest%/}" ]]; then # Normalize destination path if it is a directory
    dest_root="${dest%/}"
  else
    dest_root="$(dirname "$dest")"
  fi

  if [[ -f "$source" && -f "$dest" ]]; then # If source and dest are both single files
    log d "Removing preset file $(basename "$source") from location $dest_root"
    rm -f "$dest"
    if [[ -d "$dest_root" && -z "$(ls -A "$dest_root")" ]]; then # If the parent folder of the dest file is empty, remove it
      log d "Parent folder $dest_root is empty, removing as well..."
      rmdir "$dest_root"
    fi
    return 0
  fi

  if [[ -f "$source" && -d "${dest%/}" ]]; then # If the source is a file and the dest is a directory, where the "source" file will be removed from the "dest" directory
    log d "Removing file $(basename "$source") from destination directory $dest"
    local base
    local target
    local parent_dir
    base="$(basename "$source")"
    target="${dest%/}/$base"
    if [[ -f "$target" ]]; then
      rm -f "$target"
      parent_dir="$(dirname "$target")"
      while [[ "$parent_dir" != "${dest%/}" && -d "$parent_dir" && -z "$(ls -A "$parent_dir")" ]]; do # Remove empty subdirs up to the dest path itself
        log d "Parent directory $parent_dir is empty, removing as well..."
        rmdir "$parent_dir"
        parent_dir="$(dirname "$parent_dir")"
      done
    fi
    if [[ -z "$(ls -A "${dest%/}")" ]]; then # If the dest dir itself is empty, also remove it
      log d "Destination directory $dest is empty, removing as well..."
      rmdir "${dest%/}"
    fi
    return 0
  fi

  if [[ -d "${source%/}" && -d "${dest%/}" ]]; then # If both source and dest are directories
    if [[ "$mode" == "purge" ]]; then # Delete entire dest directory without checking contents
      log d "Purging preset file location $dest"
      rm -rf "$dest"
    else
      log d "Removing preset files from $source located in $dest"
      local source_dir
      local dest_dir
      local relative_path
      local target
      local parent_dir
      source_dir="${source%/}"
      dest_dir="${dest%/}"

      while IFS= read -r -d '' source_file; do # find every file under source, remove its twin under dest
        relative_path="${source_file#$source_dir/}"
        target="$dest_dir/$relative_path"
        if [[ -f "$target" ]]; then
          log d "Preset file $target found, removing."
          rm -f "$target"
          parent_dir="$(dirname "$target")"
          while [[ "$parent_dir" != "$dest_dir" &&  -d "$parent_dir" && -z "$(ls -A "$parent_dir")" ]]; do # Remove empty subdirs up to the dest path itself
            log d "Parent directory $parent_dir is empty, removing as well..."
            rmdir "$parent_dir"
            parent_dir="$(dirname "$parent_dir")"
          done
        fi
      done < <(find "$source_dir" -type f -print0)

      if [[ -z "$(ls -A "$dest_dir")" ]]; then
        log d "Destination directory $dest is empty, removing as well..."
        rmdir "$dest_dir"
      fi
      return 0
    fi
  fi

  # If everything else fails, exit poorly
  return 1
}
