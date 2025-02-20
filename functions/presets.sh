#!/bin/bash

change_preset_dialog() {
  # This function will build a list of all systems compatible with a given preset,
  # show their current enable/disabled state and allow the user to change one or more.
  # USAGE: change_preset_dialog "$preset"

  log d "Starting change_preset_dialog for preset: $preset"

  preset="$1"
  pretty_preset_name=${preset//_/ }  # Preset name prettification
  pretty_preset_name=$(echo "$pretty_preset_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1')
  current_preset_settings=()
  local section_results
  section_results=$(sed -n '/\['"$preset"'\]/, /\[/{ /\['"$preset"'\]/! { /\[/! p } }' "$rd_conf" | sed '/^$/d')

  while IFS= read -r config_line; do
      system_name=$(get_setting_name "$config_line" "retrodeck")
      system_value=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$preset")
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
  local extra_action=""

  log d "User made a choice: $choice with return code: $rc"

  # Handle extra button responses.
  if [ "$choice" == "Enable All" ]; then
      log d "Enable All selected"
      # Build a comma-separated list of all internal system names.
      all_systems=""
      for ((i=2; i<${#current_preset_settings[@]}; i+=3)); do
          if [ -z "$all_systems" ]; then
              all_systems="${current_preset_settings[$i]}"
          else
              all_systems="$all_systems,${current_preset_settings[$i]}"
          fi
      done
      choice="$all_systems"
      extra_action="extra"
      force_state="true"
  elif [ "$choice" == "Disable All" ]; then
      log d "Disable All selected"
      # Build a comma-separated list of all internal system names.
      all_systems=""
      for ((i=2; i<${#current_preset_settings[@]}; i+=3)); do
          if [ -z "$all_systems" ]; then
              all_systems="${current_preset_settings[$i]}"
          else
              all_systems="$all_systems,${current_preset_settings[$i]}"
          fi
      done
      choice="$all_systems"
      extra_action="extra"
      force_state="false"
  fi

  # Call make_preset_changes if the user made a selection,
  # or if an extra button was clicked (even if the resulting choice is empty).
  if [[ "$rc" == 0 || "$extra_action" == "extra" || -n "$choice" ]]; then
    log d "Calling make_preset_changes with choice: $choice"
    (
      make_preset_changes "$preset" "$choice" "$force_state"
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
  pretty_preset_name=$(echo $pretty_preset_name | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1') # Preset name prettification
  current_preset_settings=()
  current_enabled_systems=()
  current_disabled_systems=()
  changed_systems=()
  changed_presets=()
  all_systems=()
  local section_results=$(sed -n '/\['"$preset"'\]/, /\[/{ /\['"$preset"'\]/! { /\[/! p } }' $rd_conf | sed '/^$/d')

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
      current_preset_settings=("${current_preset_settings[@]}" "$system_value" "$(make_name_pretty $system_name)" "$system_name")
      echo "$system_value"^"$(make_name_pretty $system_name)"^"$system_name" >> "$godot_current_preset_settings"
  done < <(printf '%s\n' "$section_results")
}


make_preset_changes() {
  # This function takes a preset name ($1) and a CSV list ($2) of system names.
  # If a third parameter is provided (force_state), it forces the specified state (true/false)
  # for only the systems in the CSV list. Otherwise, it toggles the current state.
  #
  # USAGE: make_preset_changes $preset $choice [force_state]
  #
  # Examples:
  # Force "borders" to be true for gba:
  #   make_preset_changes "borders" "gba" true
  # Force "borders" to be true for all supported systems:
  #   make_preset_changes "borders" "all" true
  # Toggle gba in preset "borders", this will disable the enabled and vice versa:
  #   make_preset_changes "borders" "gba" true
  # Toggle all in preset "borders":
  #   make_preset_changes "borders" "all"

  log d "Fetching incompatible presets from JSON file"
  incompatible_presets=$(jq -r '
    .incompatible_presets | to_entries[] |
    [
      "\(.key):\(.value)",
      "\(.value):\(.key)"
    ] | join("\n")
  ' "$features")

  preset="$1"
  choice="$2"
  force_state="${3:-}"

  log d "Building preset list options for preset: $preset"
  build_preset_list_options "$preset"

  IFS="," read -ra choices <<< "$choice"
  if [[ " ${choices[*]} " == *" all "* ]]; then
    log d "All systems selected for preset: $preset"
    choices=("${all_systems[@]}")
  fi

  # Use an associative array to store the new state for each emulator.
  declare -A emulator_state

  # Iterate only over the specified systems.
  for emulator in "${choices[@]}"; do
    if [[ -n "$force_state" ]]; then
      new_state="$force_state"
      log d "Forcing $preset to state: $new_state for $emulator"
    else
      current_state=$(get_setting_value "$rd_conf" "$emulator" "retrodeck" "$preset")
      if [[ "$current_state" == "true" ]]; then
        new_state="false"
        if [[ $emulator == "all" ]]; then
          log i "Toggling off $preset for all systems"
        else
          log i "Toggling off $preset for system: $emulator"
        fi
      else
        if [[ $emulator == "all" ]]; then
          log i "Toggling on $preset for all systems"
        else
          new_state="true"
          log i "Toggling on $preset for system: $emulator"
        fi
      fi
    fi

    emulator_state["$emulator"]="$new_state"
    changed_systems=("${changed_systems[@]}" "$emulator")
    [[ ! " ${changed_presets[*]} " =~ " ${preset} " ]] && changed_presets=("${changed_presets[@]}" "$preset")
    set_setting_value "$rd_conf" "$emulator" "$new_state" "retrodeck" "$preset"

    # If enabling the emulator, disable any conflicting presets.
    if [[ "$new_state" == "true" ]]; then
      while IFS=: read -r preset_being_checked known_incompatible_preset || [[ -n "$preset_being_checked" ]]; do
        if [[ ! $preset_being_checked =~ ^# ]] && [[ -n "$preset_being_checked" ]]; then
          if [[ "$preset" == "$preset_being_checked" ]] && [[ $(get_setting_value "$rd_conf" "$emulator" "retrodeck" "$known_incompatible_preset") == "true" ]]; then
            log d "Disabling conflicting preset: $known_incompatible_preset for emulator: $emulator"
            changed_presets=("${changed_presets[@]}" "$known_incompatible_preset")
            set_setting_value "$rd_conf" "$emulator" "false" "retrodeck" "$known_incompatible_preset"
          fi
        fi
      done < <(echo "$incompatible_presets")
    fi

    # Adjust the custom viewport dimensions to scale it correctly
    if [[ "$read_setting_name" == "custom_viewport_width" || "$read_setting_name" == "custom_viewport_height" ]]; then
      local scaled_width=$(( (75 * $width) / 100 ))  # For example, 75% width scaled
      local scaled_height=$(( (80 * $height) / 100 ))  # For example, 80% height scaled

      if [[ "$read_setting_name" == "custom_viewport_width" ]]; then
        new_setting_value=$scaled_width
        log d "Adjusted custom_viewport_width: $new_setting_value"
      elif [[ "$read_setting_name" == "custom_viewport_height" ]]; then
        new_setting_value=$scaled_height
        log d "Adjusted custom_viewport_height: $new_setting_value"
      fi
    fi

    # Adjust the custom viewport Y to fit inside the screen bounds
    if [[ "$read_setting_name" == "custom_viewport_y" ]]; then
      # Center the viewport vertically
      local viewport_y_offset=$(( ($height - $scaled_height) / 2 ))  # Adjust for scaled height
      new_setting_value=$viewport_y_offset
      log d "Adjusted custom_viewport_y: $new_setting_value"
    fi

    # Adjust the custom viewport X if needed (same logic as Y)
    if [[ "$read_setting_name" == "custom_viewport_x" ]]; then
      local viewport_x_offset=$(( ($width - $scaled_width) / 2 ))  # Center horizontally
      new_setting_value=$viewport_x_offset
      log d "Adjusted custom_viewport_x: $new_setting_value"
    fi

  done

  # Rebuild config for all changed systems.
  for emulator in "${changed_systems[@]}"; do
    log d "Building preset config for changed emulator: $emulator"
    if [[ "${emulator_state[$emulator]}" == "true" ]]; then
      # When enabling, force a full config update (detailed settings applied).
      build_preset_config "$emulator" "${changed_presets[*]}" true
    else
      build_preset_config "$emulator" "${changed_presets[*]}"
    fi
  done
}

build_preset_config() {
  # This function will apply one or more presets for a given system, as listed in retrodeck.cfg
  # USAGE: build_preset_config "system name" "preset class 1" "preset class 2" "preset class 3"
  
  local system_being_changed="$1"
  shift
  local presets_being_changed="$*"
  log d "Applying presets: $presets_being_changed for system: $system_being_changed"
  
  for current_preset in $presets_being_changed; do
    local preset_section=$(sed -n '/\['"$current_preset"'\]/, /\[/{ /\['"$current_preset"'\]/! { /\[/! p } }' $rd_conf | sed '/^$/d')
    
    while IFS= read -r system_line; do
      local read_system_name=$(get_setting_name "$system_line")
      if [[ "$read_system_name" == "$system_being_changed" ]]; then
        local read_system_enabled=$(get_setting_value "$rd_conf" "$read_system_name" "retrodeck" "$current_preset")
        log d "Processing system: $read_system_name with preset: $current_preset, enabled: $read_system_enabled"
        
        while IFS='^' read -r action read_preset read_setting_name new_setting_value section target_file defaults_file || [[ -n "$action" ]]; do
          if [[ ! $action == "#"* ]] && [[ ! -z "$action" ]]; then
            case "$action" in

            "config_file_format")
              if [[ "$read_preset" == "retroarch-all" ]]; then
                local retroarch_all="true"
                local read_config_format="retroarch"
              else
                local read_config_format="$read_preset"
              fi
              log d "Config file format: $read_config_format"
              ;;

            "change")
              if [[ "$read_preset" == "$current_preset" ]]; then
                if [[ "$target_file" = \$* ]]; then # Resolve target file if it is a variable
                  eval target_file=$target_file
                fi
                local read_target_file="$target_file"
                if [[ "$defaults_file" = \$* ]]; then # Resolve defaults file if it is a variable
                  eval defaults_file=$defaults_file
                fi
                local read_defaults_file="$defaults_file"
                
# Handle calc expressions for all settings (viewport and overlay)
if [[ "$new_setting_value" =~ ^calc:([0-9]+)%:\$([a-zA-Z0-9_]+) ]]; then
  local percent="${BASH_REMATCH[1]}"
  local variable="${BASH_REMATCH[2]}"
  local value="${!variable}"  # Get the value of $width or $height
  
  # Ensure value is numeric
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    # Perform integer calculation (multiplying and then dividing by 100)
    new_setting_value=$(( (percent * value) / 100 ))
    log d "Calculated new_setting_value: $new_setting_value for calc: $percent%:$variable"
  else
    log e "Error: $variable value is not numeric. Value: $value"
  fi
fi

# Adjust the custom viewport dimensions to scale it correctly
if [[ "$read_setting_name" == "custom_viewport_width" || "$read_setting_name" == "custom_viewport_height" ]]; then
  local scaled_width=$(( (75 * $width) / 100 ))  # For example, 75% width scaled
  local scaled_height=$(( (80 * $height) / 100 ))  # For example, 80% height scaled

  if [[ "$read_setting_name" == "custom_viewport_width" ]]; then
    new_setting_value=$scaled_width
    log d "Adjusted custom_viewport_width: $new_setting_value"
  elif [[ "$read_setting_name" == "custom_viewport_height" ]]; then
    new_setting_value=$scaled_height
    log d "Adjusted custom_viewport_height: $new_setting_value"
  fi
fi

# Adjust the custom viewport Y to fit inside the screen bounds
if [[ "$read_setting_name" == "custom_viewport_y" ]]; then
  # Center the viewport vertically
  local viewport_y_offset=$(( ($height - $scaled_height) / 2 ))  # Adjust for scaled height
  new_setting_value=$viewport_y_offset
  log d "Adjusted custom_viewport_y: $new_setting_value"
fi

# Adjust the custom viewport X if needed (same logic as Y)
if [[ "$read_setting_name" == "custom_viewport_x" ]]; then
  local viewport_x_offset=$(( ($width - $scaled_width) / 2 ))  # Center horizontally
  new_setting_value=$viewport_x_offset
  log d "Adjusted custom_viewport_x: $new_setting_value"
fi

                log d "Changing setting: $read_setting_name to $new_setting_value in $read_target_file"
                if [[ "$read_system_enabled" == "true" ]]; then
                  if [[ "$new_setting_value" = \$* ]]; then
                    eval new_setting_value=$new_setting_value
                  fi
                  if [[ "$read_config_format" == "retroarch" && ! "$retroarch_all" == "true" ]]; then # If this is a RetroArch core, generate the override file
                    if [[ ! -f "$read_target_file" ]]; then
                      create_dir "$(realpath "$(dirname "$read_target_file")")"
                      echo "$read_setting_name = \""$new_setting_value"\"" > "$read_target_file"
                    else
                      if [[ -z $(grep -o -P "^$read_setting_name\b" "$read_target_file") ]]; then
                        add_setting "$read_target_file" "$read_setting_name" "$new_setting_value" "$read_config_format" "$section"
                      else
                        set_setting_value "$read_target_file" "$read_setting_name" "$new_setting_value" "$read_config_format" "$section"
                      fi                    
                    fi
                  else
                    set_setting_value "$read_target_file" "$read_setting_name" "$new_setting_value" "$read_config_format" "$section"
                  fi
                else
                  if [[ "$read_config_format" == "retroarch" && ! "$retroarch_all" == "true" ]]; then
                    if [[ -f "$read_target_file" ]]; then
                      delete_setting "$read_target_file" "$read_setting_name" "$read_config_format" "$section"
                      if [[ -z $(cat "$read_target_file") ]]; then # If the override file is empty
                        rm -f "$read_target_file"
                      fi
                      if [[ -z $(ls -1 "$(dirname "$read_target_file")") ]]; then # If the override folder is empty
                        rmdir "$(realpath "$(dirname "$read_target_file")")"
                      fi
                    fi
                  else
                    local default_setting_value=$(get_setting_value "$read_defaults_file" "$read_setting_name" "$read_config_format" "$section")
                    set_setting_value "$read_target_file" "$read_setting_name" "$default_setting_value" "$read_config_format" "$section"
                  fi
                fi
              fi
              ;;

            "rewrite")
              if [[ "$read_preset" == "$current_preset" ]]; then
                if [[ "$target_file" = \$* ]]; then # Read current target file and resolve if it is a variable
                  eval target_file=$target_file
                fi
                local read_target_file="$target_file"
                if [[ "$defaults_file" = \$* ]]; then # Read current defaults file and resolve if it is a variable
                  eval defaults_file=$defaults_file
                fi
                local read_defaults_file="$defaults_file"
                log d "Rewriting setting: $read_setting_name to $new_setting_value in $read_target_file"
                if [[ "$read_system_enabled" == "true" ]]; then
                  if [[ "$new_setting_value" = \$* ]]; then # Resolve new setting value if it is a variable
                    eval new_setting_value=$new_setting_value
                  fi
                  echo -n "$new_setting_value" > "$read_target_file" # Write the new setting value to the target file
                else
                  cat "$read_defaults_file" > "$read_target_file" # Restore the default settings from the defaults file
                fi
              fi
              ;;

            "enable")
              if [[ "$read_preset" == "$current_preset" ]]; then
                log d "Enabling file: $read_setting_name"
                if [[ "$read_system_enabled" == "true" ]]; then
                  enable_file "$read_setting_name"
                else
                  disable_file "$read_setting_name"
                fi
              fi
              ;;

            *)
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
        local current_section=$(sed 's^[][]^^g' <<< $current_setting_line) # Remove brackets from section name
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
  done < $rd_conf
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
              pretty_preset_name=$(echo $pretty_preset_name | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1') # Preset name prettification
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
              pretty_preset_name=$(echo $pretty_preset_name | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1') # Preset name prettification
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
