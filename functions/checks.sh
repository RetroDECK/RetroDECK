#!/bin/bash

check_network_connectivity() {
  # Check for network availability by testing multiple remote targets.
  # Returns 0 if any target is reachable, 1 if none are.
  # USAGE: if check_network_connectivity; then

  local target
  for target in "$remote_network_target_1" "$remote_network_target_2" "$remote_network_target_3"; do
    if curl --silent --head --max-time 5 --output /dev/null "$target" 2>/dev/null; then
      return 0
    fi
  done

  return 1
}

check_desktop_mode() {
  # This function will do a basic check of if we are running in Steam Deck game mode or not

  if [[ ! "$XDG_CURRENT_DESKTOP" == "gamescope" ]]; then
    return 0
  else
    return 1
  fi
}

check_low_space() {
  # This function will verify that the drive with the $HOME path on it has at least 10% space free, so the user can be warned before it fills up
  # USAGE: low_space_warning

  if [[ $low_space_warning == "true" ]]; then
    local used_percent=$(df --output=pcent "$HOME" | tail -1 | tr -d " " | tr -d "%")
    if [[ "$used_percent" -ge 90 && -d "$HOME/retrodeck" ]]; then # If there is any RetroDECK data on the main drive to move
      choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK"  --extra-button="Never show again" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK - Warning: Low Space" \
      --text="Your main drive is over <span foreground='$purple'>90%</span> full!\n\nIf it fills up completely, you could lose data or experience a system crash.\n\nPlease move some RetroDECK folders to other storage locations using the Configurator or free up some space.")
      if [[ $choice =~ "Never show again" ]]; then
        log i "Selected: \"Never show this again\""
        set_setting_value "$rd_conf" "low_space_warning" "false" retrodeck "options" # Store low space warning variable for future checks
      fi
    fi
    log i "Selected: \"OK\""
  fi
}

check_is_steam_deck() {
  # This function will check the internal product ID for the Steam Deck codename and return 0 if RetroDECK is running on a real Deck

  if [[ $(cat "/sys/devices/virtual/dmi/id/product_name") =~ ^(Jupiter|Galileo)$ ]]; then
    return 0
  else
    return 1
  fi
}

check_for_version_update() {
  # REBUILD
  # This function will perform a basic online version check and alert the user if there is a new version available.

  log d "Entering funtcion check_for_version_update"

  wget -q --spider "https://api.github.com/repos/$git_organization_name/$update_repo/releases/latest"

  if [ $? -eq 0 ]; then
  
    # Check if $selected_branch is not set
    if [[ -z "$selected_branch" ]]; then
        # If $selected_branch is not set, get the latest release tag from GitHub API
        local online_version=$(curl --silent "https://api.github.com/repos/$git_organization_name/$update_repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        local online_version=$(curl -s "https://api.github.com/repos/$git_organization_name/$update_repo/releases" | jq -r --arg bn "$branch_name" 'sort_by(.published_at) | .[] | select(.tag_name | contains($bn)) | .tag_name' | tail -n 1)
    fi

    if [[ ! "$update_ignore" == "$online_version" ]]; then
      if [[ "$update_repo" == "RetroDECK" ]] && [[ $(sed -e 's/[\.a-z]//g' <<< "$version") -le $(sed -e 's/[\.a-z]//g' <<< "$online_version") ]]; then
        choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK"  --extra-button="Ignore Version" \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK - New Update Available" \
        --text="RetroDECK version <span foreground='$blue'><b>$online_version</b></span> is now available.\nUpdate via your app store (e.g., KDE Discover / GNOME Software / Bazaar ).\n\nTo stop seeing this notification, click <span foreground='$purple'><b>Ignore this version</b></span>.")
        rc=$? # Capture return code, as "OK" button has no text value
        if [[ $rc == "1" ]]; then # If any button other than "OK" was clicked
          log i "\"Ignore this version\" selected, updating \"$rd_conf\""
          set_setting_value "$rd_conf" "update_ignore" "$online_version" retrodeck "options" # Store version to ignore for future checks
        fi
      elif [[ "$update_repo" == "$cooker_repository_name" ]] && [[ ! $version == $online_version ]]; then
        log i "Showing update request dialog as \"$online_version\" was found and is greater then \"$version\""
        choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Ignore Version" \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK -New Cooker Version Available" \
          --text="RetroDECK Cooker version:\n\n<span foreground='$blue'><b>$online_version</b></span>\nis now available.\n\nYou are on version:\n\n<span foreground='$blue'><b>$hard_version</b></span>.\n\nTo stop seeing this notification, click <span foreground='$purple'><b>Ignore this version</b></span>.\n\n<b>Would you like to update now?</b>")
        rc=$? # Capture return code, as "Yes" button has no text value
        if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
          if [[ $choice =~ "Ignore Version" ]]; then
            log i "\"Ignore this version\" selected, updating \"$rd_conf\""
            set_setting_value "$rd_conf" "update_ignore" "$online_version" retrodeck "options" # Store version to ignore for future checks.
          fi
        else # User clicked "Yes"
          install_release "$online_version"
        fi
      fi
    fi
  else # Unable to reach the GitHub API for some reason
    configurator_generic_dialog "RetroDECK can't reach the GitHub API to check for updates.\nThis might be because your network or ISP is blocking the connection or GitHub is down.\n\nIf this keeps happening, disable Update Notifications checls in the Configurator."
  fi
}

