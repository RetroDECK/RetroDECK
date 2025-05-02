#!/bin/bash

directory_browse() {
  # This function browses for a directory and returns the path chosen
  # USAGE: path_to_be_browsed_for=$(directory_browse $action_text)

  local path_selected=false

  while [ $path_selected == false ]
  do
    local target="$(rd_zenity --file-selection --title="Choose $1" --directory)"
    if [ ! -z "$target" ] #yes
    then
      rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
      --text="Directory $target chosen, is this correct?"
      if [ $? == 0 ]
      then
        path_selected=true
        echo "$target"
        break
      fi
    else
      rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
      --text="No directory selected. Do you want to exit the selection process?"
      if [ $? == 0 ]
      then
        break
      fi
    fi
  done
}

file_browse() {
  # This function browses for a file and returns the path chosen
  # USAGE: file_to_be_browsed_for=$(file_browse $action_text)

  local file_selected=false

  while [ $file_selected == false ]
  do
    local target="$(rd_zenity --file-selection --title="Choose $1")"
    if [ ! -z "$target" ] #yes
    then
      rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
      --text="File $target chosen, is this correct?"
      if [ $? == 0 ]
      then
        file_selected=true
        echo "$target"
        break
      fi
    else
      rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
      --text="No file selected. Do you want to exit the selection process?"
      if [ $? == 0 ]
      then
        break
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
    echo "false"
  else
    echo "true"
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
  --title "RetroDECK Configurator Utility - Move in Progress" \
  --text="Moving directory $(basename "$1") to new location of $2, please wait."

  if [[ -d "$source_dir" ]]; then # Some conflicting files remain
    rd_zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility - Move Directories" \
    --text="There were some conflicting files that were not moved.\n\nAll files that could be moved are in the new location,\nany files that already existed at the new location have not been moved and will need to be handled manually."
  fi
}

create_dir() {
  # A simple function that creates a directory checking if is still there while logging the activity
  # If -d it will delete it prior the creation

  if [[ "$1" == "-d" ]]; then
    # If "force" flag is provided, delete the directory first
    shift # Remove the first argument (-f)
    if [[ -e "$1" ]]; then
      rm -rf "$1" # Forcefully delete the directory
      log d "Found \"$1\", deleting it."
    fi
  fi

  if [[ ! -d "$1" ]]; then
    mkdir -p "$1" # Create directory if it doesn't exist
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

  (
    wget "$1" -O "$2" -q
  ) |
  rd_zenity --progress \
    --title="Downloading File" \
    --text="Downloading $3..." \
    --pulsate \
    --auto-close
}

