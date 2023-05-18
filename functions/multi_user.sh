#!/bin/bash

multi_user_set_default_dialog() {
  chosen_user="$1"
  choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="No and don't ask again" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Default User" \
  --text="Would you like to set $chosen_user as the default user?\n\nIf the current user cannot be determined from the system, the default will be used.\nThis normally only happens in Desktop Mode.\n\nIf you would like to be asked which user is playing every time, click \"No and don't ask again\"")
  rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
    if [[ $choice == "No and don't ask again" ]]; then
      set_setting_value $rd_conf "ask_default_user" "false" retrodeck "options"
    fi
  else # User clicked "Yes"
    set_setting_value $rd_conf "default_user" "$chosen_user" retrodeck "options"
  fi
}

multi_user_choose_current_user_dialog() {
full_userlist=()
while IFS= read -r user
do
full_userlist=("${full_userlist[@]}" "$user")
done < <(ls -1 "$multi_user_data_folder")

chosen_user=$(zenity \
  --list --width=1200 --height=720 \
  --ok-label="Select User" \
  --text="Choose the current user:" \
  --column "Steam Username" --print-column=1 \
  "${full_userlist[@]}")

if [[ ! -z $chosen_user && -z $default_user && $ask_default_user == "true" ]]; then
  multi_user_set_default_dialog "$chosen_user"
fi
echo "$chosen_user"
}

multi_user_enable_multi_user_mode() {
  if [[ -z "$SteamAppUser" ]]; then
    configurator_generic_dialog "RetroDECK Multi-User Mode" "The Steam username of the current user could not be determined from the system.\n\nThis can happen when running in Desktop mode.\n\nYou will be asked to specify the Steam username (not profile name) of the current user in the next dialog."
  fi
  if [[ -d "$multi_user_data_folder" && $(ls -1 "$multi_user_data_folder" | wc -l) -gt 0 ]]; then # If multi-user data folder exists from prior use and is not empty
    if [[ -d "$multi_user_data_folder/$SteamAppUser" ]]; then # Current user has an existing save folder
      configurator_generic_dialog "RetroDECK Multi-User Mode" "The current user $SteamAppUser has an existing folder in the multi-user data folder.\n\nThe saves here are likely older than the ones currently used by RetroDECK.\n\nThe old saves will be backed up to $backups_folder and the current saves will be loaded into the multi-user data folder."
      mkdir -p "$backups_folder"
      tar -C "$multi_user_data_folder" -cahf "$backups_folder/multi-user-backup_$SteamAppUser_$(date +"%Y_%m_%d").zip" "$SteamAppUser"
      rm -rf "$multi_user_data_folder/$SteamAppUser" # Remove stale data after backup
    fi
  fi
  set_setting_value $rd_conf "multi_user_mode" "true" retrodeck "options"
  multi_user_determine_current_user
  if [[ -d "$multi_user_data_folder/$SteamAppUser" ]]; then
    configurator_process_complete_dialog "enabling multi-user support"
  else
    configurator_generic_dialog "RetroDECK Multi-User Mode" "It looks like something went wrong while enabling multi-user mode."
  fi
}

multi_user_disable_multi_user_mode() {
  if [[ $(ls -1 "$multi_user_data_folder" | wc -l) -gt 1 ]]; then
    full_userlist=()
    while IFS= read -r user
    do
    full_userlist=("${full_userlist[@]}" "$user")
    done < <(ls -1 "$multi_user_data_folder")

    single_user=$(zenity \
      --list --width=1200 --height=720 \
      --ok-label="Select User" \
      --text="Choose the current user:" \
      --column "Steam Username" --print-column=1 \
      "${full_userlist[@]}")

    if [[ ! -z "$single_user" ]]; then # Single user was selected
      multi_user_return_to_single_user "$single_user"
      set_setting_value $rd_conf "multi_user_mode" "false" retrodeck "options"
      configurator_process_complete_dialog "disabling multi-user support"
    else
      configurator_generic_dialog "RetroDECK Multi-User Mode" "No single user was selected, please try the process again."
      configurator_retrodeck_multiuser_dialog
    fi
  else
    single_user=$(ls -1 "$multi_user_data_folder")
    multi_user_return_to_single_user "$single_user"
    set_setting_value $rd_conf "multi_user_mode" "false" retrodeck "options"
    configurator_process_complete_dialog "disabling multi-user support"
  fi
}

