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
            data: {
              component_friendly_name: $sys.name,
              description: $sys.description,
              system: $sys.system
            }
          }
      ' "$manifest_file")
      local component_name=$(echo "$json_info" | jq -r '.component_name' )
      local component_friendly_name=$(echo "$json_info" | jq -r '.data.component_friendly_name // empty')
      local description=$(echo "$json_info" | jq -r '.data.description // empty')
      local system=$(echo "$json_info" | jq -r '.data.system // "none"')
      local json_obj=$(jq -n --arg name "$component_name" --arg friendly_name "$component_friendly_name" --arg desc "$description" --arg system "$system" --arg path "$(dirname "$manifest_file")" \
                '{ component_name: $name, component_friendly_name: $friendly_name, description: $desc, emulated_system: $system, path: $path }')
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
