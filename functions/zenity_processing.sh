#!/bin/bash

rd_zenity() {
  # This function replaces the standard 'zenity' command and filters out annoying GTK errors on Steam Deck

  # env GDK_SCALE=1.5 \
  #     GDK_DPI_SCALE=1.5 \
  zenity 2> >(grep -v 'Gtk' >&2) "$@"

  local status=${PIPESTATUS[0]}  # Capture the exit code of 'zenity'
  
  return "$status"
}

build_zenity_menu_array() {
  # Build a Bash array of menu entries for use in a Zenity dialog.
  # Each entry consists of three consecutive elements: name, description, command.
  # Entries with a "priority" key are sorted by priority first, followed by remaining entries sorted alphabetically.
  # USAGE: build_zenity_menu_array "$dest_array_name" "$menu_name"

  local -n dest_array="$1"
  local menu_name="$2"
  dest_array=()

  if [[ "$menu_name" == "settings" ]]; then
    local preset_definitions
    preset_definitions=$(get_all_preset_definitions)

    mapfile -t dest_array < <(
      api_get_all_preset_names | jq -r --argjson defs "$preset_definitions" '
        [.[] | .preset_name as $preset_name | {
          name: ($defs[$preset_name].name // $preset_name),
          description: ($defs[$preset_name].desc // ""),
          command: ("configurator_change_preset_dialog " + $preset_name),
          priority: ($defs[$preset_name].priority // null)
        }]
        | (map(select(.priority != null)) | sort_by(.priority, .name))
          + (map(select(.priority == null)) | sort_by(.name))
        | .[]
        | .name, .description, .command
      '
    )
  fi

  local -a menu_entries=()
  mapfile -t menu_entries < <(api_get_component_menu_entries "$menu_name" | jq -r --arg menu "$menu_name" '
    .[$menu] // [] |
    (map(select(.priority != null)) | sort_by(.priority))
      + (map(select(.priority == null)) | sort_by(.name))
    | .[]
    | .name,
      .description,
      .command.zenity
  ')

  dest_array+=("${menu_entries[@]}")
}

build_zenity_preset_menu_array() {
  # Build a Bash array of preset state entries for use in a Zenity dialog.
  # Each entry consists of five consecutive elements: status, friendly_name, emulated_system, description, system_name.
  # USAGE: build_zenity_preset_menu_array "$dest_array_name" "$preset_name"
  
  local -n dest_array="$1"
  local preset_name="$2"
  local current_preset_states
  
  current_preset_states=$(api_get_current_preset_state "$preset_name")
  mapfile -t dest_array < <(jq -r --arg preset "$preset_name" \
    --slurpfile manifests "$component_manifest_cache_file" '
    .[$preset] // [] | .[] |
    .system_name as $sn |
    .parent_component as $parent |
    (if $parent != "" then $parent else $sn end) as $comp |
    # Find the disabled state from the manifest cache
    ([$manifests[0][] | .manifest | select(has($comp)) | .[$comp]] | first) as $manifest |
    (if $parent != "" then
      $manifest.compatible_presets[$sn][$preset][0] // ""
    else
      $manifest.compatible_presets[$preset][0] // ""
    end) as $disabled_state |
    # Resolve display status
    (if .status == $disabled_state then "Disabled"
     elif .status == "true" then "Enabled"
     else (.status | split(" ") | map(
       (.[0:1] | ascii_upcase) + .[1:]
     ) | join(" "))
     end) as $display_status |
    # Resolve emulated system friendly name
    (.emulated_system_friendly_name | if type == "array" then join(", ") else . end // "") as $emu_name |
    $display_status,
    (.system_friendly_name // ""),
    $emu_name,
    (.description // ""),
    $sn
  ' <<< "$current_preset_states")
}

build_zenity_preset_value_menu_array() {
  # Build a Bash array of available preset values for a specific component, for use in a Zenity dialog.
  # Each entry consists of three consecutive elements: is_current_value, display_name, raw_value.
  # USAGE: build_zenity_preset_value_menu_array "$dest_array_name" "$preset_name" "$component"

  local -n dest_array="$1"
  local preset_name="$2"
  local component="$3"

  local preset_current_value
  preset_current_value=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset_name")

  local base_component
  base_component=$(jq -r --arg preset "$preset_name" --arg component "$component" '
    .presets[$preset]
    | paths(scalars)
    | select(.[-1] == $component)
    | if length > 1 then .[-2] else $preset end
  ' "$rd_conf")

  if [[ "$preset_name" != "$base_component" ]]; then
    log d "Component $component is a core of $base_component"
    base_component="${base_component%_cores}"
  else
    base_component="$component"
  fi

  mapfile -t dest_array < <(jq -r --arg comp "$component" \
    --arg parent "$base_component" \
    --arg preset "$preset_name" \
    --arg current "$preset_current_value" \
  '
    ([.[] | .manifest | select(has($parent)) | .[$parent]] | first) as $manifest |
    (if $parent != $comp then
      $manifest.compatible_presets[$comp][$preset]
    else
      $manifest.compatible_presets[$preset]
    end // []) | .[] |
    . as $val |
    (if $val == $current then "true" else "false" end),
    (if $val == "false" then "Disabled"
     elif $val == "true" then "Enabled"
     else ($val | split(" ") | map(
       (.[0:1] | ascii_upcase) + .[1:]
     ) | join(" "))
     end),
    $val
  ' "$component_manifest_cache_file")
}

build_zenity_open_component_menu_array() {
  # Build a Bash array of component entries for use in a Zenity dialog.
  # Each entry consists of three consecutive elements: friendly_name, description, path.
  # USAGE: build_zenity_open_component_menu_array "$dest_array_name"

  local -n dest_array="$1"

  mapfile -t dest_array < <(api_get_component "all" | jq -r '
    sort_by(.component_name)
    | .[]
    | select(.component_name != null and .component_name != "retrodeck")
    | .component_friendly_name,
      .description,
      .path
  ')
}

build_zenity_reset_component_menu_array() {
  # Build a Bash array of component entries with checkboxes for use in a Zenity reset dialog.
  # Each entry consists of four consecutive elements: checkbox_state, component_name, friendly_name, description.
  # USAGE: build_zenity_reset_component_menu_array "$dest_array_name"

  local -n dest_array="$1"

  mapfile -t dest_array < <(api_get_component "all" | jq -r '
    sort_by(.component_name)
    | .[]
    | select(.component_name != null and .component_name != "retrodeck")
    | "FALSE",
      .component_name,
      .component_friendly_name,
      .description
  ')
}

build_zenity_find_empty_rom_folders_menu_array() {
  # Build a Bash array of empty ROM folder entries with checkboxes for use in a Zenity dialog.
  # Each entry consists of three consecutive elements: checkbox_state, system, path.
  # USAGE: build_zenity_find_empty_rom_folders_menu_array "$dest_array_name"

  local -n dest_array="$1"

  local empty_folders
  empty_folders=$(api_get_empty_rom_folders)

  if [[ "$empty_folders" == "no empty rom folders found" ]]; then
    dest_array=()
    return
  fi

  mapfile -t dest_array < <(jq -r '
    .[] |
    "TRUE",
    .system,
    .path
  ' <<< "$empty_folders")
}

build_zenity_bios_checker_menu_array() {
  # Build a Bash array of BIOS file status entries for use in a Zenity dialog.
  # Each entry consists of eight consecutive elements per BIOS file.
  # USAGE: build_zenity_bios_checker_menu_array "$dest_array_name" "$system_filter(optional)"

  local -n dest_array="$1"
  local system_filter="${2:-}"

  mapfile -t dest_array < <(api_get_bios_file_status "$system_filter" | jq -r --arg bios_path "$bios_path" '
    .[] |
    .file // "Unknown",
    .systems // "Unknown",
    .file_found // "No",
    .md5_matched // "No",
    .required // "No",
    .paths // $bios_path,
    .description // "No description provided",
    .known_md5_hashes // "Unknown"
  ')
}

build_zenity_compression_menu_array() {
  # Build a Bash array of compression format entries for use in a Zenity dialog.
  # Each entry consists of two consecutive elements: display_name, description.
  # Formats are collected from all component manifests and deduplicated.
  # USAGE: build_zenity_compression_menu_array "$dest_array_name"

  local -n dest_array="$1"

  mapfile -t dest_array < <(jq -r '
    [ .[] | .manifest | to_entries[] | .value.compression // empty | keys[] ] |
    unique | sort[] |
    (. | ascii_upcase) as $upper |
    "Compress Multiple Games: \($upper)",
    "Compress one or more games into the \($upper) format."
  ' "$component_manifest_cache_file")
}
