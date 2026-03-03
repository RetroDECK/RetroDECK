#!/bin/bash

# Component-compression-related variables
declare -A _compression_system_format
declare -A _compression_ext_restrictions
declare -A _compression_allowed_extensions

get_all_compression_targets() {
  # Gather all compression target information from component manifests.
  # Returns a JSON object keyed by format with target_systems and optional compressable_extensions.
  # USAGE: get_all_compression_targets

  get_component_manifest_cache | jq '
    reduce (.[] | .manifest | .. | objects | select(has("compression")) | .compression | to_entries[]) as $entry (
      {};
      .[$entry.key] = {
        target_systems: ((.[$entry.key].target_systems // []) + ($entry.value.target_systems // []) | unique)
      }
      | if $entry.value.compressable_extensions then
          .[$entry.key].compressable_extensions = ((.[$entry.key].compressable_extensions // []) + $entry.value.compressable_extensions | unique)
        else . end
    )
  '
}

build_compression_lookups() {
  # Build associative array lookups from compression target data for fast per-file matching.
  # Should be called once during application startup, after component functions are sourced.
  # USAGE: build_compression_lookups

  local compression_targets
  compression_targets=$(get_all_compression_targets)

  _compression_system_format=()
  _compression_ext_restrictions=()
  _compression_allowed_extensions=()

  # Build system -> format lookup
  while IFS=$'\t' read -r format system; do
    _compression_system_format["$system"]="$format"
  done < <(jq -r '
    to_entries[] | .key as $fmt |
    .value.target_systems[] |
    [$fmt, .] | @tsv
  ' <<< "$compression_targets")

  # Build extension restriction flags and allowed extensions per format
  while IFS=$'\t' read -r format extension; do
    _compression_ext_restrictions["$format"]=1
    _compression_allowed_extensions["${format}:${extension}"]=1
  done < <(jq -r '
    to_entries[]
    | select(.value.compressable_extensions)
    | .key as $fmt
    | .value.compressable_extensions[]
    | [$fmt, .] | @tsv
  ' <<< "$compression_targets")
}

find_compatible_compression_format() {
  # Determine what compression format, if any, a file and its system are compatible with.
  # Requires build_compression_lookups to have been called.
  # Returns the format name or "none".
  # USAGE: find_compatible_compression_format "$file"

  local file="$1"
  local normalized_filename=$(echo "$file" | tr '[:upper:]' '[:lower:]')
  local file_extension=".${normalized_filename##*.}"
  local system=$(echo "$file" | grep -oE "$roms_path/[^/]+" | grep -oE "[^/]+$")

  # Look up format for this system
  local format="${_compression_system_format[$system]:-}"
  if [[ -z "$format" ]]; then
    echo "none"
    return
  fi

  # Check extension restrictions if the format has them
  if [[ -n "${_compression_ext_restrictions[$format]+x}" ]]; then
    if [[ -z "${_compression_allowed_extensions[${format}:${file_extension}]+x}" ]]; then
      echo "none"
      return
    fi
  fi

  # Run format-specific validation
  local validator="_validate_for_compression::${format}"
  if declare -F "$validator" > /dev/null; then
    if "$validator" "$file"; then
      echo "$format"
    else
      echo "none"
    fi
  else
    log e "No validation handler found for format: $format"
    echo "none"
  fi
}

compress_game() {
  # Compress a file to its compatible format and optionally clean up source files.
  # USAGE: compress_game "$format" "$full_path_to_input_file" "$cleanup_choice"

  local format="$1"
  local file="$2"
  local post_compression_cleanup="$3"
  local filename_no_extension="${file%.*}"
  local source_file=$(dirname "$(realpath "$file")")"/"$(basename "$file")
  local dest_file=$(dirname "$(realpath "$file")")"/${filename_no_extension##*/}"
  local system=$(echo "$file" | grep -oE "$roms_path/[^/]+" | grep -oE "[^/]+$")

  local handler="_compress_game::${format}"
  if ! declare -F "$handler" > /dev/null; then
    log e "No compression handler found for format: $format"
    return 1
  fi

  "$handler" "$source_file" "$dest_file" "$system"

  if [[ "$post_compression_cleanup" == "true" && -f "${file%.*}.$format" ]]; then
    log i "Performing post-compression file cleanup"
    if [[ "$file" == *".cue" ]]; then
      local file_path=$(dirname "$(realpath "$file")")
      while IFS= read -r bin_file; do
        log i "Removing file $file_path/$bin_file"
        rm -f "$file_path/$bin_file"
      done < <(grep -o -P '(?<=FILE ").*(?=".*$)' "$file")
    fi
    log i "Removing file $(realpath "$file")"
    rm -f "$(realpath "$file")"
  elif [[ "$post_compression_cleanup" == "true" ]]; then
    log i "Compressed file ${file%.*}.$format not found, skipping original file deletion"
  fi
}

cli_compress_single_game() {
	# This function will compress a single file passed from the CLI arguments
  # USAGE: cli_compress_single_game $full_file_path
  local file=$(realpath "$1")
  read -p "Do you want to have the original file removed after compression is complete? Please answer y/n and press Enter: " post_compression_cleanup
  if [[ "$post_compression_cleanup" == "y" || "$post_compression_cleanup" == "n" ]]; then
    read -p "RetroDECK will now attempt to compress your selected game. Press Enter key to continue..."
    if [[ ! -z "$file" ]]; then
      if [[ -f "$file" ]]; then
        local compatible_compression_format=$(find_compatible_compression_format "$file")
        if [[ ! $compatible_compression_format == "none" ]]; then
          log i "$(basename "$file") can be compressed to $compatible_compression_format"
          if [[ "$post_compression_cleanup" == "y" ]]; then
            post_compression_cleanup="true"
          else
            post_compression_cleanup="false"
          fi
          compress_game "$compatible_compression_format" "$file" "$post_compression_cleanup"
        else
          log w "$(basename "$file") does not have any compatible compression formats."
        fi
      else
        log w "File not found, please specify the full path to the file to be compressed."
      fi
    else
      log i "Please use this command format \"--compress-one <path to file to compress>\""
    fi
  else
    log i "The response for post-compression file cleanup was not correct. Please try again."
  fi
}

cli_compress_all_games() {
  if echo "$1" | grep -qE 'chd|rvz|zip'; then
    local compression_format="$1"
  elif [[ "$1" == "all" ]]; then
    local compression_format="all"
  else
    echo "Please enter a supported compression format. Options are \"chd\", \"rvz\", \"zip\" or \"all\""
    exit 1
  fi
  local compressable_game=""
  local all_compressable_games=()
  if [[ $compression_format == "all" ]]; then
    local compressible_systems_list=$(jq -r '.compression_targets | to_entries[] | .value[]' "$features")
  else
    local compressible_systems_list=$(jq -r '.compression_targets["'"$compression_format"'"][]' "$features")
  fi

  read -p "Do you want to have the original files removed after compression is complete? Please answer y/n and press Enter: " post_compression_cleanup
  if [[ "$post_compression_cleanup" == "y" || "$post_compression_cleanup" == "n" ]]; then
    read -p "RetroDECK will now attempt to compress all compatible games. Press Enter key to continue..."
    if [[ "$post_compression_cleanup" == "y" ]]; then
      post_compression_cleanup="true"
    else
      post_compression_cleanup="false"
    fi

    while IFS= read -r system # Find and validate all games that are able to be compressed with this compression type
    do
      while (( $(jobs -p | wc -l) >= $system_cpu_max_threads )); do # Wait for a background task to finish if system_cpu_max_threads has been hit
      sleep 0.1
      done
      (
      local compression_candidates=$(find "$roms_path/$system" -type f -not -iname "*.txt")
      if [[ ! -z "$compression_candidates" ]]; then
        log i "Checking files for $system"
        while IFS= read -r file
        do
          while (( $(jobs -p | wc -l) >= $system_cpu_max_threads )); do # Wait for a background task to finish if system_cpu_max_threads has been hit
            sleep 0.1
          done
          (
          local compatible_compression_format=$(find_compatible_compression_format "$file")
          if [[ ! "$compatible_compression_format" == "none" ]]; then
            log i "$(basename "$file") can be compressed to $compatible_compression_format"
            compress_game "$compatible_compression_format" "$file" "$post_compression_cleanup"
          else
            log w "No compatible compression format found for $(basename "$file")"
          fi
          ) &
        done < <(printf '%s\n' "$compression_candidates")
        wait # wait for background tasks to finish
      else
        log w "No compatible files found for compression in $system"
      fi
      ) &
    done < <(printf '%s\n' "$compressible_systems_list")
    wait # wait for background tasks to finish
  else
    log i "The response for post-compression file cleanup was not correct. Please try again."
  fi
}
