#!/bin/bash

configurator_navigation() {
  # Central navigation loop for the Configurator utility.
  # Dialog functions set configurator_nav to control navigation.
  # Supports arguments by setting configurator_nav to "function_name arg1 arg2".
  # USAGE: configurator_navigation

  local -a nav_stack=("configurator_welcome_dialog")

  while [[ ${#nav_stack[@]} -gt 0 ]]; do
    local current="${nav_stack[-1]}"
    local func_name="${current%% *}"

    if ! declare -F "$func_name" > /dev/null; then
      log e "Dialog function not found: $func_name"
      break
    fi

    configurator_nav=""
    $current

    case "$configurator_nav" in

      "refresh")
        continue
      ;;

      "back"|"")
        unset 'nav_stack[-1]'
        ;;

      "quit")
        nav_stack=()
        ;;

      *)
        nav_stack+=("$configurator_nav")
        ;;

    esac
  done
}

configurator_welcome_dialog() {
  log i "Configurator: opening Welcome dialog"
  build_zenity_menu_array welcome_menu_options welcome

  if [[ $developer_options == "true" ]]; then
    welcome_menu_options+=("Developer Options" "Welcome to the DANGER ZONE" "configurator_developer_dialog")
  fi

  choice=$(rd_zenity --list --title="RetroDECK Configurator" --cancel-label="Quit" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${welcome_menu_options[@]}")

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    case $choice in

    "Developer Options")
      log i "Configurator: opening \"$choice\" menu"
      configurator_generic_dialog "RetroDECK Configurator - Developer Options" "<span foreground='$purple'><b>WARNING: These features and options can be EXTREMELY DANGEROUS to your RetroDECK installation!</b></span>\n\nThey represent the bleeding edge of upcoming or experimental RetroDECK functionality and should never be used when you have important saves, states, ROMs, or other content that is not fully backed up.\n\n<b>Affected data may include (but is not limited to):</b>\n\nBIOS files\nBorders\nMedia\nGamelists\nMods\nROMs\nSaves\nStates\nScreenshots\nTexture packs\nThemes\nAnd more\n\n<span foreground='$purple'><b>All of this data may be lost, damaged, or completely corrupted if you continue.</b></span>\n\n<span foreground='$purple'><b>YOU HAVE BEEN WARNED</b></span>"
      configurator_nav="$choice"
    ;;

    *)
      log d "choice: $choice"
      configurator_nav="$choice"
    ;;
    esac
  fi
}

configurator_global_presets_and_settings_dialog() {
  log i "Configurator: opening Presets And Settings dialog"
  build_zenity_menu_array choices settings # Build Zenity bash array for given menu type

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Global: Presets and Settings" --cancel-label="Back" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${choices[@]}")

  local rc="$?"

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    log d "choice: $choice"
    configurator_nav="$choice"
  fi
}

configurator_open_component_dialog() {
  log i "Configurator: opening Open Component dialog"
  if [[ $power_user_warning == "true" ]]; then
    choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Never show again" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK - Warning: Power User" \
    --text="Making manual changes to a components configuration may create serious issues, and some settings may be overwritten during RetroDECK updates or when using presets.\n\n\The RetroDECK team do encourage tinkering.\n\n\But if anything goes wrong, you need to use the built-in <span foreground='$purple'><b>reset tools</b></span> inside the RetroDECK Configurator.\n\n\<span foreground='$purple'><b>Please continue only if you know what you're doing.</b></span>\n\n\Component types in RetroDECK:\n\n<span foreground='$purple'><b>Clients</b></span>\n\<span foreground='$purple'><b>Emulators</b></span>\n\<span foreground='$purple'><b>Engines</b></span>\n\<span foreground='$purple'><b>Ports</b></span>\n\<span foreground='$purple'><b>Systems</b></span>\n\nDo you want to continue?")
  fi
  rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "0" ]]; then # If user clicked "Yes"
    build_zenity_open_component_menu_array open_component_list

    component=$(rd_zenity --list \
    --title "RetroDECK Configurator - Open Component" --cancel-label="Back" --ok-label="OK" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
    --text="Which component do you want to launch?" \
    --hide-header --hide-column=3 --print-column=3\
    --column="Component" --column="Description" --column="component_path"\
    "${open_component_list[@]}")

    if [[ -n "$component" ]]; then
      /bin/bash "$component/component_launcher.sh"
      configurator_nav="refresh"
    fi
  elif [[ $choice =~ "Never show again" ]]; then
    set_setting_value "$rd_conf" "power_user_warning" "false" retrodeck "options" # Store power user warning variable for future checks
    configurator_nav="refresh"
  fi
}

configurator_tools_dialog() {
  log i "Configurator: opening Tools dialog"
  build_zenity_menu_array choices tools # Build Zenity bash array for given menu type

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Tools" --cancel-label="Back" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${choices[@]}")

  local rc="$?"

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    log i "Configurator: opening \"$choice\" menu"
    configurator_nav="$choice"
  fi
}

configurator_data_management_dialog() {
  log i "Configurator: opening Data Management dialog"
  build_zenity_menu_array choices data_management # Build Zenity bash array for given menu type

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Data Management" --cancel-label="Back" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${choices[@]}")

  local rc="$?"

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    log d "choice: $choice"
    configurator_nav="$choice"
  fi
}

