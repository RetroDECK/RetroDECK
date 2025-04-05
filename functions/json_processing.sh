#!/bin/bash

# This is a reusable JSON object creator, meant to abstract the actual jq commands for easier readbility and use.
# The purpose is similar to the get_setting_value and set_setting_value functions, where you don't need to know the actual sed commands to get what you want.

json_init() {
  # Initialize an empty JSON file (using a temp file)
  # This temp file will be accessible in any functions in the shell that created it
  # If multiple subshells are being used (by concurrent multi-threading) multiple temp files will be created.
  JSON_BUILDER_TMP=$(mktemp)
  echo '{}' > "$JSON_BUILDER_TMP"
}

json_add() {
  # Adds a string or raw value to the JSON
  # type = "string" (default) or "raw" - "type" can be omitted and will just default to string, which is generally fine. If the value is numeric and will be used for math, it can save a step downstream to store it raw.
  # Usage: json_add "key" "value" "type"
  
  local key="$1"
  local value="$2"
  local type="${3:-string}"

  if [[ "$type" == "raw" ]]; then
    jq --argjson val "$value" ". + {\"$key\": \$val}" "$JSON_BUILDER_TMP" > "$JSON_BUILDER_TMP.tmp"
  else
    jq --arg val "$value" ". + {\"$key\": \$val}" "$JSON_BUILDER_TMP" > "$JSON_BUILDER_TMP.tmp"
  fi

  mv "$JSON_BUILDER_TMP.tmp" "$JSON_BUILDER_TMP"
}

json_add_array() {
  # Add an array (from bash array) to the JSON
  # USAGE: json_add_array "key" "${my_array[@]}"
  local key="$1"
  shift
  local arr=("$@")

  # Convert bash array to JSON array
  local json_array
  json_array=$(printf '%s\n' "${arr[@]}" | jq -R . | jq -s .)

  jq --argjson val "$json_array" ". + {\"$key\": \$val}" "$JSON_BUILDER_TMP" > "$JSON_BUILDER_TMP.tmp"
  mv "$JSON_BUILDER_TMP.tmp" "$JSON_BUILDER_TMP"
}

json_build() {
  # This exports the final JSON object and removes the temp file.
  # USAGE: (after building the JSON object in the temp file using the above functions) json_object=$(json_build)
  cat "$JSON_BUILDER_TMP"
  rm -f "$JSON_BUILDER_TMP"
}
