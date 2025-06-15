#!/bin/bash

# Dialog colors
purple="#a864fc"
blue="#6fbfff"

debug_dialog() {
  # This function is for displaying commands run by the Configurator without actually running them
  # USAGE: debug_dialog "command"

  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - Debug Dialog" \
  --text="$1"
}

configurator_process_complete_dialog() {
  # This dialog shows when a process is complete.
  # USAGE: configurator_process_complete_dialog "process text"
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
  log i "Showing a configurator_generic_dialog"
  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "$1" \
  --text="$2"
}

configurator_generic_question_dialog() {
  # This dialog provides a generic dialog for getting a response from a user.
  # USAGE: $(configurator_generic_question_dialog "title text" "action text")
  # This function will return a "true" if the user clicks "Yes", and "false" if they click "No".
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
                prepare_component "postmove" "retrodeck"
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
    --text="Making manual changes to an component, system or emulators configuration may create serious issues, and some settings may be overwritten during RetroDECK updates or when using presets.\n\nPlease continue only if you know what you're doing.\n\nDo you want to continue?")
  fi
  rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "0" ]]; then # If user clicked "Yes"
    configurator_open_emulator_dialog
  else # If any button other than "Yes" was clicked
    if [[ $choice == "No" ]]; then
      configurator_welcome_dialog
    elif [[ $choice == "Never show this again" ]]; then
      set_setting_value "$rd_conf" "power_user_warning" "false" retrodeck "options" # Store power user warning variable for future checks
      configurator_open_emulator_dialog
    fi
  fi
}

configurator_compression_tool_dialog() {
  configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "Depending on your library and compression choices, the process can sometimes take a long time.\nPlease be patient once it is started!"

  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Compression Tool" --cancel-label="Back" \
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
    local system=$(echo "$file" | grep -oE "$rd_home_roms_path/[^/]+" | grep -oE "[^/]+$")
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
      --title "RetroDECK Configurator Utility - Compression in Progress"
      configurator_generic_dialog "RetroDECK Configurator - RetroDECK: Compression Tool" "The compression process is complete."
      configurator_compression_tool_dialog

    else
      configurator_generic_dialog "RetroDECK Configurator - RetroDECK: Compression Tool" "The selected file does not have any compatible compression formats."
      configurator_compression_tool_dialog
    fi
  else
    configurator_compression_tool_dialog
  fi
}

