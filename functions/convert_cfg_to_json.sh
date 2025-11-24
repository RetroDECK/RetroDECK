#!/bin/bash

transform_key() {
  local section="$1"
  local key="$2"
  local transformed="$key"

  case "$section" in
    paths)
      if [[ -n "${PATH_KEY_MAP[$key]:-}" ]]; then
          transformed="${PATH_KEY_MAP[$key]}"
      fi
    ;;
    options)
      if [[ -n "${OPTIONS_KEY_MAP[$key]:-}" ]]; then
          transformed="${OPTIONS_KEY_MAP[$key]}"
      fi
    ;;
  esac

  echo "$transformed"
}

get_nesting_info() {
  local section="$1"
  local key="$2"
  local lookup="${section}.${key}"

  if [[ -n "${PRESET_NESTING_MAP[$lookup]:-}" ]]; then
    echo "${PRESET_NESTING_MAP[$lookup]}"
  else
    echo "$key"
  fi
}

is_excluded() {
  local section="$1"
  local key="$2"
  local lookup

  if [[ -n "$section" ]]; then
    lookup="${section}.${key}"
  else
    lookup="$key"
  fi

  for excluded in "${EXCLUDE_KEYS[@]}"; do
    if [[ "$excluded" == "$lookup" ]]; then
      return 0  # Is excluded
    fi
  done

  return 1  # Is not excluded
}

convert_cfg_to_json() {
  set -euo pipefail

  declare -A PATH_KEY_MAP=(
    ["rdhome"]="rd_home_path"
    ["roms_folder"]="roms_path"
    ["saves_folder"]="saves_path"
    ["states_folder"]="states_path"
    ["shaders_folder"]="shaders_path"
    ["bios_folder"]="bios_path"
    ["backups_folder"]="backups_path"
    ["media_folder"]="downloaded_media_path"
    ["themes_folder"]="themes_path"
    ["logs_folder"]="logs_path"
    ["screenshots_folder"]="screenshots_path"
    ["mods_folder"]="mods_path"
    ["texture_packs_folder"]="texture_packs_path"
    ["borders_folder"]="borders_path"
    ["cheats_folder"]="cheats_path"
    ["sdcard"]="sdcard"
  )

  declare -A OPTIONS_KEY_MAP=(
    ["logging_level"]="rd_logging_level"
  )

  declare -A PRESET_NESTING_MAP=(
    ["borders.gb"]="retroarch_cores.gambatte_libretro_GB"
    ["borders.gb"]="retroarch_cores.gambatte_libretro_GBC"
    ["borders.gba"]="retroarch_cores.mgba_libretro"
    ["borders.genesis"]="retroarch_cores.genesis_plus_gx_libretro_MS"
    ["borders.genesis"]="retroarch_cores.genesis_plus_gx_libretro_GG"
    ["borders.n64"]="retroarch_cores.mupen64plus_next_libretro"
    ["borders.psx_ra"]="retroarch_cores.swanstation_libretro"
    ["borders.snes"]="retroarch_cores.snes9x-current_libretro"

    ["widescreen.genesis"]="retroarch_cores.genesis_plus_gx_libretro_MS"
    ["widescreen.n64"]="retroarch_cores.mupen64plus_next_libretro"
    ["widescreen.psx_ra"]="retroarch_cores.swanstation_libretro"
    ["widescreen.snes"]="retroarch_cores.snes9x-current_libretro"

    ["rewind.gb"]="retroarch_cores.gambatte_libretro_GB"
    ["rewind.gbc"]="retroarch_cores.gambatte_libretro_GBC"
    ["rewind.gba"]="retroarch_cores.mgba_libretro"
    ["rewind.genesis"]="retroarch_cores.genesis_plus_gx_libretro_MS"
    ["rewind.genesis"]="retroarch_cores.genesis_plus_gx_libretro_GG"
    ["rewind.snes"]="retroarch_cores.snes9x-current_libretro"

    ["abxy_button_swap.gb"]="retroarch_cores.gambatte_libretro_GB"
    ["abxy_button_swap.gbc"]="retroarch_cores.gambatte_libretro_GBC"
    ["abxy_button_swap.gba"]="retroarch_cores.mgba_libretro"
    ["abxy_button_swap.n64"]="retroarch_cores.mupen64plus_next_libretro"
    ["abxy_button_swap.snes"]="retroarch_cores.snes9x-current_libretro"
  )

  declare -a EXCLUDE_KEYS=(
    "abxy_button_swap.citra"
    "options.kiroi_ponzu"
    "options.akai_ponzu"
    "ask_to_exit.citra"
  )

  input_file="$1"
  output_file="${2:-}"

  if [[ ! -f "$input_file" ]]; then
    log e "Error: Input file '$input_file' not found"
    exit 1
  fi

  json_output='{"version":"","paths":{},"options":{},"presets":{}}'

  current_section=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//') # Trim whitespace

    if [[ -z "$line" || "$line" =~ ^[#\;] ]]; then # Skip empty lines and comments
      continue
    fi

    if [[ "$line" =~ ^\[([^]]+)\]$ ]]; then
      current_section="${BASH_REMATCH[1]}"
      continue
    fi

    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"

      key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
      value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

      transformed_key=$(transform_key "$current_section" "$key")

      if is_excluded "$current_section" "$key"; then
        continue
      fi

      if [[ ! -n "$current_section" ]]; then
        json_output=$(echo "$json_output" | jq --arg key "$transformed_key" --arg val "$value" \
            '.[$key] = $val')
      elif [[ "$current_section" == "paths" ]]; then
        json_output=$(echo "$json_output" | jq --arg key "$transformed_key" --arg val "$value" \
            '.paths[$key] = $val')
      elif [[ "$current_section" == "options" ]]; then
        json_output=$(echo "$json_output" | jq --arg key "$transformed_key" --arg val "$value" \
            '.options[$key] = $val')
      else # This is a preset section
        nesting_info=$(get_nesting_info "$current_section" "$key")

        if [[ "$nesting_info" =~ ^([^.]+)\.(.+)$ ]]; then
          parent="${BASH_REMATCH[1]}"
          final_key="${BASH_REMATCH[2]}"

          json_output=$(echo "$json_output" | jq --arg section "$current_section" \
              --arg parent "$parent" --arg key "$final_key" --arg val "$value" \
              '.presets[$section][$parent][$key] = $val')
        else
          json_output=$(echo "$json_output" | jq --arg section "$current_section" \
              --arg key "$nesting_info" --arg val "$value" \
              '.presets[$section][$key] = $val')
        fi
      fi
    fi
  done < "$input_file"

  if [[ -n "$output_file" ]]; then
    echo "$json_output" | jq '.' > "$output_file"
    log i "Conversion complete: $output_file"
  else
    echo "$json_output" | jq '.'
  fi
}
