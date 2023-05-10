#!/bin/bash

# THIS IS A CENTRALIZED LOCATION FOR FUNCTIONS, WHICH CAN BE SOURCED WITHOUT RUNNING EXTRA CODE. EXISTING USE OF THESE FUNCTIONS CAN BE REFACTORED TO HERE.

# These functions are original to this file

#=================
# FUNCTION SECTION
#=================

directory_browse() {
  # This function browses for a directory and returns the path chosen
  # USAGE: path_to_be_browsed_for=$(directory_browse $action_text)

  local path_selected=false

  while [ $path_selected == false ]
  do
    local target="$(zenity --file-selection --title="Choose $1" --directory)"
    if [ ! -z $target ] #yes
    then
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
      --text="Directory $target chosen, is this correct?"
      if [ $? == 0 ]
      then
        path_selected=true
        echo $target
        break
      fi
    else
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
      --text="No directory selected. Do you want to exit the selection process?"
      if [ $? == 0 ]
      then
        break
      fi
    fi
  done
}

file_browse() {
  # This function browses for a file and returns the path chosen
  # USAGE: file_to_be_browsed_for=$(file_browse $action_text)

  local file_selected=false

  while [ $file_selected == false ]
  do
    local target="$(zenity --file-selection --title="Choose $1")"
    if [ ! -z "$target" ] #yes
    then
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
      --text="File $target chosen, is this correct?"
      if [ $? == 0 ]
      then
        file_selected=true
        echo "$target"
        break
      fi
    else
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
      --text="No file selected. Do you want to exit the selection process?"
      if [ $? == 0 ]
      then
        break
      fi
    fi
  done
}

verify_space() {
  # Function used for verifying adequate space before moving directories around
  # USAGE: verify_space $source_dir $dest_dir
  # Function returns "true" if there is enough space, "false" if there is not

  source_size=$(du -sk "$1" | awk '{print $1}')
  source_size=$((source_size+(source_size/10))) # Add 10% to source size for safety
  dest_avail=$(df -k --output=avail "$2" | tail -1)

  if [[ $source_size -ge $dest_avail ]]; then
    echo "false"
  else
    echo "true"
  fi
}

move() {
  # Function to move a directory from one parent to another
  # USAGE: move $source_dir $dest_dir

  source_dir="$(echo $1 | sed 's![^/]$!&/!')" # Add trailing slash if it is missing
  dest_dir="$(echo $2 | sed 's![^/]$!&/!')" # Add trailing slash if it is missing

  (
    rsync -a --remove-source-files --ignore-existing --mkpath "$source_dir" "$dest_dir" # Copy files but don't overwrite conflicts
    find "$source_dir" -type d -empty -delete # Cleanup empty folders that were left behind
  ) |
  zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - Move in Progress" \
  --text="Moving directory $(basename "$1") to new location of $2, please wait."

  if [[ -d "$source_dir" ]]; then # Some conflicting files remain
    zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility - Move Directories" \
    --text="There were some conflicting files that were not moved.\n\nAll files that could be moved are in the new location,\nany files that already existed at the new location have not been moved and will need to be handled manually."
  fi
}

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

desktop_mode_warning() {
  # This function is a generic warning for issues that happen when running in desktop mode.
  # Running in desktop mode can be verified with the following command: if [[ ! $XDG_CURRENT_DESKTOP == "gamescope" ]]; then
  # This function will check if desktop mode is currently being used and if the warning has not been disabled, and show it if needed.
  # USAGE: desktop_mode_warning

  if [[ ! $XDG_CURRENT_DESKTOP == "gamescope" ]]; then
    if [[ $desktop_mode_warning == "true" ]]; then
      choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Never show this again" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Desktop Mode Warning" \
      --text="You appear to be running RetroDECK in the Steam Deck's Desktop mode!\n\nSome functions of RetroDECK may not work properly in Desktop mode, such as the Steam Deck's normal controls.\n\nRetroDECK is best enjoyed in Game mode!\n\nDo you still want to proceed?")
      rc=$? # Capture return code, as "Yes" button has no text value
      if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
        if [[ $choice == "No" ]]; then
          exit 1
        elif [[ $choice == "Never show this again" ]]; then
          set_setting_value $rd_conf "desktop_mode_warning" "false" retrodeck "options" # Store desktop mode warning variable for future checks
        fi
      fi
    fi
  fi
}

low_space_warning() {
  # This function will verify that the drive with the $HOME path on it has at least 10% space free, so the user can be warned before it fills up
  # USAGE: low_space_warning

  if [[ $low_space_warning == "true" ]]; then
    local used_percent=$(df --output=pcent "$HOME" | tail -1 | tr -d " " | tr -d "%")
    if [[ "$used_percent" -ge 90 && -d "$HOME/retrodeck" ]]; then # If there is any RetroDECK data on the main drive to move
      choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK" --extra-button="Never show this again" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Low Space Warning" \
      --text="Your main drive is over 90% full!\n\nIf your drive fills completely this can lead to data loss or system crash.\n\nPlease consider moving some RetroDECK folders to other storage locations using the Configurator.")
      if [[ $choice == "Never show this again" ]]; then
          set_setting_value $rd_conf "low_space_warning" "false" retrodeck "options" # Store low space warning variable for future checks
      fi
    fi
  fi
}

set_setting_value() {
  # Function for editing settings
  # USAGE: set_setting_value $setting_file "$setting_name" "$new_setting_value" $system $section_name(optional)

  local setting_name_to_change=$(sed -e 's^\\^\\\\^g;s^`^\\`^g' <<< "$2")
  local setting_value_to_change=$(sed -e 's^\\^\\\\^g;s^`^\\`^g' <<< "$3")
  local current_section_name=$(sed -e 's/%/\\%/g' <<< "$5")

  case $4 in

    "retrodeck" | "citra" | "melonds" | "yuzu" )
      if [[ -z $current_section_name ]]; then
        sed -i 's^\^'"$setting_name_to_change"'=.*^'"$setting_name_to_change"'='"$setting_value_to_change"'^' $1
      else
        sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"'=^s^\^'"$setting_name_to_change"'=.*^'"$setting_name_to_change"'='"$setting_value_to_change"'^' $1
      fi
      if [[ "$4" == "retrodeck" && ("$current_section_name" == "" || "$current_section_name" == "paths" || "$current_section_name" == "options") ]]; then # If a RetroDECK setting is being changed, also write it to memory for immediate use
        eval "$setting_name_to_change=$setting_value_to_change"
      fi
      ;;

    "retroarch" )
      if [[ -z $current_section_name ]]; then
        sed -i 's^\^'"$setting_name_to_change"' = \".*\"^'"$setting_name_to_change"' = \"'"$setting_value_to_change"'\"^' $1
      else
        sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"' = ^s^\^'"$setting_name_to_change"' = \".*\"^'"$setting_name_to_change"' = \"'"$setting_value_to_change"'\"^' $1
      fi
      ;;

    "dolphin" | "duckstation" | "pcsx2" | "ppsspp" | "primehack" | "xemu" )
      if [[ -z $current_section_name ]]; then
        sed -i 's^\^'"$setting_name_to_change"' =.*^'"$setting_name_to_change"' = '"$setting_value_to_change"'^' $1
      else
        sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"' =^s^\^'"$setting_name_to_change"' =.*^'"$setting_name_to_change"' = '"$setting_value_to_change"'^' $1
      fi
      ;;

    "rpcs3" ) # This does not currently work for settings with a $ in them
      if [[ -z $current_section_name ]]; then
        sed -i 's^\^'"$setting_name_to_change"': .*^'"$setting_name_to_change"': '"$setting_value_to_change"'^' $1
      else
        sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"'.*^s^\^'"$setting_name_to_change"': .*^'"$setting_name_to_change"': '"$setting_value_to_change"'^' $1
      fi
      ;;

    "es_settings" )
      sed -i 's^'"$setting_name_to_change"'" value=".*"^'"$setting_name_to_change"'" value="'"$setting_value_to_change"'"^' $1
      ;;

  esac
}

get_setting_name() {
  # Function for getting the setting name from a full setting line from a config file
  # USAGE: get_setting_name "$current_setting_line" $system

  local current_setting_line="$1"

  case $2 in

  "es_settings" )
    echo ''"$current_setting_line"'' | grep -o -P '(?<=name\=\").*(?=\" value)'
    ;;

  "rpcs3" )
    echo "$current_setting_line" | grep -o -P "^\s*?.*?(?=\s?:\s?)" | sed -e 's/^[ \t]*//;s^\\ ^ ^g'
    ;;

  * )
    echo "$current_setting_line" | grep -o -P "^\s*?.*?(?=\s?=\s?)" | sed -e 's/^[ \t]*//;s^\\ ^ ^g;s^\\$^^'
    ;;

  esac
}

get_setting_value() {
# Function for getting the current value of a setting from a config file
# USAGE: get_setting_value $setting_file "$setting_name" $system $section (optional)

  local current_setting_name="$2"
  local current_section_name="$4"

  case $3 in

  "retrodeck" | "citra" | "melonds" | "yuzu" ) # For files with this syntax - setting_name=setting_value
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=^$current_setting_name=).*" $1)
    else
      sed -n '\^\['"$current_section_name"'\]^,\^\^'"$current_setting_name"'^{ \^\['"$current_section_name"'\]^! { \^\^'"$current_setting_name"'^ p } }' $1 | grep -o -P "(?<=^$current_setting_name=).*"
    fi
  ;;

  "retroarch" ) # For files with this syntax - setting_name = "setting_value"
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=^$current_setting_name = \").*(?=\")" $1)
    else
      sed -n '\^\['"$current_section_name"'\]^,\^\^'"$current_setting_name"'^{ \^\['"$current_section_name"'\]^! { \^\^'"$current_setting_name"'^ p } }' $1 | grep -o -P "(?<=^$current_setting_name = \").*(?=\")"
    fi
  ;;

  "dolphin" | "duckstation" | "pcsx2" | "ppsspp" | "primehack" | "xemu" ) # For files with this syntax - setting_name = setting_value
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=^$current_setting_name = ).*" $1)
    else
      sed -n '\^\['"$current_section_name"'\]^,\^\^'"$current_setting_name"'^{ \^\['"$current_section_name"'\]^! { \^\^'"$current_setting_name"'^ p } }' $1 | grep -o -P "(?<=^$current_setting_name = ).*"
    fi
  ;;

  "rpcs3" ) # For files with this syntax - setting_name: setting_value
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=$current_setting_name: ).*" $1)
    else
      sed -n '\^\['"$current_section_name"'\]^,\^\^'"$current_setting_name"'^{ \^\['"$current_section_name"'\]^! { \^\^'"$current_setting_name"'^ p } }' $1 | grep -o -P "(?<=$current_setting_name: ).*"
    fi
  ;;

  "es_settings" )
    echo $(grep -o -P "(?<=$current_setting_name\" value=\").*(?=\")" $1)
  ;;

  esac
}

add_setting_line() {
  # This function will add a setting line to a file. This is useful for dynamically generated config files where a setting line may not exist until the setting is changed from the default.
  # USAGE: add_setting_line $setting_file $setting_line $system $section (optional)

  local current_setting_line=$(sed -e 's^\\^\\\\^g;s^`^\\`^g' <<< "$2")
  local current_section_name=$(sed -e 's/%/\\%/g' <<< "$4")

  case $3 in

  * )
    if [[ -z $current_section_name ]]; then
      if [[ -f "$1" ]]; then
        sed -i '$ a '"$current_setting_line"'' $1
      else # If the file doesn't exist, sed add doesn't work for the first line
        echo "$current_setting_line" > $1
      fi
    else
      sed -i '/^\s*?\['"$current_section_name"'\]|\b'"$current_section_name"':$/a '"$current_setting_line"'' $1
    fi
    ;;

  esac
}

add_setting() {
  # This function will add a setting name and value to a file. This is useful for dynamically generated config files like Retroarch override files.
  # USAGE: add_setting $setting_file $setting_name $setting_value $system $section (optional)

  local current_setting_name=$(sed -e 's^\\^\\\\^g;s^`^\\`^g' <<< "$2")
  local current_setting_value=$(sed -e 's^\\^\\\\^g;s^`^\\`^g' <<< "$3")
  local current_section_name=$(sed -e 's/%/\\%/g' <<< "$5")

  case $4 in

  "retroarch" )
    if [[ -z $current_section_name ]]; then
      sed -i '$ a '"$current_setting_name"' = "'"$current_setting_value"'"' $1
    else
      sed -i '/^\s*?\['"$current_section_name"'\]|\b'"$current_section_name"':$/a '"$current_setting_name"' = "'"$current_setting_value"'"' $1
    fi
    ;;

  esac
}

delete_setting() {
  # This function will delete a setting line from a file. This is useful for dynamically generated config files like Retroarch override files
  # USAGE: delete_setting $setting_file $setting_name $system $section (optional)

  local current_setting_name=$(sed -e 's^\\^\\\\^g;s^`^\\`^g' <<< "$2")
  local current_section_name=$(sed -e 's/%/\\%/g' <<< "$4")

  case $3 in

  "retroarch" )
    if [[ -z $current_section_name ]]; then
      sed -i '\^'"$current_setting_name"'^d' "$1"
      sed -i '/^$/d' "$1" # Cleanup empty lines left behind
    fi
    ;;

  esac
}

disable_setting() {
  # This function will add a '#' to the beginning of a defined setting line, disabling it.
  # USAGE: disable_setting $setting_file $setting_line $system $section (optional)

  local current_setting_line="$2"
  local current_section_name="$4"

  case $3 in

  * )
    if [[ -z $current_section_name ]]; then
      sed -i -E 's^(\s*?)'"$current_setting_line"'^\1#'"$current_setting_line"'^' $1
    else
      sed -i -E '\^\['"$current_section_name"'\]|\b'"$current_section_name"':$^,\^\s*?'"$current_setting_line"'^s^(\s*?)'"$current_setting_line"'^\1#'"$current_setting_line"'^' $1
    fi
  ;;

  esac
}

enable_setting() {
  # This function will remove a '#' to the beginning of a defined setting line, enabling it.
  # USAGE: enable_setting $setting_file $setting_line $system $section (optional)

  local current_setting_line="$2"
  local current_section_name="$4"

  case $3 in

  * )
    if [[ -z $current_section_name ]]; then
      sed -i -E 's^(\s*?)#'"$current_setting_line"'^\1'"$current_setting_line"'^' $1
    else
      sed -i -E '\^\['"$current_section_name"'\]|\b'"$current_section_name"':$^,\^\s*?#'"$current_setting_line"'^s^(\s*?)#'"$current_setting_line"'^\1'"$current_setting_line"'^' $1
    fi
  ;;

  esac
}

disable_file() {
  # This function adds the suffix ".disabled" to the end of a file to prevent it from being used entirely.
  # USAGE: disable_file $file_name
  # NOTE: $filename can be a defined variable from global.sh or must have the full path to the file

  mv $(realpath $1) $(realpath $1).disabled
}

enable_file() {
  # This function removes the suffix ".disabled" to the end of a file to allow it to be used.
  # USAGE: enable_file $file_name
  # NOTE: $filename can be a defined variable from global.sh or must have the full path to the file and should not have ".disabled" as a suffix

  mv $(realpath $1.disabled) $(realpath $(echo $1 | sed -e 's/\.disabled//'))
}

