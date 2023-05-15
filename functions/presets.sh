#!/bin/bash

change_preset_dialog() {
  # This function will build a list of all systems compatible with a given preset, their current enable/disabled state and allow the user to change one or more
  # USAGE: change_preset_dialog "$preset"

  local preset="$1"
  pretty_preset_name=${preset//_/ } # Preset name prettification
  pretty_preset_name=$(echo $pretty_preset_name | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1') # Preset name prettification
  local current_preset_settings=()
  local current_enabled_systems=()
  local current_disabled_systems=()
  local changed_systems=()
  local changed_presets=()
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
  done < <(printf '%s\n' "$section_results")

  choice=$(zenity \
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
    IFS="," read -ra choices <<< "$choice"
    for emulator in "${all_systems[@]}"; do
      if [[ " ${choices[*]} " =~ " ${emulator} " && ! " ${current_enabled_systems[*]} " =~ " ${emulator} " ]]; then
        changed_systems=("${changed_systems[@]}" "$emulator")
        if [[ ! " ${changed_presets[*]} " =~ " ${preset} " ]]; then
          changed_presets=("${changed_presets[@]}" "$preset")
        fi
        set_setting_value "$rd_conf" "$emulator" "true" "retrodeck" "$preset"
        # Check for conflicting presets for this system
        while IFS=: read -r preset_being_checked known_incompatible_preset; do
          if [[ "$preset" == "$preset_being_checked" ]]; then
            if [[ $(get_setting_value "$rd_conf" "$emulator" "retrodeck" "$known_incompatible_preset") == "true" ]]; then
              changed_presets=("${changed_presets[@]}" "$known_incompatible_preset")
              set_setting_value "$rd_conf" "$emulator" "false" "retrodeck" "$known_incompatible_preset"
            fi
          fi
        done < "$incompatible_presets_reference_list"
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
  else
    echo "No choices made"
  fi
}

resolve_preset_conflicts() {
  # This function will resolve conflicts between setting presets. ie. borders and widescreen cannot both be enabled at the same time.
  # The function will read the $section_that_was_just_enabled and $section_to_check_for_conflicts
  # If a conflict is found (where two conflicting settings are both enabled) the $section_to_check_for_conflicts entry will be disabled
  # USAGE: resolve_preset_conflict "$section_that_was_just_enabled" "$section_to_check_for_conflicts" "system"

  local section_being_enabled=$1
  local section_to_check_for_conflicts=$2
  local system=$3
  local enabled_section_results=$(sed -n '/\['"$section_being_enabled"'\]/, /\[/{ /\['"$section_being_enabled"'\]/! { /\[/! p } }' $rd_conf | sed '/^$/d')

  while IFS= read -r config_line
    do
      system_name=$(get_setting_name "$config_line" $system)
      system_value=$(get_setting_value $rd_conf "$system_name" $system $section_being_enabled)
      if [[ $system_value == "true" && $(get_setting_value $rd_conf "$(get_setting_name "$config_line" $system)" $system $section_to_check_for_conflicts) == "true" ]]; then
        set_setting_value $rd_conf $system_name "false" retrodeck $section_to_check_for_conflicts
      fi
  done < <(printf '%s\n' "$enabled_section_results")
}

build_preset_config(){
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
        while IFS='^' read -r action read_preset read_setting_name new_setting_value section
        do
          case "$action" in

          "config_file_format" )
            local read_config_format="$read_preset"
          ;;

          "target_file" )
            if [[ "$read_preset" = \$* ]]; then
              eval read_preset=$read_preset
            fi
            local read_target_file="$read_preset"
          ;;

          "defaults_file" )
            if [[ "$read_preset" = \$* ]]; then
              eval read_preset=$read_preset
            fi
            local read_defaults_file="$read_preset"
          ;;

          "change" )
            if [[ "$read_preset" == "$current_preset" ]]; then
              if [[ "$read_system_enabled" == "true" ]]; then
                if [[ "$new_setting_value" = \$* ]]; then
                  eval new_setting_value=$new_setting_value
                fi
                if [[ "$read_config_format" == "retroarch" ]]; then # If this is a RetroArch core, generate the override file
                  if [[ -z $(grep "$read_setting_name" "$read_target_file") ]]; then
                    if [[ ! -f "$read_target_file" ]]; then
                      mkdir -p "$(realpath $(dirname "$read_target_file"))"
                      echo "$read_setting_name = ""$new_setting_value""" > "$read_target_file"
                    else
                      add_setting "$read_target_file" "$read_setting_name" "$new_setting_value" "$read_config_format" "$section"
                    fi
                  else
                    set_setting_value "$read_target_file" "$read_setting_name" "$new_setting_value" "$read_config_format" "$section"
                  fi
                else
                  if [[ "$read_config_format" == "retroarch-all" ]]; then
                    read_config_format="retroarch"
                  fi
                  set_setting_value "$read_target_file" "$read_setting_name" "$new_setting_value" "$read_config_format" "$section"
                fi
              else
                if [[ "$read_config_format" == "retroarch" ]]; then
                  if [[ -f "$read_target_file" ]]; then
                    delete_setting "$read_target_file" "$read_setting_name" "$read_config_format" "$section"
                    if [[ -z $(cat "$read_target_file") ]]; then # If the override file is empty
                      rm -f "$read_target_file"
                    fi
                    if [[ -z $(ls -1 $(dirname "$read_target_file")) ]]; then # If the override folder is empty
                      rmdir "$(dirname $read_target_file)"
                    fi
                  fi
                else
                  if [[ "$read_config_format" == "retroarch-all" ]]; then
                    read_config_format="retroarch"
                  fi
                  local default_setting_value=$(get_setting_value "$read_defaults_file" "$read_setting_name" "$read_config_format" "$section")
                  set_setting_value "$read_target_file" "$read_setting_name" "$default_setting_value" "$read_config_format" "$section"
                fi
              fi
            fi
          ;;

          "enable" )
            if [[ "$read_preset" == "$current_preset" ]]; then
              if [[ "$read_system_enabled" == "true" ]]; then
                enable_file "$read_setting_name"
              else
                diable_file "$read_setting_name"
              fi
            fi
          ;;

          * )
            echo "Other data: $action $read_preset $read_setting_name $new_setting_value $section" # DEBUG
          ;;

          esac
        done < <(cat "$presets_dir/$read_system_name"_presets.cfg)
      fi
    done < <(printf '%s\n' "$preset_section")
  done
}
