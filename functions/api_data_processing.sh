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
    while (( $(jobs -p | wc -l) >= $system_cpu_max_threads )); do # Wait for a background task to finish if system_cpu_max_threads has been hit
      sleep 0.1
    done
    (
    if [[ -d "$rd_home_roms_path/$system" ]]; then
      local compression_candidates
      compression_candidates=$(find "$rd_home_roms_path/$system" -type f -not -iname "*.txt")
      if [[ -n "$compression_candidates" ]]; then
        while IFS= read -r game; do
          while (( $(jobs -p | wc -l) >= $system_cpu_max_threads )); do # Wait for a background task to finish if system_cpu_max_threads has been hit
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
                local json_obj=$(jq -n --arg game "$game" --arg format "$compatible_compression_format" \
                '{ game: $game, format: $format }')
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
                local json_obj=$(jq -n --arg game "$game" --arg format "$compatible_compression_format" \
                '{ game: $game, format: $format }')
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
                local json_obj=$(jq -n --arg game "$game" --arg format "$compatible_compression_format" \
                '{ game: $game, format: $format }')
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
                local json_obj=$(jq -n --arg game "$game" --arg format "$compatible_compression_format" \
                '{ game: $game, format: $format }')
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

api_get_component() {
  local component
  local manifest_files
  component="$1"

  if [[ "$component" == "all" ]]; then
    manifest_files=$(find "$rd_components" -maxdepth 2 -mindepth 2 -type f -name "component_manifest.json")
  else # A specific component was named
    manifest_files=$(find "$rd_components/$component" -maxdepth 1 -mindepth 1 -type f -name "component_manifest.json")
    if [[ ! -n "$manifest_files" ]]; then # No results were found for the given component name
      echo "information for component $component could not be found"
      return 1
    fi
  fi

  # Initialize the empty JSON file meant for final output
  local all_components_obj="$(mktemp)"
  echo '[]' > "$all_components_obj"

  while IFS= read -r manifest_file; do
    while (( $(jobs -p | wc -l) >= $system_cpu_max_threads )); do # Wait for a background task to finish if system_cpu_max_threads has been hit
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
  done < <(echo "$manifest_files")
  wait # Wait for background tasks to finish

  local final_json=$(jq '[.[] | select(.component_name == "retrodeck")] + ([.[] | select(.component_name != "retrodeck")] | sort_by(.component_name))' "$all_components_obj") # Ensure RetroDECK is always first in the list
  rm "$all_components_obj"

  echo "$final_json"
}

api_get_current_preset_state() {
  # This function will gather the state (enabled/disabled/other) of all the systems in a given preset. An "all" argument can also be given which will check all presets for all components.
  # Optionally, a specific component can be added, which will make the function return the state of all presets for that one component
  # USAGE: api_get_current_preset_settings "$preset" ("$specific_component")

  local preset="$1"
  local specific_component="$2"
  local preset_settings='{}'

  while read -r preset_name; do
    if [[ "$preset" == "all" || "$preset_name" == "$preset" ]]; then # If iterated preset matches request
      while read -r component; do
        if [[ ! -n "$specific_component" || "$component" == "$specific_component" ]]; then
          if ! jq -e --arg preset_name "$preset_name" '. | has($preset_name)' <<< "$preset_settings" > /dev/null; then
            log d "Preset $preset_name not yet added to list, adding..."
            preset_settings=$(jq --arg preset "$preset_name" '. += { ($preset): [] }' <<< "$preset_settings")
          fi
          base_component=$(jq -r --arg preset "$preset_name" \
                                 --arg component "$component" '.presets[$preset]
                                                              | paths(scalars)
                                                              | select(.[-1] == $component)
                                                              | if length > 1 then .[-2] else $preset end
                                                              ' "$rd_conf")
          if [[ ! "$preset_name" == "$base_component" ]]; then # If component is a core
            log d "Component $component is a core of $base_component"
            base_component="${base_component%.cores}"
          else
            base_component="$component"
          fi

          local json_info=$(jq -r --arg component "$component" '(keys_unsorted[0]) as $system_key
                                                                | .[$system_key] as $sys
                                                                | (if $component == $system_key
                                                                    then $sys
                                                                    else $sys.cores[$component]
                                                                  end) as $selection
                                                                | {
                                                                    system_name: (if $component == $system_key then $system_key else $component end),
                                                                    data: {
                                                                      system_friendly_name:       $selection.name,
                                                                      description:                $selection.description,
                                                                      emulated_system:            $selection.system,
                                                                      emulated_system_friendly_name: $selection.system_friendly_name
                                                                    }
                                                                  }
                                                              ' "$rd_components/$base_component/component_manifest.json")

          local system_name=$(jq -c '.system_name' <<< "$json_info")
          local system_friendly_name=$(jq -c '.data.system_friendly_name' <<< "$json_info")
          local description=$(jq -c '.data.description' <<< "$json_info")
          local emulated_system=$(jq -c '.data.emulated_system' <<< "$json_info")
          local emulated_system_friendly_name=$(jq -c '.data.emulated_system_friendly_name' <<< "$json_info")
          local preset_status=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset_name")

          local json_obj=$(jq -n --argjson name "$system_name" --argjson friendly_name "$system_friendly_name" --argjson desc "$description" --argjson emu_system "$emulated_system" \
                --argjson emu_system_friendly "$emulated_system_friendly_name" --arg status "$preset_status" --arg base_comp "$base_component" \
                'if $base_comp == $name then
                  { system_name: $name, system_friendly_name: $friendly_name, description: $desc, emulated_system: $emu_system, emulated_system_friendly_name: $emu_system_friendly, status: $status }
                else
                  { system_name: $name, parent_component: $base_comp, system_friendly_name: $friendly_name, description: $desc, emulated_system: $emu_system, emulated_system_friendly_name: $emu_system_friendly,
                  status: $status }
                end')

          preset_settings=$(jq --arg preset "$preset_name" --argjson obj "$json_obj" '.[$preset] += [$obj]' <<< "$preset_settings")
        fi
      done < <(jq -r --arg preset "$preset_name" '.presets[$preset]
                                                    | paths(scalars)
                                                    | .[-1]
                                                  ' "$rd_conf") # Find all component names in this preset, finding core names if they exist
    fi
  done < <(jq -r '.presets | keys[]' "$rd_conf")
  echo "$preset_settings" | jq .
}

api_get_bios_file_status() {

  local bios_files="$(mktemp)"
  echo '[]' > "$bios_files"

  while read -r entry; do
    while (( $(jobs -p | wc -l) >= $system_cpu_max_threads )); do # Wait for a background task to finish if system_cpu_max_threads has been hit
      sleep 0.1
    done
    (
    # Extract the key (element name) and the fields
    bios_file=$(jq -r '.key // "Unknown"' <<< "$entry")
    bios_md5=$(jq -r '.value.md5 | if type=="array" then join(", ") else . end // "Unknown"' <<< "$entry")
    bios_systems=$(jq -r '.value.system | if type=="array" then join(", ") else . end // "Unknown"' <<< "$entry")
    bios_desc=$(jq -r '.value.description // "No description provided"' <<< "$entry")
    required=$(jq -r '.value.required // "No"' <<< "$entry")
    bios_paths=$(jq -r '.value.paths // "'"$rd_home_bios_path"'" | if type=="array" then join(", ") else . end' <<< "$entry")

    log d "Checking entry $bios_entry"

    # Expand any embedded shell variables (e.g. $saves_folder or $rd_home_bios_path) with their actual values
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
  done < <(find "$rd_home_roms_path" -type d -name ".*" -prune -o -type f -name "*.m3u" -print)

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

api_get_component_menu_entries() {
  # This function will find all component-specific menu entries for use in a Configurator for a given menu section, or "all" if all entries for all menu options are desired
  # Menu sections and entry information are defined in each components component_manifest.json file
  # USAGE: api_get_component_menu_entries "$menu"

  local requested_menu="$1"
  local menu_items='{}'

  while IFS= read -r manifest_file; do
    if jq -e '.. | objects | select(has("configurator_menus")) | any' "$manifest_file" > /dev/null; then # Check if manifest contains the "configurator_menus" key
      while read -r menu; do
        if [[ "$requested_menu" == "$menu" || "$requested_menu" == "all" ]]; then # Check if this manifest has entries for the menu we are looking for
          if ! jq -e --arg menu "$menu" '. | has($menu)' <<< "$menu_items" > /dev/null; then
            log d "Menu $menu not yet added to list, adding..."
            menu_items=$(jq --arg menu "$menu" '. += { ($menu): [] }' <<< "$menu_items")
          fi
          while read -r menu_entry; do
            json_obj=$(jq -r --arg menu "$menu" --arg menu_entry "$menu_entry" 'to_entries[].value.configurator_menus[$menu][$menu_entry]' "$manifest_file")
            menu_items=$(jq --arg menu "$menu" --argjson new_obj "$json_obj" '.[$menu] += [$new_obj]' <<< "$menu_items")
          done < <(jq -r --arg menu "$menu" 'to_entries[].value.configurator_menus[$menu] | to_entries[] | .key' "$manifest_file")
        fi
      done < <(jq -r 'to_entries[].value.configurator_menus | keys[]' "$manifest_file")
    fi
  done < <(find "$rd_components" -maxdepth 2 -mindepth 2 -type f -name "component_manifest.json")

  echo "$menu_items"
}

api_get_empty_rom_folders() {
  local empty_rom_folders_list="$(mktemp)"
  echo '[]' > "$empty_rom_folders_list"

  # Extract helper file names using jq and populate the all_helper_files array
  local all_helper_files=($(jq -r '.helper_files | to_entries | .[] | .value.filename' "$features"))

  while IFS= read -r system; do
    while (( $(jobs -p | wc -l) >= $system_cpu_max_threads )); do # Wait for a background task to finish if system_cpu_max_threads has been hit
      sleep 0.1
    done
    (
    local dir="$rd_home_roms_path/$system"
    local files=$(ls -A1 "$dir")
    local count=$(ls -A "$dir" | wc -l)
    local folder_is_empty="false"

    if [[ $count -eq 0 || ($count -eq 1 && "$(basename "${files[0]}")" == "systeminfo.txt") ]]; then
        folder_is_empty="true"
    elif [[ $count -eq 2 ]] && [[ "$files" =~ "systeminfo.txt" ]]; then
      contains_helper_file="false"
      for helper_file in "${all_helper_files[@]}" # Compare helper file list to dir file list
      do
        if [[ "$files" =~ "$helper_file" ]]; then
          contains_helper_file="true" # Helper file was found
          break
        fi
      done
      if [[ "$contains_helper_file" == "true" ]]; then
        folder_is_empty="true"
      fi
    fi

    if [[ "$folder_is_empty" == "true" ]]; then
      local json_obj=$(jq -n --arg system "$system" --arg path "$dir" '{ system: $system, path: $path }')
      (
      flock -x 200
      jq --argjson new_obj "$json_obj" '. + [$new_obj]' "$empty_rom_folders_list" > "$empty_rom_folders_list.tmp" && mv "$empty_rom_folders_list.tmp" "$empty_rom_folders_list"
      ) 200>"$RD_FILE_LOCK"
    fi
  ) &
  wait # wait for background tasks to finish
  done < <(find "$rd_home_roms_path" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')

  if [[ $(jq 'length' "$empty_rom_folders_list") -gt 0 ]]; then
    local final_json=$(cat "$empty_rom_folders_list" | jq -r 'sort_by(.system)')
    echo "$final_json"
    return 0
  else
    echo "no empty rom folders found"
    return 1
  fi
}

api_get_retrodeck_credits() {
  local retrodeck_credits

  if retrodeck_credits="$(jq -n --arg content "$(cat $config/retrodeck/reference_lists/retrodeck_credits.txt)" '{ "credits": $content }')"; then
    echo "$retrodeck_credits"
    return 0
  else
    echo "the retrodeck credits could not be read"
    return 1
  fi
}

api_get_retrodeck_versions() {
  local retrodeck_versions_json
  local version_array=$(xml sel -t -v '//component/releases/release/@version' -n "$rd_metainfo")

  retrodeck_versions_json="$(printf '%s\n' "${version_array[@]}" | jq -R . | jq -s .)"

  local final_json=$(jq -n --argjson version_array "$retrodeck_versions_json" '{ versions: $version_array}')

  if [[ $(echo "$final_json" | jq 'length') -gt 0 ]]; then
    echo "$final_json"
    return 0
  else
    echo "the retrodeck version history could not be read"
    return 1
  fi
}

api_get_retrodeck_changelog() {
  local version="$1"
  local release_json
  local changelogs

  if [[ "$version" == "all" ]]; then
    changelogs='[]'
    for release in $(xml sel -t -m "//component/releases/release" -v "@version" -n "$rd_metainfo"); do
      local changelog_xml=$(xml sel -t -m "//component/releases/release[@version='"$release"']/description" -c . "$rd_metainfo" | tr -s '\n' | sed 's/^\s*//')
      local changelog_md=$(echo "$changelog_xml" | \
                          sed -e 's|<p>\(.*\)</p>|## \1|g' \
                          -e 's|<ul>||g' \
                          -e 's|</ul>||g' \
                          -e 's|<h1>\(.*\)</h1>|# \1|g' \
                          -e 's|<li>\(.*\)</li>|- \1|g' \
                          -e 's|<description>||g' \
                          -e 's|</description>||g' \
                          -e '/<[^>]*>/d')
      local json_obj=$(jq -n --arg release "$release" --arg changelog "$changelog_md" '{ release: $release, changelog: $changelog }')
      changelogs=$(jq -n --argjson existing_obj "$changelogs" --argjson new_obj "$json_obj" '$existing_obj + [$new_obj]')
    done
  else
    local changelog_xml=$(xml sel -t -m "//component/releases/release[@version='"$version"']/description" -c . "$rd_metainfo" | tr -s '\n' | sed 's/^\s*//')
    local changelog_md=$(echo "$changelog_xml" | \
                          sed -e 's|<p>\(.*\)</p>|## \1|g' \
                          -e 's|<ul>||g' \
                          -e 's|</ul>||g' \
                          -e 's|<h1>\(.*\)</h1>|# \1|g' \
                          -e 's|<li>\(.*\)</li>|- \1|g' \
                          -e 's|<description>||g' \
                          -e 's|</description>||g' \
                          -e '/<[^>]*>/d')
    changelogs=$(jq -n --arg release "$release" --arg changelog "$changelog_md" '{ release: $release, changelog: $changelog }')
  fi

  echo "$changelogs"
}

api_set_preset_state() {
  local component="$1"
  local preset="$2"
  local state="$3"
  local child_component=""

  local current_preset_state=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset")

  if [[ -n "$current_preset_state" ]]; then # Component entry exists for given preset in retrodeck.cfg
    local parent_component="$(jq -r --arg preset "$preset" --arg component "$component" '
    .presets[$preset]
    | paths(scalars)
    | select(.[-1] == $component)
    | if length > 1 then .[-2] else $preset end
    ' "$rd_conf")"
    if [[ ! "$parent_component" == "$preset" ]]; then # If the given component is a nested core
      parent_component="${parent_component%.cores}"
      child_component="$component"
      component="$parent_component"
    fi

    local preset_disabled_state=$(jq -r --arg component "$component" --arg core "$child_component" --arg preset "$preset" '
                                if $core != "" then
                                  .[$component].compatible_presets[$core][$preset].[0] // empty
                                else
                                  .[$component].compatible_presets[$preset].[0] // empty
                                end
                              ' "$rd_components/$component/component_manifest.json")

    if [[ -n "$preset_disabled_state" ]]; then # The disabled state for that preset for that component could be determined
      if jq -e --arg component "$component" \
      --arg core "$child_component" \
      --arg preset "$preset" \
      --arg state "$state" '
      if $core != "" then
        .[$component].compatible_presets[$core][$preset] | index($state) != null
      else
        .[$component].compatible_presets[$preset] | index($state) != null
      end
      ' "$rd_components/$component/component_manifest.json" > /dev/null; then # Check if requested state is a valid option
        if [[ "$current_preset_state" == "$state" ]]; then # Preset is already in desired state
          echo "component $component is already in state $state for preset $preset"
          return 1
        elif [[ "$state" == "$preset_disabled_state" ]]; then # Preset is being disabled and is not currently disabled
          if [[ -n "$child_component" ]]; then
            log d "Disabling preset $preset for component $component core $child_component"
            set_setting_value "$rd_conf" "$child_component" "$state" "retrodeck" "$preset"
          else
            log d "Disabling preset $preset for component $component"
            set_setting_value "$rd_conf" "$component" "$state" "retrodeck" "$preset"
          fi
        else # Preset is being enabled
          while read -r preset_key; do # Check for incompatible preset conflicts
            local preset_key_value=$(jq -r --arg preset_key "$preset_key" '.incompatible_presets[$preset_key]' "$features")
            if [[ "$preset_key" == "$preset" ]]; then # If incompatible key name matches desired preset
              if jq -e --arg component "$component" \
              --arg core "$child_component" \
              --arg preset "$preset_key_value" '
              (if $core != "" then $component + ".cores" else $component end) as $component_ext
              |
              if $core != "" then
                .presets[$preset][$component_ext] | has($core)
              else
                .presets[$preset] | has($component)
              end
              ' "$rd_conf" > /dev/null; then # If the incompatible preset has an entry for this component
                incompatible_preset_disabled_state=$(jq -r --arg component "$component" \
                                                          --arg core "$child_component" \
                                                          --arg preset "$preset_key_value" '
                                                          if $core != "" then
                                                            .[$component].compatible_presets[$core][$preset].[0] // empty
                                                          else
                                                            .[$component].compatible_presets[$preset].[0] // empty
                                                          end
                                                        ' "$rd_components/$component/component_manifest.json")
                if [[ -n "$child_component" ]]; then
                  incompatible_preset_current_state=$(get_setting_value "$rd_conf" "$child_component" "retrodeck" "$preset_key_value")
                else
                  incompatible_preset_current_state=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset_key_value")
                fi
                log d "incompatible_preset_current_state: $incompatible_preset_current_state"
                if [[ ! "$incompatible_preset_current_state" == "$incompatible_preset_disabled_state" ]]; then # If the incompatible preset is enabled
                  echo "incompatible preset $preset_key_value is currently enabled, cannot enable $preset"
                  return 1
                fi
              fi
            elif [[ "$preset_key_value" == "$preset" ]]; then # If incompatible key value matches desired preset
              if jq -e --arg component "$component" \
              --arg core "$child_component" \
              --arg preset "$preset_key" '
              (if $core != "" then $component + ".cores" else $component end) as $component_ext
              |
              if $core != "" then
                .presets[$preset][$component_ext] | has($core)
              else
                .presets[$preset] | has($component)
              end
              ' "$rd_conf" > /dev/null; then # If the incompatible preset has an entry for this component
                incompatible_preset_disabled_state=$(jq -r --arg component "$component" --arg core "$child_component" --arg preset "$preset_key" '
                      if $core != "" then
                        .[$component].compatible_presets[$core][$preset].[0] // empty
                      else
                        .[$component].compatible_presets[$preset].[0] // empty
                      end
                    ' "$rd_components/$component/component_manifest.json")
                if [[ -n "$child_component" ]]; then
                  incompatible_preset_current_state=$(get_setting_value "$rd_conf" "$child_component" "retrodeck" "$preset_key_value")
                else
                  incompatible_preset_current_state=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset_key_value")
                fi
                if [[ ! "$incompatible_preset_current_state" == "$incompatible_preset_disabled_state" ]]; then # If the incompatible preset is enabled
                  echo "incompatible preset $preset_key is currently enabled, cannot enable $preset"
                  return 1
                fi
              fi
            fi
          done < <(jq -r '.incompatible_presets | keys[]' "$features")

          if [[ "$preset" == "cheevos" ]]; then # For cheevos preset, ensure login data is available
            if [[ -n "$cheevos_token" && -n "$cheevos_username" && -n "$cheevos_login_timestamp" ]]; then
              log d "Cheevos login info exists"
            else
              echo "login information for cheevos preset not available"
              return 1
            fi
          fi

          if [[ -n "$child_component" ]]; then
            log d "Enabling preset $preset for component $component core $child_component"
            set_setting_value "$rd_conf" "$child_component" "$state" "retrodeck" "$preset" # No incompatibilities found, enabling preset
          else
            log d "Enabling preset $preset for component $component"
            set_setting_value "$rd_conf" "$component" "$state" "retrodeck" "$preset" # No incompatibilities found, enabling preset
          fi
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

  local config_format=$(jq -r --arg component "$component" \
                              --arg core "$child_component" 'if $core != "" then
                                                              .[$component].preset_actions[$core].config_file_format
                                                            else
                                                              .[$component].preset_actions.config_file_format
                                                            end
                                                            ' "$rd_components/$component/component_manifest.json")

  if [[ "$config_format" == "retroarch-all" ]]; then
    local retroarch_all="true"
    local config_format="retroarch"
  fi
  log d "Config file format: $config_format"

  while IFS= read -r preset_setting_name; do
    current_preset_object=$(jq -r --arg component "$component" \
                                  --arg core "$child_component" \
                                  --arg preset "$preset" \
                                  --arg preset_setting_name "$preset_setting_name" \
                            'if $core != "" then
                              .[$component].preset_actions[$core][$preset][$preset_setting_name]
                            else
                              .[$component].preset_actions[$preset][$preset_setting_name]
                            end' "$rd_components/$component/component_manifest.json")
    action=$(echo "$current_preset_object" | jq -r '.action')

    case "$action" in

      "change" )
        log d "Changing config file for preset: $preset_setting_name"
        new_setting_value=$(jq -r '.new_setting_value // empty' <<< "$current_preset_object")
        section=$(jq -r '.section // empty' <<< "$current_preset_object")
        target_file=$(jq -r '.target_file // empty' <<< "$current_preset_object")
        defaults_file=$(jq -r '.defaults_file // empty' <<< "$current_preset_object")

        if [[ "$target_file" = \$* ]]; then # Read current target file and resolve if it is a variable
          eval target_file=$target_file
          log d "Target file is a variable name. Actual target $target_file"
        fi
        if [[ "$defaults_file" = \$* ]]; then #Read current defaults file and resolve if it is a variable
          eval defaults_file=$defaults_file
          log d "Defaults file is a variable name. Actual defaults file $defaults_file"
        fi

        if [[ ! "$state" == "$preset_disabled_state" ]]; then # Preset is being enabled
          if [[ "$new_setting_value" = \$* ]]; then
            eval new_setting_value=$new_setting_value
            log d "New setting value is a variable. Actual setting value is $new_setting_value"
          fi
          if [[ "$config_format" == "retroarch" && ! "$retroarch_all" == "true" ]]; then # Separate process if this is a per-system RetroArch override file
            if [[ ! -f "$target_file" ]]; then
              log d "RetroArch per-system override file $target_file not found, creating and adding setting"
              create_dir "$(realpath "$(dirname "$target_file")")"
              echo "$preset_setting_name = \""$new_setting_value"\"" > "$target_file"
            else
              if [[ -z $(grep -o -P "^$preset_setting_name\b" "$target_file") ]]; then
                log d "RetroArch per-system override file $target_file does not contain setting $preset_setting_name, adding and assigning value $new_setting_value"
                add_setting "$target_file" "$preset_setting_name" "$new_setting_value" "$config_format" "$section"
              else
                log d "Changing setting: $preset_setting_name to $new_setting_value in $target_file"
                set_setting_value "$target_file" "$preset_setting_name" "$new_setting_value" "$config_format" "$section"
              fi
            fi
          elif [[ "$config_format" == "ppsspp" && "$target_file" == "$ppssppcheevosconf" ]]; then # Separate process if this is the standalone cheevos token file used by PPSSPP
            log d "Creating cheevos token file $ppssppcheevosconf"
            echo "$new_setting_value" > "$target_file"
          else
            log d "Changing setting: $preset_setting_name to $new_setting_value in $target_file"
            set_setting_value "$target_file" "$preset_setting_name" "$new_setting_value" "$config_format" "$section"
          fi
        else # Preset is being disabled
          if [[ "$config_format" == "retroarch" && ! "$retroarch_all" == "true" ]]; then # Separate process if this is a per-system RetroArch override file
            if [[ -f "$target_file" ]]; then
              log d "Removing setting $preset_setting_name from RetroArch per-system override file $target_file"
              delete_setting "$target_file" "$preset_setting_name" "$config_format" "$section"
              if [[ -z $(cat "$target_file") ]]; then # If the override file is empty
                log d "RetroArch per-system override file is empty, removing"
                rm -f "$target_file"
              fi
              if [[ -z $(ls -1 "$(dirname "$target_file")") ]]; then # If the override folder is empty
                log d "RetroArch per-system override folder is empty, removing"
                rmdir "$(realpath "$(dirname "$target_file")")"
              fi
            fi
          elif [[ "$config_format" == "ppsspp" && "$target_file" == "$ppssppcheevosconf" ]]; then # Separate process if this is the standalone cheevos token file used by PPSSPP
            log d "Removing PPSSPP cheevos token file $ppssppcheevosconf"
            rm "$target_file"
          else
            local default_setting_value=$(get_setting_value "$defaults_file" "$preset_setting_name" "$config_format" "$section")
            log d "Changing setting: $preset_setting_name to $default_setting_value in $target_file"
            set_setting_value "$target_file" "$preset_setting_name" "$default_setting_value" "$config_format" "$section"
          fi
        fi
      ;;

      "enable" )
        target_file=$(jq -r '.target_file // empty' <<< "$current_preset_object")
        if [[ ! "$state" == "$preset_disabled_state" ]]; then
          log d "Enabling file: $preset_setting_name"
          enable_file "$target_file"
        else
          log d "Disabling file: $preset_setting_name"
          disable_file "$target_file"
        fi
      ;;

      "install" )
        source_file=$(jq -r '.source // empty' <<< "$current_preset_object")
        target_file=$(jq -r '.destination // empty' <<< "$current_preset_object")
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
  done < <(jq -r --arg component "$component" \
                --arg core "$child_component" \
                --arg preset "$preset" \
                'if $core != "" then
                  .[$component].preset_actions[$core][$preset] | keys[]
                else
                  .[$component].preset_actions[$preset] | keys[]
                end
                ' "$rd_components/$component/component_manifest.json")

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
  local cheevos_success=$(jq -r '.Success' <<< "$cheevos_api_response")
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

api_do_move_retrodeck_directory() {
  local rd_dir_name="$1" # The folder variable name from retrodeck.cfg
  local dest_dir="$2"
  local dir_to_move="$(get_setting_value "$rd_conf" "$rd_dir_name" "retrodeck" "paths")/" # The path of that folder variable

  if [[ ! -n "$dir_to_move" ]]; then
    echo "path $rd_dir_name not found in retrodeck.cfg"
    return 1
  fi

  local source_root="$(echo "$dir_to_move" | sed -e 's/\(.*\)\/retrodeck\/.*/\1/')" # The root path of the folder, excluding retrodeck/<folder name>. So /home/deck/retrodeck/roms becomes /home/deck
  if [[ ! "$rd_dir_name" == "rd_home_path" ]]; then # If a sub-folder is being moved, find it's path without the source_root. So /home/deck/retrodeck/roms becomes retrodeck/roms
    local rd_dir_path="$(echo "$dir_to_move" | sed "s/.*\(retrodeck\/.*\)/\1/; s/\/$//")"
  else # Otherwise just set the retrodeck root folder
    local rd_dir_path="$(basename "$dir_to_move")"
  fi

  if [[ -d "$dir_to_move" ]]; then # If the directory selected to move already exists at the expected location pulled from retrodeck.cfg
    if [[ "$dest" == "internal" ]]; then
      local dest_root="$HOME"
    elif [[ "$dest" == "sd" ]]; then
      if [[ -d "$sdcard" ]]; then
        local dest_root="$sdcard"
      fi
    elif [[ -d "$dest" ]]; then
      local dest_root="$dest"
    else
      echo "a valid destination was not specified"
      return 1
    fi

    if [[ -w "$dest_root" ]]; then # If user picked a destination and it is writable
      if [[ (-d "$dest_root/$rd_dir_path" && ! -L "$dest_root/$rd_dir_path" && ! $rd_dir_name == "rd_home_path") || "$(realpath "$dir_to_move")" == "$dest_root/$rd_dir_path" ]]; then # If the user is trying to move the folder to where it already is (excluding symlinks that will be unlinked)
        echo "the chosen retrodeck directory is already at the given destination"
        return 1
      else
        if [[ $(verify_space "$(echo "$dir_to_move" | sed 's/\/$//')" "$dest_root") ]]; then # Make sure there is enough space at the destination
          unlink "$dest_root/$rd_dir_path" # In case there is already a symlink at the picked destination
          move "$dir_to_move" "$dest_root/$rd_dir_path"
          if [[ -d "$dest_root/$rd_dir_path" ]]; then # If the move succeeded
            declare -g "$rd_dir_name=$dest_root/$rd_dir_path" # Set the new path for that folder variable in retrodeck.cfg
            if [[ "$rd_dir_name" == "rd_home_path" ]]; then # If the whole retrodeck folder was moved...
              prepare_component "postmove" "retrodeck"
            fi
            prepare_component "postmove" "all" # Update all the appropriate emulator path settings
            conf_write # Write the settings to retrodeck.cfg
            if [[ -z $(ls -1 "$source_root/retrodeck") ]]; then # Cleanup empty old_path/retrodeck folder if it was left behind
              rmdir "$source_root/retrodeck"
            fi
            echo "directory $rd_dir_name successfully moved to $dest_root"
            return 0
          else
            echo "move failed, please check logs for more details"
            return 1
          fi
        else # If there isn't enough space in the picked destination
          echo "not enough free space at given destination"
          return 1
        fi
      fi
    else # If the user didn't pick any custom destination, or the destination picked is unwritable
      echo "the chosen destination is not writable"
      return 1
    fi
  else # The folder to move was not found at the path pulled from retrodeck.cfg
    echo "path $dir_to_move could not be found, retrodeck.cfg paths need to be repaired"
    return 1
  fi
}