configurator_compress_multiple_games_dialog() {
  log d "Starting to compress \"$1\""

  (
    parse_json_to_array checklist_entries api_get_compressible_games "$1"
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - RetroDECK: Compression Tool" --text "RetroDECK is searching for compressible games, please wait..."

  if [[ -s "$compressible_games_list_file" ]]; then
    mapfile -t all_compressible_games < "$compressible_games_list_file"
    log d "Found the following games to compress: ${all_compressible_games[*]}"
  else
    configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "No compressible files were found."
    configurator_compression_tool_dialog
  fi

  local games_to_compress=()
  if [[ "$1" != "everything" ]]; then
    local checklist_entries=()
    for line in "${all_compressible_games[@]}"; do
      IFS="^" read -r game comp <<< "$line"
      local short_game="${game#$rd_home_roms_path}"
      checklist_entries+=( "TRUE" "$short_game" "$line" )
    done

    local choice=$(rd_zenity \
      --list --width=1200 --height=720 --title "RetroDECK Configurator - Compression Tool" \
      --checklist --hide-column=3 --ok-label="Compress Selected" --extra-button="Compress All" \
      --separator="^" --print-column=3 \
      --text="Choose which games to compress:" \
      --column "Compress?" \
      --column "Game" \
      --column "Game Full Path and Compression Format" \
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
      games_to_compress=("${all_compressible_games[@]}")
    else
      configurator_compression_tool_dialog
    fi
  else
    games_to_compress=("${all_compressible_games[@]}")
  fi

  local post_compression_cleanup=$(configurator_compression_cleanup_dialog)

  local total_games=${#games_to_compress[@]}
  local games_left=$total_games

  (
  for game_line in "${games_to_compress[@]}"; do
    while (( $(jobs -p | wc -l) >= $system_cpu_system_cpu_max_threads )); do
    sleep 0.1
    done
    (
    IFS="^" read -r game compression_format <<< "$game_line"

    local system
    system=$(echo "$game" | grep -oE "$rd_home_roms_path/[^/]+" | grep -oE "[^/]+$")
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
    --title "RetroDECK Configurator Utility - Compression in Progress"

  configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "The compression process is complete!"
  configurator_compression_tool_dialog
}

configurator_compression_cleanup_dialog() {
  rd_zenity --icon-name=net.retrodeck.retrodeck --question --no-wrap --cancel-label="No" --ok-label="Yes" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - RetroDECK: Compression Tool" \
  --text="Do you want to remove old files after they are compressed?\n\nClicking \"No\" will leave all files behind which will need to be cleaned up manually and may result in game duplicates showing in the RetroDECK library.\n\nPlease make sure you have a backup of your ROMs before using automatic cleanup."
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
    --title "RetroDECK Configurator - RetroDECK Online Update Check" \
    --text="Online update checks for RetroDECK are currently enabled.\n\nDo you want to disable them?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value "$rd_conf" "update_check" "false" retrodeck "options"
    else # User clicked "Cancel"
      configurator_tools_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Online Update Check" \
    --text="Online update checks for RetroDECK are currently disabled.\n\nDo you want to enable them?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    else # User clicked "Cancel"
      configurator_tools_dialog
    fi
  fi
}

configurator_portmaster_toggle_dialog(){

  if [[ $(get_setting_value "$rd_conf" "portmaster_show" "retrodeck" "options") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - PortMaster Visibility" \
    --text="PortMaster is currently <span foreground='$purple'><b>visible</b></span> in ES-DE. Do you want to hide it?\n\nPlease note that the installed games will still be visible."

    if [ $? == 0 ] # User clicked "Yes"
    then
      portmaster_show "false"
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - PortMaster Visibility" \
      --text="PortMaster is now <span foreground='$purple'><b>hidden</b></span> in ES-DE.\nPlease refresh your game list or restart RetroDECK to see the changes.\n\nIn order to launch PortMaster, you can access it from:\n<span foreground='$purple'><b>Configurator -> Open Component -> PortMaster</b></span>."
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - PortMaster Visibility" \
    --text="PortMaster is currently <span foreground='$purple'><b>hidden</b></span> in ES-DE. Do you want to show it?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      portmaster_show "true"
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - PortMaster Visibility" \
      --text="PortMaster is now <span foreground='$purple'><b>visible</b></span> in ES-DE.\nPlease refresh your game list or restart RetroDECK to see the changes."
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

     while IFS=$'\t' read -r bios_file bios_systems bios_desc required bios_md5 bios_paths; do

      # Expand any embedded shell variables (e.g. $saves_folder or $rd_home_bios_path) with their actual values
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

        log d "Adding BIOS entry: \"$bios_file $bios_systems $bios_file_found $bios_md5_matched $bios_desc $bios_paths $bios_md5\" to the bios_checked_list"

        bios_checked_list=("${bios_checked_list[@]}" "$bios_file" "$bios_systems" "$bios_file_found" "$bios_md5_matched" "$required" "$bios_paths" "$bios_desc" "$bios_md5")

        current_bios=$((current_bios + 1))
        echo "$((current_bios * 100 / total_bios))"

    done < <(jq -r '
          .bios
          | to_entries[]
          | [
              .key,
              (.value.system | if type=="array" then join(", ") elif type=="string" then . else "Unknown" end),
              (.value.description // "No description provided"),
              (.value.required // "No"),
              (.value.md5 | if type=="array" then join(", ") elif type=="string" then . else "Unknown" end),
              (.value.paths | if type=="array" then join(", ") elif type=="string" then . else "$rd_home_bios_path" end)
            ]
          | @tsv
        ' "$bios_checklist")

    log d "Finished checking BIOS files"

    rd_zenity --list --title="RetroDECK Configurator Utility - BIOS Checker" --no-cancel \
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
    --title "RetroDECK Configurator - BIOS Checker - Scanning" \
    --text="The BIOS Checker is scanning for BIOS & Firmware files that RetroDECK recognizes as supported by each system.\n\nPlease note that not all BIOS & Firmware files are necessary for games to work.\n\nBIOS files not recognized by this tool may still function correctly.\n\nSome emulators have additional built-in methods to verify the functionality of BIOS & Firmware files.\n\n<span foreground='$purple'><b>The BIOS Checker is now scanning your BIOS files, please wait...</b></span>\n\n" \
    --width=400 --height=100

  configurator_tools_dialog
}

configurator_version_history_dialog() {
  local version_array=($(xml sel -t -v '//component/releases/release/@version' -n "$rd_metainfo"))
  local all_versions_list=()

  for rd_version in ${version_array[*]}; do
    all_versions_list=("${all_versions_list[@]}" "RetroDECK $rd_version Changelog" "View the changes specific to version $rd_version")
  done

  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroDECK Version History" --cancel-label="Back" \
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

configurator_retrodeck_multiuser_dialog() {
  if [[ $(get_setting_value "$rd_conf" "multi_user_mode" retrodeck "options") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Multi-user Support" \
    --text="Multi-user mode is currently enabled. Do you want to disable it?\n\nIf there is more than one user configured, you will be given a choice of which user to keep as the single RetroDECK user.\n\nThis user's files will be moved to the default locations.\n\nOther users' files will remain in the mutli-user-data folder.\n"

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
    --text="Multi-user mode is currently disabled. Do you want to enable it?\n\nThe current user's saves and states will be backed up and moved to the \"retrodeck/multi-user-data\" folder.\nAdditional users will automatically be stored in their own folder here as they are added."

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
    --title "RetroDECK Configurator - RetroDECK Change Update Branch" \
    --text="You are currently on the stable branch of RetroDECK updates. Would you like to switch to the cooker branch?\n\nAfter installing a cooker build, you may need to remove the \"stable\" branch install of RetroDECK to avoid overlap."

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    else # User clicked "Cancel"
      configurator_developer_dialog
    fi
  else
    set_setting_value "$rd_conf" "update_repo" "RetroDECK" retrodeck "options"
    release_selector
  fi
}

configurator_usb_import_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - Developer Options" --cancel-label="Back" \
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
      configurator_generic_dialog "RetroDeck Configurator - USB Import" "If you have an SD card installed that is not currently configured in RetroDECK, it may show up in this list but may not be suitable for USB import.\n\nPlease select your desired drive carefully."
      choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - USB Migration Tool" --cancel-label="Back" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ ! -z "$choice" ]]; then
        create_dir "$choice/RetroDECK Import"
        start_esde --home "$choice/RetroDECK Import" --create-system-dirs # TODO: this might be broken as in project-neo we are calling es-de via component_launcher that already includes --home argument
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
      configurator_generic_dialog "RetroDeck Configurator - USB Import" "There were no USB devices found."
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
      choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - USB Migration Tool" --cancel-label="Back" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ ! -z "$choice" ]]; then
        if [[ $(verify_space "$choice/RetroDECK Import/ROMs" "$rd_home_roms_path") == "false" || $(verify_space "$choice/RetroDECK Import/BIOS" "$rd_home_bios_path") == "false" ]]; then
          if [[ $(configurator_generic_question_dialog "RetroDECK Configurator Utility - USB Migration Tool" "You MAY not have enough free space to import this ROM/BIOS library.\n\nThis utility only imports new additions from the USB device, so if there are a lot of the same files in both locations you are likely going to be fine\nbut we are not able to verify how much data will be transferred before it happens.\n\nIf you are unsure, please verify your available free space before continuing.\n\nDo you want to continue now?") == "true" ]]; then
            (
            rsync -a --mkpath "$choice/RetroDECK Import/ROMs/"* "$rd_home_roms_path"
            rsync -a --mkpath "$choice/RetroDECK Import/BIOS/"* "$rd_home_bios_path"
            ) |
            rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - USB Import In Progress"
            configurator_generic_dialog "RetroDECK Configurator - USB Migration Tool" "The import process is complete!"
          fi
        else
          (
          rsync -a --mkpath "$choice/RetroDECK Import/ROMs/"* "$rd_home_roms_path"
          rsync -a --mkpath "$choice/RetroDECK Import/BIOS/"* "$rd_home_bios_path"
          ) |
          rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK Configurator Utility - USB Import In Progress"
          configurator_generic_dialog "RetroDECK Configurator - USB Migration Tool" "The import process is complete!"
        fi
      fi
    else
      configurator_generic_dialog "RetroDeck Configurator - USB Import" "There were no USB devices found with an importable folder."
    fi
    configurator_usb_import_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_developer_dialog
  ;;
  esac
}
