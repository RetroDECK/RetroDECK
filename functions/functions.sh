#!/bin/bash

directory_browse() {
  # This function browses for a directory and returns the path chosen
  # USAGE: path_to_be_browsed_for=$(directory_browse $action_text)

  local path_selected=false

  while [ $path_selected == false ]
  do
    local target="$(zenity --file-selection --title="Choose $1" --directory)"
    if [ ! -z "$target" ] #yes
    then
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
      --text="Directory $target chosen, is this correct?"
      if [ $? == 0 ]
      then
        path_selected=true
        echo "$target"
        break
      fi
    else
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
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
    local target="$(zenity --file-selection --title="Choose $1")"
    if [ ! -z "$target" ] #yes
    then
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
      --text="File $target chosen, is this correct?"
      if [ $? == 0 ]
      then
        file_selected=true
        echo "$target"
        break
      fi
    else
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
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

  (
    rsync -a --remove-source-files --ignore-existing --mkpath "$source_dir" "$dest_dir" # Copy files but don't overwrite conflicts
    find "$source_dir" -type d -empty -delete # Cleanup empty folders that were left behind
  ) |
  zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - Move in Progress" \
  --text="Moving directory $(basename "$1") to new location of $2, please wait."

  if [[ -d "$source_dir" ]]; then # Some conflicting files remain
    zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility - Move Directories" \
    --text="There were some conflicting files that were not moved.\n\nAll files that could be moved are in the new location,\nany files that already existed at the new location have not been moved and will need to be handled manually."
  fi
}

download_file() {
  # Function to download file from the Internet, with Zenity progress bar
  # USAGE: download_file $source_url $file_dest $file_name
  # source_url is the location the file is downloaded from
  # file_dest is the destination the file should be in the filesystem, needs filename included!
  # file_name is a user-readable file name or description to be put in the Zenity dialog

  # Run wget in the background and redirect the progress to a temporary file
  (
    wget "$1" -O "$2" -q --show-progress --progress=dot 2>&1 | sed -n -e 's/^.* \([0-9]*\)%.*$/\1/p' > "/var/cache/tmp/download_progress" &
    wget_pid=$!

        progress="0"
        echo "$progress" # Initial progress value. sent to Zenity
        while true; do
            progress=$(tail -n 2 "/var/cache/tmp/download_progress" | head -1) # Read the second-to-last value written to the pipe, to avoid reading data that is half written
            echo "$progress" # Send value to Zenity
            if [[ "$(tail -n 1 "/var/cache/tmp/download_progress")" == "100" ]]; then # Read last line every time to check for download completion
                echo "100"
                break
            fi
            sleep 0.5
        done

    # Wait for wget process to finish
    wait "$wget_pid"
  ) |
  zenity --progress \
    --title="Downloading File" \
    --text="Downloading $3..." \
    --percentage=0 \
    --auto-close

  # Cleanup temp file
  rm -f "/var/cache/tmp/download_progress"
}

update_rd_conf() {
  # This function will import a default retrodeck.cfg file and update it with any current settings. This will allow us to expand the file over time while retaining current user settings.
  # USAGE: update_rd_conf

  # STAGE 1: For current files that haven't been broken into sections yet, where every setting name is unique

  conf_read # Read current settings into memory
  mv -f $rd_conf $rd_conf_backup # Backup config file before update
  cp $rd_defaults $rd_conf # Copy defaults file into place
  conf_write # Write old values into new default file

  # STAGE 2: To handle presets sections that use duplicate setting names

  mv -f $rd_conf $rd_conf_backup # Backup config file agiain before update but after Stage 1 expansion
  generate_single_patch $rd_defaults $rd_conf_backup $rd_update_patch retrodeck # Create a patch file for differences between defaults and current user settings
  sed -i '/change^^version/d' $rd_update_patch # Remove version line from temporary patch file
  deploy_single_patch $rd_defaults $rd_update_patch $rd_conf # Re-apply user settings to defaults file
  set_setting_value $rd_conf "version" "$hard_version" retrodeck # Set version of currently running RetroDECK to updated retrodeck.cfg
  rm -f $rd_update_patch # Cleanup temporary patch file
  conf_read # Read all settings into memory

  # STAGE 3: Eliminate any preset incompatibility with existing user settings and new defaults

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
            done < "$incompatible_presets_reference_list"
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
        local current_section=$(sed 's^[][]^^g' <<< $current_setting_line) # Remove brackets from section name
      else
        if [[ "$current_section" == "" || "$current_section" == "paths" || "$current_section" == "options" ]]; then
          local current_setting_name=$(get_setting_name "$current_setting_line" "retrodeck") # Read the variable name from the current line
          local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "$current_section") # Read the variables value from retrodeck.cfg
          declare -g "$current_setting_name=$current_setting_value" # Write the current setting name and value to memory
        fi
      fi
    fi
  done < $rd_conf
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
}

