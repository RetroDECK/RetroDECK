#!/bin/bash

change_preset_dialog() {
  # This function will build a list of all systems compatible with a given preset,
  # show their current enable/disabled state and allow the user to change one or more.
  # USAGE: change_preset_dialog "$preset"

  local preset="$1"
  pretty_preset_name=${preset//_/ }  # Preset name prettification
  pretty_preset_name=$(echo "$pretty_preset_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1')

  parse_json_to_array current_preset_settings_temp api_get_current_preset_settings cheevos
  bash_rearranger "2 3 4 1" current_preset_settings_temp current_preset_settings

  # Show the checklist with extra buttons for "Enable All" and "Disable All"
  choice=$(rd_zenity \
    --list --width=1200 --height=720 \
    --checklist \
    --separator="," \
    --hide-column=4 --print-column=4 \
    --text="Enable $pretty_preset_name:" \
    --column "Enabled" \
    --column "Emulator" \
    --column "Emulated System" \
    --column "internal_system_name" \
    "${current_preset_settings[@]}" \
    --extra-button "Enable All" \
    --extra-button "Disable All")

  local rc=$?

  log d "User made a choice: $choice with return code: $rc"

  if [[ "$rc" == 0 || -n "$choice" ]]; then # If the user didn't hit Cancel
    choice_made="true"
  fi

  # Handle extra button responses.
  if [ "$choice" == "Enable All" ]; then
      log d "Enable All selected"
      # Assign the comma-separated list of all preset system names as the choice
      choice="$all_emulators_in_preset"
  elif [ "$choice" == "Disable All" ]; then
      log d "Disable All selected"
      # Assign empty string as choice, as all systems will be disabled
      choice=""
  fi

  # Call make_preset_changes if the user made a selection,
  # or if an extra button was clicked (even if the resulting choice is empty, meaning all systems are to be disabled).
   if [[ "$choice_made" == "true" ]]; then
    log d "Calling make_preset_changes with choice: $choice"
    (
      make_preset_changes "$preset" "$choice"
    ) | rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
         --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
         --title "RetroDECK Configurator Utility - Presets Configuration" \
         --text="Setting up your presets, please wait..."
   else
     log i "No preset choices made"
   fi
}

build_preset_list_options() {
  # FUNCTION: build_preset_list_options
  # DESCRIPTION: This function builds a list of all the systems available for a given preset.
  #              The function also builds several arrays (all_systems, current_enabled_systems, etc.) that are used in the make_preset_changes() function.
  #              This function needs to be called in the same memory space as make_preset_changes() at least once.
  # USAGE: build_preset_list_options "$preset"
  # INPUT:
  #   - $1: The name of the preset.
  # OUTPUT:
  #   - $current_enabled_systems: An array containing the names of systems that are enabled in the preset.
  #   - $current_disabled_systems: An array containing the names of systems that are disabled in the preset.
  #   - $all_systems: An array containing the names of all systems in the preset.

  preset="$1"
  current_enabled_systems=()
  current_disabled_systems=()
  all_systems=()

  while IFS= read -r system_name
  do
    all_systems=("${all_systems[@]}" "$system_name")
    system_value=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$preset")
    if jq -e --arg system_name "$system_name" --arg system_value "$system_value" --arg preset "$preset" '.[$system_name].presets[$preset][0] == $system_value' "$RD_MODULES/$system_name/manifest.json" > /dev/null; then # The setting is set to the disabled value for this preset
      log d "$system_name is currently disabled for preset $preset"
      current_disabled_systems=("${current_disabled_systems[@]}" "$system_name")
    else # The setting is set to some enabled value
      log d "$system_name is currently enabled for preset $preset"
      current_enabled_systems=("${current_enabled_systems[@]}" "$system_name")
    fi
  done < <(jq -r --arg preset "$1" '.[$preset] | keys[]' "$rd_conf")
}

make_preset_changes() {
  # This function will take a preset name $preset and a CSV list $choice, which contains the names of systems that have been enabled for this preset and enable them in the backend
  # Any systems which are currently enabled and not in the CSV list $choice will instead be disabled in the backend
  # USAGE: make_preset_changes $preset $choice

  # Fetch incompatible presets from JSON and create a lookup list
  incompatible_presets=$(jq -r '
    .incompatible_presets | to_entries[] |
    [
      "\(.key):\(.value)",
      "\(.value):\(.key)"
    ] | join("\n")
  ' "$features")

  preset="$1"
  choice="$2"
  changed_systems=()
  changed_presets=()

  build_preset_list_options "$preset"

  IFS="," read -ra choices <<< "$choice" # Convert CSV list into Bash array
    for emulator in "${all_systems[@]}"; do
      if [[ " ${choices[*]} " =~ " ${emulator} " && ! " ${current_enabled_systems[*]} " =~ " ${emulator} " ]]; then
        changed_systems=("${changed_systems[@]}" "$emulator")
        if [[ ! " ${changed_presets[*]} " =~ " ${preset} " ]]; then
          changed_presets=("${changed_presets[@]}" "$preset")
        fi
        set_setting_value "$rd_conf" "$emulator" "true" "retrodeck" "$preset"
        # Check for conflicting presets for this system
        while IFS=: read -r preset_being_checked known_incompatible_preset || [[ -n "$preset_being_checked" ]];
        do
          if [[ ! $preset_being_checked == "#"* ]] && [[ ! -z "$preset_being_checked" ]]; then
            if [[ "$preset" == "$preset_being_checked" ]]; then
              if [[ $(get_setting_value "$rd_conf" "$emulator" "retrodeck" "$known_incompatible_preset") == "true" ]]; then
                changed_presets=("${changed_presets[@]}" "$known_incompatible_preset")
                set_setting_value "$rd_conf" "$emulator" "false" "retrodeck" "$known_incompatible_preset"
              fi
            fi
          fi
        done < <(echo "$incompatible_presets")
      fi
      if [[ ! " ${choices[*]} " =~ " ${emulator} " && ! " ${current_disabled_systems[*]} " =~ " ${emulator} " ]]; then
        changed_systems=("${changed_systems[@]}" "$emulator")
        if [[ ! " ${changed_presets[*]} " =~ " ${preset} " ]]; then
          changed_presets=("${changed_presets[@]}" "$preset")
        fi
        set_setting_value "$rd_conf" "$emulator" "false" "retrodeck" "$preset"
      fi
    done
    for emulator in "${changed_systems[@]}"; do
      build_preset_config "$emulator" "${changed_presets[*]}"
    done
}

build_preset_config() {
  # This function will apply one or more presets for a given system, as listed in retrodeck.cfg
  # USAGE: build_preset_config "system name" "preset class 1" "preset class 2" "preset class 3"

  local system_being_changed="$1"
  shift
  local presets_being_changed="$*"
  log d "Applying presets: $presets_being_changed for system: $system_being_changed"

  read_config_format=$(jq -r '.config_file_format' "$RD_MODULES/$system_being_changed/presets.json")
  if [[ "$read_config_format" == "retroarch-all" ]]; then
    local retroarch_all="true"
    local read_config_format="retroarch"
  fi
  log d "Config file format: $read_config_format"

  for current_preset in $presets_being_changed
  do
    read_setting_name="$current_preset"
    if jq -e --arg system_being_changed "$system_being_changed" --arg preset "$current_preset" '.[$preset] | has($system_being_changed)' "$rd_conf" > /dev/null; then
      local read_system_enabled=$(get_setting_value "$rd_conf" "$system_being_changed" "retrodeck" "$current_preset")
      log d "Processing system: $system_being_changed with preset: $current_preset, enabled: $read_system_enabled"
      while IFS= read -r read_setting_name
      do
        current_preset_object=$(jq -r --arg preset "$current_preset" --arg preset_name "$read_setting_name" '.[$preset][$preset_name]' "$RD_MODULES/$system_being_changed/presets.json")
        action=$(echo "$current_preset_object" | jq -r '.action')
        new_setting_value=$(echo "$current_preset_object" | jq -r '.new_setting_value')
        section=$(echo "$current_preset_object" | jq -r '.section')
        target_file=$(echo "$current_preset_object" | jq -r '.target_file')
        defaults_file=$(echo "$current_preset_object" | jq -r '.defaults_file')

        case "$action" in

        "change" )
          if [[ "$target_file" = \$* ]]; then # Read current target file and resolve if it is a variable
            eval target_file=$target_file
            log d "Target file is a variable name. Actual target $target_file"
          fi
          local read_target_file="$target_file"
          if [[ "$defaults_file" = \$* ]]; then #Read current defaults file and resolve if it is a variable
            eval defaults_file=$defaults_file
            log d "Defaults file is a variable name. Actual defaults file $defaults_file"
          fi
          local read_defaults_file="$defaults_file"

          if [[ "$read_system_enabled" == "true" ]]; then
            if [[ "$new_setting_value" = \$* ]]; then
              eval new_setting_value=$new_setting_value
              log d "New setting value is a variable. Actual setting value is $new_setting_value"
            fi
            if [[ "$read_config_format" == "retroarch" && ! "$retroarch_all" == "true" ]]; then # Separate process if this is a per-system RetroArch override file
              if [[ ! -f "$read_target_file" ]]; then
                log d "RetroArch per-system override file $read_target_file not found, creating and adding setting"
                create_dir "$(realpath "$(dirname "$read_target_file")")"
                echo "$read_setting_name = \""$new_setting_value"\"" > "$read_target_file"
              else
                if [[ -z $(grep -o -P "^$read_setting_name\b" "$read_target_file") ]]; then
                  log d "RetroArch per-system override file $read_target_file does not contain setting $read_setting_name, adding and assigning value $new_setting_value"
                  add_setting "$read_target_file" "$read_setting_name" "$new_setting_value" "$read_config_format" "$section"
                else
                  log d "Changing setting: $read_setting_name to $new_setting_value in $read_target_file"
                  set_setting_value "$read_target_file" "$read_setting_name" "$new_setting_value" "$read_config_format" "$section"
                fi
              fi
            elif [[ "$read_config_format" == "ppsspp" && "$read_target_file" == "$ppssppcheevosconf" ]]; then # Separate process if this is the standalone cheevos token file used by PPSSPP
              log d "Creating PPSSPP cheevos token file $ppssppcheevosconf"
              echo "$new_setting_value" > "$read_target_file"
            else
              log d "Changing setting: $read_setting_name to $new_setting_value in $read_target_file"
              set_setting_value "$read_target_file" "$read_setting_name" "$new_setting_value" "$read_config_format" "$section"
            fi
          else
            if [[ "$read_config_format" == "retroarch" && ! "$retroarch_all" == "true" ]]; then # Separate process if this is a per-system RetroArch override file
              if [[ -f "$read_target_file" ]]; then
                log d "Removing setting $read_setting_name from RetroArch per-system override file $read_target_file"
                delete_setting "$read_target_file" "$read_setting_name" "$read_config_format" "$section"
                if [[ -z $(cat "$read_target_file") ]]; then # If the override file is empty
                  log d "RetroArch per-system override file is empty, removing"
                  rm -f "$read_target_file"
                fi
                if [[ -z $(ls -1 "$(dirname "$read_target_file")") ]]; then # If the override folder is empty
                  log d "RetroArch per-system override folder is empty, removing"
                  rmdir "$(realpath "$(dirname "$read_target_file")")"
                fi
              fi
            elif [[ "$read_config_format" == "ppsspp" && "$read_target_file" == "$ppssppcheevosconf" ]]; then # Separate process if this is the standalone cheevos token file used by PPSSPP
              log d "Removing PPSSPP cheevos token file $ppssppcheevosconf"
              rm "$read_target_file"
            else
              local default_setting_value=$(get_setting_value "$read_defaults_file" "$read_setting_name" "$read_config_format" "$section")
              log d "Changing setting: $read_setting_name to $default_setting_value in $read_target_file"
              set_setting_value "$read_target_file" "$read_setting_name" "$default_setting_value" "$read_config_format" "$section"
            fi
          fi
        ;;

        "enable" )
          log d "Enabling file: $read_setting_name"
          if [[ "$read_system_enabled" == "true" ]]; then
            enable_file "$read_setting_name"
          else
            disable_file "$read_setting_name"
          fi
        ;;

        * )
          log d "Other data: $action $read_preset $read_setting_name $new_setting_value $section" # DEBUG
        ;;

        esac
      done < <(jq -r --arg preset "$current_preset" '.[$preset] | keys[]' "$RD_MODULES/$system_being_changed/presets.json")
    fi
  done
}

