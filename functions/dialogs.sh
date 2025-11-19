#!/bin/bash

# Dialog colors
purple="#a864fc"
blue="#6fbfff"

debug_dialog() {
  # This function is for displaying commands run by the Configurator without actually running them
  # USAGE: debug_dialog "command"
  log i "Debug dialog for: $1" # showing the command in the logs
  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - Debug Dialog" \
  --text="$1"
}

configurator_process_complete_dialog() {
  # This dialog shows when a process is complete.
  # USAGE: configurator_process_complete_dialog "process text"
  log i "Process complete dialog for: $1" # showing the process in the logs
  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Quit" --extra-button="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - Process Complete" \
  --text="The process of $1 is now complete.\n\nYou may need to restart RetroDECK for the changes to take effect.\n\nClick OK to return to the Main Menu or Quit to exit RetroDECK."

  if [ ! $? == 0 ]; then # OK button clicked
      configurator_welcome_dialog
  elif [ ! $? == 1 ]; then # Quit button clicked
      quit_retrodeck
  fi
}

configurator_generic_dialog() {
  # This dialog is for showing temporary messages before another process happens.
  # USAGE: configurator_generic_dialog "title text" "info text"
  log i "$2" # showing the message in the logs
  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "$1" \
  --text="$2"
}

configurator_generic_question_dialog() {
  # This dialog provides a generic dialog for getting a response from a user.
  # USAGE: $(configurator_generic_question_dialog "title text" "action text")
  # This function will return a "true" if the user clicks "Yes", and "false" if they click "No".
  log i "$2"
  choice=$(rd_zenity --title "RetroDECK - $1" --question --no-wrap --cancel-label="No" --ok-label="Yes" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="$2")
  if [[ $? == "0" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

configurator_destination_choice_dialog() {
  # This dialog is for making things easy for new users to move files to common locations. Gives the options for "Internal", "SD Card" and "Custom" locations.
  # USAGE: $(configurator_destination_choice_dialog "folder being moved" "action text")
  # This function returns one of the values: "Back" "Internal Storage" "SD Card" "Custom Location"
  log i "$2"
  choice=$(rd_zenity --title "RetroDECK Configurator Utility - Moving $1 folder" --info --no-wrap --ok-label="Quit" --extra-button="Internal Storage" --extra-button="SD Card" --extra-button="Custom Location" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="$2")

  local rc=$?
  if [[ $rc == "0" ]] && [[ -z "$choice" ]]; then
    echo "Back"
  else
    echo "$choice"
  fi
}

configurator_reset_confirmation_dialog() {
  # This dialog provides a confirmation for any reset functions, before the reset is actually performed.
  # USAGE: $(configurator_reset_confirmation_dialog "emulator being reset" "action text")
  # This function will return a "true" if the user clicks Confirm, and "false" if they click Cancel.
  log i "$2"
  choice=$(rd_zenity --title "RetroDECK Configurator Utility - Reset $1" --question --no-wrap --cancel-label="Cancel" --ok-label="Confirm" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="$2")
  if [[ $? == "0" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

configurator_move_folder_dialog() {
  # This dialog will take a folder variable name from retrodeck.cfg and move it to a new location. The variable will be updated in retrodeck.cfg as well as any emulator configs where it occurs.
  # USAGE: configurator_move_folder_dialog "folder_variable_name"
  log i "Showing a configurator_move_folder_dialog for $1"
  local rd_dir_name="$1" # The folder variable name from retrodeck.cfg
  local dir_to_move="$(get_setting_value "$rd_conf" "$rd_dir_name" "retrodeck" "paths")/" # The path of that folder variable
  local source_root="$(echo "$dir_to_move" | sed -e 's/\(.*\)\/retrodeck\/.*/\1/')" # The root path of the folder, excluding retrodeck/<folder name>. So /home/deck/retrodeck/roms becomes /home/deck
  if [[ ! "$rd_dir_name" == "rd_home_path" ]]; then # If a sub-folder is being moved, find it's path without the source_root. So /home/deck/retrodeck/roms becomes retrodeck/roms
    local rd_dir_path="$(echo "$dir_to_move" | sed "s/.*\(retrodeck\/.*\)/\1/; s/\/$//")"
  else # Otherwise just set the retrodeck root folder
    local rd_dir_path="$(basename "$dir_to_move")"
  fi

  if [[ -d "$dir_to_move" ]]; then # If the directory selected to move already exists at the expected location pulled from retrodeck.cfg
    choice=$(configurator_destination_choice_dialog "RetroDECK Data" "Please choose a destination for the $(basename "$dir_to_move") folder.")
    case $choice in

    "Internal Storage" | "SD Card" | "Custom Location" ) # If the user picks a location
      if [[ "$choice" == "Internal Storage" ]]; then # If the user wants to move the folder to internal storage, set the destination target as HOME
        local dest_root="$HOME"
      elif [[ "$choice" == "SD Card" ]]; then # If the user wants to move the folder to the predefined SD card location, set the target as sdcard from retrodeck.cfg
        local dest_root="$sdcard"
      else
        configurator_generic_dialog "RetroDECK Configurator - Move Folder" "Select the parent folder you would like to store the $(basename "$dir_to_move") folder in."
        local dest_root=$(directory_browse "RetroDECK directory location") # Set the destination root as the selected custom location
      fi

      if [[ (! -z "$dest_root") && ( -w "$dest_root") ]]; then # If user picked a destination and it is writable
        if [[ (-d "$dest_root/$rd_dir_path") && (! -L "$dest_root/$rd_dir_path") && (! $rd_dir_name == "rd_home_path") ]] || [[ "$(realpath "$dir_to_move")" == "$dest_root/$rd_dir_path" ]]; then # If the user is trying to move the folder to where it already is (excluding symlinks that will be unlinked)
          configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The $(basename "$dir_to_move") folder is already at that location, please pick a new one."
          configurator_move_folder_dialog "$rd_dir_name"
        else
          if [[ $(verify_space "$(echo "$dir_to_move" | sed 's/\/$//')" "$dest_root") ]]; then # Make sure there is enough space at the destination
            configurator_generic_dialog "RetroDECK Configurator - Move Folder" "Moving $(basename "$dir_to_move") folder to $choice"
            unlink "$dest_root/$rd_dir_path" # In case there is already a symlink at the picked destination
            move "$dir_to_move" "$dest_root/$rd_dir_path"
            if [[ -d "$dest_root/$rd_dir_path" ]]; then # If the move succeeded
              declare -g "$rd_dir_name=$dest_root/$rd_dir_path" # Set the new path for that folder variable in retrodeck.cfg
              if [[ "$rd_dir_name" == "rd_home_path" ]]; then # If the whole retrodeck folder was moved...
                prepare_component "postmove" "framework"
              fi
              prepare_component "postmove" "all" # Update all the appropriate emulator path settings
              conf_write # Write the settings to retrodeck.cfg
              if [[ -z $(ls -1 "$source_root/retrodeck") ]]; then # Cleanup empty old_path/retrodeck folder if it was left behind
                rmdir "$source_root/retrodeck"
              fi
              configurator_generic_dialog "RetroDECK Configurator - Move Folder" "moving the RetroDECK data directory to internal storage"
            else
              configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The moving process was not completed, please try again."
            fi
          else # If there isn't enough space in the picked destination
            rd_zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - Move Directories" \
            --text="The destination you selected does not have enough free space for the files you are trying to move.\n\nPlease choose a new destination or free up some space."
          fi
        fi
      else # If the user didn't pick any custom destination, or the destination picked is unwritable
        if [[ ! -z "$dest_root" ]]; then
          configurator_generic_dialog "RetroDECK Configurator - Move Folder" "No destination was chosen, so no files have been moved."
        else
          configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The chosen destination is not writable.\nNo files have been moved.\n\nThis can happen if RetroDECK does not have permission to write to the selected location.\nYou can usually fix this by adding the desired path to RetroDECK permissions using Flatseal."
        fi
      fi
    ;;

    esac
  else # The folder to move was not found at the path pulled from retrodeck.cfg and it needs to be reconfigured manually.
    configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The $(basename "$dir_to_move") folder was not found at the expected location.\n\nThis may have happened if the folder was moved manually.\n\nPlease select the current location of the folder."
    dir_to_move=$(directory_browse "RetroDECK $(basename "$dir_to_move") directory location")
    declare -g "$rd_dir_name=$dir_to_move"
    prepare_component "postmove" "all"
    conf_write
    configurator_generic_dialog "RetroDECK Configurator - Move Folder" "RetroDECK $(basename "$dir_to_move") folder now configured at\n$dir_to_move."
    configurator_move_folder_dialog "$rd_dir_name"
  fi
}

configurator_change_preset_dialog() {
  # This function will build a list of all systems compatible with a given preset,
  # show their current enable/disabled state and allow the user to change one or more.
  # USAGE: configurator_change_preset_dialog "$preset"

  local preset="$1"
  pretty_preset_name=${preset//_/ }  # Preset name prettification
  pretty_preset_name=$(echo "$pretty_preset_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1')

  build_zenity_preset_menu_array "current_preset_settings" "$preset"

  choice=$(rd_zenity \
    --list --width=1200 --height=720 \
    --hide-column=5 --print-column=5 \
    --text="Enable $pretty_preset_name:" \
    --column "Status" \
    --column "Emulator" \
    --column "Emulated System" \
    --column "Emulator Description" \
    --column "internal_system_name" \
    "${current_preset_settings[@]}")

  local rc=$?

  log d "User made a choice: $choice with return code: $rc"

  if [[ "$rc" == 0 || -n "$choice" ]]; then # If the user didn't hit Cancel
    configurator_change_preset_value_dialog "$preset" "$choice"
  else
    log i "No preset choices made"
    configurator_global_presets_and_settings_dialog
  fi
}

configurator_change_preset_value_dialog() {
  local preset="$1"
  local component="$2"

  build_zenity_preset_value_menu_array current_preset_values "$preset" "$component"

  choice=$(rd_zenity \
    --list --width=1200 --height=720 \
    --radiolist \
    --hide-column=3 --print-column=3 \
    --text="Enable $pretty_preset_name:" \
    --column "Current State" \
    --column "Option" \
    --column "preset_state" \
    "${current_preset_values[@]}")

  local rc=$?

  log d "User made a choice: $choice with return code: $rc"

  if [[ "$rc" == 0 || -n "$choice" ]]; then # If the user didn't hit Cancel
    local preset_current_value=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset")
    if [[ ! "$choice" == "$preset_current_value" ]]; then
      if [[ "$preset" =~ (cheevos|cheevos_hardcore) ]]; then
        if [[ ! -n "$cheevos_username" || ! -n "$cheevos_token" ]]; then
          log d "Cheevos not currently logged in, prompting user..."
          if cheevos_login_info=$(get_cheevos_token_dialog); then
            cheevos_username=$(jq -r '.User' <<< "$cheevos_login_info")
            cheevos_token=$(jq -r '.Token' <<< "$cheevos_login_info")
            cheevos_login_timestamp=$(jq -r '.Timestamp' <<< "$cheevos_login_info")
          else
            configurator_generic_dialog "RetroDECK Configurator - Change Preset" "The preset state could not be changed. The error message is:\n\n\"$result\"\n\nCheck the RetroDECK logs for more details."
            configurator_change_preset_dialog "$preset"
            return 1
          fi
        fi
      fi
      if result=$(api_set_preset_state "$component" "$preset" "$choice"); then
        configurator_change_preset_dialog "$preset"
      else
        configurator_generic_dialog "RetroDECK Configurator - Change Preset" "The preset state could not be changed. The error message is:\n\n\"$result\"\n\nCheck the RetroDECK logs for more details."
        configurator_change_preset_dialog "$preset"
      fi
    fi
  else
    log i "No preset choices made"
    configurator_change_preset_dialog "$preset"
  fi
}

changelog_dialog() {
  # This function will pull the changelog notes from the version it is passed (which must match the metainfo version tag) from the net.retrodeck.retrodeck.metainfo.xml file
  # The function also accepts "all" as a version, and will print the entire changelog
  # USAGE: changelog_dialog "version"

  log d "Showing changelog dialog"

  if [[ "$1" == "all" ]]; then
    > "$XDG_CONFIG_HOME/retrodeck/changelog-full.xml"
    for release in $(xml sel -t -m "//component/releases/release" -v "@version" -n "$rd_metainfo"); do
      echo "<h1>RetroDECK v$release</h1>" >> "$XDG_CONFIG_HOME/retrodeck/changelog-full.xml"
      xml sel -t -m "//component/releases/release[@version='"$release"']/description" -c . "$rd_metainfo" | tr -s '\n' | sed 's/^\s*//' >> "$XDG_CONFIG_HOME/retrodeck/changelog-full.xml"
      echo "" >> "$XDG_CONFIG_HOME/retrodeck/changelog-full.xml"
    done

    #convert_to_markdown "$XDG_CONFIG_HOME/retrodeck/changelog-full.xml"

    rd_zenity --icon-name=net.retrodeck.retrodeck --text-info --width=1200 --height=720 \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Changelogs" \
    --filename="$XDG_CONFIG_HOME/retrodeck/changelog-full.xml.md"
  else
    xml sel -t -m "//component/releases/release[@version='"$1"']/description" -c . "$rd_metainfo" | tr -s '\n' | sed 's/^\s*//' > "$XDG_CONFIG_HOME/retrodeck/changelog.xml"

    convert_to_markdown "$XDG_CONFIG_HOME/retrodeck/changelog.xml"

    rd_zenity --icon-name=net.retrodeck.retrodeck --text-info --width=1200 --height=720 \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Changelogs" \
    --filename="$XDG_CONFIG_HOME/retrodeck/changelog.xml.md"
  fi
}

get_cheevos_token_dialog() {
  # This function will return a RetroAchvievements token from a valid username and password, will return an error code otherwise
  # USAGE: get_cheevos_token_dialog

  local cheevos_info=$(rd_zenity --forms --title="Cheevos" \
  --text="Username and password." \
  --separator="^" \
  --add-entry="Username" \
  --add-password="Password")

  IFS='^' read -r cheevos_username cheevos_password < <(printf '%s\n' "$cheevos_info")
  if cheevos_info=$(api_do_cheevos_login "$cheevos_username" "$cheevos_password"); then
    log d "Cheevos login succeeded"
    echo "$cheevos_info"
  else # login failed
    log d "Cheevos login failed"
    return 1
  fi
}

desktop_mode_warning() {
  # This function is a generic warning for issues that happen when running in desktop mode.
  # Running in desktop mode can be verified with the following command: if [[ ! $XDG_CURRENT_DESKTOP == "gamescope" ]]; then
  # This function will check if desktop mode is currently being used and if the warning has not been disabled, and show it if needed.
  # USAGE: desktop_mode_warning

  if [[ $(check_desktop_mode) == "true" && $desktop_mode_warning == "true" ]]; then
    local message='You appear to be running RetroDECK in the SteamOS <span foreground='$purple'>Desktop Mode</span>\n\nSome functions of RetroDECK may not work properly in SteamOS <span foreground='$purple'>Desktop Mode</span>.\n\nRetroDECK is best enjoyed in <span foreground='$purple'>Game mode</span> on SteamOS.\n\nDo you still want to proceed?'
    log i "Showing message:\n$message"
    choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Never show this again" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Desktop Mode Warning" \
    --text="$message")
    rc=$? # Capture return code, as "Yes" button has no text value
    if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
      if [[ $choice == "No" ]]; then
        log i "Selected: \"No\""
        exit 1
      elif [[ $choice == "Never show this again" ]]; then
        log i "Selected: \"Never show this again\""
        set_setting_value "$rd_conf" "desktop_mode_warning" "false" retrodeck "options" # Store desktop mode warning variable for future checks
      fi
    else
      log i "Selected: \"Yes\""
    fi
  fi
}

low_space_warning() {
  # This function will verify that the drive with the $HOME path on it has at least 10% space free, so the user can be warned before it fills up
  # USAGE: low_space_warning

  if [[ $low_space_warning == "true" ]]; then
    local used_percent=$(df --output=pcent "$HOME" | tail -1 | tr -d " " | tr -d "%")
    if [[ "$used_percent" -ge 90 && -d "$HOME/retrodeck" ]]; then # If there is any RetroDECK data on the main drive to move
      local message='Your main drive is over <span foreground='$purple'>90%</span> full!\n\nIf it fills up completely, you could lose data or experience a system crash.\n\nPlease move some RetroDECK folders to other storage locations using the Configurator or free up some space.'
      log i "Showing message:\n$message"
      choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK" --extra-button="Never show this again" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Low Space Warning" \
      --text="$message")
      if [[ $choice == "Never show this again" ]]; then
        log i "Selected: \"Never show this again\""
        set_setting_value "$rd_conf" "low_space_warning" "false" retrodeck "options" # Store low space warning variable for future checks
      fi
    fi
    log i "Selected: \"OK\""
  fi
}

configurator_power_user_warning_dialog() {
  if [[ $power_user_warning == "true" ]]; then
    choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Never show this again" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Power User Warning" \
    --text="Making manual changes to a components, systems or emulators configuration may create serious issues, and some settings may be overwritten during RetroDECK updates or when using presets.\n\nPlease continue only if you know what you're doing.\n\nDo you want to continue?")
  fi
  rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "0" ]]; then # If user clicked "Yes"
    configurator_open_component_dialog
  else # If any button other than "Yes" was clicked
    if [[ $choice == "No" ]]; then
      configurator_welcome_dialog
    elif [[ $choice == "Never show this again" ]]; then
      set_setting_value "$rd_conf" "power_user_warning" "false" retrodeck "options" # Store power user warning variable for future checks
      configurator_open_component_dialog
    fi
  fi
}