dir_prep() {
  # This script is creating a symlink preserving old folder contents and moving them in the new one

  # Call me with:
  # dir prep "real dir" "symlink location"
  real="$1"
  symlink="$2"

  echo -e "\n[DIR PREP]\nMoving $symlink in $real" #DEBUG

   # if the symlink dir is already a symlink, unlink it first, to prevent recursion
  if [ -L "$symlink" ];
  then
    echo "$symlink is already a symlink, unlinking to prevent recursives" #DEBUG
    unlink "$symlink"
  fi

  # if the dest dir exists we want to backup it
  if [ -d "$symlink" ];
  then
    echo "$symlink found" #DEBUG
    mv -f "$symlink" "$symlink.old"
  fi

  # if the real dir is already a symlink, unlink it first
  if [ -L "$real" ];
  then
    echo "$real is already a symlink, unlinking to prevent recursives" #DEBUG
    unlink "$real"
  fi

  # if the real dir doesn't exist we create it
  if [ ! -d "$real" ];
  then
    echo "$real not found, creating it" #DEBUG
    mkdir -pv "$real"
  fi

  # creating the symlink
  echo "linking $real in $symlink" #DEBUG
  mkdir -pv "$(dirname "$symlink")" # creating the full path except the last folder
  ln -svf "$real" "$symlink"

  # moving everything from the old folder to the new one, delete the old one
  if [ -d "$symlink.old" ];
  then
    echo "Moving the data from $symlink.old to $real" #DEBUG
    mv -f "$symlink.old"/{.[!.],}* "$real"
    echo "Removing $symlink.old" #DEBUG
    rm -rf "$symlink.old"
  fi

  echo -e "$symlink is now $real\n"
}

check_bios_files() {
  # This function validates all the BIOS files listed in the $bios_checklist and adds the results to an array called bios_checked_list which can be used elsewhere
  
  rm -f "$godot_bios_files_checked" # Godot data transfer temp files
  touch "$godot_bios_files_checked"

  while IFS="^" read -r bios_file bios_subdir bios_hash bios_system bios_desc
    do
      bios_file_found="No"
      bios_hash_matched="No"
      if [[ -f "$bios_folder/$bios_subdir$bios_file" ]]; then
        bios_file_found="Yes"
        if [[ $bios_hash == "Unknown" ]]; then
          bios_hash_matched="Unknown"
        elif [[ $(md5sum "$bios_folder/$bios_subdir$bios_file" | awk '{ print $1 }') == "$bios_hash" ]]; then
          bios_hash_matched="Yes"
        fi
      fi
      bios_checked_list=("${bios_checked_list[@]}" "$bios_file" "$bios_system" "$bios_file_found" "$bios_hash_matched" "$bios_desc")
      echo "$bios_file"^"$bios_system"^"$bios_file_found"^"$bios_hash_matched"^"$bios_desc" >> "$godot_bios_files_checked" # Godot data transfer temp file
  done < $bios_checklist
}

update_rpcs3_firmware() {
  mkdir -p "$roms_folder/ps3/tmp"
  chmod 777 "$roms_folder/ps3/tmp"
  download_file "$rpcs3_firmware" "$roms_folder/ps3/tmp/PS3UPDAT.PUP" "RPCS3 Firmware"
  rpcs3 --installfw "$roms_folder/ps3/tmp/PS3UPDAT.PUP"
  rm -rf "$roms_folder/ps3/tmp"
}

backup_retrodeck_userdata() {
  mkdir -p "$backups_folder"
  zip -rq9 "$backups_folder/$(date +"%0m%0d")_retrodeck_userdata.zip" "$saves_folder" "$states_folder" "$bios_folder" "$media_folder" "$themes_folder" "$logs_folder" "$screenshots_folder" "$mods_folder" "$texture_packs_folder" "$borders_folder" > $logs_folder/$(date +"%0m%0d")_backup_log.log
}