conf_read() {
  # This function will read the RetroDECK config file into memory
  # USAGE: conf_read

  if head -n 1 "$rd_conf" | grep -qE '^\s*\{\s*$'; then # If retrodeck.cfg is new JSON format
    while IFS== read -r name value; do
      #log d "Setting $name has value $value"
      printf -v "$name" '%s' "$value"
      export "${name}"
    done < <(jq -r '
      # grab standalone object version into $ver
      .version as $ver
      |
      # build a new object with just version, + paths, + options
      ({ version: $ver }
      + (.paths   // {} )
      + (.options // {} )
      )
      # turn it into ["key","value"] pairs, then "key=value"
      | to_entries[]
      | "\(.key)=\(.value)"
      ' "$rd_conf")
    else
      while IFS= read -r current_setting_line # Read the existing retrodeck.cfg
      do
        if [[ (! -z "$current_setting_line") && (! "$current_setting_line" == "#"*) && (! "$current_setting_line" == "[]") ]]; then # If the line has a valid entry in it
          if [[ ! -z $(grep -o -P "^\[.+?\]$" <<< "$current_setting_line") ]]; then # If the line is a section header
            local current_section=$(sed 's^[][]^^g' <<< "$current_setting_line") # Remove brackets from section name
          else
            if [[ "$current_section" == "" || "$current_section" == "paths" || "$current_section" == "options" ]]; then
              local current_setting_name=$(cut -d'=' -f1 <<< "$current_setting_line" | xargs) # Extract name
              local current_setting_value=$(cut -d'=' -f2 <<< "$current_setting_line" | xargs) # Extract value
              declare -g "$current_setting_name=$current_setting_value" # Write the current setting name and value to memory
              export "$current_setting_name"
            fi
          fi
        fi
      done < "$rd_conf"
    fi
  log d "retrodeck.cfg read and loaded"
}

conf_write() {
  # This function will update the RetroDECK config file with matching variables from memory
  # USAGE: conf_write

  if head -n 1 "$rd_conf" | grep -qE '^\s*\{\s*$'; then # If retrodeck.cfg is new JSON format
    local tmp jq_args=() filter

    # Update version
    jq_args+=(--arg version "$version")
    filter='.version = $version'

    # Update paths section
    while read -r setting_name; do
      local setting_value="${!setting_name}"
      jq_args+=(--arg "$setting_name" "$setting_value")
      filter+=" | .paths.$setting_name = \$$setting_name"
    done < <(jq -r '(.paths // {}) | keys[]' "$rd_conf")

    # Update options section
    while read -r setting_name; do
      local setting_value="${!setting_name}"
      jq_args+=(--arg "$setting_name" "$setting_value")
      filter+=" | .options.$setting_name = \$$setting_name"
    done < <(jq -r '(.options // {}) | keys[]' "$rd_conf")

    # Write all gathered information
    tmp=$(mktemp)
    jq "${jq_args[@]}" \
      "$filter" \
      "$rd_conf" > "$tmp" \
      && mv "$tmp" "$rd_conf"
    else
      while IFS= read -r current_setting_line # Read the existing retrodeck.cfg
      do
        if [[ (! -z "$current_setting_line") && (! "$current_setting_line" == "#"*) && (! "$current_setting_line" == "[]") ]]; then # If the line has a valid entry in it
          if [[ ! -z $(grep -o -P "^\[.+?\]$" <<< "$current_setting_line") ]]; then # If the line is a section header
            local current_section=$(sed 's^[][]^^g' <<< "$current_setting_line") # Remove brackets from section name
          else
            if [[ "$current_section" == "" || "$current_section" == "paths" || "$current_section" == "options" ]]; then
              local current_setting_name=$(get_setting_name "$current_setting_line" "retrodeck") # Read the variable name from the current line
              local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "$current_section") # Read the variables value from retrodeck.cfg
              local memory_setting_value=$(eval "echo \$${current_setting_name}") # Read the variable names' value from memory
              if [[ ! "$current_setting_value" == "$memory_setting_value" && ! -z "$memory_setting_value" ]]; then # If the values are different...
                set_setting_value "$rd_conf" "$current_setting_name" "$memory_setting_value" "retrodeck" "$current_section" # Update the value in retrodeck.cfg
              fi
            fi
          fi
        fi
      done < "$rd_conf"
    fi
  log d "retrodeck.cfg written"
}

dir_prep() {
  # This script is creating a symlink preserving old folder contents and moving them in the new one

  # Call me with:
  # dir prep "real dir" "symlink location"
  real="$(realpath -s "$1")"
  symlink="$(realpath -s "$2")"

  log d "Preparing directory $symlink in $real"

   # if the symlink dir is already a symlink, unlink it first, to prevent recursion
  if [ -L "$symlink" ];
  then
    log d "$symlink is already a symlink, unlinking to prevent recursives"
    unlink "$symlink"
  fi

  # if the dest dir exists we want to backup it
  if [ -d "$symlink" ];
  then
    log d "$symlink found"
    mv -f "$symlink" "$symlink.old"
  fi

  # if the real dir is already a symlink, unlink it first
  if [ -L "$real" ];
  then
    log d "$real is already a symlink, unlinking to prevent recursives" #DEBUG
    unlink "$real"
  fi

  # if the real dir doesn't exist we create it
  if [ ! -d "$real" ];
  then
    log d "$real not found, creating it" #DEBUG
    create_dir "$real"
  fi

  # creating the symlink
  log d "linking $real in $symlink" #DEBUG
  create_dir "$(dirname "$symlink")" # creating the full path except the last folder
  ln -svf "$real" "$symlink"

  # moving everything from the old folder to the new one, delete the old one
  if [ -d "$symlink.old" ];
  then
    log d "Moving the data from $symlink.old to $real" #DEBUG
    mv -f "$symlink.old"/{.[!.],}* "$real"
    log d "Removing $symlink.old" #DEBUG
    rm -rf "$symlink.old"
  fi

  log i "$symlink is now $real"
}

update_rpcs3_firmware() {
  create_dir "$roms_folder/ps3/tmp"
  chmod 777 "$roms_folder/ps3/tmp"
  download_file "$rpcs3_firmware" "$roms_folder/ps3/tmp/PS3UPDAT.PUP" "RPCS3 Firmware"
  rpcs3 --installfw "$roms_folder/ps3/tmp/PS3UPDAT.PUP"
  rm -rf "$roms_folder/ps3/tmp"
}

update_vita3k_firmware() {
  download_file "http://dus01.psv.update.playstation.net/update/psv/image/2022_0209/rel_f2c7b12fe85496ec88a0391b514d6e3b/PSVUPDAT.PUP" "/tmp/PSVUPDAT.PUP" "Vita3K Firmware file: PSVUPDAT.PUP"
  download_file "http://dus01.psp2.update.playstation.net/update/psp2/image/2019_0924/sd_8b5f60b56c3da8365b973dba570c53a5/PSP2UPDAT.PUP?dest=us" "/tmp/PSP2UPDAT.PUP" "Vita3K Firmware file: PSP2UPDAT.PUP"
  Vita3K --firmware /tmp/PSVUPDAT.PUP
  Vita3K --firmware /tmp/PSP2UPDAT.PUP
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
  #        backup_retrodeck_userdata custom saves_folder states_folder /some/other/path

  create_dir "$backups_folder"

  backup_date=$(date +"%0m%0d_%H%M")
  backup_log_file="$logs_folder/${backup_date}_${backup_type}_backup_log.log"

  # Check if first argument is the type
  if [[ "$1" == "complete" || "$1" == "core" || "$1" == "custom" ]]; then
    backup_type="$1"
    shift # Remove the first argument
  else
    if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
      configurator_generic_dialog "RetroDECK Userdata Backup" "No valid backup option chosen. Valid options are <standard> and <custom>."
    fi
    log e "No valid backup option chosen. Valid options are <complete>, <core> and <custom>."
    return 1
  fi

  zip_file="$backups_folder/retrodeck_${backup_date}_${backup_type}.zip"

  # Initialize paths arrays
  paths_to_backup=()
  declare -A config_paths # Requires an associative (dictionary) array to work

  # Build array of folder names and real paths from retrodeck.cfg
  while read -r path_name; do
    if [[ ! $path_name =~ (rdhome|sdcard|backups_folder) ]]; then # Ignore these locations
      local path_value=$(get_setting_value "$rd_conf" "$path_name" "retrodeck" "paths")
      log d "Path $path_value added to potential backup list"
      config_paths["$path_name"]="$path_value"
    fi
  done < <(jq -r '(.paths // {}) | keys[]' "$rd_conf")

  # Determine which paths to backup
  if [[ "$backup_type" == "complete" ]]; then
    for folder_name in "${!config_paths[@]}"; do
      path_value="${config_paths[$folder_name]}"
      if [[ -e "$path_value" ]]; then
        paths_to_backup+=("$path_value")
        log i "Adding to backup: $folder_name = $path_value"
      else
        if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
          configurator_generic_dialog "RetroDECK Userdata Backup" "The $folder_name was not found at its expected location, $path_value\nSomething may be wrong with your RetroDECK installation."
        fi
        log i "Warning: Path does not exist: $folder_name = $path_value"
      fi
    done

    # Add static paths not defined in retrodeck.cfg
    if [[ -e "$rdhome/ES-DE/collections" ]]; then
      paths_to_backup+=("$rdhome/ES-DE/collections")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Userdata Backup" "The ES-DE collections folder was not found at its expected location, $rdhome/ES-DE/collections\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/collections = $rdhome/ES-DE/collections"
    fi

    if [[ -e "$rdhome/ES-DE/gamelists" ]]; then
      paths_to_backup+=("$rdhome/ES-DE/gamelists")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Userdata Backup" "The ES-DE gamelists folder was not found at its expected location, $rdhome/ES-DE/gamelists\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/gamelists = $rdhome/ES-DE/gamelists"
    fi

    if [[ -e "$rdhome/ES-DE/custom_systems" ]]; then
      paths_to_backup+=("$rdhome/ES-DE/custom_systems")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Userdata Backup" "The ES-DE custom_systems folder was not found at its expected location, $rdhome/ES-DE/custom_systems\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/custom_systems = $rdhome/ES-DE/custom_systems"
    fi

    # Check if we found any valid paths
    if [[ ${#paths_to_backup[@]} -eq 0 ]]; then
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Userdata Backup" "No valid userdata folders were found.\nSomething may be wrong with your RetroDECK installation."
      fi
      log e "Error: No valid paths found in config file"
      return 1
    fi

  elif [[ "$backup_type" == "core" ]]; then
    for folder_name in "${!config_paths[@]}"; do
      if [[ $folder_name =~ (saves_folder|states_folder|logs_folder) ]]; then # Only include these paths
        path_value="${config_paths[$folder_name]}"
        if [[ -e "$path_value" ]]; then
          paths_to_backup+=("$path_value")
          log i "Adding to backup: $folder_name = $path_value"
        else
          if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
            configurator_generic_dialog "RetroDECK Userdata Backup" "The $folder_name was not found at its expected location, $path_value\nSomething may be wrong with your RetroDECK installation."
          fi
          log i "Warning: Path does not exist: $folder_name = $path_value"
        fi
      fi
    done

    # Add static paths not defined in retrodeck.cfg
    if [[ -e "$rdhome/ES-DE/collections" ]]; then
      paths_to_backup+=("$rdhome/ES-DE/collections")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Userdata Backup" "The ES-DE collections folder was not found at its expected location, $rdhome/ES-DE/collections\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/collections = $rdhome/ES-DE/collections"
    fi

    if [[ -e "$rdhome/ES-DE/gamelists" ]]; then
      paths_to_backup+=("$rdhome/ES-DE/gamelists")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Userdata Backup" "The ES-DE gamelists folder was not found at its expected location, $rdhome/ES-DE/gamelists\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/gamelists = $rdhome/ES-DE/gamelists"
    fi

    if [[ -e "$rdhome/ES-DE/custom_systems" ]]; then
      paths_to_backup+=("$rdhome/ES-DE/custom_systems")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Userdata Backup" "The ES-DE custom_systems folder was not found at its expected location, $rdhome/ES-DE/custom_systems\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/custom_systems = $rdhome/ES-DE/custom_systems"
    fi

    # Check if we found any valid paths
    if [[ ${#paths_to_backup[@]} -eq 0 ]]; then
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Userdata Backup" "No valid userdata folders were found.\nSomething may be wrong with your RetroDECK installation."
      fi
      log e "Error: No valid paths found in config file"
      return 1
    fi

  elif [[ "$backup_type" == "custom" ]]; then
    if [[ "$#" -eq 0 ]]; then # Check if any paths were provided in the arguments
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Userdata Backup" "No valid backup locations were specified. Please try again."
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
            configurator_generic_dialog "RetroDECK Userdata Backup" "The $arg was not found at its expected location, $path_value.\nSomething may be wrong with your RetroDECK installation."
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
          configurator_generic_dialog "RetroDECK Userdata Backup" "The path $arg was not found at its expected location.\nPlease check the path and try again."
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
            --title "RetroDECK Configurator Utility - Userdata Backup" \
            --text="Verifying there is enough free space for the backup, please wait..."
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
  available_space=$(df -B1 "$backups_folder" | awk 'NR==2 {print $4}')

  # Log sizes for reference
  log i "Total size of backup data: $(numfmt --to=iec-i --suffix=B "$total_size")"
  log i "Available space at destination: $(numfmt --to=iec-i --suffix=B "$available_space")"

  # Check if we have enough space (using uncompressed size as a conservative estimate)
  if [[ "$available_space" -lt "$total_size" ]]; then
    if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
      configurator_generic_dialog "RetroDECK Userdata Backup" "There is not enough free space to perform this backup.\n\nYou need at least $(numfmt --to=iec-i --suffix=B "$total_size"),\nplease free up some space and try again."
    fi
    log e "Error: Not enough space to perform backup. Need at least $(numfmt --to=iec-i --suffix=B "$total_size")"
    return 1
  fi

  log i "Starting backup process..."

  if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then # Show progress dialog if running Zenity Configurator
    (
      # Create zip with selected paths
      if zip -rq9 "$zip_file" "${paths_to_backup[@]}" >> "$backup_log_file" 2>&1; then
        # Rotate backups for the specific type
        cd "$backups_folder" || return 1
        ls -t *_${backup_type}.zip | tail -n +4 | xargs -r rm

        final_size=$(du -h "$zip_file" | cut -f1)
        configurator_generic_dialog "RetroDECK Userdata Backup" "The backup to $zip_file was successful, final size is $final_size.\n\nThe backups have been rotated, keeping the last 3 of the $backup_type backup type."
        log i "Backup completed successfully: $zip_file (Size: $final_size)"
        log i "Older backups rotated, keeping latest 3 of type $backup_type"

        if [[ ! -s "$backup_log_file" ]]; then # If the backup log file is empty, meaning zip threw no errors
          rm -f "$backup_log_file"
        fi
      else
        configurator_generic_dialog "RetroDECK Userdata Backup" "Something went wrong with the backup process. Please check the log $backup_log_file for more information."
        log i "Error: Backup failed"
        return 1
      fi
    ) |
    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - Userdata Backup" \
            --text="Compressing files into backup, please wait..."
  else
    if zip -rq9 "$zip_file" "${paths_to_backup[@]}" >> "$backup_log_file" 2>&1; then
      # Rotate backups for the specific type
      cd "$backups_folder" || return 1
      ls -t *_${backup_type}.zip | tail -n +4 | xargs -r rm

      final_size=$(du -h "$zip_file" | cut -f1)
      log i "Backup completed successfully: $zip_file (Size: $final_size)"
      log i "Older backups rotated, keeping latest 3 of type $backup_type"

      if [[ ! -s "$backup_log_file" ]]; then # If the backup log file is empty, meaning zip threw no errors
        rm -f "$backup_log_file"
      fi
    else
      log i "Error: Backup failed"
      return 1
    fi
  fi
}

make_name_pretty() {
  # This function will take an internal system name (like "gbc") and return a pretty version for user display ("Nintendo GameBoy Color")
  # If the name is nout found it only returns the short name such as "gbc"
  # USAGE: make_name_pretty "system name"

  local system_name="$1"

  # Use jq to parse the JSON and find the pretty name from the components manifest.json
  while IFS= read -r component_manifest; do
    if jq -e --arg system "$system_name" 'to_entries | any(.value.system == $system)' "$component_manifest" > /dev/null; then
      local pretty_name=$(jq -r --arg name "$system_name" '.system[$name].name // $name' "$features")
      echo "$pretty_name"
      break
    fi
  done < <(find "$RD_MODULES" -maxdepth 2 -mindepth 2 -type f -name "manifest.json")
}

finit_browse() {
  # Function for choosing data directory location during first/forced init
  path_selected=false
  while [ $path_selected == false ]
  do
    local target="$(rd_zenity --file-selection --title="Choose RetroDECK data directory location" --directory)"
    if [[ ! -z "$target" ]]; then
      if [[ -w "$target" ]]; then
        rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" \
        --cancel-label="No" \
        --ok-label "Yes" \
        --text="Your RetroDECK data folder will be:\n\n$target/retrodeck\n\nis that ok?"
        if [ $? == 0 ] #yes
        then
          path_selected=true
          echo "$target"
          break
        else
          rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" --text="Do you want to quit?"
          if [ $? == 0 ] # yes, quit
          then
            quit_retrodeck
          fi
        fi
      fi
    else
      rd_zenity --error --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK" \
      --ok-label "Quit" \
      --text="No location was selected. Please run RetroDECK again to retry."
      quit_retrodeck
    fi
  done
}

finit_user_options_dialog() {
  finit_available_options=()
  finit_extracted_options=$(jq -r '.finit_default_options | to_entries[] | "\(.value.enabled)^\(.value.name)^\(.value.description)^\(.key)"' "$features")

  # Read finit_default_options from features.json using jq
  while IFS="^" read -r enabled option_name option_desc option_tag; do
    finit_available_options+=("$enabled" "$option_name" "$option_desc" "$option_tag")
  done <<< "$finit_extracted_options"

  local choices=$(rd_zenity \
  --list --width=1200 --height=720 \
  --checklist --hide-column=4 --ok-label="Confirm Selections" --extra-button="Enable All" \
  --separator=" " --print-column=4 \
  --text="Choose which options to enable:" \
  --column "Enabled?" \
  --column "Option" \
  --column "Description" \
  --column "option_flag" \
  "${finit_available_options[@]}")

  echo "${choices[*]}"
}

finit() {
  # Force/First init, depending on the situation

  log i "Executing finit"

  # Internal or SD Card?
  local finit_dest_choice=$(configurator_destination_choice_dialog "RetroDECK data" "Welcome to the first setup of RetroDECK.\nPlease carefully read each message prompted during the installation process to avoid any unwanted misconfigurations.\n\nWhere do you want your RetroDECK data folder to be located?\nIn this location a \"retrodeck\" folder will be created.\nThis is the folder that you will use to contain all your important files, such as your own ROMs, BIOSs, Saves and Scraped Data." )
  if [[ "$finit_dest_choice" == "" ]]; then
    log i "User closed the window"
  else
    log i "User choice: $finit_dest_choice"
  fi

  case "$finit_dest_choice" in

  "Quit" | "Back" | "" ) # Back, Quit or X button quits
    rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
    log i "Now quitting"
    quit_retrodeck
  ;;

  "Internal Storage" ) # Internal
    log i "Internal selected"
    rdhome="$HOME/retrodeck"
    if [[ -L "$rdhome" ]]; then #Remove old symlink from existing install, if it exists
      unlink "$rdhome"
    fi
  ;;

  "SD Card" )
    log i "SD Card selected"
    external_devices=()

    while read -r size device_path; do
      device_name=$(basename "$device_path")
      log d "External device $device_path found"
      external_devices=("${external_devices[@]}" "$device_name" "$size" "$device_path")
    done < <(df --output=size,target -h | grep "/run/media/" | awk '{$1=$1;print}')

    if [[ "${#external_devices[@]}" -gt 0 ]]; then # Some external storage detected
      configurator_generic_dialog "RetroDeck Installation - SD Card" "One or more external storage devices have been detected, please choose which one you would like to install RetroDECK on."
      choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - USB Migration Tool" --cancel-label="Back" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ -n "$choice" ]]; then # User chose a device
        sdcard="$choice"
      else # User did not make a choice
        rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
        exit 2
      fi
    else # No external storage detected
      log e "No external storage detected"
      rd_zenity --error --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK" \
      --ok-label "Browse" \
      --text="No external storage devices could be found.\nPlease choose the location of your SD card manually.\n\nNOTE: A \"retrodeck\" folder will be created starting from the location that you select."
      sdcard="$(finit_browse)" # Calling the browse function
      if [[ -z "$sdcard" ]]; then # If user hit the cancel button
        rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
        exit 2
      fi
    fi
    
    if [ ! -w "$sdcard" ] #SD card found but not writable
      then
        log e "SD card found but not writable"
        rd_zenity --error --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK" \
        --ok-label "Quit" \
        --text="SD card was found but is not writable\nThis can happen with cards formatted on PC.\nPlease format the SD card through the Steam Deck's Game Mode and run RetroDECK again."
        rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
        log i "Now quitting"
        quit_retrodeck
    else
      rdhome="$sdcard/retrodeck"
    fi
  ;;

  "Custom Location" )
      log i "Custom Location selected"
      rd_zenity --info --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK" \
      --ok-label "Browse" \
      --text="Please choose the root folder for the RetroDECK data.\nA retrodeck folder will be created starting from the directory that you selected."
      sdcard="$(finit_browse)" # Calling the browse function
      rdhome="$sdcard/retrodeck"
      if [[ -z "$rdhome" ]]; then # If user hit the cancel button
        rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
        exit 2
      fi
    ;;

  esac

  log i "\"retrodeck\" folder will be located in \"$rdhome\""

  prepare_component "reset" "retrodeck" # Parse the [paths] section of retrodeck.cfg and set the value of / create all needed folders

  conf_write # Write the new values to retrodeck.cfg

  configurator_generic_dialog "RetroDECK Initial Setup" "The next dialog will be a list of optional actions to take during the initial setup.\n\nIf you choose to not do any of these now, they can be done later through the Configurator."
  local finit_options_choices=$(finit_user_options_dialog)

  if [[ "$finit_options_choices" =~ (rpcs3_firmware|Enable All) ]]; then # Additional information on the firmware install process, as the emulator needs to be manually closed
    configurator_generic_dialog "RPCS3 Firmware Install" "You have chosen to install the RPCS3 firmware during the RetroDECK first setup.\n\nThis process will take several minutes and requires network access.\n\nRPCS3 will be launched automatically at the end of the RetroDECK setup process.\nOnce the firmware is installed, please close the emulator to finish the process."
  fi

  if [[ "$finit_options_choices" =~ (vita3k_firmware|Enable All) ]]; then # Additional information on the firmware install process, as the emulator needs to be manually closed
    configurator_generic_dialog "Vita3K Firmware Install" "You have chosen to install the Vita3K firmware during the RetroDECK first setup.\n\nThis process will take several minutes and requires network access.\n\nVita3K will be launched automatically at the end of the RetroDECK setup process.\nOnce the firmware is installed, please close the emulator to finish the process."
  fi

  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" \
  --text="RetroDECK will now install the needed files, which can take up to one minute.\nRetroDECK will start once the process is completed.\n\nPress OK to continue."

  (
  prepare_component "reset" "all"
  build_retrodeck_current_presets
  deploy_helper_files

  # Optional actions based on user choices
  if [[ "$finit_options_choices" =~ (rpcs3_firmware|Enable All) ]]; then
    if [[ $(check_network_connectivity) == "true" ]]; then
      update_rpcs3_firmware
    fi
  fi
  if [[ "$finit_options_choices" =~ (vita3k_firmware|Enable All) ]]; then
    if [[ $(check_network_connectivity) == "true" ]]; then
      update_vita3k_firmware
    fi
  fi
  if [[ "$finit_options_choices" =~ (rd_controller_profile|Enable All) ]]; then
    install_retrodeck_controller_profile
  fi
  if [[ "$finit_options_choices" =~ (rd_prepacks|Enable All) ]]; then
    install_retrodeck_starterpack
  fi

  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Finishing Initialization" \
    --text="RetroDECK is finishing the initial setup process, please wait.\n\n"

  add_retrodeck_to_steam
  create_lock

  # Inform the user where to put the ROMs and BIOS files
  rd_zenity --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Setup Complete" \
    --text="RetroDECK setup is complete!\n\nPlease place your <span foreground='$purple'><b>game files</b></span> in the following directory: <span foreground='$purple'><b>$rdhome/roms\n\n</b></span>and your <span foreground='$purple'><b>BIOS</b></span> files in: <span foreground='$purple'><b>$rdhome/bios\n\n</b></span>You can use the <span foreground='$purple'><b>BIOS checker tool</b></span> available trough the <span foreground='$purple'><b>RetroDECK Configurator</b></span>\nor refer to the <span foreground='$purple'><b>RetroDECK WIKI</b></span> for more information about the required BIOS files and their proper paths.\n\nYou can now start using RetroDECK."
}

install_retrodeck_starterpack() {
  # This function will install the roms, gamelists and metadata for the RetroDECK Starter Pack, a curated selection of games the creators of RetroDECK enjoy.
  # USAGE: install_retrodeck_starterpack

  ## DOOM section ##
  cp /app/retrodeck/extras/doom1.wad "$roms_folder/doom/doom1.wad" # No -f in case the user already has it
  create_dir "$XDG_CONFIG_HOME/ES-DE/gamelists/doom"
  if [[ ! -f "$XDG_CONFIG_HOME/ES-DE/gamelists/doom/gamelist.xml" ]]; then # Don't overwrite an existing gamelist
    cp "/app/retrodeck/rd_prepacks/doom/gamelist.xml" "$XDG_CONFIG_HOME/ES-DE/gamelists/doom/gamelist.xml"
  fi
  create_dir "$media_folder/doom"
  unzip -oq "/app/retrodeck/rd_prepacks/doom/doom.zip" -d "$media_folder/doom/"
}

install_retrodeck_controller_profile() {
  # This function will install the needed files for the custom RetroDECK controller profile
  # NOTE: These files need to be stored in shared locations for Steam, outside of the normal RetroDECK folders and should always be an optional user choice
  # BIGGER NOTE: As part of this process, all emulators will need to have their configs hard-reset to match the controller mappings of the profile
  # USAGE: install_retrodeck_controller_profile
  if [[ -d "$HOME/.steam/steam/controller_base/templates/" || -d "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" ]]; then
    if [[ -d "$HOME/.steam/steam/controller_base/templates/" ]]; then # If a normal binary Steam install exists
      rsync -rlD --mkpath "/app/retrodeck/binding_icons/" "$HOME/.steam/steam/tenfoot/resource/images/library/controller/binding_icons/"
      rsync -rlD --mkpath "$config/retrodeck/controller_configs/" "$HOME/.steam/steam/controller_base/templates/"
    fi
    if [[ -d "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" ]]; then # If a Flatpak Steam install exists
      rsync -rlD --mkpath "/app/retrodeck/binding_icons/" "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/tenfoot/resource/images/library/controller/binding_icons/"
      rsync -rlD --mkpath "$config/retrodeck/controller_configs/" "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/"
    fi
  else
    configurator_generic_dialog "RetroDECK Controller Profile Install" "The target directories for the controller profile do not exist.\n\nThis may happen if you do not have Steam installed or the location is does not have permission to be read."
  fi
}

create_lock() {
  # creating RetroDECK's lock file and writing the version in the config file
  version=$hard_version
  touch "$lockfile"
  conf_write
}

update_splashscreens() {
  # This script will purge any existing ES graphics and reload them from RO space into somewhere ES will look for it
  # USAGE: update_splashscreens

  log i "Updating splash screen"

  rm -rf "$XDG_CONFIG_HOME/ES-DE/resources/graphics"
  rsync -rlD --mkpath "/app/retrodeck/graphics/" "$XDG_CONFIG_HOME/ES-DE/resources/graphics/"

}

deploy_helper_files() {
  # This script will distribute helper documentation files throughout the filesystem according to the JSON configuration
  # USAGE: deploy_helper_files

  # Extract helper files information using jq
  helper_files=$(jq -r '(.helper_files // {}) | keys[]' "$features")

  # Iterate through each helper file entry
  while IFS= read -r helper_file_name; do
    current_json_object=$(jq -r --arg helper_file_name "$helper_file_name" '.helper_files[$helper_file_name]' "$features")
    file=$(echo "$current_json_object" | jq -r '.filename')
    dest=$(echo "$current_json_object" | jq -r '.location')
    if [[ ! -z "$file" ]] && [[ ! -z "$dest" ]]; then
      eval current_dest="$dest"
      log d "Copying helper file $file to $current_dest"
      cp -f "$helper_files_folder/$file" "$current_dest/$file"
    fi
  done <<< "$helper_files"
}

splash_screen() {
  # This function will replace the RetroDECK startup splash screen with a different image if the day and time match a listing in the JSON data.
  # USAGE: splash_screen

  current_day=$(date +"%m%d")  # Read the current date in a format that can be calculated in ranges
  current_time=$(date +"%H%M") # Read the current time in a format that can be calculated in ranges

  # Read the JSON file and extract splash screen data using jq
  splash_screen=$(jq -r --arg current_day "$current_day" --arg current_time "$current_time" '
    .splash_screens | to_entries[] |
    select(
      ($current_day | tonumber) >= (.value.start_date | tonumber) and
      ($current_day | tonumber) <= (.value.end_date | tonumber) and
      ($current_time | tonumber) >= (.value.start_time | tonumber) and
      ($current_time | tonumber) <= (.value.end_time | tonumber)
    ) | .value.filename' "$features")

  # Determine the splash file to use
  if [[ -n "$splash_screen" ]]; then
    new_splash_file="$splashscreen_dir/$splash_screen"
  else
    new_splash_file="$default_splash_file"
  fi

  cp -f "$new_splash_file" "$current_splash_file" # Deploy assigned splash screen
}

install_release() {
  # Logging the release tag and URL
  log d "Attempting to install release: $1 from repo $update_repo"

  # Construct the URL for the flatpak file

  if [ "$(get_setting_value "$rd_conf" "update_repo" "retrodeck" "options")" == "RetroDECK" ]; then
      iscooker=""
  else
      iscooker="-cooker"
  fi

  local flatpak_url="https://github.com/$git_organization_name/$update_repo/releases/download/$1/RetroDECK$iscooker.flatpak"
  log d "Constructed flatpak URL: $flatpak_url"

  # Confirm installation with the user
  rd_zenity --question --icon-name=net.retrodeck.retrodeck --no-wrap \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK Updater" \
          --text="$1 will be now installed.\nThe update process may take several minutes.\n\nAfter the update is complete, RetroDECK will close. When you run it again, you will be using the latest version.\n\nDo you want to continue?"

  rc=$? # Capture return code
  if [[ $rc == "1" ]]; then # If the user clicks "Cancel"
    return 0
  fi
  
  (
    mkdir -p "$rdhome/RetroDECK_Updates"

    # Download the flatpak file
    wget -P "$rdhome/RetroDECK_Updates" "$flatpak_url" -O "$rdhome/RetroDECK_Updates/RetroDECK$iscooker.flatpak"
    
    # Check if the download was successful
    if [[ $? -ne 0 ]]; then
      configurator_generic_dialog "Error" "Failed to download the flatpak file. Please check the release tag and try again."
      return 1
    fi

    # Remove the current version before installing the new one to avoid duplicates
    flatpak-spawn --host flatpak remove --noninteractive -y net.retrodeck.retrodeck
    
    # Install the new version
    flatpak-spawn --host flatpak install --user --bundle --noninteractive -y "$rdhome/RetroDECK_Updates/RetroDECK$iscooker.flatpak"
    
    # Cleanup old bundles to save space
    rm -rf "$rdhome/RetroDECK_Updates"
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Updater" \
  --text="RetroDECK is updating to the selected version, please wait."

  configurator_generic_dialog "RetroDECK Online Update" "The update process is now complete!\n\nRetroDECK will now quit."
  quit_retrodeck
}

ponzu() {
  # This function is used to extract some specific appimages
  # Check if any of the specified files exist
  # If RetroDECK is reset Ponzu must re-cooked

  log d "Checking for Ponzu"

  local tmp_folder="/tmp/extracted"
  local ponzu_files=("$rdhome"/ponzu/Citra*.AppImage "$rdhome"/ponzu/citra*.AppImage "$rdhome"/ponzu/Yuzu*.AppImage "$rdhome"/ponzu/yuzu*.AppImage) 
  local data_dir
  local appimage
  local executable

  # if the binaries are found, ponzu should be set as true into the retrodeck config
  if [ -f "$XDG_DATA_HOME/ponzu/Citra/bin/citra-qt" ]; then
    log d "Citra binaries has already been installed, checking for updates and forcing the setting as true."
    set_setting_value "$rd_conf" "akai_ponzu" "true" retrodeck "options"
  fi
  if [ -f "$XDG_DATA_HOME/ponzu/Yuzu/bin/yuzu" ]; then
    log d "Yuzu binaries has already been installed, checking for updates and forcing the setting as true."
    set_setting_value "$rd_conf" "kiroi_ponzu" "true" retrodeck "options"
  fi

  # Loop through all ponzu files
  for ponzu_file in "${ponzu_files[@]}"; do
    # Check if the current ponzu file exists
    if [ -f "$ponzu_file" ]; then
      if [[ "$ponzu_file" == *itra* ]]; then
        log i "Found akai ponzu! Elaborating it"
        data_dir="$XDG_DATA_HOME/ponzu/Citra"
        local message="Akai ponzu is served, enjoy"
      elif [[ "$ponzu_file" == *uzu* ]]; then
        log i "Found kiroi ponzu! Elaborating it"
        data_dir="$XDG_DATA_HOME/ponzu/Yuzu"
        local message="Kiroi ponzu is served, enjoy"
      else
        log e "AppImage not recognized, not a ponzu ingredient!"
        exit 1
      fi
      appimage="$ponzu_file"
      chmod +x "$ponzu_file"
      create_dir "$data_dir"
      log d "Moving AppImage in \"$data_dir\""
      mv "$appimage" "$data_dir"
      cd "$data_dir"
      local filename=$(basename "$ponzu_file")
      log d "Setting appimage=$data_dir/$filename"
      appimage="$data_dir/$filename"
      log d "Extracting AppImage"
      "$appimage" --appimage-extract
      create_dir "$tmp_folder"
      log d "Cleaning up"
      cp -r squashfs-root/* "$tmp_folder"
      rm -rf *
      if [[ "$ponzu_file" == *itra* ]]; then
        mv "$tmp_folder/usr/"** .
        executable="$data_dir/bin/citra"
        log d "Making $executable and $executable-qt executable"
        chmod +x "$executable"
        chmod +x "$executable-qt"
        prepare_component "reset" "citra"
        set_setting_value "$rd_conf" "akai_ponzu" "true" retrodeck "options"
      elif [[ "$ponzu_file" == *uzu* ]]; then
        mv "$tmp_folder/usr/"** .
        executable="$data_dir/bin/yuzu"
        log d "Making $executable executable"
        chmod +x "$executable"
        prepare_component "reset" "yuzu"
        set_setting_value "$rd_conf" "kiroi_ponzu" "true" retrodeck "options"
      fi
      
      cd -
      log i "$message"
      rm -rf "$tmp_folder"
    fi
  done
  rm -rf "$rdhome/ponzu"
}

ponzu_remove() {

  # Call me with yuzu or citra and I will remove them

  if [[ "$1" == "citra" ]]; then
    if [[ $(configurator_generic_question_dialog "Ponzu - Remove Citra" "Do you really want to remove Citra binaries?\n\nYour games and saves will not be deleted.") == "true" ]]; then
      log i "Ponzu: removing Citra"
      rm -rf "$XDG_DATA_HOME/ponzu/Citra"
      set_setting_value "$rd_conf" "akai_ponzu" "false" retrodeck "options"
      configurator_generic_dialog "Ponzu - Remove Citra" "Done, Citra is now removed from RetroDECK"
    fi
  elif [[ "$1" == "yuzu" ]]; then
    if [[ $(configurator_generic_question_dialog "Ponzu - Remove Yuzu" "Do you really want to remove Yuzu binaries?\n\nYour games and saves will not be deleted.") == "true" ]]; then
      log i "Ponzu: removing Yuzu"
      rm -rf "$XDG_DATA_HOME/ponzu/Yuzu"
      set_setting_value "$rd_conf" "kiroi_ponzu" "false" retrodeck "options"
      configurator_generic_dialog "Ponzu - Remove Yuzu" "Done, Yuzu is now removed from RetroDECK"
    fi
  else
    log e "Ponzu: \"$1\" is not a vaild choice for removal, quitting"
  fi
  configurator_tools_dialog
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
    configurator_generic_dialog "Error" "Unable to fetch the main release. Please check your network connection or try again later."
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
    configurator_generic_dialog "Error" "Unable to fetch releases. Please check your network connection or try again later."
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
    configurator_generic_dialog "RetroDECK Updater" "No available releases found, exiting."
    log d "No available releases found"
    return 1
  fi

  log d "Showing available releases"

  # Display releases in a Zenity list dialog with three columns
  selected_release=$(
    rd_zenity --list \
      --icon-name=net.retrodeck.retrodeck \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Cooker Releases - Select Release" \
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
    --title "RetroDECK Configurator Cooker Release - Confirm Selection" \
    --text="Are you sure you want to install the following release?\n\n$selected_branch: \"$selected_tag\"\nPublished on $selected_date?"

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
  log i "Quitting ES-DE"
  pkill -f "es-de"

  # if steam sync is on do the magic
  if [[ $(get_setting_value "$rd_conf" "steam_sync" "retrodeck" "options") == "true" ]]; then
    export CONFIGURATOR_GUI="zenity"
    steam_sync
  fi
  log i "Shutting down RetroDECK's framework"
  pkill -f "retrodeck"
  
  log i "See you next time"
  exit
}

start_retrodeck() {
  get_steam_user # get steam user info
  splash_screen # Check if today has a surprise splashscreen and load it if so
  ponzu

  log d "Checking if PortMaster should be shown"
  if [[ $(get_setting_value "$rd_conf" "portmaster_show" "retrodeck" "options") == "false" ]]; then
    log d "Assuring that PortMaster is hidden on ES-DE"
    portmaster_show "false"
  else
    log d "Assuring that PortMaster is shown on ES-DE"
    portmaster_show "true"
  fi

  log i "Starting RetroDECK v$version"
  es-de
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

retroarch_updater() {
  # This function updates RetroArch by synchronizing shaders, cores, and border overlays.
  # It should be called whenever RetroArch is reset or updated.

  log i "Running RetroArch updater"
  
  # Synchronize cores from the application share directory to the RetroArch cores directory
  rsync -rlD --mkpath "/app/share/libretro/cores/" "$XDG_CONFIG_HOME/retroarch/cores/" && log d "RetroArch cores updated correctly"
  
  # Synchronize border overlays from the RetroDeck configuration directory to the RetroArch overlays directory
  rsync -rlD --mkpath "/app/retrodeck/config/retroarch/borders/" "$XDG_CONFIG_HOME/retroarch/overlays/borders/" && log d "RetroArch overlays and borders updated correctly"
}

portmaster_show(){
  log d "Setting PortMaster visibility in ES-DE"
  if [ "$1" = "true" ]; then
      log d "\"$roms_folder/portmaster/PortMaster.sh\" is not found, installing it"
      install -Dm755 "$XDG_DATA_HOME/PortMaster/PortMaster.sh" "$roms_folder/portmaster/PortMaster.sh" && log d "PortMaster is correctly showing in ES-DE"
      set_setting_value "$rd_conf" "portmaster_show" "true" retrodeck "options"
  elif [ "$1" = "false" ]; then
    rm -rf "$roms_folder/portmaster/PortMaster.sh" && log d "PortMaster is correctly hidden in ES-DE"
    set_setting_value "$rd_conf" "portmaster_show" "false" retrodeck "options"
  else
    log e "\"$1\" is not a valid choice, quitting"
  fi
}

open_component(){

  if [[ -z "$1" ]]; then
    cmd=$(jq -r '.emulator[] | select(.ponzu != true) | .name' "$features")
    if [[ $(get_setting_value "$rd_conf" "akai_ponzu" "retrodeck" "options") == "true" ]]; then
      cmd+="\n$(jq -r '.emulator.citra | .name' "$features")"
    fi
    if [[ $(get_setting_value "$rd_conf" "kiroi_ponzu" "retrodeck" "options") == "true" ]]; then
      cmd+="\n$(jq -r '.emulator.yuzu | .name' "$features")"
    fi
    echo -e "This command expects one of the following components as arguments:\n$(echo -e "$cmd")"
    return
  fi

  if [[ "$1" == "--list" ]]; then
    cmd=$(jq -r '.emulator[] | select(.ponzu != true) | .name' "$features")
    if [[ $(get_setting_value "$rd_conf" "akai_ponzu" "retrodeck" "options") == "true" ]]; then
      cmd+="\n$(jq -r '.emulator.citra | .name' "$features")"
    fi
    if [[ $(get_setting_value "$rd_conf" "kiroi_ponzu" "retrodeck" "options") == "true" ]]; then
      cmd+="\n$(jq -r '.emulator.yuzu | .name' "$features")"
    fi
    echo -e "$cmd"
    return
  fi

  if [[ "$1" == "--getdesc" ]]; then
    cmd=$(jq -r '.emulator[] | select(.ponzu != true) | "\(.description)"' "$features")
    if [[ $(get_setting_value "$rd_conf" "akai_ponzu" "retrodeck" "options") == "true" ]]; then
      cmd+="\n$(jq -r '.emulator.citra | "\(.description)"' "$features")"
    fi
    if [[ $(get_setting_value "$rd_conf" "kiroi_ponzu" "retrodeck" "options") == "true" ]]; then
      cmd+="\n$(jq -r '.emulator.yuzu | "\(.description)"' "$features")"
    fi
    echo -e "$cmd"
    return
  fi

  launch_exists=$(jq -r --arg name "$1" '.emulator[] | select(.name == $name) | has("launch")' "$features")
  if [[ "$launch_exists" != "true" ]]; then
    echo "Error: The component '$1' cannot be opened."
    return 1
  fi

  cmd=$(jq -r --arg name "$1" '.emulator[] | select(.name == $name and .ponzu != true) | .launch' "$features")
  if [[ -z "$cmd" && $(get_setting_value "$rd_conf" "akai_ponzu" "retrodeck" "options") == "true" && "$1" == "citra" ]]; then
    cmd=$(jq -r '.emulator.citra | .launch' "$features")
  fi
  if [[ -z "$cmd" && $(get_setting_value "$rd_conf" "kiroi_ponzu" "retrodeck" "options") == "true" && "$1" == "yuzu" ]]; then
    cmd=$(jq -r '.emulator.yuzu | .launch' "$features")
  fi

  if [[ -n "$cmd" ]]; then
    eval "$cmd" "${@:2}"
  else
    echo "Invalid component name: $1"
    echo "Please ensure the name is correctly spelled (case sensitive) and quoted if it contains spaces."
  fi
}

add_retrodeck_to_steam(){

    log i "Checking if user wants to add RetroDECK to Steam"

    rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
  --text="Do you want to add RetroDECK to Steam?"
    if [ $? == 0 ]; then
      (
        log i "RetroDECK has been added to Steam"
        steam-rom-manager enable --names "RetroDECK Launcher"
        steam-rom-manager add
      ) |
      rd_zenity --progress --no-cancel --pulsate --auto-close \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "Adding RetroDECK to Steam" \
        --text="Please wait while RetroDECK is being added to Steam...\n\n"
      rd_zenity --info --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --text="RetroDECK has been added to Steam.\n\nPlease close and reopen Steam to see the changes."
    fi
}

repair_paths() {
  # This function will verify that all folders defined in the [paths] section of retrodeck.cfg exist
  # If a folder doesn't exist and is defined outside of rdhome, it will check in rdhome first and have the user browse for them manually if it isn't there either
  # USAGE: repair_paths

  invalid_path_found="false"

  log i "Checking that all RetroDECK paths are valid"
  while IFS= read -r path_name; do
    if [[ ! $path_name =~ (rdhome|sdcard) ]]; then # Ignore these locations
      local path_value=$(get_setting_value "$rd_conf" "$path_name" "retrodeck" "paths")
      if [[ ! -d "$path_value" ]]; then # If the folder doesn't exist as defined
        log i "$path_name does not exist as defined, config is incorrect"
        if [[ ! -d "$rdhome/${path_value#*retrodeck/}" ]]; then # If the folder doesn't exist within defined rdhome path
          if [[ ! -d "$sdcard/${path_value#*retrodeck/}" ]]; then # If the folder doesn't exist within defined sdcard path
            log i "$path_name cannot be found at any expected location, having user locate it manually"
            configurator_generic_dialog "RetroDECK Path Repair" "The RetroDECK $path_name was not found in the expected location.\nThis may happen when the folder is moved manually.\n\nPlease browse to the current location of the $path_name."
            new_path=$(directory_browse "RetroDECK $path_name location")
            set_setting_value "$rd_conf" "$path_name" "$new_path" retrodeck "paths"
            invalid_path_found="true"
          else # Folder does exist within defined sdcard path, update accordingly
            log i "$path_name found in $sdcard/retrodeck, correcting path config"
            new_path="$sdcard/retrodeck/${path_value#*retrodeck/}"
            set_setting_value "$rd_conf" "$path_name" "$new_path" retrodeck "paths"
            invalid_path_found="true"
          fi
        else # Folder does exist within defined rdhome path, update accordingly
          log i "$path_name found in $rdhome, correcting path config"
          new_path="$rdhome/${path_value#*retrodeck/}"
          set_setting_value "$rd_conf" "$path_name" "$new_path" retrodeck "paths"
          invalid_path_found="true"
        fi
      fi
    fi
  done < <(jq -r '(.paths // {}) | keys[]' "$rd_conf")

  if [[ $invalid_path_found == "true" ]]; then
    log i "One or more invalid paths repaired, fixing internal RetroDECK structures"
    conf_read
    dir_prep "$logs_folder" "$rd_logs_folder"
    prepare_component "postmove" "all"
    configurator_generic_dialog "RetroDECK Path Repair" "One or more incorrectly configured paths were repaired."
  else
    log i "All folders were found at their expected locations"
    configurator_generic_dialog "RetroDECK Path Repair" "All RetroDECK folders were found at their expected locations."
  fi
}

sanitize() {
    # Function to sanitize strings for filenames
    # Replace sequences of underscores with a single space
    echo "$1" | sed -e 's/_\{2,\}/ /g' -e 's/_/ /g' -e 's/:/ -/g' -e 's/&/and/g' -e 's%/%and%g' -e 's/  / /g'
}

get_cheevos_token() {
  # This function will attempt to authenticate with the RA API with the supplied credentials and will return a JSON object if successful
  # USAGE get_cheevos_token $username $password

  local cheevos_api_response=$(curl --silent --data "r=login&u=$1&p=$2" "$RA_API_URL")
  local cheevos_success=$(echo "$cheevos_api_response" | jq -r '.Success')
  if [[ "$cheevos_success" == "true" ]]; then
    log d "login succeeded"
    echo "$cheevos_api_response"
  else
    log d "login failed"
    return 1
  fi
}

check_if_updated() {
  # Check if an update has happened
  if [ -f "$lockfile" ]; then
    if [ "$hard_version" != "$version" ]; then
      log d "Update triggered"
      log d "Lockfile found but the version doesn't match with the config file"
      log i "Config file's version is $version but the actual version is $hard_version"
      if grep -qF "cooker" <<< "$hard_version"; then # If newly-installed version is a "cooker" build
        log d "Newly-installed version is a \"cooker\" build"
        configurator_generic_dialog "RetroDECK Cooker Warning" "RUNNING COOKER VERSIONS OF RETRODECK CAN BE EXTREMELY DANGEROUS AND ALL OF YOUR RETRODECK DATA\n(INCLUDING BIOS FILES, BORDERS, DOWNLOADED MEDIA, GAMELISTS, MODS, ROMS, SAVES, STATES, SCREENSHOTS, TEXTURE PACKS AND THEMES)\nARE AT RISK BY CONTINUING!"
        set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
        set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
        set_setting_value "$rd_conf" "developer_options" "true" retrodeck "options"
        set_setting_value "$rd_conf" "logging_level" "debug" retrodeck "options"
        cooker_base_version=$(echo "$version" | cut -d'-' -f2)
        choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Upgrade" --extra-button="Don't Upgrade" --extra-button="Full Wipe and Fresh Install" \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Cooker Upgrade" \
        --text="You appear to be upgrading to a \"cooker\" build of RetroDECK.\n\nWould you like to perform the standard post-update process, skip the post-update process or remove ALL existing RetroDECK folders and data (including ROMs and saves) to start from a fresh install?\n\nPerforming the normal post-update process multiple times may lead to unexpected results.")
        rc=$? # Capture return code, as "Yes" button has no text value
        if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
          if [[ "$choice" == "Don't Upgrade" ]]; then # If user wants to bypass the post_update.sh process this time.
            log i "Skipping upgrade process for cooker build, updating stored version in retrodeck.cfg"
            set_setting_value "$rd_conf" "version" "$hard_version" retrodeck # Set version of currently running RetroDECK to updated retrodeck.cfg
          elif [[ "$choice" == "Full Wipe and Fresh Install" ]]; then # Remove all RetroDECK data and start a fresh install
            if [[ $(configurator_generic_question_dialog "RetroDECK Cooker Reset" "This is going to remove all of the data in all locations used by RetroDECK!\n\n(INCLUDING BIOS FILES, BORDERS, DOWNLOADED MEDIA, GAMELISTS, MODS, ROMS, SAVES, STATES, SCREENSHOTS, TEXTURE PACKS AND THEMES)\n\nAre you sure you want to contine?") == "true" ]]; then
              if [[ $(configurator_generic_question_dialog "RetroDECK Cooker Reset" "Are you super sure?\n\nThere is no going back from this process, everything is gonzo.\nDust in the wind.\n\nYesterdays omelette.") == "true" ]]; then
                if [[ $(configurator_generic_question_dialog "RetroDECK Cooker Reset" "But are you super DUPER sure? We REAAAALLLLLYY want to make sure you know what is happening here.\n\nThe ~/retrodeck and ~/.var/app/net.retrodeck.retrodeck folders and ALL of their contents\nare about to be PERMANENTLY removed.\n\nStill sure you want to proceed?") == "true" ]]; then
                  configurator_generic_dialog "RetroDECK Cooker Reset" "Ok, if you're that sure, here we go!"
                  if [[ $(configurator_generic_question_dialog "RetroDECK Cooker Reset" "(Are you actually being serious here? Because we are...\n\nNo backsies.)") == "true" ]]; then
                    log w "Removing RetroDECK data and starting fresh"
                    rm -rf /var
                    rm -rf "$HOME/retrodeck"
                    rm -rf "$rdhome"
                    source /app/libexec/global.sh
                    finit
                  fi
                fi
              fi
            fi
          fi
        else
          log i "Performing normal upgrade process for version $cooker_base_version"
          version="$cooker_base_version" # Temporarily assign cooker base version to $version so update script can read it properly.
          post_update
        fi
      else # If newly-installed version is a normal build.
        if grep -qF "cooker" <<< "$version"; then # If previously installed version was a cooker build
          cooker_base_version=$(echo "$version" | cut -d'-' -f2)
          version="$cooker_base_version" # Temporarily assign cooker base version to $version so update script can read it properly.
          set_setting_value "$rd_conf" "update_repo" "RetroDECK" retrodeck "options"
          set_setting_value "$rd_conf" "update_check" "false" retrodeck "options"
          set_setting_value "$rd_conf" "update_ignore" "" retrodeck "options"
          set_setting_value "$rd_conf" "developer_options" "false" retrodeck "options"
          set_setting_value "$rd_conf" "logging_level" "info" retrodeck "options"
        fi
        post_update       # Executing post update script
      fi
    fi
  # Else, LOCKFILE IS NOT EXISTING (WAS REMOVED)
  # if the lock file doesn't exist at all means that it's a fresh install or a triggered reset
  else
    log w "Lockfile not found"
    finit             # Executing First/Force init
  fi
}

source_component_functions() {
  # This function will iterate the paths.sh file for every installed component and source it for use in the greater application
  while IFS= read -r functions_file; do
    log d "Found component paths file $functions_file"
    source "$functions_file"
  done < <(find "$RD_MODULES" -maxdepth 2 -mindepth 2 -type f -name "functions.sh")
}

update_rd_conf() {
  # This function will update the retrodeck.cfg file with any new settings which are included in the shipped defaults file.
  # This will allow expansion of the included settings over time while keeping all existing user settings intact.

  for section_name in $(jq -r '. | keys[]' "$rd_defaults"); do
    if [[ ! "$section_name" == "version" ]]; then
      if ! jq -e --arg section "$section_name" '. | has($section)' "$rd_conf" > /dev/null; then # If the name of the section doesn't exist at all.
        log d "Section \"$section_name\" not found in retrodeck.cfg, creating it."
        tmpfile=$(mktemp)
        jq --arg section "$section_name" '. += { ($section): {} }' "$rd_conf" > "$tmpfile" && mv "$tmpfile" "$rd_conf"
      fi
      for setting_name in $(jq -r --arg section "$section_name" '.[$section] | keys[]' "$rd_defaults"); do
        if jq -e --arg section "$section_name" --arg setting "$setting_name" '.[$section] | has($setting)' "$rd_conf" > /dev/null; then
          log d "The section \"$section_name\" already contains the setting \"$setting_name\". Skipping."
        else
          default_setting_value=$(jq -r --arg section "$section_name" --arg setting "$setting_name" '.[$section][$setting]' "$rd_defaults")
          log d "Adding setting \"$setting_name\" with default value '$default_setting_value' to section \"$section_name\"."
          tmpfile=$(mktemp)
          jq --arg section "$section_name" --arg setting "$setting_name" --arg value "$default_setting_value" \
            '.[$section] += { ($setting): $value }' "$rd_conf" > "$tmpfile" && mv "$tmpfile" "$rd_conf"
        fi
      done
    fi
  done
}

update_component_presets() {
  # This function will create, as needed, component entries for different presets in retrodeck.cfg
  # This will allow us to expand the supported presets for every component in the presets section at once, creating new component entries in each named preset as needed.
  # USAGE: update_component_presets

  while IFS= read -r manifest_file; do
    log d "Examining manifest file $manifest_file"
    component_name=$(jq -r '. | keys[]' "$manifest_file")
    if jq -e --arg component "$component_name" '.[$component].compatible_presets? != null' "$manifest_file" > /dev/null; then # Check if the given manifest file even has a presets section
      while read -r preset_name; do # Gather non-nested entries
        if ! jq -e --arg preset "$preset_name" '.presets | has($preset)' "$rd_conf" > /dev/null; then # If the name of the preset doesn't exist at all in retrodeck.cfg
          log d "Preset \"$preset_name\" not found, creating it."
          tmpfile=$(mktemp)
          jq --arg preset "$preset_name" '.presets += { ($preset): {} }' "$rd_conf" > "$tmpfile" && mv "$tmpfile" "$rd_conf"
        fi
        if jq -e --arg preset "$preset_name" --arg component "$component_name" '.presets[$preset] | has($component)' "$rd_conf" > /dev/null; then
          log d "The preset \"$preset_name\" already contains the component \"$component_name\". Skipping."
        else
          # Retrieve the first element of the array for the current preset name in the source file, which is the "disabled" state
          default_preset_value=$(jq -r --arg name "$component_name" --arg preset "$preset_name" '.[$name].compatible_presets[$preset][0]' "$manifest_file")
          log d "Adding component \"$component_name\" with default value '$default_preset_value' to preset \"$preset_name\"."
          tmpfile=$(mktemp)
          jq --arg preset "$preset_name" --arg component "$component_name" --arg value "$default_preset_value" \
            '.presets[$preset] += { ($component): $value }' "$rd_conf" > "$tmpfile" && mv "$tmpfile" "$rd_conf"
        fi
      done < <(jq -r --arg component "$component_name" '
                                    .[$component].compatible_presets
                                    | to_entries[]
                                    | select(.value|type == "array")
                                    | .key
                                  ' "$manifest_file")
      while read -r nested_object; do # Gather nested entries, such as RA cores
        while read -r preset_name; do # Gather non-nested entries
          if ! jq -e --arg preset "$preset_name" '.presets | has($preset)' "$rd_conf" > /dev/null; then # If the name of the preset doesn't exist at all in retrodeck.cfg
            log d "Preset \"$preset_name\" not found, creating it."
            tmpfile=$(mktemp)
            jq --arg preset "$preset_name" '.presets += { ($preset): {} }' "$rd_conf" > "$tmpfile" && mv "$tmpfile" "$rd_conf"
          fi
          if ! jq -e --arg component "$component_name.cores" --arg preset "$preset_name" '.presets[$preset] | has($component)' "$rd_conf" > /dev/null; then # If there is no wrapper for the parent component for this core
            log d "Wrapper for parent component \"$component_name\" in \"$preset_name\" not found, creating it."
            tmpfile=$(mktemp)
            jq --arg component "$component_name.cores" --arg preset "$preset_name" '.presets[$preset] += { ($component): {} }' "$rd_conf" > "$tmpfile" && mv "$tmpfile" "$rd_conf"
          fi
          if jq -e --arg preset "$preset_name" --arg component "$component_name.cores" --arg nest "$nested_object" '.presets[$preset][$component] | has($nest)' "$rd_conf" > /dev/null; then
            log d "The preset \"$preset_name\" already contains the component \"$component_name\" core \"$nested_object\". Skipping."
          else
            # Retrieve the first element of the array for the current preset name in the source file, which is the "disabled" state
            default_preset_value=$(jq -r --arg name "$component_name" --arg nest "$nested_object" --arg preset "$preset_name" '.[$name].compatible_presets[$nest][$preset][0]' "$manifest_file")
            log d "Adding component \"$component_name\" core \"$nested_object\" with default value '$default_preset_value' to preset \"$preset_name\"."
            tmpfile=$(mktemp)
            jq --arg preset "$preset_name" --arg component "$component_name.cores" --arg nest "$nested_object" --arg value "$default_preset_value" \
              '.presets[$preset][$component] += { ($nest): $value }' "$rd_conf" > "$tmpfile" && mv "$tmpfile" "$rd_conf"
          fi
        done < <(jq -r --arg component "$component_name" --arg nest "$nested_object" '
                                    .[$component].compatible_presets[$nest]
                                    | to_entries[]
                                    | select(.value|type == "array")
                                    | .key
                                  ' "$manifest_file")
      done < <(jq -r --arg component "$component_name" '
                                  .[$component].compatible_presets
                                  | to_entries[]
                                  | select(.value|type == "object")
                                  | .key
                                ' "$manifest_file")
    fi
  done < <(find "$RD_MODULES" -maxdepth 2 -mindepth 2 -type f -name "manifest.json")
}

install_preset_files() {
  # This function will copy files from a source to a destination, for the purposes of making them available for a preset.
  # An example of this purpose would be the Dynamic Input Textures for use in Dolphin or Primehack
  # The destination path must be the FULL destination, even if it does not currently exist, not the parent directory of the destination.
  # If the destination path does not exist it will be created.
  # USAGE: install_preset_files "$source" "$destination"

  local source="$1"
  local dest="$2"

  if [[ -d "$source" ]]; then # Ensure paths to directories always have a trailing slash
    [[ "${source}" != */ ]] && source="${source}/"
  elif [[ ! -f "$source" ]]; then # If given path is neither a file or folder
    log d "Provided source $source is neither a valid file or directory"
    return 1
  fi
  if [[ -d "$dest" ]]; then # Ensure paths to directories always have a trailing slash
    [[ "${dest}" != */ ]] && dest="${dest}/"
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

  # If everything else fails, exit poorly
  return 1
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
