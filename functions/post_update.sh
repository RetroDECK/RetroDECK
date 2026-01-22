#!/bin/bash

post_update() {

  # post update script
  log i "Executing post-update script"

  version_being_updated="$version"

  update_rd_conf
  update_component_presets

  export CONFIGURATOR_GUI="zenity"

  # Optional userdata backup prior to update

  local backup_question_response=$(configurator_generic_question_dialog "RetroDECK Update - Backup Userdata" "Would you like to back up some or all RetroDECK userdata prior to the update?")

  if [[ "$backup_question_response" == "true" ]]; then
    configurator_retrodeck_backup_dialog
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

    deploy_helper_files
    build_retrodeck_current_presets
    handle_folder_iconsets "$(get_setting_value "$rd_conf" "iconset" "retrodeck" "options")"
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK - Upgrade Process" \
  --width=400 --height=200 \
  --text="RetroDECK is completing the upgrade. Please check for any background windows or pop-ups that may require your attention.\n\n<span foreground='$purple'><b>Please wait while the setup process completes...</b></span>"

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