make_name_pretty() {
  # This function will take an internal system name (like "gbc") and return a pretty version for user display ("Nintendo GameBoy Color")
  # USAGE: make_name_pretty "system name"
  local system=$(grep "$1^" "$pretty_system_names_reference_list")
  IFS='^' read -r internal_name pretty_name < <(echo "$system")
  echo "$pretty_name"
}

finit_browse() {
# Function for choosing data directory location during first/forced init
path_selected=false
while [ $path_selected == false ]
do
  local target="$(zenity --file-selection --title="Choose RetroDECK data directory location" --directory)"
  if [[ ! -z "$target" ]]; then
    if [[ -w "$target" ]]; then
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" \
      --cancel-label="No" \
      --ok-label "Yes" \
      --text="Your RetroDECK data folder will be:\n\n$target/retrodeck\n\nis that ok?"
      if [ $? == 0 ] #yes
      then
        path_selected=true
        echo "$target/retrodeck"
        break
      else
        zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" --text="Do you want to quit?"
        if [ $? == 0 ] # yes, quit
        then
          quit_retrodeck
        fi
      fi
    fi
  else
    zenity --error --no-wrap \
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

  while IFS="^" read -r enabled option_name option_desc option_tag
  do
    finit_available_options=("${finit_available_options[@]}" "$enabled" "$option_name" "$option_desc" "$option_tag")
  done < $finit_options_list


  local choices=$(zenity \
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

  echo "Executing finit"

  # Internal or SD Card?
  local finit_dest_choice=$(configurator_destination_choice_dialog "RetroDECK data" "Welcome to the first configuration of RetroDECK.\nThe setup will be quick but please READ CAREFULLY each message in order to avoid misconfigurations.\n\nWhere do you want your RetroDECK data folder to be located?\n\nThis folder will contain all ROMs, BIOSs and scraped data." )
  echo "Choice is $finit_dest_choice"

  case "$finit_dest_choice" in

  "Back" | "" ) # Back or X button quits
    rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
    echo "Now quitting"
    quit_retrodeck
  ;;

  "Internal Storage" ) # Internal
    echo "Internal selected"
    rdhome="$HOME/retrodeck"
    if [[ -L "$rdhome" ]]; then #Remove old symlink from existing install, if it exists
      unlink "$rdhome"
    fi
  ;;

  "SD Card" )
    echo "SD Card selected"
    if [ ! -d "$sdcard" ] # SD Card path is not existing
    then
      echo "Error: SD card not found"
      zenity --error --no-wrap \
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
        echo "Error: SD card found but not writable"
        zenity --error --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK" \
        --ok-label "Quit" \
        --text="SD card was found but is not writable\nThis can happen with cards formatted on PC.\nPlease format the SD card through the Steam Deck's Game Mode and run RetroDECK again."
        rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
        echo "Now quitting"
        quit_retrodeck
    else
      rdhome="$sdcard/retrodeck"
    fi
  ;;

  "Custom Location" )
      echo "Custom Location selected"
      zenity --info --no-wrap \
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

  prepare_component "reset" "retrodeck" # Parse the [paths] section of retrodeck.cfg and set the value of / create all needed folders

  conf_write # Write the new values to retrodeck.cfg

  configurator_generic_dialog "RetroDECK Initial Setup" "The next dialog will be a list of optional actions to take during the initial setup.\n\nIf you choose to not do any of these now, they can be done later through the Configurator."
  local finit_options_choices=$(finit_user_options_dialog)

  if [[ "$finit_options_choices" =~ (rpcs3_firmware|Enable All) ]]; then # Additional information on the firmware install process, as the emulator needs to be manually closed
    configurator_generic_dialog "RPCS3 Firmware Install" "You have chosen to install the RPCS3 firmware during the RetroDECK first setup.\n\nThis process will take several minutes and requires network access.\n\nRPCS3 will be launched automatically at the end of the RetroDECK setup process.\nOnce the firmware is installed, please close the emulator to finish the process."
  fi

  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
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
  if [[ "$finit_options_choices" =~ (rd_controller_profile|Enable All) ]]; then
    install_retrodeck_controller_profile
  fi
  if [[ "$finit_options_choices" =~ (rd_prepacks|Enable All) ]]; then
    install_retrodeck_starterpack
  fi

  ) |
  zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Finishing Initialization" \
  --text="RetroDECK is finishing the initial setup process, please wait."

  create_lock
}

