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

  source_dir="$(echo $1 | sed 's![^/]$!&/!')" # Add trailing slash if it is missing
  dest_dir="$(echo $2 | sed 's![^/]$!&/!')" # Add trailing slash if it is missing

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

update_rd_conf() {
  # This function will import a default retrodeck.cfg file and update it with any current settings. This will allow us to expand the file over time while retaining current user settings.
  # USAGE: update_rd_conf

  # STAGE 1: For current files that haven't been broken into sections yet, where every setting name is unique

  conf_read # Read current settings into memory
  mv -f $rd_conf $rd_conf_backup # Backup config file before update
  cp $rd_defaults $rd_conf # Copy defaults file into place
  conf_write # Write old values into new retrodeck.cfg file

  # STAGE 2: To handle presets sections that use duplicate setting names

  generate_single_patch $rd_defaults $rd_conf_backup $rd_update_patch retrodeck # Create a patch file for differences between defaults and current user settings
  sed -i '/change^^version/d' $rd_update_patch # Remove version line from temporary patch file
  deploy_single_patch $rd_defaults $rd_update_patch $rd_conf # Re-apply user settings to defaults file
  set_setting_value $rd_conf "version" "$hard_version" retrodeck # Set version of currently running RetroDECK to updated retrodeck.cfg
  rm -f $rd_update_patch # Cleanup temporary patch file
  conf_read # Read all settings into memory

  # STAGE 3: Create new folders that were added to the shipped retrodeck.cfg, if any

  new_paths=$(awk -F= 'FNR==NR {keys[$1]=1; next} !($1 in keys)' \
  <(grep -v '^\s*$' "$rd_conf_backup" | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f') \
  <(grep -v '^\s*$' "$rd_conf" | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f'))

  if [[ -n "$new_paths" ]]; then
    log i "New paths found in RetroDECK config: \n $new_paths"
    if [[ ! "$rdhome" == "/home/deck/retrodeck" ]]; then # If rdhome is not the normal internal path, set new folders to rdhome as their root
      while read -r config_line; do
        local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
        local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
        local relative_path="${current_setting_value#*retrodeck/}"
        local new_setting_value="$rdhome/$relative_path"
        set_setting_value "$rd_conf" "$current_setting_name" "$new_setting_value" "retrodeck" "paths"
        create_dir "$new_setting_value"
      done <<< "$new_paths"
    else # rdhome is default internal location, so imported new paths are valid
      while read -r config_line; do
        local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
        local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
        create_dir "$current_setting_value"
      done <<< "$new_paths"
    fi
    conf_read
  fi

  # STAGE 4: Eliminate any preset incompatibility with existing user settings and new defaults

  # Fetch incompatible presets from JSON and create a lookup list
  incompatible_presets=$(jq -r '
    .incompatible_presets | to_entries[] |
    [
      "\(.key):\(.value)",
      "\(.value):\(.key)"
    ] | join("\n")
  ' $features)

  while IFS= read -r current_setting_line # Read the existing retrodeck.cfg
  do
    if [[ (! -z "$current_setting_line") && (! "$current_setting_line" == "#"*) && (! "$current_setting_line" == "[]") ]]; then # If the line has a valid entry in it
      if [[ ! -z $(grep -o -P "^\[.+?\]$" <<< "$current_setting_line") ]]; then # If the line is a section header
        local current_section=$(sed 's^[][]^^g' <<< $current_setting_line) # Remove brackets from section name
      else
        if [[ ! ("$current_section" == "" || "$current_section" == "paths" || "$current_section" == "options" || "$current_section" == "cheevos" || "$current_section" == "cheevos_hardcore") ]]; then
          local system_name=$(get_setting_name "$current_setting_line" "retrodeck") # Read the variable name from the current line
          local system_enabled=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$current_section") # Read the variables value from active retrodeck.cfg
          local default_setting=$(get_setting_value "$rd_defaults" "$system_name" "retrodeck" "$current_section") # Read the variable value from the retrodeck defaults
          if [[ "$system_enabled" == "true" ]]; then
            while IFS=: read -r preset_being_checked known_incompatible_preset; do
              if [[ "$current_section" == "$preset_being_checked" ]]; then
                if [[ $(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$known_incompatible_preset") == "true" ]]; then
                  set_setting_value "$rd_conf" "$system_name" "false" "retrodeck" "$current_section"
                fi
              fi
            done <<< "$incompatible_presets"
          fi
        fi
      fi
    fi
  done < $rd_conf
}

conf_read() {
  # This function will read the RetroDECK config file into memory
  # USAGE: conf_read

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
}

conf_write() {
  # This function will update the RetroDECK config file with matching variables from memory
  # USAGE: conf_write

  while IFS= read -r current_setting_line # Read the existing retrodeck.cfg
  do
    if [[ (! -z "$current_setting_line") && (! "$current_setting_line" == "#"*) && (! "$current_setting_line" == "[]") ]]; then # If the line has a valid entry in it
      if [[ ! -z $(grep -o -P "^\[.+?\]$" <<< "$current_setting_line") ]]; then # If the line is a section header
        local current_section=$(sed 's^[][]^^g' <<< $current_setting_line) # Remove brackets from section name
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
  done < $rd_conf
  log d "retrodeck.cfg written"
}

dir_prep() {
  # This script is creating a symlink preserving old folder contents and moving them in the new one

  # Call me with:
  # dir prep "real dir" "symlink location"
  real="$(realpath -s $1)"
  symlink="$(realpath -s $2)"

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

rd_zenity() {
  # This function replaces the standard 'zenity' command and filters out annoying GTK errors on Steam Deck
  export CONFIGURATOR_GUI="zenity"

  # env GDK_SCALE=1.5 \
  #     GDK_DPI_SCALE=1.5 \
  zenity 2> >(grep -v 'Gtk' >&2) "$@"

  local status=${PIPESTATUS[0]}  # Capture the exit code of 'zenity'

  unset CONFIGURATOR_GUI
  
  return $status
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
  create_dir "$backups_folder"
  zip -rq9 "$backups_folder/$(date +"%0m%0d")_retrodeck_userdata.zip" "$saves_folder" "$states_folder" "$bios_folder" "$media_folder" "$themes_folder" "$rdhome/ES-DE/collections" "$rdhome/ES-DE/gamelists" "$logs_folder" "$screenshots_folder" "$mods_folder" "$texture_packs_folder" "$borders_folder" > $logs_folder/$(date +"%0m%0d")_backup_log.log
}

make_name_pretty() {
  # This function will take an internal system name (like "gbc") and return a pretty version for user display ("Nintendo GameBoy Color")
  # If the name is nout found it only returns the short name such as "gbc"
  # USAGE: make_name_pretty "system name"

  local system_name="$1"

  # Use jq to parse the JSON and find the pretty name
  local pretty_name=$(jq -r --arg name "$system_name" '.system[$name].name // $name' "$features")

  echo "$pretty_name"
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
        echo "$target/retrodeck"
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
    if [ ! -d "$sdcard" ] # SD Card path is not existing
    then
      log e "SD card not found"
      rd_zenity --error --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK" \
      --ok-label "Browse" \
      --text="SD Card was not found in the default location.\nPlease choose the SD Card root.\nA retrodeck folder will be created starting from the directory that you selected."
      rdhome="$(finit_browse)" # Calling the browse function
      if [[ -z "$rdhome" ]]; then # If user hit the cancel button
        rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
        exit 2
      fi
    elif [ ! -w "$sdcard" ] #SD card found but not writable
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
      rdhome="$(finit_browse)" # Calling the browse function
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
  create_dir "/var/config/ES-DE/gamelists/doom"
  if [[ ! -f "/var/config/ES-DE/gamelists/doom/gamelist.xml" ]]; then # Don't overwrite an existing gamelist
    cp "/app/retrodeck/rd_prepacks/doom/gamelist.xml" "/var/config/ES-DE/gamelists/doom/gamelist.xml"
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

  rm -rf /var/config/ES-DE/resources/graphics
  rsync -rlD --mkpath "/app/retrodeck/graphics/" "/var/config/ES-DE/resources/graphics/"

}

deploy_helper_files() {
  # This script will distribute helper documentation files throughout the filesystem according to the JSON configuration
  # USAGE: deploy_helper_files

  # Extract helper files information using jq
  helper_files=$(jq -r '.helper_files | to_entries | map("\(.value.filename)^\(.value.location)")[]' "$features")

  # Iterate through each helper file entry
  while IFS='^' read -r file dest; do
    if [[ ! -z "$file" ]] && [[ ! -z "$dest" ]]; then
      eval current_dest="$dest"
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
    ) | .value.filename' $features)

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
    wget -P "$rdhome/RetroDECK_Updates" $flatpak_url -O "$rdhome/RetroDECK_Updates/RetroDECK$iscooker.flatpak"
    
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
  if [ -f "/var/data/ponzu/Citra/bin/citra-qt" ]; then
    log d "Citra binaries has already been installed, checking for updates and forcing the setting as true."
    set_setting_value $rd_conf "akai_ponzu" "true" retrodeck "options"
  fi
  if [ -f "/var/data/ponzu/Yuzu/bin/yuzu" ]; then
    log d "Yuzu binaries has already been installed, checking for updates and forcing the setting as true."
    set_setting_value $rd_conf "kiroi_ponzu" "true" retrodeck "options"
  fi

  # Loop through all ponzu files
  for ponzu_file in "${ponzu_files[@]}"; do
    # Check if the current ponzu file exists
    if [ -f "$ponzu_file" ]; then
      if [[ "$ponzu_file" == *itra* ]]; then
        log i "Found akai ponzu! Elaborating it"
        data_dir="/var/data/ponzu/Citra"
        local message="Akai ponzu is served, enjoy"
      elif [[ "$ponzu_file" == *uzu* ]]; then
        log i "Found kiroi ponzu! Elaborating it"
        data_dir="/var/data/ponzu/Yuzu"
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
        set_setting_value $rd_conf "akai_ponzu" "true" retrodeck "options"
      elif [[ "$ponzu_file" == *uzu* ]]; then
        mv "$tmp_folder/usr/"** .
        executable="$data_dir/bin/yuzu"
        log d "Making $executable executable"
        chmod +x "$executable"
        prepare_component "reset" "yuzu"
        set_setting_value $rd_conf "kiroi_ponzu" "true" retrodeck "options"
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
      rm -rf "/var/data/ponzu/Citra"
      set_setting_value $rd_conf "akai_ponzu" "false" retrodeck "options"
      configurator_generic_dialog "Ponzu - Remove Citra" "Done, Citra is now removed from RetroDECK"
    fi
  elif [[ "$1" == "yuzu" ]]; then
    if [[ $(configurator_generic_question_dialog "Ponzu - Remove Yuzu" "Do you really want to remove Yuzu binaries?\n\nYour games and saves will not be deleted.") == "true" ]]; then
      log i "Ponzu: removing Yuzu"
      rm -rf "/var/data/ponzu/Yuzu"
      set_setting_value $rd_conf "kiroi_ponzu" "false" retrodeck "options"
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
    local main_release=$(curl -s https://api.github.com/repos/$git_organization_name/RetroDECK/releases/latest)

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
    local releases=$(curl -s https://api.github.com/repos/$git_organization_name/$cooker_repository_name/releases?per_page=100)

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
        set_setting_value $rd_conf "update_repo" "$main_repository_name" retrodeck "options"
        log i "Switching to main channel"
      else
        set_setting_value $rd_conf "update_repo" "$cooker_repository_name" retrodeck "options"
        log i "Switching to cooker channel"
      fi

        set_setting_value "$rd_conf" "branch" "$selected_branch" "retrodeck" "options"
        log d "Set branch to $selected_branch in configuration"
        install_release $selected_tag

    else
      log d "User canceled installation"
      return 0
    fi
}

quit_retrodeck() {
  log i "Quitting ES-DE"
  pkill -f "es-de"

  # if steam sync is on do the magic
  if [[ $(get_setting_value "$rd_conf" "steam_sync" retrodeck "options") == "true" ]]; then
  (
  source /app/libexec/steam_sync.sh
  add_to_steam "$(ls "$rdhome/ES-DE/gamelists/")"
  ) |
  rd_zenity --progress \
    --title="Syncing with Steam" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="<span foreground='$purple'><b>\t\t\t\tSyncing favorite games with Steam</b></span>\n\n<b>NOTE: </b>This operation may take some time depending on the size of your library.\nFeel free to leave this in the background and switch to another application.\n\n" \
    --percentage=25 \
    --pulsate \
    --width=500 \
    --height=150 \
    --auto-close \
    --auto-kill \
    --no-cancel
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

# Function to convert XML tags to Markdown
convert_to_markdown() {
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

# This function updates RetroArch by synchronizing shaders, cores, and border overlays.
# It should be called whenever RetroArch is reset or updated.
retroarch_updater(){

  log i "Running RetroArch updater"
  
  # Synchronize cores from the application share directory to the RetroArch cores directory
  rsync -rlD --mkpath "/app/share/libretro/cores/" "/var/config/retroarch/cores/" && log d "RetroArch cores updated correctly"
  
  # Synchronize border overlays from the RetroDeck configuration directory to the RetroArch overlays directory
  rsync -rlD --mkpath "/app/retrodeck/config/retroarch/borders/" "/var/config/retroarch/overlays/borders/" && log d "RetroArch overlays and borders updated correctly"
}

portmaster_show(){
  log d "Setting PortMaster visibility in ES-DE"
  if [ "$1" = "true" ]; then
      log d "\"$roms_folder/portmaster/PortMaster.sh\" is not found, installing it"
      install -Dm755 "/var/data/PortMaster/PortMaster.sh" "$roms_folder/portmaster/PortMaster.sh" && log d "PortMaster is correctly showing in ES-DE"
      set_setting_value $rd_conf "portmaster_show" "true" retrodeck "options"
  elif [ "$1" = "false" ]; then
    rm -rf "$roms_folder/portmaster/PortMaster.sh" && log d "PortMaster is correctly hidden in ES-DE"
    set_setting_value $rd_conf "portmaster_show" "false" retrodeck "options"
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

    log i "Adding RetroDECK to Steam"

    rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
  --text="Do you want to add RetroDECK to Steam?"
    if [ $? == 0 ]; then
      (
        steam-rom-manager enable --names "RetroDECK Launcher"
        steam-rom-manager add
      ) |
      rd_zenity --progress --no-cancel --pulsate --auto-close \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "Adding RetroDECK to Steam" \
        --text="Please wait while RetroDECK is being added to Steam...\n\n"
      rd_zenity --info --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --text="RetroDECK has been added to Steam.\n\nPlease close and reopen Steam to see the changes."
    fi

    log i "RetroDECK has been added to Steam"
}
