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
