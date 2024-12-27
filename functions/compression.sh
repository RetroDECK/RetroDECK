#!/bin/bash

compress_game() {
  # Function for compressing one or more files to .chd format
  # USAGE: compress_game $format $full_path_to_input_file $system(optional)
  local file="$2"
  local filename_no_path=$(basename "$file")
  local filename_no_extension="${filename_no_path%.*}"
  local filename_extension="${filename_no_path##*.}"
  local source_file=$(dirname "$(realpath "$file")")"/"$(basename "$file")
  local dest_file=$(dirname "$(realpath "$file")")"/""$filename_no_extension"

  if [[ "$1" == "chd" ]]; then
    case "$3" in # Check platform-specific compression options
    "psp" )
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
  elif [[ "$1" == "zip" ]]; then
    zip -jq9 "$dest_file".zip "$source_file"
  elif [[ "$1" == "rvz" ]]; then
    dolphin-tool convert -f rvz -b 131072 -c zstd -l 5 -i "$source_file" -o "$dest_file.rvz"
  fi

  if [[ $post_compression_cleanup == "true" ]]; then # Remove file(s) if requested
    if [[ -f "${file%.*}.$1" ]]; then
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
      log i "Compressed file ${file%.*}.$1 not found, skipping original file deletion"
    fi
  fi
}

find_compatible_compression_format() {
  # This function will determine what compression format, if any, the file and system are compatible with
  # USAGE: find_compatible_compression_format "$file"
  local normalized_filename=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  local system=$(echo "$1" | grep -oE "$roms_folder/[^/]+" | grep -oE "[^/]+$")

  # Extract the relevant lists from the JSON file
  local chd_systems=$(jq -r '.compression_targets.chd[]' $features)
  local rvz_systems=$(jq -r '.compression_targets.rvz[]' $features)
  local zip_systems=$(jq -r '.compression_targets.zip[]' $features)
  local zip_compressable_extensions=$(jq -r '.zip_compressable_extensions[]' $features)

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
  # The function takes the following arguments, which alter what files are compressed:
  # "everything" - Compresses all games found into their compatible formats
  # "all" - Compresses a list of user-chosen files into their compatible formats
  # "chd" or "zip" or "rvz" - Compresses a list of user-chosen files into the given format

  if [[ -f "$godot_compression_compatible_games" ]]; then
    rm -f "$godot_compression_compatible_games" # Godot data transfer temp files
  fi
  touch "$godot_compression_compatible_games"

  compressable_games_list=()
  all_compressable_games=()
  games_to_compress=()
  target_selection="$1"

  if [[ "$1" == "everything" ]]; then
    local compression_format="all"
  else
    local compression_format="$1"
  fi

  if [[ $compression_format == "all" ]]; then
    local compressable_systems_list=$(cat $compression_targets | sed '/^$/d' | sed '/^\[/d')
  else
    local compressable_systems_list=$(sed -n '/\['"$compression_format"'\]/, /\[/{ /\['"$compression_format"'\]/! { /\[/! p } }' $compression_targets | sed '/^$/d')
  fi

  while IFS= read -r system # Find and validate all games that are able to be compressed with this compression type
  do
    compression_candidates=$(find "$roms_folder/$system" -type f -not -iname "*.txt")
    if [[ ! -z $compression_candidates ]]; then
      while IFS= read -r game
      do
        local compatible_compression_format=$(find_compatible_compression_format "$game")
        if [[ $compression_format == "chd" ]]; then
          if [[ $compatible_compression_format == "chd" && ! -f "$(echo ${game%.*}.chd)" ]]; then
            all_compressable_games=("${all_compressable_games[@]}" "$game")
            compressable_games_list=("${compressable_games_list[@]}" "false" "${game#$roms_folder}" "$game")
            echo "${game}"^"$compatible_compression_format" >> "$godot_compression_compatible_games"
          fi
        elif [[ $compression_format == "zip" ]]; then
          if [[ $compatible_compression_format == "zip" && ! -f "$(echo ${game%.*}.zip)" ]]; then
            all_compressable_games=("${all_compressable_games[@]}" "$game")
            compressable_games_list=("${compressable_games_list[@]}" "false" "${game#$roms_folder}" "$game")
            echo "${game}"^"$compatible_compression_format" >> "$godot_compression_compatible_games"
          fi
        elif [[ $compression_format == "rvz" ]]; then
          if [[ $compatible_compression_format == "rvz" && ! -f "$(echo ${game%.*}.rvz)" ]]; then
            all_compressable_games=("${all_compressable_games[@]}" "$game")
            compressable_games_list=("${compressable_games_list[@]}" "false" "${game#$roms_folder}" "$game")
            echo "${game}"^"$compatible_compression_format" >> "$godot_compression_compatible_games"
          fi
        elif [[ $compression_format == "all" ]]; then
          if [[ ! $compatible_compression_format == "none" ]]; then
            all_compressable_games=("${all_compressable_games[@]}" "$game")
            compressable_games_list=("${compressable_games_list[@]}" "false" "${game#$roms_folder}" "$game")
            echo "${game}"^"$compatible_compression_format" >> "$godot_compression_compatible_games"
          fi
        fi
      done < <(printf '%s\n' "$compression_candidates")
    fi
  done < <(printf '%s\n' "$compressable_systems_list")
}

