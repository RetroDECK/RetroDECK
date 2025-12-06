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
      rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No 🟥" --ok-label="Yes 🟢" \
      --text="Directory <span foreground='$purple'><b>$target</b></span> selected.\nIs this correct?"
      if [ $? == 0 ]
      then
        path_selected=true
        echo "$target"
        break
      fi
    else
      rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No 🟥" --ok-label="Yes 🟢" \
      --text="No directory selected.\n\n<span foreground='$purple'><b>Do you want to exit the selection process?</b></span>"
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
      rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No 🟥" --ok-label="Yes 🟢" \
      --text="File <span foreground='$purple'><b>$target</b></span> selected.\nIs this correct?"
      if [ $? == 0 ]
      then
        file_selected=true
        echo "$target"
        break
      fi
    else
      rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No 🟥" --ok-label="Yes 🟢" \
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
  --title "RetroDECK Configurator - Move in Progress" \
  --text="Moving directory: <span foreground='$purple'><b>$(basename "$1")</b></span>\n\n To a new location: <span foreground='$purple'><b>$2</b></span>.\n\n⏳<span foreground='$purple'><b>Please wait while the process finishes...</b></span>⏳"

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
    # If "force" flag is provided, delete the directory first
    shift # Remove the first argument (-f)
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
    mkdir -p "$1" #|| log e "Failed to create directory: $1"
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
    --text="Downloading <span foreground='$purple'><b>$3</b></span>..." \
    --pulsate \
    --auto-close
}