validate_input() {
  while IFS="^" read -r input action || [[ -n "$input" ]];
  do
    if [[ ! "$input" == "#"* ]] && [[ ! -z "$input" ]]; then
      if [[ "$input" == "$1" ]]; then
        eval "$action"
        input_validated="true"
      fi
    fi
  done < "$input_validation"
}

check_if_preprod() {
  if [[ ! "$hard_version" == "$version" && ! "$hard_version" =~ ^[0-9] && ! "$hard_version" =~ ^(epicure) ]]; then
    log i "Config file's version is $version but the actual version is $hard_version"
    log d "Newly-installed version is a \"pre-production\" build"
    configurator_generic_dialog "RetroDECK - Warning: Pre-Production" "<span foreground='$purple'><b>RUNNING PRE-PRODUCTION VERSIONS OF RETRODECK CAN BE EXTREMELY DANGEROUS!</b></span>\n\nAll of your RetroDECK data is at risk, including:\n<span foreground='$purple'><b>BIOS files</b></span>\n<span foreground='$purple'><b>Borders</b></span>\n<span foreground='$purple'><b>Downloaded media</b></span>\n<span foreground='$purple'><b>Gamelists</b></span>\n<span foreground='$purple'><b>Mods</b></span>\n<span foreground='$purple'><b>ROMs</b></span>\n<span foreground='$purple'><b>Saves</b></span>\n<span foreground='$purple'><b>States</b></span>\n<span foreground='$purple'><b>Screenshots</b></span>\n<span foreground='$purple'><b>Texture packs</b></span>\n<span foreground='$purple'><b>Themes</b></span>\n\n<span foreground='$purple'><b>Proceeding may result in loss or corruption of these files!</b></span>"
    choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Upgrade" --extra-button="Don't Upgrade" --extra-button="Delete Everything and Fresh Install" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="RetroDECK - RetroDECK Pre-Production: Upgrade" \
    --text="You are upgrading a pre-production build of RetroDECK.\n\nPress the <span foreground='$purple'><b>Upgrade</b></span> button to perform a upgrade.\n\nPress the <span foreground='$purple'><b>Don't Upgrade</b></span> to skip the upgrade.\n\nWarning!\n\nPressing the <span foreground='$purple'><b>Delete Everything and Fresh Install</b></span> button deletes all data, including:\nROMs, BIOS, Saves and everything else stored in retrodeck folder.\nDo not press it unless you know what you are doing!")
    rc=$? # Capture return code, as "Yes" button has no text value
    if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
      if [[ "$choice" =~ "Don't Upgrade" ]]; then # If user wants to bypass the post-update process this time.
        log i "Skipping upgrade process for pre-production build, updating stored version in retrodeck.json"
        set_setting_value "$rd_conf" "version" "$hard_version" retrodeck # Set version of currently running RetroDECK to updated retrodeck.json
        echo "true"
        return 0
      elif [[ "$choice" =~ "Delete Everything and Fresh Install" ]]; then # Remove all RetroDECK data and start a fresh install
        if configurator_generic_question_dialog "RetroDECK Pre-Production: Delete Everything and Fresh Install" "<span foreground='$purple'><b>This will delete ALL RetroDECK data!</b></span>\n\nAffected data includes:\n<span foreground='$purple'><b>BIOS files</b></span>\n<span foreground='$purple'><b>Borders</b></span>\n<span foreground='$purple'><b>Media</b></span>\n<span foreground='$purple'><b>Gamelists</b></span>\n<span foreground='$purple'><b>Mods</b></span>\n<span foreground='$purple'><b>ROMs</b></span>\n<span foreground='$purple'><b>Saves</b></span>\n<span foreground='$purple'><b>States</b></span>\n<span foreground='$purple'><b>Screenshots</b></span>\n<span foreground='$purple'><b>Texture packs</b></span>\n<span foreground='$purple'><b>Themes</b></span>\n<span foreground='$purple'><b>And more</b></span>\n\nAre you sure you want to continue?\n<span foreground='$purple'><b>Remember what happened last time!</b></span>"; then
          if configurator_generic_question_dialog "RetroDECK Pre-Production: Delete Everything and Fresh Install: Reset" "<span foreground='$purple'><b>Are you absolutely sure?</b></span>\n\nThere is no going back from this process — everything will be permanently deleted.\n<span foreground='$purple'><b>Dust in the wind.</b></span>\n<span foreground='$purple'><b>Yesterday's omelette.</b></span>"; then
            if configurator_generic_question_dialog "RetroDECK Pre-Production: Delete Everything and Fresh Install: Reset" "<span foreground='$purple'><b>But are you super DUPER sure?</b></span>\n\nWe REALLY want to make sure you understand what is about to happen.\n\nThe following folders and <b>ALL of their contents</b> will be <span foreground='$purple'><b>PERMANENTLY deleted like what happened to Rowan Skye!</b></span>:\n<span foreground='$purple'><b>~/retrodeck</b></span>\n<span foreground='$purple'><b>~/.var/app/net.retrodeck.retrodeck</b></span>\n\n<span foreground='$purple'><b>This is irreversible — proceed at your own risk!</b></span>"; then
              configurator_generic_dialog "RetroDECK Pre-Production: Delete Everything and Fresh Install" "<span foreground='$purple'><b>Ok, if you're that sure, here we go!</b></span>"
              if configurator_generic_question_dialog "RetroDECK Pre-Production: Delete Everything and Fresh Install" "<span foreground='$purple'><b>Are you actually being serious here?</b></span>\n\nBecause we are...\n\n<span foreground='$purple'><b>No backsies...OK?!</b></span>"; then
                log w "Deleting all RetroDECK Data & Fresh Install"
                quit_retrodeck
                rm -rf "$XDG_CONFIG_HOME"
                rm -rf "$rd_home_path"
                source "/app/libexec/global.sh"
              fi
            fi
          fi
        fi
      fi
    fi
  fi
}

