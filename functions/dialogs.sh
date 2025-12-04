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
  --title "RetroDECK Configurator - Debug Dialog" \
  --text="$1"
}

configurator_process_complete_dialog() {
  # This dialog shows when a process is complete.
  # USAGE: configurator_process_complete_dialog "process text"
  log i "Process complete dialog for: $1" # showing the process in the logs
  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Quit🚪" --extra-button="OK 🟢" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - Process Complete" \
  --text="The process of <span foreground='$purple'><b>$1</b></span> is now complete.\n\nYou may need to <span foreground='$purple'><b>restart RetroDECK</b></span> for the changes to take effect.\n\nClick OK to return to the main menu or Quit to exit RetroDECK."

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
  choice=$(rd_zenity --title "RetroDECK - $1" --question --no-wrap --cancel-label="No 🟥" --ok-label="Yes 🟢" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="$2")
  if [[ $? == "0" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

configurator_destination_choice_dialog() {
  # This dialog is for making things easy for new users to move files to common locations. Gives the options for "Internal", "SD Card" and "Custom Location" locations if on Steam Deck, "Home Directory" and "Custom Location" otherwise.
  # USAGE: $(configurator_destination_choice_dialog "folder being moved" "action text")
  # This function returns one of the values: "Back" "Internal Storage"/"Home Directory" "SD Card" "Custom Location"
  log i "$2"
  if [[ $(check_is_steam_deck) == "true" ]]; then
    choice=$(rd_zenity --title "RetroDECK Configurator - Moving $1 directory" --info --no-wrap --ok-label="Quit🚪" --extra-button="Internal Storage 🏠" --extra-button="SD Card 💾" --extra-button="Custom Location 🟡" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="$2")
  else
    choice=$(rd_zenity --title "RetroDECK Configurator - Moving $1 directory" --info --no-wrap --ok-label="Quit🚪" --extra-button="Home Directory 🏠" --extra-button="Custom Location 🟡" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="$2")
  fi

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
  choice=$(rd_zenity --title "RetroDECK Configurator - Reset $1" --question --no-wrap --cancel-label="Cancel 🟥" --ok-label="Confirm 🟢" \
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

    "Internal Storage 🏠" | "Home Directory 🏠" | "SD Card 💾" | "Custom Location 🟡" ) # If the user picks a location
      if [[ "$choice" == "Internal Storage 🏠" || "$choice" == "Home Directory 🏠" ]]; then # If the user wants to move the folder to internal storage, set the destination target as HOME
        local dest_root="$HOME"
      elif [[ "$choice" == "SD Card 💾" ]]; then # If the user wants to move the folder to the predefined SD card location, set the target as sdcard from retrodeck.cfg
        local dest_root="$sdcard"
      else
        configurator_generic_dialog "RetroDECK Configurator - 📁 Move Folder 📁" "Select the parent folder where you would like to store the $(basename "$dir_to_move") folder."
        local dest_root=$(directory_browse "RetroDECK directory location") # Set the destination root as the selected custom location
      fi

      if [[ (! -z "$dest_root") && ( -w "$dest_root") ]]; then # If user picked a destination and it is writable
        if [[ (-d "$dest_root/$rd_dir_path") && (! -L "$dest_root/$rd_dir_path") && (! $rd_dir_name == "rd_home_path") ]] || [[ "$(realpath "$dir_to_move")" == "$dest_root/$rd_dir_path" ]]; then # If the user is trying to move the folder to where it already is (excluding symlinks that will be unlinked)
          configurator_generic_dialog "RetroDECK Configurator - 📁 Move Folder 📁" "The <span foreground='$purple'><b>$(basename "$dir_to_move")</b></span> folder is already at that location. Please select a new one."
          configurator_move_folder_dialog "$rd_dir_name"
        else
          if [[ $(verify_space "$(echo "$dir_to_move" | sed 's/\/$//')" "$dest_root") ]]; then # Make sure there is enough space at the destination
            configurator_generic_dialog "RetroDECK Configurator - 📁 Move Folder 📁" "Moving <span foreground='$purple'><b>$(basename "$dir_to_move")</b></span> folder to <span foreground='$purple'><b>$dest_root/retrodeck/$(basename "$dir_to_move")</b></span>)"
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
              configurator_generic_dialog "RetroDECK Configurator - 📁 Move Folder 📁" "<span foreground='$purple'><b>Moving $(basename "$dir_to_move")</b></span> folder to <span foreground='$purple'><b>$dest_root/retrodeck/$(basename "$dir_to_move")</b></span> was successful."
            else
              configurator_generic_dialog "RetroDECK Configurator - 📁 Move Folder 📁" "<span foreground='$purple'><b>The moving process was not completed.</b></span> Please try again."
            fi
          else # If there isn't enough space in the picked destination
            rd_zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator - Move Directories" \
            --text="The destination you selected does not have enough free space for the files you are trying to move\n\n\<span foreground='$purple'><b>Please choose a new destination or free up some space.</b></span>."
          fi
        fi
      else # If the user didn't pick any custom destination, or the destination picked is unwritable
        if [[ ! -z "$dest_root" ]]; then
          configurator_generic_dialog "RetroDECK Configurator - 📁 Move Folder 📁" "<span foreground='$purple'><b>No destination was chosen</b></span>, so no files have been moved."
        else
          configurator_generic_dialog "RetroDECK Configurator - 📁 Move Folder 📁" "<span foreground='$purple'><b>The chosen destination is not writable.</b></span>\nNo files have been moved.\n\nThis can happen if RetroDECK does not have permission to write to the selected location.\nYou can usually fix this by adding the desired path to RetroDECK permissions using Flatseal."
        fi
      fi
    ;;

    esac
  else # The folder to move was not found at the path pulled from retrodeck.cfg and it needs to be reconfigured manually.
    configurator_generic_dialog "RetroDECK Configurator - 📁 Move Folder 📁" "The <span foreground='$purple'><b>$(basename "$dir_to_move")</b></span> folder was not found at the expected location.\n\nThis may have happened if the folder was moved manually.\n\nPlease select the current location of the folder."
    dir_to_move=$(directory_browse "RetroDECK $(basename "$dir_to_move") directory location")
    declare -g "$rd_dir_name=$dir_to_move"
    prepare_component "postmove" "all"
    conf_write
    configurator_generic_dialog "RetroDECK Configurator - 📁 Move Folder 📁" "RetroDECK <span foreground='$purple'><b>$(basename "$dir_to_move")</b></span> folder now configured at\n<span foreground='$purple'><b>$dir_to_move</b></span>."
    configurator_move_folder_dialog "$rd_dir_name"
  fi

  configurator_data_management_dialog
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
    --ok-label="Select 🟡" --extra-button="Disable All 🟥" --extra-button="Enable All 🟢" \
    --text="Enable $pretty_preset_name:" \
    --column "Status" \
    --column "Emulator" \
    --column "Emulated System" \
    --column "Emulator Description" \
    --column "internal_system_name" \
    "${current_preset_settings[@]}")

  local rc=$?

  log d "User made a choice: $choice with return code: $rc"

  if [[ -n "$choice" ]]; then # If the user didn't hit Cancel
    if [[ "$choice" == "Enable All" ]]; then
      log d "User selected \"Enable All\""
      (
      while read -r component_obj; do
        local component="$(jq -r '.system_name' <<< $component_obj)"
        local parent_name="$(jq -r '.parent_component // empty' <<< $component_obj)"
        local child_component=""
        local current_status="$(jq -r '.status' <<< $component_obj)"

        if [[ -n "$parent_name" ]]; then
          child_component="$component"
          component="$parent_name"
        fi

        local preset_enabled_state=$(jq -r --arg component "$component" --arg core "$child_component" --arg preset "$preset" '
                                if $core != "" then
                                  .[$component].compatible_presets[$core][$preset].[1] // empty
                                else
                                  .[$component].compatible_presets[$preset].[1] // empty
                                end
                              ' "$rd_components/$component/component_manifest.json")

        if [[ ! "$current_status" == "$preset_enabled_state" ]]; then
          if [[ -n "$child_component" ]]; then
            log d "Enabling preset $preset for component $child_component"
            api_set_preset_state "$child_component" "$preset" "$preset_enabled_state"
          else
            log d "Enabling preset $preset for component $component"
            api_set_preset_state "$component" "$preset" "$preset_enabled_state"
          fi
        else
          if [[ -n "$child_component" ]]; then
            log d "Component $child_component is already enabled for preset $preset"
          else
            log d "Component $component is already enabled for preset $preset"
          fi
        fi
      done < <(api_get_current_preset_state "$preset" | jq -c '.[].[]')
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK - Enabling Preset $preset" \
      --width=400 --height=200 \
      --text="RetroDECK is <span foreground='$purple'><b>Enabling</b></span> the preset <span foreground='$purple'><b>$preset</b></span> for all compatible systems.\n\n⏳ Please wait... ⏳"
      configurator_change_preset_dialog "$preset"
    elif [[ "$choice" == "Disable All" ]]; then
      log d "User selected \"Disable All\""
      (
      while read -r component_obj; do
        local component="$(jq -r '.system_name' <<< $component_obj)"
        local parent_name="$(jq -r '.parent_component // empty' <<< $component_obj)"
        local child_component=""
        local current_status="$(jq -r '.status' <<< $component_obj)"

        if [[ -n "$parent_name" ]]; then
          child_component="$component"
          component="$parent_name"
        fi

        local preset_disabled_state=$(jq -r --arg component "$component" --arg core "$child_component" --arg preset "$preset" '
                                if $core != "" then
                                  .[$component].compatible_presets[$core][$preset].[0] // empty
                                else
                                  .[$component].compatible_presets[$preset].[0] // empty
                                end
                              ' "$rd_components/$component/component_manifest.json")

        if [[ ! "$current_status" == "$preset_disabled_state" ]]; then
          if [[ -n "$child_component" ]]; then
            log d "Disabling preset $preset for component $child_component"
            api_set_preset_state "$child_component" "$preset" "$preset_disabled_state"
          else
            log d "Disabling preset $preset for component $component"
            api_set_preset_state "$component" "$preset" "$preset_disabled_state"
          fi
        else
          if [[ -n "$child_component" ]]; then
            log d "Component $child_component is already disabled for preset $preset"
          else
            log d "Component $component is already disabled for preset $preset"
          fi
        fi
      done < <(api_get_current_preset_state "$preset" | jq -c '.[].[]')
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK - Disabling Preset $preset" \
      --width=400 --height=200 \
      --text="RetroDECK is <span foreground='$purple'><b>Disabling</b></span> the preset <span foreground='$purple'><b>$preset</b></span> for all compatible systems.\n\n⏳ Please wait... ⏳"
      configurator_change_preset_dialog "$preset"
    else
      log d "User selected \"$choice\""
      configurator_change_preset_value_dialog "$preset" "$choice"
    fi
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

  if [[ "$rc" == 0 && -n "$choice" ]]; then # If the user didn't hit Cancel
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
            configurator_generic_dialog "RetroDECK Configurator - 🔩 Change Preset 🔩" "The preset state could not be changed. The error message is:\n\n<span foreground='$purple'><b>"$result"</b></span>\n\nCheck the RetroDECK logs for more details."
            configurator_change_preset_dialog "$preset"
            return 1
          fi
        fi
      fi
      if result=$(api_set_preset_state "$component" "$preset" "$choice"); then
        configurator_change_preset_dialog "$preset"
      else
        configurator_generic_dialog "RetroDECK Configurator - 🔩 Change Preset 🔩" "The preset state could not be changed. The error message is:\n\n<span foreground='$purple'><b>"$result"</b></span>\n\nCheck the RetroDECK logs for more details."
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
    local message='You appear to be running RetroDECK in the SteamOS <span foreground='$purple'><b>Desktop Mode</b></span>.\n\n\Some functions of RetroDECK may not work properly in SteamOS <span foreground='$purple'><b>Desktop Mode</b></span>.\n\n\RetroDECK is best enjoyed in <span foreground='$purple'><b>Game Mode</b></span> on SteamOS.\n\n\Do you still want to proceed?'
    log i "Showing message:\n$message"
    choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes 🟢" --extra-button="No 🟥" --extra-button="Never show again 🛑" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK - 🛑 Warning: Desktop Mode 🛑" \
    --text="$message")
    rc=$? # Capture return code, as "Yes" button has no text value
    if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
      if [[ $choice == "No" ]]; then
        log i "Selected: \"No\""
        exit 1
      elif [[ $choice == "Never show again 🛑" ]]; then
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
      choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK 🟢"  --extra-button="Never show again 🛑" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK - 🛑 Warning: Low Space 🛑" \
      --text="$message")
      if [[ $choice == "Never show again 🛑" ]]; then
        log i "Selected: \"Never show this again\""
        set_setting_value "$rd_conf" "low_space_warning" "false" retrodeck "options" # Store low space warning variable for future checks
      fi
    fi
    log i "Selected: \"OK\""
  fi
}

configurator_power_user_warning_dialog() {
  if [[ $power_user_warning == "true" ]]; then
    choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes 🟢" --extra-button="No 🟥" --extra-button="Never show again 🛑" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK - 🛑 Warning: Power User 🛑" \
    --text="Making manual changes to a components configuration may create serious issues, and some settings may be overwritten during RetroDECK updates or when using presets.\n\n\The RetroDECK team do encourage tinkering.\n\n\But if anything goes wrong, you need to use the built-in <span foreground='$purple'><b>reset tools</b></span> inside the RetroDECK Configurator.\n\n\<span foreground='$purple'><b>Please continue only if you know what you're doing.</b></span>\n\n\Component types in RetroDECK:\n\n<span foreground='$purple'><b>• Clients</b></span>\n\<span foreground='$purple'><b>• Emulators</b></span>\n\<span foreground='$purple'><b>• Engines</b></span>\n\<span foreground='$purple'><b>• Ports</b></span>\n\<span foreground='$purple'><b>• Systems</b></span>\n\nDo you want to continue?")
  fi
  rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "0" ]]; then # If user clicked "Yes"
    configurator_open_component_dialog
  else # If any button other than "Yes" was clicked
    if [[ $choice == "No" ]]; then
      configurator_welcome_dialog
    elif [[ $choice == "Never show again 🛑" ]]; then
      set_setting_value "$rd_conf" "power_user_warning" "false" retrodeck "options" # Store power user warning variable for future checks
      configurator_open_component_dialog
    fi
  fi
}

configurator_portmaster_toggle_dialog() {

  if [[ $(get_setting_value "$rd_conf" "portmaster_show" "retrodeck" "options") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - 🛶 PortMaster Visibility 🛶" \
    --text="PortMaster is currently <span foreground='$purple'><b>Visible</b></span> in ES-DE. Do you want to hide it?\n\n\<span foreground='$purple'><b>Note: The installed games will still be visible.</b></span>"

    if [ $? == 0 ] # User clicked "Yes"
    then
      portmaster_show "false"
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - 🛶 PortMaster Visibility 🛶" \
      --text="PortMaster is now <span foreground='$purple'><b>Hidden</b></span> in ES-DE.\n\Please refresh your game list in ES-DE or restart RetroDECK to see the changes.\n\n\To launch PortMaster, you can access it from:\n<span foreground='$purple'><b>Configurator -> Open Component -> PortMaster</b></span>."
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - 🛶 PortMaster Visibility 🛶" \
    --text="PortMaster is currently <span foreground='$purple'><b>Hidden</b></span> in ES-DE. Do you want to show it?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      portmaster_show "true"
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - 🛶 PortMaster Visibility 🛶" \
      --text="PortMaster is now <span foreground='$purple'><b>Visible</b></span> in ES-DE.\nPlease refresh your game list in ES-DE or restart RetroDECK to see the changes."
    fi
  fi
}

configurator_bios_checker_dialog() {

  log d "Starting BIOS checker"

  (
    # Read the BIOS checklist from bios.json using jq
    total_bios=$(jq '.bios | length' "$bios_checklist")
    current_bios=0

    log d "Total BIOS files to check: $total_bios"

    bios_checked_list=()

    while read -r bios_obj; do

    local bios_file=$(jq -r '.filename // "Unknown"' <<< "$bios_obj")
    local bios_systems=$(jq -r '.system // "Unknown"' <<< "$bios_obj")
    local bios_required=$(jq -r '.required // "No"' <<< "$bios_obj")
    local bios_paths=$(jq -r '.paths // "'"$bios_path"'" | if type=="array" then join(", ") else . end' <<< "$bios_obj")
    local bios_desc=$(jq -r '.description // "No description provided"' <<< "$bios_obj")
    local bios_md5=$(jq -r '.md5 | if type=="array" then join(", ") else . end // "Unknown"' <<< "$obj")

    # Expand any embedded shell variables (e.g. $saves_path or $bios_path) with their actual values
    bios_paths=$(echo "$bios_paths" | envsubst)

    bios_file_found="No"
    bios_md5_matched="No"

    IFS=', ' read -r -a paths_array <<< "$bios_paths"
    for path in "${paths_array[@]}"; do
      log d "Looking for $path/$bios_file"
      if [[ ! -f "$path/$bios_file" ]]; then
        log d "File $path/$bios_file not found"
        break
      else
        bios_file_found="Yes"
        computed_md5=$(md5sum "$path/$bios_file" | awk '{print $1}')

        IFS=', ' read -ra expected_md5_array <<< "$bios_md5"
        for expected in "${expected_md5_array[@]}"; do
          expected=$(echo "$expected" | xargs)
          if [ "$computed_md5" == "$expected" ]; then
            bios_md5_matched="Yes"
            break
          fi
        done
        log d "BIOS file found: $bios_file_found, Hash matched: $bios_md5_matched"
        log d "Expected path: $path/$bios_file"
        log d "Expected MD5: $bios_md5"
      fi
    done

    log d "Adding BIOS entry: \"$bios_file $bios_systems $bios_file_found $bios_md5_matched $bios_required $bios_desc $bios_paths $bios_md5\" to the bios_checked_list"

    bios_checked_list=("${bios_checked_list[@]}" "$bios_file" "$bios_systems" "$bios_file_found" "$bios_md5_matched" "$bios_required" "$bios_paths" "$bios_desc" "$bios_md5")

    current_bios=$((current_bios + 1))
    echo "$((current_bios * 100 / total_bios))"

    done < <(jq -c '.bios | map(.system |= (if type=="array" then join(", ") else . end // "Unknown")) | sort_by(.system) | .[]' "$bios_checklist")

    log d "Finished checking BIOS files"

    rd_zenity --list --title="RetroDECK Configurator - BIOS Checker" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --column "BIOS File Name" \
      --column "Systems" \
      --column "Found" \
      --column "Hash Matches" \
      --column "Required" \
      --column "Expected Path" \
      --column "Description" \
      --column "MD5" \
      "${bios_checked_list[@]}"

  ) |
  rd_zenity --progress --auto-close --no-cancel \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - BIOS Checker: 🔎 Scanning 🔎" \
    --text="The BIOS Checker is scanning for <span foreground='$purple'><b>BIOS and Firmware</b></span> files that RetroDECK recognizes as supported by each system.\n\n\Please note that not all BIOS & Firmware files are necessary for games to work.\n\n\BIOS files not recognized by this tool may still function correctly.\n\n\Some components have additional built-in methods to verify the functionality of BIOS and Firmware files.\n\n\⏳ <span foreground='$purple'><b>The BIOS Checker is now scanning your BIOS files, please wait...</b></span> ⏳" \
    --width=400 --height=100

  configurator_tools_dialog
}

configurator_compression_tool_dialog() {
  configurator_generic_dialog "RetroDECK Configurator - 🗜️ Compression Tool 🗜️" "Depending on your library size and compression settings, this process may take some time."

  choice=$(rd_zenity --list --title="RetroDECK Configurator - 🗜️ Compression Tool 🗜️" --cancel-label="Back 🔙" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Compress Single Game" "Compress a single game into a compatible format." \
  "Compress Multiple Games: CHD" "Compress one or more games into the CHD format." \
  "Compress Multiple Games: ZIP" "Compress one or more games into the ZIP format." \
  "Compress Multiple Games: RVZ" "Compress one or more games into the RVZ format." \
  "Compress Multiple Games: All Formats" "Compress one or more games into any format." \
  "Compress All Games" "Compress all games into compatible formats." )

  case $choice in

  "Compress Single Game" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_single_game_dialog
  ;;

  "Compress Multiple Games: CHD" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "chd"
    configurator_compression_tool_dialog
  ;;

  "Compress Multiple Games: ZIP" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "zip"
    configurator_compression_tool_dialog
  ;;

  "Compress Multiple Games: RVZ" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "rvz"
    configurator_compression_tool_dialog
  ;;

  "Compress Multiple Games: All Formats" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "all"
    configurator_compression_tool_dialog
  ;;

  "Compress All Games" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "everything"
    configurator_compression_tool_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_tools_dialog
  ;;

  esac
}

configurator_compress_single_game_dialog() {
  local file=$(file_browse "Game to compress")
  if [[ ! -z "$file" ]]; then
    local system=$(echo "$file" | grep -oE "$roms_path/[^/]+" | grep -oE "[^/]+$")
    local compatible_compression_format=$(find_compatible_compression_format "$file")
    if [[ ! $compatible_compression_format == "none" ]]; then
      local post_compression_cleanup=$(configurator_compression_cleanup_dialog)
      (
      echo "# Compressing $(basename "$file") to $compatible_compression_format format" # This updates the Zenity dialog
      log i "Compressing $(basename "$file") to $compatible_compression_format format"
      compress_game "$compatible_compression_format" "$file" "$post_compression_cleanup" "$system"
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --width="800" \
      --title "RetroDECK Configurator - ⏳ Compression in Progress ⏳"
      configurator_generic_dialog "RetroDECK Configurator - 🗜️ Compression Tool 🗜️" "The compression process is complete."
      configurator_compression_tool_dialog

    else
      configurator_generic_dialog "RetroDECK Configurator - 🗜️ Compression Tool 🗜️" "The selected file does not contain any compatible compression formats."
      configurator_compression_tool_dialog
    fi
  else
    configurator_compression_tool_dialog
  fi
}

configurator_compress_multiple_games_dialog() {
  log d "Starting to compress \"$1\""

  compressible_games_list_file="$(mktemp)"

  (
    api_get_compressible_games "$1" | jq -c '.[]' > "$compressible_games_list_file"
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - 🗜️ Compression Tool 🗜️" --text "RetroDECK is searching for compressible games, please wait..."

  if [[ -n "$(cat "$compressible_games_list_file")" ]]; then
    log d "Found the following games to compress: ${all_compressible_games[*]}"
  else
    configurator_generic_dialog "RetroDECK Configurator - 🗜️ Compression Tool 🗜️" "No compressible files were found."
    rm "$compressible_games_list_file"
    return 1
  fi

  local games_to_compress=()
  if [[ "$1" != "everything" ]]; then
    local checklist_entries=()
    while read -r obj; do # Iterate through all returned menu objects
      local game=$(jq -r '.game' <<< "$obj")
      local format=$(jq -r '.format' <<< "$obj")
      checklist_entries+=( "FALSE" "$game" "$format" )
    done < <(cat "$compressible_games_list_file")

    local choice=$(rd_zenity \
      --list --width=1200 --height=720 --title "RetroDECK Configurator - 🗜️ Compression Tool 🗜️" \
      --checklist --hide-column=3 --ok-label="Compress Selected 🟡" --extra-button="Compress All 🟢" \
      --separator="^" --print-column=2,3 \
      --text="Choose which games to compress:" \
      --column "Compress?" \
      --column "Game" \
      --column "Compression Format" \
      "${checklist_entries[@]}")

    local rc=$?
    log d "User choice: $choice"
    if [[ $rc == 0 && -n "$choice" && ! "$choice" == "Compress All" ]]; then
      IFS='^' read -r -a temp_array <<< "$choice"
      games_to_compress=()
      for ((i=0; i<${#temp_array[@]}; i+=2)); do
        games_to_compress+=("${temp_array[i]}^${temp_array[i+1]}")
      done
    elif [[ "$choice" == "Compress All" ]]; then
      while read -r obj; do # Iterate through all returned menu objects
        local game=$(jq -r '.game' <<< "$obj")
        local format=$(jq -r '.format' <<< "$obj")
        games_to_compress+=( "$game^$format" )
      done < <(cat "$compressible_games_list_file")
    else
      rm "$compressible_games_list_file"
      return 0
    fi
  else
    while read -r obj; do # Iterate through all returned menu objects
      local game=$(jq -r '.game' <<< "$obj")
      local format=$(jq -r '.format' <<< "$obj")
      games_to_compress+=( "$game^$format" )
    done < <(cat "$compressible_games_list_file")
  fi

  rm "$compressible_games_list_file"

  local post_compression_cleanup=$(configurator_compression_cleanup_dialog)

  local total_games=${#games_to_compress[@]}
  local games_left=$total_games

  (
  for game_line in "${games_to_compress[@]}"; do
    while (( $(jobs -p | wc -l) >=  $system_cpu_max_threads )); do
    sleep 0.1
    done
    (
    IFS="^" read -r game compression_format <<< "$game_line"

    local system
    system=$(echo "$game" | grep -oE "$roms_path/[^/]+" | grep -oE "[^/]+$")
    log i "Compressing $(basename "$game") into $compression_format format"

    echo "#Compressing $(basename "$game") into $compression_format format.\n\n$games_left games left to compress." # Update Zenity dialog text

    compress_game "$compression_format" "$game" "$post_compression_cleanup" "$system"

    games_left=$(( games_left - 1 ))
    local progress=$(( 99 - (( 99 / total_games ) * games_left) ))
    echo "$progress" # Update Zenity dialog progress bar
    ) &
  done
  wait # wait for background tasks to finish
  echo "100" # Close Zenity progress dialog when finished
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck/retrodeck.svg" \
    --width="800" \
    --title "RetroDECK Configurator - ⏳ Compression in Progress ⏳"

  configurator_generic_dialog "RetroDECK Configurator - 🗜️ Compression Tool 🗜️" "The compression process is complete!"
}

configurator_compression_cleanup_dialog() {
  rd_zenity --icon-name=net.retrodeck.retrodeck --question --no-wrap --cancel-label="No 🟥" --ok-label="Yes 🟢" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - 🗜️ Compression Tool 🗜️" \
  --text="Would you like to delete the original files after they are compressed?\n\n\If you select <span foreground='$purple'><b>No</b></span>, the original files will remain. You will need to remove them manually, and this may cause <span foreground='$purple'><b>duplicate games</b></span> to appear in the RetroDECK library.\n\n\Before enabling automatic cleanup, please ensure you have a <span foreground='$purple'><b>backup of your files</b></span>."
  local rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "0" ]]; then # If user clicked "Yes"
    echo "true"
  else # If "No" was clicked
    echo "false"
  fi
}

configurator_update_notify_dialog() {
  if [[ $(get_setting_value "$rd_conf" "update_check" retrodeck "options") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - ✅ Online Update Check ✅" \
    --text="Online update checks for RetroDECK are currently <span foreground='$purple'><b>Enabled</b></span>.\n\nDo you want to disable them?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value "$rd_conf" "update_check" "false" retrodeck "options"
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - ✅ Online Update Check ✅" \
    --text="Online update checks for RetroDECK are currently <span foreground='$purple'><b>Disabled</b></span>.\n\nDo you want to enable them?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    fi
  fi
  configurator_tools_dialog
}

configurator_repair_paths_dialog() {
  repair_paths
  configurator_tools_dialog
}

configurator_change_rd_logging_level_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator - 📒 Change Logging Level 📒" --cancel-label="Back 🔙" --ok-label="OK 🟢" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Level 1: Informational" "The default setting, logs only basic important information." \
  "Level 2: Warnings" "Logs general warnings." \
  "Level 3: Errors" "Logs more detailed error messages." \
  "Level 4: Debug" "Logs everything, which may generate a lot of logs.")

  case $choice in

  "Level 1: Informational" )
    log i "Configurator: Changing logging level to \"$choice\""
    set_setting_value "$rd_conf" "rd_logging_level" "info" "retrodeck" "options"
    declare -g "$rd_logging_level=info"
    configurator_generic_dialog "RetroDECK Configurator - 📒 Change Logging Level 📒" "The logging level has been changed to <span foreground='$purple'><b>Level 1: Informational</b></span>."
  ;;

  "Level 2: Warnings" )
    log i "Configurator: Changing logging level to \"$choice\""
    set_setting_value "$rd_conf" "rd_logging_level" "warn" "retrodeck" "options"
    declare -g "$rd_logging_level=warn"
    configurator_generic_dialog "RetroDECK Configurator - 📒 Change Logging Level 📒" "The logging level has been changed to <span foreground='$purple'><b>Level 2: Warnings</b></span>."
  ;;

  "Level 3: Errors" )
    log i "Configurator: Changing logging level to \"$choice\""
    set_setting_value "$rd_conf" "rd_logging_level" "error" "retrodeck" "options"
    declare -g "$rd_logging_level=error"
    configurator_generic_dialog "RetroDECK Configurator - 📒 Change Logging Level 📒" "The logging level has been changed to <span foreground='$purple'><b> Level 3: Errors</b></span>."
  ;;

  "Level 4: Debug" )
    log i "Configurator: Changing logging level to \"$choice\""
    set_setting_value "$rd_conf" "rd_logging_level" "debug" "retrodeck" "options"
    declare -g "$rd_logging_level=debug"
    configurator_generic_dialog "RetroDECK Configurator - 📒 Change Logging Level 📒" "The logging level has been changed to <span foreground='$purple'><b> Level 4: Debug</b></span>."
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
  ;;

  esac
  configurator_tools_dialog
}

configurator_retrodeck_backup_dialog() {
  configurator_generic_dialog "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" "This tool will compress one or more RetroDECK userdata folders into a single zip file.\n\n\Please note that this process may take several minutes.\n\n\<span foreground='$purple'><b>The resulting zip file will be located in $backups_path.</b></span>"

  choice=$(rd_zenity --title "RetroDECK Configurator - 🗄️ Backup Userdata 🗄️" --info --no-wrap --ok-label="No Backup 🟥" --extra-button="Core Backup 🟠" --extra-button="Custom Backup 🟡" --extra-button="Complete Backup 🟢" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --text="Would you like to back up some or all RetroDECK userdata?\n\n")

  case $choice in
    "Core Backup 🟠" )
      log i "User chose to backup core userdata prior to update."
      export CONFIGURATOR_GUI="zenity"
      backup_retrodeck_userdata "core"
    ;;
    "Custom Backup 🟡" )
      log i "User chose to backup custom userdata prior to update."
      while read -r config_line; do
        local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
        if [[ ! $current_setting_name =~ (rd_home_path|sdcard|rd_home_backups_path) ]]; then # Ignore these locations
        log d "Adding $current_setting_name to compressible paths."
          local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
          compressible_paths=("${compressible_paths[@]}" "false" "$current_setting_name" "$current_setting_value")
        fi
      done < <(grep -v '^\s*$' "$rd_conf" | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f')

      choice=$(rd_zenity \
      --list --width=1200 --height=720 \
      --checklist \
      --separator="^" \
      --print-column=3 \
      --text="Please select the folders you wish to compress..." \
      --column "Backup?" \
      --column "Folder Name" \
      --column "Path" \
      "${compressible_paths[@]}")

      choices=() # Expand choice string into passable array
      IFS='^' read -ra choices <<< "$choice"

      export CONFIGURATOR_GUI="zenity"
      backup_retrodeck_userdata "custom" "${choices[@]}" # Expand array of choices into individual arguments
    ;;
    "Complete Backup 🟢" )
      log i "User chose to backup all userdata prior to update."
      export CONFIGURATOR_GUI="zenity"
      backup_retrodeck_userdata "complete"
    ;;
  esac

  configurator_data_management_dialog
}

configurator_clean_empty_systems_dialog() {
  configurator_generic_dialog "RetroDECK Configurator - 📁 Clean Empty System Folders 📁" "Before removing any identified empty system folders,\n<span foreground='$purple'><b>please ensure that your game collection is backed up to prevent data loss.</b></span>"
  configurator_generic_dialog "RetroDECK Configurator - 📁 Clean Empty System Folders 📁" "Searching for empty system folders.\n\n⏳ Please wait... ⏳"
  find_empty_rom_folders

  choice=$(rd_zenity \
      --list --width=1200 --height=720 --title "RetroDECK Configurator - 📁 Clean Empty System Folders 📁" \
      --checklist --hide-column=3 --ok-label="Remove Selected 🟡" --extra-button="Remove All 🟢" \
      --separator="^" --print-column=2 \
      --text="Choose which empty ROM folders to remove:" \
      --column "Remove?" \
      --column "System" \
      "${empty_rom_folders_list[@]}")

  local rc=$?
  if [[ $rc == "0" && ! -z $choice ]]; then # User clicked "Remove Selected" with at least one system selected
    IFS="^" read -ra folders_to_remove <<< "$choice"
    for folder in "${folders_to_remove[@]}"; do
      log i "Removing empty folder $folder"
      rm -rf "$folder"
    done
    configurator_generic_dialog "RetroDECK Configurator - 📁 Clean Empty System Folders 📁" "The removal process is complete."
  elif [[ ! -z $choice ]]; then # User clicked "Remove All"
    for folder in "${all_empty_folders[@]}"; do
      log i "Removing empty folder $folder"
      rm -rf "$folder"
    done
    configurator_generic_dialog "RetroDECK Configurator - 📁 Clean Empty System Folders 📁" "The removal process is complete."
  fi

  configurator_data_management_dialog
}

configurator_rebuild_esde_systems() {
  es-de --create-system-dirs
  configurator_generic_dialog "RetroDECK Configurator - 📁 Rebuild System Folders 📁" "<span foreground='$purple'><b>The rebuilding process is complete.</b></span>\n\nAll missing default system folders will now exist in <span foreground='$purple'><b>$roms_path</b></span>."
  configurator_data_management_dialog
}

configurator_version_history_dialog() {
  local version_array=($(xml sel -t -v '//component/releases/release/@version' -n "$rd_metainfo"))
  local all_versions_list=()

  for rd_version in ${version_array[*]}; do
    all_versions_list=("${all_versions_list[@]}" "RetroDECK $rd_version Changelog" "View the changes specific to version $rd_version")
  done

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Version History 📖" --cancel-label="Back 🔙" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Full RetroDECK Changelog" "View the list of all changes that have ever been made to RetroDECK" \
  "${all_versions_list[@]}")

  case $choice in

  "Full RetroDECK Changelog" )
    log i "Configurator: opening \"$choice\" menu"
    changelog_dialog "all"
  ;;

  "RetroDECK"*"Changelog" )
    log i "Configurator: opening \"$choice\" menu"
    local version=$(echo "$choice" | sed 's/^RetroDECK \(.*\) Changelog$/\1/')
    changelog_dialog "$version"
  ;;

  esac

  configurator_about_retrodeck_dialog
}

