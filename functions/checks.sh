#!/bin/bash

check_network_connectivity() {
  # This function will do a basic check for network availability and return "true" if it is working.
  # USAGE: if [[ $(check_network_connectivity) == "true" ]]; then

  if [[ ! -z $(wget --spider -t 1 $remote_network_target_1 | grep "HTTP response 200") ]]; then
    local network_connected="true"
  elif [[ ! -z $(wget --spider -t 1 $remote_network_target_2 | grep "HTTP response 200") ]]; then
    local network_connected="true"
  elif [[ ! -z $(wget --spider -t 1 $remote_network_target_3 | grep "HTTP response 200") ]]; then
    local network_connected="true"
  else
    local network_connected="false"
  fi

  echo "$network_connected"
}

check_desktop_mode() {
  # This function will do a basic check of if we are running in Steam Deck game mode or not, and return "true" if we are outside of game mode
  # USAGE: if [[ $(check_desktop_mode) == "true" ]]; then

  if [[ ! $XDG_CURRENT_DESKTOP == "gamescope" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

check_for_version_update() {
  # This function will perform a basic online version check and alert the user if there is a new version available.

  wget -q --spider "https://api.github.com/repos/XargonWan/$update_repo/releases/latest"

  if [ $? -eq 0 ]; then
    local online_version=$(curl --silent "https://api.github.com/repos/XargonWan/$update_repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [[ ! "$update_ignore" == "$online_version" ]]; then
      if [[ "$update_repo" == "RetroDECK" ]] && [[ $(sed -e 's/[\.a-z]//g' <<< $version) -le $(sed -e 's/[\.a-z]//g' <<< $online_version) ]]; then
        # choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Ignore this version" \
        #   --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        #   --title "RetroDECK Update Available" \
        #   --text="There is a new version of RetroDECK on the stable release channel $online_version. Would you like to update to it?\n\n(depending on your internet speed this could takes several minutes).")
        # rc=$? # Capture return code, as "Yes" button has no text value
        # if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
        #   if [[ $choice == "Ignore this version" ]]; then
        #     set_setting_value $rd_conf "update_ignore" "$online_version" retrodeck "options" # Store version to ignore for future checks
        #   fi
        # else # User clicked "Yes"
        #   configurator_generic_dialog "RetroDECK Online Update" "The update process may take several minutes.\n\nAfter the update is complete, RetroDECK will close. When you run it again you will be using the latest version."
        #   (
        #   flatpak-spawn --host flatpak update --noninteractive -y net.retrodeck.retrodeck
        #   ) |
        #   zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
        #   --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        #   --title "RetroDECK Updater" \
        #   --text="Upgrade in process please wait (this could takes several minutes)."
        #   configurator_generic_dialog "RetroDECK Online Update" "The update process is now complete!\n\nPlease restart RetroDECK to keep the fun going."
        #   exit 1
        # fi
        choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK" --extra-button="Ignore this version" \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Update Available" \
        --text="There is a new version of RetroDECK on the stable release channel $online_version. Please update through the Discover app!\n\nIf you would like to ignore this version and recieve a notification at the NEXT version,\nclick the \"Ignore this version\" button.")
        rc=$? # Capture return code, as "OK" button has no text value
        if [[ $rc == "1" ]]; then # If any button other than "OK" was clicked
          set_setting_value $rd_conf "update_ignore" "$online_version" retrodeck "options" # Store version to ignore for future checks
        fi
      elif [[ "$update_repo" == "RetroDECK-cooker" ]] && [[ ! $version == $online_version ]]; then
        choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Ignore this version" \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK Update Available" \
          --text="There is a more recent build of the RetroDECK cooker branch.\nYou are running version $hard_version, the latest is $online_version.\n\nWould you like to update to it?\nIf you would like to skip reminders about this version, click \"Ignore this version\".\nYou will be reminded again at the next version update.\n\nIf you would like to disable these update notifications entirely, disable Online Update Checks in the Configurator.")
        rc=$? # Capture return code, as "Yes" button has no text value
        if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
          if [[ $choice == "Ignore this version" ]]; then
            set_setting_value $rd_conf "update_ignore" "$online_version" retrodeck "options" # Store version to ignore for future checks.
          fi
        else # User clicked "Yes"
          configurator_generic_dialog "RetroDECK Online Update" "The update process may take several minutes.\n\nAfter the update is complete, RetroDECK will close. When you run it again you will be using the latest version."
          (
          local latest_cooker_download=$(curl --silent https://api.github.com/repos/XargonWan/$update_repo/releases/latest | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')
          mkdir -p "$rdhome/RetroDECK_Updates"
          wget -P "$rdhome/RetroDECK_Updates" $latest_cooker_download
          flatpak-spawn --host flatpak remove --noninteractive -y net.retrodeck.retrodeck # Remove current version before installing new one, to avoid duplicates
          flatpak-spawn --host flatpak install --user --bundle --noninteractive -y "$rdhome/RetroDECK_Updates/RetroDECK-cooker.flatpak"
          rm -rf "$rdhome/RetroDECK_Updates" # Cleanup old bundles to save space
          ) |
          zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK Updater" \
          --text="RetroDECK is updating to the latest version, please wait."
          configurator_generic_dialog "RetroDECK Online Update" "The update process is now complete!\n\nPlease restart RetroDECK to keep the fun going."
          exit 1
        fi
      fi
    fi
  else # Unable to reach the GitHub API for some reason
    configurator_generic_dialog "RetroDECK Online Update" "RetroDECK is unable to reach the GitHub API to perform a version check.\nIt's possible that location is being blocked by your network or ISP.\n\nIf the problem continues, you will need to disable internal checks through the Configurator\nand perform updates manually through the Discover store."
  fi
}

validate_input() {
  while IFS="^" read -r input action
  do
    if [[ "$input" == "$1" ]]; then
      eval "$action"
      input_validated="true"
    fi
  done < $input_validation
}
