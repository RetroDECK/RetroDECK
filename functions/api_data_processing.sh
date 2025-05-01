#!/bin/bash

# This is the main data processing hub for the RetroDECK API.
# It will handle the direct demands of the API requests by leveraging the rest of the RetroDECK functions.
# Most of these functions will have been adapted from the ones built for the Zenity Configurator, with the Zenity specifics pulled out and all data passed through JSON objects.

api_get_compressible_games() {
  # Supported parameters:
  # "everything"  - All games found (regardless of format)
  # "all"         - Only user-chosen games (later selected via checklist)
  # "chd", "zip", "rvz" - Only games matching that compression type

  log d "Started find_compatible_games with parameter: $1"

  local compression_format

  if [[ "$1" == "everything" ]]; then
    compression_format="all"
  else
    compression_format="$1"
  fi

  local compressible_systems_list
  if [[ "$compression_format" == "all" ]]; then
    compressible_systems_list=$(jq -r '.compression_targets | to_entries[] | .value[]' "$features")
    log d "compressible_systems_list: $compressible_systems_list"
  else
    compressible_systems_list=$(jq -r '.compression_targets["'"$compression_format"'"][]' "$features")
    log d "compressible_systems_list: $compressible_systems_list"
  fi

  log d "Finding compatible games for compression ($1)"
  log d "compression_targets: $compression_targets"

  local compressible_games_list="$(mktemp)"

  # Initialize the empty JSON file meant for final output
  echo '[]' > "$compressible_games_list"

  while IFS= read -r system; do
    while (( $(jobs -p | wc -l) >= $max_threads )); do # Wait for a background task to finish if max_threads has been hit
      sleep 0.1
    done
    (
    if [[ -d "$roms_folder/$system" ]]; then
      local compression_candidates
      compression_candidates=$(find "$roms_folder/$system" -type f -not -iname "*.txt")
      if [[ -n "$compression_candidates" ]]; then
        while IFS= read -r game; do
          while (( $(jobs -p | wc -l) >= $max_threads )); do # Wait for a background task to finish if max_threads has been hit
            sleep 0.1
          done
          (
          local compatible_compression_format
          compatible_compression_format=$(find_compatible_compression_format "$game")
          if [[ -f "${game%.*}.$compatible_compression_format" ]]; then # If a compressed version of this game already exists
            log d "Skipping $game because a $compatible_compression_format version already exists."
            exit
          fi
          local file_ext="${game##*.}"
          case "$compression_format" in
            "chd")
              if [[ "$compatible_compression_format" == "chd" ]]; then
                log d "Game $game is compatible with CHD compression"
                # Build a JSON object for this game
                local json_obj=$(jq -n --arg game "$game" --arg compression "$compatible_compression_format" \
                '{ game: $game, compression: $compression }')
                # Write the final JSON object to the output file, locking it to prevent write race conditions.
                (
                flock -x 200
                jq --argjson obj "$json_obj" '. + [$obj]' "$compressible_games_list" > "$compressible_games_list.tmp" && mv "$compressible_games_list.tmp" "$compressible_games_list"
                ) 200>"$RD_FILE_LOCK"
              fi
              ;;
            "zip")
              if [[ "$compatible_compression_format" == "zip" ]]; then
                log d "Game $game is compatible with ZIP compression"
                # Build a JSON object for this game.
                local json_obj=$(jq -n --arg game "$game" --arg compression "$compatible_compression_format" \
                '{ game: $game, compression: $compression }')
                # Write the final JSON object to the output file, locking it to prevent write race conditions.
                (
                flock -x 200
                jq --argjson obj "$json_obj" '. + [$obj]' "$compressible_games_list" > "$compressible_games_list.tmp" && mv "$compressible_games_list.tmp" "$compressible_games_list"
                ) 200>"$RD_FILE_LOCK"
              fi
              ;;
            "rvz")
              if [[ "$compatible_compression_format" == "rvz" ]]; then
                log d "Game $game is compatible with ZIP compression"
                # Build a JSON object for this game.
                local json_obj=$(jq -n --arg game "$game" --arg compression "$compatible_compression_format" \
                '{ game: $game, compression: $compression }')
                # Write the final JSON object to the output file, locking it to prevent write race conditions.
                (
                flock -x 200
                jq --argjson obj "$json_obj" '. + [$obj]' "$compressible_games_list" > "$compressible_games_list.tmp" && mv "$compressible_games_list.tmp" "$compressible_games_list"
                ) 200>"$RD_FILE_LOCK"
              fi
              ;;
            "all")
              if [[ "$compatible_compression_format" != "none" ]]; then
                log d "Game $game is compatible with ZIP compression"
                # Build a JSON object for this game.
                local json_obj=$(jq -n --arg game "$game" --arg compression "$compatible_compression_format" \
                '{ game: $game, compression: $compression }')
                # Write the final JSON object to the output file, locking it to prevent write race conditions.
                (
                flock -x 200
                jq --argjson obj "$json_obj" '. + [$obj]' "$compressible_games_list" > "$compressible_games_list.tmp" && mv "$compressible_games_list.tmp" "$compressible_games_list"
                ) 200>"$RD_FILE_LOCK"
              fi
              ;;
          esac
        ) &
        done < <(printf '%s\n' "$compression_candidates")
        wait # wait for background tasks to finish
      fi
    else
      log d "Rom folder for $system is missing, skipping"
    fi
    ) &
  done < <(printf '%s\n' "$compressible_systems_list")
  wait # wait for background tasks to finish

  # Sort the final list numerically, then alphabetically
  local final_json=$(cat "$compressible_games_list" | jq 'sort_by([
                                                            ( .game
                                                              | sub(".*/";"")
                                                              | test("^[0-9]")
                                                              | not
                                                            ),
                                                            ( .game | sub(".*/";"") )
                                                          ])')
  rm "$compressible_games_list"

  echo "$final_json"
}