build_preset_config(){
  # This function will apply one or more presets for a given system, as listed in retrodeck.cfg
  # USAGE: build_preset_config "system name" "preset class 1" "preset class 2" "preset class 3"
  
  local system_being_changed="$1"
  shift
  local presets_being_changed="$*"
  for preset in $presets_being_changed
  do
    current_preset="$preset"
    local preset_section=$(sed -n '/\['"$current_preset"'\]/, /\[/{ /\['"$current_preset"'\]/! { /\[/! p } }' $rd_conf | sed '/^$/d')
    while IFS= read -r system_line
    do
      local read_system_name=$(get_setting_name "$system_line")
      if [[ "$read_system_name" == "$system_being_changed" ]]; then
        local read_system_enabled=$(get_setting_value "$rd_conf" "$read_system_name" "retrodeck" "$current_preset")
        while IFS='^' read -r action read_preset read_setting_name new_setting_value section
        do
          case "$action" in

          "config_file_format" )
            local read_config_format="$read_preset"
          ;;

          "target_file" )
            if [[ "$read_preset" = \$* ]]; then
              eval read_preset=$read_preset
            fi
            local read_target_file="$read_preset"
          ;;

          "defaults_file" )
            if [[ "$read_preset" = \$* ]]; then
              eval read_preset=$read_preset
            fi
            local read_defaults_file="$read_preset"
          ;;

          "change" )
            if [[ "$read_preset" == "$current_preset" ]]; then
              if [[ "$read_system_enabled" == "true" ]]; then
                if [[ "$new_setting_value" = \$* ]]; then
                  eval new_setting_value=$new_setting_value
                fi
                if [[ "$read_config_format" == "retroarch" ]]; then # If this is a RetroArch core, generate the override file
                  if [[ -z $(grep "$read_setting_name" "$read_target_file") ]]; then
                    if [[ ! -f "$read_target_file" ]]; then
                      mkdir -p "$(realpath $(dirname "$read_target_file"))"
                      echo "$read_setting_name = ""$new_setting_value""" > "$read_target_file"
                    else
                      add_setting "$read_target_file" "$read_setting_name" "$new_setting_value" "$read_config_format" "$section"
                    fi
                  else
                    set_setting_value "$read_target_file" "$read_setting_name" "$new_setting_value" "$read_config_format" "$section"
                  fi
                else
                  if [[ "$read_config_format" == "retroarch-all" ]]; then
                    read_config_format="retroarch"
                  fi
                  set_setting_value "$read_target_file" "$read_setting_name" "$new_setting_value" "$read_config_format" "$section"
                fi
              else
                if [[ "$read_config_format" == "retroarch" ]]; then
                  if [[ -f "$read_target_file" ]]; then
                    delete_setting "$read_target_file" "$read_setting_name" "$read_config_format" "$section"
                    if [[ -z $(cat "$read_target_file") ]]; then # If the override file is empty
                      rm -f "$read_target_file"
                    fi
                    if [[ -z $(ls -1 $(dirname "$read_target_file")) ]]; then # If the override folder is empty
                      rmdir "$(dirname $read_target_file)"
                    fi
                  fi
                else
                  if [[ "$read_config_format" == "retroarch-all" ]]; then
                    read_config_format="retroarch"
                  fi
                  local default_setting_value=$(get_setting_value "$read_defaults_file" "$read_setting_name" "$read_config_format" "$section")
                  set_setting_value "$read_target_file" "$read_setting_name" "$default_setting_value" "$read_config_format" "$section"
                fi
              fi
            fi
          ;;

          * )
            echo "Other data: $action $read_preset $read_setting_name $new_setting_value $section" # DEBUG
          ;;

          esac
        done < <(cat "$presets_dir/$read_system_name"_presets.cfg)
      fi
    done < <(printf '%s\n' "$preset_section")
  done
}

generate_single_patch() {
  # generate_single_patch $original_file $modified_file $patch_file $system

  local original_file="$1"
  local modified_file="$2"
  local patch_file="$3"
  local system="$4"

  rm "$patch_file" # Remove old patch file (maybe change this to create a backup instead?)

  while read -r current_setting_line; # Look for changes from the original file to the modified one
  do
    printf -v escaped_setting_line '%q' "$current_setting_line" # Take care of special characters before they mess with future commands
    escaped_setting_line=$(sed -E 's^\+^\\+^g' <<< "$escaped_setting_line") # Need to escape plus signs as well

    if [[ (! -z $current_setting_line) && (! $current_setting_line == "#!/bin/bash") && (! $current_setting_line == "[]") ]]; then # Ignore empty lines, empty arrays or Bash start lines
      if [[ ! -z $(grep -o -P "^\[.+?\]$" <<< "$current_setting_line") || ! -z $(grep -o -P "^\b.+?:$" <<< "$current_setting_line") ]]; then # Capture section header lines
        if [[ $current_setting_line =~ ^\[.+\] ]]; then # If normal section line
          action="section"
          current_section=$(sed 's^[][]^^g' <<< $current_setting_line) # Remove brackets from section name
        elif [[ ! -z $(grep -o -P "^\b.+?:$" <<< "$current_setting_line") ]]; then # If RPCS3 section name
          action="section"
          current_section=$(sed 's^:$^^' <<< $current_setting_line) # Remove colon from section name
        fi
      elif [[ (! -z $current_section) ]]; then # If line is in a section...
        if [[ ! -z $(grep -o -P "^\s*?#.*?$" <<< "$current_setting_line") ]]; then # Check for disabled lines
          if [[ -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\s*?'"$(sed -E 's/^[ \t]*//;' <<< "$escaped_setting_line")"'^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\s*?'"$(sed -E 's/^[ \t]*//' <<< "$escaped_setting_line")"'^ p } }' "$modified_file") ]]; then # If disabled line is not disabled in new file...
          action="disable_setting"
          echo $action"^"$current_section"^"$(sed -n -E 's^\s*?#(.*?)$^\1^p' <<< $(sed -E 's/^[ \t]*//' <<< "$current_setting_line")) >> "$patch_file"
          fi
        elif [[ ! -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\s*?#'"$(sed -E 's/^[ \t]*//' <<< "$escaped_setting_line")"'^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\s*?#'"$(sed -E 's/^[ \t]*//;' <<< "$escaped_setting_line")"'^ p } }' "$modified_file") ]]; then # Check if line is disabled in new file
          action="enable_setting"
          echo $action"^"$current_section"^"$current_setting_line >> "$patch_file"
        else # Look for setting value differences
          current_setting_name=$(get_setting_name "$escaped_setting_line" "$system")
          if [[ (-z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\b'"$current_setting_name"'\s*?[:=]^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\b'"$(sed -E 's/^[ \t]*//;' <<< "$escaped_setting_line")"'$^ p } }' "$modified_file")) ]]; then # If the same setting line is not found in the same section of the modified file...
            if [[ ! -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\b'"$current_setting_name"'\s*?[:=]^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\b'"$current_setting_name"'\s*?[:=]^ p } }' "$modified_file") ]]; then # But the setting exists in that section, only with a different value...
              new_setting_value=$(get_setting_value $2 "$current_setting_name" "$system" $current_section)
              action="change"
              echo $action"^"$current_section"^"$(sed -e 's%\\\\%\\%g' <<< "$current_setting_name")"^"$new_setting_value"^"$system >> "$patch_file"
            fi
          fi
        fi
      elif [[ -z "$current_section" ]]; then # If line is not in a section...
        if [[ ! -z $(grep -o -P "^\s*?#.*?$" <<< "$current_setting_line") ]]; then # Check for disabled lines
          if [[ -z $(grep -o -P "^\s*?$current_setting_line$" "$modified_file") ]]; then # If disabled line is not disabled in new file...
            action="disable_setting"
            echo $action"^"$current_section"^"$(sed -n -E 's^\s*?#(.*?)$^\1^p' <<< "$current_setting_line") >> "$patch_file"
          fi
        elif [[ ! -z $(sed -n -E '\^\s*?#'"$(sed -E 's/^[ \t]*//' <<< "$escaped_setting_line")"'$^p' "$modified_file") ]]; then # Check if line is disabled in new file
            action="enable_setting"
            echo $action"^"$current_section"^"$current_setting_line >> "$patch_file"
        else # Look for setting value differences
          if [[ (-z $(sed -n -E '\^\s*?\b'"$(sed -E 's/^[ \t]*//' <<< "$escaped_setting_line")"'$^p' "$modified_file")) ]]; then # If the same setting line is not found in the modified file...
            current_setting_name=$(get_setting_name "$escaped_setting_line" "$system")
            if [[ ! -z $(sed -n -E '\^\s*?\b'"$current_setting_name"'\s*?[:=]^p' "$modified_file") ]]; then # But the setting exists, only with a different value...
              new_setting_value=$(get_setting_value $2 "$current_setting_name" "$system")
              action="change"
              echo $action"^"$current_section"^"$(sed -e 's%\\\\%\\%g' <<< "$current_setting_name")"^"$new_setting_value"^"$system >> "$patch_file"
            fi
          fi
        fi
      fi
    fi
  done < "$original_file"

    # Reset the variables for reuse
    action=""
    current_section=""
    current_setting_name=""
    current_setting_value=""

  while read -r current_setting_line; # Look for new lines (from dynamically generated config files) in modified file compared to original
  do

    printf -v escaped_setting_line '%q' "$current_setting_line" # Take care of special characters before they mess with future commands

    if [[ (! -z $current_setting_line) && (! $current_setting_line == "#!/bin/bash") && (! $current_setting_line == "[]") ]]; then # Ignore empty lines, empty arrays or Bash start lines
      if [[ ! -z $(grep -o -P "^\[.+?\]$" <<< "$current_setting_line") || ! -z $(grep -o -P "^\b.+?:$" <<< "$current_setting_line") ]]; then # Capture section header lines
      if [[ $current_setting_line =~ ^\[.+\] ]]; then # If normal section line
        action="section"
        current_section=$(sed 's^[][]^^g' <<< $current_setting_line) # Remove brackets from section name
      elif [[ ! -z $(grep -o -P "^\b.+?:$" <<< "$current_setting_line") ]]; then # If RPCS3 section name
        action="section"
        current_section=$(sed 's^:$^^' <<< $current_setting_line) # Remove colon from section name
      fi
      elif [[ (! -z $current_section) ]]; then
        current_setting_name=$(get_setting_name "$escaped_setting_line" "$4")
        if [[ -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\b'"$current_setting_name"'.*^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\b'"$current_setting_name"'^p } }' $1 ) ]]; then # If setting name is not found in this section of the original file...
          action="add_setting_line" # TODO: This should include the previous line, so that new lines can be inserted in the correct place rather than at the end.
          echo $action"^"$current_section"^"$current_setting_line"^^"$4 >> $3
        fi
      elif [[ (-z $current_section) ]]; then
        current_setting_name=$(get_setting_name "$escaped_setting_line" "$4")
        if [[ -z $(sed -n -E '\^\s*?\b'"$current_setting_name"'\s*?[:=]^p' $1) ]]; then # If setting name is not found in the original file...
          action="add_setting_line" # TODO: This should include the previous line, so that new lines can be inserted in the correct place rather than at the end.
          echo $action"^"$current_section"^"$current_setting_line"^^"$4 >> $3
        fi
      fi
    fi
  done < "$modified_file"
}

deploy_single_patch() {

# This function will take an "original" file and a patch file and generate a ready to use modified file
# USAGE: deploy_single_patch $original_file $patch_file $output_file

cp -fv $1 $3 # Create a copy of the original file to be patched

while IFS="^" read -r action current_section setting_name setting_value system_name
do

  case $action in

	"disable_file" )
    eval disable_file "$setting_name"
	;;

	"enable_file" )
    eval enable_file "$setting_name"
	;;

	"add_setting_line" )
    add_setting_line $3 "$setting_name" $system_name $current_section
	;;

	"disable_setting" )
    disable_setting $3 "$setting_name" $system_name $current_section
	;;

	"enable_setting" )
    enable_setting $3 "$setting_name" $system_name $current_section
	;;

	"change" )
    if [[ "$setting_value" = \$* ]]; then # If patch setting value is a reference to an internal variable name
      eval setting_value="$setting_value"
    fi
    set_setting_value $3 "$setting_name" "$setting_value" $system_name $current_section
  ;;

  *"#"* )
	  # Comment line in patch file
	;;

	* )
	  echo "Config line malformed: $action"
	;;

  esac
done < $2
}

deploy_multi_patch() {

# This function will take a single "batch" patch file and run all patches listed in it, across multiple config files
# USAGE: deploy_multi_patch $patch_file
# Patch file format should be as follows, with optional entries in (). Optional settings can be left empty, but must still have ^ dividers:
# $action^($current_section)^$setting_name^$setting_value^$system_name^($config file)

while IFS="^" read -r action current_section setting_name setting_value system_name config_file
do
  case $action in

	"disable_file" )
    if [[ "$config_file" = \$* ]]; then # If patch setting value is a reference to an internal variable name
      eval config_file="$config_file"
    fi
    disable_file "$config_file"
	;;

	"enable_file" )
    if [[ "$config_file" = \$* ]]; then # If patch setting value is a reference to an internal variable name
      eval config_file="$config_file"
    fi
    enable_file "$config_file"
	;;

	"add_setting_line" )
    if [[ "$config_file" = \$* ]]; then # If patch setting value is a reference to an internal variable name
      eval config_file="$config_file"
    fi
    add_setting_line "$config_file" "$setting_name" $system_name $current_section
	;;

	"disable_setting" )
    if [[ "$config_file" = \$* ]]; then # If patch setting value is a reference to an internal variable name
      eval config_file="$config_file"
    fi
    disable_setting "$config_file" "$setting_name" $system_name $current_section
	;;

	"enable_setting" )
    if [[ "$config_file" = \$* ]]; then # If patch setting value is a reference to an internal variable name
      eval config_file="$config_file"
    fi
    enable_setting "$config_file" "$setting_name" $system_name $current_section
	;;

	"change" )
    if [[ "$setting_value" = \$* ]]; then # If patch setting value is a reference to an internal variable name
      eval setting_value="$setting_value"
    fi
    set_setting_value "$config_file" "$setting_name" "$setting_value" $system_name $current_section
  ;;

  *"#"* )
	  # Comment line in patch file
	;;

	* )
	  echo "Config line malformed: $action"
	;;

  esac
done < $1
}

check_network_connectivity() {
  # This function will do a basic check for network availability and return "true" if it is working.
  # USAGE: if [[ $(check_network_connectivity) == "true" ]]; then

  wget -q --spider "$remote_network_target"

  if [ $? -eq 0 ]; then
    echo "true"
  else
    echo "false"
  fi
}

