#!/bin/bash

compress_game() {
  # Function for compressing one or more files to .chd format
  # USAGE: compress_game $format $full_path_to_input_file $cleanup_choice $system(optional)
  local format="$1"
  local file="$2"
  local post_compression_cleanup="$3"
  local system="$4"
  local filename_no_path=$(basename "$file")
  local filename_no_extension="${filename_no_path%.*}"
  local filename_extension="${filename_no_path##*.}"
  local source_file=$(dirname "$(realpath "$file")")"/""$(basename "$file")"
  local dest_file=$(dirname "$(realpath "$file")")"/""$filename_no_extension"

  if [[ "$format" == "chd" ]]; then
    case "$system" in # Check platform-specific compression options
    "psp" )
      log d "Compressing PSP game $source_file into $dest_file"
      /app/bin/chdman createdvd --hunksize 2048 -i "$source_file" -o "$dest_file".chd -c zstd
    ;;
    "ps2" )
      if [[ "$filename_extension" == "cue" ]]; then
        /app/bin/chdman createcd -i "$source_file" -o "$dest_file".chd
      else
        /app/bin/chdman createdvd -i "$source_file" -o "$dest_file".chd -c zstd
      fi
    ;;
    * )
      /app/bin/chdman createcd -i "$source_file" -o "$dest_file".chd
    ;;
    esac
  elif [[ "$format" == "zip" ]]; then
    zip -jq9 "$dest_file".zip "$source_file"
  elif [[ "$format" == "rvz" ]]; then
    dolphin-tool convert -f rvz -b 131072 -c zstd -l 5 -i "$source_file" -o "$dest_file.rvz"
  fi

  if [[ "$post_compression_cleanup" == "true" ]]; then # Remove file(s) if requested
    if [[ -f "${file%.*}.$format" ]]; then
      log i "Performing post-compression file cleanup"
      if [[ "$file" == *".cue" ]]; then
        local cue_bin_files=$(grep -o -P "(?<=FILE \").*(?=\".*$)" "$file")
        local file_path=$(dirname "$(realpath "$file")")
        while IFS= read -r line
        do
          log i "Removing file $file_path/$line"
          rm -f "$file_path/$line"
        done < <(printf '%s\n' "$cue_bin_files")
        log i "Removing file $(realpath "$file")"
        rm -f "$(realpath "$file")"
      else
        log i "Removing file $(realpath "$file")"
        rm -f "$(realpath "$file")"
      fi
    else
      log i "Compressed file ${file%.*}.$format not found, skipping original file deletion"
    fi
  fi
}

find_compatible_compression_format() {
  # This function will determine what compression format, if any, the file and system are compatible with
  # USAGE: find_compatible_compression_format "$file"
  local normalized_filename=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  local system=$(echo "$1" | grep -oE "$roms_path/[^/]+" | grep -oE "[^/]+$")

  # Extract the relevant lists from the JSON file
  local chd_systems=$(jq -r '.compression_targets.chd[]' "$features")
  local rvz_systems=$(jq -r '.compression_targets.rvz[]' "$features")
  local zip_systems=$(jq -r '.compression_targets.zip[]' "$features")
  local zip_compressable_extensions=$(jq -r '.zip_compressable_extensions[]' "$features")

  if [[ $(validate_for_chd "$1") == "true" ]] && echo "$chd_systems" | grep -q "\b$system\b"; then
    echo "chd"
  elif echo "$zip_compressable_extensions" | grep -qF ".${normalized_filename##*.}" && echo "$zip_systems" | grep -q "\b$system\b"; then
    echo "zip"
  elif echo "$normalized_filename" | grep -qE '\.iso|\.gcm' && echo "$rvz_systems" | grep -q "\b$system\b"; then
    echo "rvz"
  elif echo "$normalized_filename" | grep -qE '\.iso' && echo "$chd_systems" | grep -q "\b$system\b"; then
    echo "cso"
  else
    # If no compatible format can be found for the input file
    echo "none"
  fi
}


