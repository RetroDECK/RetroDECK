#!/bin/bash

# Dialog colors
purple="#a864fc"
blue="#6fbfff"

debug_dialog() {
  # This function is for displaying commands run by the Configurator without actually running them
  # USAGE: debug_dialog "command"
  log i "Debug dialog for: $1" # showing the command in the logs
  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - Debug Dialog" \
  --text="$1"
}

configurator_process_complete_dialog() {
  # This dialog shows when a process is complete.
  # USAGE: configurator_process_complete_dialog "process text"
  log i "Process complete dialog for: $1" # showing the process in the logs
  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Quit" --extra-button="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - Process Complete" \
  --text="The process of <span foreground='$purple'><b>$1</b></span> is now complete.\n\nYou may need to <span foreground='$purple'><b>restart RetroDECK</b></span> for the changes to take effect.\n\nClick OK to return to the previous menu or Quit to exit RetroDECK."

  if [ ! $? == 1 ]; then # Quit button clicked
    configurator_nav="quit"
    quit_retrodeck
  fi
}

configurator_generic_dialog() {
  # This dialog is for showing temporary messages before another process happens.
  # USAGE: configurator_generic_dialog "title text" "info text"
  log i "$2" # showing the message in the logs
  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "$1" \
  --text="$2"
}

configurator_generic_question_dialog() {
  # This dialog provides a generic dialog for getting a response from a user.
  # USAGE: if configurator_generic_question_dialog "title text" "action text; then
  log i "$2"
  rd_zenity --title "RetroDECK - $1" --question --no-wrap --cancel-label="No" --ok-label="Yes" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="$2"
}

configurator_destination_choice_dialog() {
  # This dialog is for making things easy for new users to move files to common locations. Gives the options for "Internal", "SD Card" and "Custom Location" locations if on Steam Deck, "Home Directory" and "Custom Location" otherwise.
  # USAGE: $(configurator_destination_choice_dialog "folder being moved" "action text")
  # This function returns one of the values: "Back" "Internal Storage"/"Home Directory" "SD Card" "Custom Location"
  log i "$2"
  if check_is_steam_deck; then
    choice=$(rd_zenity --title "RetroDECK Configurator - Choosing $1 directory" --info --no-wrap --ok-label="Quit" --extra-button="Internal Storage" --extra-button="SD Card" --extra-button="Custom Location" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="$2")
  else
    choice=$(rd_zenity --title "RetroDECK Configurator - Choosing $1 directory" --info --no-wrap --ok-label="Quit" --extra-button="Home Directory" --extra-button="Custom Location" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="$2")
  fi

  local rc=$?
  if [[ -n "$choice" ]]; then
    echo "$choice"
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

  local cheevos_username
  cheevos_username=$(rd_zenity --entry \
    --title="RetroAchievements Login" \
    --text="Enter your RetroAchievements username:")

  if [[ -z "$cheevos_username" ]]; then
    return 1
  fi

  local cheevos_password
  cheevos_password=$(rd_zenity --password \
    --title="RetroAchievements Login" \
    --text="Enter your password for $cheevos_username:")

  if [[ -z "$cheevos_password" ]]; then
    return 1
  fi

  local cheevos_info
  if cheevos_info=$(api_do_cheevos_login "$cheevos_username" "$cheevos_password"); then
    log d "Cheevos login succeeded"
    echo "$cheevos_info"
  else
    log d "Cheevos login failed"
    echo "RetroAchievements login failed, check your username and password."
    return 1
  fi
}

desktop_mode_warning() {
  # This function is a generic warning for issues that happen when running in desktop mode.
  # Running in desktop mode can be verified with the following command: if [[ ! $XDG_CURRENT_DESKTOP == "gamescope" ]]; then
  # This function will check if desktop mode is currently being used and if the warning has not been disabled, and show it if needed.
  # USAGE: desktop_mode_warning

  if check_desktop_mode && [[ $desktop_mode_warning == "true" ]]; then
    choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Never show again" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK - Warning: Desktop Mode" \
    --text="You appear to be running RetroDECK in the SteamOS <span foreground='$purple'><b>Desktop Mode</b></span>.\n\nSome functions of RetroDECK may not work properly in SteamOS <span foreground='$purple'><b>Desktop Mode</b></span>.\n\nRetroDECK is best enjoyed in <span foreground='$purple'><b>Game Mode</b></span> on SteamOS.\n\nDo you still want to proceed?")
    rc=$? # Capture return code, as "Yes" button has no text value
    if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
      if [[ $choice =~ "No" ]]; then
        log i "Selected: \"No\""
        exit 1
      elif [[ $choice =~ "Never show again" ]]; then
        log i "Selected: \"Never show this again\""
        set_setting_value "$rd_conf" "desktop_mode_warning" "false" retrodeck "options" # Store desktop mode warning variable for future checks
      fi
    else
      log i "Selected: \"Yes\""
    fi
  fi
}

configurator_compression_cleanup_dialog() {
  rd_zenity --icon-name=net.retrodeck.retrodeck --question --no-wrap --cancel-label="No" --ok-label="Yes" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - Compression Tool" \
  --text="Would you like to delete the original files after they are compressed?\n\n\If you select <span foreground='$purple'><b>No</b></span>, the original files will remain. You will need to remove them manually, and this may cause <span foreground='$purple'><b>duplicate games</b></span> to appear in the RetroDECK library.\n\n\Before enabling automatic cleanup, please ensure you have a <span foreground='$purple'><b>backup of your files</b></span>."
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
      --title "RetroDECK Configurator - Online Update Check" \
      --text="Online update checks for RetroDECK are currently <span foreground='$purple'><b>Enabled</b></span>.\n\nDo you want to disable them?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value "$rd_conf" "update_check" "false" retrodeck "options"
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Online Update Check" \
    --text="Online update checks for RetroDECK are currently <span foreground='$purple'><b>Disabled</b></span>.\n\nDo you want to enable them?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    fi
  fi
}

configurator_version_history_dialog() {
  local version_array=($(xml sel -t -v '//component/releases/release/@version' -n "$rd_metainfo"))
  local all_versions_list=()

  for rd_version in ${version_array[*]}; do
    all_versions_list=("${all_versions_list[@]}" "RetroDECK $rd_version Changelog" "View the changes specific to version $rd_version")
  done

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Version History" --cancel-label="Back" \
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
}

configurator_retrodeck_credits_dialog() {
  rd_zenity --icon-name=net.retrodeck.retrodeck --text-info --width=1200 --height=720 \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - RetroDECK Team Credits" \
  --filename="$rd_core_files/reference_lists/retrodeck_credits.txt"
}

configurator_browse_retrodeck_wiki_dialog() {
  xdg-open "$rd_wiki_url"
}

configurator_online_update_channel_dialog() {
  if [[ $(get_setting_value "$rd_conf" "update_repo" retrodeck "options") == "RetroDECK" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Change Update Branch" \
    --text="You are currently on the <span foreground='$purple'><b>Stable</b></span> branch of RetroDECK updates. Would you like to switch to the <span foreground='$purple'><b>Cooker</b></span> branch?\n\n\After installing a cooker build, you may need to remove the <span foreground='$purple'><b>Stable</b></span> branch install of RetroDECK to avoid overlap."

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    fi
  else
    set_setting_value "$rd_conf" "update_repo" "RetroDECK" retrodeck "options"
    release_selector
  fi
}