check_for_version_update() {
  # This function will perform a basic online version check and alert the user if there is a new version available.

  local online_version=$(curl --silent "https://api.github.com/repos/XargonWan/$update_repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

  if [[ ! "$update_ignore" == "$online_version" ]]; then
    if [[ "$update_repo" == "RetroDECK" ]] && [[ $(sed -e 's/[\.a-z]//g' <<< $version) -le $(sed -e 's/[\.a-z]//g' <<< $online_version) ]]; then
      choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Ignore this version" \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Update Available" \
        --text="There is a new version of RetroDECK available!\nYou are running version $hard_version, the latest is $online_version.\n\nIf you would like to update to the new version now, click \"Yes\".\nIf you would like to skip reminders about this version, click \"Ignore this version\".\nYou will be reminded again at the next version update.\n\nIf you would like to disable these update notifications entirely, disable Online Update Checks in the Configurator.")
      rc=$? # Capture return code, as "Yes" button has no text value
      if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
        if [[ $choice == "Ignore this version" ]]; then
          set_setting_value $rd_conf "update_ignore" "$online_version" retrodeck "options" # Store version to ignore for future checks
        fi
      else # User clicked "Yes"
        configurator_generic_dialog "RetroDECK Online Update" "The update process may take several minutes.\n\nAfter the update is complete, RetroDECK will close. When you run it again you will be using the latest version."
        (
        flatpak-spawn --host flatpak update --noninteractive -y net.retrodeck.retrodeck
        ) |
        zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Updater" \
        --text="RetroDECK is updating to the latest version, please wait."
        configurator_generic_dialog "RetroDECK Online Update" "The update process is now complete!\n\nPlease restart RetroDECK to keep the fun going."
        exit 1
      fi
    elif [[ "$update_repo" == "RetroDECK-cooker" ]] && [[ ! $version == $online_version ]]; then
      choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Ignore this version" \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Update Available" \
        --text="There is a more recent build of the RetroDECK cooker branch.\nYou are running version $hard_version, the latest is $online_version.\n\nWould you like to update to it?\nIf you would like to skip reminders about this version, click \"Ignore this version\".\nYou will be reminded again at the next version update.\n\nIf you would like to disable these update notifications entirely, disable Online Update Checks in the Configurator.")
      rc=$? # Capture return code, as "Yes" button has no text value
      if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
        if [[ $choice == "Ignore this version" ]]; then
          set_setting_value $rd_conf "update_ignore" "$online_version" retrodeck "options" # Store version to ignore for future checks.
        fi
      else # User clicked "Yes"
        configurator_generic_dialog "RetroDECK Online Update" "The update process may take several minutes.\n\nAfter the update is complete, RetroDECK will close. When you run it again you will be using the latest version."
        (
        local latest_cooker_download=$(curl --silent https://api.github.com/repos/XargonWan/$update_repo/releases/latest | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')
        mkdir -p "$rdhome/RetroDECK_Updates"
        wget -P "$rdhome/RetroDECK_Updates" $latest_cooker_download
        flatpak-spawn --host flatpak install --user --bundle --noninteractive -y "$rdhome/RetroDECK_Updates/RetroDECK.flatpak"
        rm -rf "$rdhome/RetroDECK_Updates" # Cleanup old bundles to save space
        ) |
        zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Updater" \
        --text="RetroDECK is updating to the latest version, please wait."
        configurator_generic_dialog "RetroDECK Online Update" "The update process is now complete!\n\nPlease restart RetroDECK to keep the fun going."
        exit 1
      fi
    fi
  fi
}

validate_input() {
  while IFS="^" read -r input action
  do
    if [[ "$input" == "$1" ]]; then
      eval "$action"
      input_validated="true"
    fi
  done < $input_validation
}

update_rd_conf() {
  # This function will import a default retrodeck.cfg file and update it with any current settings. This will allow us to expand the file over time while retaining current user settings.
  # USAGE: update_rd_conf

  # STAGE 1: For current files that haven't been broken into sections yet, where every setting name is unique

  conf_read # Read current settings into memory
  mv -f $rd_conf $rd_conf_backup # Backup config file before update
  cp $rd_defaults $rd_conf # Copy defaults file into place
  conf_write # Write old values into new default file

  # STAGE 2: To handle presets sections that use duplicate setting names

  mv -f $rd_conf $rd_conf_backup # Backup config file agiain before update but after Stage 1 expansion
  generate_single_patch $rd_defaults $rd_conf_backup $rd_update_patch retrodeck # Create a patch file for differences between defaults and current user settings
  sed -i '/change^^version/d' $rd_update_patch # Remove version line from temporary patch file
  deploy_single_patch $rd_defaults $rd_update_patch $rd_conf # Re-apply user settings to defaults file
  set_setting_value $rd_conf "version" "$hard_version" retrodeck # Set version of currently running RetroDECK to updated retrodeck.cfg
  rm -f $rd_update_patch # Cleanup temporary patch file
  conf_read # Read all settings into memory
}

resolve_preset_conflicts() {
  # This function will resolve conflicts between setting presets. ie. borders and widescreen cannot both be enabled at the same time.
  # The function will read the $section_that_was_just_enabled and $section_to_check_for_conflicts
  # If a conflict is found (where two conflicting settings are both enabled) the $section_to_check_for_conflicts entry will be disabled
  # USAGE: resolve_preset_conflict "$section_that_was_just_enabled" "$section_to_check_for_conflicts" "system"

  local section_being_enabled=$1
  local section_to_check_for_conflicts=$2
  local system=$3
  local enabled_section_results=$(sed -n '/\['"$section_being_enabled"'\]/, /\[/{ /\['"$section_being_enabled"'\]/! { /\[/! p } }' $rd_conf | sed '/^$/d')

  while IFS= read -r config_line
    do
      system_name=$(get_setting_name "$config_line" $system)
      system_value=$(get_setting_value $rd_conf "$system_name" $system $section_being_enabled)
      if [[ $system_value == "true" && $(get_setting_value $rd_conf "$(get_setting_name "$config_line" $system)" $system $section_to_check_for_conflicts) == "true" ]]; then
        set_setting_value $rd_conf $system_name "false" retrodeck $section_to_check_for_conflicts
      fi
  done < <(printf '%s\n' "$enabled_section_results")
}

multi_user_set_default_dialog() {
  chosen_user="$1"
  choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="No and don't ask again" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Default User" \
  --text="Would you like to set $chosen_user as the default user?\n\nIf the current user cannot be determined from the system, the default will be used.\nThis normally only happens in Desktop Mode.\n\nIf you would like to be asked which user is playing every time, click \"No and don't ask again\"")
  rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
    if [[ $choice == "No and don't ask again" ]]; then
      set_setting_value $rd_conf "ask_default_user" "false" retrodeck "options"
    fi
  else # User clicked "Yes"
    set_setting_value $rd_conf "default_user" "$chosen_user" retrodeck "options"
  fi
}

multi_user_choose_current_user_dialog() {
full_userlist=()
while IFS= read -r user
do
full_userlist=("${full_userlist[@]}" "$user")
done < <(ls -1 "$multi_user_data_folder")

chosen_user=$(zenity \
  --list --width=1200 --height=720 \
  --ok-label="Select User" \
  --text="Choose the current user:" \
  --column "Steam Username" --print-column=1 \
  "${full_userlist[@]}")

if [[ ! -z $chosen_user && -z $default_user && $ask_default_user == "true" ]]; then
  multi_user_set_default_dialog "$chosen_user"
fi
echo "$chosen_user"
}

multi_user_enable_multi_user_mode() {
  if [[ -z "$SteamAppUser" ]]; then
    configurator_generic_dialog "RetroDECK Multi-User Mode" "The Steam username of the current user could not be determined from the system.\n\nThis can happen when running in Desktop mode.\n\nYou will be asked to specify the Steam username (not profile name) of the current user in the next dialog."
  fi
  if [[ -d "$multi_user_data_folder" && $(ls -1 "$multi_user_data_folder" | wc -l) -gt 0 ]]; then # If multi-user data folder exists from prior use and is not empty
    if [[ -d "$multi_user_data_folder/$SteamAppUser" ]]; then # Current user has an existing save folder
      configurator_generic_dialog "RetroDECK Multi-User Mode" "The current user $SteamAppUser has an existing folder in the multi-user data folder.\n\nThe saves here are likely older than the ones currently used by RetroDECK.\n\nThe old saves will be backed up to $backups_folder and the current saves will be loaded into the multi-user data folder."
      mkdir -p "$backups_folder"
      tar -C "$multi_user_data_folder" -cahf "$backups_folder/multi-user-backup_$SteamAppUser_$(date +"%Y_%m_%d").zip" "$SteamAppUser"
      rm -rf "$multi_user_data_folder/$SteamAppUser" # Remove stale data after backup
    fi
  fi
  set_setting_value $rd_conf "multi_user_mode" "true" retrodeck "options"
  multi_user_determine_current_user
  if [[ -d "$multi_user_data_folder/$SteamAppUser" ]]; then
    configurator_process_complete_dialog "enabling multi-user support"
  else
    configurator_generic_dialog "RetroDECK Multi-User Mode" "It looks like something went wrong while enabling multi-user mode."
  fi
}

multi_user_disable_multi_user_mode() {
  if [[ $(ls -1 "$multi_user_data_folder" | wc -l) -gt 1 ]]; then
    full_userlist=()
    while IFS= read -r user
    do
    full_userlist=("${full_userlist[@]}" "$user")
    done < <(ls -1 "$multi_user_data_folder")

    single_user=$(zenity \
      --list --width=1200 --height=720 \
      --ok-label="Select User" \
      --text="Choose the current user:" \
      --column "Steam Username" --print-column=1 \
      "${full_userlist[@]}")

    if [[ ! -z "$single_user" ]]; then # Single user was selected
      multi_user_return_to_single_user "$single_user"
      set_setting_value $rd_conf "multi_user_mode" "false" retrodeck "options"
      configurator_process_complete_dialog "disabling multi-user support"
    else
      configurator_generic_dialog "RetroDECK Multi-User Mode" "No single user was selected, please try the process again."
      configurator_retrodeck_multiuser_dialog
    fi
  else
    single_user=$(ls -1 "$multi_user_data_folder")
    multi_user_return_to_single_user "$single_user"
    set_setting_value $rd_conf "multi_user_mode" "false" retrodeck "options"
    configurator_process_complete_dialog "disabling multi-user support"
  fi
}

multi_user_determine_current_user() {
  if [[ $(get_setting_value $rd_conf "multi_user_mode" retrodeck "options") == "true" ]]; then # If multi-user environment is enabled in rd_conf
    if [[ -d "$multi_user_data_folder" ]]; then
      if [[ ! -z $SteamAppUser ]]; then # If running in Game Mode and this variable exists
        if [[ -z $(ls -1 "$multi_user_data_folder" | grep "$SteamAppUser") ]]; then
          multi_user_setup_new_user
        else
          multi_user_link_current_user_files
        fi
      else # Unable to find Steam user ID
        if [[ $(ls -1 "$multi_user_data_folder" | wc -l) -gt 1 ]]; then
          if [[ -z $default_user ]]; then # And a default user is not set
            configurator_generic_dialog "RetroDECK Multi-User Mode" "The current user could not be determined from the system, and there are multiple users registered.\n\nPlease select which user is currently playing in the next dialog."
            SteamAppUser=$(multi_user_choose_current_user_dialog)
            if [[ ! -z $SteamAppUser ]]; then # User was chosen from dialog
              multi_user_link_current_user_files
            else
              configurator_generic_dialog "RetroDECK Multi-User Mode" "No user was chosen, RetroDECK will launch with the files from the user who played most recently."
            fi
          else # The default user is set
            if [[ ! -z $(ls -1 $multi_user_data_folder | grep "$default_user") ]]; then # Confirm user data folder exists
              SteamAppUser=$default_user
              multi_user_link_current_user_files
            else # Default user has no data folder, something may have gone horribly wrong. Setting up as a new user.
              multi_user_setup_new_user
            fi
          fi
        else # If there is only 1 user in the userlist, default to that user
          SteamAppUser=$(ls -1 $multi_user_data_folder)
          multi_user_link_current_user_files
        fi
      fi
    else # If the userlist file doesn't exist yet, create it and add the current user
      if [[ ! -z "$SteamAppUser" ]]; then
        multi_user_setup_new_user
      else # If running in Desktop mode for the first time
        configurator_generic_dialog "RetroDECK Multi-User Mode" "The current user could not be determined from the system and there is no existing userlist.\n\nPlease enter the Steam account username (not profile name) into the next dialog, or run RetroDECK in game mode."
        if zenity --entry \
          --title="Specify Steam username" \
          --text="Enter Steam username:"
        then # User clicked "OK"
          SteamAppUser="$?"
          if [[ ! -z "$SteamAppUser" ]]; then
            multi_user_setup_new_user
          else # But dialog box was blank
            configurator_generic_dialog "RetroDECK Multi-User Mode" "No username was entered, so multi-user data folder cannot be created.\n\nDisabling multi-user mode, please try the process again."
            set_setting_value $rd_conf "multi_user_mode" "false" retrodeck "options"
          fi
        else # User clicked "Cancel"
          configurator_generic_dialog "RetroDECK Multi-User Mode" "Cancelling multi-user mode activation."
          set_setting_value $rd_conf "multi_user_mode" "false" retrodeck "options"
        fi
      fi
    fi
  else
    configurator_generic_dialog "RetroDECK Multi-User Mode" "Multi-user mode is not currently enabled"
  fi
}

multi_user_return_to_single_user() {
  single_user="$1"
  echo "Returning to single-user mode for $single_user"
  unlink "$saves_folder"
  unlink "$states_folder"
  unlink "$rd_conf"
  mv -f "$multi_user_data_folder/$SteamAppUser/config/retrodeck/retrodeck.cfg" "$rd_conf"
  # RetroArch one-offs, because it has so many folders that should be shared between users
  unlink "/var/config/retroarch/retroarch.cfg"
  unlink "/var/config/retroarch/retroarch-core-options.cfg"
  mv -f "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch.cfg" "/var/config/retroarch/retroarch.cfg"
  mv -f "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch-core-options.cfg" "/var/config/retroarch/retroarch-core-options.cfg"
  # XEMU one-offs, because it stores its config in /var/data, not /var/config like everything else
  unlink "/var/config/xemu"
  unlink "/var/data/xemu"
  mkdir -p "/var/config/xemu"
  mv -f "$multi_user_data_folder/$single_user/config/xemu"/{.[!.],}* "/var/config/xemu"
  dir_prep "/var/config/xemu" "/var/data/xemu"
  mkdir -p "$saves_folder"
  mkdir -p "$states_folder"
  mv -f "$multi_user_data_folder/$single_user/saves"/{.[!.],}* "$saves_folder"
  mv -f "$multi_user_data_folder/$single_user/states"/{.[!.],}* "$states_folder"
  for emu_conf in $(find "$multi_user_data_folder/$single_user/config" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
  do
    if [[ ! -z $(grep "^$emu_conf$" "$multi_user_emulator_config_dirs") ]]; then
      unlink "/var/config/$emu_conf"
      mkdir -p "/var/config/$emu_conf"
      mv -f "$multi_user_data_folder/$single_user/config/$emu_conf"/{.[!.],}* "/var/config/$emu_conf"
    fi
  done
  rm -r "$multi_user_data_folder/$single_user" # Should be empty, omitting -f for safety
}

multi_user_setup_new_user() {
  # TODO: RPCS3 one-offs
  echo "Setting up new user"
  unlink "$saves_folder"
  unlink "$states_folder"
  dir_prep "$multi_user_data_folder/$SteamAppUser/saves" "$saves_folder"
  dir_prep "$multi_user_data_folder/$SteamAppUser/states" "$states_folder"
  mkdir -p "$multi_user_data_folder/$SteamAppUser/config/retrodeck"
  cp -L "$rd_conf" "$multi_user_data_folder/$SteamAppUser/config/retrodeck/retrodeck.cfg" # Copy existing rd_conf file for new user.
  rm -f "$rd_conf"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/config/retrodeck/retrodeck.cfg" "$rd_conf"
  mkdir -p "$multi_user_data_folder/$SteamAppUser/config/retroarch"
  if [[ ! -L "/var/config/retroarch/retroarch.cfg" ]]; then
    mv "/var/config/retroarch/retroarch.cfg" "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch.cfg"
    mv "/var/config/retroarch/retroarch-core-options.cfg" "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch-core-options.cfg"
  else
    cp "$emuconfigs/retroarch/retroarch.cfg" "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch.cfg"
    cp "$emuconfigs/retroarch/retroarch-core-options.cfg" "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch-core-options.cfg"
    set_setting_value "$raconf" "savefile_directory" "$saves_folder" "retroarch"
    set_setting_value "$raconf" "savestate_directory" "$states_folder" "retroarch"
    set_setting_value "$raconf" "screenshot_directory" "$screenshots_folder" "retroarch"
  fi
  ln -sfT "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch.cfg" "/var/config/retroarch/retroarch.cfg"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch-core-options.cfg" "/var/config/retroarch/retroarch-core-options.cfg"
  for emu_conf in $(find "/var/config" -mindepth 1 -maxdepth 1 -type l -printf '%f\n') # For all the config folders already linked to a different user
  do
    if [[ ! -z $(grep "^$emu_conf$" "$multi_user_emulator_config_dirs") ]]; then
      unlink "/var/config/$emu_conf"
      prepare_emulator "reset" "$emu_conf"
    fi
  done
  for emu_conf in $(find "/var/config" -mindepth 1 -maxdepth 1 -type d -printf '%f\n') # For all the currently non-linked config folders, like from a newly-added emulator
  do
    if [[ ! -z $(grep "^$emu_conf$" "$multi_user_emulator_config_dirs") ]]; then
      dir_prep "$multi_user_data_folder/$SteamAppUser/config/$emu_conf" "/var/config/$emu_conf"
    fi
  done
}

multi_user_link_current_user_files() {
  echo "Linking existing user"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/saves" "$saves_folder"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/states" "$states_folder"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/config/retrodeck/retrodeck.cfg" "$rd_conf"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch.cfg" "/var/config/retroarch/retroarch.cfg"
  ln -sfT "$multi_user_data_folder/$SteamAppUser/config/retroarch/retroarch-core-options.cfg" "/var/config/retroarch/retroarch-core-options.cfg"
  for emu_conf in $(find "/var/config" -mindepth 1 -maxdepth 1 -type d -printf '%f\n') # Find any new emulator config folders from last time this user played
  do
    if [[ ! -z $(grep "^$emu_conf$" "$multi_user_emulator_config_dirs") ]]; then
      dir_prep "$multi_user_data_folder/$SteamAppUser/config/$emu_conf" "/var/config/$emu_conf"
    fi
  done
  for emu_conf in $(find "/var/config" -mindepth 1 -maxdepth 1 -type l -printf '%f\n')
  do
    if [[ ! -z $(grep "^$emu_conf$" "$multi_user_emulator_config_dirs") ]]; then
      if [[ -d "$multi_user_data_folder/$SteamAppUser/config/$emu_conf" ]]; then # If the current user already has a config folder for this emulator
        ln -sfT "$multi_user_data_folder/$SteamAppUser/config/$emu_conf" "retrodeck/config/$emu_conf"
      else # If the current user doesn't have a config folder for this emulator, init it and then link it
        prepare_emulator "reset" "$emu_conf"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/$emu_conf" "/var/config/$emu_conf"
      fi
    fi
  done
}

conf_write() {
  # This function will update the RetroDECK config file with matching variables from memory
  # USAGE: conf_write

  while IFS= read -r current_setting_line # Read the existing retrodeck.cfg
  do
    if [[ (! -z "$current_setting_line") && (! "$current_setting_line" == "#"*) && (! "$current_setting_line" == "[]") ]]; then # If the line has a valid entry in it
      if [[ ! -z $(grep -o -P "^\[.+?\]$" <<< "$current_setting_line") ]]; then # If the line is a section header
        local current_section=$(sed 's^[][]^^g' <<< $current_setting_line) # Remove brackets from section name
      else
        if [[ "$current_section" == "" || "$current_section" == "paths" || "$current_section" == "options" ]]; then
          local current_setting_name=$(get_setting_name "$current_setting_line" "retrodeck") # Read the variable name from the current line
          local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "$current_section") # Read the variables value from retrodeck.cfg
          local memory_setting_value=$(eval "echo \$${current_setting_name}") # Read the variable names' value from memory
          if [[ ! "$current_setting_value" == "$memory_setting_value" && ! -z "$memory_setting_value" ]]; then # If the values are different...
            set_setting_value "$rd_conf" "$current_setting_name" "$memory_setting_value" "retrodeck" "$current_section" # Update the value in retrodeck.cfg
          fi
        fi
      fi
    fi
  done < $rd_conf
}

