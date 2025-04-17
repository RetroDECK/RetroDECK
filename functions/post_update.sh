#!/bin/bash

post_update() {

  # post update script
  log i "Executing post-update script"

  version_being_updated="$version"

  export CONFIGURATOR_GUI="zenity"

  # Optional userdata backup prior to update

  choice=$(rd_zenity --title "RetroDECK Update - Backup Userdata" --info --no-wrap --ok-label="No Backup" --extra-button="Core Backup" --extra-button="Custom Backup" --extra-button="Complete Backup" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --text="Would you like to backup some or all of the RetroDECK userdata?\n\nChoose one of the following options:\n\n1. Core Backup: Only essential files (such as saves, states, and gamelists).\n\n2. Custom Backup: You will be given the option to select specific folders to backup.\n\n3. Complete Backup: All data, including games and downloaded media, will be backed up.\n\n<span foreground='$purple'><b>PLEASE NOTE: A complete backup may require a significant amount of space.</b></span>\n\n")

  local rc=$?
  if [[ $rc == "0" ]] && [[ -z "$choice" ]]; then # User selected No Backup button
    log i "User chose to not backup prior to update."
  else
    case $choice in
      "Core Backup" )
        log i "User chose to backup core userdata prior to update."
        if ! backup_retrodeck_userdata "core"; then
          log d "Userdata backup failed, giving option to proceed"
          if [[ $(configurator_generic_question_dialog "RetroDECK Update" "Unfortunately the userdata backup process was not successful.\nWould you like to proceed with the upgrade anyway?\n\nRetroDECK will exit if you choose \"No\"") == "false" ]]; then
            log d "User chose to stop post_update process after backup failure"
            exit 1
          fi
        fi
      ;;
      "Custom Backup" )
        log i "User chose to backup some userdata prior to update."
        while read -r config_line; do
          local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
          if [[ ! $current_setting_name =~ (rdhome|sdcard|backups_folder) ]]; then # Ignore these locations
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

        if ! backup_retrodeck_userdata "custom" "${choices[@]}"; then # Expand array of choices into individual arguments
          log d "Userdata backup failed, giving option to proceed"
          if [[ $(configurator_generic_question_dialog "RetroDECK Update" "Unfortunately the userdata backup process was not successful.\nWould you like to proceed with the upgrade anyway?\n\nRetroDECK will exit if you choose \"No\"") == "false" ]]; then
            log d "User chose to stop post_update process after backup failure"
            exit 1
          fi
        fi
      ;;
      "Complete Backup" )
        log i "User chose to backup all userdata prior to update."
        if ! backup_retrodeck_userdata "complete"; then
          log d "Userdata backup failed, giving option to proceed"
          if [[ $(configurator_generic_question_dialog "RetroDECK Update" "Unfortunately the userdata backup process was not successful.\nWould you like to proceed with the upgrade anyway?\n\nRetroDECK will exit if you choose \"No\"") == "false" ]]; then
            log d "User chose to stop post_update process after backup failure"
            exit 1
          fi
        fi
      ;;
    esac
  fi

  # Start of post_update actions

  # The following commands are run every time.

  if [[ -d "$XDG_DATA_HOME/dolphin-emu/Load/DynamicInputTextures" ]]; then # Refresh installed textures if they have been enabled
    log i "Refreshing installed textures for Dolphin..."
    rsync -rlD --mkpath "/app/retrodeck/extras/DynamicInputTextures/" "$XDG_DATA_HOME/dolphin-emu/Load/DynamicInputTextures/" && log i "Done"
  fi
  if [[ -d "$XDG_DATA_HOME/primehack/Load/DynamicInputTextures" ]]; then # Refresh installed textures if they have been enabled
    log i "Refreshing installed textures for Dolphin..."
    rsync -rlD --mkpath "/app/retrodeck/extras/DynamicInputTextures/" "$XDG_DATA_HOME/primehack/Load/DynamicInputTextures/" && log i "Done"
  fi

  if [[ ! -z $(find "$HOME/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") || ! -z $(find "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") ]]; then # If RetroDECK controller profile has been previously installed
    install_retrodeck_controller_profile
  fi

  retroarch_updater
  update_splashscreens
  deploy_helper_files
  build_retrodeck_current_presets
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK - Upgrade Process" \
  --width=400 --height=200 \
  --text="RetroDECK is finishing up the upgrading process, please be patient.\n\n<span foreground='$purple' size='larger'><b>NOTICE - If the process is taking too long:</b></span>\n\nSome windows might be running in the background that require your attention: pop-ups from emulators or the upgrade itself that need your input to continue."

  conf_read
  version="$hard_version"
  conf_write

  if grep -qF "cooker" <<< "$hard_version"; then
    changelog_dialog "$(echo "$version" | cut -d'-' -f2)"
  else
    changelog_dialog "$version"
  fi

  unset CONFIGURATOR_GUI

  log i "Upgrade process completed successfully."
}
