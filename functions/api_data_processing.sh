#!/bin/bash

# This is the main data processing hub for the RetroDECK API.
# It will handle the direct demands of the API requests by leveraging the rest of the RetroDECK functions.
# Most of these functions will have been adapted from the ones built for the Zenity Configurator, with the Zenity specifics pulled out and all data passed through JSON objects.

api_find_compatible_games() {
  # Supported parameters:
  # "everything"  - All games found (regardless of format)
  # "all"         - Only user-chosen games (later selected via checklist)
  # "chd", "zip", "rvz" - Only games matching that compression type

  log d "Started find_compatible_games with parameter: $1"

  local target_selection="$1"
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

  local output_file="$(mktemp)"

  # Initialize the empty JSON file meant for final output
  echo '[]' > "$output_file"

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
                json_init
                json_add "game" "$game"
                json_add "compression" "$compatible_compression_format"
                # Build the complete JSON object for this game
                json_obj=$(json_build)
                # Write the final JSON object to the output file, locking it to prevent write race conditions.
                (
                flock -x 200
                jq --argjson obj "$json_obj" '. + [$obj]' "$output_file" > "$output_file.tmp" && mv "$output_file.tmp" "$output_file"
                ) 200>"$RD_FILE_LOCK"
              fi
              ;;
            "zip")
              if [[ "$compatible_compression_format" == "zip" ]]; then
                log d "Game $game is compatible with ZIP compression"
                # Build a JSON object for this game.
                json_init
                json_add "game" "$game"
                json_add "compression" "$compatible_compression_format"
                # Build the complete JSON object for this game
                json_obj=$(json_build)
                # Write the final JSON object to the output file, locking it to prevent write race conditions.
                (
                flock -x 200
                jq --argjson obj "$json_obj" '. + [$obj]' "$output_file" > "$output_file.tmp" && mv "$output_file.tmp" "$output_file"
                ) 200>"$RD_FILE_LOCK"
              fi
              ;;
            "rvz")
              if [[ "$compatible_compression_format" == "rvz" ]]; then
                log d "Game $game is compatible with ZIP compression"
                # Build a JSON object for this game.
                json_init
                json_add "game" "$game"
                json_add "compression" "$compatible_compression_format"
                # Build the complete JSON object for this game
                json_obj=$(json_build)
                # Write the final JSON object to the output file, locking it to prevent write race conditions.
                (
                flock -x 200
                jq --argjson obj "$json_obj" '. + [$obj]' "$output_file" > "$output_file.tmp" && mv "$output_file.tmp" "$output_file"
                ) 200>"$RD_FILE_LOCK"
              fi
              ;;
            "all")
              if [[ "$compatible_compression_format" != "none" ]]; then
                log d "Game $game is compatible with ZIP compression"
                # Build a JSON object for this game.
                json_init
                json_add "game" "$game"
                json_add "compression" "$compatible_compression_format"
                # Build the complete JSON object for this game
                json_obj=$(json_build)
                # Write the final JSON object to the output file, locking it to prevent write race conditions.
                (
                flock -x 200
                jq --argjson obj "$json_obj" '. + [$obj]' "$output_file" > "$output_file.tmp" && mv "$output_file.tmp" "$output_file"
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

  final_json=$(cat "$output_file")

  echo "$final_json"
}

api_find_all_components() {
  # This function will return an array of JSON objects with the names, user-friendly names and descriptions of every installed component.
  # USAGE: api_find_all_components

  # Initialize the empty JSON file meant for final output
  all_components_obj="$(mktemp)"
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
            system_name: $system_key,
            data: {
              system_friendly_name: $sys.name,
              description: $sys.description
            }
          }
      ' "$manifest_file")
      local system_name=$(echo "$json_info" | jq -r '.system_name' )
      local system_friendly_name=$(echo "$json_info" | jq -r '.data.system_friendly_name')
      local description=$(echo "$json_info" | jq -r '.data.description')
      json_obj=$(jq -n --arg name "$system_name" --arg friendly_name "$system_friendly_name" --arg desc "$description" \
                '{ system_name: $name, system_friendly_name: $friendly_name, description: $desc }')
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
