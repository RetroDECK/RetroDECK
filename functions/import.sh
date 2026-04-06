#!/bin/bash

# Rollback state arrays
declare -a import_rollback_config_backups=()   # "dest|backup_path" pairs
declare -a import_rollback_symlinks=()         # symlink paths to unlink
declare -a import_rollback_preset_changes=()   # "setting_file|setting|old_value|section" entries

resolve_entry_source() {
  # Resolve the full source path for an import entry, using the appropriate root.
  # USAGE: resolve_entry_source "$entry_source" "$sub_root" "$source_root"
  
  local entry_source="$1"
  local sub_root="$2"
  local source_root="$3"
  local root="$source_root"

  if [[ -n "$sub_root" ]]; then
    root="$sub_root"
  fi

  root=$(envsubst <<< "$root")
  entry_source=$(envsubst <<< "$entry_source")

  # If entry_source is already absolute, use it directly
  if [[ "$entry_source" == /* ]]; then
    echo "$entry_source"
  else
    echo "${root%/}/${entry_source}"
  fi
}

verify_import_space() {
  # Verify adequate free space across all destination filesystems for planned copy operations
  # Takes a JSON array of objects with "source" and "dest" keys as an argument
  # USAGE: verify_import_space "$copy_plan_json"
  
  local copy_plan="$1"
 
  if [[ -z "$copy_plan" || "$copy_plan" == "[]" ]]; then
    log d "No copy operations to verify space for"
    return 0
  fi
 
  local -A fs_needed
  local -A fs_avail
 
  while IFS= read -r entry; do
    local source dest source_size dest_fs
    source=$(jq -r '.source' <<< "$entry")
    dest=$(jq -r '.dest' <<< "$entry")
 
    if [[ -e "$source" ]]; then
      source_size=$(du -sk "$source" 2>/dev/null | awk '{print $1}')
      source_size=$((source_size + (source_size / 10)))  # Add 10% safety margin
    else
      log w "Source path $source does not exist, skipping space check for this entry"
      continue
    fi
 
    # Determine destination filesystem, use dest parent if dest doesn't exist yet
    local dest_check="$dest"
    while [[ ! -d "$dest_check" && -n "$dest_check" ]]; do
      dest_check=$(dirname "$dest_check")
    done
    dest_fs=$(df -k --output=target "$dest_check" 2>/dev/null | tail -1)
 
    if [[ -z "$dest_fs" ]]; then
      log e "Cannot determine filesystem for destination: $dest"
      return 1
    fi
 
    fs_needed["$dest_fs"]=$(( ${fs_needed["$dest_fs"]:-0} + source_size ))
 
    if [[ -z "${fs_avail["$dest_fs"]:-}" ]]; then
      fs_avail["$dest_fs"]=$(df -k --output=avail "$dest_check" 2>/dev/null | tail -1)
    fi
  done < <(jq -c '.[]' <<< "$copy_plan")
 
  for fs in "${!fs_needed[@]}"; do
    if [[ ${fs_needed["$fs"]} -ge ${fs_avail["$fs"]} ]]; then
      local needed_mb=$(( fs_needed["$fs"] / 1024 ))
      local avail_mb=$(( fs_avail["$fs"] / 1024 ))
      log e "Insufficient space on $fs: need ${needed_mb}MB, have ${avail_mb}MB"
      return 1
    fi
    log d "Space check passed for $fs: need $((fs_needed["$fs"] / 1024))MB, have $((fs_avail["$fs"] / 1024))MB"
  done
 
  return 0
}

get_import_source() {
  # Extract the full import_options block for a specific source from a specific component
  # USAGE: get_import_source "$component" "$source_key"
  
  local component="$1"
  local source_key="$2"

  jq -r --arg comp "$component" --arg source "$source_key" '
    .[] | .manifest | select(has($comp)) | .[$comp] |
    .import_options[$source] // empty
  ' "$component_manifest_cache_file"
}

reset_rollback_state() {
  # Clear all rollback tracking arrays
  # USAGE: reset_rollback_state

  import_rollback_config_backups=()
  import_rollback_symlinks=()
  import_rollback_preset_changes=()
}

rollback_import() {
  # Attempt to undo completed import operations after a failure
  # Restores config backups, removes symlinks, and reverts preset changes
  # USAGE: rollback_import

  log w "Rolling back import operations"

  # Restore config backups
  local pair
  for pair in "${import_rollback_config_backups[@]}"; do
    local dest="${pair%%|*}"
    local backup="${pair#*|}"
    if [[ -f "$backup" ]]; then
      log d "Restoring config backup: $backup -> $dest"
      mv -f "$backup" "$dest"
    fi
  done

  # Remove created symlinks
  local sym
  for sym in "${import_rollback_symlinks[@]}"; do
    if [[ -L "$sym" ]]; then
      log d "Removing symlink: $sym"
      unlink "$sym"
    fi
  done

  # Revert preset changes
  local entry
  for entry in "${import_rollback_preset_changes[@]}"; do
    local IFS='|'
    local parts
    read -ra parts <<< "$entry"
    local setting_file="${parts[0]}"
    local setting="${parts[1]}"
    local old_value="${parts[2]}"
    local section="${parts[3]:-}"
    log d "Reverting preset: $setting -> $old_value"
    set_setting_value "$setting_file" "$setting" "$old_value" "retrodeck" "$section"
  done

  log w "Rollback complete"
}

select_import_source() {
  # Present the user with a list of discovered import sources to choose from
  # Sources are validated for existence and tagged accordingly
  # USAGE: select_import_source "$sources_json"

  local sources_json="$1"
  local entry_count
  entry_count=$(jq -r 'length' <<< "$sources_json")
 
  if [[ "$entry_count" -eq 0 ]]; then
    log i "No import sources found in component manifests"
    configurator_generic_dialog "RetroDECK Import" "No import sources are defined in any component manifests."
    return 1
  fi
 
  # Build Zenity list arguments and validate each source
  local -a zenity_args=()
  local -a validated=()
 
  while IFS= read -r source_entry; do
    local source_key description component default_root resolved_root status
    source_key=$(jq -r '.source_key' <<< "$source_entry")
    description=$(jq -r '.description' <<< "$source_entry")
    component=$(jq -r '.component' <<< "$source_entry")
    default_root=$(jq -r '.default_root' <<< "$source_entry")
    resolved_root=$(envsubst <<< "$default_root")
 
    if [[ -d "$resolved_root" ]]; then
      status="Found"
    else
      status="Not found"
    fi
 
    zenity_args+=("$source_key" "$description" "$component" "$status")
    validated+=("$(jq -nc --arg source_key "$source_key" --arg comp "$component" \
      --arg desc "$description" --arg root "$resolved_root" --arg stat "$status" \
      '{source_key: $source_key, component: $comp, description: $desc, resolved_root: $root, status: $stat}')")
  done < <(echo "$sources_json" | jq -c '.[]')
 
  local selected
  selected=$(rd_zenity --list \
    --title="RetroDECK Import - Select Source" \
    --text="Select a project to import data from:" \
    --column="Key" --column="Description" --column="Component" --column="Status" \
    --hide-column=1 --print-column=1 \
    --width=700 --height=400 \
    "${zenity_args[@]}")
 
  if [[ -z "$selected" ]]; then
    log i "User cancelled import source selection"
    return 1
  fi
 
  # Return the validated entry for the selected project
  local entry
  for entry in "${validated[@]}"; do
    if [[ "$(echo "$entry" | jq -r '.source_key')" == "$selected" ]]; then
      echo "$entry"
      return 0
    fi
  done
 
  log e "Selected project key '$selected' not found in validated list"
  return 1
}

resolve_import_root() {
  # Ensure the import root path exists, prompting the user to browse if not found
  # USAGE: resolve_import_root "$resolved_root" "$description"

  local resolved_root="$1"
  local description="$2"

  if [[ -d "$resolved_root" ]]; then
    echo "$resolved_root"
    return 0
  fi

  log i "Default root not found at $resolved_root, prompting user"
  configurator_generic_dialog "RetroDECK Import" "The default location for $description was not found at:\n$resolved_root\n\nPlease browse to the correct location."

  local browsed_path
  browsed_path=$(directory_browse)
  if [[ $? -ne 0 || -z "$browsed_path" ]]; then
    log i "User cancelled directory browse for import root"
    return 1
  fi

  if [[ ! -d "$browsed_path" ]]; then
    log e "Browsed path does not exist: $browsed_path"
    return 1
  fi

  echo "$browsed_path"
  return 0
}

select_optional_entries() {
  # Present a Zenity checklist of optional import entries for the user to include or exclude
  # USAGE: select_optional_entries "$all_entries_json"

  local all_entries="$1"
 
  local optional_entries
  optional_entries=$(jq '[to_entries[] | select(.value.optional == true)]' <<< "$all_entries")
  local opt_count
  opt_count=$(jq 'length' <<< "$optional_entries")
 
  if [[ "$opt_count" -eq 0 ]]; then
    log d "No optional entries to present"
    echo "$all_entries" | jq '[to_entries[].key]'
    return 0
  fi
 
  local -a zenity_args=()

  mapfile -t zenity_args < <(echo "$optional_entries" | jq -r '
    .[] |
    "TRUE",
    (.key | tostring),
    .value.description,
    .value.entry_type
  ')
 
  local selected
  selected=$(rd_zenity --list --checklist \
    --title="RetroDECK Import - Optional Items" \
    --text="Select which optional items to import:" \
    --column="Import" --column="Index" --column="Description" --column="Type" \
    --hide-column=2 --print-column=2 \
    --separator="^" \
    --width=700 --height=400 \
    "${zenity_args[@]}")
 
  if [[ $? -ne 0 ]]; then
    log i "User cancelled optional entry selection"
    return 1
  fi
 
  local non_optional_entries
  non_optional_entries=$(jq '[to_entries[] | select(.value.optional != true) | .key]' <<< "$all_entries")
 
  local selected_optional_entries="[]"
  if [[ -n "$selected" ]]; then
    local -a selected_arr
    IFS='^' read -ra selected_arr <<< "$selected"
    selected_optional_entries=$(printf '%s\n' "${selected_arr[@]}" | jq -R 'tonumber' | jq -s '.')
  fi
 
  # Merge non-optional and selected optional entries
  echo "$non_optional_entries" "$selected_optional_entries" | jq -s 'add | sort | unique'
  return 0
}

select_data_methods() {
  # Present a Zenity checklist for optional data entries to choose copy (checked) or symlink (unchecked)
  # USAGE: select_data_methods "$optional_data_entries_json"

  local data_entries="$1"
  local entry_count
  entry_count=$(jq 'length' <<< "$data_entries")
 
  if [[ "$entry_count" -eq 0 ]]; then
    log d "No optional data entries for method selection"
    echo "[]"
    return 0
  fi
 
  local -a zenity_args=()

  mapfile -t zenity_args < <(echo "$data_entries" | jq -r '
    .[] |
    (if .default_method == "copy" then "TRUE" else "FALSE" end),
    .entry,
    .description
  ')
 
  local selected
  selected=$(rd_zenity --list --checklist \
    --title="RetroDECK Import - Import Method" \
    --text="Select import method per item.\nChecked = Copy data, Unchecked = Create symlink:" \
    --column="Copy" --column="Index" --column="Description" \
    --hide-column=2 --print-column=2 \
    --separator="^" \
    --width=700 --height=400 \
    "${zenity_args[@]}")
 
  if [[ $? -ne 0 ]]; then
    log i "User cancelled data method selection"
    return 1
  fi
 
  local copy_choices_json="[]"
  if [[ -n "$selected" ]]; then
    local -a copy_arr
    IFS='^' read -ra copy_arr <<< "$selected"
    copy_choices_json=$(printf '%s\n' "${copy_arr[@]}" | jq -R '.' | jq -s '.')
  fi
 
  echo "$data_entries" | jq --argjson copies "$copy_choices_json" '
    [.[] | .resolved_method = (if (.entry | IN($copies[])) then "copy" else "symlink" end)]
  '
  return 0
}

select_symlink_directions() {
  # For each data entry using the symlink method, let the user choose where real data lives
  # Checked = store real data in RetroDECK (dest), Unchecked = keep real data at source
  # USAGE: select_symlink_directions "$symlink_entries_json"

  local symlink_entries="$1"
  local entry_count
  entry_count=$(jq 'length' <<< "$symlink_entries")
 
  if [[ "$entry_count" -eq 0 ]]; then
    log d "No symlink entries for direction selection"
    echo "[]"
    return 0
  fi
 
  local -a zenity_args=()

  mapfile -t zenity_args < <(echo "$symlink_entries" | jq -r '
    .[] |
    "FALSE",
    .entry,
    .description,
    .resolved_source,
    .resolved_dest
  ')
 
  local selected
  selected=$(rd_zenity --list --checklist \
    --title="RetroDECK Import - Symlink Data Location" \
    --text="Choose where the real data should be stored for symlinked items.\nChecked = Move data into RetroDECK, Unchecked = Keep data at source location:" \
    --column="Move" --column="Index" --column="Description" --column="Source" --column="Destination" \
    --hide-column=2 --print-column=2 \
    --separator="^" \
    --width=900 --height=400 \
    "${zenity_args[@]}")
 
  if [[ $? -ne 0 ]]; then
    log i "User cancelled symlink direction selection"
    return 1
  fi
 
  # Convert selected move indices to JSON array and annotate all entries in a single jq pass
  local move_indices_json="[]"
  if [[ -n "$selected" ]]; then
    local -a move_arr
    IFS='^' read -ra move_arr <<< "$selected"
    move_indices_json=$(printf '%s\n' "${move_arr[@]}" | jq -R '.' | jq -s '.')
  fi
 
  echo "$symlink_entries" | jq --argjson moves "$move_indices_json" '
    [.[] | .real_data_at = (if (.entry | IN($moves[])) then "dest" else "source" end)]
  '
  return 0
}

show_import_summary() {
  # Display an informational summary of all non-optional import actions before execution
  # USAGE: show_import_summary "$import_plan_json"

  local import_plan="$1"
 
  local summary="The following mandatory actions will be performed:\n\n"
 
  # Non-optional config entries
  local mandatory_config_descs
  mandatory_config_descs=$(jq -r '[.config_entries[] | select(.optional != true) | .description] | .[]' <<< "$import_plan")
  if [[ -n "$mandatory_config_descs" ]]; then
    summary+="Configuration files to import:\n"
    while IFS= read -r desc; do
      summary+="  - $desc\n"
    done <<< "$mandatory_config_descs"
    summary+="\n"
  fi
 
  # Non-optional data entries
  local mandatory_data
  mandatory_data=$(jq -c '[.data_entries[] | select(.optional != true)] | .[]' <<< "$import_plan")
  if [[ -n "$mandatory_data" ]]; then
    summary+="Data to import:\n"
    while IFS= read -r data_entry; do
      local desc method
      desc=$(jq -r '.description' <<< "$data_entry")
      method=$(jq -r '.resolved_method' <<< "$data_entry")
      summary+="  - $desc ($method)\n"
    done <<< "$mandatory_data"
    summary+="\n"
  fi
 
  # Preset cleanup
  local component
  component=$(jq -r '.component' <<< "$import_plan")
  summary+="Presets for $component will be set to their default (disabled) state.\n"
 
  configurator_generic_question_dialog "RetroDECK Import - Confirm" "$summary\nProceed with import?" 
  return $?
}

backup_config() {
  # Create a timestamped backup of an existing config file.
  # USAGE: backup_config "$filepath"

  local filepath="$1"
  if [[ ! -f "$filepath" ]]; then
    log d "No existing file to back up at $filepath"
    return 0
  fi

  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_path="${filepath}.rd_backup_${timestamp}"
  cp -a "$filepath" "$backup_path"
  log i "Backed up $filepath -> $backup_path"
  echo "$backup_path"
  return 0
}

import_data_entries() {
  # Process all data import entries from the import plan
  # USAGE: import_data_entries "$import_plan_json"

  local import_plan="$1"
  local data_entries
  data_entries=$(jq -c '.data_entries[]' <<< "$import_plan")
 
  if [[ -z "$data_entries" ]]; then
    log d "No data entries to import"
    return 0
  fi
 
  while IFS= read -r entry; do
    local description source dest method
    description=$(jq -r '.description' <<< "$entry")
    source=$(jq -r '.resolved_source' <<< "$entry")
    dest=$(jq -r '.resolved_dest' <<< "$entry")
    method=$(jq -r '.resolved_method' <<< "$entry")
 
    log i "Importing data: $description ($method)"
 
    if [[ ! -e "$source" ]]; then
      log e "Source path does not exist: $source"
      return 1
    fi
 
    if [[ "$method" == "copy" ]]; then
      create_dir "$dest"
      if [[ -d "$source" ]]; then
        rsync -a "${source%/}/" "${dest%/}/"
      else
        rsync -a "$source" "$dest"
      fi
      if [[ $? -ne 0 ]]; then
        log e "Failed to copy data from $source to $dest"
        return 1
      fi
      log i "Copied $source -> $dest"
 
    elif [[ "$method" == "symlink" ]]; then
      local real_data_at
      real_data_at=$(jq -r '.real_data_at' <<< "$entry")
 
      if [[ "$real_data_at" == "source" ]]; then
        # Real data stays at source, symlink at dest
        dir_prep "$source" "$dest"
        import_rollback_symlinks+=("$dest")
      else
        # Real data moves into dest, symlink at source
        dir_prep "$dest" "$source"
        import_rollback_symlinks+=("$source")
      fi
 
      if [[ $? -ne 0 ]]; then
        log e "Failed to create symlink for $description"
        return 1
      fi
    fi
  done <<< "$data_entries"
 
  return 0
}

import_config_entries() {
  # Process all config import entries: backup existing, copy source to dest, run actions
  # USAGE: import_config_entries "$import_plan_json"

  local import_plan="$1"
  local component
  component=$(jq -r '.component' <<< "$import_plan")
  local config_entries
  config_entries=$(jq -c '.config_entries[]' <<< "$import_plan")
 
  if [[ -z "$config_entries" ]]; then
    log d "No config entries to import"
    return 0
  fi
 
  while IFS= read -r entry; do
    local description source dest
    description=$(jq -r '.description' <<< "$entry")
    source=$(jq -r '.resolved_source' <<< "$entry")
    dest=$(jq -r '.resolved_dest' <<< "$entry")
 
    log i "Importing config: $description"
 
    if [[ ! -f "$source" ]]; then
      log e "Source config file does not exist: $source"
      return 1
    fi
 
    # Backup existing config if present
    local backup_path
    backup_path=$(backup_config "$dest")
    if [[ -n "$backup_path" ]]; then
      import_rollback_config_backups+=("${dest}|${backup_path}")
    fi
 
    # Copy source config to dest
    create_dir "$(dirname "$dest")"
    cp -a "$source" "$dest"
    if [[ $? -ne 0 ]]; then
      log e "Failed to copy config from $source to $dest"
      return 1
    fi
    log i "Copied config $source -> $dest"
 
    # Apply actions
    while IFS= read -r action; do
      local action_type setting value section
      action_type=$(jq -r '.type // "set_setting_value"' <<< "$action")
      setting=$(jq -r '.setting' <<< "$action")
      value=$(jq -r '.value' <<< "$action")
      section=$(jq -r '.section // empty' <<< "$action")
 
      # Resolve any variables in the value
      value=$(envsubst <<< "$value")
 
      case "$action_type" in
        set_setting_value)
          log d "Setting: $setting = $value (section: ${section:-none})"
          set_setting_value "$dest" "$setting" "$value" "$component" "$section"
          if [[ $? -ne 0 ]]; then
            log e "Failed to set $setting in $dest"
            return 1
          fi
          ;;
        *)
          log w "Unknown action type: $action_type, skipping"
          ;;
      esac
    done < <(jq -c '(.actions // [])[]' <<< "$entry")
  done <<< "$config_entries"
 
  return 0
}

cleanup_component_presets() {
  # Set all presets for a given component to their disabled state
  # USAGE: cleanup_component_presets "$component"

  local component="$1"
 
  local -a preset_names
  mapfile -t preset_names < <(jq -r '.presets | keys[]' "$rd_conf" 2>/dev/null)
 
  if [[ ${#preset_names[@]} -eq 0 ]]; then
    log d "No presets found in core config"
    return 0
  fi
 
  local preset
  for preset in "${preset_names[@]}"; do
    local current_value
    current_value=$(jq -r --arg preset "$preset" --arg comp "$component" \
      '.presets[$preset] | to_entries[] | select(.key == $comp) | .value // empty' \
      "$rd_conf" 2>/dev/null)
 
    if [[ -z "$current_value" ]]; then
      continue
    fi
 
    local disabled_state
    disabled_state=$(jq -r --arg comp "$component" --arg preset "$preset" \
      '.[] | .manifest | select(has($comp)) | .[$comp] |
       .compatible_presets[$preset][0] // empty' \
      "$component_manifest_cache_file")
 
    if [[ -z "$disabled_state" ]]; then
      log w "Could not determine disabled state for preset $preset on component $component"
      continue
    fi
 
    if [[ "$current_value" == "$disabled_state" ]]; then
      log d "Preset $preset for $component is already in disabled state"
      continue
    fi
 
    # Store old value for rollback
    import_rollback_preset_changes+=("${rd_conf}|presets.${preset}.${component}|${current_value}|")
 
    log i "Setting preset $preset for $component to disabled state: $disabled_state"
    set_setting_value "$rd_conf" "presets.${preset}.${component}" "$disabled_state" "retrodeck"
  done
 
  return 0
}

run_import() {
  # Main entry point for the source import process
  # USAGE: run_import

  reset_rollback_state
 
  log i "Discovering import sources from manifests"
  local sources_json
  sources_json=$(jq -r '
    [
      .[] | .manifest | to_entries[] |
      select(.value | type == "object" and has("import_options")) |
      .key as $component |
      .value.import_options | to_entries[] |
      {
        project_key: .key,
        component: $component,
        description: (.value.description // .key),
        default_root: .value.default_root
      }
    ]
  ' "$component_manifest_cache_file")
 
  # Validation and source selection
  local selected_source
  selected_source=$(select_import_source "$sources_json")
  if [[ $? -ne 0 ]]; then
    return 1
  fi
 
  local source_key component description resolved_root
  source_key=$(jq -r '.source_key' <<< "$selected_project")
  component=$(jq -r '.component' <<< "$selected_project")
  description=$(jq -r '.description' <<< "$selected_project")
  resolved_root=$(jq -r '.resolved_root' <<< "$selected_project")
 
  log i "Selected import source: $description ($source_key) for component $component"
 
  # Root resolution
  resolved_root=$(resolve_import_root "$resolved_root" "$description")
  if [[ $? -ne 0 ]]; then
    return 1
  fi
  log i "Resolved import root: $resolved_root"
 
  # Fetch the full source definition from the manifest
  local source_def
  source_def=$(get_import_source "$component" "$source_key")
  if [[ -z "$source_def" ]]; then
    log e "Could not retrieve import definition for $source_key from $component manifest"
    return 1
  fi
 
  # Determine sub-roots
  local config_root data_root
  config_root=$(jq -r '.config.root // empty' <<< "$source_def")
  data_root=$(jq -r '.data.root // empty' <<< "$source_def")
  if [[ -n "$config_root" ]]; then
    config_root=$(envsubst <<< "$config_root")
  fi
  if [[ -n "$data_root" ]]; then
    data_root=$(envsubst <<< "$data_root")
  fi
 
  # Build a unified entry list with resolved paths and type annotations
  local all_entries
  all_entries=$(jq '
    [
      (.config.entries // [] | to_entries[] | .value + {
        entry_type: "config",
        entry: ("c" + (.key | tostring))
      }),
      (.data.entries // [] | to_entries[] | .value + {
        entry_type: "data",
        entry: ("d" + (.key | tostring))
      })
    ]
  ' <<< "$source_def")
 
  # Resolve source and dest paths for all entries
  local -a resolved_entries=()
  while IFS= read -r entry; do
    local entry_type source dest sub_root resolved_source resolved_dest
    entry_type=$(jq -r '.entry_type' <<< "$entry")
    source=$(jq -r '.source' <<< "$entry")
    dest=$(jq -r '.dest' <<< "$entry")
 
    if [[ "$entry_type" == "config" ]]; then
      sub_root="$config_root"
    else
      sub_root="$data_root"
    fi
 
    resolved_source=$(resolve_entry_source "$source" "$sub_root" "$resolved_root")
    resolved_dest=$(envsubst <<< "$dest")
 
    resolved_entries+=("$(echo "$entry" | jq -c --arg src "$resolved_source" --arg dst "$resolved_dest" \
      '. + {resolved_source: $src, resolved_dest: $dst}')")
  done < <(jq -c '.[]' <<< "$all_entries")
 
  # Reassemble into a JSON array
  all_entries=$(printf '%s\n' "${resolved_entries[@]}" | jq -s '.')
 
  # Optional entry selection
  local selected_optional_entries
  selected_optional_entries=$(select_optional_entries "$all_entries")
  if [[ $? -ne 0 ]]; then
    return 1
  fi
 
  # Filter to only selected entries
  local selected_entries
  selected_entries=$(echo "$all_entries" | jq --argjson entries "$selected_optional_entries" \
    '[to_entries[] | select(.key as $key | $entries | index($key)) | .value]')
 
  # Split into config and data entries
  local config_entries data_entries
  config_entries=$(jq '[.[] | select(.entry_type == "config")]' <<< "$selected_entries")
  data_entries=$(jq '[.[] | select(.entry_type == "data")]' <<< "$selected_entries")
 
  # Method selection for optional data entries
  local optional_data
  optional_data=$(jq '[.[] | select(.optional == true)]' <<< "$data_entries")
  optional_data=$(select_data_methods "$optional_data")
  if [[ $? -ne 0 ]]; then
    return 1
  fi
 
  # Apply resolved methods: non-optional entries use default_method, optional entries get their user-selected method merged
  data_entries=$(jq --argjson opts "$optional_data" '
    ($opts | map({(.entry): .resolved_method}) | add // {}) as $method_map |
    [.[] | .resolved_method = (
      if .optional != true then .default_method
      else ($method_map[.entry] // .default_method) end
    )]
  ' <<< "$data_entries")
 
  # Symlink direction selection
  local symlink_entries
  symlink_entries=$(jq '[.[] | select(.resolved_method == "symlink")]' <<< "$data_entries")
  symlink_entries=$(select_symlink_directions "$symlink_entries")
  if [[ $? -ne 0 ]]; then
    return 1
  fi
 
  # Merge symlink directions back into data_entries via a single jq pass
  data_entries=$(jq --argjson syms "$symlink_entries" '
    ($syms | map({(.idx): .real_data_at}) | add // {}) as $dir_map |
    [.[] | if .resolved_method == "symlink" then .real_data_at = ($dir_map[.idx] // "source") else . end]
  ' <<< "$data_entries")
 
  # Build the full import plan
  local import_plan
  import_plan=$(jq -nc \
    --arg key "$source_key" \
    --arg comp "$component" \
    --arg desc "$description" \
    --arg root "$resolved_root" \
    --argjson config "$config_entries" \
    --argjson data "$data_entries" \
    '{
      source_key: $key,
      component: $comp,
      description: $desc,
      resolved_root: $root,
      config_entries: $config,
      data_entries: $data
    }')
 
  # Non-optional summary and confirmation
  show_import_summary "$import_plan"
  if [[ $? -ne 0 ]]; then
    log i "User cancelled import at confirmation"
    return 1
  fi
 
  # Space verification for copy operations and inbound symlinks
  log i "Verifying available disk space"
  local copy_plan
  copy_plan=$(jq '
    [
      (.data_entries[] | select(
        .resolved_method == "copy" or
        (.resolved_method == "symlink" and .real_data_at == "dest")
      ) | {source: .resolved_source, dest: .resolved_dest})
    ]
  ' <<< "$import_plan")
 
  verify_import_space "$copy_plan"
  if [[ $? -ne 0 ]]; then
    log e "Insufficient disk space for import"
    rd_zenity --error --title="RetroDECK Import" \
      --text="There is not enough free disk space to complete this import.\nPlease free up space and try again." \
      --width=400
    return 1
  fi
 
  # Import data entries
  log i "Importing data entries"
  import_data_entries "$import_plan"
  if [[ $? -ne 0 ]]; then
    log e "Data import failed, initiating rollback"
    rollback_import
    rd_zenity --error --title="RetroDECK Import" \
      --text="Data import failed. Changes have been rolled back where possible.\nCheck the log for details." \
      --width=400
    return 1
  fi
 
  # Import config entries and apply actions
  log i "Importing config entries"
  import_config_entries "$import_plan"
  if [[ $? -ne 0 ]]; then
    log e "Config import failed, initiating rollback"
    rollback_import
    rd_zenity --error --title="RetroDECK Import" \
      --text="Config import failed. Changes have been rolled back where possible.\nCheck the log for details." \
      --width=400
    return 1
  fi
 
  # Preset cleanup
  log i "Cleaning up component presets"
  cleanup_component_presets "$component"
  if [[ $? -ne 0 ]]; then
    log e "Preset cleanup failed, initiating rollback"
    rollback_import
    rd_zenity --error --title="RetroDECK Import" \
      --text="Preset cleanup failed. Changes have been rolled back where possible.\nCheck the log for details." \
      --width=400
    return 1
  fi
 
  log i "Import of $description into $component completed successfully"
  configurator_generic_dialog "RetroDECK Import" "Import of $description completed successfully."

  return 0
}