install_retrodeck_starterpack() {
  # This function will install the roms, gamelists and metadata for the RetroDECK Starter Pack, a curated selection of games the creators of RetroDECK enjoy.
  # USAGE: install_retrodeck_starterpack

  ## DOOM section ##
  cp /app/retrodeck/extras/doom1.wad "$roms_folder/doom/doom1.wad" # No -f in case the user already has it
  mkdir -p "/var/config/emulationstation/ES-DE/gamelists/doom"
  if [[ ! -f "/var/config/emulationstation/ES-DE/gamelists/doom/gamelist.xml" ]]; then # Don't overwrite an existing gamelist
    cp "/app/retrodeck/rd_prepacks/doom/gamelist.xml" "/var/config/emulationstation/ES-DE/gamelists/doom/gamelist.xml"
  fi
  mkdir -p "$media_folder/doom"
  unzip -oq "/app/retrodeck/rd_prepacks/doom/doom.zip" -d "$media_folder/doom/"
}

install_retrodeck_controller_profile() {
  # This function will install the needed files for the custom RetroDECK controller profile
  # NOTE: These files need to be stored in shared locations for Steam, outside of the normal RetroDECK folders and should always be an optional user choice
  # BIGGER NOTE: As part of this process, all emulators will need to have their configs hard-reset to match the controller mappings of the profile
  # USAGE: install_retrodeck_controller_profile
  if [[ -d "$HOME/.steam/steam/tenfoot/resource/images/library/controller/binding_icons/" && -d "$HOME/.steam/steam/controller_base/templates/" ]]; then
    rsync -rlD --mkpath "/app/retrodeck/binding_icons/" "$HOME/.steam/steam/tenfoot/resource/images/library/controller/binding_icons/"
    rsync -rlD --mkpath "$emuconfigs/defaults/retrodeck/controller_configs/" "$HOME/.steam/steam/controller_base/templates/"
    # TODO: delete older files Issue#672
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

  rm -rf /var/config/emulationstation/ES-DE/resources/graphics
  rsync -rlD --mkpath "/app/retrodeck/graphics/" "/var/config/emulationstation/ES-DE/resources/graphics/"
}

deploy_helper_files() {
  # This script will distribute helper documentation files throughout the filesystem according to the $helper_files_list
  # USAGE: deploy_helper_files

  while IFS='^' read -r file dest
  do
      if [[ ! "$file" == "#"* ]] && [[ ! -z "$file" ]]; then
      eval current_dest="$dest"
      cp -f "$helper_files_folder/$file" "$current_dest/$file"
    fi

  done < "$helper_files_list"
}

easter_eggs() {
  # This function will replace the RetroDECK startup splash screen with a different image if the day and time match a listing in easter_egg_checklist.cfg
  # The easter_egg_checklist.cfg file has the current format: $start_date^$end_date^$start_time^$end_time^$splash_file
  # Ex. The line "1001^1031^0000^2359^spooky.svg" would show the file "spooky.svg" during any time of day in the month of October
  # The easter_egg_checklist.cfg is read in order, so lines higher in the file will have higher priority in the event of an overlap
  # USAGE: easter_eggs
  current_day=$(date +"%0m%0d") # Read the current date in a format that can be calculated in ranges
  current_time=$(date +"%0H%0M") # Read the current time in a format that can be calculated in ranges
  if [[ ! -z $(cat $easter_egg_checklist) ]]; then
    while IFS="^" read -r start_date end_date start_time end_time splash_file # Read Easter Egg checklist file and separate values
    do
      if [[ "$((10#$current_day))" -ge "$((10#$start_date))" && "$((10#$current_day))" -le "$((10#$end_date))" && "$((10#$current_time))" -ge "$((10#$start_time))" && "$((10#$current_time))" -le "$((10#$end_time))" ]]; then # If current line specified date/time matches current date/time, set $splash_file to be deployed
        new_splash_file="$splashscreen_dir/$splash_file"
        break
      else # When there are no matches, the default splash screen is set to deploy
        new_splash_file="$default_splash_file"
      fi
    done < $easter_egg_checklist
  else
    new_splash_file="$default_splash_file"
  fi

  cp -f "$new_splash_file" "$current_splash_file" # Deploy assigned splash screen
}

