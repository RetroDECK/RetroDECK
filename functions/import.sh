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
