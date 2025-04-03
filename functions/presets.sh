#!/bin/bash

change_preset_dialog() {
  # This function will build a list of all systems compatible with a given preset,
  # show their current enable/disabled state and allow the user to change one or more.
  # USAGE: change_preset_dialog "$preset"

  preset="$1"
  pretty_preset_name=${preset//_/ }  # Preset name prettification
  pretty_preset_name=$(echo "$pretty_preset_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1')
  current_preset_settings=()
  local section_results
  section_results=$(sed -n '/\['"$preset"'\]/, /\[/{ /\['"$preset"'\]/! { /\[/! p } }' "$rd_conf" | sed '/^$/d')
  all_emulators_in_preset=""

  log d "Starting change_preset_dialog for preset: $preset"

  while IFS= read -r config_line; do
      system_name=$(get_setting_name "$config_line" "retrodeck")
      system_value=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$preset")
      if [[ -n $all_emulators_in_preset ]]; then
        all_emulators_in_preset+=","
      fi
      all_emulators_in_preset+="$system_name" # Build a list of all emulators in case user selects "Enable All"
      # Append three values: the current enabled state, a pretty name, and the internal system name.
      current_preset_settings=("${current_preset_settings[@]}" "$system_value" "$(make_name_pretty "$system_name")" "$system_name")
  done < <(printf '%s\n' "$section_results")

  log d "Current preset settings built for preset: $preset"

  # Show the checklist with extra buttons for "Enable All" and "Disable All"
  choice=$(rd_zenity \
    --list --width=1200 --height=720 \
    --checklist \
    --separator="," \
    --hide-column=3 --print-column=3 \
    --text="Enable $pretty_preset_name:" \
    --column "Enabled" \
    --column "Emulator" \
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
  #              It generates the list into a Godot temp file and updates the variable $current_preset_settings.
  #              The function also builds several arrays (all_systems, changed_systems, etc.) that are used in the make_preset_changes() function.
  #              This function needs to be called in the same memory space as make_preset_changes() at least once.
  # USAGE: build_preset_list_options "$preset"
  # INPUT:
  #   - $1: The name of the preset.
  # OUTPUT:
  #   - $godot_current_preset_settings: A Godot temp file containing the system values, pretty system names, and system names.
  #   - $current_preset_settings: An array containing the system values, pretty system names, and system names.
  #   - $current_enabled_systems: An array containing the names of systems that are enabled in the preset.
  #   - $current_disabled_systems: An array containing the names of systems that are disabled in the preset.
  #   - $changed_systems: An array that will be used to track systems that have changed.
  #   - $changed_presets: An array that will be used to track presets that have changed.
  #   - $all_systems: An array containing the names of all systems in the preset.

  if [[ -f "$godot_current_preset_settings" ]]; then
    rm -f "$godot_current_preset_settings" # Godot data transfer temp files
  fi
  touch "$godot_current_preset_settings"

  preset="$1"
  pretty_preset_name=${preset//_/ } # Preset name prettification
  pretty_preset_name=$(echo "$pretty_preset_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1') # Preset name prettification
  current_preset_settings=()
  current_enabled_systems=()
  current_disabled_systems=()
  changed_systems=()
  changed_presets=()
  all_systems=()
  local section_results=$(sed -n '/\['"$preset"'\]/, /\[/{ /\['"$preset"'\]/! { /\[/! p } }' "$rd_conf" | sed '/^$/d')

  while IFS= read -r config_line
    do
      system_name=$(get_setting_name "$config_line" "retrodeck")
      all_systems=("${all_systems[@]}" "$system_name")
      system_value=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$preset")
      if [[ "$system_value" == "true" ]]; then
        current_enabled_systems=("${current_enabled_systems[@]}" "$system_name")
      elif [[ "$system_value" == "false" ]]; then
        current_disabled_systems=("${current_disabled_systems[@]}" "$system_name")
      fi
      current_preset_settings=("${current_preset_settings[@]}" "$system_value" "$(make_name_pretty "$system_name")" "$system_name")
      echo "$system_value"^"$(make_name_pretty "$system_name")"^"$system_name" >> "$godot_current_preset_settings"
  done < <(printf '%s\n' "$section_results")
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

  build_preset_list_options "$preset"

  IFS="," read -ra choices <<< "$choice"
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
  for current_preset in $presets_being_changed
  do
    local preset_section=$(sed -n '/\['"$current_preset"'\]/, /\[/{ /\['"$current_preset"'\]/! { /\[/! p } }' "$rd_conf" | sed '/^$/d')
    while IFS= read -r system_line
    do
      local read_system_name=$(get_setting_name "$system_line")
      if [[ "$read_system_name" == "$system_being_changed" ]]; then
        local read_system_enabled=$(get_setting_value "$rd_conf" "$read_system_name" "retrodeck" "$current_preset")
        log d "Processing system: $read_system_name with preset: $current_preset, enabled: $read_system_enabled"
        while IFS='^' read -r action read_preset read_setting_name new_setting_value section target_file defaults_file || [[ -n "$action" ]];
        do
          if [[ ! $action == "#"* ]] && [[ ! -z "$action" ]]; then
            case "$action" in

            "config_file_format" )
              if [[ "$read_preset" == "retroarch-all" ]]; then
                local retroarch_all="true"
                local read_config_format="retroarch"
              else
                local read_config_format="$read_preset"
              fi
              log d "Config file format: $read_config_format"
            ;;

            "change" )
              if [[ "$read_preset" == "$current_preset" ]]; then
                if [[ "$target_file" = \$* ]]; then # Read current target file and resolve if it is a variable
                  eval target_file=$target_file
                fi
                local read_target_file="$target_file"
                if [[ "$defaults_file" = \$* ]]; then #Read current defaults file and resolve if it is a variable
                  eval defaults_file=$defaults_file
                fi
                local read_defaults_file="$defaults_file"

                if [[ "$read_system_enabled" == "true" ]]; then
                  if [[ "$new_setting_value" = \$* ]]; then
                    eval new_setting_value=$new_setting_value
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
              fi
            ;;

            "enable" )
              if [[ "$read_preset" == "$current_preset" ]]; then
                log d "Enabling file: $read_setting_name"
                if [[ "$read_system_enabled" == "true" ]]; then
                  enable_file "$read_setting_name"
                else
                  disable_file "$read_setting_name"
                fi
              fi
            ;;

            * )
              log d "Other data: $action $read_preset $read_setting_name $new_setting_value $section" # DEBUG
            ;;

            esac
          fi
        done < <(cat "$presets_dir/$read_system_name"_presets.cfg)
      fi
    done < <(printf '%s\n' "$preset_section")
  done
}

build_retrodeck_current_presets() {
  # This function will read the presets sections of the retrodeck.cfg file and build the default state
  # This can also be used to build the "current" state post-update after adding new systems
  # USAGE: build_retrodeck_current_presets

  while IFS= read -r current_setting_line || [[ -n "$current_setting_line" ]]; # Read the existing retrodeck.cfg
  do
    if [[ (! -z "$current_setting_line") && (! "$current_setting_line" == "#"*) && (! "$current_setting_line" == "[]") ]]; then # If the line has a valid entry in it
      if [[ ! -z $(grep -o -P "^\[.+?\]$" <<< "$current_setting_line") ]]; then # If the line is a section header
        local current_section=$(sed 's^[][]^^g' <<< "$current_setting_line") # Remove brackets from section name
      else
        if [[ ! ("$current_section" == "" || "$current_section" == "paths" || "$current_section" == "options" || "$current_section" == "cheevos" || "$current_section" == "cheevos_hardcore") ]]; then
          local system_name=$(get_setting_name "$current_setting_line" "retrodeck") # Read the variable name from the current line
          local system_enabled=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$current_section") # Read the variables value from active retrodeck.cfg
          if [[ "$system_enabled" == "true" ]]; then
            build_preset_config "$system_name" "$current_section"
          fi
        fi
      fi
    fi
  done < "$rd_conf"
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
