#!/bin/bash

rd_zenity() {
  # This function replaces the standard 'zenity' command and filters out annoying GTK errors on Steam Deck
  export CONFIGURATOR_GUI="zenity"

  # env GDK_SCALE=1.5 \
  #     GDK_DPI_SCALE=1.5 \
  zenity 2> >(grep -v 'Gtk' >&2) "$@"

  local status=${PIPESTATUS[0]}  # Capture the exit code of 'zenity'

  unset CONFIGURATOR_GUI
  
  return "$status"
}

parse_json_to_array() {
  # This function will parse a set of JSON objects (which must all have the same sets of keys, but can have different values) into a given Bash array
  # This is useful for turning API JSON output into Bash arrays that can be used in Zenity dialogs
  # To avoid whitespace issues, the destination array must be given to this function as an argument, and will have its contents assigned directly
  # USAGE: parse_json_to_array $destination_arry $JSON_input
  local dest_array="$1"; shift
  local -a temp_bash_array=()

  while IFS= read -r json_value; do
    temp_bash_array+=( "$json_value" )
  done < <("$@" | jq -r '.[]
                          | if type=="array" then .[] else . end
                          | if type=="object" then .[] else . end
                          | if type=="array" then
                              join(",")
                            else
                              (if . == null then "" else tostring end)
                            end
                        ') # Flatten arrays of values into a CSV string

  eval "$dest_array=(\"\${temp_bash_array[@]}\")"
}

add_value_to_array() {
  # This function will add a specific value to an array at given intervals
  # This is useful if you are trying to adapt API-gathered information for Zenity checklists
  # It will take a "source" array, insert the "value" at the given interval and assign the new array to the "dest" array name
  # Example: You have an array that contains "retrodeck" "RetroDECK" "The RetroDECK Framework" "ppsspp" "PPSSPP" "PlayStation Portable Emulator" and want to use it in a 4-column Zenity checklist, which requires a true/false value in the first element of each data "set"
  # You can accomplish that with the following call:
  # USAGE: add_value_to_array source_array dest_array FALSE 3
  local -n array_in="$1"
  local -n array_out="$2"
  local value="$3"
  local group_size="$4"

  array_out=()
  for ((i=0; i<${#array_in[@]}; i++)); do
    if (( i % group_size == 0 )); then
      array_out+=( "$value" )
    fi
    array_out+=( "${array_in[i]}" )
  done
}

bash_rearranger() {
  # This function will rerrange a given Bash array by "groups" with a given index order into a new destination array.
  # For example if you have an array with the contents ( "four" "three" "two" "one" )
  # You can use this function to reorder it to ( "one" "two" "three" "four" ) using the order pattern "4 3 2 1"
  # The function also works with groups in a bash array of any length,
  # so to change ( "after1" "before1" "after2" "before2" ) to ( "before1" "after1" "before2" "after2" ) you can use a order pattern of "2 1"
  # The order patterns are always space-delimited groups of integers.
  # USAGE: bash_rearranger "order pattern" "source_array_name" "dest_array_name"
  local order_pattern="$1"
  local -n source_array="$2"
  local -n dest_array="$3"
  shift 3

  read -ra order <<< "$order_pattern"

  dest_array=()

  local group_size=${#order[@]}
  local total_elements=${#source_array[@]}

  for (( i=0; i<total_elements; i+=group_size )); do
    for array_index in "${order[@]}"; do
      dest_array+=( "${source_array[i + array_index - 1]}" )
    done
  done
}

keep_parts_of_array() {
  local keep_pattern="$1"
  local source_array="$2"
  local dest_array="$3"
  local group_size="$4"
  shift 4

  read -ra pattern <<< "$keep_pattern"

  local -n in="$source_array"
  local -n out="$dest_array"

  out=()

  local total=${#in[@]}
  if (( total % group_size != 0 )); then
    echo "Error: \${#$source_array[@]} ($total) is not a multiple of group size ($group_size)" >&2
    return 1
  fi

  for (( i=0; i<total; i+=group_size )); do
    for array_index in "${pattern[@]}"; do
      out+=( "${in[i + array_index - 1]}" )
    done
  done
}

remove_group_from_array() {
  local key="$1"
  local source_array="$2"
  local dest_array="$3"
  local group_size="$4"
  shift 4

  local -n in=$source_array
  local -n out=$dest_array

  out=()

  local total=${#in[@]}
  if (( total % group_size != 0 )); then
    echo "Error: \${#$source_array[@]} ($total) is not a multiple of group size ($group_size)" >&2
    return 1
  fi

  for (( i=0; i<total; i+=group_size )); do
    if [[ "${in[i]}" == "$key" ]]; then # if this group's first element matches key, skip it
      continue
    fi
    for (( j=0; j<group_size; j++ )); do
      out+=( "${in[i + j]}" )
    done
  done
}

build_zenity_menu_array() {
  local dest_array="$1"
  local menu_name="$2"
  local -a temp_bash_array=()
  local all_menu_entries=$(api_get_component_menu_entries "$menu_name") # Collect all relevent menu objects from all components

  if [[ "$menu_name" == "settings" ]]; then # If building the Settings menu, start with all known presets
    while read -r preset_name; do
      local name=$(jq -r --arg preset "$preset_name" '.presets[$preset].name // empty' "$features")
      local desc=$(jq -r --arg preset "$preset_name" '.presets[$preset].desc // empty' "$features")
      local command="configurator_change_preset_dialog $preset_name"
      temp_bash_array+=("$name" "$desc" "$command")
    done < <(api_get_all_preset_names | jq -r '.[].preset_name')
  fi

  while read -r obj; do # Iterate through all returned menu objects
    local name=$(jq -r '.name' <<< "$obj")
    local desc=$(jq -r '.description' <<< "$obj")
    local command=$(jq -r '.command.zenity' <<< "$obj")
    temp_bash_array+=("$name" "$desc" "$command")
  done < <(jq -c --arg menu "$menu_name" '.[$menu].[]' <<< "$all_menu_entries")

  eval "$dest_array=(\"\${temp_bash_array[@]}\")"
}

build_zenity_preset_menu_array() {
  local dest_array="$1"
  local preset_name="$2"
  local -a temp_bash_array=()
  local current_preset_states=$(api_get_current_preset_state "$preset_name")

  while read -r obj; do # Iterate through all returned menu objects
    local system_name=$(jq -r '.system_name // empty' <<< "$obj")
    local friendly_name=$(jq -r '.system_friendly_name // empty' <<< "$obj")
    local desc=$(jq -r '.description // empty' <<< "$obj")
    local emulated_friendly_name=$(jq -r '.emulated_system_friendly_name | if type=="array" then join(", ") else . end // empty' <<< "$obj")
    local status=$(jq -r '.status // empty' <<< "$obj")
    local parent_component=$(jq -r '.parent_component // empty' <<< "$obj")

    if [[ -n "$parent_component" ]]; then
      local component="$parent_component"
    else
      local component="$system_name"
    fi

    local preset_disabled_state=$(jq -r --arg component "$system_name" --arg parent "$parent_component" --arg preset "$preset_name" '
                                if $parent != "" then
                                  .[$parent].compatible_presets[$component][$preset].[0] // empty
                                else
                                  .[$component].compatible_presets[$preset].[0] // empty
                                end
                              ' "$rd_components/$component/component_manifest.json")

    if [[ "$status" == "$preset_disabled_state" ]]; then
      status="Disabled"
    elif [[ "$status" == "true" ]]; then
      status="Enabled"
    else
      status=$(echo "$status" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1')
    fi

    temp_bash_array+=("$status" "$friendly_name" "$emulated_friendly_name" "$desc" "$system_name")
  done < <(jq -c --arg preset "$preset_name" '.[$preset].[]' <<< "$current_preset_states")

  eval "$dest_array=(\"\${temp_bash_array[@]}\")"
}

build_zenity_preset_value_menu_array() {
  local dest_array="$1"
  local preset_name="$2"
  local component="$3"

  local -a temp_bash_array=()

  local preset_current_value=$(get_setting_value "$rd_conf" "$component" "retrodeck" "$preset_name")

  local base_component=$(jq -r --arg preset "$preset_name" \
                        --arg component "$component" '.presets[$preset]
                                                    | paths(scalars)
                                                    | select(.[-1] == $component)
                                                    | if length > 1 then .[-2] else $preset end
                                                    ' "$rd_conf")

  if [[ ! "$preset_name" == "$base_component" ]]; then # If component is a core
    log d "Component $component is a core of $base_component"
    base_component="${base_component%_cores}"
  else
    base_component="$component"
  fi

  while read -r preset_value; do
    if [[ "$preset_value" == "false" ]]; then
      local pretty_status="Disabled"
    elif [[ "$preset_value" == "true" ]]; then
      local pretty_status="Enabled"
    else
      local pretty_status=$(echo "$status" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1')
    fi

    if [[ "$preset_value" == "$preset_current_value" ]]; then
      local currently_set_value="true"
    else
      local currently_set_value="false"
    fi

    temp_bash_array+=("$currently_set_value" "$pretty_status" "$preset_value")
  done < <(jq -r --arg component "$component" --arg parent "$base_component" --arg preset "$preset_name" '
                                if $parent != $component then
                                  .[$parent].compatible_presets[$component][$preset].[] // empty
                                else
                                  .[$component].compatible_presets[$preset].[] // empty
                                end
                                ' "$rd_components/$base_component/component_manifest.json")

  eval "$dest_array=(\"\${temp_bash_array[@]}\")"
}

build_zenity_open_component_menu_array() {
  local dest_array="$1"
  local -a temp_bash_array=()

  while read -r obj; do # Iterate through all returned menu objects
    local name=$(jq -r '.component_friendly_name' <<< "$obj")
    local desc=$(jq -r '.description' <<< "$obj")
    local command=$(jq -r '.path' <<< "$obj")
    temp_bash_array+=("$name" "$desc" "$command")
  done < <(api_get_component "all" | jq -c 'sort_by(.component_name) | .[] | select(.component_name != null)')

  eval "$dest_array=(\"\${temp_bash_array[@]}\")"
}

build_zenity_reset_component_menu_array() {
  local dest_array="$1"
  local -a temp_bash_array=()

  while read -r obj; do # Iterate through all returned menu objects
    local checkbox_state="FALSE"
    local name=$(jq -r '.component_name' <<< "$obj")
    local friendly_name=$(jq -r '.component_friendly_name' <<< "$obj")
    local desc=$(jq -r '.description' <<< "$obj")
    temp_bash_array+=("$checkbox_state" "$name" "$friendly_name" "$desc")
  done < <(api_get_component "all" | jq -c 'sort_by(.component_name) | .[] | select(.component_name != null)')

  eval "$dest_array=(\"\${temp_bash_array[@]}\")"
}