multi_user_determine_current_user() {
  if [[ $(get_setting_value $rd_conf "multi_user_mode" retrodeck "options") == "true" ]]; then # If multi-user environment is enabled in rd_conf
    if [[ -d "$multi_user_data_folder" ]]; then
      if [[ ! -z $SteamAppUser ]]; then # If running in Game Mode and this variable exists
        if [[ -z $(ls -1 "$multi_user_data_folder" | grep "$SteamAppUser") ]]; then
          multi_user_setup_new_user
        else
          multi_user_link_current_user_files
        fi
      else # Unable to find Steam user ID
        if [[ $(ls -1 "$multi_user_data_folder" | wc -l) -gt 1 ]]; then
          if [[ -z $default_user ]]; then # And a default user is not set
            configurator_generic_dialog "RetroDECK Multi-User Mode" "The current user could not be determined from the system, and there are multiple users registered.\n\nPlease select which user is currently playing in the next dialog."
            SteamAppUser=$(multi_user_choose_current_user_dialog)
            if [[ ! -z $SteamAppUser ]]; then # User was chosen from dialog
              multi_user_link_current_user_files
            else
              configurator_generic_dialog "RetroDECK Multi-User Mode" "No user was chosen, RetroDECK will launch with the files from the user who played most recently."
            fi
          else # The default user is set
            if [[ ! -z $(ls -1 $multi_user_data_folder | grep "$default_user") ]]; then # Confirm user data folder exists
              SteamAppUser=$default_user
              multi_user_link_current_user_files
            else # Default user has no data folder, something may have gone horribly wrong. Setting up as a new user.
              multi_user_setup_new_user
            fi
          fi
        else # If there is only 1 user in the userlist, default to that user
          SteamAppUser=$(ls -1 $multi_user_data_folder)
          multi_user_link_current_user_files
        fi
      fi
    else # If the userlist file doesn't exist yet, create it and add the current user
      if [[ ! -z "$SteamAppUser" ]]; then
        multi_user_setup_new_user
      else # If running in Desktop mode for the first time
        configurator_generic_dialog "RetroDECK Multi-User Mode" "The current user could not be determined from the system and there is no existing userlist.\n\nPlease enter the Steam account username (not profile name) into the next dialog, or run RetroDECK in game mode."
        if zenity --entry \
          --title="Specify Steam username" \
          --text="Enter Steam username:"
        then # User clicked "OK"
          SteamAppUser="$?"
          if [[ ! -z "$SteamAppUser" ]]; then
            multi_user_setup_new_user
          else # But dialog box was blank
            configurator_generic_dialog "RetroDECK Multi-User Mode" "No username was entered, so multi-user data folder cannot be created.\n\nDisabling multi-user mode, please try the process again."
            set_setting_value $rd_conf "multi_user_mode" "false" retrodeck "options"
          fi
        else # User clicked "Cancel"
          configurator_generic_dialog "RetroDECK Multi-User Mode" "Cancelling multi-user mode activation."
          set_setting_value $rd_conf "multi_user_mode" "false" retrodeck "options"
        fi
      fi
    fi
  else
    configurator_generic_dialog "RetroDECK Multi-User Mode" "Multi-user mode is not currently enabled"
  fi
}

