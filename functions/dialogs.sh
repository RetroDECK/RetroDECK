#!/bin/bash

debug_dialog() {
  # This function is for displaying commands run by the Configurator without actually running them
  # USAGE: debug_dialog "command"

  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - Debug Dialog" \
  --text="$1"
}

configurator_process_complete_dialog() {
  # This dialog shows when a process is complete.
  # USAGE: configurator_process_complete_dialog "process text"
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Quit" --extra-button="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - Process Complete" \
  --text="The process of $1 is now complete.\n\nYou may need to quit and restart RetroDECK for your changes to take effect\n\nClick OK to return to the Main Menu or Quit to return to RetroDECK."

  if [ ! $? == 0 ] # OK button clicked
  then
      configurator_welcome_dialog
  fi
}

configurator_generic_dialog() {
  # This dialog is for showing temporary messages before another process happens.
  # USAGE: configurator_generic_dialog "title text" "info text"
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "$1" \
  --text="$2"
}

configurator_generic_question_dialog() {
  # This dialog provides a generic dialog for getting a response from a user.
  # USAGE: $(configurator_generic_question_dialog "title text" "action text")
  # This function will return a "true" if the user clicks "Yes", and "false" if they click "No".
  choice=$(zenity --title "RetroDECK - $1" --question --no-wrap --cancel-label="No" --ok-label="Yes" \
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
  choice=$(zenity --title "RetroDECK Configurator Utility - Moving $1 folder" --info --no-wrap --ok-label="Back" --extra-button="Internal Storage" --extra-button="SD Card" --extra-button="Custom Location" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="$2")

  local rc=$?
  if [[ $rc == "0" ]] && [[ -z "$choice" ]]; then
    echo "Back"
  else
    echo $choice
  fi
}

configurator_reset_confirmation_dialog() {
  # This dialog provides a confirmation for any reset functions, before the reset is actually performed.
  # USAGE: $(configurator_reset_confirmation_dialog "emulator being reset" "action text")
  # This function will return a "true" if the user clicks Confirm, and "false" if they click Cancel.
  choice=$(zenity --title "RetroDECK Configurator Utility - Reset $1" --question --no-wrap --cancel-label="Cancel" --ok-label="Confirm" \
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
  local source_root="$(echo $dir_to_move | sed -e 's/\(.*\)\/retrodeck\/.*/\1/')" # The root path of the folder, excluding retrodeck/<folder name>. So /home/deck/retrodeck/roms becomes /home/deck
  if [[ ! "$rd_dir_name" == "rdhome" ]]; then # If a sub-folder is being moved, find it's path without the source_root. So /home/deck/retrodeck/roms becomes retrodeck/roms
    local rd_dir_path="$(echo "$dir_to_move" | sed "s/.*\(retrodeck\/.*\)/\1/; s/\/$//")"
  else # Otherwise just set the retrodeck root folder
    local rd_dir_path="$(basename $dir_to_move)"
  fi

  if [[ -d "$dir_to_move" ]]; then # If the directory selected to move already exists at the expected location pulled from retrodeck.cfg
    choice=$(configurator_destination_choice_dialog "RetroDECK Data" "Please choose a destination for the $(basename $dir_to_move) folder.")
    case $choice in

    "Internal Storage" | "SD Card" | "Custom Location" ) # If the user picks a location
      if [[ "$choice" == "Internal Storage" ]]; then # If the user wants to move the folder to internal storage, set the destination target as HOME
        local dest_root="$HOME"
      elif [[ "$choice" == "SD Card" ]]; then # If the user wants to move the folder to the predefined SD card location, set the target as sdcard from retrodeck.cfg
        local dest_root="$sdcard"
      else
        configurator_generic_dialog "RetroDECK Configurator - Move Folder" "Select the parent folder you would like to store the $(basename $dir_to_move) folder in."
        local dest_root=$(directory_browse "RetroDECK directory location") # Set the destination root as the selected custom location
      fi

      if [[ (! -z "$dest_root") && ( -w "$dest_root") ]]; then # If user picked a destination and it is writable
        if [[ (-d "$dest_root/$rd_dir_path") && (! -L "$dest_root/$rd_dir_path") && (! $rd_dir_name == "rdhome") ]] || [[ "$(realpath $dir_to_move)" == "$dest_root/$rd_dir_path" ]]; then # If the user is trying to move the folder to where it already is (excluding symlinks that will be unlinked)
          configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The $(basename $dir_to_move) folder is already at that location, please pick a new one."
          configurator_move_folder_dialog "$rd_dir_name"
        else
          if [[ $(verify_space "$(echo $dir_to_move | sed 's/\/$//')" "$dest_root") ]]; then # Make sure there is enough space at the destination
            configurator_generic_dialog "RetroDECK Configurator - Move Folder" "Moving $(basename $dir_to_move) folder to $choice"
            unlink "$dest_root/$rd_dir_path" # In case there is already a symlink at the picked destination
            move "$dir_to_move" "$dest_root/$rd_dir_path"
            if [[ -d "$dest_root/$rd_dir_path" ]]; then # If the move succeeded
              declare -g "$rd_dir_name=$dest_root/$rd_dir_path" # Set the new path for that folder variable in retrodeck.cfg
              if [[ "$rd_dir_name" == "rdhome" ]]; then # If the whole retrodeck folder was moved...
                prepare_emulator "postmove" "retrodeck"
              fi
              prepare_emulator "postmove" "all" # Update all the appropriate emulator path settings
              conf_write # Write the settings to retrodeck.cfg
              if [[ -z $(ls -1 "$source_root/retrodeck") ]]; then # Cleanup empty old_path/retrodeck folder if it was left behind
                rmdir "$source_root/retrodeck"
              fi
              configurator_process_complete_dialog "moving the RetroDECK data directory to internal storage"
            else
              configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The moving process was not completed, please try again."
            fi
          else # If there isn't enough space in the picked destination
            zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - Move Directories" \
            --text="The destination directory you have selected does not have enough free space for the files you are trying to move.\n\nPlease select a new destination or free up some space."
          fi
        fi
      else # If the user didn't pick any custom destination, or the destination picked is unwritable
        if [[ ! -z "$dest_root" ]]; then
          configurator_generic_dialog "RetroDECK Configurator - Move Folder" "No destination was chosen, so no files have been moved."
        else
          configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The chosen destination is not writable.\nNo files have been moved.\n\nThis can happen when trying to select a location that RetroDECK does not have permission to write.\nThis can normally be fixed by adding the desired path to the RetroDECK permissions with Flatseal."
        fi
      fi
    ;;

    esac
  else # The folder to move was not found at the path pulled from retrodeck.cfg and it needs to be reconfigured manually.
    configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The $(basename $dir_to_move) folder was not found at the expected location.\n\nThis may have happened if the folder was moved manually.\n\nPlease select the current location of the folder."
    dir_to_move=$(directory_browse "RetroDECK $(basename $dir_to_move) directory location")
    declare -g "$rd_dir_name=$dir_to_move"
    prepare_emulator "postmove" "all"
    conf_write
    configurator_generic_dialog "RetroDECK Configurator - Move Folder" "RetroDECK $(basename $dir_to_move) folder now configured at\n$dir_to_move."
    configurator_move_folder_dialog "$rd_dir_name"
  fi
}

changelog_dialog() {
  # This function will pull the changelog notes from the version it is passed (which must match the appdata version tag) from the net.retrodeck.retrodeck.appdata.xml file
  # The function also accepts "all" as a version, and will print the entire changelog
  # USAGE: changelog_dialog "version"

  if [[ "$1" == "all" ]]; then
    xml sel -t -m "//release" -v "concat('RetroDECK version: ', @version)" -n -v "description" -n $rd_appdata | awk '{$1=$1;print}' | sed -e '/./b' -e :n -e 'N;s/\n$//;tn' > "/var/config/retrodeck/changelog.txt"

    zenity --icon-name=net.retrodeck.retrodeck --text-info --width=1200 --height=720 \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Changelogs" \
    --filename="/var/config/retrodeck/changelog.txt"
  else
    local version_changelog=$(xml sel -t -m "//release[@version='$1']/description" -v . -n $rd_appdata | tr -s '\n' | sed 's/^\s*//')

    echo -e "In RetroDECK version $1, the following changes were made:\n$version_changelog" > "/var/config/retrodeck/changelog-partial.txt" 
    "$version_changelog" >> "/var/config/retrodeck/changelog-partial.txt"

    zenity --icon-name=net.retrodeck.retrodeck --text-info --width=1200 --height=720 \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Changelogs" \
    --filename="/var/config/retrodeck/changelog-partial.txt"
    fi
}

get_cheevos_token_dialog() {
  # This function will return a RetroAchvievements token from a valid username and password, will return "login failed" otherwise
  # USAGE: get_cheevos_token_dialog

  local cheevos_info=$(zenity --forms --title="Cheevos" \
  --text="Username and password." \
  --separator="^" \
  --add-entry="Username" \
  --add-password="Password")

  IFS='^' read -r cheevos_username cheevos_password < <(printf '%s\n' "$cheevos_info")
  local cheevos_response=$(curl --silent --data "r=login&u=$cheevos_username&p=$cheevos_password" $RA_API_URL)
  local cheevos_success=$(echo $cheevos_response | jq .Success | tr -d '"')
  local cheevos_token=$(echo $cheevos_response | jq .Token | tr -d '"')
  local cheevos_login_timestamp=$(date +%s)
  if [[ "$cheevos_success" == "true" ]]; then
    echo "$cheevos_username,$cheevos_token,$cheevos_login_timestamp"
  else
    echo "failed"
  fi
}

desktop_mode_warning() {
  # This function is a generic warning for issues that happen when running in desktop mode.
  # Running in desktop mode can be verified with the following command: if [[ ! $XDG_CURRENT_DESKTOP == "gamescope" ]]; then
  # This function will check if desktop mode is currently being used and if the warning has not been disabled, and show it if needed.
  # USAGE: desktop_mode_warning

  if [[ $(check_desktop_mode) == "true" && $desktop_mode_warning == "true" ]]; then
    choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Never show this again" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Desktop Mode Warning" \
    --text="You appear to be running RetroDECK in the Steam Deck's Desktop mode!\n\nSome functions of RetroDECK may not work properly in Desktop mode, such as the Steam Deck's normal controls.\n\nRetroDECK is best enjoyed in Game mode!\n\nDo you still want to proceed?")
    rc=$? # Capture return code, as "Yes" button has no text value
    if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
      if [[ $choice == "No" ]]; then
        exit 1
      elif [[ $choice == "Never show this again" ]]; then
        set_setting_value $rd_conf "desktop_mode_warning" "false" retrodeck "options" # Store desktop mode warning variable for future checks
      fi
    fi
  fi
}

low_space_warning() {
  # This function will verify that the drive with the $HOME path on it has at least 10% space free, so the user can be warned before it fills up
  # USAGE: low_space_warning

  if [[ $low_space_warning == "true" ]]; then
    local used_percent=$(df --output=pcent "$HOME" | tail -1 | tr -d " " | tr -d "%")
    if [[ "$used_percent" -ge 90 && -d "$HOME/retrodeck" ]]; then # If there is any RetroDECK data on the main drive to move
      choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK" --extra-button="Never show this again" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Low Space Warning" \
      --text="Your main drive is over 90% full!\n\nIf your drive fills completely this can lead to data loss or system crash.\n\nPlease consider moving some RetroDECK folders to other storage locations using the Configurator.")
      if [[ $choice == "Never show this again" ]]; then
          set_setting_value $rd_conf "low_space_warning" "false" retrodeck "options" # Store low space warning variable for future checks
      fi
    fi
  fi
}
