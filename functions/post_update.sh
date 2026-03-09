#!/bin/bash

post_update() {
  # Run post-update actions after a RetroDECK application version upgrade.
  # USAGE: post_update "$version_being_updated"

  local version_being_updated="$1"

  log i "Checking for core application and component updates..."

  if [[ ! "$hard_version" == "$version_being_updated" ]]; then # Core application update
    local core_updated=true
    update_rd_conf

    if configurator_generic_question_dialog "RetroDECK Update - Backup Userdata" "Would you like to back up some or all RetroDECK userdata prior to the update?"; then
      configurator_retrodeck_backup_dialog
    fi
  
    # Legacy pre-0.5.0b save migration (core application level, not component level)
    if check_version_is_older_than "$version_being_updated" "0.5.0b"; then
      log d "Version is older than 0.5.0b, executing save migration"
      save_migration
    fi

    # Legacy variable aliases for pre-0.10.0b component update scripts
    if check_version_is_older_than "$version_being_updated" "0.10.0b"; then
      log d "Version is older than 0.10.0b, defining legacy paths for proper post_update processing."
      export rdhome="$rd_home_path"
      export roms_folder="$roms_path"
      export saves_folder="$saves_path"
      export states_folder="$states_path"
      export shaders_folder="$shaders_path"
      export bios_folder="$bios_path"
      export backups_folder="$backups_path"
      export media_folder="$downloaded_media_path"
      export themes_folder="$themes_path"
      export logs_folder="$logs_path"
      export screenshots_folder="$screenshots_path"
      export mods_folder="$mods_path"
      export texture_packs_folder="$texture_packs_path"
      export borders_folder="$borders_path"
      export cheats_folder="$cheats_path"
    fi
  fi

  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --pulsate --no-cancel --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK - Upgrade Process" \
    --width=400 --height=200 \
    --text="RetroDECK is completing the upgrade. Please check for any background windows or pop-ups that may require your attention.\n\n<span foreground='$purple'><b>Please wait while the setup process completes...</b></span>" \
    < "$progress_pipe" &
  local zenity_pid=$!

  exec 3>"$progress_pipe"

  if [[ "$core_updated" == true ]]; then
    echo "# RetroDECK is completing the upgrade. Please check for any background windows or pop-ups that may require your attention.\n\n<span foreground='$purple'><b>Please wait while the setup process completes...</b></span>\n\nRunning RetroDECK core updates..." >&3
    local framework_handler="_post_update::framework"
    if declare -F "$framework_handler" > /dev/null; then
      log d "Running post-update handler for framework"
      "$framework_handler" "$version_being_updated"
    fi
    echo "# RetroDECK is completing the upgrade. Please check for any background windows or pop-ups that may require your attention.\n\n<span foreground='$purple'><b>Please wait while the setup process completes...</b></span>\n\nDeploying helper files..." >&3
    deploy_helper_files
    echo "# RetroDECK is completing the upgrade. Please check for any background windows or pop-ups that may require your attention.\n\n<span foreground='$purple'><b>Please wait while the setup process completes...</b></span>\n\nApplying RetroDECK icons..." >&3
    rsync -rlD --delete --mkpath "/app/retrodeck/graphics/folder-iconsets/" "$XDG_CONFIG_HOME/retrodeck/graphics/folder-iconsets/"
    handle_folder_iconsets "$iconset"
  fi

  echo "# RetroDECK is completing the upgrade. Please check for any background windows or pop-ups that may require your attention.\n\n<span foreground='$purple'><b>Please wait while the setup process completes...</b></span>\n\nLooking for component updates..." >&3
  run_component_updates "$version_being_updated"

  echo "100" >&3

  exec 3>&-
  wait "$zenity_pid" 2>/dev/null
  rm -f "$progress_pipe"

  if [[ "$core_updated" == true ]]; then
    set_setting_value "$rd_conf" "version" "$hard_version" "retrodeck"
    local changelog_version
    if [[ ! "$hard_version" =~ ^[0-9] ]]; then
      if [[ "$hard_version" =~ ([0-9]+\.[0-9]+[0-9.]*[a-z]*) ]]; then
        changelog_version="${BASH_REMATCH[1]}"
      else
        log e "Could not extract version from: $hard_version. No way to show changelog."
      fi
    else
      changelog_version="$hard_version"
    fi
    changelog_dialog "$changelog_version"

    log i "Upgrade process completed successfully."
  fi
}
