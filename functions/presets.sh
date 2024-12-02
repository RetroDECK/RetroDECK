#!/bin/bash

change_preset_dialog() {
  # This function will build a list of all systems compatible with a given preset, their current enable/disabled state and allow the user to change one or more
  # USAGE: change_preset_dialog "$preset"

  preset="$1"
  pretty_preset_name=${preset//_/ } # Preset name prettification
  pretty_preset_name=$(echo $pretty_preset_name | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1') # Preset name prettification
  current_preset_settings=()
  local section_results=$(sed -n '/\['"$preset"'\]/, /\[/{ /\['"$preset"'\]/! { /\[/! p } }' $rd_conf | sed '/^$/d')

  while IFS= read -r config_line
    do
      system_name=$(get_setting_name "$config_line" "retrodeck")
      system_value=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$preset")
      current_preset_settings=("${current_preset_settings[@]}" "$system_value" "$(make_name_pretty $system_name)" "$system_name")
  done < <(printf '%s\n' "$section_results")

  choice=$(rd_zenity \
    --list --width=1200 --height=720 \
    --checklist \
    --separator="," \
    --hide-column=3 --print-column=3 \
    --text="Enable $pretty_preset_name:" \
    --column "Enabled" \
    --column "Emulator" \
    --column "internal_system_name" \
    "${current_preset_settings[@]}")

  local rc=$?

  if [[ ! -z $choice || "$rc" == 0 ]]; then
    (
      make_preset_changes "$1" "$choice"
    ) |
    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility - Presets Configuration" \
    --text="Setting up your presets, please wait..."
  else
    log i "No preset choices made"
  fi
}

build_preset_list_options() {
  # This function will build a list of all the systems available for a given preset
  # The list will be generated into a Godot temp file and the variable $current_preset_settings
  # The other arrays built (all_systems, changed_systems etc.) are also used in the make_preset_changes() function, so this needs to be called in the same memory space as that function at least once
  # USAGE: build_preset_list_options "$preset"

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
  ' $features)

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
      build_preset_config $emulator ${changed_presets[*]}
    done
}

build_preset_config() {
  # This function will apply one or more presets for a given system, as listed in retrodeck.cfg
  # USAGE: build_preset_config "system name" "preset class 1" "preset class 2" "preset class 3"
  
  local system_being_changed="$1"
  shift
  local presets_being_changed="$*"
  for current_preset in $presets_being_changed
  do
    local preset_section=$(sed -n '/\['"$current_preset"'\]/, /\[/{ /\['"$current_preset"'\]/! { /\[/! p } }' $rd_conf | sed '/^$/d')
    while IFS= read -r system_line
    do
      local read_system_name=$(get_setting_name "$system_line")
      if [[ "$read_system_name" == "$system_being_changed" ]]; then
        local read_system_enabled=$(get_setting_value "$rd_conf" "$read_system_name" "retrodeck" "$current_preset")
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

           "rewrite" )
              if [[ "$read_preset" == "$current_preset" ]]; then
                if [[ "$read_system_enabled" == "true" ]]; then
                  if [[ "$new_setting_value" = \$* ]]; then
                    eval new_setting_value=$new_setting_value
                  fi
                  echo -n "$new_setting_value" > "$read_target_file"
                fi
              fi
            ;;

            "enable" )
              if [[ "$read_preset" == "$current_preset" ]]; then
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
