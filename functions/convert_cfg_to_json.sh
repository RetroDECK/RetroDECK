#!/bin/bash

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

# Preset nesting rules: "section.key" -> "parent1.parent2.final_key"
# Format: "section_name.original_key=nested.path.to.key"
# Use empty value for no transformation
declare -A PRESET_NESTING_MAP=(
  ["borders.gb"]="retroarch.cores.gambatte_libretro"
  ["borders.gba"]="retroarch.cores.mgba_libretro"
  ["borders.gbc"]="retroarch.cores.gambatte_libretro"
  ["borders.genesis"]="retroarch.cores.genesis_plus_gx_libretro"
  ["borders.gg"]="retroarch.cores.genesis_plus_gx_libretro"
  ["borders.n64"]="retroarch.cores.mupen64plus_next_libretro"
  ["borders.psx_ra"]="retroarch.cores.pcsx_rearmed_libretro"
  ["borders.snes"]="retroarch.cores.snes9x-current_libretro"

  ["widescreen.genesis"]="retroarch.cores.genesis_plus_gx_libretro"
  ["widescreen.n64"]="retroarch.cores.mupen64plus_next_libretro"
  ["widescreen.psx_ra"]="retroarch.cores.pcsx_rearmed_libretro"
  ["widescreen.snes"]="retroarch.cores.snes9x-current_libretro"

  ["rewind.gb"]="retroarch.cores.gambatte_libretro"
  ["rewind.gba"]="retroarch.cores.mgba_libretro"
  ["rewind.gbc"]="retroarch.cores.gambatte_libretro"
  ["rewind.genesis"]="retroarch.cores.genesis_plus_gx_libretro"
  ["rewind.gg"]="retroarch.cores.genesis_plus_gx_libretro"
  ["rewind.snes"]="retroarch.cores.snes9x-current_libretro"
)

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

get_nesting_path() {
  local section="$1"
  local key="$2"
  local lookup="${section}.${key}"

  if [[ -n "${PRESET_NESTING_MAP[$lookup]:-}" ]]; then
    echo "${PRESET_NESTING_MAP[$lookup]}"
  else
    echo "$key"
  fi
}

convert_cfg_to_json() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <input.ini> [output.json]"
    echo "If output.json is not specified, outputs to stdout"
    exit 1
  fi

  input_file="$1"
  output_file="${2:-}"

  if [[ ! -f "$input_file" ]]; then
    echo "Error: Input file '$input_file' not found"
    exit 1
  fi

  json_output='{}'

  current_section=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//') # Trim whitespace

    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue
    [[ "$line" =~ ^\; ]] && continue

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

      if [[ "$current_section" == "paths" ]]; then
        json_output=$(echo "$json_output" | jq --arg key "$transformed_key" --arg val "$value" \
            '.paths[$key] = $val')
      elif [[ "$current_section" == "options" ]]; then
        json_output=$(echo "$json_output" | jq --arg key "$transformed_key" --arg val "$value" \
            '.options[$key] = $val')
      else # This is a preset section
        nesting_path=$(get_nesting_path "$current_section" "$key")

        if [[ "$nesting_path" == *"."* ]]; then
          IFS='.' read -ra PATH_PARTS <<< "$nesting_path"
          jq_path=".presets[\"$current_section\"]"

          for part in "${PATH_PARTS[@]}"; do
            jq_path="${jq_path}[\"${part}\"]"
          done

          json_output=$(echo "$json_output" | jq --arg v "$value" "${jq_path} = \$v")
        else
          json_output=$(echo "$json_output" | jq --arg section "$current_section" \
              --arg k "$nesting_path" --arg v "$value" \
              '.presets[$section][$k] = $v')
        fi
      fi
    fi
  done < "$input_file"

  if [[ -n "$output_file" ]]; then
    echo "$json_output" | jq '.' > "$output_file"
    echo "Conversion complete: $output_file"
  else
    echo "$json_output" | jq '.'
  fi
}

input_file="$1"
shift

convert_cfg_to_json "$1" "$@"