install_release() {
  # TODO logging - add some logging here
  # Pass me a vaild GitHub tag and I will update to that version, I will use the update_repo variable to determine the repo

  local flatpak_url="https://github.com/XargonWan/$update_repo/releases/download/$1/$update_repo.flatpak"

  zenity --question --icon-name=net.retrodeck.retrodeck --no-wrap \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK Updater" \
          --text="The chosen version will be now intalled, after the update process RetroDECK will quit, do you want to continue?"
  rc=$? # Capture return code
  if [[ $rc == "1" ]]; then # If any button other than "OK" was clicked
    return 0
  fi

  configurator_generic_dialog "RetroDECK Online Update" "The update process may take several minutes.\n\nAfter the update is complete, RetroDECK will close. When you run it again you will be using the latest version."
  (
  mkdir -p "/tmp/RetroDECK_Updates"
  wget -P "/tmp/RetroDECK_Updates" $flatpak_url -O "/tmp/RetroDECK_Updates/$update_repo.flatpak"
  flatpak-spawn --host flatpak remove --noninteractive -y net.retrodeck.retrodeck # Remove current version before installing new one, to avoid duplicates
  flatpak-spawn --host flatpak install --user --bundle --noninteractive -y "/tmp/RetroDECK_Updates/$update_repo.flatpak"
  rm -rf "/tmp/RetroDECK_Updates" # Cleanup old bundles to save space
  ) |
  zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Updater" \
  --text="RetroDECK is updating to the selected version, please wait."

  configurator_generic_dialog "RetroDECK Online Update" "The update process is now complete!\n\nRetroDECK will now quit."
  quit_retrodeck
}

# TODO: this function is not yet used
branch_selector() {
    # Fetch branches from GitHub API excluding "main"
    local branches=$(curl -s https://api.github.com/repos/XargonWan/RetroDECK/branches | grep '"name":' | awk -F '"' '$4 != "main" {print $4}')
    # TODO: logging - Fetching branches from GitHub API

    # Create an array to store branch names
    local branch_array=()

    # Loop through each branch and add it to the array
    while IFS= read -r branch; do
        branch_array+=("$branch")
    done <<< "$branches"
    # TODO: logging - Creating array of branch names

    # Display branches in a Zenity list dialog
    local selected_branch=$(
      zenity --list \
        --icon-name=net.retrodeck.retrodeck \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Configurator Cooker Branch - Select Branch" \
        --column="Branch" --width=1280 --height=800 "${branch_array[@]}"
    )
    # TODO: logging - Displaying branches in Zenity list dialog

    # If no branch is selected, quit the function
    if [ -z "$selected_branch" ]; then
        # TODO: logging
        return 1
    fi

    # Display warning message
    zenity --question --icon-name=net.retrodeck.retrodeck --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Cooker Branch - Switch Branch" \
      --text="Are you sure you want to move to \"$selected_branch\" branch?"
    # Output selected branch
    echo "Selected branch: $selected_branch" # TODO: logging - Outputting selected branch
    set_setting_value "$rd_conf" "branch" "$selected_branch" "retrodeck" "options"

    # Get the latest release for the specified branch
    local latest_release=$(curl -s "https://api.github.com/repos/XargonWan/$update_repo/releases" | jq -r --arg bn "$branch_name" 'sort_by(.published_at) | .[] | select(.tag_name | contains($bn)) | .tag_name' | tail -n 1)
    
    zenity --question --icon-name=net.retrodeck.retrodeck --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Cooker Branch - Switch Branch" \
      --text="Do you want to download and install the release \"$latest_release\"?"

    # Check user's choice
    if [[ $? -eq 0 ]]; then
        # User clicked Yes
        install_release $latest_release
    else
        return 0
    fi
}

quit_retrodeck() {
  pkill -f retrodeck
  pkill -f emulationstation
}

start_retrodeck() {
  easter_eggs # Check if today has a surprise splashscreen and load it if so
  # normal startup
  echo "Starting RetroDECK v$version"
  emulationstation --home /var/config/emulationstation
}
