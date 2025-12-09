#!/bin/bash

post_update() {

  # post update script
  log i "Executing post-update script"

  version_being_updated="$version"

  update_rd_conf
  update_component_presets

  export CONFIGURATOR_GUI="zenity"

  # Optional userdata backup prior to update

  choice=$(rd_zenity --title "RetroDECK Update - 🗄️ Backup Userdata 🗄️" --info --no-wrap --ok-label="No Backup" --extra-button="Core Backup" --extra-button="Custom Backup" --extra-button="Complete Backup" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --text="Would you like to back up some or all RetroDECK userdata?\n\n\Please choose a backup method for your RetroDECK userdata:\n\n\🧩 Core Backup:\nOnly essential files will be saved, including game saves, save states, and gamelists.\n\n\🎛️ Custom Backup:\nSelect specific folders to include in your backup. Ideal for tailored data preservation.\n\n\📦 Complete Backup:\nAll userdata will be backed up, including games and downloaded media.\n\n\<span foreground='purple'>⚠️ <b>WARNING:</b> A complete backup may require a very large amount of storage space. ⚠️</span>")

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
          if [[ ! $current_setting_name =~ (rd_home_path|sdcard|backups_path) ]]; then # Ignore these locations
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

  if [[ $(check_version_is_older_than "$version_being_updated" "0.5.0b") == "true" ]]; then # If updating from prior to save sorting change at 0.5.0b
    log d "Version is older than 0.5.0b, executing save migration"
    save_migration
  fi

  if [[ $(check_version_is_older_than "$version_being_updated" "0.10.0b") == "true" ]]; then # If updating from prior to save sorting change at 0.10.0b

    log d "Version is older than 0.10.0b, defining legacy paths for proper post_update processing."
    rdhome="$rd_home_path"
    roms_folder="$roms_path"
    saves_folder="$saves_path"
    states_folder="$states_path"
    shaders_folder="$shaders_path"
    bios_folder="$bios_path"
    backups_folder="$backups_path"
    media_folder="$downloaded_media_path"
    themes_folder="$themes_path"
    logs_folder="$logs_path"
    screenshots_folder="$screenshots_path"
    mods_folder="$mods_path"
    texture_packs_folder="$texture_packs_path"
    borders_folder="$borders_path"
    cheats_folder="$cheats_path"

  fi

  # Everything within the following ( <code> ) will happen behind the Zenity dialog. The save migration was a long process so it has its own individual dialogs.
  (
    source "/app/retrodeck/components/framework/component_update.sh"
    
    while read -r component_update_file; do
      source "$component_update_file"
    done < <(find "$rd_components" -mindepth 2 -maxdepth 2 -type f -iname "component_update.sh" -not -path "/app/retrodeck/components/framework/*")

    #######################################
    # These actions happen at every update
    #######################################

    if [[ ! -z $(find "$HOME/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") || ! -z $(find "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") ]]; then # If RetroDECK controller profile has been previously installed
      install_retrodeck_controller_profile
    fi

    update_splashscreens
    deploy_helper_files
    build_retrodeck_current_presets
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK - Upgrade Process" \
  --width=400 --height=200 \
  --text="RetroDECK is completing the upgrade. Please check for any background windows or pop-ups that may require your attention.\n\n⏳ <span foreground='$purple'><b>Please wait while the setup process completes...</b></span> ⏳"

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