validate_for_chd() {
  # Function for validating chd compression candidates, and compresses if validation passes. Supports .cue, .iso and .gdi formats ONLY
  # USAGE: validate_for_chd $input_file

	local file="$1"
	local normalized_filename=$(echo "$file" | tr '[:upper:]' '[:lower:]')
  local file_validated="false"
	log i "Validating file: $file"
	if echo "$normalized_filename" | grep -qE '\.iso|\.cue|\.gdi'; then
		log i ".cue/.iso/.gdi file detected"
		local file_path=$(dirname "$(realpath "$file")")
		local file_base_name=$(basename "$file")
		local file_name=${file_base_name%.*}
		if [[ "$normalized_filename" == *".cue" ]]; then # Validate .cue file
			if [[ ! "$file_path" == *"dreamcast"* ]]; then # .bin/.cue compression may not work for Dreamcast, only GDI or ISO # TODO: verify
        log i "Validating .cue associated .bin files"
        local cue_bin_files=$(grep -o -P "(?<=FILE \").*(?=\".*$)" "$file")
        log i "Associated bin files read:"
        log i "$(printf '%s\n' "$cue_bin_files")"
        if [[ ! -z "$cue_bin_files" ]]; then
          while IFS= read -r line
          do
            log i "Looking for $file_path/$line"
            if [[ -f "$file_path/$line" ]]; then
              log i ".bin file found at $file_path/$line"
              file_validated="true"
            else
              log e ".bin file NOT found at $file_path/$line"
              log e ".cue file could not be validated. Please verify your .cue file contains the correct corresponding .bin file information and retry."
              file_validated="false"
              break
            fi
          done < <(printf '%s\n' "$cue_bin_files")
        fi
      else
        log w ".cue files not compatible with CHD compression"
      fi
      echo $file_validated
		else # If file is a .iso or .gdi
      file_validated="true"
			echo $file_validated
		fi
	else
		log w "File type not recognized. Supported file types are .cue, .gdi and .iso"
		echo $file_validated
	fi
}

find_compatible_games() {
  # Supported parameters:
  # "everything"  - All games found (regardless of format)
  # "all"         - Only user-chosen games (later selected via checklist)
  # "chd", "zip", "rvz" - Only games matching that compression type

  log d "Started find_compatible_games with parameter: $1"
  local output_file="${godot_compression_compatible_games}"
  [ -f "$output_file" ] && rm -f "$output_file"
  touch "$output_file"

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

  while IFS= read -r system; do
    while (( $(jobs -p | wc -l) >= $system_cpu_max_threads )); do # Wait for a background task to finish if system_cpu_max_threads has been hit
      sleep 0.1
    done
    (
    log d "Checking system: $system"
    if [[ -d "$roms_path/$system" ]]; then
      local compression_candidates
      compression_candidates=$(find "$roms_path/$system" -type f -not -iname "*.txt")
      if [[ -n "$compression_candidates" ]]; then
        while IFS= read -r game; do
          while (( $(jobs -p | wc -l) >= $system_cpu_max_threads )); do # Wait for a background task to finish if system_cpu_max_threads has been hit
            sleep 0.1
          done
          (
          log d "Checking game: $game"
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
                (
                flock -x 200
                echo "${game}^chd" >> "$output_file"
                ) 200>"$rd_file_lock"
              fi
              ;;
            "zip")
              if [[ "$compatible_compression_format" == "zip" ]]; then
                log d "Game $game is compatible with ZIP compression"
                (
                flock -x 200
                echo "${game}^zip" >> "$output_file"
                ) 200>"$rd_file_lock"
              fi
              ;;
            "rvz")
              if [[ "$compatible_compression_format" == "rvz" ]]; then
                log d "Game $game is compatible with RVZ compression"
                (
                flock -x 200
                echo "${game}^rvz" >> "$output_file"
                ) 200>"$rd_file_lock"
              fi
              ;;
            "all")
              if [[ "$compatible_compression_format" != "none" ]]; then
                log d "Game $game is compatible with $compatible_compression_format compression"
                (
                flock -x 200
                echo "${game}^${compatible_compression_format}" >> "$output_file"
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

  log d "Compatible games have been written to $output_file"
  cat "$output_file"
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
        local system=$(echo "$file" | grep -oE "$roms_path/[^/]+" | grep -oE "[^/]+$")
        local compatible_compression_format=$(find_compatible_compression_format "$file")
        if [[ ! $compatible_compression_format == "none" ]]; then
          log i "$(basename "$file") can be compressed to $compatible_compression_format"
          if [[ "$post_compression_cleanup" == "y" ]]; then
            post_compression_cleanup="true"
          else
            post_compression_cleanup="false"
          fi
          compress_game "$compatible_compression_format" "$file" "$post_compression_cleanup" "$system"
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
            compress_game "$compatible_compression_format" "$file" "$post_compression_cleanup" "$system"
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