conf_read() {
  # This function will read the RetroDECK config file into memory
  # USAGE: conf_read

  set -o allexport # Export all the variables found during sourcing, for use elsewhere  

  if head -n 1 "$rd_conf" | grep -qE '^\s*\{\s*$'; then # If retrodeck.cfg is new JSON format
    while IFS== read -r name value; do
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
  set +o allexport # Back to normal, otherwise every assigned variable will get exported through the rest of the run
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

  if [[ -z "$1" ]]; then
    log e "No real directory specified for preparation"
    return 1
  fi

  if [[ -z "$2" ]]; then
    log e "No symlink location specified for preparation"
    return 1
  fi

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
    if [[ -n $(ls -A1 "$symlink.old") ]]; then # If the old folder is not empty
      log d "Moving the data from $symlink.old to $real" #DEBUG
      shopt -s dotglob
      mv -f "${symlink}.old"/* "$real"
      shopt -u dotglob
    else
      log d "$symlink.old is empty, no need to move files."
    fi
    log d "Removing $symlink.old" #DEBUG
    rm -rf "$symlink.old"
  fi

  log i "$symlink is now $real"
}

update_rpcs3_firmware() {
  create_dir "$roms_path/ps3/tmp"
  chmod 777 "$roms_path/ps3/tmp"
  download_file "$rpcs3_firmware_url" "$roms_path/ps3/tmp/PS3UPDAT.PUP" "RPCS3 Firmware"
  rpcs3 --installfw "$roms_path/ps3/tmp/PS3UPDAT.PUP"
  rm -rf "$roms_path/ps3/tmp"
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
  #        backup_retrodeck_userdata custom saves_path states_path /some/other/path

  create_dir "$backups_path"

  # Check if first argument is the type
  if [[ "$1" == "complete" || "$1" == "core" || "$1" == "custom" ]]; then
    backup_type="$1"
    shift # Remove the first argument
  else
    if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
      configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "No valid backup option chosen. Valid options are <standard> and <custom>."
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
    local path_var=$(echo "$config_path" | jq -r '.key')
    local path_value=$(echo "$config_path" | jq -r '.value')
    log d "Adding $path_value to compressible paths."
    config_paths["$path_var"]="$path_value"
  done < <(jq -c '.paths | to_entries[] | select(.key != "rd_home_path" and .key != "backups_path" and .key != "sdcard")' "$rd_conf")

  # Determine which paths to backup
  if [[ "$backup_type" == "complete" ]]; then
    for folder_name in "${!config_paths[@]}"; do
      path_value="${config_paths[$folder_name]}"
      if [[ -e "$path_value" ]]; then
        paths_to_backup+=("$path_value")
        log i "Adding to backup: $folder_name = $path_value"
      else
        if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
          configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "The <span foreground='$purple'><b>$folder_name</b></span> was not found at its expected location: <span foreground='$purple'><b>$path_value</b></span>.\nSomething may be wrong with your RetroDECK installation."
        fi
        log i "Warning: Path does not exist: $folder_name = $path_value"
      fi
    done

    # Add static paths not defined in retrodeck.cfg
    if [[ -e "$rd_home_path/ES-DE/collections" ]]; then
      paths_to_backup+=("$rd_home_path/ES-DE/collections")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "The ES-DE collections folder was not found at its expected location: <span foreground='$purple'><b>$rd_home_path/ES-DE/collections</b></span>.\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/collections = $rd_home_path/ES-DE/collections"
    fi

    if [[ -e "$rd_home_path/ES-DE/gamelists" ]]; then
      paths_to_backup+=("$rd_home_path/ES-DE/gamelists")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "The ES-DE gamelists folder was not found at its expected location: <span foreground='$purple'><b>$rd_home_path/ES-DE/gamelists</b></span>.\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/gamelists = $rd_home_path/ES-DE/gamelists"
    fi

    if [[ -e "$rd_home_path/ES-DE/custom_systems" ]]; then
      paths_to_backup+=("$rd_home_path/ES-DE/custom_systems")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "The ES-DE custom_systems folder was not found at its expected location: <span foreground='$purple'><b>$rd_home_path/ES-DE/custom_systems</b></span>.\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/custom_systems = $rd_home_path/ES-DE/custom_systems"
    fi

    # Check if we found any valid paths
    if [[ ${#paths_to_backup[@]} -eq 0 ]]; then
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "<span foreground='$purple'><b>No valid userdata folders were found.</b></span>\nSomething may be wrong with your RetroDECK installation."
      fi
      log e "Error: No valid paths found in config file"
      return 1
    fi

  elif [[ "$backup_type" == "core" ]]; then
    for folder_name in "${!config_paths[@]}"; do
      if [[ $folder_name =~ (saves_path|states_path|logs_path) ]]; then # Only include these paths
        path_value="${config_paths[$folder_name]}"
        if [[ -e "$path_value" ]]; then
          paths_to_backup+=("$path_value")
          log i "Adding to backup: $folder_name = $path_value"
        else
          if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
            configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "The <span foreground='$purple'><b>$folder_name</b></span> was not found at its expected location: <span foreground='$purple'><b>$path_value</b></span>.\nSomething may be wrong with your RetroDECK installation."
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
        configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "The ES-DE collections folder was not found at its expected location, $rd_home_path/ES-DE/collections\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/collections = $rd_home_path/ES-DE/collections"
    fi

    if [[ -e "$rd_home_path/ES-DE/gamelists" ]]; then
      paths_to_backup+=("$rd_home_path/ES-DE/gamelists")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "The ES-DE collections folder was not found at its expected location: <span foreground='$purple'><b>$rd_home_path/ES-DE/collections</b></span>.\nSomething may be wrong with your RetroDECK installation.."
      fi
      log i "Warning: Path does not exist: ES-DE/gamelists = $rd_home_path/ES-DE/gamelists"
    fi

    if [[ -e "$rd_home_path/ES-DE/custom_systems" ]]; then
      paths_to_backup+=("$rd_home_path/ES-DE/custom_systems")
    else
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "The ES-DE custom_systems folder was not found at its expected location: <span foreground='$purple'><b>$rd_home_path/ES-DE/custom_systems</b></span>.\nSomething may be wrong with your RetroDECK installation."
      fi
      log i "Warning: Path does not exist: ES-DE/custom_systems = $rd_home_path/ES-DE/custom_systems"
    fi

    # Check if we found any valid paths
    if [[ ${#paths_to_backup[@]} -eq 0 ]]; then
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "<span foreground='$purple'><b>No valid userdata folders were found.</b></span>\nSomething may be wrong with your RetroDECK installation."
      fi
      log e "Error: No valid paths found in config file"
      return 1
    fi

  elif [[ "$backup_type" == "custom" ]]; then
    if [[ "$#" -eq 0 ]]; then # Check if any paths were provided in the arguments
      if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
        configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "<span foreground='$purple'><b>No valid backup locations were specified.</b></span> Please try again."
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
            configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "The <span foreground='$purple'><b>$arg</b></span> was not found at its expected location: <span foreground='$purple'><b>$path_value</b></span>.\nSomething may be wrong with your RetroDECK installation."
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
          configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "The path <span foreground='$purple'><b>$arg</b></span> was not found at its expected location.\nPlease check the path and try again."
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
            --title "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" \
            --text="Verifying there is enough free space for the backup.\n\n⏳<span foreground='$purple'><b>Please wait while the process finishes...</b></span>⏳"
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
      configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "There is not enough free space to perform this backup.\n\nYou need at least <span foreground='$purple'><b>$(numfmt --to=iec-i --suffix=B "$total_size")</b></span>.\nPlease free up some space and try again."
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
        configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "The backup to <span foreground='$purple'><b>$backup_file</b></span> was successful, final size is <span foreground='$purple'><b>$final_size</b></span>.\n\nThe backups have been rotated, keeping the last 3 of the <span foreground='$purple'><b>$backup_type</b></span> backup type."
        log i "Backup completed successfully: $backup_file (Size: $final_size)"
        log i "Older backups rotated, keeping latest 3 of type $backup_type"

        if [[ ! -s "$backup_log_file" ]]; then # If the backup log file is empty, meaning tar threw no errors
          rm -f "$backup_log_file"
        fi
      else
        configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "Something went wrong with the backup process. Please check the log <span foreground='$purple'><b>$backup_log_file</b></span> for more information."
        log i "Error: Backup failed"
        return 1
      fi
    ) |
    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️ 🗄️" \
            --text="Compressing files into backup.\n\n⏳<span foreground='$purple'><b>Please wait while the process finishes...</b></span>⏳"
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

make_name_pretty() {
  # This function will take an internal system name (like "gbc") and return a pretty version for user display ("Nintendo GameBoy Color")
  # If the name is nout found it only returns the short name such as "gbc"
  # USAGE: make_name_pretty "system name"

  local system_name="$1"

  # Use jq to parse the JSON and find the pretty name from the components component_manifest.json
  while IFS= read -r component_manifest; do
    if jq -e --arg system "$system_name" 'to_entries | any(.value.system == $system)' "$component_manifest" > /dev/null; then
      local pretty_name=$(jq -r --arg name "$system_name" '.system[$name].name // $name' "$features")
      echo "$pretty_name"
      break
    fi
  done < <(find "$rd_components" -maxdepth 2 -mindepth 2 -type f -name "component_manifest.json")
}

finit_browse() {
  # Function for choosing data directory location during first/forced init
  path_selected=false
  while [ $path_selected == false ]
  do
    local target="$(rd_zenity --file-selection --title="RetroDECK - 📂 retrodeck 📂 location" --directory)"
    if [[ ! -z "$target" ]]; then
      if [[ -w "$target" ]]; then
        rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" \
        --cancel-label="No" \
        --ok-label "Yes" \
        --text="Your RetroDECK main data folder location will be:\n\n<span foreground='$purple'><b>$target/retrodeck</b></span>\n\nIs this correct?"
        if [ $? == 0 ] #yes
        then
          path_selected=true
          echo "$target"
          break
        else
          rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No 🟥" --ok-label="Yes 🟢" --text="Do you want to quit?"
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

finit() {
  # Force/First init, depending on the situation

  log i "Executing finit"

  # Internal or SD Card?
  local finit_dest_choice=$(configurator_destination_choice_dialog "RetroDECK data" "<b>Welcome to RetroDECKs first-time setup!</b>\n\nRead each prompt carefully during installation so everything is configured correctly.\n\nChoose where RetroDECK should store its data.\n\nA data folder named <span foreground='$purple'><b>retrodeck</b></span> will be created at the location you choose.\n\nThis folder will hold all of your important files:\n\n<span foreground='$purple'><b>🕹️ ROMs and Games \n⚙️ BIOS and Firmware \n💾 Game Saves \n🖼️ Art Data \n🧺 Etc...</b></span>." )
  
  if [[ "$finit_dest_choice" == "" ]]; then
    log i "User closed the window"
  else
    log i "User choice: $finit_dest_choice"
  fi

  case "$finit_dest_choice" in

  "Quit" | "Back" | "" ) # Back, Quit or X button quits
    rm -f "$rd_conf" # Cleanup unfinished retrodeck.json if first install is interrupted
    log i "Now quitting"
    exit 2
  ;;

  "Internal Storage 🏠" | "Home Directory 🏠" ) # Internal
    log i "Internal selected"
    rd_home_path="$HOME/retrodeck"
    if [[ -L "$rd_home_path" ]]; then #Remove old symlink from existing install, if it exists
      unlink "$rd_home_path"
    fi
  ;;

  "SD Card 💾" )
    log i "SD Card selected"
    external_devices=()

    while read -r size device_path; do
      device_name=$(basename "$device_path")
      log d "External device $device_path found"
      external_devices=("${external_devices[@]}" "$device_name" "$size" "$device_path")
    done < <(df --output=size,target -h | grep "/run/media/" | awk '{$1=$1;print}')

    if [[ "${#external_devices[@]}" -gt 0 ]]; then # Some external storage detected
      configurator_generic_dialog "RetroDeck Installation - 💾 SD Card 💾" "One or more external storage devices have been detected.\n\nPlease select the device where you would like to create the <span foreground='$purple'><b>retrodeck</b></span> data folder."
      choice=$(rd_zenity --list --title="RetroDECK Configurator - ➡️ USB Migration Tool ➡️" --cancel-label="Back 🔙" \
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
      --text="No external drives were detected.\nPlease manually select the location of your SD card."
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
        --text="SD card detected, but it cannot be written to.\n\This often occurs when the card was formatted on a PC.\n\n\What to do:\n\n\Switch the Steam Deck to <span foreground='$purple'><b>Game Mode</b></span>.\n\Settings > System > Format SD Card\n\n\Run RetroDECK again.."
        rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
        log i "Now quitting"
        quit_retrodeck
    else
      rd_home_path="$sdcard/retrodeck"
    fi
  ;;

  "Custom Location" )
      log i "Custom Location selected"
      rd_zenity --info --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK" \
      --ok-label "Browse" \
      --text="Choose a location for the <span foreground='$purple'><b>retrodeck</b></span> data folder."
      sdcard="$(finit_browse)" # Calling the browse function
      rd_home_path="$sdcard/retrodeck"
      if [[ -z "$rd_home_path" ]]; then # If user hit the cancel button
        rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
        exit 2
      fi
    ;;

  esac

  log i "\"retrodeck\" folder will be located in \"$rd_home_path\""

  local finit_choices=()

  while read -r manifest_file; do
    if jq -e '.. | objects | select(has("finit_options")) | any' "$manifest_file" > /dev/null; then
      while read -r finit_array_obj; do
        local option_dialog=$(jq -r '.dialog' <<< "$finit_array_obj")
        local option_action=$(jq -r '.action' <<< "$finit_array_obj")

        if launch_command "$option_dialog"; then
          finit_choices+=("$option_action")
        fi
      done < <(jq -c '.[].finit_options.[]' "$manifest_file")
    else
      continue
    fi
  done < <({
            find "$rd_components" -maxdepth 2 -mindepth 2 -type f -name "component_manifest.json" | grep "^$rd_components/framework/component_manifest.json" || true
            find "$rd_components" -maxdepth 2 -mindepth 2 -type f -name "component_manifest.json" | grep -v "^$rd_components/framework/component_manifest.json" | sort
           })

  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK Initial Install - Start" \
  --text="RetroDECK is now going to install the required files.\nWhen the installation finishes, RetroDECK will launch automatically.\n\n⏳<span foreground='$purple'><b>This may take up to a minute or two</b></span>⏳\n\nPress <span foreground='$purple'><b>OK</b></span> to continue."

  (
  prepare_component "reset" "framework" # Parse the [paths] section of retrodeck.cfg and set the value of / create all needed folders
  conf_write # Write the new values to retrodeck.cfg
  prepare_component "reset" "all"
  update_component_presets
  deploy_helper_files

  if [[ -n "${finit_choices:-}" ]]; then # Process optional finit choices
    for choice in "${finit_choices[@]}"; do
      log d "Processing finit user choice $choice"
      launch_command "$choice"
    done
  fi

  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK: Installing 📀" \
    --text="RetroDECK is completing its initial setup.\n\n\Please check for any background <span foreground='$purple'><b>windows or pop-ups</b></span> that may require your attention.\n\n⏳ <span foreground='$purple'><b>Please wait while the setup process completes...</b></span> ⏳"

  create_lock

  # Inform the user where to put the ROMs and BIOS files
  rd_zenity --question --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --ok-label="Start RetroDECK 🎮" \
    --cancel-label="Return to Desktop 🖥️" \
    --title "RetroDECK Initial Setup - Complete ✅" \
    --text="RetroDECK initial setup is Complete! ✅\n\nEither <span foreground='$purple'><b>Start RetroDECK</b></span> 🎮 or <span foreground='$purple'><b>Return to Desktop</b></span> 🖥️.\n\nPlace your 🕹️ <span foreground='$purple'><b>Game Files</b></span> in the following directory:\n\n<span foreground='$purple'><b>$rd_home_path/roms\n\n</b></span> Your ⚙️ <span foreground='$purple'><b>BIOS and Firmware</b></span> files in:\n\n<span foreground='$purple'><b>$rd_home_path/bios</b></span>\n\nTIP: Check out the <span foreground='$purple'><b>RetroDECK Wiki and Website</b></span>\n\nThey contain detailed guides and tips on getting the most out of RetroDECK.\n\nHave a fantastic time!\n\n❤️ RetroDECK Team ❤️"

  local rc=$?
  if [[ $rc == "1" ]]; then
    quit_retrodeck
  fi
}

install_retrodeck_starterpack() {
  # This function will install the roms, gamelists and metadata for the RetroDECK Starter Pack, a curated selection of games the creators of RetroDECK enjoy.
  # USAGE: install_retrodeck_starterpack

  ## DOOM section ##
  cp /app/retrodeck/extras/doom1.wad "$roms_path/doom/doom1.wad" # No -f in case the user already has it
  create_dir "$XDG_CONFIG_HOME/ES-DE/gamelists/doom"
  if [[ ! -f "$XDG_CONFIG_HOME/ES-DE/gamelists/doom/gamelist.xml" ]]; then # Don't overwrite an existing gamelist
    cp "/app/retrodeck/rd_prepacks/doom/gamelist.xml" "$XDG_CONFIG_HOME/ES-DE/gamelists/doom/gamelist.xml"
  fi
  create_dir "$downloaded_media_path/doom"
  unzip -oq "/app/retrodeck/rd_prepacks/doom/doom.zip" -d "$downloaded_media_path/doom/"
}

install_retrodeck_controller_profile() {
  # This function will install the needed files for the custom RetroDECK controller profile
  # NOTE: These files need to be stored in shared locations for Steam, outside of the normal RetroDECK folders and should always be an optional user choice
  # BIGGER NOTE: As part of this process, all emulators will need to have their configs hard-reset to match the controller mappings of the profile
  # USAGE: install_retrodeck_controller_profile
  if [[ -d "$HOME/.steam/steam/controller_base/templates/" || -d "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" ]]; then
    if [[ -d "$HOME/.steam/steam/controller_base/templates/" ]]; then # If a normal binary Steam install exists
      rsync -rlD --mkpath "/app/retrodeck/binding_icons/" "$HOME/.steam/steam/tenfoot/resource/images/library/controller/binding_icons/"
      rsync -rlD --mkpath "$rd_core_files/controller_configs/" "$HOME/.steam/steam/controller_base/templates/"
    fi
    if [[ -d "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" ]]; then # If a Flatpak Steam install exists
      rsync -rlD --mkpath "/app/retrodeck/binding_icons/" "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/tenfoot/resource/images/library/controller/binding_icons/"
      rsync -rlD --mkpath "$rd_core_files/controller_configs/" "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/"
    fi
  else
    configurator_generic_dialog "RetroDECK - Install: 🎮 Steam Controller Templates 🎮" "The target directories for the controller profile do not exist.\n\nThis may occur if <span foreground='$purple'><b>Steam is not installed</b></span> or if the location does not have <span foreground='$purple'><b>read permissions</b></span>."
  fi
}

create_lock() {
  # creating RetroDECK's lock file and writing the version in the config file
  version=$hard_version
  log i "Creating RetroDECK lock file in $rd_lockfile"
  touch "$rd_lockfile"
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
      if [[ -d "$dest" ]]; then
        log d "Copying helper file $file to $current_dest"
        cp -f "$helper_files_path/$file" "$current_dest/$file"
      else
        log d "Helper file location $dest does not exist, component may not be installed. Skipping..."
      fi
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
          configurator_generic_dialog "Online Update - 🛑 Error: Archive 🛑" "Failed to download the Flatpak file: <span foreground='$purple'><b>RetroDECK update aborted.</b></span>\nPlease check your internet connection and try again."
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
          configurator_generic_dialog "Online Update - 🛑 Error: Archive 🛑" "Failed to extract the split archive: <span foreground='$purple'><b>RetroDECK update aborted.</b></span>"
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
        if [[ $(configurator_generic_question_dialog "SHA256 Mismatch" "The SHA256 checksum for $flatpak_name does not match.\nThe file may be corrupted or incomplete.\n\nDo you want to continue with the installation anyway?") != "true" ]]; then
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
    --text="RetroDECK is updating to the selected version.\n\n⏳<span foreground='$purple'><b>Please wait while the process finishes...</b></span>⏳"

  configurator_generic_dialog "RetroDECK - 🌐 Online Update 🌐" "<span foreground='$purple'><b>The update process is now complete!</b></span>\n\nRetroDECK will now quit."
  quit_retrodeck
}

# Don't remove this function as itś used in post update of 0.10.b to remove ponzu itself
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
    configurator_generic_dialog "Online Update - 🛑 Error: Main 🛑" "<span foreground='$purple'><b>Unable to fetch the main release.</b></span> Please check your internet connection or try again later."
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
    configurator_generic_dialog "Online Update - 🛑 Error: Releases 🛑" "<span foreground='$purple'><b>Unable to fetch releases.</b></span> Please check your internet connection or try again later."
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
    configurator_generic_dialog "RetroDECK - 🌐 Online Update 🌐" "<span foreground='$purple'><b>No available releases were found.</b></span> Exiting."
    log d "No available releases found"
    return 1
  fi

  log d "Showing available releases"

  # Display releases in a Zenity list dialog with three columns
  selected_release=$(
    rd_zenity --list \
      --icon-name=net.retrodeck.retrodeck \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - 🍲 RetroDECK Cooker: Select Release 🍲" \
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

  log d "Checking if PortMaster should be shown"
  if [[ $(get_setting_value "$rd_conf" "portmaster_show" "retrodeck" "options") == "false" ]]; then
    log d "Assuring that PortMaster is hidden on ES-DE"
    portmaster_show "false"
  else
    log d "Assuring that PortMaster is shown on ES-DE"
    portmaster_show "true"
  fi

  log i "Starting RetroDECK v$version"
  start_esde
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

open_component(){
  local command="$1"
  shift

  if [[ "$command" == "--list" ]]; then
    echo "Installed components:"
    echo "$(api_get_component "all" | jq -r '.[] | select(.component_name != "retrodeck") | .component_name')"
  else
    if [[ -f "$rd_components/$command/component_launcher.sh" ]]; then
      # Pass any additional arguments given to open_component on to the
      # component's launcher script so callers can forward flags/parameters.
      log d "Launching component '$command' with args: $@"
      /bin/bash "$rd_components/$command/component_launcher.sh" "$@"
    else
      log e "No launcher could be found for the component: $command"
    fi
  fi
}

add_retrodeck_to_steam() {
  (
    log i "RetroDECK has been added to Steam"
    rd_srm enable --names "RetroDECK Launcher"
    rd_srm add
  ) |
  rd_zenity --progress --no-cancel --pulsate --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - ⏳ Adding RetroDECK to Steam ⏳" \
    --text="RetroDECK is being added to Steam.\n\n⏳<span foreground='$purple'><b>Please wait while the process finishes...</b></span>⏳"
  rd_zenity --info --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --text="RetroDECK has been added to Steam.\n\n\<span foreground='$purple'><b>Please restart Steam to see the changes.</b></span>"
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
            configurator_generic_dialog "RetroDECK Configurator - 🔧 Path Repair 🔧" "The RetroDECK <span foreground='$purple'><b>$path_name</b></span> was not found in the expected location.\nThis may occur if the folder was moved manually.\n\nPlease browse to the current location of the <span foreground='$purple'><b>$path_name</b></span>."
            new_path=$(directory_browse "RetroDECK $path_name location")
            set_setting_value "$rd_conf" "$path_name" "$new_path" retrodeck "paths"
            invalid_path_found="true"
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
    conf_read
    dir_prep "$logs_path" "$rd_xdg_config_logs_path"
    prepare_component "postmove" "all"
    configurator_generic_dialog "RetroDECK Configurator - 🔧 Path Repair 🔧" "<span foreground='$purple'><b>One or more incorrectly configured paths were repaired.</b></span>"
  else
    log i "All folders were found at their expected locations"
    configurator_generic_dialog "RetroDECK Configurator - 🔧 Path Repair 🔧" "<span foreground='$purple'><b>All RetroDECK folders were found at their expected locations.</b></span>"
  fi
}

sanitize() {
    # Function to sanitize strings for filenames
    # Replace sequences of underscores with a single space
    echo "$1" | sed -e 's/_\{2,\}/ /g' -e 's/_/ /g' -e 's/:/ -/g' -e 's/&/and/g' -e 's%/%and%g' -e 's/  / /g'
}

check_if_updated() {
  # Check if an update has happened
  if [ -f "$rd_lockfile" ]; then
    if [ "$hard_version" != "$version" ]; then
      log d "Update triggered"
      log d "Lockfile found but the version doesn't match with the config file"
      log i "Config file's version is $version but the actual version is $hard_version"
      if grep -qF "cooker" <<< "$hard_version"; then # If newly-installed version is a "cooker" build
        log d "Newly-installed version is a \"cooker\" build"
        configurator_generic_dialog "RetroDECK - 🛑🍲 Warning: Cooker 🍲🛑" "<span foreground='$purple'><b>RUNNING COOKER VERSIONS OF RETRODECK CAN BE EXTREMELY DANGEROUS!</b></span>\n\nAll of your RetroDECK data is at risk, including:\n<span foreground='$purple'><b>• BIOS files</b></span>\n<span foreground='$purple'><b>• Borders</b></span>\n<span foreground='$purple'><b>• Downloaded media</b></span>\n<span foreground='$purple'><b>• Gamelists</b></span>\n<span foreground='$purple'><b>• Mods</b></span>\n<span foreground='$purple'><b>• ROMs</b></span>\n<span foreground='$purple'><b>• Saves</b></span>\n<span foreground='$purple'><b>• States</b></span>\n<span foreground='$purple'><b>• Screenshots</b></span>\n<span foreground='$purple'><b>• Texture packs</b></span>\n<span foreground='$purple'><b>• Themes</b></span>\n\n<span foreground='$purple'><b>Proceeding may result in loss or corruption of these files!</b></span>"
        set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
        set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
        set_setting_value "$rd_conf" "developer_options" "true" retrodeck "options"
        set_setting_value "$rd_conf" "rd_logging_level" "debug" retrodeck "options"
        cooker_base_version=$(echo "$version" | cut -d'-' -f2)
        choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Upgrade 🟢" --extra-button="Don't Upgrade 🟥" --extra-button="Delete Everything & Fresh Install ☢️" \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK - 🍲 RetroDECK Cooker: Upgrade 🍲" \
        --text="You are upgrading a cooker build of RetroDECK.\n\n Press the ✅ <span foreground='$purple'><b>Upgrade</b></span> button to perform a upgrade.\n\nPress the ❌ <span foreground='$purple'><b>Don't Upgrade</b></span> to skip the upgrade.\n\n🛑 Warning! 🛑\n\nPressing the ☢️ <span foreground='$purple'><b>Delete Everything & Fresh Install</b></span> ☢️ button deletes all data (including ROMs, BIOS, Saves and everything else stored in /retrodeck). Do not press it unless you know what you are doing!")
        rc=$? # Capture return code, as "Yes" button has no text value
        if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
          if [[ "$choice" =~ "Don't Upgrade" ]]; then # If user wants to bypass the post_update.sh process this time.
            log i "Skipping upgrade process for cooker build, updating stored version in retrodeck.cfg"
            set_setting_value "$rd_conf" "version" "$hard_version" retrodeck # Set version of currently running RetroDECK to updated retrodeck.cfg
          elif [[ "$choice" =~ "Delete Everything & Fresh Install" ]]; then # Remove all RetroDECK data and start a fresh install
            if [[ $(configurator_generic_question_dialog "RetroDECK Cooker: ☢️ Delete Everything & Fresh Install ☢️" "<span foreground='$purple'><b>This will delete ALL RetroDECK data!</b></span>\n\nAffected data includes:\n<span foreground='$purple'><b>• BIOS files</b></span>\n<span foreground='$purple'><b>• Borders</b></span>\n<span foreground='$purple'><b>• Media</b></span>\n<span foreground='$purple'><b>• Gamelists</b></span>\n<span foreground='$purple'><b>• Mods</b></span>\n<span foreground='$purple'><b>• ROMs</b></span>\n<span foreground='$purple'><b>• Saves</b></span>\n<span foreground='$purple'><b>• States</b></span>\n<span foreground='$purple'><b>• Screenshots</b></span>\n<span foreground='$purple'><b>• Texture packs</b></span>\n<span foreground='$purple'><b>• Themes</b></span>\n<span foreground='$purple'><b>• And more</b></span>\n\nAre you sure you want to continue?\n<span foreground='$purple'><b>Remember what happened last time!</b></span>") == "true" ]]; then
              if [[ $(configurator_generic_question_dialog "RetroDECK Cooker: ☢️ Delete Everything & Fresh Install ☢️: Reset 🍲" "<span foreground='$purple'><b>Are you absolutely sure?</b></span>\n\nThere is no going back from this process — everything will be permanently deleted.\n<span foreground='$purple'><b>Dust in the wind.</b></span>\n<span foreground='$purple'><b>Yesterday's omelette.</b></span>") == "true" ]]; then
                if [[ $(configurator_generic_question_dialog "RetroDECK Cooker: ☢️ Delete Everything & Fresh Install ☢️: Reset 🍲" "<span foreground='$purple'><b>But are you super DUPER sure?</b></span>\n\nWe REALLY want to make sure you understand what is about to happen.\n\nThe following folders and <b>ALL of their contents</b> will be <span foreground='$purple'><b>PERMANENTLY deleted like what happened to Rowan Skye!</b></span>:\n<span foreground='$purple'><b>• ~/retrodeck</b></span>\n<span foreground='$purple'><b>• ~/.var/app/net.retrodeck.retrodeck</b></span>\n\n<span foreground='$purple'><b>This is irreversible — proceed at your own risk!</b></span>") == "true" ]]; then
                  configurator_generic_dialog "RetroDECK Cooker: ☢️ Delete Everything & Fresh Install ☢️" "<span foreground='$purple'><b>Ok, if you're that sure, here we go!</b></span>"
                  if [[ $(configurator_generic_question_dialog "RetroDECK Cooker: ☢️ Delete Everything & Fresh Install ☢️" "<span foreground='$purple'><b>Are you actually being serious here?</b></span>\n\nBecause we are...\n\n<span foreground='$purple'><b>No backsies...OK?!</b></span>") == "true" ]]; then
                    log w "☢️ Deleting all RetroDECK Data & Fresh Install"
                    rm -rf /var
                    rm -rf "$HOME/retrodeck"
                    rm -rf "$rd_home_path"
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
          set_setting_value "$rd_conf" "rd_logging_level" "info" retrodeck "options"
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
  # This function will iterate the component_functions.sh file for every installed component and source it for use in the greater application
  # Specific component names can be specified, as well as the unique values of "retrodeck", "external" or "internal"
  # The "retrodeck" option will source only the RetroDECK component_functions.sh file, which is typically needed to be sourced before anything else on boot
  # The "internal" option will source components which are specifically internal to RetroDECK, such as SRM or ES-DE, but not RetroDECK itself
  # The "external" option will source everything else, excluding the RetroDECK and internal files for speed reasons
  # A specific component name will also be allowed, where the component_functions.sh file under $rd_components/<component name> will be sourced.
  # A fallback where all files are sourced when there is no component specified is also an option.

  local choice="$1"

  if [[ -n "$choice" ]]; then
    case "$choice" in

    "internal" )
      set -o allexport # Export all the variables found during sourcing, for use elsewhere
      source "$rd_components/es-de/component_functions.sh"
      log d "Sourcing $rd_components/es-de/component_functions.sh"
      source "$rd_components/steam-rom-manager/component_functions.sh"
      log d "Sourcing $rd_components/steam-rom-manager/component_functions.sh"
      set +o allexport # Back to normal, otherwise every assigned variable will get exported through the rest of the run
    ;;

    "external" )
      while IFS= read -r functions_file; do
        if [[ ! $(basename $(dirname $functions_file)) =~ ^(retrodeck|es-de|steam-rom-manager)$ ]]; then
          log d "Found component functions file $functions_file"
          set -o allexport # Export all the variables found during sourcing, for use elsewhere
          source "$functions_file"
          set +o allexport # Back to normal, otherwise every assigned variable will get exported through the rest of the run
        fi
      done < <(find "$rd_components" -maxdepth 2 -mindepth 2 -type f -name "component_functions.sh")
    ;;

    * )
      if [[ -n $(find "$rd_components/$choice" -maxdepth 1 -mindepth 1 -type f -name "component_functions.sh") ]]; then
        set -o allexport # Export all the variables found during sourcing, for use elsewhere
        log d "Sourcing $rd_components/$choice/component_functions.sh"
        source "$rd_components/$choice/component_functions.sh"
        set +o allexport # Back to normal, otherwise every assigned variable will get exported through the rest of the run
      else
        log e "component_functions.sh file for component $choice could not be found."
      fi
    ;;

    esac
  else
    while IFS= read -r functions_file; do
      log d "Found component functions file $functions_file"
      set -o allexport # Export all the variables found during sourcing, for use elsewhere
      source "$functions_file"
      set +o allexport # Back to normal, otherwise every assigned variable will get exported through the rest of the run
    done < <(find "$rd_components" -maxdepth 2 -mindepth 2 -type f -name "component_functions.sh")
  fi
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
          if ! jq -e --arg component "${component_name}_cores" --arg preset "$preset_name" '.presets[$preset] | has($component)' "$rd_conf" > /dev/null; then # If there is no wrapper for the parent component for this core
            log d "Wrapper for parent component \"$component_name\" in \"$preset_name\" not found, creating it."
            tmpfile=$(mktemp)
            jq --arg component "${component_name}_cores" --arg preset "$preset_name" '.presets[$preset] += { ($component): {} }' "$rd_conf" > "$tmpfile" && mv "$tmpfile" "$rd_conf"
          fi
          if jq -e --arg preset "$preset_name" --arg component "${component_name}_cores" --arg nest "$nested_object" '.presets[$preset][$component] | has($nest)' "$rd_conf" > /dev/null; then
            log d "The preset \"$preset_name\" already contains the component \"$component_name\" core \"$nested_object\". Skipping."
          else
            # Retrieve the first element of the array for the current preset name in the source file, which is the "disabled" state
            default_preset_value=$(jq -r --arg name "$component_name" --arg nest "$nested_object" --arg preset "$preset_name" '.[$name].compatible_presets[$nest][$preset][0]' "$manifest_file")
            log d "Adding component \"$component_name\" core \"$nested_object\" with default value '$default_preset_value' to preset \"$preset_name\"."
            tmpfile=$(mktemp)
            jq --arg preset "$preset_name" --arg component "${component_name}_cores" --arg nest "$nested_object" --arg value "$default_preset_value" \
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
  done < <(find "$rd_components" -maxdepth 2 -mindepth 2 -type f -name "component_manifest.json")
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

portmaster_show(){
  log d "Setting PortMaster visibility in ES-DE"
  if [ "$1" = "true" ]; then
    log d "\"$roms_path/portmaster/PortMaster.sh\" is not found, installing it"
    install -Dm755 "$XDG_DATA_HOME/PortMaster/PortMaster.sh" "$roms_path/portmaster/PortMaster.sh" && log d "PortMaster is correctly showing in ES-DE"
    set_setting_value "$rd_conf" "portmaster_show" "true" retrodeck "options"
  elif [ "$1" = "false" ]; then
    rm -rf "$roms_path/portmaster/PortMaster.sh" && log d "PortMaster is correctly hidden in ES-DE"
    set_setting_value "$rd_conf" "portmaster_show" "false" retrodeck "options"
  else
    log e "\"$1\" is not a valid choice, quitting"
  fi
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
      configurator_generic_dialog "RetroDeck Configurator - 🎨 Toggle Folder Iconsets 🎨" "The chosen <span foreground='$purple'><b>iconset</b></span> could not be found in the RetroDECK assets."
      return 1
    fi
  else
    while read -r path; do
      find -L "$path" -maxdepth 2 -type f -iname '.directory' -exec rm {} \;
    done < <(jq -r 'del(.paths.downloaded_media_path, .paths.themes_path, .paths.sdcard) | .paths[]' "$rd_conf")
    set_setting_value "$rd_conf" "iconset" "false" retrodeck "options"
  fi
}

install_retrodeck_controller_profile_and_add_to_steam() {
  install_retrodeck_controller_profile
  add_retrodeck_to_steam
  
  rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK Initial Install - 🚂 Steam Syncronization 🚂" --cancel-label="No 🟥" --ok-label "Yes 🟢" \
    --text="Enable Steam synchronization?\n\nThis will scan your games for any 🌟 <span foreground='$purple'><b>Favorited</b></span> 🌟 games in ES-DE and add them to your Steam library as individual entries.\n\nYou will need to restart Steam for the changes to take effect."

  if [[ $? == 0 ]]; then
    configurator_enable_steam_sync
  fi
}

finit_default_yes() {
  log i "Defaulting setting "$@" enabled."
  return 0
}
