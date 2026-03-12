#!/bin/bash

directory_browse() {
  # Browse for a directory and return the selected path.
  # Returns 1 if the user exits without selecting.
  # USAGE: selected_path=$(directory_browse "$action_text")

  local action_text="$1"

  while true; do
    local target
    target=$(rd_zenity --file-selection --title="Choose $action_text" --directory)

    if [[ -n "$target" ]]; then
      rd_zenity --question --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK" \
        --cancel-label="No" --ok-label="Yes" \
        --text="Directory <span foreground='$purple'><b>$target</b></span> selected.\nIs this correct?"
      if [[ $? -eq 0 ]]; then
        echo "$target"
        return 0
      fi
    else
      rd_zenity --question --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK" \
        --cancel-label="No" --ok-label="Yes" \
        --text="No directory selected.\n\n<span foreground='$purple'><b>Do you want to exit the selection process?</b></span>"
      if [[ $? -eq 0 ]]; then
        return 1
      fi
    fi
  done
}

file_browse() {
  # This function browses for a file and returns the path chosen
  # Returns 1 if the user exits without selecting.
  # USAGE: file_to_be_browsed_for=$(file_browse $action_text)

  local action_text="$1"
  local file_selected=false

  while true; do
    local target
    target="$(rd_zenity --file-selection --title="Choose $action_text")"
    if [[ -n "$target" ]]; then
      rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label="Yes" \
      --text="File <span foreground='$purple'><b>$target</b></span> selected.\nIs this correct?"
      if [[ $? -eq 0 ]]; then
        echo "$target"
        return 0
      fi
    else
      rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label="Yes" \
      --text="No file selected. Do you want to exit the selection process?"
      if [[ $? -eq 0 ]]; then
        return 1
      fi
    fi
  done
}

verify_space() {
  # Function used for verifying adequate space before moving directories around
  # USAGE: verify_space $source_dir $dest_dir
  # Function returns "true" if there is enough space, "false" if there is not

  source_size=$(du -sk "$1" | awk '{print $1}')
  source_size=$((source_size+(source_size/10))) # Add 10% to source size for safety
  dest_avail=$(df -k --output=avail "$2" | tail -1)

  if [[ $source_size -ge $dest_avail ]]; then
    return 1
  else
    return 0
  fi
}