configurator_retrodeck_credits_dialog() {
  rd_zenity --icon-name=net.retrodeck.retrodeck --text-info --width=1200 --height=720 \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - 🏆 RetroDECK Team Credits 🏆" \
  --filename="$rd_core_files/reference_lists/retrodeck_credits.txt"
  configurator_about_retrodeck_dialog
}

configurator_browse_retrodeck_wiki_dialog() {
  xdg-open "https://github.com/RetroDECK/RetroDECK/wiki"
  configurator_developer_dialog
}

configurator_install_retrodeck_starter_pack_dialog() {
  if [[ $(configurator_generic_question_dialog "Install: RetroDECK Starter Pack" "The RetroDECK creators have put together a collection of classic retro games you might enjoy!\n\nWould you like to have them automatically added to your library?") == "true" ]]; then
    install_retrodeck_starterpack
  fi
  configurator_developer_dialog
}

configurator_retrodeck_multiuser_dialog() {
  if [[ $(get_setting_value "$rd_conf" "multi_user_mode" retrodeck "options") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Multi-user Support" \
    --text="Multi-user mode is currently enabled. Do you want to disable it?\n\nIf there is more than one user configured, you will be given a choice of which user to keep as the single RetroDECK user.\n\nThis users files will be moved to the default locations.\n\nOther users files will remain in the mutli-user-data folder."

    if [ $? == 0 ] # User clicked "Yes"
    then
      multi_user_disable_multi_user_mode
    else # User clicked "Cancel"
      configurator_developer_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Multi-user support" \
    --text="Multi-user mode is currently disabled. Do you want to enable it?\n\nThe current users saves and states will be backed up and moved to the \"retrodeck/multi-user-data\" folder.\nAdditional users will automatically be stored in their own folder here as they are added."

    if [ $? == 0 ]
    then
      multi_user_enable_multi_user_mode
    else
      configurator_developer_dialog
    fi
  fi
}

configurator_online_update_channel_dialog() {
  if [[ $(get_setting_value "$rd_conf" "update_repo" retrodeck "options") == "RetroDECK" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Change Update Branch" \
    --text="You are currently on the <span foreground='$purple'><b>Stable</b></span> 💎 branch of RetroDECK updates. Would you like to switch to the <span foreground='$purple'><b>Cooker</b></span> 🍲 branch?\n\n\After installing a cooker build, you may need to remove the <span foreground='$purple'><b>Stable</b></span> branch install of RetroDECK to avoid overlap."

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    fi
  else
    set_setting_value "$rd_conf" "update_repo" "RetroDECK" retrodeck "options"
    release_selector
  fi
  configurator_developer_dialog
}

configurator_usb_import_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator - 🧑‍💻 Developer Options 🧑‍💻" --cancel-label="Back 🔙" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Prepare USB device" "Create ROM and BIOS folders on a selected USB device" \
  "Import from USB" "Import collection from a previously prepared device" )

  case $choice in

  "Prepare USB device" )
    log i "Configurator: opening \"$choice\" menu"

    external_devices=()

    while read -r size device_path; do
      device_name=$(basename "$device_path")
      external_devices=("${external_devices[@]}" "$device_name" "$size" "$device_path")
    done < <(df --output=size,target -h | grep "/run/media/" | grep -v "$sdcard" | awk '{$1=$1;print}')

    if [[ "${#external_devices[@]}" -gt 0 ]]; then
      configurator_generic_dialog "RetroDeck Configurator - ⬇️ USB Import ⬇️" "If you have an SD card installed that is not currently configured in RetroDECK, it may appear in this list but may not be suitable for USB import.\n\n<span foreground='$purple'><b>Please select your desired drive carefully.</b></span>"
      choice=$(rd_zenity --list --title="RetroDECK Configurator - ➡️ USB Migration Tool ➡️" --cancel-label="Back 🔙" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ ! -z "$choice" ]]; then
        create_dir "$choice/RetroDECK Import"
        es-de --home "$choice/RetroDECK Import" --create-system-dirs
        rm -rf "$choice/RetroDECK Import/ES-DE" # Cleanup unnecessary folder


        # Prepare default BIOS folder subfolders
        create_dir "$choice/RetroDECK Import/BIOS/np2kai"
        create_dir "$choice/RetroDECK Import/BIOS/dc"
        create_dir "$choice/RetroDECK Import/BIOS/Mupen64plus"
        create_dir "$choice/RetroDECK Import/BIOS/quasi88"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/samples"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/cheats"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/blend"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/patched"
        create_dir "$choice/RetroDECK Import/BIOS/citra/sysdata"
        create_dir "$choice/RetroDECK Import/BIOS/cemu"
        create_dir "$choice/RetroDECK Import/BIOS/pico-8/carts"
        create_dir "$choice/RetroDECK Import/BIOS/pico-8/cdata"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_hdd0"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_hdd1"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_flash"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_flash2"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_flash3"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_bdvd"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_usb000"
        create_dir "$choice/RetroDECK Import/BIOS/Vita3K/"
        create_dir "$choice/RetroDECK Import/BIOS/mame-sa/samples"
        create_dir "$choice/RetroDECK Import/BIOS/gzdoom"
      fi
    else
      configurator_generic_dialog "RetroDeck Configurator - ⬇️ USB Import ⬇️" "<span foreground='$purple'><b>No USB devices were found.</b></span>"
    fi
    configurator_usb_import_dialog
  ;;

  "Import from USB" )
    log i "Configurator: opening \"$choice\" menu"
    external_devices=()

    while read -r size device_path; do
      if [[ -d "$device_path/RetroDECK Import/ROMs" ]]; then
        device_name=$(basename "$device_path")
        external_devices=("${external_devices[@]}" "$device_name" "$size" "$device_path")
      fi
    done < <(df --output=size,target -h | grep "/run/media/" | grep -v "$sdcard" | awk '{$1=$1;print}')

    if [[ "${#external_devices[@]}" -gt 0 ]]; then
      choice=$(rd_zenity --list --title="RetroDECK Configurator - ➡️ USB Migration Tool ➡️" --cancel-label="Back 🔙" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ ! -z "$choice" ]]; then
        if [[ $(verify_space "$choice/RetroDECK Import/ROMs" "$roms_path") == "false" || $(verify_space "$choice/RetroDECK Import/BIOS" "$bios_path") == "false" ]]; then
          if [[ $(configurator_generic_question_dialog "RetroDECK Configurator - ➡️ USB Migration Tool ➡️" "You MAY not have enough free space to import this ROM/BIOS library.\n\nThis utility only imports new additions from the USB device, so if there are a lot of the same files in both locations you are likely going to be fine\nbut we are not able to verify how much data will be transferred before it happens.\n\nIf you are unsure, please verify your available free space before continuing.\n\nDo you want to continue now?") == "true" ]]; then
            (
            rsync -a --mkpath "$choice/RetroDECK Import/ROMs/"* "$roms_path"
            rsync -a --mkpath "$choice/RetroDECK Import/BIOS/"* "$bios_path"
            ) |
            rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator - ⏳ USB Import In Progress ⏳"
            configurator_generic_dialog "RetroDECK Configurator - ➡️ USB Migration Tool ➡️" "The import process is complete!"
          fi
        else
          (
          rsync -a --mkpath "$choice/RetroDECK Import/ROMs/"* "$roms_path"
          rsync -a --mkpath "$choice/RetroDECK Import/BIOS/"* "$bios_path"
          ) |
          rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK Configurator - ⏳ USB Import In Progress ⏳"
          configurator_generic_dialog "RetroDECK Configurator - ➡️ USB Migration Tool ➡️" "The import process is complete!"
        fi
      fi
    else
      configurator_generic_dialog "RetroDeck Configurator - ⬇️ USB Import ⬇️" "<span foreground='$purple'><b>No USB devices with an importable folder were found.</b></span>"
    fi
    configurator_usb_import_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_developer_dialog
  ;;
  esac
}

