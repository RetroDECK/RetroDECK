#!/bin/bash

check_network_connectivity() {
  # This function will do a basic check for network availability and return "true" if it is working.
  # USAGE: if [[ $(check_network_connectivity) == "true" ]]; then

  if [[ ! -z $(wget --spider -t 1 "$remote_network_target_1" | grep "HTTP response 200") ]]; then
    local network_connected="true"
  elif [[ ! -z $(wget --spider -t 1 "$remote_network_target_2" | grep "HTTP response 200") ]]; then
    local network_connected="true"
  elif [[ ! -z $(wget --spider -t 1 "$remote_network_target_3" | grep "HTTP response 200") ]]; then
    local network_connected="true"
  else
    local network_connected="false"
  fi

  echo "$network_connected"
}

check_desktop_mode() {
  # This function will do a basic check of if we are running in Steam Deck game mode or not, and return "true" if we are outside of game mode
  # USAGE: if [[ $(check_desktop_mode) == "true" ]]; then

  if [[ ! "$XDG_CURRENT_DESKTOP" == "gamescope" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

check_is_steam_deck() {
  # This function will check the internal product ID for the Steam Deck codename and return "true" if RetroDECK is running on a real Deck
  # USAGE: if [[ $(check_is_steam_deck) == "true" ]]; then

  if [[ $(cat "/sys/devices/virtual/dmi/id/product_name") =~ ^(Jupiter|Galileo)$ ]]; then
    echo "true"
  else
    echo "false"
  fi
}

check_for_version_update() {
  # TODO logging
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
        choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK 🟢"  --extra-button="Ignore this version" \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK - 🆕 New Update Available 🆕" \
        --text="RetroDECK version 🆕 <span foreground='$blue'><b>$online_version</b></span> 🆕 is now available.\nUpdate via your app store (e.g., KDE Discover / GNOME Software / Bazaar ).\n\nTo stop seeing this notification, click <span foreground='$purple'><b>Ignore this version</b></span>.")
        rc=$? # Capture return code, as "OK" button has no text value
        if [[ $rc == "1" ]]; then # If any button other than "OK" was clicked
          log i "Selected: \"OK\""
          set_setting_value "$rd_conf" "update_ignore" "$online_version" retrodeck "options" # Store version to ignore for future checks
        fi
      elif [[ "$update_repo" == "$cooker_repository_name" ]] && [[ ! $version == $online_version ]]; then
        log i "Showing update request dialog as \"$online_version\" was found and is greater then \"$version\""
        choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes 🟢" --extra-button="No 🟥" --extra-button="Ignore Version 🛑" \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK - 🆕🍲 New Cooker Version Available 🍲🆕" \
          --text="RetroDECK Cooker version:\n\n🆕 <span foreground='$blue'><b>$online_version</b></span> 🆕\nis now available.\n\nYou are on version:\n\n🔴 <span foreground='$blue'><b>$hard_version</b></span> 🔴.\n\nTo stop seeing this notification, click <span foreground='$purple'><b>Ignore this version</b></span>.\n\n<b>Would you like to update now?</b>")
        rc=$? # Capture return code, as "Yes" button has no text value
        if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
          if [[ $choice == "Ignore this version" ]]; then
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

check_version_is_older_than() {
# This function will determine if a given version number is newer than the one currently read from retrodeck.cfg (which will be the previous running version at update time) and will return "true" if it is
# The given version to check should be in normal RetroDECK version notation of N.N.Nb (eg. 0.8.0b)
# USAGE: check_version_is_older_than "version"

local current_version="$1"
local new_version="$2"
local is_newer_version="false"

current_version_major_rev=$(sed 's/^\([0-9]*\)\..*/\1/' <<< "$current_version")
new_version_major_rev=$(sed 's/^\([0-9]*\)\..*/\1/' <<< "$new_version")

current_version_minor_rev=$(sed 's/^[0-9]*\.\([0-9]*\)\..*/\1/' <<< "$current_version")
new_version_minor_rev=$(sed 's/^[0-9]*\.\([0-9]*\)\..*/\1/' <<< "$new_version")

current_version_point_rev=$(sed 's/^[0-9]*\.[0-9]*\.\([0-9]*\).*/\1/' <<< "$current_version")
new_version_point_rev=$(sed 's/^[0-9]*\.[0-9]*\.\([0-9]*\).*/\1/' <<< "$new_version")

if [[ "$new_version_major_rev" -gt "$current_version_major_rev" ]]; then
  is_newer_version="true"
elif [[ "$new_version_major_rev" -eq "$current_version_major_rev" ]]; then
  if [[ "$new_version_minor_rev" -gt "$current_version_minor_rev" ]]; then
    is_newer_version="true"
  elif [[ "$new_version_minor_rev" -eq "$current_version_minor_rev" ]]; then
    if [[ "$new_version_point_rev" -gt "$current_version_point_rev" ]]; then
      is_newer_version="true"
    fi
  fi
fi

# Perform post_update commands for current version if it is a cooker or PR
if grep -qF "cooker" <<< "$hard_version" || grep -qF "PR" <<< "$hard_version"; then
  # If newly-installed version is a "cooker" or "PR" build, always perform post_update commands for current version
  if [[ "$(echo "$hard_version" | cut -d'-' -f2)" == "$new_version" ]]; then
    is_newer_version="true"
  fi
fi

echo "$is_newer_version"
}