conf_read() {
  # This function will read the RetroDECK config file into memory
  # USAGE: conf_read

  while IFS= read -r current_setting_line # Read the existing retrodeck.cfg
  do
    if [[ (! -z "$current_setting_line") && (! "$current_setting_line" == "#"*) && (! "$current_setting_line" == "[]") ]]; then # If the line has a valid entry in it
      if [[ ! -z $(grep -o -P "^\[.+?\]$" <<< "$current_setting_line") ]]; then # If the line is a section header
        local current_section=$(sed 's^[][]^^g' <<< $current_setting_line) # Remove brackets from section name
      else
        if [[ "$current_section" == "" || "$current_section" == "paths" || "$current_section" == "options" ]]; then
          local current_setting_name=$(get_setting_name "$current_setting_line" "retrodeck") # Read the variable name from the current line
          local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "$current_section") # Read the variables value from retrodeck.cfg
          eval "$current_setting_name=$current_setting_value" # Write the current setting name and value to memory
        fi
      fi
    fi
  done < $rd_conf
}

dir_prep() {
  # This script is creating a symlink preserving old folder contents and moving them in the new one

  # Call me with:
  # dir prep "real dir" "symlink location"
  real="$1"
  symlink="$2"

  echo -e "\n[DIR PREP]\nMoving $symlink in $real" #DEBUG

   # if the symlink dir is already a symlink, unlink it first, to prevent recursion
  if [ -L "$symlink" ];
  then
    echo "$symlink is already a symlink, unlinking to prevent recursives" #DEBUG
    unlink "$symlink"
  fi

  # if the dest dir exists we want to backup it
  if [ -d "$symlink" ];
  then
    echo "$symlink found" #DEBUG
    mv -f "$symlink" "$symlink.old"
  fi

  # if the real dir is already a symlink, unlink it first
  if [ -L "$real" ];
  then
    echo "$real is already a symlink, unlinking to prevent recursives" #DEBUG
    unlink "$real"
  fi

  # if the real dir doesn't exist we create it
  if [ ! -d "$real" ];
  then
    echo "$real not found, creating it" #DEBUG
    mkdir -pv "$real"
  fi

  # creating the symlink
  echo "linking $real in $symlink" #DEBUG
  mkdir -pv "$(dirname "$symlink")" # creating the full path except the last folder
  ln -svf "$real" "$symlink"

  # moving everything from the old folder to the new one, delete the old one
  if [ -d "$symlink.old" ];
  then
    echo "Moving the data from $symlink.old to $real" #DEBUG
    mv -f "$symlink.old"/{.[!.],}* $real
    echo "Removing $symlink.old" #DEBUG
    rm -rf "$symlink.old"
  fi

  echo -e "$symlink is now $real\n"
}