configurator_reset_dialog() {
  log i "Configurator: opening Reset Component dialog"
  build_zenity_reset_component_menu_array reset_component_list

  local choice
  choice=$(rd_zenity --list \
    --title "RetroDECK Configurator - Reset Components" --cancel-label="Cancel" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
    --checklist --ok-label="Reset Selected" --extra-button="Reset All" --extra-button="Factory Reset" \
    --print-column=2 --hide-column=2 \
    --separator="^" \
    --text="Which components do you want to reset?" \
    --column "Reset" \
    --column "Component" \
    --column "Name" \
    --column "Description" \
    "${reset_component_list[@]}")

  log d "User selected: $choice"

  if [[ "$choice" =~ "Factory Reset" ]]; then
    rd_zenity --question \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Factory Reset" \
      --text="<span foreground='$purple'><b>This action will reset all RetroDECK settings to their default values.</b></span> It will also restart the first-time setup process.\n\nYour personal data: including games, saves, and scraped artwork, will not be affected.\n\n<span foreground='$purple'><b>Are you sure you want to proceed?</b></span>"
    if [[ $? -eq 0 ]]; then
      prepare_component "factory-reset"
      configurator_process_complete_dialog "performing a factory reset"
    fi
    configurator_nav="refresh"
  elif [[ "$choice" =~ "Reset All" ]]; then
    rd_zenity --question \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Reset All" \
      --text="<span foreground='$purple'><b>This action will reset all component settings to their default values.</b></span>\n\nYour personal data: including games, saves, and scraped artwork, will not be affected.\n\n<span foreground='$purple'><b>Are you sure you want to proceed?</b></span>"
    if [[ $? -eq 0 ]]; then
      local -a all_components=()
      mapfile -t all_components < <(jq -r \
      '
        [.[] | .manifest | keys[]] | unique | .[]
      ' "$component_manifest_cache_file")

      local progress_pipe
      progress_pipe=$(mktemp -u)
      mkfifo "$progress_pipe"

      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Configurator - Reset in Progress" \
        --text="Resetting all components\n\nPlease wait while the process finishes..." < "$progress_pipe" &
      local zenity_pid=$!

      exec 3>"$progress_pipe"

      # Framework first
      echo "0" >&3
      echo "# Resetting framework..." >&3
      prepare_component "reset" "retrodeck"

      local remaining=()
      for component in "${all_components[@]}"; do
        [[ "$component" == "retrodeck" ]] && continue
        remaining+=("$component")
      done

      local total=${#remaining[@]}
      local idx=0
      for component in "${remaining[@]}"; do
        idx=$((idx + 1))
        local progress=$((99 * idx / total))
        echo "$progress" >&3
        echo "# Resetting $component..." >&3
        prepare_component "reset" "$component"
      done

      echo "100" >&3

      exec 3>&-
      wait "$zenity_pid" 2>/dev/null
      rm -f "$progress_pipe"

      configurator_process_complete_dialog "resetting all components"
      configurator_nav="refresh"
    fi
  elif [[ -n "$choice" ]]; then
    local -a choices=()
    IFS='^' read -ra choices <<< "$choice"

    # Resolve friendly names from manifest cache
    local pretty_names
    pretty_names=$(printf '%s\n' "${choices[@]}" | jq -R \
    '
      . as $component |
      [.[] | .manifest | select(has($component)) | .[$component].name // $component]
    ' "$component_manifest_cache_file")

    rd_zenity --question \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Reset Components" \
      --text="You selected the following components to be reset:\n\n$(echo "$pretty_names" | jq -r '.')\n\nDo you want to continue?"
    if [[ $? -eq 0 ]]; then
      local progress_pipe
      progress_pipe=$(mktemp -u)
      mkfifo "$progress_pipe"

      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Configurator - Reset in Progress" \
        --text="Resetting selected components.\n\n<span foreground='$purple'><b>Please wait while the process finishes...</b></span>" < "$progress_pipe" &
      local zenity_pid=$!

      exec 3>"$progress_pipe"

      local total_choices=${#choices[@]}
      local choice_idx=0
      for component_to_reset in "${choices[@]}"; do
        choice_idx=$((choice_idx + 1))
        local progress=$((99 * choice_idx / total_choices))
        echo "$progress" >&3
        echo "# Resetting $component_to_reset..." >&3
        prepare_component "reset" "$component_to_reset"
      done

      echo "100" >&3

      exec 3>&-
      wait "$zenity_pid" 2>/dev/null
      rm -f "$progress_pipe"

      configurator_process_complete_dialog "resetting selected components"
      configurator_nav="refresh"
    fi
  fi
}

configurator_about_retrodeck_dialog() {
  log i "Configurator: opening About RetroDECK dialog"
  build_zenity_menu_array choices about_retrodeck # Build Zenity bash array for given menu type

  choice=$(rd_zenity --list --title="RetroDECK Configurator - About RetroDECK" --cancel-label="Back" --ok-label="OK"\
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${choices[@]}")

  local rc="$?"

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    log d "choice: $choice"
    configurator_nav="$choice"
  fi
}

configurator_developer_dialog() {
  log i "Configurator: opening Developer Options dialog"
  build_zenity_menu_array choices developer_options # Build Zenity bash array for given menu type

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Developer Options" --cancel-label="Back" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${choices[@]}")

  local rc="$?"

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    log d "choice: $choice"
    configurator_nav="$choice"
  fi
}

configurator_move_folder_dialog() {
  # This dialog will take a folder variable name from retrodeck.json and move it to a new location. The variable will be updated in retrodeck.json as well as any emulator configs where it occurs.
  # USAGE: configurator_move_folder_dialog "folder_variable_name"
  log i "Showing a configurator_move_folder_dialog for $1"
  local rd_dir_name="$1" # The folder variable name from retrodeck.json
  local dir_to_move="$(get_setting_value "$rd_conf" "$rd_dir_name" "retrodeck" "paths")"
  local dest

  if [[ -d "$dir_to_move" ]]; then # If the directory selected to move already exists at the expected location pulled from retrodeck.json
    choice=$(configurator_destination_choice_dialog "RetroDECK Data" "Please choose a destination for the $(basename "$dir_to_move") folder.")
    
    case ${choice:-} in

    "Internal Storage" | "Home Directory" | "SD Card" | "Custom Location" )
      if [[ "$choice" == "Internal Storage" || "$choice" == "Home Directory" ]]; then # If the user wants to move the folder to internal storage, set the destination target as HOME
        dest="internal"
      elif [[ "$choice" == "SD Card" ]]; then # If the user wants to move the folder to the predefined SD card location, set the target as sdcard from retrodeck.json
        if [[ -n "$sdcard" ]]; then
          dest="sd"
        else
          configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The SD card location is not configured in retrodeck.json, it cannot be used as a destination."
        fi
      else
        configurator_generic_dialog "RetroDECK Configurator - Move Folder" "Select the parent folder where you would like to store the $(basename "$dir_to_move") folder."
        if ! dest=$(directory_browse "RetroDECK directory location"); then
          configurator_generic_dialog "RetroDECK Configurator - Move Folder" "No Custom Location was selected."
          configurator_nav="refresh"
        fi
      fi
    ;;

    esac

    if [[ -n "$dest" ]]; then
      local progress_pipe
      progress_pipe=$(mktemp -u)
      mkfifo "$progress_pipe"

      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --pulsate --no-cancel --auto-close \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Configurator - Move Folder" \
        --text="Moving RetroDECK path $rd_dir_name to $dest, please wait..." < "$progress_pipe" &
      local zenity_pid=$!

      exec 3>"$progress_pipe"

      local result=$(api_do_move_retrodeck_directory "$rd_dir_name" "$dest")

      echo "100" >&3

      exec 3>&-
      wait "$zenity_pid" 2>/dev/null
      rm -f "$progress_pipe"

      configurator_generic_dialog "RetroDECK Configurator - Move Folder" "$result"
    fi
  else # The folder to move was not found at the path pulled from retrodeck.json and it needs to be reconfigured manually.
    configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The <span foreground='$purple'><b>$(basename "$dir_to_move")</b></span> folder was not found at the expected location.\n\nThis may have happened if the folder was moved manually.\n\nPlease select the current location of the folder."
    
    if dir_to_move=$(directory_browse "RetroDECK $(basename "$dir_to_move") directory location"); then
      set_setting_value "$rd_conf" "$rd_dir_name" "$dir_to_move" "retrodeck" "paths"
      source_component_functions
      prepare_component "postmove" "all"
      configurator_generic_dialog "RetroDECK Configurator - Move Folder" "RetroDECK <span foreground='$purple'><b>$(basename "$dir_to_move")</b></span> folder now configured at\n<span foreground='$purple'><b>$dir_to_move</b></span>."
      configurator_nav="refresh"
    else
      configurator_generic_dialog "RetroDECK Configurator - Move Folder" "No location was selected, returning to the Data Management menu."
    fi
  fi
}

configurator_change_preset_dialog() {
  # This function will build a list of all systems compatible with a given preset,
  # show their current enable/disabled state and allow the user to change one or more.
  # USAGE: configurator_change_preset_dialog "$preset"

  local preset="$1"
  pretty_preset_name=${preset//_/ }  # Preset name prettification
  pretty_preset_name=$(echo "$pretty_preset_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1')

  build_zenity_preset_menu_array "current_preset_settings" "$preset"

  choice=$(rd_zenity \
    --list --width=1200 --height=720 \
    --hide-column=5 --print-column=5 \
    --ok-label="Select" --extra-button="Disable All" --extra-button="Enable All" \
    --text="Enable $pretty_preset_name:" \
    --column "Status" \
    --column "Emulator" \
    --column "Emulated System" \
    --column "Emulator Description" \
    --column "internal_system_name" \
    "${current_preset_settings[@]}")

  local rc=$?

  log d "User made a choice: $choice with return code: $rc"

  if [[ -n "$choice" ]]; then # If the user didn't hit Cancel
    if [[ "$choice" =~ "Enable All" ]]; then
      log d "User selected \"Enable All\""
      
      if [[ "$preset" =~ (cheevos|cheevos_hardcore) ]]; then
        if [[ ! -n "$cheevos_username" || ! -n "$cheevos_token" ]]; then
          log d "Cheevos not currently logged in, prompting user..."
          if cheevos_login_info=$(get_cheevos_token_dialog); then
            export cheevos_username=$(jq -r '.User' <<< "$cheevos_login_info")
            export cheevos_token=$(jq -r '.Token' <<< "$cheevos_login_info")
            export cheevos_login_timestamp=$(jq -r '.Timestamp' <<< "$cheevos_login_info")
          else
            configurator_generic_dialog "RetroDECK Configurator - Change Preset" "The preset state could not be changed. The error message is:\n\n<span foreground='$purple'><b>$cheevos_login_info</b></span>\n\nCheck the RetroDECK logs for more details."
            configurator_nav="refresh"
            return 1
          fi
        fi
      fi

      local progress_pipe
      progress_pipe=$(mktemp -u)
      mkfifo "$progress_pipe"

      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --pulsate --no-cancel --auto-close \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK - Enabling Preset $preset" \
        --text="RetroDECK is <span foreground='$purple'><b>Enabling</b></span> the preset <span foreground='$purple'><b>$preset</b></span> for all compatible systems.\n\nPlease wait..." < "$progress_pipe" &
      local zenity_pid=$!

      exec 3>"$progress_pipe"

      while read -r component_obj; do
        local component="$(jq -r '.system_name' <<< $component_obj)"
        local parent_name="$(jq -r '.parent_component // empty' <<< $component_obj)"
        local child_component=""
        local current_status="$(jq -r '.status' <<< $component_obj)"

        if [[ -n "$parent_name" ]]; then
          child_component="$component"
          component="$parent_name"
        fi

        local preset_enabled_state=$(jq -r --arg component "$component" --arg core "$child_component" --arg preset "$preset" '
                                        .[] | .manifest | select(has($component)) | .[$component] |
                                        if $core != "" then
                                          .compatible_presets[$core][$preset][1] // empty
                                        else
                                          .compatible_presets[$preset][1] // empty
                                        end
                                      ' "$component_manifest_cache_file")

        if [[ ! "$current_status" == "$preset_enabled_state" ]]; then
          if [[ -n "$child_component" ]]; then
            log d "Enabling preset $preset for component $child_component"
            api_set_preset_state "$child_component" "$preset" "$preset_enabled_state"
          else
            log d "Enabling preset $preset for component $component"
            api_set_preset_state "$component" "$preset" "$preset_enabled_state"
          fi
        else
          if [[ -n "$child_component" ]]; then
            log d "Component $child_component is already enabled for preset $preset"
          else
            log d "Component $component is already enabled for preset $preset"
          fi
        fi
      done < <(api_get_current_preset_state "$preset" | jq -c '.[].[]')
      
      echo "100" >&3

      exec 3>&-
      wait "$zenity_pid" 2>/dev/null
      rm -f "$progress_pipe"

      configurator_nav="refresh"
    elif [[ "$choice" =~ "Disable All" ]]; then
      log d "User selected \"Disable All\""
      
      local progress_pipe
      progress_pipe=$(mktemp -u)
      mkfifo "$progress_pipe"

      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --pulsate --no-cancel --auto-close \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK - Disabling Preset $preset" \
        --text="RetroDECK is <span foreground='$purple'><b>Disabling</b></span> the preset <span foreground='$purple'><b>$preset</b></span> for all compatible systems.\n\nPlease wait..." < "$progress_pipe" &
      local zenity_pid=$!

      exec 3>"$progress_pipe"

      while read -r component_obj; do
        local component="$(jq -r '.system_name' <<< $component_obj)"
        local parent_name="$(jq -r '.parent_component // empty' <<< $component_obj)"
        local child_component=""
        local current_status="$(jq -r '.status' <<< $component_obj)"

        if [[ -n "$parent_name" ]]; then
          child_component="$component"
          component="$parent_name"
        fi

        local preset_disabled_state=$(jq -r --arg component "$component" --arg core "$child_component" --arg preset "$preset" '
                                        .[] | .manifest | select(has($component)) | .[$component] |
                                        if $core != "" then
                                          .compatible_presets[$core][$preset][0] // empty
                                        else
                                          .compatible_presets[$preset][0] // empty
                                        end
                                      ' "$component_manifest_cache_file")

        if [[ ! "$current_status" == "$preset_disabled_state" ]]; then
          if [[ -n "$child_component" ]]; then
            log d "Disabling preset $preset for component $child_component"
            api_set_preset_state "$child_component" "$preset" "$preset_disabled_state"
          else
            log d "Disabling preset $preset for component $component"
            api_set_preset_state "$component" "$preset" "$preset_disabled_state"
          fi
        else
          if [[ -n "$child_component" ]]; then
            log d "Component $child_component is already disabled for preset $preset"
          else
            log d "Component $component is already disabled for preset $preset"
          fi
        fi
      done < <(api_get_current_preset_state "$preset" | jq -c '.[].[]')

      echo "100" >&3

      exec 3>&-
      wait "$zenity_pid" 2>/dev/null
      rm -f "$progress_pipe"

      configurator_nav="refresh"
    else
      log d "User selected \"$choice\""
      configurator_nav="configurator_change_preset_value_dialog $preset $choice"
    fi
  fi
}

configurator_change_preset_value_dialog() {
  local preset="$1"
  local component="$2"
  local current_preset_values
  local choice
  local rc
  local preset_current_value
  local component_obj
  local parent_name
  local current_status
  local component_id
  local preset_disabled_state
  local result

  build_zenity_preset_value_menu_array current_preset_values "$preset" "$component"

  choice=$(rd_zenity \
    --list --width=1200 --height=720 \
    --radiolist \
    --hide-column=3 --print-column=3 \
    --text="Enable $pretty_preset_name:" \
    --column "Current State" \
    --column "Option" \
    --column "preset_state" \
    "${current_preset_values[@]}")
  rc=$?

  log d "User made a choice: $choice with return code: $rc"

  if [[ "$rc" == 0 && -n "$choice" ]]; then
    preset_current_value=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset")

    if [[ "$choice" != "$preset_current_value" ]]; then
      component_obj=$(api_get_current_preset_state "$preset" "$component" | jq -c '.[].[]')
      parent_name=$(jq -r '.parent_component // empty' <<< "$component_obj")
      current_status=$(jq -r '.status' <<< "$component_obj")
      component_id="$component"

      if [[ -n "$parent_name" ]]; then
        component_id="$parent_name"
      fi

      local preset_disabled_state=$(jq -r --arg component "$component" --arg core "$child_component" --arg preset "$preset" '
                                        .[] | .manifest | select(has($component)) | .[$component] |
                                        if $core != "" then
                                          .compatible_presets[$core][$preset][0] // empty
                                        else
                                          .compatible_presets[$preset][0] // empty
                                        end
                                      ' "$component_manifest_cache_file")

      if [[ "$preset" =~ (cheevos|cheevos_hardcore) && "$choice" != "$preset_disabled_state" ]]; then
        if [[ -z "$cheevos_username" || -z "$cheevos_token" ]]; then
          log d "Cheevos not currently logged in, prompting user..."
          if cheevos_login_info=$(get_cheevos_token_dialog); then
            export cheevos_username=$(jq -r '.User' <<< "$cheevos_login_info")
            export cheevos_token=$(jq -r '.Token' <<< "$cheevos_login_info")
            export cheevos_login_timestamp=$(jq -r '.Timestamp' <<< "$cheevos_login_info")
          else
            configurator_generic_dialog "RetroDECK Configurator - Change Preset" "The preset state could not be changed. The error message is:\n\n<span foreground='$purple'><b>$cheevos_login_info</b></span>\n\nCheck the RetroDECK logs for more details."
          fi
        fi
      fi

      if ! result=$(api_set_preset_state "$component" "$preset" "$choice"); then
        configurator_generic_dialog "RetroDECK Configurator - Change Preset" "The preset state could not be changed. The error message is:\n\n<span foreground='$purple'><b>$result</b></span>\n\nCheck the RetroDECK logs for more details."
      fi
    fi
  fi
}

configurator_bios_checker_dialog() {
  log d "Starting BIOS checker"

  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --pulsate --no-cancel --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - BIOS Checker: Scanning" \
    --text="RetroDECK is scanning your BIOS files.\n\nPlease wait..." < "$progress_pipe" &
  local zenity_pid=$!

  exec 3>"$progress_pipe"

  build_zenity_bios_checker_menu_array "bios_checked_list"

  echo "100" >&3

  exec 3>&-
  wait "$zenity_pid" 2>/dev/null
  rm -f "$progress_pipe"

  log d "Finished checking BIOS files"

  rd_zenity --list --title="RetroDECK Configurator - BIOS Checker" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
    --column "BIOS File Name" \
    --column "Systems" \
    --column "Found" \
    --column "Hash Matches" \
    --column "Required" \
    --column "Expected Path" \
    --column "Description" \
    --column "MD5" \
    "${bios_checked_list[@]}"
}

configurator_compression_tool_dialog() {
  local -a zenity_entries=()
  local -a format_entries=()
  local choice
  local format

  # Static entry: Compress Single Game
  zenity_entries+=("Compress Single Game" "Compress a single game into a compatible format.")

  # Dynamic format-specific entries
  build_zenity_compression_menu_array format_entries
  zenity_entries+=("${format_entries[@]}")

  # Static entries: All Formats and All Games
  zenity_entries+=("Compress Multiple Games: All Formats" "Compress one or more games into any format.")
  zenity_entries+=("Compress All Games" "Compress all games into compatible formats.")

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Compression Tool" --cancel-label="Back" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
    --column="Choice" --column="Action" \
    "${zenity_entries[@]}")

  case $choice in

    "Compress Single Game" )
      log i "Configurator: opening \"$choice\" menu"
      configurator_nav="configurator_compress_single_game_dialog"
    ;;

    "Compress Multiple Games: All Formats" )
      log i "Configurator: opening \"$choice\" menu"
      configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "Depending on your library size and compression settings, this process may take some time."
      configurator_nav="configurator_compress_multiple_games_dialog all"
    ;;

    "Compress All Games" )
      log i "Configurator: opening \"$choice\" menu"
      configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "Depending on your library size and compression settings, this process may take some time."
      configurator_nav="configurator_compress_multiple_games_dialog everything"
    ;;

    "Compress Multiple Games: "* )
      # Dynamic format match: extract the format key from the choice string
      format=$(echo "$choice" | sed 's/Compress Multiple Games: //' | tr '[:upper:]' '[:lower:]')
      log i "Configurator: opening \"$choice\" menu"
      configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "Depending on your library size and compression settings, this process may take some time."
      configurator_nav="configurator_compress_multiple_games_dialog $format"
    ;;

  esac
}

configurator_compress_single_game_dialog() {
  if file=$(file_browse "Game to compress"); then
    local compatible_compression_format=$(find_compatible_compression_format "$file")
    if [[ ! $compatible_compression_format == "none" ]]; then
      local post_compression_cleanup=$(configurator_compression_cleanup_dialog)
      
      local progress_pipe
      progress_pipe=$(mktemp -u)
      mkfifo "$progress_pipe"

      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --width="800" \
      --title "RetroDECK Configurator - Compression in Progress" < "$progress_pipe" &
      local zenity_pid=$!

      exec 3>"$progress_pipe"

      echo "# Compressing $(basename "$file") to $compatible_compression_format format" # This updates the Zenity dialog
      log i "Compressing $(basename "$file") to $compatible_compression_format format"
      compress_game "$compatible_compression_format" "$file" "$post_compression_cleanup"

      echo "100" >&3

      exec 3>&-
      wait "$zenity_pid" 2>/dev/null
      rm -f "$progress_pipe"

      configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "The compression process is complete."
    else
      configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "The selected file does not contain any compatible compression formats."
    fi
  fi
}

configurator_compress_multiple_games_dialog() {
  log d "Starting to compress \"$1\""

  compressible_games_list_file="$(mktemp)"

  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --pulsate --no-cancel --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - Compression Tool" --text "RetroDECK is searching for compressible games, please wait..." < "$progress_pipe" &
  local zenity_pid=$!

  exec 3>"$progress_pipe"

  api_get_compressible_games "$1" | jq -c '.[]' > "$compressible_games_list_file"
  
  echo "100" >&3

  exec 3>&-
  wait "$zenity_pid" 2>/dev/null
  rm -f "$progress_pipe"

  if [[ -n "$(cat "$compressible_games_list_file")" ]]; then
    log d "Found the following games to compress: ${all_compressible_games[*]}"
  else
    configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "No compressible files were found."
    rm "$compressible_games_list_file"
    return 1
  fi

  local games_to_compress=()
  if [[ "$1" != "everything" ]]; then
    local checklist_entries=()
    while read -r obj; do # Iterate through all returned menu objects
      local game=$(jq -r '.game' <<< "$obj")
      local format=$(jq -r '.format' <<< "$obj")
      checklist_entries+=( "FALSE" "$game" "$format" )
    done < <(cat "$compressible_games_list_file")

    local choice=$(rd_zenity \
      --list --width=1200 --height=720 --title "RetroDECK Configurator - Compression Tool" \
      --checklist --hide-column=3 --ok-label="Compress Selected" --extra-button="Compress All" \
      --separator="^" --print-column=2,3 \
      --text="Choose which games to compress:" \
      --column "Compress?" \
      --column "Game" \
      --column "Compression Format" \
      "${checklist_entries[@]}")

    local rc=$?
    log d "User choice: $choice"
    if [[ $rc == 0 && -n "$choice" && ! "$choice" == "Compress All" ]]; then
      IFS='^' read -r -a temp_array <<< "$choice"
      games_to_compress=()
      for ((i=0; i<${#temp_array[@]}; i+=2)); do
        games_to_compress+=("${temp_array[i]}^${temp_array[i+1]}")
      done
    elif [[ "$choice" =~ "Compress All" ]]; then
      while read -r obj; do # Iterate through all returned menu objects
        local game=$(jq -r '.game' <<< "$obj")
        local format=$(jq -r '.format' <<< "$obj")
        games_to_compress+=( "$game^$format" )
      done < <(cat "$compressible_games_list_file")
    else
      rm "$compressible_games_list_file"
      return 0
    fi
  else
    while read -r obj; do # Iterate through all returned menu objects
      local game=$(jq -r '.game' <<< "$obj")
      local format=$(jq -r '.format' <<< "$obj")
      games_to_compress+=( "$game^$format" )
    done < <(cat "$compressible_games_list_file")
  fi

  rm "$compressible_games_list_file"

  local post_compression_cleanup=$(configurator_compression_cleanup_dialog)

  local total_games=${#games_to_compress[@]}
  local games_left=$total_games

  (
    for game_line in "${games_to_compress[@]}"; do
      while (( $(jobs -p | wc -l) >=  $system_cpu_max_threads )); do
      sleep 0.1
      done
      (
        IFS="^" read -r game compression_format <<< "$game_line"
        log i "Compressing $(basename "$game") into $compression_format format"
        echo "#Compressing $(basename "$game") into $compression_format format.\n\n$games_left games left to compress." # Update Zenity dialog text

        compress_game "$compression_format" "$game" "$post_compression_cleanup"

        games_left=$(( games_left - 1 ))
        local progress=$(( 99 - (( 99 / total_games ) * games_left) ))
        echo "$progress" # Update Zenity dialog progress bar
      ) &
    done
    wait # wait for background tasks to finish
    echo "100" # Close Zenity progress dialog when finished
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck/retrodeck.svg" \
    --width="800" \
    --title "RetroDECK Configurator - Compression in Progress"

  configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "The compression process is complete!"
}

configurator_change_rd_logging_level_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator - Change Logging Level" --cancel-label="Back" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Level 1: Informational" "The default setting, logs only basic important information." \
  "Level 2: Warnings" "Logs general warnings." \
  "Level 3: Errors" "Logs more detailed error messages." \
  "Level 4: Debug" "Logs everything, which may generate a lot of logs.")

  case $choice in

  "Level 1: Informational" )
    log i "Configurator: Changing logging level to \"$choice\""
    set_setting_value "$rd_conf" "rd_logging_level" "info" "retrodeck" "options"
    configurator_generic_dialog "RetroDECK Configurator - Change Logging Level" "The logging level has been changed to <span foreground='$purple'><b>Level 1: Informational</b></span>."
  ;;

  "Level 2: Warnings" )
    log i "Configurator: Changing logging level to \"$choice\""
    set_setting_value "$rd_conf" "rd_logging_level" "warn" "retrodeck" "options"
    configurator_generic_dialog "RetroDECK Configurator - Change Logging Level" "The logging level has been changed to <span foreground='$purple'><b>Level 2: Warnings</b></span>."
  ;;

  "Level 3: Errors" )
    log i "Configurator: Changing logging level to \"$choice\""
    set_setting_value "$rd_conf" "rd_logging_level" "error" "retrodeck" "options"
    configurator_generic_dialog "RetroDECK Configurator - Change Logging Level" "The logging level has been changed to <span foreground='$purple'><b> Level 3: Errors</b></span>."
  ;;

  "Level 4: Debug" )
    log i "Configurator: Changing logging level to \"$choice\""
    set_setting_value "$rd_conf" "rd_logging_level" "debug" "retrodeck" "options"
    configurator_generic_dialog "RetroDECK Configurator - Change Logging Level" "The logging level has been changed to <span foreground='$purple'><b> Level 4: Debug</b></span>."
  ;;

  esac
}

configurator_retrodeck_backup_dialog() {
  local "backup_choice" "result"
  local -a choices=()
  configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "This tool will compress one or more RetroDECK userdata folders into a single .tar file.\n\n<span foreground='$purple'><b>Please note that this process may take several minutes.</b></span>\n\nThe resulting .tar file will be located in:\n<span foreground='$purple'><b>$backups_path.</b></span>"

  choice=$(rd_zenity --title "RetroDECK Configurator - Backup Userdata" --info --no-wrap --ok-label="No Backup" --extra-button="Core Backup" --extra-button="Custom Backup" --extra-button="Complete Backup" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --text="Please choose a backup method for your RetroDECK userdata:\n\nCore Backup:\nOnly essential files will be saved, including game saves, save states, and gamelists.\n\nCustom Backup:\nSelect specific folders to include in your backup. Ideal for tailored data preservation.\n\nComplete Backup:\nAll userdata will be backed up, including games and downloaded media.\n\n<span foreground='purple'><b>WARNING:</b> A complete backup may require a very large amount of storage space.</span>")

  case $choice in
    "Core Backup" )
      log i "User chose to backup core userdata."
      backup_choice="core"
    ;;
    "Custom Backup" )
      log i "User chose to backup custom userdata."

      local -a compressible_paths=()
      declare -A path_components
      declare -A path_symlink_flags

      while IFS=$'\t' read -r component_name raw_path follow_symlinks; do
        local resolved_path
        resolved_path=$(echo "$raw_path" | envsubst)
        if [[ -z "$resolved_path" ]]; then
          continue
        fi
        if [[ -n "${path_components[$resolved_path]}" ]]; then
          path_components["$resolved_path"]="${path_components[$resolved_path]}, $component_name"
          if [[ "$follow_symlinks" == "true" ]]; then
            path_symlink_flags["$resolved_path"]="true"
          fi
        else
          path_components["$resolved_path"]="$component_name"
          path_symlink_flags["$resolved_path"]="$follow_symlinks"
        fi
      done < <(
        jq -r '
          [to_entries[] |
          .value.name as $name |
          (.value.backup_data // {} | (.core // [])[], (.complete // [])[]) |
          [$name, .path, (.follow_symlinks // false | tostring)]] | unique[] | @tsv
        ' "$component_manifest_cache_file"
      )

      # Ensure "RetroDECK" appears first within any multi-component entry
      for resolved_path in "${!path_components[@]}"; do
        local components="${path_components[$resolved_path]}"
        if [[ "$components" == *", "* && "$components" == *"RetroDECK"* ]]; then
          local -a parts=()
          IFS=', ' read -ra parts <<< "$components"
          local -a others=()
          for part in "${parts[@]}"; do
            [[ -n "$part" && "$part" != "RetroDECK" ]] && others+=("$part")
          done
          IFS=', ' eval 'local sorted_others="${others[*]}"'
          path_components["$resolved_path"]="RetroDECK, $sorted_others"
        fi
      done

      # Sort paths: RetroDECK entries first, then alphabetically by component name
      local -a sorted_paths=()
      mapfile -t sorted_paths < <(
        for resolved_path in "${!path_components[@]}"; do
          printf '%s\t%s\n' "${path_components[$resolved_path]}" "$resolved_path"
        done | sort -t$'\t' -k1,1 | awk -F'\t' '
          /^RetroDECK/ { print; next }
          { rest[NR] = $0 }
          END { for (i in rest) print rest[i] }
        '
      )

      for line in "${sorted_paths[@]}"; do
        local component_name="${line%%$'\t'*}"
        local resolved_path="${line#*$'\t'}"
        log d "Adding $resolved_path to compressible paths ($component_name)"
        compressible_paths+=("false" "$component_name" "$resolved_path")
      done

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

      if [[ -n "$choice" ]]; then
        log i "User chose custom paths to backup."
        backup_choice="custom"
        IFS='^' read -ra choices <<< "$choice"
      fi
    ;;
    "Complete Backup" )
      log i "User chose to backup all userdata."
      backup_choice="complete"
    ;;
  esac

  if [[ -n "$backup_choice" ]]; then
    local progress_pipe
    progress_pipe=$(mktemp -u)
    mkfifo "$progress_pipe"

    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --width="800" \
    --title "RetroDECK Configurator - Backup in Progress" < "$progress_pipe" &
    local zenity_pid=$!

    exec 3>"$progress_pipe"

    log i "Starting $backup_choice backup process"
    echo "# Starting $backup_choice backup process, please wait..."
    result=$(api_do_backup_retrodeck_userdata "$backup_choice" "${choices[@]}")
    local rc=$?

    echo "100" >&3

    exec 3>&-
    wait "$zenity_pid" 2>/dev/null
    rm -f "$progress_pipe"

    if [[ "$rc" == 0 ]]; then
      configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The \"$backup_choice\" backup process is complete,\nthe backup file is located at $result"
    else
      configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The \"$backup_choice\" backup process could not be completed.\n\n$result"
    fi
  fi
}

configurator_clean_empty_systems_dialog() {
  configurator_generic_dialog "RetroDECK Configurator - Clean Empty System Folders" "Before removing any identified empty system folders,\n<span foreground='$purple'><b>please ensure that your game collection is backed up to prevent data loss.</b></span>"

  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close --pulsate \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - Clean Empty System Folders" --text "Searching for empty system folders.\n\nPlease wait..." < "$progress_pipe" &
  local zenity_pid=$!

  exec 3>"$progress_pipe"

  build_zenity_find_empty_rom_folders_menu_array empty_rom_folders_list

  echo "100" >&3

  exec 3>&-
  wait "$zenity_pid" 2>/dev/null
  rm -f "$progress_pipe"

  if [[ -n ${empty_rom_folders_list[@]} ]]; then
    choice=$(rd_zenity --list \
    --width=1200 --height=720 --title "RetroDECK Configurator - Clean Empty System Folders" \
    --checklist --ok-label="Remove Selected" --extra-button="Remove All" \
    --separator="^" --hide-column=3 --print-column=3 \
    --text="Choose which empty ROM folders to remove:" \
    --column "Remove?" \
    --column "System" \
    --column "path" \
    "${empty_rom_folders_list[@]}")

    local rc=$?
    if [[ $rc == "0" && -n "$choice" ]]; then # User clicked "Remove Selected" with at least one system selected
      IFS="^" read -ra folders_to_remove <<< "$choice"
      for folder in "${folders_to_remove[@]}"; do
        log i "Removing empty folder $folder"
        rm -rf "$folder"
      done
      configurator_generic_dialog "RetroDECK Configurator - Clean Empty System Folders" "The removal process is complete."
    elif [[ ! -z $choice ]]; then # User clicked "Remove All"
      for ((i = 2; i < ${#empty_rom_folders_list[@]}; i += 3)); do
        log i "Removing empty folder ${empty_rom_folders_list[i]}"
        rm -rf "${empty_rom_folders_list[i]}"
      done
      configurator_generic_dialog "RetroDECK Configurator - Clean Empty System Folders" "The removal process is complete."
    fi
  else
    configurator_generic_dialog "RetroDECK Configurator - Clean Empty System Folders" "No empty folders found for removal."
  fi
}

configurator_usb_import_dialog() {
  # REBUILD
  choice=$(rd_zenity --list --title="RetroDECK Configurator - USB Import" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Prepare USB device" "Create ROM and BIOS folders on a selected USB device" \
  "Import from USB" "Import collection from a previously prepared device" )

  case $choice in

  "Prepare USB device" )
    log i "Configurator: opening \"$choice\" menu"

    external_devices=()

    while read -r size device_path; do
      device_name=$(basename "$device_path")
      external_devices=("${external_devices[@]}" "$device_name" "$size" "$device_path")
    done < <(df --output=size,target -h | grep "/run/media/" | grep -v "$sdcard" | awk '{$1=$1;print}')

    if [[ "${#external_devices[@]}" -gt 0 ]]; then
      configurator_generic_dialog "RetroDECK Configurator - USB Import" "If you have an SD card installed that is not currently configured in RetroDECK, it may appear in this list but may not be suitable for USB import.\n\n<span foreground='$purple'><b>Please select your desired drive carefully.</b></span>"
      choice=$(rd_zenity --list --title="RetroDECK Configurator - USB Migration Tool" --cancel-label="Back" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ ! -z "$choice" ]]; then
        create_dir "$choice/RetroDECK Import"
        es-de --home "$choice/RetroDECK Import" --create-system-dirs
        rm -rf "$choice/RetroDECK Import/ES-DE" # Cleanup unnecessary folder


        # Prepare default BIOS folder subfolders
        create_dir "$choice/RetroDECK Import/BIOS/np2kai"
        create_dir "$choice/RetroDECK Import/BIOS/dc"
        create_dir "$choice/RetroDECK Import/BIOS/Mupen64plus"
        create_dir "$choice/RetroDECK Import/BIOS/quasi88"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/samples"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/cheats"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/blend"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/patched"
        create_dir "$choice/RetroDECK Import/BIOS/citra/sysdata"
        create_dir "$choice/RetroDECK Import/BIOS/cemu"
        create_dir "$choice/RetroDECK Import/BIOS/pico-8/carts"
        create_dir "$choice/RetroDECK Import/BIOS/pico-8/cdata"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_hdd0"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_hdd1"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_flash"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_flash2"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_flash3"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_bdvd"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_usb000"
        create_dir "$choice/RetroDECK Import/BIOS/Vita3K/"
        create_dir "$choice/RetroDECK Import/BIOS/mame-sa/samples"
        create_dir "$choice/RetroDECK Import/BIOS/gzdoom"
      fi
    else
      configurator_generic_dialog "RetroDeck Configurator - USB Import" "<span foreground='$purple'><b>No USB devices were found.</b></span>"
    fi
    configurator_nav="refresh"
  ;;

  "Import from USB" )
    log i "Configurator: opening \"$choice\" menu"
    external_devices=()

    while read -r size device_path; do
      if [[ -d "$device_path/RetroDECK Import/ROMs" ]]; then
        device_name=$(basename "$device_path")
        external_devices=("${external_devices[@]}" "$device_name" "$size" "$device_path")
      fi
    done < <(df --output=size,target -h | grep "/run/media/" | grep -v "$sdcard" | awk '{$1=$1;print}')

    if [[ "${#external_devices[@]}" -gt 0 ]]; then
      choice=$(rd_zenity --list --title="RetroDECK Configurator - USB Migration Tool" --cancel-label="Back" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ ! -z "$choice" ]]; then
        if verify_space "$choice/RetroDECK Import/ROMs" "$roms_path" || verify_space "$choice/RetroDECK Import/BIOS" "$bios_path"; then
          if configurator_generic_question_dialog "RetroDECK Configurator - USB Migration Tool" "You MAY not have enough free space to import this ROM/BIOS library.\n\nThis utility only imports new additions from the USB device, so if there are a lot of the same files in both locations you are likely going to be fine\nbut we are not able to verify how much data will be transferred before it happens.\n\nIf you are unsure, please verify your available free space before continuing.\n\nDo you want to continue now?"; then
            (
            rsync -a --mkpath "$choice/RetroDECK Import/ROMs/"* "$roms_path"
            rsync -a --mkpath "$choice/RetroDECK Import/BIOS/"* "$bios_path"
            ) |
            rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator - USB Import In Progress"
            configurator_generic_dialog "RetroDECK Configurator - USB Migration Tool" "The import process is complete!"
          fi
        else
          (
          rsync -a --mkpath "$choice/RetroDECK Import/ROMs/"* "$roms_path"
          rsync -a --mkpath "$choice/RetroDECK Import/BIOS/"* "$bios_path"
          ) |
          rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK Configurator - USB Import In Progress"
          configurator_generic_dialog "RetroDECK Configurator - USB Migration Tool" "The import process is complete!"
        fi
      fi
    else
      configurator_generic_dialog "RetroDeck Configurator - USB Import" "<span foreground='$purple'><b>No USB devices with an importable folder were found.</b></span>"
    fi
    configurator_nav="refresh"
  ;;
  esac
}

configurator_iconset_toggle_dialog() {
  if [[ ! $(get_setting_value "$rd_conf" "iconset" "retrodeck" "options") == "false" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Folder Iconsets" \
    --text="RetroDECK folder icons are currently <span foreground='$purple'><b>Enabled</b></span>. Do you want to remove them?"
    
    if [ $? == 0 ] # User clicked "Yes"
    then
      local progress_pipe
      progress_pipe=$(mktemp -u)
      mkfifo "$progress_pipe"

      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --pulsate --no-cancel --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator - Toggle Folder Iconsets In Progress" < "$progress_pipe" &
      local zenity_pid=$!

      exec 3>"$progress_pipe"

      handle_folder_iconsets "false"

      echo "100" >&3

      exec 3>&-
      wait "$zenity_pid" 2>/dev/null
      rm -f "$progress_pipe"
      
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Folder Iconsets" \
      --text="RetroDECK folder icons are now <span foreground='$purple'><b>Disabled</b></span>."
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Folder Iconsets" \
    --text="RetroDECK folder icons are currently <span foreground='$purple'><b>Disabled</b></span>. Do you want to enable them?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      
      local progress_pipe
      progress_pipe=$(mktemp -u)
      mkfifo "$progress_pipe"

      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --pulsate --no-cancel --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator - Toggle Folder Iconsets In Progress" < "$progress_pipe" &
      local zenity_pid=$!

      exec 3>"$progress_pipe"

      handle_folder_iconsets "lahrs-main"
      echo "100" >&3

      exec 3>&-
      wait "$zenity_pid" 2>/dev/null
      rm -f "$progress_pipe"

      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Toggle Folder Iconsets" \
      --text="RetroDECK folder icons are now <span foreground='$purple'><b>Enabled</b></span>."
    fi
  fi
}

configurator_toggle_retroengine_event_scripts_dialog() {
  if [[ ! $(get_compoenent_option "es-de" "esde_engine_launch_scripts") == "false" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroENGINE Event Script Processing" \
    --text="RetroENGINE event script processing is currently <span foreground='$purple'><b>Enabled</b></span>. Do you want to disable it?"
    
    if [ $? == 0 ] # User clicked "Yes"
    then
      set_compoenent_option "es-de" "esde_engine_launch_scripts" "false"

      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - RetroENGINE Event Script Processing" \
      --text="RetroENGINE event script processing is now <span foreground='$purple'><b>Disabled</b></span>."
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroENGINE Event Script Processing" \
    --text="RetroENGINE event script processing is currently <span foreground='$purple'><b>Disabled</b></span>. Do you want to enable it?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_compoenent_option "es-de" "esde_engine_launch_scripts" "true"

      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - RetroENGINE Event Script Processing" \
      --text="RetroENGINE event script processing is now <span foreground='$purple'><b>Enabled</b></span>."
    fi
  fi
}