check_version_is_older_than() {
  # Determine if current_version is older than new_version using semantic versioning comparison.
  # Version strings can be production format (e.g. "0.8.0b") or pre-production (e.g. "cooker-0.10.1b-CodeName-date").
  # Returns 0 (success/true) if current_version is older, 1 (failure/false) otherwise.
  # USAGE: check_version_is_older_than "$current_version" "$new_version"

  local current_version="$1"
  local new_version="$2"

  # Extract the version number by finding the segment containing dots (e.g. "0.10.1b")
  local current_extracted new_extracted

  if [[ "$current_version" =~ ([0-9]+\.[0-9]+[0-9.]*[a-z]*) ]]; then
    current_extracted="${BASH_REMATCH[1]}"
  else
    log e "Could not extract version from: $current_version"
    return 1
  fi

  if [[ "$new_version" =~ ([0-9]+\.[0-9]+[0-9.]*[a-z]*) ]]; then
    new_extracted="${BASH_REMATCH[1]}"
  else
    log e "Could not extract version from: $new_version"
    return 1
  fi

  # Strip trailing non-numeric suffix (e.g. "b")
  local current_clean="${current_extracted%%[!0-9.]*}"
  local new_clean="${new_extracted%%[!0-9.]*}"

  if [[ "$current_clean" == "$new_clean" ]]; then
    # Pre-production builds (any prefix present) always run updates for their matching version
    if [[ "$hard_version" != "$current_version" ]]; then
      return 0
    fi
    return 1
  fi

  local oldest
  oldest=$(printf '%s\n%s\n' "$current_clean" "$new_clean" | sort -V | head -1)

  [[ "$oldest" == "$current_clean" ]]
}

check_for_updates() {
  # Run post-update actions after a RetroDECK application version upgrade.
  # USAGE: post_update "$version_being_updated"

  local version_being_updated="$1"

  log i "Checking for core application and component updates..."

  if [[ ! "$hard_version" == "$version_being_updated" ]]; then # Core application update
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

    echo "# RetroDECK is completing the upgrade. Please check for any background windows or pop-ups that may require your attention.\n\n<span foreground='$purple'><b>Please wait while the setup process completes...</b></span>\n\nRunning RetroDECK core updates..." >&3
    local framework_handler="_post_update::retrodeck"
    if declare -F "$framework_handler" > /dev/null; then
      log d "Running post-update handler for framework"
      "$framework_handler" "$version_being_updated"
    fi
    echo "# RetroDECK is completing the upgrade. Please check for any background windows or pop-ups that may require your attention.\n\n<span foreground='$purple'><b>Please wait while the setup process completes...</b></span>\n\nDeploying helper files..." >&3
    deploy_helper_files "retrodeck"
    echo "# RetroDECK is completing the upgrade. Please check for any background windows or pop-ups that may require your attention.\n\n<span foreground='$purple'><b>Please wait while the setup process completes...</b></span>\n\nApplying RetroDECK icons..." >&3
    rsync -rlD --delete --mkpath "/app/retrodeck/graphics/folder-iconsets/" "$XDG_CONFIG_HOME/retrodeck/graphics/folder-iconsets/"
    handle_folder_iconsets "$iconset"
  
    echo "100" >&3

    exec 3>&-
    wait "$zenity_pid" 2>/dev/null
    rm -f "$progress_pipe"

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

    log i "Core application upgrade process completed."
  fi

  if check_for_component_updates; then # One or more component updates
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

    echo "# RetroDECK is completing the upgrade. Please check for any background windows or pop-ups that may require your attention.\n\n<span foreground='$purple'><b>Please wait while the setup process completes...</b></span>\n\nUpdating installed components..." >&3
    run_component_updates "$version_being_updated"

    echo "100" >&3

    exec 3>&-
    wait "$zenity_pid" 2>/dev/null
    rm -f "$progress_pipe"

    log i "Component upgrade process completed."
  fi
}