update_splashscreens() {
  # This script will purge any existing ES graphics and reload them from RO space into somewhere ES will look for it
  # USAGE: update_splashscreens

  rm -rf /var/config/emulationstation/.emulationstation/resources/graphics
  mkdir -p /var/config/emulationstation/.emulationstation/resources/graphics
  cp -rf /app/retrodeck/graphics/* /var/config/emulationstation/.emulationstation/resources/graphics
}

deploy_helper_files() {
  # This script will distribute helper documentation files throughout the filesystem according to the $helper_files_list
  # USAGE: deploy_helper_files

  while IFS='^' read -r file dest
  do
      if [[ ! "$file" == "#"* ]] && [[ ! -z "$file" ]]; then
      eval current_dest="$dest"
      cp -f "$helper_files_folder/$file" "$current_dest/$file"
    fi

  done < "$helper_files_list"
}

prepare_emulator() {
  # This function will perform one of several actions on one or more emulators
  # The actions currently include "reset" and "postmove"
  # The "reset" action will initialize the emulator
  # The "postmove" action will update the emulator settings after one or more RetroDECK folders were moved
  # An emulator can be called by name, by parent folder name in the /var/config root or use the option "all" to perform the action on all emulators equally
  # The function will also behave differently depending on if the initial request was from the Configurator, the CLI interface or a normal function call if needed
  # USAGE: prepare_emulator "$action" "$emulator" "$call_source(optional)"
  
  action="$1"
  emulator="$2"
  call_source="$3"

  if [[ "$emulator" == "retrodeck" ]]; then
    if [[ "$action" == "reset" ]]; then # Update the paths of all folders in retrodeck.cfg and create them
        while read -r config_line; do
          local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
          if [[ ! $current_setting_name =~ (rdhome|sdcard) ]]; then # Ignore these locations
            local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
            eval "$current_setting_name=$rdhome/$(basename $current_setting_value)"
            mkdir -p "$rdhome/$(basename $current_setting_value)"
          fi
        done < <(grep -v '^\s*$' $rd_conf | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f')
    fi
    if [[ "$action" == "postmove" ]]; then # Update the paths of any folders that came with the retrodeck folder during a move
      while read -r config_line; do
        local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
        if [[ ! $current_setting_name =~ (rdhome|sdcard) ]]; then # Ignore these locations
          local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
          if [[ -d "$rdhome/$(basename $current_setting_value)" ]]; then # If the folder exists at the new ~/retrodeck location
              eval "$current_setting_name=$rdhome/$(basename $current_setting_value)"
          fi
        fi
      done < <(grep -v '^\s*$' $rd_conf | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f')
    fi
  fi

  if [[ "$emulator" =~ ^(emulationstation|all)$ ]]; then # For use after ESDE-related folders are moved or a reset
    if [[ "$action" == "reset" ]]; then
      rm -rf /var/config/emulationstation/
      mkdir -p /var/config/emulationstation/
      emulationstation --home /var/config/emulationstation --create-system-dirs
      update_splashscreens
      dir_prep "$roms_folder" "/var/config/emulationstation/ROMs"
      dir_prep "$media_folder" "/var/config/emulationstation/.emulationstation/downloaded_media"
      dir_prep "$themes_folder" "/var/config/emulationstation/.emulationstation/themes"
      dir_prep "$rdhome/gamelists" "/var/config/emulationstation/.emulationstation/gamelists"
      cp -f /app/retrodeck/es_settings.xml /var/config/emulationstation/.emulationstation/es_settings.xml
    fi
    if [[ "$action" == "postmove" ]]; then
      dir_prep "$roms_folder" "/var/config/emulationstation/ROMs"
      dir_prep "$media_folder" "/var/config/emulationstation/.emulationstation/downloaded_media"
      dir_prep "$themes_folder" "/var/config/emulationstation/.emulationstation/themes"
      dir_prep "$rdhome/gamelists" "/var/config/emulationstation/.emulationstation/gamelists"
    fi
  fi

  if [[ "$emulator" =~ ^(retroarch|RetroArch|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      if [[ $(check_network_connectivity) == "true" ]]; then
        if [[ $multi_user_mode == "true" ]]; then
          rm -rf "$multi_user_data_folder/$SteamAppUser/config/retroarch"
          mkdir -p "$multi_user_data_folder/$SteamAppUser/config/retroarch"
          cp -fv $emuconfigs/retroarch/retroarch.cfg "$multi_user_data_folder/$SteamAppUser/config/retroarch/"
          cp -fv $emuconfigs/retroarch/retroarch-core-options.cfg "$multi_user_data_folder/$SteamAppUser/config/retroarch/"
        else
          rm -rf /var/config/retroarch
          mkdir -p /var/config/retroarch
          dir_prep "$bios_folder" "/var/config/retroarch/system"
          dir_prep "$logs_folder/retroarch" "/var/config/retroarch/logs"
          mkdir -pv /var/config/retroarch/shaders/
          cp -rf /app/share/libretro/shaders /var/config/retroarch/
          dir_prep "$rdhome/shaders/retroarch" "/var/config/retroarch/shaders"
          mkdir -pv /var/config/retroarch/cores/
          cp -f /app/share/libretro/cores/* /var/config/retroarch/cores/
          cp -fv $emuconfigs/retroarch/retroarch.cfg /var/config/retroarch/
          cp -fv $emuconfigs/retroarch/retroarch-core-options.cfg /var/config/retroarch/
          mkdir -pv /var/config/retroarch/config/
          cp -rf "$emuconfigs/retroarch/core-overrides/"* /var/config/retroarch/config
          dir_prep "$borders_folder" "/var/config/retroarch/borders"
          cp -rt /var/config/retroarch/borders/ /app/retrodeck/emu-configs/retroarch/borders/*
          set_setting_value "$raconf" "savefile_directory" "$saves_folder" "retroarch"
          set_setting_value "$raconf" "savestate_directory" "$states_folder" "retroarch"
          set_setting_value "$raconf" "screenshot_directory" "$screenshots_folder" "retroarch"
        fi

        # PPSSPP
        echo "--------------------------------"
        echo "Initializing PPSSPP_LIBRETRO"
        echo "--------------------------------"
        if [ -d $bios_folder/PPSSPP/flash0/font ]
        then
          mv -fv $bios_folder/PPSSPP/flash0/font $bios_folder/PPSSPP/flash0/font.bak
        fi
        mkdir -p $bios_folder/PPSSPP
        wget "https://github.com/hrydgard/ppsspp/archive/refs/heads/master.zip" -P $bios_folder/PPSSPP
        unzip -q "$bios_folder/PPSSPP/master.zip" -d $bios_folder/PPSSPP/
        mv -f "$bios_folder/PPSSPP/ppsspp-master/assets/"* "$bios_folder/PPSSPP/"
        rm -rfv "$bios_folder/PPSSPP/master.zip"
        rm -rfv "$bios_folder/PPSSPP/ppsspp-master"
        if [ -d $bios_folder/PPSSPP/flash0/font.bak ]
        then
          mv -f $bios_folder/PPSSPP/flash0/font.bak $bios_folder/PPSSPP/flash0/font
        fi

        # MSX / SVI / ColecoVision / SG-1000
        echo "-----------------------------------------------------------"
        echo "Initializing MSX / SVI / ColecoVision / SG-1000 LIBRETRO"
        echo "-----------------------------------------------------------"
        wget "http://bluemsx.msxblue.com/rel_download/blueMSXv282full.zip" -P $bios_folder/MSX
        unzip -q "$bios_folder/MSX/blueMSXv282full.zip" -d $bios_folder/MSX
        mv -f $bios_folder/MSX/Databases $bios_folder/Databases
        mv -f $bios_folder/MSX/Machines $bios_folder/Machines
        rm -rf $bios_folder/MSX
      else
        if [[ "$call_source" == "cli" ]]; then
          printf "You do not appear to be connected to a network with internet access.\n\nThe RetroArch reset process requires some files from the internet to function properly.\n\nPlease retry this process once a network connection is available.\n"
        fi
      fi
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$bios_folder" "/var/config/retroarch/system"
      dir_prep "$logs_folder/retroarch" "/var/config/retroarch/logs"
      dir_prep "$rdhome/shaders/retroarch" "/var/config/retroarch/shaders"
      set_setting_value "$raconf" "savefile_directory" "$saves_folder" "retroarch"
      set_setting_value "$raconf" "savestate_directory" "$states_folder" "retroarch"
      set_setting_value "$raconf" "screenshot_directory" "$screenshots_folder" "retroarch"
    fi
  fi
  
  if [[ "$emulator" =~ ^(cemu|Cemu|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing CEMU"
      echo "----------------------"
      rm -rf /var/config/Cemu
      mkdir -pv /var/config/Cemu/
      cp -fr "$emuconfigs/cemu/"* /var/config/Cemu/
      #TODO : set_setting_value for Cemu and multi_user
      sed -i 's#RETRODECKHOMEDIR#'$rdhome'#g' /var/config/Cemu/settings.xml
      dir_prep "$rdhome/saves/wiiu/cemu" "$rdhome/bios/cemu/usr/save"
    fi
    if [[ "$action" == "reset" ]] || [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
      #TODO : set_setting_value for Cemu and multi_user
      sed -i 's#RETRODECKHOMEDIR#'$rdhome'#g' /var/config/Cemu/settings.xml
      dir_prep "$rdhome/saves/wiiu/cemu" "$rdhome/bios/cemu/usr/save"
    fi
    # if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      
    # fi
  fi
  
  if [[ "$emulator" =~ ^(citra|citra-emu|Citra|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "------------------------"
      echo "Initializing CITRA"
      echo "------------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/citra-emu"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/citra-emu"
        cp -fv $emuconfigs/citra/qt-config.ini "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini" "nand_directory" "$saves_folder/n3ds/citra/nand/" "citra" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini" "sdmc_directory" "$saves_folder/n3ds/citra/sdmc/" "citra" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini" "Paths\gamedirs\3\path" "$roms_folder/n3ds" "citra" "UI"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini" "Paths\screenshotPath" "$screenshots_folder" "citra" "UI"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/citra-emu" "/var/config/citra-emu"
      else # Single-user actions
        rm -rf /var/config/citra-emu
        mkdir -pv /var/config/citra-emu/
        cp -f $emuconfigs/citra/qt-config.ini /var/config/citra-emu/qt-config.ini
        set_setting_value "$citraconf" "nand_directory" "$saves_folder/n3ds/citra/nand/" "citra" "Data%20Storage"
        set_setting_value "$citraconf" "sdmc_directory" "$saves_folder/n3ds/citra/sdmc/" "citra" "Data%20Storage"
        set_setting_value "$citraconf" "Paths\gamedirs\3\path" "$roms_folder/n3ds" "citra" "UI"
        set_setting_value "$citraconf" "Paths\screenshotPath" "$screenshots_folder" "citra" "UI"
      fi
      # Shared actions
      mkdir -pv "$saves_folder/n3ds/citra/nand/"
      mkdir -pv "$saves_folder/n3ds/citra/sdmc/"
      dir_prep "$bios_folder/citra/sysdata" "/var/data/citra-emu/sysdata"
      dir_prep "$logs_folder/citra" "/var/data/citra-emu/log"
      dir_prep "$mods_folder/Citra" "/var/data/citra-emu/load/mods"
      dir_prep "$texture_packs_folder/Citra" "/var/data/citra-emu/load/textures"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$rdhome/bios/citra/sysdata" "/var/data/citra-emu/sysdata"
      dir_prep "$rdhome/.logs/citra" "/var/data/citra-emu/log"
      dir_prep "$mods_folder/Citra" "/var/data/citra-emu/load/mods"
      dir_prep "$texture_packs_folder/Citra" "/var/data/citra-emu/load/textures"
      set_setting_value "$citraconf" "nand_directory" "$saves_folder/n3ds/citra/nand/" "citra" "Data%20Storage"
      set_setting_value "$citraconf" "sdmc_directory" "$saves_folder/n3ds/citra/sdmc/" "citra" "Data%20Storage"
      set_setting_value "$citraconf" "Paths\gamedirs\3\path" "$roms_folder/n3ds" "citra" "UI"
      set_setting_value "$citraconf" "Paths\screenshotPath" "$screenshots_folder" "citra" "UI"
    fi
  fi
  
  if [[ "$emulator" =~ ^(dolphin|dolphin-emu|Dolphin|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing DOLPHIN"
      echo "----------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu"
        cp -fvr "$emuconfigs/dolphin/"* "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "BIOS" "$bios_folder" "dolphin" "GBA"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "SavesPath" "$saves_folder/gba" "dolphin" "GBA"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "ISOPath0" "$roms_folder/wii" "dolphin" "General"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "ISOPath1" "$roms_folder/gc" "dolphin" "General"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "WiiSDCardPath" "$saves_folder/wii/dolphin/sd.raw" "dolphin" "General"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu" "/var/config/dolphin-emu"
      else # Single-user actions
        rm -rf /var/config/dolphin-emu
        mkdir -pv /var/config/dolphin-emu/
        cp -fvr "$emuconfigs/dolphin/"* /var/config/dolphin-emu/
        set_setting_value "$dolphinconf" "BIOS" "$bios_folder" "dolphin" "GBA"
        set_setting_value "$dolphinconf" "SavesPath" "$saves_folder/gba" "dolphin" "GBA"
        set_setting_value "$dolphinconf" "ISOPath0" "$roms_folder/wii" "dolphin" "General"
        set_setting_value "$dolphinconf" "ISOPath1" "$roms_folder/gc" "dolphin" "General"
        set_setting_value "$dolphinconf" "WiiSDCardPath" "$saves_folder/wii/dolphin/sd.raw" "dolphin" "General"
      fi # Shared actions
      dir_prep "$saves_folder/gc/dolphin/EU" "/var/data/dolphin-emu/GC/EUR" # TODO: Multi-user one-off
      dir_prep "$saves_folder/gc/dolphin/US" "/var/data/dolphin-emu/GC/USA" # TODO: Multi-user one-off
      dir_prep "$saves_folder/gc/dolphin/JP" "/var/data/dolphin-emu/GC/JAP" # TODO: Multi-user one-off
      dir_prep "$screenshots_folder" "/var/data/dolphin-emu/ScreenShots"
      dir_prep "$states_folder/dolphin" "/var/data/dolphin-emu/StateSaves"
      dir_prep "$saves_folder/wii/dolphin" "/var/data/dolphin-emu/Wii"
      dir_prep "$mods_folder/Dolphin" "/var/data/dolphin-emu/Load/GraphicMods"
      dir_prep "$texture_packs_folder/Dolphin" "/var/data/dolphin-emu/Load/Textures"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$saves_folder/gc/dolphin/EU" "/var/data/dolphin-emu/GC/EUR"
      dir_prep "$saves_folder/gc/dolphin/US" "/var/data/dolphin-emu/GC/USA"
      dir_prep "$saves_folder/gc/dolphin/JP" "/var/data/dolphin-emu/GC/JAP"
      dir_prep "$screenshots_folder" "/var/data/dolphin-emu/ScreenShots"
      dir_prep "$states_folder/dolphin" "/var/data/dolphin-emu/StateSaves"
      dir_prep "$saves_folder/wii/dolphin" "/var/data/dolphin-emu/Wii"
      dir_prep "$mods_folder/Dolphin" "/var/data/dolphin-emu/Load/GraphicMods"
      dir_prep "$texture_packs_folder/Dolphin" "/var/data/dolphin-emu/Load/Textures"
      set_setting_value "$dolphinconf" "BIOS" "$bios_folder" "dolphin" "GBA"
      set_setting_value "$dolphinconf" "SavesPath" "$saves_folder/gba" "dolphin" "GBA"
      set_setting_value "$dolphinconf" "ISOPath0" "$roms_folder/wii" "dolphin" "General"
      set_setting_value "$dolphinconf" "ISOPath1" "$roms_folder/gc" "dolphin" "General"
      set_setting_value "$dolphinconf" "WiiSDCardPath" "$saves_folder/wii/dolphin/sd.raw" "dolphin" "General"
    fi
  fi
  
  if [[ "$emulator" =~ ^(duckstation|Duckstation|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "------------------------"
      echo "Initializing DUCKSTATION"
      echo "------------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/duckstation"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/data/duckstation/"
        cp -fv "$emuconfigs/duckstation/"* "$multi_user_data_folder/$SteamAppUser/data/duckstation"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "SearchDirectory" "$bios_folder" "duckstation" "BIOS"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "Card1Path" "$saves_folder/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "Card2Path" "$saves_folder/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "Directory" "$saves_folder/psx/duckstation/memcards" "duckstation" "MemoryCards"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/duckstation" "/var/config/duckstation"
      else # Single-user actions
        rm -rf /var/config/duckstation
        mkdir -p /var/data/duckstation/
        cp -fv "$emuconfigs/duckstation/"* /var/data/duckstation
        set_setting_value "$duckstationconf" "SearchDirectory" "$bios_folder" "duckstation" "BIOS"
        set_setting_value "$duckstationconf" "Card1Path" "$saves_folder/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
        set_setting_value "$duckstationconf" "Card2Path" "$saves_folder/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
        set_setting_value "$duckstationconf" "Directory" "$saves_folder/psx/duckstation/memcards" "duckstation" "MemoryCards"
      fi
      dir_prep "$saves_folder/psx/duckstation/memcards" "/var/data/duckstation/memcards" # TODO: This shouldn't be needed anymore, verify
      dir_prep "$states_folder/psx/duckstation" "/var/data/duckstation/savestates" # This is hard-coded in Duckstation, always needed
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      set_setting_value "$duckstationconf" "SearchDirectory" "$bios_folder" "duckstation" "BIOS"
      set_setting_value "$duckstationconf" "Card1Path" "$saves_folder/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
      set_setting_value "$duckstationconf" "Card2Path" "$saves_folder/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
      set_setting_value "$duckstationconf" "Directory" "$saves_folder/psx/duckstation/memcards" "duckstation" "MemoryCards"
      dir_prep "$states_folder/psx/duckstation" "/var/data/duckstation/savestates" # This is hard-coded in Duckstation, always needed
    fi
  fi
  
  if [[ "$emulator" =~ ^(melonds|melonDS|MelonDS|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing MELONDS"
      echo "----------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/melonDS"
        mkdir -pv "$multi_user_data_folder/$SteamAppUser/config/melonDS/"
        cp -fvr $emuconfigs/melonds/melonDS.ini "$multi_user_data_folder/$SteamAppUser/config/melonDS/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "BIOS9Path" "$bios_folder/bios9.bin" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "BIOS7Path" "$bios_folder/bios7.bin" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "FirmwarePath" "$bios_folder/firmware.bin" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "SaveFilePath" "$saves_folder/nds/melonds" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "SavestatePath" "$states_folder/nds/melonds" "melonds"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/melonDS" "/var/config/melonDS"
      else # Single-user actions
        rm -rf /var/config/melonDS
        mkdir -pv /var/config/melonDS/
        cp -fvr $emuconfigs/melonds/melonDS.ini /var/config/melonDS/
        set_setting_value "$melondsconf" "BIOS9Path" "$bios_folder/bios9.bin" "melonds"
        set_setting_value "$melondsconf" "BIOS7Path" "$bios_folder/bios7.bin" "melonds"
        set_setting_value "$melondsconf" "FirmwarePath" "$bios_folder/firmware.bin" "melonds"
        set_setting_value "$melondsconf" "SaveFilePath" "$saves_folder/nds/melonds" "melonds"
        set_setting_value "$melondsconf" "SavestatePath" "$states_folder/nds/melonds" "melonds"
      fi
      # Shared actions
      mkdir -pv "$saves_folder/nds/melonds"
      mkdir -pv "$states_folder/nds/melonds"
      dir_prep "$bios_folder" "/var/config/melonDS/bios"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$bios_folder" "/var/config/melonDS/bios"
      set_setting_value "$melondsconf" "BIOS9Path" "$bios_folder/bios9.bin" "melonds"
      set_setting_value "$melondsconf" "BIOS7Path" "$bios_folder/bios7.bin" "melonds"
      set_setting_value "$melondsconf" "FirmwarePath" "$bios_folder/firmware.bin" "melonds"
      set_setting_value "$melondsconf" "SaveFilePath" "$saves_folder/nds/melonds" "melonds"
      set_setting_value "$melondsconf" "SavestatePath" "$states_folder/nds/melonds" "melonds"
    fi
  fi
  
  if [[ "$emulator" =~ ^(pcsx2|PCSX2|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing PCSX2"
      echo "----------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/PCSX2"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis"
        cp -fvr "$emuconfigs/PCSX2/"* "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "Bios" "$bios_folder" "pcsx2" "Folders"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "Snapshots" "$screenshots_folder" "pcsx2" "Folders"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "SaveStates" "$states_folder/ps2/pcsx2" "pcsx2" "Folders"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "MemoryCards" "$saves_folder/ps2/pcsx2/memcards" "pcsx2" "Folders"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "RecursivePaths" "$roms_folder/ps2" "pcsx2" "GameList"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/PCSX2" "/var/config/PCSX2"
      else # Single-user actions
        rm -rf /var/config/PCSX2
        mkdir -pv "/var/config/PCSX2/inis"
        cp -fvr "$emuconfigs/PCSX2/"* /var/config/PCSX2/inis/
        set_setting_value "$pcsx2conf" "Bios" "$bios_folder" "pcsx2" "Folders"
        set_setting_value "$pcsx2conf" "Snapshots" "$screenshots_folder" "pcsx2" "Folders"
        set_setting_value "$pcsx2conf" "SaveStates" "$states_folder/ps2/pcsx2" "pcsx2" "Folders"
        set_setting_value "$pcsx2conf" "MemoryCards" "$saves_folder/ps2/pcsx2/memcards" "pcsx2" "Folders"
        set_setting_value "$pcsx2conf" "RecursivePaths" "$roms_folder/ps2" "pcsx2" "GameList"
      fi
      # Shared actions
      mkdir -pv "$saves_folder/ps2/pcsx2/memcards"
      mkdir -pv "$states_folder/ps2/pcsx2"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      set_setting_value "$pcsx2conf" "Bios" "$bios_folder" "pcsx2" "Folders"
      set_setting_value "$pcsx2conf" "Snapshots" "$screenshots_folder" "pcsx2" "Folders"
      set_setting_value "$pcsx2conf" "SaveStates" "$states_folder/ps2/pcsx2" "pcsx2" "Folders"
      set_setting_value "$pcsx2conf" "MemoryCards" "$saves_folder/ps2/pcsx2/memcards" "pcsx2" "Folders"
      set_setting_value "$pcsx2conf" "RecursivePaths" "$roms_folder/ps2" "pcsx2" "GameList"
    fi
  fi

  if [[ "$emulator" =~ ^(pico8|pico-8|all)$ ]]; then
    if [[ ("$action" == "reset") || ("$action" == "postmove") ]]; then
      dir_prep "$bios_folder/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
      dir_prep "$roms_folder/pico8" "$bios_folder/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
      dir_prep "$saves_folder/pico-8" "$bios_folder/pico-8/cdata"  # PICO-8 saves folder
    fi
  fi
  
  if [[ "$emulator" =~ ^(ppsspp|PPSSPP|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "------------------------"
      echo "Initializing PPSSPPSDL"
      echo "------------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/ppsspp"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/ppsspp/PSP/SYSTEM/"
        cp -fv "$emuconfigs/ppssppsdl/"* "$multi_user_data_folder/$SteamAppUser/config/ppsspp/PSP/SYSTEM/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/ppsspp/PSP/SYSTEM/ppsspp.ini" "CurrentDirectory" "$roms_folder/psp" "ppsspp" "General"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/ppsspp" "/var/config/ppsspp"
      else # Single-user actions
        rm -rf /var/config/ppsspp
        mkdir -p /var/config/ppsspp/PSP/SYSTEM/
        cp -fv "$emuconfigs/ppssppsdl/"* /var/config/ppsspp/PSP/SYSTEM/
        set_setting_value "$ppssppconf" "CurrentDirectory" "$roms_folder/psp" "ppsspp" "General"
      fi
      # Shared actions
      dir_prep "$saves_folder/PSP/PPSSPP-SA" "/var/config/ppsspp/PSP/SAVEDATA"
      dir_prep "$states_folder/PSP/PPSSPP-SA" "/var/config/ppsspp/PSP/PPSSPP_STATE"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      set_setting_value "$ppssppconf" "CurrentDirectory" "$roms_folder/psp" "ppsspp" "General"
      dir_prep "$saves_folder/PSP/PPSSPP-SA" "/var/config/ppsspp/PSP/SAVEDATA"
      dir_prep "$states_folder/PSP/PPSSPP-SA" "/var/config/ppsspp/PSP/PPSSPP_STATE"
    fi
  fi
  
  if [[ "$emulator" =~ ^(primehack|Primehack|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing Primehack"
      echo "----------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/primehack"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/primehack"
        cp -fvr "$emuconfigs/primehack/"* "$multi_user_data_folder/$SteamAppUser/config/primehack/"
        set_setting_value ""$multi_user_data_folder/$SteamAppUser/config/primehack/Dolphin.ini"" "ISOPath0" "$roms_folder/gc" "primehack" "General"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/primehack" "/var/config/primehack"
      else # Single-user actions
        rm -rf /var/config/primehack
        mkdir -pv /var/config/primehack/
        cp -fvr "$emuconfigs/primehack/"* /var/config/primehack/
        set_setting_value "$primehackconf" "ISOPath0" "$roms_folder/gc" "primehack" "General"
      fi
      # Shared actions
      dir_prep "$saves_folder/gc/primehack/EU" "/var/data/primehack/GC/EUR"
      dir_prep "$saves_folder/gc/primehack/US" "/var/data/primehack/GC/USA"
      dir_prep "$saves_folder/gc/primehack/JP" "/var/data/primehack/GC/JAP"
      dir_prep "$screenshots_folder" "/var/data/primehack/ScreenShots"
      dir_prep "$states_folder/primehack" "/var/data/primehack/StateSaves"
      mkdir -pv /var/data/primehack/Wii/
      dir_prep "$saves_folder/wii/primehack" "/var/data/primehack/Wii"
      dir_prep "$mods_folder/Primehack" "/var/data/primehack/Load/GraphicMods"
      dir_prep "$texture_packs_folder/Primehack" "/var/data/primehack/Load/Textures"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$saves_folder/gc/primehack/EU" "/var/data/primehack/GC/EUR"
      dir_prep "$saves_folder/gc/primehack/US" "/var/data/primehack/GC/USA"
      dir_prep "$saves_folder/gc/primehack/JP" "/var/data/primehack/GC/JAP"
      dir_prep "$screenshots_folder" "/var/data/primehack/ScreenShots"
      dir_prep "$states_folder/primehack" "/var/data/primehack/StateSaves"
      dir_prep "$saves_folder/wii/primehack" "/var/data/primehack/Wii/"
      dir_prep "$mods_folder/Primehack" "/var/data/primehack/Load/GraphicMods"
      dir_prep "$texture_packs_folder/Primehack" "/var/data/primehack/Load/Textures"
      set_setting_value "$primehackconf" "ISOPath0" "$roms_folder/gc" "primehack" "General"
    fi
  fi
  
  if [[ "$emulator" =~ ^(rpcs3|RPCS3|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "------------------------"
      echo "Initializing RPCS3"
      echo "------------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/rpcs3"
        mkdir -pv "$multi_user_data_folder/$SteamAppUser/config/rpcs3/"
        cp -fr "$emuconfigs/rpcs3/"* "$multi_user_data_folder/$SteamAppUser/config/rpcs3/"
        # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
        sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_folder/rpcs3/"'^' "$multi_user_data_folder/$SteamAppUser/config/rpcs3/vfs.yml"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/rpcs3/vfs.yml" "/games/" "$roms_folder/ps3/" "rpcs3"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/rpcs3" "/var/config/rpcs3"
      else # Single-user actions
        rm -rf /var/config/rpcs3
        mkdir -pv /var/config/rpcs3/
        cp -fr "$emuconfigs/rpcs3/"* /var/config/rpcs3/
        # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
        sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_folder/rpcs3/"'^' "$rpcs3vfsconf"
        set_setting_value "$rpcs3vfsconf" "/games/" "$roms_folder/ps3/" "rpcs3"
        dir_prep "$bios_folder/rpcs3/dev_hdd0/home/00000001/savedata" "$saves_folder/ps3/rpcs3"
      fi
      # Shared actions
      mkdir -p "$bios_folder/rpcs3/dev_hdd0"
      mkdir -p "$bios_folder/rpcs3/dev_hdd1"
      mkdir -p "$bios_folder/rpcs3/dev_flash"
      mkdir -p "$bios_folder/rpcs3/dev_flash2"
      mkdir -p "$bios_folder/rpcs3/dev_flash3"
      mkdir -p "$bios_folder/rpcs3/dev_bdvd"
      mkdir -p "$bios_folder/rpcs3/dev_usb000"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
      sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_folder/rpcs3"'^' "$rpcs3vfsconf"
      set_setting_value "$rpcs3vfsconf" "/games/" "$roms_folder/ps3" "rpcs3"
    fi
  fi
  
  # if [[ "$emulator" =~ ^(ryujunx|Ryujinx|all)$ ]]; then
  #   if [[ "$action" == "reset" ]]; then # Run reset-only commands
  #     echo "------------------------"
  #     echo "Initializing RYUJINX"
  #     echo "------------------------"
  #     if [[ $multi_user_mode == "true" ]]; then
  #       rm -rf "$multi_user_data_folder/$SteamAppUser/config/Ryujinx"
  #       mkdir -p "$multi_user_data_folder/$SteamAppUser/config/Ryujinx/system"
  #       cp -fv $emuconfigs/ryujinx/* "$multi_user_data_folder/$SteamAppUser/config/Ryujinx"
  #       sed -i 's#/home/deck/retrodeck#'$rdhome'#g' "$multi_user_data_folder/$SteamAppUser/config/Ryujinx/Config.json"
  #       dir_prep "$multi_user_data_folder/$SteamAppUser/config/Ryujinx" "/var/config/Ryujinx"
  #     else
  #       # removing config directory to wipe legacy files
  #       rm -rf /var/config/Ryujinx
  #       mkdir -p /var/config/Ryujinx/system
  #       cp -fv $emuconfigs/ryujinx/* /var/config/Ryujinx
  #       sed -i 's#/home/deck/retrodeck#'$rdhome'#g' "$ryujinxconf"
  #     fi
  #   fi
  #   if [[ "$action" == "reset" ]] || [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
  #     dir_prep "$bios_folder/switch/keys" "/var/config/Ryujinx/system"
  #   fi
  #   if [[ "$action" == "postmove" ]]; then # Run only post-move commands
  #     sed -i 's#RETRODECKHOMEDIR#'$rdhome'#g' "$ryujinxconf" # This is an unfortunate one-off because set_setting_value does not currently support JSON
  #   fi
  # fi
  
  if [[ "$emulator" =~ ^(xemu|XEMU|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      if [[ $(check_network_connectivity) == "true" ]]; then
        echo "------------------------"
        echo "Initializing XEMU"
        echo "------------------------"
        if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
          rm -rf /var/config/xemu
          rm -rf /var/data/xemu
          rm -rf "$multi_user_data_folder/$SteamAppUser/config/xemu"
          mkdir -pv "$multi_user_data_folder/$SteamAppUser/config/xemu/"
          cp -fv $emuconfigs/xemu/xemu.toml "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml"
          set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "screenshot_dir" "'$screenshots_folder'" "xemu" "General"
          set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "bootrom_path" "'$bios_folder/mcpx_1.0.bin'" "xemu" "sys.files"
          set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "flashrom_path" "'$bios_folder/Complex.bin'" "xemu" "sys.files"
          set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "eeprom_path" "$saves_folder/xbox/xemu/xbox-eeprom.bin" "xemu" "sys.files"
          set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "hdd_path" "'$bios_folder/xbox_hdd.qcow2'" "xemu" "sys.files"
          dir_prep "$multi_user_data_folder/$SteamAppUser/config/xemu" "/var/config/xemu" # Creating config folder in /var/config for consistentcy and linking back to original location where emulator will look
          dir_prep "$multi_user_data_folder/$SteamAppUser/config/xemu" "/var/data/xemu"
        else # Single-user actions
          rm -rf /var/config/xemu
          rm -rf /var/data/xemu
          dir_prep "/var/config/xemu" "/var/data/xemu" # Creating config folder in /var/config for consistentcy and linking back to original location where emulator will look
          cp -fv $emuconfigs/xemu/xemu.toml "$xemuconf"
          set_setting_value "$xemuconf" "screenshot_dir" "'$screenshots_folder'" "xemu" "General"
          set_setting_value "$xemuconf" "bootrom_path" "'$bios_folder/mcpx_1.0.bin'" "xemu" "sys.files"
          set_setting_value "$xemuconf" "flashrom_path" "'$bios_folder/Complex.bin'" "xemu" "sys.files"
          set_setting_value "$xemuconf" "eeprom_path" "$saves_folder/xbox/xemu/xbox-eeprom.bin" "xemu" "sys.files"
          set_setting_value "$xemuconf" "hdd_path" "'$bios_folder/xbox_hdd.qcow2'" "xemu" "sys.files"
        fi # Shared actions
        mkdir -pv $saves_folder/xbox/xemu/
        # Preparing HD dummy Image if the image is not found
        if [ ! -f $bios_folder/xbox_hdd.qcow2 ]
        then
          wget "https://github.com/mborgerson/xemu-hdd-image/releases/latest/download/xbox_hdd.qcow2.zip" -P $bios_folder/
          unzip -q $bios_folder/xbox_hdd.qcow2.zip -d $bios_folder/
          rm -rfv $bios_folder/xbox_hdd.qcow2.zip
        fi
      else
        if [[ "$call_source" == "cli" ]]; then
          printf "You do not appear to be connected to a network with internet access.\n\nThe Xemu reset process requires some files from the internet to function properly.\n\nPlease retry this process once a network connection is available.\n"
        fi
      fi
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      set_setting_value "$xemuconf" "screenshot_dir" "'$screenshots_folder'" "xemu" "General"
      set_setting_value "$xemuconf" "bootrom_path" "'$bios_folder/mcpx_1.0.bin'" "xemu" "sys.files"
      set_setting_value "$xemuconf" "flashrom_path" "'$bios_folder/Complex.bin'" "xemu" "sys.files"
      set_setting_value "$xemuconf" "eeprom_path" "$saves_folder/xbox/xemu/xbox-eeprom.bin" "xemu" "sys.files"
      set_setting_value "$xemuconf" "hdd_path" "'$bios_folder/xbox_hdd.qcow2'" "xemu" "sys.files"
    fi
  fi
  
  if [[ "$emulator" =~ ^(yuzu|Yuzu|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing YUZU"
      echo "----------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/yuzu"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/yuzu"
        cp -fvr "$emuconfigs/yuzu/"* "$multi_user_data_folder/$SteamAppUser/config/yuzu/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "nand_directory" "$saves_folder/switch/yuzu/nand" "yuzu" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "sdmc_directory" "$saves_folder/switch/yuzu/sdmc" "yuzu" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "Paths\gamedirs\4\path" "$roms_folder/switch" "yuzu" "UI"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "Screenshots\screenshot_path" "$screenshots_folder" "yuzu" "UI"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/yuzu" "/var/config/yuzu"
      else # Single-user actions
        rm -rf /var/config/yuzu
        mkdir -pv /var/config/yuzu/
        cp -fvr "$emuconfigs/yuzu/"* /var/config/yuzu/
        set_setting_value "$yuzuconf" "nand_directory" "$saves_folder/switch/yuzu/nand" "yuzu" "Data%20Storage"
        set_setting_value "$yuzuconf" "sdmc_directory" "$saves_folder/switch/yuzu/sdmc" "yuzu" "Data%20Storage"
        set_setting_value "$yuzuconf" "Paths\gamedirs\4\path" "$roms_folder/switch" "yuzu" "UI"
        set_setting_value "$yuzuconf" "Screenshots\screenshot_path" "$screenshots_folder" "yuzu" "UI"
      fi
      # Shared actions
      dir_prep "$saves_folder/switch/yuzu/nand" "/var/data/yuzu/nand"
      dir_prep "$saves_folder/switch/yuzu/sdmc" "/var/data/yuzu/sdmc"
      dir_prep "$bios_folder/switch/keys" "/var/data/yuzu/keys"
      dir_prep "$bios_folder/switch/registered" "/var/data/yuzu/nand/system/Contents/registered"
      dir_prep "$logs_folder/yuzu" "/var/data/yuzu/log"
      dir_prep "$screenshots_folder" "/var/data/yuzu/screenshots"
      dir_prep "$mods_folder/Yuzu" "/var/data/yuzu/load"
      # removing dead symlinks as they were present in a past version
      if [ -d $bios_folder/switch ]; then
        find $bios_folder/switch -xtype l -exec rm {} \;
      fi
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$bios_folder/switch/keys" "/var/data/yuzu/keys"
      dir_prep "$bios_folder/switch/registered" "/var/data/yuzu/nand/system/Contents/registered"
      dir_prep "$saves_folder/switch/yuzu/nand" "/var/data/yuzu/nand"
      dir_prep "$saves_folder/switch/yuzu/sdmc" "/var/data/yuzu/sdmc"
      dir_prep "$logs_folder/yuzu" "/var/data/yuzu/log"
      dir_prep "$screenshots_folder" "/var/data/yuzu/screenshots"
      dir_prep "$mods_folder/Yuzu" "/var/data/yuzu/load"
      set_setting_value "$yuzuconf" "nand_directory" "$saves_folder/switch/yuzu/nand" "yuzu" "Data%20Storage"
      set_setting_value "$yuzuconf" "sdmc_directory" "$saves_folder/switch/yuzu/sdmc" "yuzu" "Data%20Storage"
      set_setting_value "$yuzuconf" "Paths\gamedirs\4\path" "$roms_folder/switch" "yuzu" "UI"
      set_setting_value "$yuzuconf" "Screenshots\screenshot_path" "$screenshots_folder" "yuzu" "UI"
    fi
  fi
}

update_rpcs3_firmware() {
  (
  mkdir -p "$roms_folder/ps3/tmp"
  chmod 777 "$roms_folder/ps3/tmp"
  wget "$rpcs3_firmware" -P "$roms_folder/ps3/tmp/"
  ) |
  zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK RPCS3 Firmware Download" \
  --text="RetroDECK downloading the RPCS3 firmware, please wait."
  rpcs3 --installfw "$roms_folder/ps3/tmp/PS3UPDAT.PUP"
  rm -rf "$roms_folder/ps3/tmp"
}

backup_retrodeck_userdata() {
  zip -rq9 "$backups_folder/$(date +"%0m%0d")_retrodeck_userdata.zip" "$saves_folder" "$states_folder" "$bios_folder" "$media_folder" "$themes_folder" "$logs_folder" "$screenshots_folder" "$mods_folder" "$texture_packs_folder" "$borders_folder" > $logs_folder/$(date +"%0m%0d")_backup_log.log
}

install_retrodeck_starterpack() {
  # This function will install the roms, gamelists and metadata for the RetroDECK Starter Pack, a curated selection of games the creators of RetroDECK enjoy.
  # USAGE: install_retrodeck_starterpack
  
  ## DOOM section ##
  cp /app/retrodeck/extras/doom1.wad "$roms_folder/doom/doom1.wad" # No -f in case the user already has it
  mkdir -p "/var/config/emulationstation/.emulationstation/gamelists/doom"
  if [[ ! -f "/var/config/emulationstation/.emulationstation/gamelists/doom/gamelist.xml" ]]; then # Don't overwrite an existing gamelist
    cp "/app/retrodeck/rd_prepacks/doom/gamelist.xml" "/var/config/emulationstation/.emulationstation/gamelists/doom/gamelist.xml"
  fi
  mkdir -p "$media_folder/doom"
  unzip -oq "/app/retrodeck/rd_prepacks/doom/doom.zip" -d "$media_folder/doom/"
}

install_retrodeck_controller_profile() {
  # This function will install the needed files for the custom RetroDECK controller profile
  # NOTE: These files need to be stored in shared locations for Steam, outside of the normal RetroDECK folders and should always be an optional user choice
  # BIGGER NOTE: As part of this process, all emulators have their configs hard-reset to match the controller mappings of the profile
  # USAGE: install_retrodeck_controller_profile
  rsync -a "/app/retrodeck/binding-icons/" "$HOME/.steam/steam/tenfoot/resource/images/library/controller/binding_icons/"
  cp -f "$emuconfigs/defaults/retrodeck/RetroDECK_controller_config.vdf" "$HOME/.steam/steam/controller_base/templates/RetroDECK_controller_config.vdf"
  prepare_emulator "all" "reset"
}

create_lock() {
  # creating RetroDECK's lock file and writing the version in the config file
  version=$hard_version
  touch "$lockfile"
  conf_write
}

easter_eggs() {
  # This function will replace the RetroDECK startup splash screen with a different image if the day and time match a listing in easter_egg_checklist.cfg
  # The easter_egg_checklist.cfg file has the current format: $start_date^$end_date^$start_time^$end_time^$splash_file
  # Ex. The line "1001^1031^0000^2359^spooky.svg" would show the file "spooky.svg" during any time of day in the month of October
  # The easter_egg_checklist.cfg is read in order, so lines higher in the file will have higher priority in the event of an overlap
  # USAGE: easter_eggs
  current_day=$(date +"%0m%0d") # Read the current date in a format that can be calculated in ranges
  current_time=$(date +"%0H%0M") # Read the current time in a format that can be calculated in ranges
  if [[ ! -z $(cat $easter_egg_checklist) ]]; then
    while IFS="^" read -r start_date end_date start_time end_time splash_file # Read Easter Egg checklist file and separate values
    do
      if [[ $current_day -ge "$start_date" && $current_day -le "$end_date" && $current_time -ge "$start_time" && $current_time -le "$end_time" ]]; then # If current line specified date/time matches current date/time, set $splash_file to be deployed
        new_splash_file="$splashscreen_dir/$splash_file"
        break
      else # When there are no matches, the default splash screen is set to deploy
        new_splash_file="$default_splash_file"
      fi
    done < $easter_egg_checklist
  else
    new_splash_file="$default_splash_file"
  fi

  cp -f "$new_splash_file" "$current_splash_file" # Deploy assigned splash screen
}

start_retrodeck() {
  easter_eggs # Check if today has a surprise splashscreen and load it if so
  # normal startup
  echo "Starting RetroDECK v$version"
  emulationstation --home /var/config/emulationstation
}

finit_browse() {
# Function for choosing data directory location during first/forced init
path_selected=false
while [ $path_selected == false ]
do
  local target="$(zenity --file-selection --title="Choose RetroDECK data directory location" --directory)"
  if [[ ! -z "$target" ]]; then
    if [[ -w "$target" ]]; then
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" \
      --cancel-label="No" \
      --ok-label "Yes" \
      --text="Your RetroDECK data folder will be:\n\n$target/retrodeck\n\nis that ok?"
      if [ $? == 0 ] #yes
      then
        path_selected=true
        echo "$target/retrodeck"
        break
      else
        zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" --text="Do you want to quit?"
        if [ $? == 0 ] # yes, quit
        then
          exit 2
        fi
      fi
    fi
  else
    zenity --error --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK" \
    --ok-label "Quit" \
    --text="No location was selected. Please run RetroDECK again to retry."
    exit 2
  fi
done
}

finit_user_options_dialog() {
  finit_available_options=()

  while IFS="^" read -r enabled option_name option_desc option_tag
  do
    finit_available_options=("${finit_available_options[@]}" "$enabled" "$option_name" "$option_desc" "$option_tag")
  done < $finit_options_list


  local choices=$(zenity \
  --list --width=1200 --height=720 \
  --checklist --hide-column=4 --ok-label="Confirm Selections" --extra-button="Enable All" \
  --separator=" " --print-column=4 \
  --text="Choose which options to enable:" \
  --column "Enabled?" \
  --column "Option" \
  --column "Description" \
  --column "option_flag" \
  "${finit_available_options[@]}")

  echo "${choices[*]}"
}

finit() {
# Force/First init, depending on the situation

  echo "Executing finit"

  # Internal or SD Card?
  local finit_dest_choice=$(configurator_destination_choice_dialog "RetroDECK data" "Welcome to the first configuration of RetroDECK.\nThe setup will be quick but please READ CAREFULLY each message in order to avoid misconfigurations.\n\nWhere do you want your RetroDECK data folder to be located?\n\nThis folder will contain all ROMs, BIOSs and scraped data." )
  echo "Choice is $finit_dest_choice"

  case $finit_dest_choice in

  "Back" | "" ) # Back or X button quits
    rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
    echo "Now quitting"
    exit 2
  ;;

  "Internal Storage" ) # Internal
    echo "Internal selected"
    rdhome="$HOME/retrodeck"
    if [[ -L $rdhome ]]; then #Remove old symlink from existing install, if it exists
      unlink $rdhome
    fi
  ;;

  "SD Card" )
    echo "SD Card selected"
    if [ ! -d "$sdcard" ] # SD Card path is not existing
    then
      echo "Error: SD card not found"
      zenity --error --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK" \
      --ok-label "Browse" \
      --text="SD Card was not find in the default location.\nPlease choose the SD Card root.\nA retrodeck folder will be created starting from the directory that you selected."
      rdhome=$(finit_browse) # Calling the browse function
      if [[ -z $rdhome ]]; then # If user hit the cancel button
        rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
        exit 2
      fi
    elif [ ! -w "$sdcard" ] #SD card found but not writable
      then
        echo "Error: SD card found but not writable"
        zenity --error --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK" \
        --ok-label "Quit" \
        --text="SD card was found but is not writable\nThis can happen with cards formatted on PC.\nPlease format the SD card through the Steam Deck's Game Mode and run RetroDECK again."
        rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
        echo "Now quitting"
        exit 2
    else
      rdhome="$sdcard/retrodeck"
    fi
  ;;

  "Custom Location" )
      echo "Custom Location selected"
      zenity --info --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK" \
      --ok-label "Browse" \
      --text="Please choose the root folder for the RetroDECK data.\nA retrodeck folder will be created starting from the directory that you selected."
      rdhome=$(finit_browse) # Calling the browse function
      if [[ -z $rdhome ]]; then # If user hit the cancel button
        rm -f "$rd_conf" # Cleanup unfinished retrodeck.cfg if first install is interrupted
        exit 2
      fi
    ;;

  esac

  prepare_emulator "reset" "retrodeck" # Parse the [paths] section of retrodeck.cfg and set the value of / create all needed folders

  conf_write # Write the new values to retrodeck.cfg

  configurator_generic_dialog "RetroDECK Initial Setup" "The next dialog will be a list of optional actions to take during the initial setup.\n\nIf you choose to not do any of these now, they can be done later through the Configurator."
  local finit_options_choices=$(finit_user_options_dialog)

  if [[ "$finit_options_choices" =~ (rpcs3_firmware|Enable All) ]]; then # Additional information on the firmware install process, as the emulator needs to be manually closed
    configurator_generic_dialog "RPCS3 Firmware Install" "You have chosen to install the RPCS3 firmware during the RetroDECK first setup.\n\nThis process will take several minutes and requires network access.\n\nRPCS3 will be launched automatically at the end of the RetroDECK setup process.\nOnce the firmware is installed, please close the emulator to finish the process."
  fi
  
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" \
  --text="RetroDECK will now install the needed files, which can take up to one minute.\nRetroDECK will start once the process is completed.\n\nPress OK to continue."

  (
  prepare_emulator "reset" "all"
  
  # Optional actions based on user choices
  if [[ "$finit_options_choices" =~ (rpcs3_firmware|Enable All) ]]; then
    if [[ $(check_network_connectivity) == "true" ]]; then
      update_rpcs3_firmware
    fi
  fi
  if [[ "$finit_options_choices" =~ (rd_controller_profile|Enable All) ]]; then
    install_retrodeck_controller_profile
  fi
  if [[ "$finit_options_choices" =~ (rd_prepacks|Enable All) ]]; then 
    install_retrodeck_starterpack
  fi

  ) |
  zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Finishing Initialization" \
  --text="RetroDECK is finishing the initial setup process, please wait."

  create_lock
}

save_migration() {
  # Finding existing ROMs folder
  if [ -d "$default_sd/retrodeck" ]
  then
    # ROMs on SD card
    roms_folder="$default_sd/retrodeck/roms"
    if [[ ! -L $rdhome && ! -L $rdhome/roms ]]; then # Add a roms folder symlink back to ~/retrodeck if missing, to fix things like PS2 autosaves until user migrates whole ~retrodeck directory
      ln -s $roms_folder $rdhome/roms
    fi
  else
    # ROMs on Internal
    roms_folder="$HOME/retrodeck/roms"
  fi
  echo "ROMs folder found at $roms_folder"

  # Unhiding downloaded media from the previous versions
  if [ -d "$rdhome/.downloaded_media" ]
  then
    mv -fv "$rdhome/.downloaded_media" "$media_folder"
  fi

  # Unhiding themes folder from the previous versions
  if [ -d "$rdhome/.themes" ]
  then
    mv -fv "$rdhome/.themes" "$themes_folder"
  fi

  # Doing the dir prep as we don't know from which version we came
  dir_prep "$media_folder" "/var/config/emulationstation/.emulationstation/downloaded_media"
  dir_prep "$themes_folder" "/var/config/emulationstation/.emulationstation/themes"
  mkdir -pv $rdhome/.logs #this was added later, maybe safe to remove in a few versions

  # Resetting es_settings, now we need it but in the future I should think a better solution, maybe with sed
  cp -fv /app/retrodeck/es_settings.xml /var/config/emulationstation/.emulationstation/es_settings.xml

  # 0.4 -> 0.5
  # Perform save and state migration if needed

  # Moving PCSX2 Saves
  mv -fv /var/config/PCSX2/sstates/* $rdhome/states/ps2/pcsx2
  mv -fv /var/config/PCSX2/memcards/* $rdhome/saves/ps2/memcards

  # Moving Citra saves from legacy location to 0.5.0b structure

  mv -fv $rdhome/saves/Citra/* $rdhome/saves/n3ds/citra
  rmdir $rdhome/saves/Citra # Old folder cleanup

  versionwheresaveschanged="0.4.5b" # Hardcoded break point between unsorted and sorted saves

  if [[ $(sed -e "s/\.//g" <<< $hard_version) > $(sed -e "s/\.//g" <<< $versionwheresaveschanged) ]] && [[ ! $(sed -e "s/\.//g" <<< $version) > $(sed -e "s/\.//g" <<< $versionwheresaveschanged) ]]; then # Check if user is upgrading from the version where save organization was changed. Try not to reuse this, it things 0.4.5b is newer than 0.4.5
    migration_logfile=$rdhome/.logs/savemove_"$(date +"%Y_%m_%d_%I_%M_%p").log"
    save_backup_file=$rdhome/savebackup_"$(date +"%Y_%m_%d_%I_%M_%p").zip"
    state_backup_file=$rdhome/statesbackup_"$(date +"%Y_%m_%d_%I_%M_%p").zip"

    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK" \
      --text="You are updating to a version of RetroDECK where save file locations have changed!\n\nYour existing files will be backed up for safety and then sorted automatically.\n\nIf a file cannot be sorted automatically it will remain where it is for manual sorting.\n\nPLEASE BE PATIENT! This process can take several minutes if you have a large ROM library."

    allgames=($(find "$roms_folder" -maxdepth 2 -mindepth 2 ! -name "systeminfo.txt" ! -name "systems.txt" ! -name "gc" ! -name "n3ds" ! -name "nds" ! -name "wii" ! -name "xbox" ! -name "*^*" | sed -e "s/ /\^/g")) # Build an array of all games and multi-disc-game-containing folders, adding whitespace placeholder

    allsaves=($(find "$saves_folder" -mindepth 1 -maxdepth 1 -name "*.*" ! -name "gc" ! -name "n3ds" ! -name "nds" ! -name "wii" ! -name "xbox"  | sed -e "s/ /\^/g")) # Build an array of all save files, ignoring standalone emulator sub-folders, adding whitespace placeholder

    allstates=($(find "$states_folder" -mindepth 1 -maxdepth 1 -name "*.*" ! -name "gc" ! -name "n3ds" ! -name "nds" ! -name "wii" ! -name "xbox"  | sed -e "s/ /\^/g")) # Build an array of all state files, ignoring standalone emulator sub-folders, adding whitespace placeholder

    totalsaves=${#allsaves[@]}
    totalstates=${#allstates[@]}
    filesleft=
    current_dest_folder=
    gamestoskip=

    tar -C $rdhome -czf $save_backup_file saves # Backup save directory for safety
    echo "Saves backed up to" $save_backup_file >> $migration_logfile
    tar -C $rdhome -czf $state_backup_file states # Backup state directory for safety
    echo "States backed up to" $state_backup_file >> $migration_logfile

    (
    movefile() { # Take matching save and rom files and sort save into appropriate system folder
      echo "# $filesleft $currentlybeingmoved remaining..." # These lines update the Zenity progress bar
      progress=$(( 100 - (( 100 / "$totalfiles" ) * "$filesleft" )))
      echo $progress
      filesleft=$((filesleft-1))
      if [[ ! " ${gamestoskip[*]} " =~ " ${1} " ]]; then # If the current game name exists multiple times in array ie. /roms/snes/Mortal Kombat 3.zip and /roms/genesis/Mortal Kombat 3.zip, skip and alert user to sort manually
        game=$(sed -e "s/\^/ /g" <<< "$1") # Remove whitespace placeholder
        gamebasename=$(basename "$game" | sed -e 's/\..*//') # Extract pure file name ie. /roms/snes/game1.zip becomes game1
        systemdir="$(basename "$(dirname "$1")")" # Extract parent directory identifying system ROM belongs to
        matches=($(find "$roms_folder" -maxdepth 2 -mindepth 2 -name "$gamebasename"".*" | sed -e 's/ /^/g' | sed -e 's/\..*//')) # Search for multiple instances of pure game name, adding to skip list if found
        if [[ ${#matches[@]} -gt 1 ]]; then
          echo "ERROR: Multiple ROMS found with name:" $gamebasename "Please sort saves and states for these ROMS manually" >> $migration_logfile
          gamestoskip+=("$1")
          return
        fi
        echo "INFO: Examining ROM file:" "$game" >> $migration_logfile
        echo "INFO: System detected as" $systemdir >> $migration_logfile
        sosfile=$(sed -e "s/\^/ /g" <<< "$2") # Remove whitespace placeholder from s-ave o-r s-tate file
        sospurebasename="$(basename "$sosfile")" # Extract pure file name ie. /saves/game1.sav becomes game1
        echo "INFO: Current save or state being examined for match:" $sosfile >> $migration_logfile
        echo "INFO: Matching save or state" $sosfile "and game" $game "found." >> $migration_logfile
        echo "INFO: Moving save or state to" $current_dest_folder"/"$systemdir"/"$sosbasename >> $migration_logfile
        if [[ ! -d $current_dest_folder"/"$systemdir ]]; then # If system directory doesn't exist for save yet, create it
          echo "WARNING: Creating missing system directory" $current_dest_folder"/"$systemdir
          mkdir $current_dest_folder/$systemdir
        fi
        mv "$sosfile" -t $current_dest_folder/$systemdir # Move save to appropriate system directory
        return
      else
        echo "WARNING: Game with name" "$(basename "$1" | sed -e "s/\^/ /g")" "already found. Skipping to next game..." >> $migration_logfile # Inform user of game being skipped due to duplicate ROM names
      fi
    }

    find "$roms_folder" -mindepth 2 -maxdepth 2 -name "*\^*" -exec echo "ERROR: Game named" {} "found, please move save manually" \; >> $migration_logfile # Warn user if any of their files have the whitespace replacement character used by the script

    totalfiles=$totalsaves #set variables for save file migration
    filesleft=$totalsaves
    currentlybeingmoved="saves"
    current_dest_folder=$saves_folder

    for i in "${allsaves[@]}"; do # For each save file, compare to every ROM file name looking for a match
      found=
      currentsave=($(basename "$i" | sed -e 's/\..*//')) # Extract pure file name ie. /saves/game1.sav becomes game1
      for j in "${allgames[@]}"; do
        currentgame=($(basename "$j" | sed -e 's/\..*//')) # Extract pure file name ie. /roms/snes/game1.zip becomes game1
        [[ $currentgame == $currentsave ]] && { found=1; break; } # If names match move to next stage, otherwise skip
      done
      [[ -n $found ]] && movefile $j $i || echo "ERROR: No ROM match found for save file" $i | sed -e 's/\^/ /g' >> $migration_logfile # If a match is found, run movefile() otherwise warn user of stranded save file
    done

    totalfiles=$totalstates #set variables for state file migration
    filesleft=$totalstates
    currentlybeingmoved="states"
    current_dest_folder=$states_folder

    for i in "${allstates[@]}"; do # For each state file, compare to every ROM file name looking for a match
      found=
      currentstate=($(basename "$i" | sed -e 's/\..*//')) # Extract pure file name ie. /states/game1.sav becomes game1
      for j in "${allgames[@]}"; do
        currentgame=($(basename "$j" | sed -e 's/\..*//')) # Extract pure file name ie. /roms/snes/game1.zip becomes game1
        [[ $currentgame == $currentstate ]] && { found=1; break; } # If names match move to next stage, otherwise skip
      done
      [[ -n $found ]] && movefile $j $i || echo "ERROR: No ROM match found for state file" $i | sed -e 's/\^/ /g' >> $migration_logfile # If a match is found, run movefile() otherwise warn user of stranded state file
    done

    ) |
    zenity --progress \
    --icon-name=net.retrodeck.retrodeck \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="Processing Files" \
    --text="# files remaining..." \
    --percentage=0 \
    --no-cancel \
    --auto-close

    if [[ $(cat $migration_logfile | grep "ERROR" | wc -l) -eq 0 ]]; then
      zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK" \
      --text="The migration process has sorted all of your files automatically.\n\nEverything should be working normally, if you experience any issues please check the RetroDECK wiki or contact us directly on the Discord."

    else
      cat $migration_logfile | grep "ERROR" > "$rdhome/manual_sort_needed.log"
      zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK" \
      --text="The migration process was unable to sort $(cat $migration_logfile | grep "ERROR" | wc -l) files automatically.\n\nThese files will need to be moved manually to their new locations, find more detail on the RetroDECK wiki.\n\nA log of the files that need manual sorting can be found at $rdhome/manual_sort_needed.log"
    fi

  else
    echo "Version" $version "is after the save and state organization was changed, no need to sort again"
  fi
}

#=========================
# REUSABLE DIALOGS SECTION
#=========================

debug_dialog() {
  # This function is for displaying commands run by the Configurator without actually running them
  # USAGE: debug_dialog "command"

  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - Debug Dialog" \
  --text="$1"
}

configurator_process_complete_dialog() {
  # This dialog shows when a process is complete.
  # USAGE: configurator_process_complete_dialog "process text"
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Quit" --extra-button="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - Process Complete" \
  --text="The process of $1 is now complete.\n\nYou may need to quit and restart RetroDECK for your changes to take effect\n\nClick OK to return to the Main Menu or Quit to return to RetroDECK."

  if [ ! $? == 0 ] # OK button clicked
  then
      configurator_welcome_dialog
  fi
}

configurator_generic_dialog() {
  # This dialog is for showing temporary messages before another process happens.
  # USAGE: configurator_generic_dialog "title text" "info text"
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "$1" \
  --text="$2"
}

configurator_generic_question_dialog() {
  # This dialog provides a generic dialog for getting a response from a user.
  # USAGE: $(configurator_generic_question_dialog "title text" "action text")
  # This function will return a "true" if the user clicks "Yes", and "false" if they click "No".
  choice=$(zenity --title "RetroDECK - $1" --question --no-wrap --cancel-label="No" --ok-label="Yes" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="$2")
  if [[ $? == "0" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

configurator_destination_choice_dialog() {
  # This dialog is for making things easy for new users to move files to common locations. Gives the options for "Internal", "SD Card" and "Custom" locations.
  # USAGE: $(configurator_destination_choice_dialog "folder being moved" "action text")
  # This function returns one of the values: "Back" "Internal Storage" "SD Card" "Custom Location"
  choice=$(zenity --title "RetroDECK Configurator Utility - Moving $1 folder" --info --no-wrap --ok-label="Back" --extra-button="Internal Storage" --extra-button="SD Card" --extra-button="Custom Location" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="$2")

  local rc=$?
  if [[ $rc == "0" ]] && [[ -z "$choice" ]]; then
    echo "Back"
  else
    echo $choice
  fi
}

configurator_reset_confirmation_dialog() {
  # This dialog provides a confirmation for any reset functions, before the reset is actually performed.
  # USAGE: $(configurator_reset_confirmation_dialog "emulator being reset" "action text")
  # This function will return a "true" if the user clicks Confirm, and "false" if they click Cancel.
  choice=$(zenity --title "RetroDECK Configurator Utility - Reset $1" --question --no-wrap --cancel-label="Cancel" --ok-label="Confirm" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="$2")
  if [[ $? == "0" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

configurator_move_folder_dialog() {
  # This dialog will take a folder variable name from retrodeck.cfg and move it to a new location. The variable will be updated in retrodeck.cfg as well as any emulator configs where it occurs.
  # USAGE: configurator_move_folder_dialog "folder_variable_name"
  local rd_dir_name="$1" # The folder variable name from retrodeck.cfg
  local dir_to_move="$(get_setting_value "$rd_conf" "$rd_dir_name" "retrodeck" "paths")/" # The path of that folder variable
  local source_root="$(echo $dir_to_move | sed -e 's/\(.*\)\/retrodeck\/.*/\1/')" # The root path of the folder, excluding retrodeck/<folder name>. So /home/deck/retrodeck/roms becomes /home/deck
  if [[ ! "$rd_dir_name" == "rdhome" ]]; then # If a sub-folder is being moved, find it's path without the source_root. So /home/deck/retrodeck/roms becomes retrodeck/roms
    local rd_dir_path="$(echo "$dir_to_move" | sed "s/.*\(retrodeck\/.*\)/\1/; s/\/$//")"
  else # Otherwise just set the retrodeck root folder
    local rd_dir_path="$(basename $dir_to_move)"
  fi

  if [[ -d "$dir_to_move" ]]; then # If the directory selected to move already exists at the expected location pulled from retrodeck.cfg
    choice=$(configurator_destination_choice_dialog "RetroDECK Data" "Please choose a destination for the $(basename $dir_to_move) folder.")
    case $choice in

    "Internal Storage" | "SD Card" | "Custom Location" ) # If the user picks a location
      if [[ "$choice" == "Internal Storage" ]]; then # If the user wants to move the folder to internal storage, set the destination target as HOME
        local dest_root="$HOME"
      elif [[ "$choice" == "SD Card" ]]; then # If the user wants to move the folder to the predefined SD card location, set the target as sdcard from retrodeck.cfg
        local dest_root="$sdcard"
      else
        configurator_generic_dialog "RetroDECK Configurator - Move Folder" "Select the parent folder you would like to store the $(basename $dir_to_move) folder in."
        local dest_root=$(directory_browse "RetroDECK directory location") # Set the destination root as the selected custom location
      fi

      if [[ (! -z "$dest_root") && ( -w "$dest_root") ]]; then # If user picked a destination and it is writable
        if [[ (-d "$dest_root/$rd_dir_path") && (! -L "$dest_root/$rd_dir_path") && (! $rd_dir_name == "rdhome") ]] || [[ "$(realpath $dir_to_move)" == "$dest_root/$rd_dir_path" ]]; then # If the user is trying to move the folder to where it already is (excluding symlinks that will be unlinked)
          configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The $(basename $dir_to_move) folder is already at that location, please pick a new one."
          configurator_move_folder_dialog "$rd_dir_name"
        else
          if [[ $(verify_space "$(echo $dir_to_move | sed 's/\/$//')" "$dest_root") ]]; then # Make sure there is enough space at the destination
            configurator_generic_dialog "RetroDECK Configurator - Move Folder" "Moving $(basename $dir_to_move) folder to $choice"
            unlink "$dest_root/$rd_dir_path" # In case there is already a symlink at the picked destination
            move "$dir_to_move" "$dest_root/$rd_dir_path"
            if [[ -d "$dest_root/$rd_dir_path" ]]; then # If the move succeeded
              eval "$rd_dir_name"="$dest_root/$rd_dir_path" # Set the new path for that folder variable in retrodeck.cfg
              if [[ "$rd_dir_name" == "rdhome" ]]; then # If the whole retrodeck folder was moved...
                prepare_emulator "postmove" "retrodeck"
              fi
              prepare_emulator "postmove" "all" # Update all the appropriate emulator path settings
              conf_write # Write the settings to retrodeck.cfg
              if [[ -z $(ls -1 "$source_root/retrodeck") ]]; then # Cleanup empty old_path/retrodeck folder if it was left behind
                rmdir "$source_root/retrodeck"
              fi
              configurator_process_complete_dialog "moving the RetroDECK data directory to internal storage"
            else
              configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The moving process was not completed, please try again."
            fi
          else # If there isn't enough space in the picked destination
            zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - Move Directories" \
            --text="The destination directory you have selected does not have enough free space for the files you are trying to move.\n\nPlease select a new destination or free up some space."
          fi
        fi
      else # If the user didn't pick any custom destination, or the destination picked is unwritable
        if [[ ! -z "$dest_root" ]]; then
          configurator_generic_dialog "RetroDECK Configurator - Move Folder" "No destination was chosen, so no files have been moved."
        else
          configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The chosen destination is not writable.\nNo files have been moved.\n\nThis can happen when trying to select a location that RetroDECK does not have permission to write.\nThis can normally be fixed by adding the desired path to the RetroDECK permissions with Flatseal."
        fi
      fi
    ;;

    esac
  else # The folder to move was not found at the path pulled from retrodeck.cfg and it needs to be reconfigured manually.
    configurator_generic_dialog "RetroDECK Configurator - Move Folder" "The $(basename $dir_to_move) folder was not found at the expected location.\n\nThis may have happened if the folder was moved manually.\n\nPlease select the current location of the folder."
    dir_to_move=$(directory_browse "RetroDECK $(basename $dir_to_move) directory location")
    eval "$rd_dir_name"="$dir_to_move"
    prepare_emulator "postmove" "all"
    conf_write
    configurator_generic_dialog "RetroDECK Configurator - Move Folder" "RetroDECK $(basename $dir_to_move) folder now configured at\n$dir_to_move."
    configurator_move_folder_dialog "$rd_dir_name"
  fi
}

changelog_dialog() {
  # This function will pull the changelog notes from the version it is passed (which must match the appdata version tag) from the net.retrodeck.retrodeck.appdata.xml file
  # The function also accepts "all" as a version, and will print the entire changelog
  # USAGE: changelog_dialog "version"

  if [[ "$1" == "all" ]]; then
    xmlstarlet sel -t -m "//release" -v "concat('RetroDECK version: ', @version)" -n -v "description" -n $rd_appdata | awk '{$1=$1;print}' | sed -e '/./b' -e :n -e 'N;s/\n$//;tn' > "/var/config/retrodeck/changelog.txt"

    zenity --icon-name=net.retrodeck.retrodeck --text-info --width=1200 --height=720 \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Changelogs" \
    --filename="/var/config/retrodeck/changelog.txt"
  else
    local version_changelog=$(xml sel -t -m "//release[@version='$1']/description" -v . -n $rd_appdata | tr -s '\n' | sed 's/^\s*//')

    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Changelogs" \
    --text="In RetroDECK version $1, the following changes were made:\n$version_changelog"
    fi
}

get_cheevos_token_dialog() {
  # This function will return a RetroAchvievements token from a valid username and password, will return "login failed" otherwise
  # USAGE: get_cheevos_token_dialog

  local cheevos_info=$(zenity --forms --title="Cheevos" \
  --text="Username and password." \
  --separator="^" \
  --add-entry="Username" \
  --add-password="Password")

  IFS='^' read -r cheevos_username cheevos_password < <(printf '%s\n' "$cheevos_info")
  cheevos_token=$(curl --silent --data "r=login&u=$cheevos_username&p=$cheevos_password" $RA_API_URL | jq .Token | tr -d '"')
  if [[ ! "$cheevos_token" == "null" ]]; then
    echo "$cheevos_username,$cheevos_token"
  else
    echo "failed"
  fi
}

change_preset_dialog() {
  # This function will build a list of all systems compatible with a given preset, their current enable/disabled state and allow the user to change one or more
  # USAGE: change_preset_dialog "$preset"

  local preset="$1"
  pretty_preset_name=${preset//_/ } # Preset name prettification
  pretty_preset_name=$(echo $pretty_preset_name | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))substr($i,2)}}1') # Preset name prettification
  local current_preset_settings=()
  local current_enabled_systems=()
  local current_disabled_systems=()
  local changed_systems=()
  local changed_presets=()
  local section_results=$(sed -n '/\['"$preset"'\]/, /\[/{ /\['"$preset"'\]/! { /\[/! p } }' $rd_conf | sed '/^$/d')

  while IFS= read -r config_line
    do
      system_name=$(get_setting_name "$config_line" "retrodeck")
      all_systems=("${all_systems[@]}" "$system_name")
      system_value=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$preset")
      if [[ "$system_value" == "true" ]]; then
        current_enabled_systems=("${current_enabled_systems[@]}" "$system_name")
      elif [[ "$system_value" == "false" ]]; then
        current_disabled_systems=("${current_disabled_systems[@]}" "$system_name")
      fi
      current_preset_settings=("${current_preset_settings[@]}" "$system_value" "$system_name")
  done < <(printf '%s\n' "$section_results")

  choice=$(zenity \
    --list --width=1200 --height=720 \
    --checklist \
    --separator="," \
    --text="Enable $pretty_preset_name:" \
    --column "Enabled" \
    --column "Emulator" \
    "${current_preset_settings[@]}")

  local rc=$?

  if [[ ! -z $choice || "$rc" == 0 ]]; then
    IFS="," read -ra choices <<< "$choice"
    for emulator in "${all_systems[@]}"; do
      if [[ " ${choices[*]} " =~ " ${emulator} " && ! " ${current_enabled_systems[*]} " =~ " ${emulator} " ]]; then
        changed_systems=("${changed_systems[@]}" "$emulator")
        if [[ ! " ${changed_presets[*]} " =~ " ${preset} " ]]; then
          changed_presets=("${changed_presets[@]}" "$preset")
        fi
        set_setting_value "$rd_conf" "$emulator" "true" "retrodeck" "$preset"
        # Check for conflicting presets for this system
        while IFS=: read -r preset_being_checked known_incompatible_preset; do
          if [[ "$preset" == "$preset_being_checked" ]]; then
            if [[ $(get_setting_value "$rd_conf" "$emulator" "retrodeck" "$known_incompatible_preset") == "true" ]]; then
              changed_presets=("${changed_presets[@]}" "$known_incompatible_preset")
              set_setting_value "$rd_conf" "$emulator" "false" "retrodeck" "$known_incompatible_preset"
            fi
          fi
        done < "$incompatible_presets_reference_list"
      fi
      if [[ ! " ${choices[*]} " =~ " ${emulator} " && ! " ${current_disabled_systems[*]} " =~ " ${emulator} " ]]; then
        changed_systems=("${changed_systems[@]}" "$emulator")
        if [[ ! " ${changed_presets[*]} " =~ " ${preset} " ]]; then
          changed_presets=("${changed_presets[@]}" "$preset")
        fi
        set_setting_value "$rd_conf" "$emulator" "false" "retrodeck" "$preset"
      fi
    done
    for emulator in "${changed_systems[@]}"; do
      build_preset_config $emulator ${changed_presets[*]}
    done
  else
    echo "No choices made"
  fi
}