api_get_all_components() {
  # This function will gather information about all installed components, including their name, emulated systems, user-friendly name, description and all compatible presets and their acceptable values
  # USAGE: api_get_all_components

  # Initialize the empty JSON file meant for final output
  local all_components_obj="$(mktemp)"
  echo '[]' > "$all_components_obj"

  while IFS= read -r manifest_file; do
    while (( $(jobs -p | wc -l) >= $max_threads )); do # Wait for a background task to finish if max_threads has been hit
      sleep 0.1
    done
    (
      json_info=$(jq -r '
        # Grab the first top‑level key into $system_key
        (keys_unsorted[0]) as $system_key
        | .[$system_key] as $sys
        | {
            component_name: $system_key,
            data: ( {
              component_friendly_name: $sys.name,
              description: $sys.description,
              system: $sys.system
            }
            + (if $sys.compatible_presets? != null then {compatible_presets: $sys.compatible_presets} else {} end)
          )
          }
      ' "$manifest_file")
      local component_name=$(jq -r '.component_name' <<< "$json_info")
      local component_friendly_name=$(jq -r '.data.component_friendly_name // empty' <<< "$json_info")
      local description=$(jq -r '.data.description // empty' <<< "$json_info")
      local system=$(jq -r '.data.system // "none"' <<< "$json_info")
      local compatible_presets=$(jq -c '.data.compatible_presets // "none"' <<< "$json_info")
      local json_obj=$(jq -n --arg name "$component_name" --arg friendly_name "$component_friendly_name" --arg desc "$description" --arg system "$system" \
                            --argjson compatible_presets "$compatible_presets" --arg path "$(dirname "$manifest_file")" \
                            '{ component_name: $name, component_friendly_name: $friendly_name, description: $desc, emulated_system: $system, path: $path, compatible_presets: $compatible_presets }')
      (
      flock -x 200
      jq --argjson obj "$json_obj" '. + [$obj]' "$all_components_obj" > "$all_components_obj.tmp" && mv "$all_components_obj.tmp" "$all_components_obj"
      ) 200>"$RD_FILE_LOCK"
    ) &
  done < <(find "$RD_MODULES" -maxdepth 2 -mindepth 2 -type f -name "manifest.json")
  wait # Wait for background tasks to finish

  local final_json=$(jq '[.[] | select(.system_name == "retrodeck")] + ([.[] | select(.system_name != "retrodeck")] | sort_by(.system_name))' "$all_components_obj") # Ensure RetroDECK is always first in the list
  rm "$all_components_obj"

  echo "$final_json"
}

api_get_current_preset_settings() {
  # This function will gather the state (enabled/disabled/other) of all the systems in a given preset. An "all" argument can also be given which will check all presets for all components.
  # Optionally, a specific component can be added, which will make the function return the state of all presets for that one component
  # USAGE: api_get_current_preset_settings "$preset" ("$specific_component")

  local preset="$1"
  local specific_component="$2"
  local current_preset_settings='[]'
  local all_preset_settings='{}'

  if [[ "$preset" == "all" || -n "$specific_component" ]]; then
    for preset_name in $(jq -r '.presets | keys[]' "$rd_conf"); do
      if [[ ! -n "$specific_component" ]]; then
        if ! jq -e --arg preset_name "$preset_name" '. | has($preset_name)' <<< "$all_preset_settings" > /dev/null; then
          log d "Preset $preset_name not yet added to list, adding..."
          all_preset_settings=$(jq --arg preset "$preset_name" '. += { ($preset): {} }' <<< "$all_preset_settings")
        fi
        for component in $(jq -r --arg preset "$preset_name" '.presets[$preset] | keys[]' "$rd_conf"); do
          if ! jq -e --arg preset_name "$preset_name" --arg component_name "$component" '.[$preset_name] | has($component_name)' <<< "$all_preset_settings" > /dev/null; then
            log d "Component $component not yet added to list, adding..."
            local json_info=$(jq -r '
              # Grab the first top‑level key into $system_key
              (keys_unsorted[0]) as $system_key
              | .[$system_key] as $sys
              | {
                  system_name: $system_key,
                  data: {
                    system_friendly_name: $sys.name,
                    description: $sys.description,
                    emulated_system: $sys.system,
                    emulated_system_friendly_name: $sys.system_friendly_name
                  }
                }
            ' "$RD_MODULES/$component/manifest.json")
            local system_name=$(echo "$json_info" | jq -r '.system_name' )
            local system_friendly_name=$(echo "$json_info" | jq -r '.data.system_friendly_name')
            local description=$(echo "$json_info" | jq -r '.data.description')
            local emulated_system=$(echo "$json_info" | jq -r '.data.emulated_system')
            local emulated_system_friendly_name=$(echo "$json_info" | jq -r '.data.emulated_system_friendly_name')
            local preset_status=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset_name")
            local json_obj=$(jq -n --arg name "$system_name" --arg friendly_name "$system_friendly_name" --arg desc "$description" --arg emu_system "$emulated_system" \
                            --arg emu_system_friendly "$emulated_system_friendly_name" --arg status "$preset_status" \
                            '{ system_name: $name, system_friendly_name: $friendly_name, description: $desc, emulated_system: $emu_system, emulated_system_friendly_name: $emu_system_friendly, status: $status }')
            all_preset_settings=$(jq --arg preset "$preset_name" --arg component "$component" --argjson obj "$json_obj" '.[$preset][$component] = [$obj]' <<< "$all_preset_settings")
          fi
        done
      else # User specified a specific component to get preset settings for
        for component in $(jq -r --arg preset "$preset_name" '.presets[$preset] | keys[]' "$rd_conf"); do
          if ! jq -e --arg preset_name "$preset_name" --arg component_name "$specific_component" '.[$preset_name] | has($component_name)' <<< "$all_preset_settings" > /dev/null; then
            log d "Component $specific_component not yet added to list in preset $preset_name, adding..."
            if ! jq -e --arg preset_name "$preset_name" '. | has($preset_name)' <<< "$all_preset_settings" > /dev/null; then
              log d "Preset $preset_name not yet added to list, adding..."
              all_preset_settings=$(jq --arg preset "$preset_name" '. += { ($preset): {} }' <<< "$all_preset_settings")
            fi
            local json_info=$(jq -r '
              # Grab the first top‑level key into $system_key
              (keys_unsorted[0]) as $system_key
              | .[$system_key] as $sys
              | {
                  system_name: $system_key,
                  data: {
                    system_friendly_name: $sys.name,
                    description: $sys.description,
                    emulated_system: $sys.system,
                    emulated_system_friendly_name: $sys.system_friendly_name
                  }
                }
            ' "$RD_MODULES/$component/manifest.json")
            local system_name=$(echo "$json_info" | jq -r '.system_name' )
            local system_friendly_name=$(echo "$json_info" | jq -r '.data.system_friendly_name')
            local description=$(echo "$json_info" | jq -r '.data.description')
            local emulated_system=$(echo "$json_info" | jq -r '.data.emulated_system')
            local emulated_system_friendly_name=$(echo "$json_info" | jq -r '.data.emulated_system_friendly_name')
            local preset_status=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset_name")
            local json_obj=$(jq -n --arg name "$system_name" --arg friendly_name "$system_friendly_name" --arg desc "$description" --arg emu_system "$emulated_system" \
                            --arg emu_system_friendly "$emulated_system_friendly_name" --arg status "$preset_status" \
                            '{ system_name: $name, system_friendly_name: $friendly_name, description: $desc, emulated_system: $emu_system, emulated_system_friendly_name: $emu_system_friendly, status: $status }')
            all_preset_settings=$(jq --arg preset "$preset_name" --arg component "$component" --argjson obj "$json_obj" '.[$preset][$component] = [$obj]' <<< "$all_preset_settings")
          fi
        done
      fi
    done
    echo "$all_preset_settings" | jq .
  else
    for component in $(jq -r --arg preset "$preset" '.presets[$preset] | keys[]' "$rd_conf"); do
      local json_info=$(jq -r '
        # Grab the first top‑level key into $system_key
        (keys_unsorted[0]) as $system_key
        | .[$system_key] as $sys
        | {
            system_name: $system_key,
            data: {
              system_friendly_name: $sys.name,
              description: $sys.description,
              emulated_system: $sys.system,
              emulated_system_friendly_name: $sys.system_friendly_name
            }
          }
      ' "$RD_MODULES/$component/manifest.json")
      local system_name=$(echo "$json_info" | jq -r '.system_name' )
      local system_friendly_name=$(echo "$json_info" | jq -r '.data.system_friendly_name')
      local description=$(echo "$json_info" | jq -r '.data.description')
      local emulated_system=$(echo "$json_info" | jq -r '.data.emulated_system')
      local emulated_system_friendly_name=$(echo "$json_info" | jq -r '.data.emulated_system_friendly_name')
      local preset_status=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset")
      local json_obj=$(jq -n --arg name "$system_name" --arg friendly_name "$system_friendly_name" --arg desc "$description" --arg emu_system "$emulated_system" \
                          --arg emu_system_friendly "$emulated_system_friendly_name" --arg status "$preset_status" \
                          '{ system_name: $name, system_friendly_name: $friendly_name, description: $desc, emulated_system: $emu_system, emulated_system_friendly_name: $emu_system_friendly, status: $status }')
      current_preset_settings=$(jq -n --argjson existing_obj "$current_preset_settings" --argjson obj "$json_obj" '$existing_obj + [$obj]')
    done
    echo "$current_preset_settings" | jq .
  fi
}

api_get_bios_file_status() {

  local bios_files="$(mktemp)"
  echo '[]' > "$bios_files"

  while read -r entry; do
    while (( $(jobs -p | wc -l) >= $max_threads )); do # Wait for a background task to finish if max_threads has been hit
      sleep 0.1
    done
    (
    # Extract the key (element name) and the fields
    bios_file=$(echo "$entry" | jq -r '.key // "Unknown"')
    bios_md5=$(echo "$entry" | jq -r '.value.md5 | if type=="array" then join(", ") else . end // "Unknown"')
    bios_systems=$(echo "$entry" | jq -r '.value.system | if type=="array" then join(", ") else . end // "Unknown"')
    bios_desc=$(echo "$entry" | jq -r '.value.description // "No description provided"')
    required=$(echo "$entry" | jq -r '.value.required // "No"')
    bios_paths=$(echo "$entry" | jq -r '.value.paths // "'"$bios_folder"'" | if type=="array" then join(", ") else . end')

    log d "Checking entry $bios_entry"

    # Expand any embedded shell variables (e.g. $saves_folder or $bios_folder) with their actual values
    bios_paths=$(echo "$bios_paths" | envsubst)

    # Skip if bios_file is empty
    if [[ ! -z "$bios_file" ]]; then
      bios_file_found="Yes"
      bios_md5_matched="No"

      IFS=', ' read -r -a paths_array <<< "$bios_paths"
      for path in "${paths_array[@]}"; do
        if [[ ! -f "$path/$bios_file" ]]; then
          bios_file_found="No"
          break
        fi
      done

      if [[ $bios_file_found == "Yes" ]]; then
        IFS=', ' read -r -a md5_array <<< "$bios_md5"
        for md5 in "${md5_array[@]}"; do
          if [[ $(md5sum "$path/$bios_file" | awk '{ print $1 }') == "$md5" ]]; then
            bios_md5_matched="Yes"
            break
          fi
        done
      fi

      log d "BIOS file found: $bios_file_found, Hash matched: $bios_md5_matched"
      log d "Expected path: $path/$bios_file"
      log d "Expected MD5: $bios_md5"
    fi

    log d "Adding BIOS entry: \"$bios_file $bios_systems $bios_file_found $bios_md5_matched $bios_desc $bios_paths $bios_md5\" to the bios_checked_list"

    local json_obj=$(jq -n --arg file "$bios_file" --arg systems "$bios_systems" --arg found "$bios_file_found" --arg md5_matched "$bios_md5_matched" \
                          --arg desc "$bios_desc" --arg paths "$bios_paths" --arg md5 "$bios_md5" \
                          '{ file: $file, systems: $systems, file_found: $found, md5_matched: $md5_matched, description: $desc, paths: $paths, known_md5_hashes: $md5 }')
    (
    flock -x 200
    jq --argjson new_obj "$json_obj" '. + [$new_obj]' "$bios_files" > "$bios_files.tmp" && mv "$bios_files.tmp" "$bios_files"
    ) 200>"$RD_FILE_LOCK"
  ) &
  wait # wait for background tasks to finish
  done < <(jq -c '.bios | to_entries[]' "$bios_checklist")

  # Sort the final list numerically, then alphabetically by system name
  local final_json=$(cat "$bios_files" | jq 'sort_by([
                                                            ( .systems
                                                              | sub(".*/";"")
                                                              | test("^[0-9]")
                                                              | not
                                                            ),
                                                            ( .systems | sub(".*/";"") )
                                                          ])')
  rm "$bios_files"

  echo "$final_json"
}

api_get_multifile_game_structure() {
  # This function will find any files with .m3u extensions that are in a directory that does not have a name that ends in .m3u as well, which would be considered an incorrect structure for multi-file games
  # USAGE: api_check_multifile_game_structure

  local m3u_files=()
  local problem_files

  while IFS= read -r file; do
    parent_dir=$(basename "$(dirname "$file")")
    if [[ "$parent_dir" != *.m3u ]]; then
        m3u_files+=("$file")
    fi
  done < <(find "$roms_folder" -type d -name ".*" -prune -o -type f -name "*.m3u" -print)

  if [[ ${#m3u_files[@]} -gt 0 ]]; then
    problem_files='[]'
    for file in "${m3u_files[@]}"; do
      local json_obj=$(jq -n --arg file "$file" '{ incorrect_file: $file }')
      problem_files=$(jq -n --argjson existing_obj "$problem_files" --argjson new_obj "$json_obj" '$existing_obj + [$new_obj]')
    done
    echo "$problem_files"
    return 1
  else
    echo "no multifile game structure issues found"
    return 0
  fi
}

api_set_preset_state() {

  local component="$1"
  local preset="$2"
  local state="$3"

  local current_preset_state=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset")
  local preset_disabled_state=$(jq -r --arg component "$component" --arg preset "$preset" '.[$component].compatible_presets[$preset].[0] // empty' "$RD_MODULES/$component/manifest.json")

  if [[ -n "$current_preset_state" ]]; then # Component entry exists for given preset in retrodeck.cfg
    if [[ -n "$preset_disabled_state" ]]; then # The disabled state for that preset for that component could be determined
      if jq -e --arg component "$component" --arg preset "$preset" --arg state "$state" '.[$component].compatible_presets[$preset] | index($state) !=null' "$RD_MODULES/$component/manifest.json" > /dev/null; then # Validate that the desired preset state is valid for this component and preset
        if [[ "$current_preset_state" == "$state" ]]; then # Preset is already in desired state
          echo "component $component is already in state $state for preset $preset"
          return 1
        elif [[ "$state" == "$preset_disabled_state" ]]; then # Preset is being disabled and is not currently disabled
          log d "Disabling preset $preset for component $component"
          set_setting_value "$rd_conf" "$component" "$state" "retrodeck" "$preset"
        else # Preset is being enabled
          while read -r preset_key; do # Check for incompatible preset conflicts
            local preset_key_value=$(jq -r --arg preset_key "$preset_key" '.incompatible_presets[$preset_key]' "$features")
            if [[ "$preset_key" == "$preset" ]]; then # If incompatible key name matches desired preset
              if jq -e --arg component "$component" --arg preset "$preset_key_value" '.presets[$preset] | has($component)' "$rd_conf" > /dev/null; then # If the incompatible preset has an entry for this component
                incompatible_preset_disabled_state=$(jq -r --arg component "$component" --arg preset "$preset_key_value" '.[$component].compatible_presets[$preset].[0] // empty' "$RD_MODULES/$component/manifest.json")
                incompatible_preset_current_state=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset_key_value")
                if [[ ! "$incompatible_preset_current_state" == "$incompatible_preset_disabled_state" ]]; then # If the incompatible preset is enabled
                  echo "incompatible preset $preset_key_value is currently enabled, cannot enable $preset"
                  return 1
                fi
              fi
            elif [[ "$preset_key_value" == "$preset" ]]; then # If incompatible key value matches desired preset
              if jq -e --arg component "$component" --arg preset "$preset_key" '.presets[$preset] | has($component)' "$rd_conf" > /dev/null; then # If the incompatible preset has an entry for this component
                incompatible_preset_disabled_state=$(jq -r --arg component "$component" --arg preset "$preset_key" '.[$component].compatible_presets[$preset].[0] // empty' "$RD_MODULES/$component/manifest.json")
                incompatible_preset_current_state=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset_key")
                if [[ ! "$incompatible_preset_current_state" == "$incompatible_preset_disabled_state" ]]; then # If the incompatible preset is enabled
                  echo "incompatible preset $preset_key is currently enabled, cannot enable $preset"
                  return 1
                fi
              fi
            fi
          done < <(jq -r '.incompatible_presets | keys[]' "$features")

          if [[ "$preset" == "cheevos" ]]; then # For cheevos preset, ensure login data is available
            if [[ -n "$cheevos_token" && -n "$cheevos_username" ]]; then
              log d "Cheevos login info exists"
            else
              echo "login information for cheevos preset not available"
              return 1
            fi
          fi

          log d "Enabling preset $preset for component $component"
          set_setting_value "$rd_conf" "$component" "$state" "retrodeck" "$preset" # No incompatibilities found, enabling preset
        fi
      else
        echo "desired state $state for component $component preset $preset is invalid"
        return 1
      fi
    else
      echo "disabled state for component $component preset $preset could not be determined"
      return 1
    fi
  else
    echo "component $component not compatible with preset $preset"
    return 1
  fi

  log d "Preset change passed all prechecks, continuing..."

  local config_format=$(jq -r --arg component "$component" '.[$component].preset_actions.config_file_format' "$RD_MODULES/$component/manifest.json")
  if [[ "$config_format" == "retroarch-all" ]]; then
    local retroarch_all="true"
    local config_format="retroarch"
  fi
  log d "Config file format: $config_format"

  while IFS= read -r preset_setting_name; do
    current_preset_object=$(jq -r --arg component "$component" --arg preset "$preset" --arg preset_setting_name "$preset_setting_name" \
                                    '.[$component].preset_actions[$preset][$preset_setting_name]' "$RD_MODULES/$component/manifest.json")
    action=$(echo "$current_preset_object" | jq -r '.action')

    case "$action" in

      "change" )
        log d "Changing config file for preset: $preset_setting_name"
        new_setting_value=$(echo "$current_preset_object" | jq -r '.new_setting_value')
        section=$(echo "$current_preset_object" | jq -r '.section')
        target_file=$(echo "$current_preset_object" | jq -r '.target_file')
        defaults_file=$(echo "$current_preset_object" | jq -r '.defaults_file')

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

        if [[ ! "$state" == "$preset_disabled_state" ]]; then # Preset is being enabled
          if [[ "$new_setting_value" = \$* ]]; then
            eval new_setting_value=$new_setting_value
            log d "New setting value is a variable. Actual setting value is $new_setting_value"
          fi
          if [[ "$read_config_format" == "retroarch" && ! "$retroarch_all" == "true" ]]; then # Separate process if this is a per-system RetroArch override file
            if [[ ! -f "$read_target_file" ]]; then
              log d "RetroArch per-system override file $read_target_file not found, creating and adding setting"
              create_dir "$(realpath "$(dirname "$read_target_file")")"
              echo "$preset_setting_name = \""$new_setting_value"\"" > "$read_target_file"
            else
              if [[ -z $(grep -o -P "^$preset_setting_name\b" "$read_target_file") ]]; then
                log d "RetroArch per-system override file $read_target_file does not contain setting $preset_setting_name, adding and assigning value $new_setting_value"
                add_setting "$read_target_file" "$preset_setting_name" "$new_setting_value" "$read_config_format" "$section"
              else
                log d "Changing setting: $preset_setting_name to $new_setting_value in $read_target_file"
                set_setting_value "$read_target_file" "$preset_setting_name" "$new_setting_value" "$read_config_format" "$section"
              fi
            fi
          elif [[ "$read_config_format" == "ppsspp" && "$read_target_file" == "$ppssppcheevosconf" ]]; then # Separate process if this is the standalone cheevos token file used by PPSSPP
            log d "Creating PPSSPP cheevos token file $ppssppcheevosconf"
            echo "$new_setting_value" > "$read_target_file"
          else
            log d "Changing setting: $preset_setting_name to $new_setting_value in $read_target_file"
            set_setting_value "$read_target_file" "$preset_setting_name" "$new_setting_value" "$read_config_format" "$section"
          fi
        else # Preset is being disabled
          if [[ "$read_config_format" == "retroarch" && ! "$retroarch_all" == "true" ]]; then # Separate process if this is a per-system RetroArch override file
            if [[ -f "$read_target_file" ]]; then
              log d "Removing setting $preset_setting_name from RetroArch per-system override file $read_target_file"
              delete_setting "$read_target_file" "$preset_setting_name" "$read_config_format" "$section"
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
            local default_setting_value=$(get_setting_value "$read_defaults_file" "$preset_setting_name" "$read_config_format" "$section")
            log d "Changing setting: $preset_setting_name to $default_setting_value in $read_target_file"
            set_setting_value "$read_target_file" "$preset_setting_name" "$default_setting_value" "$read_config_format" "$section"
          fi
        fi
      ;;

      "enable" )
        log d "Enabling/disabling file: $preset_setting_name"
        target_file=$(echo "$current_preset_object" | jq -r '.target_file')
        if [[ ! "$state" == "$preset_disabled_state" ]]; then
          enable_file "$preset_setting_name"
        else
          disable_file "$preset_setting_name"
        fi
      ;;

      "install" )
        source_file=$(echo "$current_preset_object" | jq -r '.source')
        target_file=$(echo "$current_preset_object" | jq -r '.destination')
        if [[ ! "$state" == "$preset_disabled_state" ]]; then
          log d "Installing files for preset $preset_setting_name"
          install_preset_files "$source_file" "$target_file"
        else
          log d "Removing files for preset $preset_setting_name"
          remove_preset_files "$source_file" "$target_file"
        fi
      ;;

      * )
        log d "Other data: $action $preset_setting_name $new_setting_value $section" # DEBUG
      ;;

    esac
  done < <(jq -r --arg component "$component" --arg preset "$preset" '.[$component].preset_actions[$preset] | keys[]' "$RD_MODULES/$component/manifest.json")

  echo "preset $preset for component $component was successfully changed to $state"
}

api_do_install_retrodeck_package() {

  local package_name="$1"

  case "$package_name" in

    "retrodeck_controller_profile" )
      install_retrodeck_controller_profile
      echo "retrodeck controller profile installed"
    ;;

    * )
      echo "unknown package name: $package_name"
    ;;

  esac
}

api_do_cheevos_login() {
  # This function will attempt to authenticate with the RA API with the supplied credentials and will return a JSON object if successful
  # USAGE api_do_cheevos_login $username $password

  local cheevos_api_response=$(curl --silent --data "r=login&u=$1&p=$2" "$RA_API_URL")
  local cheevos_success=$(echo "$cheevos_api_response" | jq -r '.Success')
  if [[ "$cheevos_success" == "true" ]]; then
    log d "cheevos login succeeded"
    cheevos_login_timestamp=$(date +%s)
    final_response=$(jq --arg ts "$cheevos_login_timestamp" '. + {Timestamp: $ts}' <<< "$cheevos_api_response") # Add timestamp to response object
    echo "$final_response"
  else
    log d "cheevos login failed"
    echo "login failed"
    return 1
  fi
}
