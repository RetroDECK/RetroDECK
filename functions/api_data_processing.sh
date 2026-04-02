#!/bin/bash

# This is the main data processing hub for the RetroDECK API.
# It will handle the direct demands of the API requests by leveraging the rest of the RetroDECK functions.

api_get_retrodeck_settings() {
  jq -c . "$rd_conf"
}

api_get_compressible_games() {
  # Find all games that can be compressed, optionally filtered to a specific format.
  # Returns a sorted JSON array of objects with game path and compatible format.
  # USAGE: api_get_compressible_games "<compression_format | all>"

  local target="$1"
  local compression_format

  # "everything" is a variable value used by the upstream Zenity dialog, but is otherwise equivalent to "all" in this function
  if [[ "$target" == "everything" ]]; then
    compression_format="all"
  else
    compression_format="$target"
  fi

  # Build list of systems to scan from the lookup
  local -a systems_to_scan=()
  for system in "${!compression_system_format[@]}"; do
    if [[ "$compression_format" == "all" || "${compression_system_format[$system]}" == "$compression_format" ]]; then
      systems_to_scan+=("$system")
    fi
  done

  if [[ ${#systems_to_scan[@]} -eq 0 ]]; then
    echo '[]'
    return
  fi

  local results_dir
  results_dir=$(mktemp -d)

  for system in "${systems_to_scan[@]}"; do
    [[ ! -d "$roms_path/$system" ]] && continue

    while (( $(jobs -p | wc -l) >= system_cpu_max_threads )); do
      sleep 0.1
    done
    (
      local system_results=""
      while IFS= read -r game; do
        [[ -z "$game" ]] && continue
        local compatible_format
        compatible_format=$(find_compatible_compression_format "$game")

        [[ "$compatible_format" == "none" ]] && continue

        if [[ "$compression_format" != "all" && "$compatible_format" != "$compression_format" ]]; then
          continue
        fi

        if [[ -f "${game%.*}.$compatible_format" ]]; then
          continue
        fi

        system_results+=$(printf '%s\t%s\n' "$game" "$compatible_format")$'\n'
      done < <(find "$roms_path/$system" -type f -not -iname "*.txt" -not -iname ".directory")

      if [[ -n "$system_results" ]]; then
        printf '%s' "$system_results" | awk -F'\t' '{printf "{\"game\":\"%s\",\"format\":\"%s\"}\n", $1, $2}' > "$results_dir/$system.json"
      fi
    ) &
  done

  wait

  local final_json
  if compgen -G "$results_dir/*.json" > /dev/null; then
    final_json=$(jq -s 'flatten | sort_by([
      (.game | sub(".*/";"") | test("^[0-9]") | not),
      (.game | sub(".*/";""))
    ])' "$results_dir"/*.json)
  else
    final_json='[]'
  fi

  rm -rf "$results_dir"
  echo "$final_json"
}

api_get_component() {
  # Gather component metadata from cached manifest data.
  # Returns a JSON array of component objects sorted alphabetically, with "retrodeck" always first.
  # USAGE: api_get_component "<component_name | all>"

  local component="$1"
  jq --arg component "$component" \
  '
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
  ' "$component_manifest_cache_file"
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
      manifest_data=$(jq --arg comp "$base_component" \
      '
        .[] | select(.manifest | has($comp)) | .manifest
      ' "$component_manifest_cache_file")

      if [[ -z "$manifest_data" || "$manifest_data" == "null" ]]; then
        log e "Manifest not found for component $base_component"
        continue
      fi

      local preset_status=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset_name")

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

  # Handle list-systems request
  if [[ $(echo "$systems_to_check" | jq -r 'if length == 1 and .[0] == "list-systems" then "true" else "false" end') == "true" ]]; then
    jq '
      [.[] | .manifest | to_entries[] |
        .value as $comp |
        ($comp.name // .key) as $comp_name |
        [$comp | .. | objects | select(has("bios")) | .bios] | flatten | .[] |
        (.system | if type == "array" then .[] else . end) as $sys |
        {system: $sys, component: $comp_name}
      ]
      | group_by(.system)
      | map({
          system: .[0].system,
          component: [.[].component] | unique
        })
      | sort_by(.system)
    ' "$component_manifest_cache_file"
    return
  fi

  local tmp_bios
  tmp_bios=$(mktemp)

  # Merge BIOS info from cache
  jq --argjson systems "$systems_to_check" \
  '
    {bios: (
      [.[] | .manifest | .. | objects | select(has("bios")) | .bios] | flatten |
      if ($systems | length) == 0
      then .
      else map(select([.system] | flatten | any(. as $s | $systems | index($s))))
      end
    )}
  ' "$component_manifest_cache_file" | envsubst > "$tmp_bios"

  # Find all files in BIOS directories
  mapfile -t files_to_check < <(
    {
      jq -r --argjson systems "$systems_to_check" '
        if ($systems | length) == 0
        then [.bios[] | select(has("paths")) | .paths]
        else [.bios[] | select(has("paths") and ([.system] | flatten | any(. as $s | $systems | index($s)))) | .paths]
        end | flatten | unique | .[]' "$tmp_bios"
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
  done < <(jq -r '.bios[] | select(.md5 != null) | .filename' "$tmp_bios")
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
  ' "$tmp_bios")
  
  rm -f "$tmp_bios"
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
  jq --arg menu "$requested_menu" \
  '
    reduce (.[] | .manifest | .. | objects | select(has("configurator_menus")) | .configurator_menus | to_entries[]) as $entry (
      {};
      if ($menu == "all" or $entry.key == $menu) then
        .[$entry.key] = ((.[$entry.key] // []) + [$entry.value | to_entries[].value])
      else . end
    )
  ' "$component_manifest_cache_file"
}

api_get_empty_rom_folders() {
  # Find ROM system directories that contain no game files (only helper/system files or nothing at all).
  # Returns a sorted JSON array of objects with system name and path, or a message if none are found.
  # USAGE: api_get_empty_rom_folders

  # Build ignorable files lookup from all component manifests
  local -A ignorable_files
  while IFS= read -r helper_filename; do
    [[ -n "$helper_filename" ]] && ignorable_files["$helper_filename"]=1
  done < <(get_helper_files "all" | jq -r '.[].filename')
  ignorable_files[".directory"]=1
  ignorable_files["systeminfo.txt"]=1

  local -a empty_systems=()

  while IFS= read -r system; do
    local dir="$roms_path/$system"
    local folder_is_empty=true

    while IFS= read -r -d '' filepath; do
      if [[ -z "${ignorable_files[$(basename "$filepath")]+x}" ]]; then
        folder_is_empty=false
        break
      fi
    done < <(find "$dir" -maxdepth 1 -type f -print0)

    if [[ "$folder_is_empty" == true ]]; then
      empty_systems+=("$system")
    fi
  done < <(find "$roms_path" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')

  if [[ ${#empty_systems[@]} -gt 0 ]]; then
    printf '%s\n' "${empty_systems[@]}" | jq -R --arg roms_path "$roms_path" \
      '{ system: ., path: ($roms_path + "/" + .) }' | jq -s 'sort_by(.system)'
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
  # Set the state of a preset for a given component, applying all associated config changes.
  # Validates the requested state, checks for conflicting presets and prerequisites, then applies changes.
  # USAGE: api_set_preset_state "$component" "$preset" "$state"

  local component="$1"
  local preset="$2"
  local state="$3"
  local child_component=""

  local current_preset_state
  current_preset_state=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset")

  if [[ -z "$current_preset_state" ]]; then
    echo "component $component not compatible with preset $preset"
    return 1
  fi

  # Resolve parent/child relationship for nested cores
  local parent_component
  parent_component=$(jq -r --arg preset "$preset" --arg component "$component" '
    .presets[$preset]
    | paths(scalars)
    | select(.[-1] == $component)
    | if length > 1 then .[-2] else $preset end
  ' "$rd_conf")

  if [[ "$parent_component" != "$preset" ]]; then
    parent_component="${parent_component%_cores}"
    child_component="$component"
    component="$parent_component"
  fi

  local tmp_manifest
  tmp_manifest=$(mktemp)
  jq --arg comp "$component" \
  '
    .[] | .manifest | select(has($comp)) | .[$comp]
  ' "$component_manifest_cache_file" > "$tmp_manifest"

  if [[ ! -s "$tmp_manifest" || "$(cat "$tmp_manifest")" == "null" ]]; then
    echo "manifest not found for component $component"
    rm -f "$tmp_manifest"
    return 1
  fi

  # Determine the disabled state for this preset
  local preset_disabled_state
  preset_disabled_state=$(jq -r --arg core "$child_component" --arg preset "$preset" '
    if $core != "" then
      .compatible_presets[$core][$preset][0] // empty
    else
      .compatible_presets[$preset][0] // empty
    end
  ' "$tmp_manifest")

  if [[ -z "$preset_disabled_state" ]]; then
    echo "disabled state for component $component preset $preset could not be determined"
    rm -f "$tmp_manifest"
    return 1
  fi

  # Validate that the requested state is a valid option
  local state_is_valid
  state_is_valid=$(jq -r --arg core "$child_component" --arg preset "$preset" --arg state "$state" '
    if $core != "" then
      .compatible_presets[$core][$preset] | index($state) != null
    else
      .compatible_presets[$preset] | index($state) != null
    end
  ' "$tmp_manifest")

  if [[ "$state_is_valid" != "true" ]]; then
    echo "desired state $state for component $component preset $preset is invalid"
    rm -f "$tmp_manifest"
    return 1
  fi

  # Determine which component name to use for config changes
  local config_component
  if [[ -n "$child_component" ]]; then
    config_component="$child_component"
  else
    config_component="$component"
  fi

  if [[ "$state" == "$preset_disabled_state" ]]; then
    # Disabling preset
    log d "Disabling preset $preset for component $config_component"
    set_setting_value "$rd_conf" "$config_component" "$state" "retrodeck" "$preset"
  else
    # Enabling preset: check conflicting presets
    local conflicting_presets
    conflicting_presets=$(jq -c '.conflicting_presets // []' "$tmp_manifest")

    if [[ "$conflicting_presets" != "[]" ]]; then
      while IFS= read -r pair; do
        local preset_a preset_b conflicting_preset
        preset_a=$(jq -r '.[0]' <<< "$pair")
        preset_b=$(jq -r '.[1]' <<< "$pair")

        if [[ "$preset" == "$preset_a" ]]; then
          conflicting_preset="$preset_b"
        elif [[ "$preset" == "$preset_b" ]]; then
          conflicting_preset="$preset_a"
        else
          continue
        fi

        # Check if the conflicting preset has an entry for this component
        local conflicting_state
        conflicting_state=$(jq -r --arg section "$conflicting_preset" --arg setting "$config_component" '.presets[$section] | .. | objects | select(has($setting)) | .[$setting] // empty' "$rd_conf")

        if [[ -n "$conflicting_state" ]]; then
          local conflicting_disabled_state
          conflicting_disabled_state=$(jq -r --arg core "$child_component" --arg preset "$conflicting_preset" '
            if $core != "" then
              .compatible_presets[$core][$preset][0] // empty
            else
              .compatible_presets[$preset][0] // empty
            end
          ' "$tmp_manifest")

          if [[ "$conflicting_state" != "$conflicting_disabled_state" ]]; then
            echo "conflicting preset $conflicting_preset is currently enabled, cannot enable $preset"
            rm -f "$tmp_manifest"
            return 1
          fi
        fi
      done < <(jq -c '.[]' <<< "$conflicting_presets")
    fi

    # Check prerequisites
    local prerequisites
    prerequisites=$(jq -c --arg preset "$preset" '.preset_prerequisites[$preset] // null' "$tmp_manifest")

    if [[ "$prerequisites" != "null" && -n "$prerequisites" ]]; then
      while IFS= read -r var_name; do
        if [[ -z "${!var_name}" ]]; then
          local error_msg
          error_msg=$(jq -r '.error_message // "prerequisite check failed"' <<< "$prerequisites")
          echo "$error_msg"
          rm -f "$tmp_manifest"
          return 1
        fi
      done < <(jq -r '.required_vars[]' <<< "$prerequisites")
    fi

    log d "Enabling preset $preset for component $config_component"
    set_setting_value "$rd_conf" "$config_component" "$state" "retrodeck" "$preset"
  fi

  log d "Preset change passed all prechecks, continuing..."

  # Apply preset actions
  local config_format
  config_format=$(jq -r --arg core "$child_component" '
    if $core != "" then
      .preset_actions[$core].config_file_format
    else
      .preset_actions.config_file_format
    end
  ' "$tmp_manifest")

  log d "Config file format: $config_format"

  while IFS= read -r current_preset_object; do
    [[ -z "$current_preset_object" ]] && continue

    local preset_setting_name action apply_method
    preset_setting_name=$(jq -r '.setting_name' <<< "$current_preset_object")
    action=$(jq -r '.action' <<< "$current_preset_object")
    apply_method=$(jq -r '.apply_method // "set"' <<< "$current_preset_object")

    case "$action" in

      "change")
        local new_setting_value section target_file defaults_file
        new_setting_value=$(jq -r '.new_setting_value // empty' <<< "$current_preset_object")
        section=$(jq -r '.section // empty' <<< "$current_preset_object")
        target_file=$(jq -r '.target_file // empty' <<< "$current_preset_object")
        defaults_file=$(jq -r '.defaults_file // empty' <<< "$current_preset_object")

        [[ "$target_file" == \$* ]] && target_file=$(envsubst <<< "$target_file")
        [[ "$defaults_file" == \$* ]] && defaults_file=$(envsubst <<< "$defaults_file")
        [[ "$new_setting_value" == \$* ]] && new_setting_value=$(envsubst <<< "$new_setting_value")

        if [[ "$state" != "$preset_disabled_state" ]]; then
          if ! jq -e --arg state "$state" '.enabled_states | index($state) != null' <<< "$current_preset_object" > /dev/null 2>&1; then
            continue
          fi
          log d "Changing: $preset_setting_name = $new_setting_value in $target_file"
          set_setting_value "$target_file" "$preset_setting_name" "$new_setting_value" "$config_format" "$section"
        else
          local default_setting_value
          default_setting_value=$(get_setting_value "$defaults_file" "$preset_setting_name" "$config_format" "$section")
          log d "Restoring default: $preset_setting_name = $default_setting_value in $target_file"
          set_setting_value "$target_file" "$preset_setting_name" "$default_setting_value" "$config_format" "$section"
        fi
        ;;

      "add")
        local new_setting_value section target_file
        new_setting_value=$(jq -r '.new_setting_value // empty' <<< "$current_preset_object")
        section=$(jq -r '.section // empty' <<< "$current_preset_object")
        target_file=$(jq -r '.target_file // empty' <<< "$current_preset_object")

        [[ "$target_file" == \$* ]] && target_file=$(envsubst <<< "$target_file")
        [[ "$new_setting_value" == \$* ]] && new_setting_value=$(envsubst <<< "$new_setting_value")

        if [[ "$state" != "$preset_disabled_state" ]]; then
          if ! jq -e --arg state "$state" '.enabled_states | index($state) != null' <<< "$current_preset_object" > /dev/null 2>&1; then
            continue
          fi
          log d "Adding: $preset_setting_name = $new_setting_value in $target_file"
          if [[ ! -f "$target_file" ]]; then
            create_dir "$(realpath "$(dirname "$target_file")")"
            echo "$preset_setting_name = \"$new_setting_value\"" > "$target_file"
          elif grep -q "^${preset_setting_name}\b" "$target_file"; then
            set_setting_value "$target_file" "$preset_setting_name" "$new_setting_value" "$config_format" "$section"
          else
            add_setting "$target_file" "$preset_setting_name" "$new_setting_value" "$config_format" "$section"
          fi
        else
          log d "Removing: $preset_setting_name from $target_file"
          if [[ -f "$target_file" ]]; then
            delete_setting "$target_file" "$preset_setting_name" "$config_format" "$section"
            if [[ ! -s "$target_file" ]]; then
              log d "File is empty after removal, deleting"
              rm -f "$target_file"
              local target_dir
              target_dir=$(realpath "$(dirname "$target_file")")
              if [[ -z "$(ls -A "$target_dir" 2>/dev/null)" ]]; then
                log d "Directory is empty, removing"
                rmdir "$target_dir"
              fi
            fi
          fi
        fi
        ;;

      "raw_write")
        local new_setting_value target_file
        new_setting_value=$(jq -r '.new_setting_value // empty' <<< "$current_preset_object")
        target_file=$(jq -r '.target_file // empty' <<< "$current_preset_object")

        [[ "$target_file" == \$* ]] && target_file=$(envsubst <<< "$target_file")
        [[ "$new_setting_value" == \$* ]] && new_setting_value=$(envsubst <<< "$new_setting_value")

        if [[ "$state" != "$preset_disabled_state" ]]; then
          if ! jq -e --arg state "$state" '.enabled_states | index($state) != null' <<< "$current_preset_object" > /dev/null 2>&1; then
            continue
          fi
          log d "Writing: $new_setting_value to $target_file"
          create_dir "$(dirname "$target_file")"
          echo "$new_setting_value" > "$target_file"
        else
          log d "Removing file: $target_file"
          rm -f "$target_file"
        fi
        ;;

      "enable")
        local target_file
        target_file=$(jq -r '.target_file // empty' <<< "$current_preset_object")
        [[ "$target_file" == \$* ]] && target_file=$(envsubst <<< "$target_file")

        if [[ "$state" != "$preset_disabled_state" ]]; then
          if ! jq -e --arg state "$state" '.enabled_states | index($state) != null' <<< "$current_preset_object" > /dev/null 2>&1; then
            continue
          fi
          log d "Enabling file: $preset_setting_name"
          enable_file "$target_file"
        else
          log d "Disabling file: $preset_setting_name"
          disable_file "$target_file"
        fi
        ;;

      "install")
        local source_file target_file cleanup_type
        source_file=$(jq -r '.source // empty' <<< "$current_preset_object")
        target_file=$(jq -r '.destination // empty' <<< "$current_preset_object")
        cleanup_type=$(jq -r '.cleanup_type // empty' <<< "$current_preset_object")
        [[ "$source_file" == \$* ]] && source_file=$(envsubst <<< "$source_file")
        [[ "$target_file" == \$* ]] && target_file=$(envsubst <<< "$target_file")

        if [[ "$state" != "$preset_disabled_state" ]]; then
          if jq -e --arg state "$state" '.enabled_states | index($state) != null' <<< "$current_preset_object" > /dev/null 2>&1; then
            log d "Installing files for preset $preset_setting_name"
            install_preset_files "$source_file" "$target_file"
          fi
        else
          log d "Removing files for preset $preset_setting_name"
          remove_preset_files "$source_file" "$target_file" "$cleanup_type"
        fi
        ;;

      "symlink")
        local source_path target_path
        source_path=$(jq -r '.source // empty' <<< "$current_preset_object")
        target_path=$(jq -r '.target_file // empty' <<< "$current_preset_object")

        [[ "$source_path" == \$* ]] && source_path=$(envsubst <<< "$source_path")
        [[ "$target_path" == \$* ]] && target_path=$(envsubst <<< "$target_path")

        if [[ "$state" != "$preset_disabled_state" ]]; then
          if ! jq -e --arg state "$state" '.enabled_states | index($state) != null' <<< "$current_preset_object" > /dev/null 2>&1; then
            continue
          fi
          log d "Creating symlink: $target_path -> $source_path"
          create_dir "$(dirname "$target_path")"
          ln -svf "$source_path" "$target_path"
        else
          log d "Removing symlink: $target_path"
          if [[ -L "$target_path" ]]; then
            unlink "$target_path"
            _prune_empty_parents "$(dirname "$target_path")" "$(dirname "$target_path")"
          fi
        fi
        ;;

      "patch")
        local patch_file target_file
        patch_file=$(jq -r '.patch_file // empty' <<< "$current_preset_object")
        target_file=$(jq -r '.target_file // empty' <<< "$current_preset_object")

        [[ "$patch_file" == \$* ]] && patch_file=$(envsubst <<< "$patch_file")
        [[ "$target_file" == \$* ]] && target_file=$(envsubst <<< "$target_file")

        if [[ "$state" != "$preset_disabled_state" ]]; then
          if ! jq -e --arg state "$state" '.enabled_states | index($state) != null' <<< "$current_preset_object" > /dev/null 2>&1; then
            continue
          fi
          log d "Applying patch $patch_file to $target_file"
          if [[ -f "$patch_file" && -f "$target_file" ]]; then
            patch --forward --silent "$target_file" "$patch_file" || log w "Patch may have already been applied to $target_file"
          else
            log e "Patch file or target file not found: $patch_file, $target_file"
          fi
        else
          log d "Reversing patch $patch_file from $target_file"
          if [[ -f "$patch_file" && -f "$target_file" ]]; then
            patch --reverse --silent "$target_file" "$patch_file" || log w "Patch may have already been reversed from $target_file"
          else
            log e "Patch file or target file not found: $patch_file, $target_file"
          fi
        fi
        ;;

      "run")
        local on_enable on_disable
        on_enable=$(jq -r '.on_enable // empty' <<< "$current_preset_object")
        on_disable=$(jq -r '.on_disable // empty' <<< "$current_preset_object")

        [[ "$on_enable" == \$* ]] && on_enable=$(envsubst <<< "$on_enable")
        [[ "$on_disable" == \$* ]] && on_disable=$(envsubst <<< "$on_disable")

        if [[ "$state" != "$preset_disabled_state" ]]; then
          if ! jq -e --arg state "$state" '.enabled_states | index($state) != null' <<< "$current_preset_object" > /dev/null 2>&1; then
            continue
          fi
          if [[ -n "$on_enable" ]]; then
            if declare -F "$on_enable" > /dev/null; then
              log d "Running enable handler: $on_enable"
              "$on_enable"
            else
              log e "Enable handler not found: $on_enable"
            fi
          fi
        else
          if [[ -n "$on_disable" ]]; then
            if declare -F "$on_disable" > /dev/null; then
              log d "Running disable handler: $on_disable"
              "$on_disable"
            else
              log e "Disable handler not found: $on_disable"
            fi
          fi
        fi
        ;;

    esac

  done < <(jq -c --arg comp "$component" --arg core "$child_component" --arg preset "$preset" '
    if $core != "" then
      .preset_actions[$core][$preset][]
    else
      .preset_actions[$preset][]
    end
  ' "$tmp_manifest")

  rm -f "$tmp_manifest"
  echo "preset $preset for component $config_component was successfully changed to $state"
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
  # USAGE api_do_cheevos_login "$username" "$password"

  local username="$1"
  local password="$2"

  local cheevos_api_response
  cheevos_api_response=$(curl --silent \
    --data-urlencode "r=login" \
    --data-urlencode "u=$username" \
    --data-urlencode "p=$password" \
    "$ra_cheevos_api_url")

  local cheevos_success
  cheevos_success=$(jq -r '.Success' <<< "$cheevos_api_response")

  if [[ "$cheevos_success" == "true" ]]; then
    log d "cheevos login succeeded"
    cheevos_login_timestamp=$(date +%s)
    jq --arg ts "$cheevos_login_timestamp" '. + {Timestamp: $ts}' <<< "$cheevos_api_response"
  else
    log d "cheevos login failed"
    echo "login failed"
    return 1
  fi
}

api_do_move_retrodeck_directory() {
  local rd_dir_name="$1" # The folder variable name from retrodeck.json
  local dest="$2"
  local dir_to_move="$(get_setting_value "$rd_conf" "$rd_dir_name" "retrodeck" "paths")" # The path of that folder variable
  local dirname_to_move="$(basename "$dir_to_move")"
  local dest_root=""

  if [[ ! -n "$dir_to_move" ]]; then
    log e "path $rd_dir_name not found in retrodeck.json"
    echo "path $rd_dir_name not found in retrodeck.json"
    return 1
  fi

  if [[ -d "$dir_to_move" ]]; then # If the directory selected to move already exists at the expected location pulled from retrodeck.json
    if [[ "$dest" == "internal" ]]; then
      if [[ "$rd_dir_name" == "rd_home_path" ]]; then
        dest_root="$HOME"
      else
        dest_root="$HOME/retrodeck"
      fi
    elif [[ "$dest" == "sd" ]]; then
      if [[ -n "$sdcard" && -d "$sdcard" ]]; then
        if [[ "$rd_dir_name" == "rd_home_path" ]]; then
          dest_root="$sdcard"
        else
          dest_root="$sdcard/retrodeck"
        fi
      else
        log e "sdcard location could not be found"
        echo "sdcard location could not be found"
        return 1
      fi
    elif [[ -d "$dest" ]]; then
      dest_root="$dest"
    else
      log e "a valid destination was not specified"
      echo "a valid destination was not specified"
      return 1
    fi

    if [[ -w "$dest_root" ]]; then # If user picked a destination and it is writable
      if [[ (-d "$dest_root/$dirname_to_move" && ! -L "$dest_root/$dirname_to_move" && ! $rd_dir_name == "rd_home_path") || "$(realpath "$dir_to_move")" == "$dest_root/$dirname_to_move" ]]; then # If the user is trying to move the folder to where it already is (excluding symlinks that will be unlinked)
        log e "a directory with the name $dirname_to_move is already at the given destination $dest_root"
        echo "a directory with the name $dirname_to_move is already at the given destination $dest_root"
        return 1
      else
        if verify_space "$(echo "$dir_to_move" | sed 's/\/$//')" "$dest_root"; then # Make sure there is enough space at the destination
          if [[ -L "$dest_root/$dirname_to_move" ]]; then
            unlink "$dest_root/$dirname_to_move" # In case there is already a symlink at the picked destination
          fi
          move "$dir_to_move" "$dest_root/$dirname_to_move"
          if [[ -d "$dest_root/$dirname_to_move" ]]; then # If the move succeeded
            set_setting_value "$rd_conf" "$rd_dir_name" "$dest_root/$dirname_to_move" "retrodeck" "paths" # Set the new path for that folder variable in retrodeck.json

            # Multi-user: propagate shared path changes to all other users
            if [[ "$rd_dir_name" == "rd_home_path" ]]; then
              propagate_rd_home_path_update
            elif [[ "${multi_user_enabled:-false}" == "true" ]]; then
              load_path_scope_cache
              local scope="${path_scope_cache[$rd_dir_name]:-shared}"
              if [[ "$scope" == "shared" ]]; then
                multi_user_propagate_path_change "$rd_dir_name" "$dest_root/$dirname_to_move"
              fi
            fi

            source_component_functions
            prepare_component "postmove" "all" # Update all the appropriate emulator path settings
            log i "directory $rd_dir_name successfully moved to $dest_root/$dirname_to_move"
            echo "directory $rd_dir_name successfully moved to $dest_root/$dirname_to_move"
            return 0
          else
            log e "move failed, please check logs for more details"
            echo "move failed, please check logs for more details"
            return 1
          fi
        else # If there isn't enough space in the picked destination
          log e "not enough free space at given destination"
          echo "not enough free space at given destination"
          return 1
        fi
      fi
    else # If the user didn't pick any custom destination, or the destination picked is unwritable
      log e "the chosen destination is not writable"
      echo "the chosen destination is not writable"
      return 1
    fi
  else # The folder to move was not found at the path pulled from retrodeck.json
    log e "path $dir_to_move could not be found, retrodeck.json paths need to be repaired"
    echo "path $dir_to_move could not be found, retrodeck.json paths need to be repaired"
    return 1
  fi
}

api_do_backup_retrodeck_userdata() {
  local backup_type="$1"
  shift

  if [[ -z "$backup_type" || ! "$backup_type" =~ ^(complete|core|custom)$ ]]; then
    echo "Invalid backup type. Valid options: complete, core, custom"
    return 1
  fi

  create_dir "$backups_path"

  local backup_date
  backup_date=$(date +"%0m%0d_%H%M")
  local backup_log_file="$logs_path/${backup_date}_${backup_type}_backup_log.log"
  local backup_file="$backups_path/retrodeck_${backup_date}_${backup_type}.tar.gz"

  local -a resolved_paths=()
  declare -A path_symlink_flags

  if [[ "$backup_type" == "complete" || "$backup_type" == "core" ]]; then
    while IFS=$'\t' read -r raw_path follow_symlinks; do
      local resolved_path
      resolved_path=$(echo "$raw_path" | envsubst)
      if [[ -z "$resolved_path" ]]; then
        continue
      fi
      # If a path appears in multiple manifests, follow_symlinks=true wins
      if [[ -z "${path_symlink_flags[$resolved_path]}" ]]; then
        resolved_paths+=("$resolved_path")
        path_symlink_flags["$resolved_path"]="$follow_symlinks"
      elif [[ "$follow_symlinks" == "true" ]]; then
        path_symlink_flags["$resolved_path"]="true"
      fi
    done < <(
      jq -r --arg type "$backup_type" '
        [to_entries[] |
         .value.backup_data // {} | .[$type] // [] | .[] |
         [.path, (.follow_symlinks // false | tostring)]] | unique[] | @tsv
      ' "$component_manifest_cache_file"
    )

    if [[ ${#resolved_paths[@]} -eq 0 ]]; then
      echo "No backup paths defined in component manifests for type: $backup_type"
      return 1
    fi

  elif [[ "$backup_type" == "custom" ]]; then
    if [[ "$#" -eq 0 ]]; then
      echo "No paths specified for custom backup"
      return 1
    fi
    for arg in "$@"; do
      local resolved_path=""
      if [[ "$arg" == /* ]]; then
        resolved_path="$arg"
      elif [[ "$arg" == \$* ]]; then
        resolved_path=$(echo "$arg" | envsubst)
      else
        resolved_path=$(jq -r --arg key "$arg" '.paths[$key] // empty' "$rd_conf")
        if [[ -z "$resolved_path" ]]; then
          echo "Unknown path or key: $arg"
          return 1
        fi
      fi
      if [[ -z "${path_symlink_flags[$resolved_path]}" ]]; then
        resolved_paths+=("$resolved_path")
        path_symlink_flags["$resolved_path"]="false"
      fi
    done
  fi

  # Validate paths exist
  local -a valid_paths=()
  for path in "${resolved_paths[@]}"; do
    if [[ -e "$path" ]]; then
      valid_paths+=("$path")
      log i "Adding to backup: $path (follow_symlinks=${path_symlink_flags[$path]})"
    else
      log w "Path does not exist, skipping: $path"
    fi
  done

  if [[ ${#valid_paths[@]} -eq 0 ]]; then
    echo "No valid paths found to backup"
    return 1
  fi

  # Calculate total size of backup data
  log i "Calculating size of backup data..."
  local total_size=0
  for path in "${valid_paths[@]}"; do
    local du_flags="-sk"
    if [[ "${path_symlink_flags[$path]}" == "true" ]]; then
      du_flags="-sLk" # -L dereferences symlinks for accurate size
    fi
    local path_size_kb
    path_size_kb=$(du $du_flags "$path" 2>/dev/null | cut -f1)
    total_size=$((total_size + (path_size_kb * 1024)))
  done

  local available_space
  available_space=$(df -B1 "$backups_path" | awk 'NR==2 {print $4}')

  local required_space=$((total_size * 2))

  log i "Total size of backup data: $(numfmt --to=iec-i --suffix=B "$total_size")"
  log i "Required free space (with compression overhead): $(numfmt --to=iec-i --suffix=B "$required_space")"
  log i "Available space at destination: $(numfmt --to=iec-i --suffix=B "$available_space")"

  if [[ "$available_space" -lt "$required_space" ]]; then
    echo "Not enough free space. Need $(numfmt --to=iec-i --suffix=B "$required_space"), have $(numfmt --to=iec-i --suffix=B "$available_space")"
    return 1
  fi

  # Iterate paths to build archive
  log i "Starting $backup_type backup..."
  local tar_file="${backup_file%.gz}"

  for path in "${valid_paths[@]}"; do
    local tar_opts
    if [[ -e "$tar_file" ]]; then
      tar_opts="-rf"
    else
      tar_opts="-cf" # First path creates the archive
    fi
    if [[ "${path_symlink_flags[$path]}" == "true" ]]; then
      tar_opts="${tar_opts/f/hf}"
    fi
    if ! tar "$tar_opts" "$tar_file" "$path" >> "$backup_log_file" 2>&1; then
      echo "Backup failed while adding: $path. See log: $backup_log_file"
      rm -f "$tar_file"
      return 1
    fi
    log i "Added to archive: $path (follow_symlinks=${path_symlink_flags[$path]})"
  done

  if ! gzip "$tar_file"; then
    echo "Backup failed during compression. See log: $backup_log_file"
    rm -f "$tar_file"
    return 1
  fi

  if [[ ! -s "$backup_log_file" ]]; then
    rm -f "$backup_log_file"
  fi

  # Rotate old backups
  local max_backups
  max_backups=$(jq -r '.options.max_backups // 3' "$rd_conf")
  local -a old_backups=()
  mapfile -t old_backups < <(ls -t "$backups_path"/retrodeck_*_"${backup_type}".tar.gz 2>/dev/null | tail -n +"$((max_backups + 1))")
  if [[ ${#old_backups[@]} -gt 0 ]]; then
    rm -f "${old_backups[@]}"
    log i "Rotated backups: removed ${#old_backups[@]} old backup(s), keeping latest $max_backups of type $backup_type"
  fi

  local final_size
  final_size=$(du -h "$backup_file" | cut -f1)
  log i "Backup completed: $backup_file ($final_size)"
  echo "$backup_file"
  return 0
}

api_do_compress_games() {
  # Compress a set of games into their specified formats.
  # Receives a JSON array of game objects and an optional cleanup flag.
  # Sends per-game progress updates to the client via api_send_progress.
  # USAGE: api_do_compress_games "$game_objects_json" "[$post_compression_cleanup]"

  local game_objects="$1"
  local post_compression_cleanup="${2:-false}"
 
  # Validate game_objects is a JSON array
  if ! jq -e 'type == "array"' <<< "$game_objects" > /dev/null 2>&1; then
    echo "game_objects must be a JSON array"
    return 1
  fi
 
  local total
  total=$(jq -r 'length' <<< "$game_objects")
 
  if [[ "$total" -eq 0 ]]; then
    echo "No games provided for compression"
    return 1
  fi
 
  local current=0
  local success_count=0
  local fail_count=0
  local -a failed_games=()
 
  while IFS= read -r game_path; do
    [[ -z "$game_path" ]] && continue
    current=$((current + 1))
 
    local compression_format
    compression_format=$(jq -r --arg game_path "$game_path" \
      '.[] | select(.game == $game_path) | .format' <<< "$game_objects")
 
    local game_basename
    game_basename=$(basename "$game_path")
 
    # Send progress update to client
    api_send_progress "$current" "$total" "Compressing $game_basename into $compression_format format"
 
    # Call the core compression function
    if compress_game "$compression_format" "$game_path" "$post_compression_cleanup"; then
      success_count=$((success_count + 1))
    else
      fail_count=$((fail_count + 1))
      failed_games+=("$game_path")
    fi
  done < <(jq -r '.[].game' <<< "$game_objects")
 
  # Build result summary
  local result
  if [[ ${#failed_games[@]} -gt 0 ]]; then
    local failed_json
    failed_json=$(printf '%s\n' "${failed_games[@]}" | jq -R -s 'split("\n") | map(select(length > 0))')
    result=$(jq -c -n \
      --argjson total "$total" \
      --argjson success "$success_count" \
      --argjson failed "$fail_count" \
      --argjson failed_games "$failed_json" \
      '{total: $total, successful: $success, failed: $failed, failed_games: $failed_games}')
  else
    result=$(jq -c -n \
      --argjson total "$total" \
      --argjson success "$success_count" \
      '{total: $total, successful: $success, failed: 0}')
  fi
 
  echo "$result"
}
