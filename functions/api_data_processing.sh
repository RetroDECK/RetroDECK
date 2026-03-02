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
    if [[ -d "$roms_path/$system" ]]; then
      local compression_candidates
      compression_candidates=$(find "$roms_path/$system" -type f -not -iname "*.txt" -not -iname ".directory")
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
                ) 200>"$rd_file_lock"
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
                ) 200>"$rd_file_lock"
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
                ) 200>"$rd_file_lock"
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
                ) 200>"$rd_file_lock"
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
  # Gather component metadata from cached manifest data.
  # Returns a JSON array of component objects sorted alphabetically, with "retrodeck" always first.
  # USAGE: api_get_component "<component_name | all>"

  local component="$1"

  get_component_manifest_cache | jq --arg component "$component" '
    [.[] |
     .component_path as $path |
     .manifest | to_entries[] |
     .key as $component_name | .value as $sys |
     select($component == "all" or $component_name == $component) |
     {
       component_name: $component_name,
       component_friendly_name: ($sys.name // ""),
       description: ($sys.description // ""),
       emulated_system: ($sys.system // "none"),
       path: $path,
       compatible_presets: ($sys.compatible_presets // "none")
     }
    ]
    | [.[] | select(.component_name == "retrodeck")] +
      ([.[] | select(.component_name != "retrodeck")] | sort_by(.component_name))
  '
}

api_get_all_preset_names() {
  # Gather the names of all compatible presets for all installed components
  # USAGE: api_get_all_preset_names

  jq '[.presets | keys[] | { preset_name: . }] | sort_by(.preset_name)' "$rd_conf"
}

api_get_current_preset_state() {
  # Gather the state (enabled/disabled/other) of all systems in a given preset, or all presets.
  # Optionally filter to a specific component.
  # USAGE: api_get_current_preset_state "$preset" ["$specific_component"]

  local preset="$1"
  local specific_component="$2"
  local preset_settings='{}'

  while read -r preset_name; do
    if [[ "$preset" != "all" && "$preset_name" != "$preset" ]]; then
      continue
    fi

    while read -r component; do
      if [[ -n "$specific_component" && "$component" != "$specific_component" ]]; then
        continue
      fi

      local base_component
      base_component=$(jq -r --arg preset "$preset_name" \
        --arg component "$component" '
        .presets[$preset]
        | paths(scalars)
        | select(.[-1] == $component)
        | if length > 1 then .[-2] else $preset end
      ' "$rd_conf")

      local is_core=false
      if [[ "$base_component" != "$preset_name" ]]; then
        log d "Component $component is a core of $base_component"
        is_core=true
        base_component="${base_component%_cores}"
      else
        base_component="$component"
      fi

      local manifest_data
      manifest_data=$(get_component_manifest_cache | jq --arg comp "$base_component" '
        .[] | select(.manifest | has($comp)) | .manifest
      ')

      if [[ -z "$manifest_data" || "$manifest_data" == "null" ]]; then
        log e "Manifest not found for component $base_component"
        continue
      fi

      local json_obj
      json_obj=$(jq -c --arg component "$component" \
        --argjson is_core "$is_core" \
        --arg base_comp "$base_component" \
        --arg status "$preset_status" '
        (keys_unsorted[0]) as $system_key
        | .[$system_key] as $sys
        | (if $component == $system_key then $sys else $sys.cores[$component] end) as $selection
        | {
            system_name: (if $component == $system_key then $system_key else $component end),
            system_friendly_name: $selection.name,
            description: $selection.description,
            emulated_system: $selection.system,
            emulated_system_friendly_name: $selection.system_friendly_name,
            status: $status
          }
        | if $is_core then . + { parent_component: $base_comp } else . end
      ' <<< "$manifest_data")

      preset_settings=$(jq --arg preset "$preset_name" --argjson obj "$json_obj" '
        .[$preset] = ((.[$preset] // []) + [$obj])
      ' <<< "$preset_settings")

    done < <(jq -r --arg preset "$preset_name" '
      .presets[$preset] | paths(scalars) | .[-1]
    ' "$rd_conf")
  done < <(jq -r '.presets | keys[]' "$rd_conf")

  echo "$preset_settings"
}

api_get_bios_file_status() {
  # Check the status of BIOS files for given systems, including file presence and MD5 validation.
  # Returns a sorted JSON array of BIOS file status objects.
  # USAGE: api_get_bios_file_status ["$systems_json_array"]

  local systems_to_check="${1:-[]}"

  # Merge BIOS info from cache
  merged_bios_info=$(get_component_manifest_cache | jq --argjson systems "$systems_to_check" '
    {bios: (
      [.[] | .manifest | .. | objects | select(has("bios")) | .bios] | flatten |
      if ($systems | length) == 0
      then .
      else map(select([.system] | flatten | any(. as $s | $systems | index($s))))
      end
    )}
  ')

  # Translate stored variable names into real values
  merged_bios_info=$(echo "$merged_bios_info" | envsubst)

  # Find all files in BIOS directories
  mapfile -t files_to_check < <(
    {
      echo "$merged_bios_info" | jq -r --argjson systems "$systems_to_check" '
        if ($systems | length) == 0
        then [.bios[] | select(has("paths")) | .paths]
        else [.bios[] | select(has("paths") and ([.system] | flatten | any(. as $s | $systems | index($s)))) | .paths]
        end | flatten | unique | .[]'
      echo "$bios_path"
    } | xargs -I {} sh -c '[ -d "{}" ] && find "{}" -maxdepth 1 -type f -not -iname ".directory" -not -iname "*.txt"'
  )

  # Build lookup of found filenames to paths
  declare -A found_file_lookup
  for filepath in "${files_to_check[@]}"; do
    found_file_lookup["$(basename "$filepath")"]="$filepath"
  done

  local found_json
  found_json=$(printf '%s\n' "${!found_file_lookup[@]}" | jq -R . | jq -s .)

  # Collect all found file paths and compute md5sums
  local md5_json='{}'
  local -a md5_paths=()
  while read -r filename; do
    [[ -n "${found_file_lookup[$filename]+x}" ]] && md5_paths+=("${found_file_lookup[$filename]}")
  done < <(jq -r '.bios[] | select(.md5 != null) | .filename' <<< "$merged_bios_info")

  if [[ ${#md5_paths[@]} -gt 0 ]]; then
    md5_json=$(md5sum "${md5_paths[@]}" | awk '{print $2, $1}' | jq -R 'split(" ") | {(.[0] | split("/") | .[-1]): .[1]}' | jq -s 'add')
  fi

  # Build final results
  local final_json
  final_json=$(jq --argjson found "$found_json" \
    --argjson md5s "$md5_json" \
    --arg bios_path "$bios_path" '
    .bios | map(
      (.filename // "Unknown") as $file
      | ($found | index($file) | . != null) as $is_found
      | ($md5s[$file] // null) as $actual_md5
      | (.md5 // null) as $known_md5
      | (if $is_found and $known_md5 != null and $actual_md5 != null then
            if ($known_md5 | if type=="array" then . else [.] end | index($actual_md5)) != null
            then "Yes" else "No" end
          elif $is_found then "Pending"
          else "N/A"
        end) as $md5_status
      | {
          file: $file,
          systems: (.system | if type=="array" then join(", ") else . end // "Unknown"),
          file_found: (if $is_found then "Yes" else "No" end),
          md5_matched: $md5_status,
          description: (.description // "No description provided"),
          paths: (.paths // $bios_path | if type=="array" then join(", ") else . end),
          required: (.required // "No"),
          known_md5_hashes: (.md5 | if type=="array" then join(", ") else . end // "N/A")
        }
    )
    | sort_by([
        (.systems | sub(".*/";"") | test("^[0-9]") | not),
        (.systems | sub(".*/";""))
      ])
  ' <<< "$merged_bios_info")

  echo "$final_json" > "$logs_path/retrodeck_bios_check.log"
  echo "$final_json"
}

api_get_multifile_game_structure() {
  # Find any .m3u files in directories whose name does not also end in .m3u, indicating incorrect multi-file game structure.
  # USAGE: api_get_multifile_game_structure

  local -a m3u_files=()
  while IFS= read -r file; do
    if [[ "$(basename "$(dirname "$file")")" != *.m3u ]]; then
      m3u_files+=("$file")
    fi
  done < <(find "$roms_path" -type d -name ".*" -prune -o -type f -name "*.m3u" -print)

  if [[ ${#m3u_files[@]} -gt 0 ]]; then
    printf '%s\n' "${m3u_files[@]}" | jq -R '{ incorrect_file: . }' | jq -s '.'
    return 1
  else
    echo "no multifile game structure issues found"
    return 0
  fi
}

api_get_component_menu_entries() {
  # Find all component-specific menu entries for use in a Configurator for a given menu section.
  # USAGE: api_get_component_menu_entries "<menu_name | all>"

  local requested_menu="$1"

  get_component_manifest_cache | jq --arg menu "$requested_menu" '
    reduce (.[] | .manifest | .. | objects | select(has("configurator_menus")) | .configurator_menus | to_entries[]) as $entry (
      {};
      if ($menu == "all" or $entry.key == $menu) then
        .[$entry.key] = ((.[$entry.key] // []) + [$entry.value | to_entries[].value])
      else . end
    )
  '
}

api_get_empty_rom_folders() {
  local empty_rom_folders_list="$(mktemp)"
  echo '[]' > "$empty_rom_folders_list"

  # Extract helper file names using jq and populate the all_helper_files array
  local all_ignorable_files=($(jq -r '.helper_files | to_entries | .[] | .value.filename' "$features"))

  all_ignorable_files+=(".directory" "systeminfo.txt")

  while IFS= read -r system; do
    while (( $(jobs -p | wc -l) >= $system_cpu_max_threads )); do # Wait for a background task to finish if system_cpu_max_threads has been hit
      sleep 0.1
    done
    (
    local dir="$roms_path/$system"
    local all_files=()

    while IFS= read -r -d '' file; do
      all_files+=("$(basename "$file")")
    done < <(find "$dir" -maxdepth 1 -type f -print0)

    local folder_is_empty="true"

    for file in "${all_files[@]}"; do
      local is_ignorable="false"
      for ignorable_file in "${all_ignorable_files[@]}"; do
        if [[ "$file" == "$ignorable_file" ]]; then
          is_ignorable="true"
          break
        fi
      done

      if [[ "$is_ignorable" == "false" ]]; then
        folder_is_empty="false"
        break
      fi
    done

    if [[ "$folder_is_empty" == "true" ]]; then
      local json_obj=$(jq -n --arg system "$system" --arg path "$dir" '{ system: $system, path: $path }')
      (
      flock -x 200
      jq --argjson new_obj "$json_obj" '. + [$new_obj]' "$empty_rom_folders_list" > "$empty_rom_folders_list.tmp" && mv "$empty_rom_folders_list.tmp" "$empty_rom_folders_list"
      ) 200>"$rd_file_lock"
    fi
  ) &
  wait # wait for background tasks to finish
  done < <(find "$roms_path" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')

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

  if retrodeck_credits="$(jq -n --arg content "$(cat $rd_core_files/reference_lists/retrodeck_credits.txt)" '{ "credits": $content }')"; then
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
      parent_component="${parent_component%_cores}"
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
        if [[ "$state" == "$preset_disabled_state" ]]; then # Preset is being disabled and is not currently disabled
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
              (if $core != "" then $component + "_cores" else $component end) as $component_ext
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
              (if $core != "" then $component + "_cores" else $component end) as $component_ext
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
                  incompatible_preset_current_state=$(get_setting_value "$rd_conf" "$child_component" "retrodeck" "$preset_key")
                else
                  incompatible_preset_current_state=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset_key")
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

  while IFS= read -r current_preset_object; do
    preset_setting_name=$(echo "$current_preset_object" | jq -r '.setting_name')
    action=$(echo "$current_preset_object" | jq -r '.action')

    case "$action" in

      "change" )
        log d "Changing config file for preset $preset setting name $preset_setting_name"
        new_setting_value=$(jq -r '.new_setting_value // empty' <<< "$current_preset_object")
        section=$(jq -r '.section // empty' <<< "$current_preset_object")
        target_file=$(jq -r '.target_file // empty' <<< "$current_preset_object")
        defaults_file=$(jq -r '.defaults_file // empty' <<< "$current_preset_object")

        if [[ "$target_file" = \$* ]]; then # Read current target file and resolve if it is a variable
          target_file=$(echo "$target_file" | envsubst)
          log d "Target file is a variable name. Actual target $target_file"
        fi
        if [[ "$defaults_file" = \$* ]]; then #Read current defaults file and resolve if it is a variable
            defaults_file=$(echo "$defaults_file" | envsubst)
          log d "Defaults file is a variable name. Actual defaults file $defaults_file"
        fi

        if [[ ! "$state" == "$preset_disabled_state" ]]; then # Preset is being enabled
          if echo "$current_preset_object" | jq -e --arg state "$state" '.enabled_states | contains([$state])' > /dev/null; then # If the desired state should process this action
            if [[ "$new_setting_value" = \$* ]]; then
              new_setting_value=$(echo "$new_setting_value" | envsubst)
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
            elif [[ ! -f "$target_file" ]]; then # Separate process if this is the standalone cheevos token file used by PPSSPP
              log d "Target file $target_file does not exist, creating..."
              echo "$new_setting_value" > "$target_file"
            elif [[ "$config_format" == "pcsx2" && "$target_file" == "$pcsx2_secrets_ini" ]]; then # Separate process if this is the PCSX2 secrets.ini file
              log d "Adding PCSX2 cheevos token line from $pcsx2_secrets_ini"
              add_setting "$target_file" "$preset_setting_name" "$new_setting_value" "$config_format" "$section"
            else
              log d "Changing setting: $preset_setting_name to $new_setting_value in $target_file"
              set_setting_value "$target_file" "$preset_setting_name" "$new_setting_value" "$config_format" "$section"
            fi
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
          elif [[ "$config_format" == "ppsspp" && "$target_file" == "$ppsspp_retroachievements_dat" ]]; then # Separate process if this is the standalone cheevos token file used by PPSSPP
            log d "Removing PPSSPP cheevos token file ppsspp_retroachievements_dat"
            rm "$target_file"
          elif [[ "$config_format" == "pcsx2" && "$target_file" == "$pcsx2_secrets_ini" ]]; then # Separate process if this is the PCSX2 secrets.ini file
            log d "Removing PCSX2 cheevos token line from $pcsx2_secrets_ini"
            delete_setting "$target_file" "$preset_setting_name" "$config_format" "$section"
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
          if echo "$current_preset_object" | jq -e --arg state "$state" '.enabled_states | contains([$state])' > /dev/null; then # If the desired state should process this action
            log d "Enabling file: $preset_setting_name"
            enable_file "$target_file"
          fi
        else
          log d "Disabling file: $preset_setting_name"
          disable_file "$target_file"
        fi
      ;;

      "install" )
        source_file=$(jq -r '.source // empty' <<< "$current_preset_object")
        target_file=$(jq -r '.destination // empty' <<< "$current_preset_object")
        cleanup_type=$(jq -r '.cleanup_type // empty' <<< "$current_preset_object")
        if [[ ! "$state" == "$preset_disabled_state" ]]; then
          if echo "$current_preset_object" | jq -e --arg state "$state" '.enabled_states | contains([$state])' > /dev/null; then # If the desired state should process this action
            log d "Installing files for preset $preset_setting_name"
            install_preset_files "$source_file" "$target_file"
          fi
        else
          log d "Removing files for preset $preset_setting_name"
          remove_preset_files "$source_file" "$target_file" "$cleanup_type"
        fi
      ;;

      * )
        log d "Other data: $action $preset_setting_name $new_setting_value $section" # DEBUG
      ;;

    esac
  done < <(jq -c --arg component "$component" \
                --arg core "$child_component" \
                --arg preset "$preset" \
                'if $core != "" then
                  .[$component].preset_actions[$core][$preset].[]
                else
                  .[$component].preset_actions[$preset].[]
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

  local cheevos_api_response=$(curl --silent --data "r=login&u=$1&p=$2" "$ra_cheevos_api_url")
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
              prepare_component "postmove" "framework"
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