configurator_iconset_toggle_dialog() {
  if [[ ! $(get_setting_value "$rd_conf" "folder_iconset" "retrodeck" "options") == "false" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - 🎨 Folder Iconsets 🎨" \
    --text="RetroDECK folder icons are currently <span foreground='$purple'><b>Enabled</b></span>. Do you want to remove them?"
    
    if [ $? == 0 ] # User clicked "Yes"
    then
      (
      handle_folder_iconsets "false"
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator - Toggle Folder Iconsets ⏳ In Progress ⏳ "
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - 🎨 Folder Iconsets 🎨" \
      --text="RetroDECK folder icons are now <span foreground='$purple'><b>Disabled</b></span>."
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - 🎨 Folder Iconsets 🎨" \
    --text="RetroDECK folder icons are currently <span foreground='$purple'><b>Disabled</b></span>. Do you want to enable them?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      (
      handle_folder_iconsets "lahrs-main"
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - Toggle Folder Iconsets ⏳ In Progress ⏳"
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - 🎨 Toggle Folder Iconsets 🎨" \
      --text="RetroDECK folder icons are now <span foreground='$purple'><b>Enabled</b></span>."
    fi
  fi

  configurator_global_presets_and_settings_dialog
}

finit_install_controller_profile_dialog() {
  get_steam_user "finit"
  if [[ -n "$steam_id" ]]; then
    rd_zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK Initial Install - 🚂 Add to Steam 🚂" --cancel-label="No 🟥 " --ok-label "Yes 🟢" \
    --text="Would you like to install the RetroDECK Steam Controller Templates and add RetroDECK to Steam?\n\n\Needed for <span foreground='$purple'><b>optimal controller support</b></span>via Steam Input."
  else
    return 1
  fi
}