build_retrodeck_current_presets() {
  # This function will read the presets sections of the retrodeck.cfg file and build the default state
  # This can also be used to build the "current" state post-update after adding new systems
  # USAGE: build_retrodeck_current_presets

  while IFS= read -r preset_name # Iterate all presets listed in retrodeck.cfg
  do
    while IFS= read -r system_name # Iterate all system names in this preset
    do
      local system_enabled=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$preset_name") # Read the variables value from active retrodeck.cfg
      if [[ "$system_enabled" == "true" ]]; then
        build_preset_config "$system_name" "$current_section"
      fi
    done < <(jq -r --arg preset "$preset_name" '.presets[$preset] | keys[]' "$rd_conf")
  done < <(jq -r '.presets | keys[]' "$rd_conf")
}

fetch_all_presets() {
  # This function fetches all possible presets from the presets directory
  # USAGE: fetch_all_presets [--pretty] [system_name]

  local presets_dir="$config/retrodeck/presets"
  local presets=()
  local pretty_presets=()
  local pretty_output=false
  local system_name=""

  if [[ "$1" == "--pretty" ]]; then
    pretty_output=true
    system_name="$2"
  else
    system_name="$1"
  fi

  if [[ -n "$system_name" ]]; then
    preset_file="$presets_dir/${system_name}_presets.cfg"
    if [[ -f "$preset_file" ]]; then
      while IFS= read -r line; do
        if [[ $line =~ ^(change|enable)\^([a-zA-Z0-9_]+)\^ ]]; then
          preset="${BASH_REMATCH[2]}"
          if [[ ! " ${presets[*]} " =~ " ${preset} " ]]; then
            presets+=("$preset")
            if $pretty_output; then
              pretty_preset_name=${preset//_/ } # Preset name prettification
              pretty_preset_name=$(echo "$pretty_preset_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1') # Preset name prettification
              pretty_presets+=("$pretty_preset_name")
            fi
          fi
        fi
      done < "$preset_file"
    fi
  else
    for preset_file in "$presets_dir"/*_presets.cfg; do
      while IFS= read -r line; do
        if [[ $line =~ ^change\^([a-zA-Z0-9_]+)\^ ]]; then
          preset="${BASH_REMATCH[1]}"
          if [[ ! " ${presets[*]} " =~ " ${preset} " ]]; then
            presets+=("$preset")
            if $pretty_output; then
              pretty_preset_name=${preset//_/ } # Preset name prettification
              pretty_preset_name=$(echo "$pretty_preset_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1') # Preset name prettification
              pretty_presets+=("$pretty_preset_name")
            fi
          fi
        fi
      done < "$preset_file"
    done
  fi

  if $pretty_output; then
    printf "%s\n" "${pretty_presets[@]}"
  else
    echo "${presets[@]}"
  fi
}

change_presets_cli () {
  # This function will allow a user to change presets either individually or all for a preset class from the CLI.
  # USAGE: change_presets_cli "$preset" "$system/all" "$on/off"

  local preset="$1"
  local system="$2"
  local value="$3"
  local section_results
  section_results=$(sed -n '/\['"$preset"'\]/, /\[/{ /\['"$preset"'\]/! { /\[/! p } }' "$rd_conf" | sed '/^$/d')
  local all_emulators_in_preset="" # A CSV string containing all emulators in a preset block
  local all_other_emulators_in_preset="" # A CSV string containing every emulator except the one provided by the user in a preset block

  log d "Changing settings for preset: $preset"

  while IFS= read -r config_line; do
    # Build a list of all emulators in the preset block
    system_name=$(get_setting_name "$config_line" "retrodeck")
    if [[ -n $all_emulators_in_preset ]]; then
      all_emulators_in_preset+=","
    fi
    all_emulators_in_preset+="$system_name" # Build a list of all emulators in case user provides "all" as the system name

    if [[ "$value" =~ (false|off) && ! "$system" == "all" ]]; then # If the user is disabling a specific emulator, check for any other already enabled and keep them enabled
      system_value=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$preset")
      if [[ ! "$system_name" == "$system" && "$system_value" == "true" ]]; then
        log d "Other system $system_name is enabled for preset $preset, retaining setting."
        if [[ -n $all_other_emulators_in_preset ]]; then
          all_other_emulators_in_preset+=","
        fi
        all_other_emulators_in_preset+="$system_name" # Build a list of all emulators that are currently enabled that aren't the one being disabled
      fi
    fi

  done < <(printf '%s\n' "$section_results")

  if [[ "$value" =~ (true|on) ]]; then # If user is enabling one or more systems in a preset
    if [[ "$system" == "all" ]]; then
      log d "Enabling all emualtors for preset $preset"
      choice="$all_emulators_in_preset" # All emulators in the preset will be enabled
    else
      if [[ "$all_emulators_in_preset" =~ "$system" ]]; then
        log d "Enabling preset $preset for $system"
        choice="$system"
      else
        log i "Emulator $system does not support preset $preset, please check the command options and try again."
      fi
    fi
  else # If user is disabling one or more systems in a preset
    if [[ "$system" == "all" ]]; then
      choice="" # Empty string means all systems in preset should be disabled
    else
      choice="$all_other_emulators_in_preset"
    fi
  fi

  # Call make_preset_changes if the user made a selection,
  # or if an extra button was clicked (even if the resulting choice is empty, meaning all systems are to be disabled).
    log d "Calling make_preset_changes with choice: $choice"
    make_preset_changes "$preset" "$choice"
}