move() {
  # Function to move a directory from one parent to another
  # USAGE: move $source_dir $dest_dir

  source_dir="$(echo "$1" | sed 's![^/]$!&/!')" # Add trailing slash if it is missing
  dest_dir="$(echo "$2" | sed 's![^/]$!&/!')" # Add trailing slash if it is missing

  log d "Moving \"$source_dir\" to \"$dest_dir\""

  (
    rsync -a --remove-source-files --ignore-existing --mkpath "$source_dir" "$dest_dir" # Copy files but don't overwrite conflicts
    find "$source_dir" -type d -empty -delete # Cleanup empty folders that were left behind
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - Move in Progress" \
  --text="Moving directory:\n<span foreground='$purple'><b>$(basename "$1")</b></span>\n\nTo its new location:\n<span foreground='$purple'><b>$2</b></span>.\n\n<span foreground='$purple'><b>Please wait while the process finishes</b></span>.\nThis might take a while..."

  if [[ -d "$source_dir" ]]; then # Some conflicting files remain
    rd_zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Move Directories" \
    --text="Some files could not be moved because they already exist in the destination.\n\n\<span foreground='$purple'><b>All other files have been moved to the new location. You will need to handle the remaining conflicts manually.</b></span>"
  fi
}

create_dir() {
  # A simple function that creates a directory checking if is still there while logging the activity
  # If -d it will delete it prior the creation

  if [[ "$1" == "-d" ]]; then
    shift
    if [[ -e "$1" ]]; then
      rm -rf "$1" # Forcefully delete the directory
      log d "Found \"$1\", deleting it."
    fi
  fi

  if [[ -z "$1" ]]; then
    log e "No directory specified for creation"
    return 1
  fi

  if [[ ! -d "$1" ]]; then
    mkdir -p "$1"
    log d "Created directory: $1"
  else
    log d "Directory \"$1\" already exists, skipping."
  fi
}

download_file() {
  # Function to download file from the Internet, with Zenity progress bar
  # USAGE: download_file $source_url $file_dest $file_name
  # source_url is the location the file is downloaded from
  # file_dest is the destination the file should be in the filesystem, needs filename included!
  # file_name is a user-readable file name or description to be put in the Zenity dialog
  local source="$1"
  local dest="$2"
  local name="$3"

  (
    curl --silent --location --output "$dest" "$source"
  ) |
  rd_zenity --progress \
    --title="Downloading File" \
    --text="Downloading <span foreground='$purple'><b>$name</b></span>..." \
    --pulsate \
    --auto-close
}

conf_read() {
  # Read the RetroDECK JSON config file and load version, paths, and options into global variables.
  # USAGE: conf_read

  while IFS=$'\t' read -r name value; do
    [[ -z "$name" ]] && continue
    declare -g "$name=$value"
    export "$name"
  done < <(jq -r '
    ({ version: .version }
    + (.paths   // {})
    + (.options // {})
    )
    | to_entries[]
    | [.key, (.value | tostring)]
    | @tsv
  ' "$rd_conf")

  if [[ -n "$rd_logging_override" ]]; then
    rd_logging_level="$rd_logging_override"
    export rd_logging_level
  fi

  log d "retrodeck.json read and loaded"
}

conf_write() {
  # Write current in-memory values for version, paths, and options back to the RetroDECK JSON config file.
  # USAGE: conf_write

  local tmp jq_args=() filter

  jq_args+=(--arg version "$version")
  filter='.version = $version'

  while read -r setting_name; do
    [[ -z "$setting_name" ]] && continue
    local setting_value="${!setting_name}"
    jq_args+=(--arg "$setting_name" "$setting_value")
    filter+=" | .paths.$setting_name = \$$setting_name"
  done < <(jq -r '(.paths // {}) | keys[]' "$rd_conf")

  while read -r setting_name; do
    [[ -z "$setting_name" ]] && continue
    local setting_value="${!setting_name}"
    jq_args+=(--arg "$setting_name" "$setting_value")
    filter+=" | .options.$setting_name = \$$setting_name"
  done < <(jq -r '(.options // {}) | keys[]' "$rd_conf")

  tmp=$(mktemp)
  jq "${jq_args[@]}" "$filter" "$rd_conf" > "$tmp" && mv "$tmp" "$rd_conf"

  log d "retrodeck.json written"
}

dir_prep() {
  # Create a symlink at a specified location pointing to a real directory, merging any existing data.
  # If conflicting files exist during the merge, they are preserved in a lost+found directory.
  # USAGE: dir_prep "$real_dir" "$symlink_location"

  if [[ -z "$1" || -z "$2" ]]; then
    log e "dir_prep requires both a real directory and symlink location"
    return 1
  fi

  local real symlink
  real=$(realpath -s "$1")
  symlink=$(realpath -s "$2")

  log d "Preparing directory: real=$real symlink=$symlink"

  if [[ -L "$symlink" ]]; then
    log d "$symlink is already a symlink, unlinking"
    unlink "$symlink"
  fi

  local staged_dir=""
  if [[ -d "$symlink" ]]; then
    staged_dir=$(mktemp -d "${symlink}.merging.XXXXXX" 2>/dev/null) || staged_dir=$(mktemp -d)
    log d "$symlink is an existing directory, staging as $staged_dir"
    mv -f "$symlink" "$staged_dir/contents"
  fi

  if [[ -L "$real" ]]; then
    log d "$real is already a symlink, unlinking"
    unlink "$real"
  fi

  if [[ ! -d "$real" ]]; then
    log d "$real not found, creating"
    create_dir "$real"
  fi

  create_dir "$(dirname "$symlink")"
  ln -svf "$real" "$symlink"
  log d "Linked $symlink -> $real"

  if [[ -n "$staged_dir" && -d "$staged_dir/contents" ]]; then
    # Merge non-conflicting files into real, skipping any that already exist
    rsync -a --ignore-existing "$staged_dir/contents/" "$real/"

    # Remove successfully merged files, leaving only conflicts behind
    rsync -a --ignore-existing --delete "$real/" "$staged_dir/contents/" 2>/dev/null

    # Anything remaining in staged is a conflict
    if [[ -n "$(find "$staged_dir/contents" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
      local lost_found="$real/lost_and_found"
      create_dir "$lost_found"
      rsync -a "$staged_dir/contents/" "$lost_found/"
      log w "Conflicting files preserved in $lost_found"
    fi

    rm -rf "$staged_dir"
    log d "Merge complete"
  fi

  log i "$symlink is now linked to $real"
}

backup_retrodeck_userdata() {
  # This function can compress one or more RetroDECK userdata folders into a single zip file for backup.
  # The function can do a "complete" backup of all userdata including ROMs and ES-DE media, so can end up being very large.
  # The function can also do a "core" backup of all the very important userdata files (like saves, states and gamelists) or a "custom" backup of only specified paths
  # The function can take both folder names as defined in retrodeck.cfg or full paths as arguments for folders to backup
  # It will also validate that all the provided paths exist and that there is enough free space to perform the backup before actually proceeding.
  # It will also rotate backups so that there are only 3 maximum of each type (complete, core or custom)
  # USAGE: backup_retrodeck_userdata complete
  #        backup_retrodeck_userdata core
  #        backup_retrodeck_userdata custom saves_path states_path /some/other/path

  create_dir "$backups_path"

  # Check if first argument is the type
  if [[ "$1" == "complete" || "$1" == "core" || "$1" == "custom" ]]; then
    backup_type="$1"
    shift # Remove the first argument
  else
    if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
      configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "No valid backup option chosen. Valid options are <standard> and <custom>."
    fi
    log e "No valid backup option chosen. Valid options are <complete>, <core> and <custom>."
    return 1
  fi

  backup_date=$(date +"%0m%0d_%H%M")
  backup_log_file="$logs_path/${backup_date}_${backup_type}_backup_log.log"
  backup_file="$backups_path/retrodeck_${backup_date}_${backup_type}.tar.gz"

  # Initialize paths arrays
  paths_to_backup=()
  declare -A config_paths # Requires an associative (dictionary) array to work

  # Build array of folder names and real paths from retrodeck.json
  while read -r config_path; do
    if check_version_is_older_than "$version_being_updated" "0.10.0b"; then # Skip paths newly added in 0.10.0b, as they do not exist yet
      if [[ "$config_path" =~ (portmaster_path|storage_path|videos_path) ]]; then
        log i "Skipping $config_path as it is new to 0.10.0b and does not exist yet"
        continue
      fi
    fi
    local path_var=$(echo "$config_path" | jq -r '.key')
    local path_value=$(echo "$config_path" | jq -r '.value')
    log d "Adding $path_value to compressible paths."
    config_paths["$path_var"]="$path_value"
  done < <(jq -c '.paths | to_entries[] | select(.key != "rd_home_path" and .key != "backups_path" and .key != "logs_path" and .key != "sdcard")' "$rd_conf")

  # Determine which paths to backup
  if [[ "$backup_type" == "complete" ]]; then
    for folder_name in "${!config_paths[@]}"; do
      path_value="${config_paths[$folder_name]}"
      if [[ -e "$path_value" ]]; then
        paths_to_backup+=("$path_value")
        log i "Adding to backup: $folder_name = $path_value"
      else
        if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
          configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The <span foreground='$purple'><b>$folder_name</b></span> was not found at its expected location: <span foreground='$purple'><b>$path_value</b></span>.\nSomething may be wrong with your RetroDECK installation."
        fi
        log i "Warning: Path does not exist: $folder_name = $path_value"
      fi
    done

    # Add static paths not defined in retrodeck.cfg
    if [[ -e "$rd_home_path/ES-DE/collections" ]]; then
      paths_to_backup+=("$rd_home_path/ES-DE/collections")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The ES-DE collections folder was not found at its expected location: <span foreground='$purple'><b>$rd_home_path/ES-DE/collections</b></span>.\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/collections = $rd_home_path/ES-DE/collections"
    fi

    if [[ -e "$rd_home_path/ES-DE/gamelists" ]]; then
      paths_to_backup+=("$rd_home_path/ES-DE/gamelists")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The ES-DE gamelists folder was not found at its expected location: <span foreground='$purple'><b>$rd_home_path/ES-DE/gamelists</b></span>.\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/gamelists = $rd_home_path/ES-DE/gamelists"
    fi

    if [[ -e "$rd_home_path/ES-DE/custom_systems" ]]; then
      paths_to_backup+=("$rd_home_path/ES-DE/custom_systems")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The ES-DE custom_systems folder was not found at its expected location: <span foreground='$purple'><b>$rd_home_path/ES-DE/custom_systems</b></span>.\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/custom_systems = $rd_home_path/ES-DE/custom_systems"
    fi

    # Check if we found any valid paths
    if [[ ${#paths_to_backup[@]} -eq 0 ]]; then
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "<span foreground='$purple'><b>No valid userdata folders were found.</b></span>\nSomething may be wrong with your RetroDECK installation."
      fi
      log e "Error: No valid paths found in config file"
      return 1
    fi

  elif [[ "$backup_type" == "core" ]]; then
    for folder_name in "${!config_paths[@]}"; do
      if [[ $folder_name =~ (saves_path|states_path) ]]; then # Only include these paths
        path_value="${config_paths[$folder_name]}"
        if [[ -e "$path_value" ]]; then
          paths_to_backup+=("$path_value")
          log i "Adding to backup: $folder_name = $path_value"
        else
          if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
            configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The <span foreground='$purple'><b>$folder_name</b></span> was not found at its expected location: <span foreground='$purple'><b>$path_value</b></span>.\nSomething may be wrong with your RetroDECK installation."
          fi
          log i "Warning: Path does not exist: $folder_name = $path_value"
        fi
      fi
    done

    # Add static paths not defined in retrodeck.cfg
    if [[ -e "$rd_home_path/ES-DE/collections" ]]; then
      paths_to_backup+=("$rd_home_path/ES-DE/collections")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The ES-DE collections folder was not found at its expected location, $rd_home_path/ES-DE/collections\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/collections = $rd_home_path/ES-DE/collections"
    fi

    if [[ -e "$rd_home_path/ES-DE/gamelists" ]]; then
      paths_to_backup+=("$rd_home_path/ES-DE/gamelists")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The ES-DE collections folder was not found at its expected location: <span foreground='$purple'><b>$rd_home_path/ES-DE/collections</b></span>.\nSomething may be wrong with your RetroDECK installation.."
      fi
      log i "Warning: Path does not exist: ES-DE/gamelists = $rd_home_path/ES-DE/gamelists"
    fi

    if [[ -e "$rd_home_path/ES-DE/custom_systems" ]]; then
      paths_to_backup+=("$rd_home_path/ES-DE/custom_systems")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The ES-DE custom_systems folder was not found at its expected location: <span foreground='$purple'><b>$rd_home_path/ES-DE/custom_systems</b></span>.\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/custom_systems = $rd_home_path/ES-DE/custom_systems"
    fi

    # Check if we found any valid paths
    if [[ ${#paths_to_backup[@]} -eq 0 ]]; then
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "<span foreground='$purple'><b>No valid userdata folders were found.</b></span>\nSomething may be wrong with your RetroDECK installation."
      fi
      log e "Error: No valid paths found in config file"
      return 1
    fi

  elif [[ "$backup_type" == "custom" ]]; then
    if [[ "$#" -eq 0 ]]; then # Check if any paths were provided in the arguments
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "<span foreground='$purple'><b>No valid backup locations were specified.</b></span> Please try again."
      fi
      log e "Error: No paths specified for custom backup"
      return 1
    fi

    # Process each argument - it could be a variable name or a direct path
    for arg in "$@"; do
      # Check if argument is a variable name in the config
      if [[ -n "${config_paths[$arg]}" ]]; then
        path_value="${config_paths[$arg]}"
        if [[ -e "$path_value" ]]; then
          paths_to_backup+=("$path_value")
          log i "Added to backup: $arg = $path_value"
        else
          if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
            configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The <span foreground='$purple'><b>$arg</b></span> was not found at its expected location: <span foreground='$purple'><b>$path_value</b></span>.\nSomething may be wrong with your RetroDECK installation."
          fi
          log e "Error: Path from variable '$arg' does not exist: $path_value"
          return 1
        fi
      # Otherwise treat it as a direct path
      elif [[ -e "$arg" ]]; then
        paths_to_backup+=("$arg")
        log i "Added to backup: $arg"
      else
        if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
          configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The path <span foreground='$purple'><b>$arg</b></span> was not found at its expected location.\nPlease check the path and try again."
        fi
        log e "Error: '$arg' is neither a valid variable name nor an existing path"
        return 1
      fi
    done
  fi

  # Calculate total size of selected paths
  log i "Calculating size of backup data..."

  total_size=0

  if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then # Show progress dialog if running Zenity Configurator
    total_size_file=$(mktemp) # Create temp file for Zenity subshell data extraction
    (
    for path in "${paths_to_backup[@]}"; do
      if [[ -e "$path" ]]; then
        log d "Checking size of path $path"
        path_size=$(du -sk "$path" 2>/dev/null | cut -f1) # Get size in KB
        path_size=$((path_size * 1024)) # Convert to bytes for calculation
        total_size=$((total_size + path_size))
        echo "$total_size" > "$total_size_file"
      fi
    done
    ) |
    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator - Backup Userdata" \
            --text="Verifying there is enough free space for the backup.\n\n<span foreground='$purple'><b>Please wait while the process finishes...</b></span>"
    total_size=$(cat "$total_size_file")
    rm "$total_size_file" # Clean up temp file
  else # If running in CLI
    for path in "${paths_to_backup[@]}"; do
      if [[ -e "$path" ]]; then
        log d "Checking size of path $path"
        path_size=$(du -sk "$path" 2>/dev/null | cut -f1) # Get size in KB
        path_size=$((path_size * 1024)) # Convert to bytes for calculation
        total_size=$((total_size + path_size))
      fi
    done
  fi

  # Get available space at destination
  available_space=$(df -B1 "$backups_path" | awk 'NR==2 {print $4}')

  # Log sizes for reference
  log i "Total size of backup data: $(numfmt --to=iec-i --suffix=B "$total_size")"
  log i "Available space at destination: $(numfmt --to=iec-i --suffix=B "$available_space")"

  # Check if we have enough space (using uncompressed size as a conservative estimate)
  if [[ "$available_space" -lt "$total_size" ]]; then
    if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
      configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "There is not enough free space to perform this backup.\n\nYou need at least <span foreground='$purple'><b>$(numfmt --to=iec-i --suffix=B "$total_size")</b></span>.\nPlease free up some space and try again."
    fi
    log e "Error: Not enough space to perform backup. Need at least $(numfmt --to=iec-i --suffix=B "$total_size")"
    return 1
  fi

  log i "Starting backup process..."

  if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then # Show progress dialog if running Zenity Configurator
    (
      # Create backup with selected paths
      if tar -czhf "$backup_file" "${paths_to_backup[@]}" >> "$backup_log_file" 2>&1; then
        # Rotate backups for the specific type
        cd "$backups_path" || return 1
        ls -t *_${backup_type}.tar.gz | tail -n +4 | xargs -r rm

        final_size=$(du -h "$backup_file" | cut -f1)
        configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "Backup <span foreground='$purple'><b>$backup_file</b></span> completed successfully\n\nSize: <span foreground='$purple'><b>$final_size</b></span>\n\nRotated backups: last 3 <span foreground='$purple'><b>$backup_type</b></span>."
        log i "Backup completed successfully: $backup_file (Size: $final_size)"
        log i "Older backups rotated, keeping latest 3 of type $backup_type"

        if [[ ! -s "$backup_log_file" ]]; then # If the backup log file is empty, meaning tar threw no errors
          rm -f "$backup_log_file"
        fi
      else
        configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "Something went wrong during the backup.\n\nPlease review the log <span foreground='$purple'><b>$backup_log_file</b></span> for details."
        log i "Error: Backup failed"
        return 1
      fi
    ) |
    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator - Backup Userdata" \
            --text="Compressing files into backup.\n\n<span foreground='$purple'><b>Please wait while the process finishes...</b></span>"
  else
    if tar -czhf "$backup_file" "${paths_to_backup[@]}" >> "$backup_log_file" 2>&1; then
      # Rotate backups for the specific type
      cd "$backups_path" || return 1
      ls -t *_${backup_type}.tar.gz | tail -n +4 | xargs -r rm

      final_size=$(du -h "$backup_file" | cut -f1)
      log i "Backup completed successfully: $backup_file (Size: $final_size)"
      log i "Older backups rotated, keeping latest 3 of type $backup_type"

      if [[ ! -s "$backup_log_file" ]]; then # If the backup log file is empty, meaning tar threw no errors
        rm -f "$backup_log_file"
      fi
    else
      log i "Error: Backup failed"
      return 1
    fi
  fi
}

finit() {
  # First-time initialization and setup of RetroDECK.
  # Guides the user through storage location selection and optional component setup.
  # USAGE: finit

  log i "Executing finit"

  local finit_dest_choice
  local path_choice

  finit_dest_choice=$(configurator_destination_choice_dialog "RetroDECK data" \
    "<b>Welcome to RetroDECKs first-time setup!</b>\n\nRead each prompt carefully during installation so everything is configured correctly.\n\nChoose where RetroDECK should store its data.\n\nA data folder named <span foreground='$purple'><b>retrodeck</b></span> will be created at the location you choose.\n\nThis folder will hold all of your important files:\n\n<span foreground='$purple'><b>ROMs and Games \nBIOS and Firmware \nGame Saves \nArt Data \nEtc...</b></span>.")

  case "${finit_dest_choice:-}" in

    "Quit" | "Back" | "")
      log i "User closed the window or chose to quit"
      rm -f "$rd_conf"
      exit 2
      ;;

    "Internal Storage" | "Home Directory")
      log i "Internal selected"
      set_setting_value "$rd_conf" "rd_home_path" "$HOME/retrodeck" "retrodeck" "paths"
      if [[ -L "$rd_home_path" ]]; then
        unlink "$rd_home_path"
      fi
      ;;

    "SD Card")
      log i "SD Card selected"
      local -a external_devices=()

      while read -r size device_path; do
        local device_name
        device_name=$(basename "$device_path")
        log d "External device $device_path found"
        external_devices+=("$device_name" "$size" "$device_path")
      done < <(df --output=size,target -h | grep "/run/media/" | awk '{$1=$1;print}')

      if [[ ${#external_devices[@]} -gt 0 ]]; then
        configurator_generic_dialog "RetroDeck Installation - SD Card" \
          "One or more external storage devices have been detected.\n\nPlease select the device where you would like to create the <span foreground='$purple'><b>retrodeck</b></span> data folder."
        path_choice=$(rd_zenity --list --title="RetroDECK Configurator - USB Migration Tool" --cancel-label="Back" \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
          --hide-column=3 --print-column=3 \
          --column "Device Name" \
          --column "Device Size" \
          --column "path" \
          "${external_devices[@]}")

        if [[ ! -n "$path_choice" ]]; then
          log i "User closed the window or chose to quit"
          rm -f "$rd_conf"
          exit 2
        fi
      else
        log e "No external storage detected"
        rd_zenity --error --no-wrap \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK" \
          --ok-label "Browse" \
          --text="No external drives were detected.\n\nPlease select the device where you would like to create the <span foreground='$purple'><b>retrodeck</b></span> data folder."
        if path_choice="$(directory_browse "SD card location")"; then
          log i "User closed the window or chose to quit"
          rm -f "$rd_conf"
          exit 2
        fi
      fi

      if [[ ! -w "$path_choice" ]]; then
        log e "SD card found but not writable"
        rd_zenity --error --no-wrap \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK" \
          --ok-label "Quit" \
          --text="SD card detected, but it cannot be written to.\n\nThis often occurs when the card was formatted on a PC.\n\nWhat to do:\n\nSwitch the Steam Deck to <span foreground='$purple'><b>Game Mode</b></span>.\nSettings > System > Format SD Card\n\nRun RetroDECK again."
        rm -f "$rd_conf"
        log i "Now quitting"
        quit_retrodeck
      else
        set_setting_value "$rd_conf" "rd_home_path" "$path_choice/retrodeck" "retrodeck" "paths"
      fi
      ;;

    "Custom Location")
      log i "Custom Location selected"
      rd_zenity --info --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK" \
        --ok-label "Browse" \
        --text="Choose a location for the <span foreground='$purple'><b>retrodeck</b></span> data folder."
      if path_choice="$(directory_browse "custom storage location")"; then
        set_setting_value "$rd_conf" "rd_home_path" "$path_choice/retrodeck" "retrodeck" "paths"
      else
        log i "User closed the window or chose to quit"
        rm -f "$rd_conf"
        exit 2
      fi
      ;;

  esac

  log i "\"retrodeck\" folder will be located in \"$rd_home_path\""

  # Set up framework paths and write initial config
  prepare_component "reset" "retrodeck"

  # Source component functions now that config paths are loaded
  source_component_functions

  # Gather finit options from component manifests
  local -a finit_choices=()
  local manifest_cache
  manifest_cache=$(get_component_manifest_cache)

  while IFS= read -r finit_entry; do
    [[ -z "$finit_entry" ]] && continue
    local option_dialog option_action
    IFS=$'\t' read -r option_dialog option_action < <(jq -r '[.dialog, .action] | @tsv' <<< "$finit_entry")
    if launch_command "$option_dialog"; then
      finit_choices+=("$option_action")
    fi
  done < <(jq -c '[.[] | .manifest | .. | objects | select(has("finit_options")) | .finit_options[]] | .[]' <<< "$manifest_cache")

  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK Initial Install - Start" \
    --text="RetroDECK is now going to install the required files.\nWhen the installation finishes, RetroDECK will launch automatically.\n\n<span foreground='$purple'><b>This may take up to a minute or two</b></span>\n\nPress <span foreground='$purple'><b>OK</b></span> to continue."

  # Set up progress pipe for zenity
  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --pulsate --no-cancel --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK: Installing" \
    --text="RetroDECK is completing its initial setup.\n\nPlease check for any background <span foreground='$purple'><b>windows or pop-ups</b></span> that may require your attention.\n\n<span foreground='$purple'><b>Please wait while the setup process completes...</b></span>" \
    < "$progress_pipe" &
  local zenity_pid=$!

  # Open the pipe for writing
  exec 3>"$progress_pipe"

  echo "# Resetting components..." >&3
  prepare_component "reset" "all-installed"

  echo "# Applying presets..." >&3
  update_component_presets

  echo "# Deploying helper files..." >&3
  deploy_helper_files

  if [[ ${#finit_choices[@]} -gt 0 ]]; then
    local total_choices=${#finit_choices[@]}
    local choice_idx=0
    for choice in "${finit_choices[@]}"; do
      choice_idx=$((choice_idx + 1))
      local progress=$((70 + (30 * choice_idx / total_choices)))
      echo "$progress" >&3
      echo "# Processing: $choice..." >&3
      log d "Processing finit user choice $choice"
      launch_command "$choice"
    done
  else
    echo "100" >&3
  fi

  # Close the pipe and clean up
  exec 3>&-
  wait "$zenity_pid" 2>/dev/null
  rm -f "$progress_pipe"

  rd_zenity --question --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --ok-label="Start RetroDECK" \
    --cancel-label="Return to Desktop" \
    --title "RetroDECK Initial Setup - Complete" \
    --text="RetroDECK initial setup is Complete!\n\nEither <span foreground='$purple'><b>Start RetroDECK</b></span> or <span foreground='$purple'><b>Return to Desktop</b></span>.\n\nPlace your <span foreground='$purple'><b>Game Files</b></span> in the following directory:\n\n<span foreground='$purple'><b>$rd_home_path/roms\n\n</b></span>Place your <span foreground='$purple'><b>BIOS and Firmware Files</b></span> in the following directory:\n\n<span foreground='$purple'><b>$rd_home_path/bios</b></span>\n\nTIP: Check out the <span foreground='$purple'><b>RetroDECK Wiki and Website</b></span>\n\nThey contain detailed guides and tips on getting the most out of RetroDECK.\n\nHave a fantastic time!\n\nRetroDECK Team"

  if [[ $? -eq 1 ]]; then
    quit_retrodeck
  fi
}

install_release() {
  log d "Attempting to install release: $1 from repo $update_repo"

  if [ "$(get_setting_value "$rd_conf" "update_repo" "retrodeck" "options")" == "RetroDECK" ]; then
      iscooker=""
  else
      iscooker="-cooker"
  fi

  local base_url="https://github.com/$git_organization_name/$update_repo/releases/download/$1"

  # Query the release and list the assets for debugging/logging
  local release_info=$(curl -s "https://api.github.com/repos/$git_organization_name/$update_repo/releases/tags/$1")

  rd_zenity --question --icon-name=net.retrodeck.retrodeck --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Updater" \
    --text="<span foreground='$purple'><b>$1</b></span> will now be installed.\nThe update process may take several minutes.\n\nAfter the update is complete, RetroDECK will close. When you run it again, you will be using the latest version.\n\nDo you want to continue?"

  rc=$?
  if [[ $rc == "1" ]]; then
    return 0
  fi

  (
    mkdir -p "$rd_home_path/RetroDECK_Updates"
    cd "$rd_home_path/RetroDECK_Updates"

    log d "Assets for release $1:"
    asset_names=$(echo "$release_info" | jq -r '.assets[].browser_download_url')
    log d "Asset filenames for release $1:"
    assets_list=()
    while IFS= read -r asset; do
      log d "  $asset"
      assets_list+=("$asset")
    done <<< "$asset_names"

    # Find all files matching RetroDECK*.flatpak* in the release assets and store them in a list variable
    flatpak_assets=()
    for asset in "${assets_list[@]}"; do
      if [[ "$asset" == *".flatpak"* ]]; then
        flatpak_assets+=("$asset")
        log d "Found flatpak asset: $asset"
        log d "downloading it to $rd_home_path/RetroDECK_Updates"
        if ! wget -q -O "$rd_home_path/RetroDECK_Updates/$(basename "$asset")" "$asset"; then
          log e "Failed to download $asset"
          configurator_generic_dialog "Online Update - Error: Archive" "Failed to download the Flatpak file: <span foreground='$purple'><b>RetroDECK update aborted.</b></span>\nPlease check your internet connection and try again."
          log d "$rd_home_path/RetroDECK_Updates folder contents:\n$(ls -l "$rd_home_path/RetroDECK_Updates")"
          return 1
        fi
      fi
    done

    # Check for any .7z or .7z.001 files in the download folder and extract them
    local current_dir=$(pwd)
    cd "$rd_home_path/RetroDECK_Updates"
    for archive in *.7z *.7z.001; do
      if [[ -f "$archive" ]]; then
        log d "Found archive $archive, extracting it..."
        if ! 7z x -aoa "$archive" && rm -f *.7z*; then
          log e "Failed to extract $archive"
          configurator_generic_dialog "Online Update - Error: Archive" "Failed to extract the split archive: <span foreground='$purple'><b>RetroDECK update aborted.</b></span>"
          log d "$rd_home_path/RetroDECK_Updates folder contents:\n$(ls -l "$rd_home_path/RetroDECK_Updates")"
          rm -rf "$rd_home_path/RetroDECK_Updates"
          return 1
        fi
      fi
    done
    cd "$current_dir"

    # Find the .flatpak file and verify its SHA256 checksum if a .sha file exists
    flatpak_name="RetroDECK$iscooker.flatpak"
    flatpak_path="$rd_home_path/RetroDECK_Updates/$flatpak_name"
    sha_file="$rd_home_path/RetroDECK_Updates/RetroDECK.flatpak$iscooker.sha"

    if [[ -f "$flatpak_path" && -f "$sha_file" ]]; then
      log d "Found $flatpak_name and corresponding SHA file: $sha_file"
      expected_sha=$(cat "$sha_file" | awk '{print $1}')
      actual_sha=$(sha256sum "$flatpak_path" | awk '{print $1}')
      if [[ "$expected_sha" != "$actual_sha" ]]; then
        log e "SHA256 mismatch for $flatpak_name! Expected: $expected_sha, Actual: $actual_sha"
        if configurator_generic_question_dialog "SHA256 Mismatch" "The SHA256 checksum for $flatpak_name does not match.\nThe file may be corrupted or incomplete.\n\nDo you want to continue with the installation anyway?"; then
          rm -rf "$rd_home_path/RetroDECK_Updates"
          return 1
        fi
        log w "User decided to continue with installation despite SHA256 mismatch for $flatpak_name"
        log w "Expected hash: $expected_sha"
        log w "Actual hash:   $actual_sha"
      else
        log d "SHA256 checksum verified for $flatpak_name"
      fi
    fi

    # Proceed with Flatpak update
    flatpak-spawn --host flatpak remove --noninteractive -y net.retrodeck.retrodeck
    flatpak-spawn --host flatpak install --user --bundle --noninteractive -y "$flatpak_name"

    # Cleanup
    rm -rf "$rd_home_path/RetroDECK_Updates"
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Updater" \
    --text="RetroDECK is updating to the selected version.\n\n<span foreground='$purple'><b>Please wait while the process finishes...</b></span>"

  configurator_generic_dialog "RetroDECK - Online Update" "<span foreground='$purple'><b>The update process is now complete!</b></span>\n\nRetroDECK will now quit."
  quit_retrodeck
}

release_selector() {
  # Show a progress bar
  ( 
    while true; do
      echo "# Fetching all available releases from GitHub repositories... Please wait. This may take some time." ; sleep 1
    done
  ) | rd_zenity --progress --title="Fetching Releases" --text="Fetching releases..." --pulsate --no-cancel --auto-close --width=500 --height=150 &
  
  progress_pid=$!  # save process PID to kill it later

  log d "Fetching releases from GitHub API for repository $cooker_repository_name"
  
  # Fetch the main release from the RetroDECK repository
  log d "Fetching latest main release from GitHub API for repository RetroDECK"
  local main_release=$(curl -s "https://api.github.com/repos/$git_organization_name/RetroDECK/releases/latest")

  if [[ -z "$main_release" ]]; then
    log e "Failed to fetch the main release"
    kill $progress_pid  # kill the progress bar
    configurator_generic_dialog "Online Update - Error: Main" "<span foreground='$purple'><b>Unable to fetch the main release.</b></span> Please check your internet connection or try again later."
    return 1
  fi

  main_tag_name=$(echo "$main_release" | jq -r '.tag_name')
  main_published_at=$(echo "$main_release" | jq -r '.published_at')

  # Convert published_at to human-readable format for the main release
  main_human_readable_date=$(date -d "$main_published_at" +"%d %B %Y %H:%M")

  # Add the main release as the first entry in the release array
  local release_array=("Main Release" "$main_tag_name" "$main_human_readable_date")

  # Fetch all releases (including draft and pre-release) from the Cooker repository
  local releases=$(curl -s "https://api.github.com/repos/$git_organization_name/$cooker_repository_name/releases?per_page=100")

  if [[ -z "$releases" ]]; then
    log e "Failed to fetch releases or no releases available"
    kill $progress_pid  # kill the progress bar
    configurator_generic_dialog "Online Update - Error: Releases" "<span foreground='$purple'><b>Unable to fetch releases.</b></span> Please check your internet connection or try again later."
    return 1
  fi

  # Loop through each release and add to the release array
  while IFS= read -r release; do
    tag_name=$(echo "$release" | jq -r '.tag_name')
    published_at=$(echo "$release" | jq -r '.published_at')
    draft=$(echo "$release" | jq -r '.draft')
    prerelease=$(echo "$release" | jq -r '.prerelease')

    # Classifying releases
    if echo "$tag_name" | grep -q "PR"; then
      status="Pull Request"
    elif [[ "$draft" == "true" ]]; then
      status="Draft"
    elif [[ "$prerelease" == "true" ]]; then
      status="Pre-release"
    elif [[ "$cooker_repository_name" == *"Cooker"* ]]; then
      status="Cooker"
    else
      status="Main"
    fi

    # Convert published_at to human-readable format, if available
    if [[ "$published_at" != "null" ]]; then
      human_readable_date=$(date -d "$published_at" +"%d %B %Y %H:%M")
    else
      human_readable_date="Not published"
    fi

    # Ensure fields are properly aligned for Zenity
    release_array+=("$status" "$tag_name" "$human_readable_date")
  done < <(echo "$releases" | jq -c '.[]' | sort -t: -k3,3r)

  # kill the progress bar before opening the release list window
  kill $progress_pid

  if [[ ${#release_array[@]} -eq 0 ]]; then
    configurator_generic_dialog "RetroDECK - Online Update" "<span foreground='$purple'><b>No available releases were found.</b></span> Exiting."
    log d "No available releases found"
    return 1
  fi

  log d "Showing available releases"

  # Display releases in a Zenity list dialog with three columns
  selected_release=$(
    rd_zenity --list \
      --icon-name=net.retrodeck.retrodeck \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - RetroDECK Cooker: Select Release" \
      --column="Branch" --column="Release Tag" --column="Published Date" --width=1280 --height=800 \
      --separator="|" --print-column='ALL' "${release_array[@]}"
  )

  log i "Selected release: $selected_release"

  if [[ -z "$selected_release" ]]; then
    log d "No release selected, user exited."
    return 1
  fi

  # Parse the selected release using the pipe separator
  IFS='|' read -r selected_branch selected_tag selected_date <<< "$selected_release"
  selected_branch=$(echo "$selected_branch" | xargs)  # Trim any extra spaces
  selected_tag=$(echo "$selected_tag" | xargs)
  selected_date=$(echo "$selected_date" | xargs)

  log d "Selected branch: $selected_branch, release: $selected_tag, date: $selected_date"

  rd_zenity --question --icon-name=net.retrodeck.retrodeck --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Cooker Releases: Confirm Selection" \
    --text="Are you sure you want to install the following release?\n\n\<span foreground='$purple'><b>$selected_branch: \"$selected_tag\"</b></span>\n\Published on <span foreground='$purple'><b>$selected_date</b></span>?"

  if [[ $? -eq 0 ]]; then
    log d "User confirmed installation of release $selected_tag"
    if echo "$selected_release" | grep -q "Main Release"; then
      set_setting_value "$rd_conf" "update_repo" "$main_repository_name" retrodeck "options"
      log i "Switching to main channel"
    else
      set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
      log i "Switching to cooker channel"
    fi
    set_setting_value "$rd_conf" "branch" "$selected_branch" "retrodeck" "options"
    log d "Set branch to $selected_branch in configuration"
    install_release "$selected_tag"
  else
    log d "User canceled installation"
    return 0
  fi
}

quit_retrodeck() {
  log i "See you next time"
  
  prepare_component "shutdown" "all"
  
  exit
}

start_retrodeck() {
  log i "Starting RetroDECK v$version"

  prepare_component "startup" "all"
}

convert_to_markdown() {
  # Function to convert XML tags to Markdown
  local xml_content=$(cat "$1")
  local output_file="$1.md"

  # Convert main tags
  echo "$xml_content" | \
    sed -e 's|<p>\(.*\)</p>|## \1|g' \
      -e 's|<ul>||g' \
      -e 's|</ul>||g' \
      -e 's|<h1>\(.*\)</h1>|# \1|g' \
      -e 's|<li>\(.*\)</li>|- \1|g' \
      -e 's|<description>||g' \
      -e 's|</description>||g' \
      -e '/<[^>]*>/d' > "$output_file" # Remove any other XML tags and output to .md file
}

repair_paths() {
  # This function will verify that all folders defined in the [paths] section of retrodeck.cfg exist
  # If a folder doesn't exist and is defined outside of rd_home_path, it will check in rd_home_path first and have the user browse for them manually if it isn't there either
  # USAGE: repair_paths

  invalid_path_found="false"

  log i "Checking that all RetroDECK paths are valid"
  while IFS= read -r path_name; do
    if [[ ! $path_name =~ (rd_home_path|sdcard) ]]; then # Ignore these locations
      local path_value=$(get_setting_value "$rd_conf" "$path_name" "retrodeck" "paths")
      if [[ ! -d "$path_value" ]]; then # If the folder doesn't exist as defined
        log i "$path_name does not exist as defined, config is incorrect"
        if [[ ! -d "$rd_home_path/${path_value#*retrodeck/}" ]]; then # If the folder doesn't exist within defined rd_home_path path
          if [[ ! -d "$sdcard/${path_value#*retrodeck/}" ]]; then # If the folder doesn't exist within defined sdcard path
            log i "$path_name cannot be found at any expected location, having user locate it manually"
            configurator_generic_dialog "RetroDECK Configurator - Path Repair" "The RetroDECK <span foreground='$purple'><b>$path_name</b></span> was not found in the expected location.\nThis may occur if the folder was moved manually.\n\nPlease browse to the current location of the <span foreground='$purple'><b>$path_name</b></span>."
            if new_path=$(directory_browse "RetroDECK $path_name location"); then
              set_setting_value "$rd_conf" "$path_name" "$new_path" retrodeck "paths"
              invalid_path_found="true"
            else
              configurator_generic_dialog "RetroDECK Configurator - Path Repair" "No path for $path_name chosen, cannot repair."
            fi
          else # Folder does exist within defined sdcard path, update accordingly
            log i "$path_name found in $sdcard/retrodeck, correcting path config"
            new_path="$sdcard/retrodeck/${path_value#*retrodeck/}"
            set_setting_value "$rd_conf" "$path_name" "$new_path" retrodeck "paths"
            invalid_path_found="true"
          fi
        else # Folder does exist within defined rd_home_path path, update accordingly
          log i "$path_name found in $rd_home_path, correcting path config"
          new_path="$rd_home_path/${path_value#*retrodeck/}"
          set_setting_value "$rd_conf" "$path_name" "$new_path" retrodeck "paths"
          invalid_path_found="true"
        fi
      fi
    fi
  done < <(jq -r '(.paths // {}) | keys[]' "$rd_conf")

  if [[ $invalid_path_found == "true" ]]; then
    log i "One or more invalid paths repaired, fixing internal RetroDECK structures"
    prepare_component "postmove" "all"
    configurator_generic_dialog "RetroDECK Configurator - Path Repair" "<span foreground='$purple'><b>One or more incorrectly configured paths were repaired.</b></span>"
  else
    log i "All folders were found at their expected locations"
    configurator_generic_dialog "RetroDECK Configurator - Path Repair" "<span foreground='$purple'><b>All RetroDECK folders were found at their expected locations.</b></span>"
  fi
}

update_rd_conf() {
  # Update the retrodeck.cfg file with any new settings from the shipped defaults file.
  # New sections and settings are added with their default values. Existing settings are not modified.
  # New settings in the "paths" section have their base path rewritten to match the user's actual rd_home_path.
  # USAGE: update_rd_conf

  local tmp
  tmp=$(mktemp)

  jq -s '
    .[0] as $current |
    .[1] as $defaults |
    ($current.paths.rd_home_path // $defaults.paths.rd_home_path) as $actual_home |
    ($defaults.paths.rd_home_path) as $default_home |
    reduce ($defaults | to_entries[] | select(.key != "version")) as $section (
      $current;
      if has($section.key) then
        .[$section.key] = (
          ($section.value // {}) as $default_settings |
          .[$section.key] as $current_settings |
          reduce ($default_settings | to_entries[]) as $setting (
            $current_settings;
            if has($setting.key) then .
            else
              . + {($setting.key): (
                if $section.key == "paths" and ($setting.value | type) == "string" and ($setting.value | startswith($default_home)) then
                  ($setting.value | sub($default_home; $actual_home))
                else
                  $setting.value
                end
              )}
            end
          )
        )
      else
        if $section.key == "paths" then
          . + {($section.key): (
            $section.value | with_entries(
              if (.value | type) == "string" and (.value | startswith($default_home)) then
                .value |= sub($default_home; $actual_home)
              else . end
            )
          )}
        else
          . + {($section.key): $section.value}
        end
      end
    )
  ' "$rd_conf" "$rd_defaults" > "$tmp" && mv "$tmp" "$rd_conf"

  log d "retrodeck.cfg updated with any new default settings"
}

merge_directories() {
  # This function will take 2 or more "source" folders and create a new "merged" folder combining all the source files and subfolders using symlinks
  # Every time the function is run, it will check for the existance of all the files in all the source folders and ensure the "merged" folder is up to date, adding and removing symlinks as needed
  # USAGE: merge_directories "$merged_dir" "$source_dir_1" "$source_dir_2" ("$more_source_dirs")

  if [[ $# -lt 2 ]]; then
      log e "Usage: merge_directories merged_dir source_dir1 [source_dir2...]"
      return 1
  fi

  local merged_dir="$1"
  shift  # Remove merged_dir from arguments, leaving only source dirs
  local source_dirs=("$@")

  mkdir -p "$merged_dir"

  log i "Merging ${#source_dirs[@]} locations into $merged_dir"

  for source_dir in "${source_dirs[@]}"; do # First scan all source directories to build the complete folder structure
    if [[ ! -d "$source_dir" ]]; then
      log d "Warning: Source directory $source_dir doesn't exist. Skipping."
      continue
    fi

    find "$source_dir" -type d | while read -r dir; do # Find all subdirectories in this source
      if [[ "$dir" == "$src_dir" ]]; then # This is the source directory itself, skip it
        continue
      else
        relative_path=$(realpath --relative-to="$source_dir" "$dir")
      fi

      mkdir -p "$merged_dir/$relative_path"
    done
  done

  local valid_files_tmp=$(mktemp) # Create a temporary file to track all valid files

  log i "Creating symlinks for files..."
  for source_dir in "${source_dirs[@]}"; do # Process files from all source directories
    if [[ ! -d "$source_dir" ]]; then
      log d "$source_dir does not exist, skipping..."
      continue  # Skip non-existent directories
    fi

    find "$source_dir" -type f | while read -r file; do
      relative_path=$(realpath --relative-to="$source_dir" "$file") # Get path relative to the source dir
      merged_file="$merged_dir/$relative_path" # Path in the merged directory

      echo "$merged_file" >> "$valid_files_tmp"

      if [[ -L "$merged_file" ]]; then # If file already exists in merged location, check if it's the correct symlink
        target=$(readlink "$merged_file")

        if [[ "$target" = "$file" ]]; then # If symlink already points to this file, skip
          log d "Existing symlink for $file already exists, skipping..."
          continue
        fi

        if [[ -f "$target" ]]; then # Otherwise, it points to a different file, only replace if current target doesn't exist
          log d "New target for $file exists at $target, keeping existing symlink"
          continue  # Keep the existing symlink
        fi

        log d "Removing stale symlink $merged_file"
        rm "$merged_file" # Remove the stale symlink
      fi

      if [[ -f "$merged_file" ]] && [[ ! -L "$merged_file" ]]; then # Skip if a real file already exists (not a symlink)
        log w "Warning: Real file exists at $merged_file. Skipping symlink creation."
        continue
      fi

      mkdir -p "$(dirname "$merged_file")"
      log d "Creating new symlink for $file at $merged_file"
      ln -sf "$file" "$merged_file"
    done
  done

  log i "Removing stale symlinks..."
  find "$merged_dir" -type l | while read -r symlink; do # Find and remove stale symlinks
    if ! grep -q "^$symlink$" "$valid_files_tmp"; then # Check if this symlink is in our list of valid files
      if [[ ! -e "$(readlink "$symlink")" ]]; then # Also verify the target doesn't exist
        log d "Removing stale symlink: $symlink"
        rm "$symlink"
      fi
    fi
  done

  rm "$valid_files_tmp"

  log i "Merge complete!"
}

launch_command() {
  input="$1"
  set -- $input
  # Get the function name and remove it from the list of arguments
  function_name="$1"
  shift

  # Check if the function exists
  if ! declare -f "$function_name" >/dev/null 2>&1; then
    log e "Function \'$function_name\' not found"
    exit 1
  fi

  # Call the function with any remaining arguments
  "$function_name" "$@"
}

prune_empty_parents() {
  # Remove empty directories walking up from start_dir to stop_dir (inclusive).
  # USAGE: prune_empty_parents "$start_dir" "$stop_dir"

  local current="$1"
  local stop="$2"

  while [[ -d "$current" && -z "$(ls -A "$current" 2>/dev/null)" ]]; do
    log d "Directory $current is empty, removing"
    rmdir "$current"
    [[ "$current" == "$stop" ]] && break
    current=$(dirname "$current")
    # Don't go above the stop directory
    [[ "${current}" != "${stop}"* ]] && break
  done
}

finit_default_yes() {
  log i "Defaulting setting "$@" enabled."
  return 0
}

handle_folder_iconsets() {
  local iconset="$1"

  if [[ ! "$iconset" == "false" ]]; then
    if [[ -d "$folder_iconsets_dir/$iconset" ]]; then
      while read -r icon; do
        local icon_relative_path="${icon#$folder_iconsets_dir/$iconset/}"
        local icon_relative_path="${icon_relative_path%.ico}"
        local icon_relative_root="${icon_relative_path%%/*}"
        local path_var_name="${icon_relative_root}_path"
        local path_name=""

        if [[ "$icon_relative_path" =~ (sync) ]]; then # If the icon is for a hidden folder, add the leading dot temporarily for searching
          icon_relative_path=".${icon_relative_path}"
        fi

        if [[ -v "$path_var_name" ]]; then
          path_name="${!path_var_name}"
          if [[ ! "$icon_relative_path" == "$icon_relative_root" ]]; then
            path_name="$path_name/${icon_relative_path#$icon_relative_root/}"
          fi
          if [[ ! -d "$path_name" ]]; then
            log w "Path for icon $icon could not be found, skipping..."
            continue
          fi
        elif [[ -d "$rd_home_path/$icon_relative_path" ]]; then
          path_name="$rd_home_path/$icon_relative_path"
          icon_relative_path="${icon_relative_path#.}" # Remove leading dot from actual icon name reference
        else
          log w "Path for icon $icon could not be found, skipping..."
          continue
        fi

        log d "Creating file $path_name/.directory"
        echo '[Desktop Entry]' > "$path_name/.directory"
        echo "Icon=$folder_iconsets_dir/$iconset/$icon_relative_path.ico" >> "$path_name/.directory"
      done < <(find "$folder_iconsets_dir/$iconset" -maxdepth 2 -type f -iname "*.ico")
      set_setting_value "$rd_conf" "iconset" "$iconset" retrodeck "options"
    else
      configurator_generic_dialog "RetroDeck Configurator - Toggle Folder Iconsets" "The chosen iconset <span foreground='$purple'><b>$iconset</b></span> could not be found in the RetroDECK assets."
      return 1
    fi
  else
    while read -r path; do
      find -L "$path" -maxdepth 2 -type f -iname '.directory' -exec rm {} \;
    done < <(jq -r 'del(.paths.downloaded_media_path, .paths.themes_path, .paths.sdcard) | .paths[]' "$rd_conf")
    set_setting_value "$rd_conf" "iconset" "false" retrodeck "options"
  fi
}

url_encode() {
  # URL-encode a string, escaping all special characters for safe use in URLs and form data.
  # USAGE: url_encode "$string"

  jq -sRr @uri <<< "$1"
}

set_build_options() {
  # If this is a pre-production build
  if [[ ! "$hard_version" =~ ^[0-9] && ! "$hard_version" =~ ^(epicure) ]]; then
    log d "Pre-production version $hard_version detected, setting debugging values in retrodeck.json"
    set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    set_setting_value "$rd_conf" "developer_options" "true" retrodeck "options"
    set_setting_value "$rd_conf" "rd_logging_level" "debug" retrodeck "options"
  else
    log d "Production version $hard_version detected, resetting debugging values in retrodeck.json"
    set_setting_value "$rd_conf" "update_repo" "RetroDECK" retrodeck "options"
    set_setting_value "$rd_conf" "update_check" "false" retrodeck "options"
    set_setting_value "$rd_conf" "update_ignore" "" retrodeck "options"
    set_setting_value "$rd_conf" "developer_options" "false" retrodeck "options"
    set_setting_value "$rd_conf" "rd_logging_level" "info" retrodeck "options"
  fi
}