multi_user_return_to_single_user() {
  single_user="$1"
  echo "Returning to single-user mode for $single_user"
  unlink "$saves_folder"
  unlink "$states_folder"
  unlink "$rd_conf"
  mv -f "$multi_user_data_folder/$SteamAppUser/config/retrodeck/retrodeck.cfg" "$rd_conf"
  # RetroArch one-offs, because it has so many folders that should be shared between users
  unlink "/var/config/retroarch/retroarch.cfg"
  unlink "/var/config/retroarch/retroarch-core-options.cfg"
  mv -f "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch.cfg" "/var/config/retroarch/retroarch.cfg"
  mv -f "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch-core-options.cfg" "/var/config/retroarch/retroarch-core-options.cfg"
  # XEMU one-offs, because it stores its config in /var/data, not /var/config like everything else
  unlink "/var/config/xemu"
  unlink "/var/data/xemu/xemu"
  mkdir -p "/var/config/xemu"
  mv -f "$multi_user_data_folder/$single_user/config/xemu"/{.[!.],}* "/var/config/xemu"
  dir_prep "/var/config/xemu" "/var/data/xemu/xemu"
  mkdir -p "$saves_folder"
  mkdir -p "$states_folder"
  mv -f "$multi_user_data_folder/$single_user/saves"/{.[!.],}* "$saves_folder"
  mv -f "$multi_user_data_folder/$single_user/states"/{.[!.],}* "$states_folder"
  for emu_conf in $(find "$multi_user_data_folder/$single_user/config" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
  do
    if [[ ! -z $(grep "^$emu_conf$" "$multi_user_emulator_config_dirs") ]]; then
      unlink "/var/config/$emu_conf"
      mkdir -p "/var/config/$emu_conf"
      mv -f "$multi_user_data_folder/$single_user/config/$emu_conf"/{.[!.],}* "/var/config/$emu_conf"
    fi
  done
  rm -r "$multi_user_data_folder/$single_user" # Should be empty, omitting -f for safety
}

multi_user_setup_new_user() {
  # TODO: RPCS3 one-offs
  echo "Setting up new user"
  unlink "$saves_folder"
  unlink "$states_folder"
  dir_prep "$multi_user_data_folder/$SteamAppUser/saves" "$saves_folder"
  dir_prep "$multi_user_data_folder/$SteamAppUser/states" "$states_folder"
  mkdir -p "$multi_user_data_folder/$SteamAppUser/config/retrodeck"
  cp -L "$rd_conf" "$multi_user_data_folder/$SteamAppUser/config/retrodeck/retrodeck.cfg" # Copy existing rd_conf file for new user.
  rm -f "$rd_conf"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/config/retrodeck/retrodeck.cfg" "$rd_conf"
  mkdir -p "$multi_user_data_folder/$SteamAppUser/config/retroarch"
  if [[ ! -L "/var/config/retroarch/retroarch.cfg" ]]; then
    mv "/var/config/retroarch/retroarch.cfg" "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch.cfg"
    mv "/var/config/retroarch/retroarch-core-options.cfg" "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch-core-options.cfg"
  else
    cp "$emuconfigs/retroarch/retroarch.cfg" "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch.cfg"
    cp "$emuconfigs/retroarch/retroarch-core-options.cfg" "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch-core-options.cfg"
    set_setting_value "$raconf" "savefile_directory" "$saves_folder" "retroarch"
    set_setting_value "$raconf" "savestate_directory" "$states_folder" "retroarch"
    set_setting_value "$raconf" "screenshot_directory" "$screenshots_folder" "retroarch"
  fi
  ln -sfT "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch.cfg" "/var/config/retroarch/retroarch.cfg"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch-core-options.cfg" "/var/config/retroarch/retroarch-core-options.cfg"
  for emu_conf in $(find "/var/config" -mindepth 1 -maxdepth 1 -type l -printf '%f\n') # For all the config folders already linked to a different user
  do
    if [[ ! -z $(grep "^$emu_conf$" "$multi_user_emulator_config_dirs") ]]; then
      unlink "/var/config/$emu_conf"
      prepare_emulator "reset" "$emu_conf"
    fi
  done
  for emu_conf in $(find "/var/config" -mindepth 1 -maxdepth 1 -type d -printf '%f\n') # For all the currently non-linked config folders, like from a newly-added emulator
  do
    if [[ ! -z $(grep "^$emu_conf$" "$multi_user_emulator_config_dirs") ]]; then
      dir_prep "$multi_user_data_folder/$SteamAppUser/config/$emu_conf" "/var/config/$emu_conf"
    fi
  done
}

multi_user_link_current_user_files() {
  echo "Linking existing user"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/saves" "$saves_folder"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/states" "$states_folder"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/config/retrodeck/retrodeck.cfg" "$rd_conf"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch.cfg" "/var/config/retroarch/retroarch.cfg"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch-core-options.cfg" "/var/config/retroarch/retroarch-core-options.cfg"
  for emu_conf in $(find "/var/config" -mindepth 1 -maxdepth 1 -type d -printf '%f\n') # Find any new emulator config folders from last time this user played
  do
    if [[ ! -z $(grep "^$emu_conf$" "$multi_user_emulator_config_dirs") ]]; then
      dir_prep "$multi_user_data_folder/$SteamAppUser/config/$emu_conf" "/var/config/$emu_conf"
    fi
  done
  for emu_conf in $(find "/var/config" -mindepth 1 -maxdepth 1 -type l -printf '%f\n')
  do
    if [[ ! -z $(grep "^$emu_conf$" "$multi_user_emulator_config_dirs") ]]; then
      if [[ -d "$multi_user_data_folder/$SteamAppUser/config/$emu_conf" ]]; then # If the current user already has a config folder for this emulator
        ln -sfT "$multi_user_data_folder/$SteamAppUser/config/$emu_conf" "retrodeck/config/$emu_conf"
      else # If the current user doesn't have a config folder for this emulator, init it and then link it
        prepare_emulator "reset" "$emu_conf"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/$emu_conf" "/var/config/$emu_conf"
      fi
    fi
  done
}
