#!/bin/bash

compress_game() {
  # Function for compressing one or more files to .chd format
  # USAGE: compress_game $format $full_path_to_input_file
  local file="$2"
  local filename_no_path=$(basename "$file")
  local filename_no_extension="${filename_no_path%.*}"
  local source_file=$(dirname "$(realpath "$file")")"/"$(basename "$file")
  local dest_file=$(dirname "$(realpath "$file")")"/""$filename_no_extension"

  if [[ "$1" == "chd" ]]; then
    /app/bin/chdman createcd -i "$source_file" -o "$dest_file".chd
  elif [[ "$1" == "zip" ]]; then
    zip -jq9 "$dest_file".zip "$source_file"
  elif [[ "$1" == "rvz" ]]; then
    dolphin-tool convert -f rvz -b 131072 -c zstd -l 5 -i "$source_file" -o "$dest_file.rvz"
  fi
}

find_compatible_compression_format() {
  # This function will determine what compression format, if any, the file and system are compatible with
  # USAGE: find_compatible_compression_format "$file"
  local normalized_filename=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  local system=$(echo "$1" | grep -oE "$roms_folder/[^/]+" | grep -oE "[^/]+$")

	if [[ $(validate_for_chd "$1") == "true" ]] && [[ $(sed -n '/^\[/{h;d};/\b'"$system"'\b/{g;s/\[\(.*\)\]/\1/p;q};' $compression_targets) == "chd" ]]; then
    echo "chd"
  elif grep -qF ".${normalized_filename##*.}" $zip_compressable_extensions && [[ $(sed -n '/^\[/{h;d};/\b'"$system"'\b/{g;s/\[\(.*\)\]/\1/p;q};' $compression_targets) == "zip" ]]; then
    echo "zip"
  elif echo "$normalized_filename" | grep -qE '\.iso|\.gcm' && [[ $(sed -n '/^\[/{h;d};/\b'"$system"'\b/{g;s/\[\(.*\)\]/\1/p;q};' $compression_targets) == "rvz" ]]; then
    echo "rvz"
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
	chd_validation_log_file="compression_$(basename "$file").log"
	echo "Validating file:" "$file" > "$logs_folder/$chd_validation_log_file"
	if echo "$normalized_filename" | grep -qE '\.iso|\.cue|\.gdi'; then
		echo ".cue/.iso/.gdi file detected" >> "$logs_folder/$chd_validation_log_file"
		local file_path=$(dirname "$(realpath "$file")")
		local file_base_name=$(basename "$file")
		local file_name=${file_base_name%.*}
		if [[ "$normalized_filename" == *".cue" ]]; then # Validate .cue file
			if [[ ! "$file_path" == *"dreamcast"* ]]; then # .bin/.cue compression may not work for Dreamcast, only GDI or ISO # TODO: verify
        echo "Validating .cue associated .bin files" >> "$logs_folder/$chd_validation_log_file"
        local cue_bin_files=$(grep -o -P "(?<=FILE \").*(?=\".*$)" "$file")
        echo "Associated bin files read:" >> "$logs_folder/$chd_validation_log_file"
        printf '%s\n' "$cue_bin_files" >> "$logs_folder/$chd_validation_log_file"
        if [[ ! -z "$cue_bin_files" ]]; then
          while IFS= read -r line
          do
            echo "looking for $file_path/$line" >> "$logs_folder/$chd_validation_log_file"
            if [[ -f "$file_path/$line" ]]; then
              echo ".bin file found at $file_path/$line" >> "$logs_folder/$chd_validation_log_file"
              file_validated="true"
            else
              echo ".bin file NOT found at $file_path/$line" >> "$logs_folder/$chd_validation_log_file"
              echo ".cue file could not be validated. Please verify your .cue file contains the correct corresponding .bin file information and retry." >> "$logs_folder/$chd_validation_log_file"
              file_validated="false"
              break
            fi
          done < <(printf '%s\n' "$cue_bin_files")
        fi
      else
        echo ".cue files not compatible with Dreamcast CHD compression" >> "$logs_folder/$chd_validation_log_file"
      fi
      echo $file_validated
		else # If file is a .iso or .gdi
      file_validated="true"
			echo $file_validated
		fi
	else
		echo "File type not recognized. Supported file types are .cue, .gdi and .iso" >> "$logs_folder/$chd_validation_log_file"
		echo $file_validated
	fi
}

cli_compress_single_game() {
	# This function will compress a single file passed from the CLI arguments
  # USAGE: cli_compress_single_game $full_file_path
  local file=$(realpath "$1")
  read -p "Do you want to have the original file removed after compression is complete? Please answer y/n and press Enter: " post_compression_cleanup
  read -p "RetroDECK will now attempt to compress your selected game. Press Enter key to continue..."
	if [[ ! -z "$file" ]]; then
		if [[ -f "$file" ]]; then
      check_system=$(echo "$file" | grep -oE "$roms_folder/[^/]+" | grep -oE "[^/]+$")
      local compatible_compression_format=$(find_compatible_compression_format "$file")
      if [[ ! $compatible_compression_format == "none" ]]; then
        echo "$(basename "$file") can be compressed to $compatible_compression_format"
        compress_game "$compatible_compression_format" "$file"
        if [[ $post_compression_cleanup == [yY] ]]; then # Remove file(s) if requested
          if [[ $(basename "$file") == *".cue" ]]; then
            local cue_bin_files=$(grep -o -P "(?<=FILE \").*(?=\".*$)" "$file")
            local file_path=$(dirname "$(realpath "$file")")
            while IFS= read -r line
            do # Remove associated .bin files
              echo "Removing original file "$file_path/$line""
              rm -f "$file_path/$line"
            done < <(printf '%s\n' "$cue_bin_files") # Remove original .cue file
            echo "Removing original file $(basename "$file")"
            rm -f "$file"
          else
            echo "Removing original file $(basename "$file")"
            rm -f "$file"
          fi
        fi
      else
        echo "$(basename "$file") does not have any compatible compression formats."
      fi
		else
			echo "File not found, please specify the full path to the file to be compressed."
		fi
	else
		echo "Please use this command format \"--compress-one <path to file to compress>\""
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
      echo "Checking files for $system"
      while IFS= read -r file
      do
        local compatible_compression_format=$(find_compatible_compression_format "$file")
        if [[ ! "$compatible_compression_format" == "none" ]]; then
          echo "$(basename "$file") can be compressed to $compatible_compression_format"
          compress_game "$compatible_compression_format" "$file"
          if [[ $post_compression_cleanup == [yY] ]]; then # Remove file(s) if requested
            if [[ "$file" == *".cue" ]]; then
              local cue_bin_files=$(grep -o -P "(?<=FILE \").*(?=\".*$)" "$file")
              local file_path=$(dirname "$(realpath "$file")")
              while IFS= read -r line
              do # Remove associated .bin files
                echo "Removing original file "$file_path/$line""
                rm -f "$file_path/$line"
              done < <(printf '%s\n' "$cue_bin_files") # Remove original .cue file
              echo "Removing original file "$file""
              rm -f $(realpath "$file")
            else
              echo "Removing original file "$file""
              rm -f $(realpath "$file")
            fi
          fi
        else
          echo "No compatible compression format found for $(basename "$file")"
        fi
      done < <(printf '%s\n' "$compression_candidates")
    else
      echo "No compatible files found for compression in $system"
    fi
  done < <(printf '%s\n' "$compressable_systems_list")
}