cli_compress_single_game() {
	# This function will compress a single file passed from the CLI arguments
  # USAGE: cli_compress_single_game $full_file_path
  local file=$(realpath "$1")
  read -p "Do you want to have the original file removed after compression is complete? Please answer y/n and press Enter: " post_compression_cleanup
  read -p "RetroDECK will now attempt to compress your selected game. Press Enter key to continue..."
	if [[ ! -z "$file" ]]; then
		if [[ -f "$file" ]]; then
      local system=$(echo "$file" | grep -oE "$roms_folder/[^/]+" | grep -oE "[^/]+$")
      local compatible_compression_format=$(find_compatible_compression_format "$file")
      if [[ ! $compatible_compression_format == "none" ]]; then
        log i "$(basename "$file") can be compressed to $compatible_compression_format"
        compress_game "$compatible_compression_format" "$file" "$system"
      else
        log w "$(basename "$file") does not have any compatible compression formats."
      fi
		else
			log w "File not found, please specify the full path to the file to be compressed."
		fi
	else
		log i "Please use this command format \"--compress-one <path to file to compress>\""
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
    local compressable_systems_list=$(cat $compression_targets | sed '/^$/d' | sed '/^\[/d')
  else
    local compressable_systems_list=$(sed -n '/\['"$compression_format"'\]/, /\[/{ /\['"$compression_format"'\]/! { /\[/! p } }' $compression_targets | sed '/^$/d')
  fi

  read -p "Do you want to have the original files removed after compression is complete? Please answer y/n and press Enter: " post_compression_cleanup
  read -p "RetroDECK will now attempt to compress all compatible games. Press Enter key to continue..."

  while IFS= read -r system # Find and validate all games that are able to be compressed with this compression type
  do
    local compression_candidates=$(find "$roms_folder/$system" -type f -not -iname "*.txt")
    if [[ ! -z "$compression_candidates" ]]; then
      log i "Checking files for $system"
      while IFS= read -r file
      do
        local compatible_compression_format=$(find_compatible_compression_format "$file")
        if [[ ! "$compatible_compression_format" == "none" ]]; then
          log i "$(basename "$file") can be compressed to $compatible_compression_format"
          compress_game "$compatible_compression_format" "$file" "$system"
        else
          log w "No compatible compression format found for $(basename "$file")"
        fi
      done < <(printf '%s\n' "$compression_candidates")
    else
      log w "No compatible files found for compression in $system"
    fi
  done < <(printf '%s\n' "$compressable_systems_list")
}
