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

  if [[ ! -d "$2/$(basename "$1")" ]]; then
    if [[ $(verify_space "$1" "$2") ]]; then
      (
        if [[ ! -d "$2" ]]; then # Create destination directory if it doesn't already exist
          mkdir -pv "$2"
        fi
        mv -v -t "$2" "$1"
      ) |
      zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Move in Progress" \
      --text="Moving directory $(basename "$1") to new location of $2, please wait."
    else
      zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Move Directories" \
      --text="The destination directory you have selected does not have enough free space for the files you are trying to move.\n\nPlease select a new destination or free up some space."

      configurator_move_dialog
    fi
  else
    zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility - Move Directories" \
    --text="The destination directory you have selected already exists.\n\nPlease select a new destination."
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
          set_setting_value $rd_conf "desktop_mode_warning" "false" retrodeck  "options" # Store desktop mode warning variable for future checks
        fi
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
        sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"'.*^s^\^'"$setting_name_to_change"'=.*^'"$setting_name_to_change"'='"$setting_value_to_change"'^' $1
      fi
      ;;

    "retroarch" )
      if [[ -z $current_section_name ]]; then
        sed -i 's^\^'"$setting_name_to_change"' = \".*\"^'"$setting_name_to_change"' = \"'"$setting_value_to_change"'\"^' $1
      else
        sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"'.*^s^\^'"$setting_name_to_change"' = \".*\"^'"$setting_name_to_change"' = \"'"$setting_value_to_change"'\"^' $1
      fi
      ;;

    "dolphin" | "duckstation" | "pcsx2" | "ppsspp" | "primehack" | "xemu" )
      if [[ -z $current_section_name ]]; then
        sed -i 's^\^'"$setting_name_to_change"' =.*^'"$setting_name_to_change"' = '"$setting_value_to_change"'^' $1
      else
        sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"'.*^s^\^'"$setting_name_to_change"' =.*^'"$setting_name_to_change"' = '"$setting_value_to_change"'^' $1
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

add_setting() {
  # This function will add a setting line to a file. This is useful for dynamically generated config files where a setting line may not exist until the setting is changed from the default.
  # USAGE: add_setting $setting_file $setting_line $system $section (optional)

  local current_setting_line=$(sed -e 's^\\^\\\\^g;s^`^\\`^g' <<< "$2")
  local current_section_name=$(sed -e 's/%/\\%/g' <<< "$4")

  case $3 in

  * )
    if [[ -z $current_section_name ]]; then
      sed -i '$ a '"$current_setting_line"'' $1
    else
      sed -i '/^\s*?\['"$current_section_name"'\]|\b'"$current_section_name"':$/a '"$current_setting_line"'' $1
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

generate_single_patch() {
  # generate_single_patch $original_file $modified_file $patch_file $system

  rm $3 # Remove old patch file (maybe change this to create a backup instead?)

  while read -r current_setting_line; # Look for changes from the original file to the modified one
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
      elif [[ (! -z $current_section) ]]; then # If line is in a section...
        if [[ ! -z $(grep -o -P "^\s*?#.*?$" <<< "$current_setting_line") ]]; then # Check for disabled lines
          if [[ -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\s*?'"$(sed -E 's/^[ \t]*//;' <<< "$escaped_setting_line")"'^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\s*?'"$(sed -E 's/^[ \t]*//' <<< "$escaped_setting_line")"'^ p } }' $2) ]]; then # If disabled line is not disabled in new file...
          action="disable_setting"
          echo $action"^"$current_section"^"$(sed -n -E 's^\s*?#(.*?)$^\1^p' <<< $(sed -E 's/^[ \t]*//' <<< "$current_setting_line")) >> $3
          fi
        elif [[ ! -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\s*?#'"$(sed -E 's/^[ \t]*//' <<< "$escaped_setting_line")"'^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\s*?#'"$(sed -E 's/^[ \t]*//;' <<< "$escaped_setting_line")"'^ p } }' $2) ]]; then # Check if line is disabled in new file
          action="enable_setting"
          echo $action"^"$current_section"^"$current_setting_line >> $3
        else # Look for setting value differences
          current_setting_name=$(get_setting_name "$escaped_setting_line" $4)
          if [[ (-z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\b'"$current_setting_name"'.*^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\b'"$(sed -E 's/^[ \t]*//;' <<< "$escaped_setting_line")"'$^ p } }' $2)) ]]; then # If the same setting line is not found in the same section of the modified file...
            if [[ ! -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\b'"$current_setting_name"'^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\b'"$current_setting_name"'^ p } }' $2) ]]; then # But the setting exists in that section, only with a different value...
              new_setting_value=$(get_setting_value $2 "$current_setting_name" $4 $current_section)
              action="change"
              echo $action"^"$current_section"^"$(sed -e 's%\\\\%\\%g' <<< "$current_setting_name")"^"$new_setting_value"^"$4 >> $3
            fi
          fi
        fi
      elif [[ (-z $current_section) ]]; then # If line is not in a section...
        if [[ ! -z $(grep -o -P "^\s*?#.*?$" <<< "$current_setting_line") ]]; then # Check for disabled lines
          if [[ -z $(grep -o -P "^\s*?$current_setting_line$" $2) ]]; then # If disabled line is not disabled in new file...
            action="disable_setting"
            echo $action"^"$current_section"^"$(sed -n -E 's^\s*?#(.*?)$^\1^p' <<< "$current_setting_line") >> $3
          fi
        elif [[ ! -z $(sed -n -E '\^\s*?#'"$(sed -E 's/^[ \t]*//' <<< "$escaped_setting_line")"'$^p' $2) ]]; then # Check if line is disabled in new file
            action="enable_setting"
            echo $action"^"$current_section"^"$current_setting_line >> $3
        else # Look for setting value differences
          if [[ (-z $(sed -n -E '\^\s*?\b'"$(sed -E 's/^[ \t]*//' <<< "$escaped_setting_line")"'$^p' $2)) ]]; then # If the same setting line is not found in the modified file...
            current_setting_name=$(get_setting_name "$escaped_setting_line" "$4")
            if [[ ! -z $(sed -n -E '\^\s*?\b'"$current_setting_name"'\s*?[:=]^p' $2) ]]; then # But the setting exists, only with a different value...
              new_setting_value=$(get_setting_value $2 "$current_setting_name" $4)
              action="change"
              echo $action"^"$current_section"^"$(sed -e 's%\\\\%\\%g' <<< "$current_setting_name")"^"$new_setting_value"^"$4 >> $3
            fi
          fi
        fi
      fi
    fi
  done < $1

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
        echo "Section found:" "$current_section""."
      elif [[ ! -z $(grep -o -P "^\b.+?:$" <<< "$current_setting_line") ]]; then # If RPCS3 section name
        action="section"
        current_section=$(sed 's^:$^^' <<< $current_setting_line) # Remove colon from section name
        echo "Section found:" "$current_section""."
      fi
      elif [[ (! -z $current_section) ]]; then
        current_setting_name=$(get_setting_name "$escaped_setting_line" "$4")
        if [[ -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\b'"$current_setting_name"'.*^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\b'"$current_setting_name"'^p } }' $1 ) ]]; then # If setting name is not found in this section of the original file...
          action="add_setting"
          echo $action"^"$current_section"^"$current_setting_line"^^"$4 >> $3
        fi
      elif [[ (-z $current_section) ]]; then
        current_setting_name=$(get_setting_name "$escaped_setting_line" "$4")
        if [[ -z $(sed -n -E '\^\s*?\b'"$current_setting_name"'\s*?[:=]^p' $1) ]]; then # If setting name is not found in the original file...
          action="add_setting"
          echo $action"^"$current_section"^"$current_setting_line"^^"$4 >> $3
        fi
      fi
    fi
  done < $2
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

	"add_setting" )
    eval add_setting $3 "$setting_name" $system_name $current_section
	;;

	"disable_setting" )
    eval disable_setting $3 "$setting_name" $system_name $current_section
	;;

	"enable_setting" )
    eval enable_setting $3 "$setting_name" $system_name $current_section
	;;

	"change" )
    eval set_setting_value $3 "$setting_name" "$setting_value" $system_name $current_section
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
    eval disable_file "$config_file"
	;;

	"enable_file" )
    eval enable_file "$config_file"
	;;

	"add_setting" )
    eval add_setting "$config_file" "$setting_name" $system_name $current_section
	;;

	"disable_setting" )
    eval disable_setting "$config_file" "$setting_name" $system_name $current_section
	;;

	"enable_setting" )
    eval enable_setting "$config_file" "$setting_name" $system_name $current_section
	;;

	"change" )
    eval set_setting_value "$config_file" "$setting_name" "$setting_value" $system_name $current_section
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
        --text="There is a new version of RetroDECK available!\n\nIf you would like to update to the new version now, click \"Yes\". If you would like to skip reminders about this version, click \"Ignore this version\".\nYou will be reminded again at the next version update.\n\nIf you would like to disable these update notifications entirely, disable Online Update Checks in the Configurator.")
      rc=$? # Capture return code, as "Yes" button has no text value
      if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
        if [[ $choice == "Ignore this version" ]]; then
          set_setting_value $rd_conf "update_ignore" "$online_version" retrodeck "options" # Store version to ignore for future checks
        fi
      else # User clicked "Yes"
        configurator_generic_dialog "The update process may take several minutes.\n\nAfter the update is complete, RetroDECK will close. When you run it again you will be using the latest version."
        flatpak-spawn --host flatpak update --noninteractive -y net.retrodeck.retrodeck
        exit 1
      fi
    elif [[ "$update_repo" == "RetroDECK-cooker" ]] && [[ ! $current_version == $online_version ]]; then
      choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Ignore this version" \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Update Available" \
        --text="There is a more recent build of the RetroDECK cooker branch.\n\nWould you like to update to it?\nIf you would like to skip reminders about this version, click \"Ignore this version\".\nYou will be reminded again at the next version update.\n\nIf you would like to disable these update notifications entirely, disable Online Update Checks in the Configurator.")
      rc=$? # Capture return code, as "Yes" button has no text value
      if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
        if [[ $choice == "Ignore this version" ]]; then
          set_setting_value $rd_conf "update_ignore" "$online_version" retrodeck "options" # Store version to ignore for future checks.
        fi
      else # User clicked "Yes"
        configurator_generic_dialog "The update process may take several minutes.\n\nAfter the update is complete, RetroDECK will close. When you run it again you will be using the latest version."
        local latest_cooker_download=$(curl --silent https://api.github.com/repos/XargonWan/$update_repo/releases/latest | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')
        mkdir -p "$rdhome/RetroDECK_Updates"
        wget -P "$rdhome/RetroDECK_Updates" $latest_cooker_download
        flatpak-spawn --host flatpak install --user --bundle --noninteractive -y "$rdhome/RetroDECK_Updates/RetroDECK.flatpak"
        rm -f "$rdhome/RetroDECK_Updates" # Cleanup old bundles to save space
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

  conf_read # Read current settings into memory
  mv -f $rd_conf $rd_conf_backup # Backup config file before update
  cp $rd_defaults $rd_conf # Copy defaults file into place
  conf_write # Write old values into new default file
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
    configurator_generic_dialog "The Steam username of the current user could not be determined from the system.\n\nThis can happen when running in Desktop mode.\n\nYou will be asked to specify the Steam username (not profile name) of the current user in the next dialog."
  fi
  if [[ -d "$multi_user_data_folder" && $(ls -1 "$multi_user_data_folder" | wc -l) -gt 0 ]]; then # If multi-user data folder exists from prior use and is not empty
    if [[ -d "$multi_user_data_folder/$SteamAppUser" ]]; then # Current user has an existing save folder
      configurator_generic_dialog "The current user $SteamAppUser has an existing folder in the multi-user data folder.\n\nThe saves here are likely older than the ones currently used by RetroDECK.\n\nThe old saves will be backed up to $backups_folder and the current saves will be loaded into the multi-user data folder."
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
    configurator_generic_dialog "It looks like something went wrong while enabling multi-user mode."
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
      configurator_generic_dialog "No single user was selected, please try the process again."
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
            configurator_generic_dialog "The current user could not be determined from the system, and there are multiple users registered.\n\nPlease select which user is currently playing in the next dialog."
            SteamAppUser=$(multi_user_choose_current_user_dialog)
            if [[ ! -z $SteamAppUser ]]; then # User was chosen from dialog
              multi_user_link_current_user_files
            else
              configurator_generic_dialog "No user was chosen, RetroDECK will launch with the files from the user who played most recently."
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
        configurator_generic_dialog "The current user could not be determined from the system and there is no existing userlist.\n\nPlease enter the Steam account username (not profile name) into the next dialog, or run RetroDECK in game mode."
        if zenity --entry \
          --title="Specify Steam username" \
          --text="Enter Steam username:"
        then # User clicked "OK"
          SteamAppUser="$?"
          if [[ ! -z "$SteamAppUser" ]]; then
            multi_user_setup_new_user
          else # But dialog box was blank
            configurator_generic_dialog "No username was entered, so multi-user data folder cannot be created.\n\nDisabling multi-user mode, please try the process again."
            set_setting_value $rd_conf "multi_user_mode" "false" retrodeck "options"
          fi
        else # User clicked "Cancel"
          configurator_generic_dialog "Cancelling multi-user mode activation."
          set_setting_value $rd_conf "multi_user_mode" "false" retrodeck "options"
        fi
      fi
    fi
  else
    configurator_generic_dialog "Multi-user mode is not currently enabled"
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
        current_section=$(sed 's^[][]^^g' <<< $current_setting_line) # Remove brackets from section name
      else
        current_setting_name=$(get_setting_name "$current_setting_line" "retrodeck") # Read the variable name from the current line
        current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "$current_section") # Read the variables value from retrodeck.cfg
        memory_setting_value=$(eval "echo \$${current_setting_name}") # Read the variable names' value from memory
        if [[ ! "$current_setting_value" == "$memory_setting_value" ]]; then # If the values are different...
          set_setting_value "$rd_conf" "$current_setting_name" "$memory_setting_value" "retrodeck" "$current_section" # Update the value in retrodeck.cfg
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
        current_section=$(sed 's^[][]^^g' <<< $current_setting_line) # Remove brackets from section name
      else
        local current_setting_name=$(get_setting_name "$current_setting_line" "retrodeck") # Read the variable name from the current line
        local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "$current_section") # Read the variables value from retrodeck.cfg
        eval "$current_setting_name=$current_setting_value" # Write the current setting name and value to memory
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

consolidate_retrodeck_folders() {
  # This script will find folders that may have been moved out of the main RetroDECK folder individually and move them home
  # USAGE: consolidate_retrodeck_folders

  while read -r path; do
  if realpath "$path" | grep -q "^$main_path/"; then
    echo "$path is a subfolder of $main_path"
  else
    echo "$path is not a subfolder of $main_path"
  fi
  done < <(grep -v '^\s*$' $rd_conf | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f')
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

  if [[ "$emulator" == "retrodeck" ]]; then # For use after RetroDECK is consolidated and moved
    if [[ "$action" == "postmove" ]]; then
      roms_folder=$rdhome/roms
      saves_folder=$rdhome/saves
      states_folder=$rdhome/states
      bios_folder=$rdhome/bios
      media_folder=$rdhome/downloaded_media
      themes_folder=$rdhome/themes
      logs_folder=$rdhome/.logs
      screenshots_folder=$rdhome/screenshots
      mods_folder=$rdhome/mods
      texture_packs_folder=$rdhome/texture_packs
      borders_folder=$rdhome/borders
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
          cp -rf $emuconfigs/retroarch/core-overrides/* /var/config/retroarch/config
          dir_prep "$borders_folder" "/var/config/retroarch/borders"
          cp -rt "/var/config/retroarch/borders/" "/app/retrodeck/emu-configs/retroarch/borders/*"
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
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$rdhome/bios/citra/sysdata" "/var/data/citra-emu/sysdata"
      dir_prep "$rdhome/.logs/citra" "/var/data/citra-emu/log"
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
        cp -fvr $emuconfigs/dolphin/* "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/"
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
      dir_prep "$saves_folder/gc/dolphin/EUR" "/var/data/dolphin-emu/GC/EUR" # TODO: Multi-user one-off
      dir_prep "$saves_folder/gc/dolphin/USA" "/var/data/dolphin-emu/GC/USA" # TODO: Multi-user one-off
      dir_prep "$saves_folder/gc/dolphin/JAP" "/var/data/dolphin-emu/GC/JAP" # TODO: Multi-user one-off
      dir_prep "$screenshots_folder" "/var/data/dolphin-emu/ScreenShots"
      dir_prep "$states_folder/dolphin" "/var/data/dolphin-emu/StateSaves"
      dir_prep "$saves_folder/wii/dolphin" "/var/data/dolphin-emu/Wii" 
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$saves_folder/gc/dolphin/EUR" "/var/data/dolphin-emu/GC/EUR"
      dir_prep "$saves_folder/gc/dolphin/USA" "/var/data/dolphin-emu/GC/USA"
      dir_prep "$saves_folder/gc/dolphin/JAP" "/var/data/dolphin-emu/GC/JAP"
      dir_prep "$screenshots_folder" "/var/data/dolphin-emu/ScreenShots"
      dir_prep "$states_folder/dolphin" "/var/data/dolphin-emu/StateSaves"
      dir_prep "$saves_folder/wii/dolphin" "/var/data/dolphin-emu/Wii" 
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
        cp -fv $emuconfigs/duckstation/* "$multi_user_data_folder/$SteamAppUser/data/duckstation"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "SearchDirectory" "$bios_folder" "duckstation" "BIOS"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "Card1Path" "$saves_folder/duckstation/shared_card_1.mcd" "duckstation" "MemoryCards"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "Card2Path" "$saves_folder/duckstation/shared_card_2.mcd" "duckstation" "MemoryCards"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "Directory" "$saves_folder/duckstation" "duckstation" "MemoryCards"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/duckstation" "/var/config/duckstation"
      else # Single-user actions
        rm -rf /var/config/duckstation
        mkdir -p /var/data/duckstation/
        cp -fv $emuconfigs/duckstation/* /var/data/duckstation
        set_setting_value "$duckstationconf" "SearchDirectory" "$bios_folder" "duckstation" "BIOS"
        set_setting_value "$duckstationconf" "Card1Path" "$saves_folder/duckstation/shared_card_1.mcd" "duckstation" "MemoryCards"
        set_setting_value "$duckstationconf" "Card2Path" "$saves_folder/duckstation/shared_card_2.mcd" "duckstation" "MemoryCards"
        set_setting_value "$duckstationconf" "Directory" "$saves_folder/duckstation" "duckstation" "MemoryCards"
      fi
      dir_prep "$saves_folder/duckstation" "/var/data/duckstation/memcards" # TODO: This shouldn't be needed anymore, verify
      dir_prep "$states_folder/duckstation" "/var/data/duckstation/savestates" # TODO: This shouldn't be needed anymore, verify
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      set_setting_value "$duckstationconf" "SearchDirectory" "$bios_folder" "duckstation" "BIOS"
      set_setting_value "$duckstationconf" "Card1Path" "$saves_folder/duckstation/shared_card_1.mcd" "duckstation" "MemoryCards"
      set_setting_value "$duckstationconf" "Card2Path" "$saves_folder/duckstation/shared_card_2.mcd" "duckstation" "MemoryCards"
      set_setting_value "$duckstationconf" "Directory" "$saves_folder/duckstation" "duckstation" "MemoryCards"
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
        cp -fvr $emuconfigs/PCSX2/* "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "Bios" "$bios_folder" "pcsx2" "Folders"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "Snapshots" "$screenshots_folder" "pcsx2" "Folders"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "SaveStates" "$states_folder/ps2/pcsx2" "pcsx2" "Folders"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "MemoryCards" "$saves_folder/ps2/pcsx2/memcards" "pcsx2" "Folders"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "RecursivePaths" "$roms_folder/ps2" "pcsx2" "GameList"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/PCSX2" "/var/config/PCSX2"
      else # Single-user actions
        rm -rf /var/config/PCSX2
        mkdir -pv "/var/config/PCSX2/inis"
        cp -fvr $emuconfigs/PCSX2/* /var/config/PCSX2/inis/
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
  
  if [[ "$emulator" =~ ^(ppsspp|PPSSPP|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "------------------------"
      echo "Initializing PPSSPPSDL"
      echo "------------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/ppsspp"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/ppsspp/PSP/SYSTEM/"
        cp -fv $emuconfigs/ppssppsdl/* "$multi_user_data_folder/$SteamAppUser/config/ppsspp/PSP/SYSTEM/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/ppsspp/PSP/SYSTEM/ppsspp.ini" "CurrentDirectory" "$roms_folder/psp" "ppsspp" "General"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/ppsspp" "/var/config/ppsspp"
      else # Single-user actions
        rm -rf /var/config/ppsspp
        mkdir -p /var/config/ppsspp/PSP/SYSTEM/
        cp -fv $emuconfigs/ppssppsdl/* /var/config/ppsspp/PSP/SYSTEM/
        set_setting_value "$ppssppconf" "CurrentDirectory" "$roms_folder/psp" "ppsspp" "General"
      fi
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      set_setting_value "$ppssppconf" "CurrentDirectory" "$roms_folder/psp" "ppsspp" "General"
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
        cp -fvr $emuconfigs/primehack/* "$multi_user_data_folder/$SteamAppUser/config/primehack/"
        set_setting_value ""$multi_user_data_folder/$SteamAppUser/config/primehack/Dolphin.ini"" "ISOPath0" "$roms_folder/gc" "primehack" "General"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/primehack" "/var/config/primehack"
      else # Single-user actions
        rm -rf /var/config/primehack
        mkdir -pv /var/config/primehack/
        cp -fvr "$emuconfigs/primehack/"* /var/config/primehack/
        set_setting_value "$primehackconf" "ISOPath0" "$roms_folder/gc" "primehack" "General"
      fi
      # Shared actions
      dir_prep "$saves_folder/gc/primehack/EUR" "/var/data/primehack/GC/EUR"
      dir_prep "$saves_folder/gc/primehack/USA" "/var/data/primehack/GC/USA"
      dir_prep "$saves_folder/gc/primehack/JAP" "/var/data/primehack/GC/JAP"
      dir_prep "$screenshots_folder" "/var/data/primehack/ScreenShots"
      dir_prep "$states_folder/primehack" "/var/data/primehack/StateSaves"
      mkdir -pv /var/data/primehack/Wii/
      dir_prep "$saves_folder/wii/primehack" "/var/data/primehack/Wii"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$saves_folder/gc/primehack/EUR" "/var/data/primehack/GC/EUR"
      dir_prep "$saves_folder/gc/primehack/USA" "/var/data/primehack/GC/USA"
      dir_prep "$saves_folder/gc/primehack/JAP" "/var/data/primehack/GC/JAP"
      dir_prep "$screenshots_folder" "/var/data/primehack/ScreenShots"
      dir_prep "$states_folder/primehack" "/var/data/primehack/StateSaves"
      dir_prep "$saves_folder/wii/primehack" "/var/data/primehack/Wii/"
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
        cp -fr $emuconfigs/rpcs3/* "$multi_user_data_folder/$SteamAppUser/config/rpcs3/"
        # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
        sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_folder/rpcs3"'^' "$multi_user_data_folder/$SteamAppUser/config/rpcs3/vfs.yml"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/rpcs3/vfs.yml" "/games/" "$roms_folder/ps3" "rpcs3"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/rpcs3" "/var/config/rpcs3"
      else # Single-user actions
        rm -rf /var/config/rpcs3
        mkdir -pv /var/config/rpcs3/
        cp -fr $emuconfigs/rpcs3/* /var/config/rpcs3/
        # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
        sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_folder/rpcs3"'^' "$rpcs3vfsconf"
        set_setting_value "$rpcs3vfsconf" "/games/" "$roms_folder/ps3" "rpcs3"
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
        cp -fvr $emuconfigs/yuzu/* "$multi_user_data_folder/$SteamAppUser/config/yuzu/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "nand_directory" "$saves_folder/switch/yuzu/nand" "yuzu" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "sdmc_directory" "$saves_folder/switch/yuzu/sdmc" "yuzu" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "Paths\gamedirs\4\path" "$roms_folder/switch" "yuzu" "UI"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "Screenshots\screenshot_path" "$screenshots_folder" "yuzu" "UI"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/yuzu" "/var/config/yuzu"
      else # Single-user actions
        rm -rf /var/config/yuzu
        mkdir -pv /var/config/yuzu/
        cp -fvr $emuconfigs/yuzu/* /var/config/yuzu/
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
      set_setting_value "$yuzuconf" "nand_directory" "$saves_folder/switch/yuzu/nand" "yuzu" "Data%20Storage"
      set_setting_value "$yuzuconf" "sdmc_directory" "$saves_folder/switch/yuzu/sdmc" "yuzu" "Data%20Storage"
      set_setting_value "$yuzuconf" "Paths\gamedirs\4\path" "$roms_folder/switch" "yuzu" "UI"
      set_setting_value "$yuzuconf" "Screenshots\screenshot_path" "$screenshots_folder" "yuzu" "UI"
    fi
  fi
}

update_rpcs3_firmware() {
  mkdir -p "$roms_folder/ps3/tmp"
  chmod 777 "$roms_folder/ps3/tmp"
  wget "$rpcs3_firmware" -P "$roms_folder/ps3/tmp/"
  rpcs3 --installfw "$roms_folder/ps3/tmp/PS3UPDAT.PUP"
  rm -rf "$roms_folder/ps3/tmp"
}

backup_retrodeck_userdata() {
  zip -rq9 "$backups_folder/$(date +"%0m%0d")_retrodeck_userdata.zip" "$saves_folder" "$states_folder" "$bios_folder" "$media_folder" "$themes_folder" "$logs_folder" "$screenshots_folder" "$mods_folder" "$texture_packs_folder" "$borders_folder" > $logs_folder/$(date +"%0m%0d")_backup_log.log
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

tools_init() {
  mkdir -pv /var/config/emulationstation/.emulationstation/gamelists/tools/
  cp -fv /app/retrodeck/tools-gamelist.xml /var/config/emulationstation/.emulationstation/gamelists/tools/gamelist.xml
}

start_retrodeck() {
  echo "Checking to see if today has a surprise..."
  easter_eggs
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

finit() {
# Force/First init, depending on the situation

  echo "Executing finit"

  # Internal or SD Card?
  choice=$(configurator_destination_choice_dialog "RetroDECK data" "Welcome to the first configuration of RetroDECK.\nThe setup will be quick but please READ CAREFULLY each message in order to avoid misconfigurations.\n\nWhere do you want your RetroDECK data folder to be located?\n\nThis folder will contain all ROMs, BIOSs and scraped data." )
  echo "Choice is $choice"

  case $choice in

  "" ) # Cancel or X button quits
    echo "Now quitting"
    exit 2
  ;;

  "Internal Storage" ) # Internal
    echo "Internal selected"
    rdhome="$HOME/retrodeck"
    roms_folder="$rdhome/roms"
    saves_folder="$rdhome/saves"
    states_folder="$rdhome/states"
    bios_folder="$rdhome/bios"
    media_folder="$rdhome/downloaded_media"
    themes_folder="$rdhome/themes"
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
        exit 2
      fi
      roms_folder="$rdhome/roms"
      saves_folder="$rdhome/saves"
      states_folder="$rdhome/states"
      bios_folder="$rdhome/bios"
      media_folder="$rdhome/downloaded_media"
      themes_folder="$rdhome/themes"
    elif [ ! -w "$sdcard" ] #SD card found but not writable
      then
        echo "Error: SD card found but not writable"
        zenity --error --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK" \
        --ok-label "Quit" \
        --text="SD card was found but is not writable\nThis can happen with cards formatted on PC.\nPlease format the SD card through the Steam Deck's Game Mode and run RetroDECK again."
        echo "Now quitting"
        exit 2
    else
      rdhome="$sdcard/retrodeck"
      roms_folder="$rdhome/roms"
      saves_folder="$rdhome/saves"
      states_folder="$rdhome/states"
      bios_folder="$rdhome/bios"
      media_folder="$rdhome/downloaded_media"
      themes_folder="$rdhome/themes"
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
        exit 2
      fi
      roms_folder="$rdhome/roms"
      saves_folder="$rdhome/saves"
      states_folder="$rdhome/states"
      bios_folder="$rdhome/bios"
      media_folder="$rdhome/downloaded_media"
      themes_folder="$rdhome/themes"
    ;;

  esac

  if [[ ! "$rdhome" == "$HOME/retrodeck" && ! -L $HOME/retrodeck ]]; then # If data stored on SD card, create /home/deck/retrodeck symlink to keep things working until configs can get modified
    echo "Symlinking retrodeck directory to home directory"
    dir_prep "$rdhome" "$HOME/retrodeck"
  fi

  mkdir -pv $roms_folder

  local rpcs_firmware_install=$(configurator_generic_question_dialog "RPCS3 Firmware Install" "Would you like to install the latest PS3 firmware for the RPCS3 emulator?\n\nThis process will take several minutes and requires network access.\nIf you do not plan to emulate PS3 games this can be skipped, and can always be done later through the Configurator.\n\nIf you click Yes, RPCS3 will be launched at the end of the RetroDECK setup process.\nOnce the firmware is installed, please close the emulator to finish the process.")

  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" \
  --text="RetroDECK will now install the needed files, which can take up to one minute.\nRetroDECK will start once the process is completed.\n\nPress OK to continue."

  (
  # Recreating the folder
  rm -rf /var/config/emulationstation/
  mkdir -p /var/config/emulationstation/

  # Initializing ES-DE
  # TODO: after the next update of ES-DE this will not be needed - let's test it
  emulationstation --home /var/config/emulationstation --create-system-dirs
  update_splashscreens

  # Initializing ROMs folder - Original in retrodeck home (or SD Card)
  dir_prep $roms_folder "/var/config/emulationstation/ROMs"

  mkdir -pv $saves_folder
  mkdir -pv $states_folder
  mkdir -pv $screenshots_folder
  mkdir -pv $logs_folder
  mkdir -pv $mods_folder
  mkdir -pv $texture_packs_folder

  # XMLSTARLET HERE
  cp -fv /app/retrodeck/es_settings.xml /var/config/emulationstation/.emulationstation/es_settings.xml

  # ES-DE preparing user-exposed folders
  dir_prep "$media_folder" "/var/config/emulationstation/.emulationstation/downloaded_media"
  dir_prep "$themes_folder" "/var/config/emulationstation/.emulationstation/themes"
  dir_prep "$rdhome/gamelists" "/var/config/emulationstation/.emulationstation/gamelists"

  # PICO-8
  dir_prep "$bios_folder/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
  dir_prep "$roms_folder/pico8" "$bios_folder/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
  dir_prep "$saves_folder/pico-8" "$bios_folder/pico-8/cdata"  # PICO-8 saves folder

  # Add packaged extras, after the ROMS folder has been initialized
  cp /app/retrodeck/extras/doom1.wad "$roms_folder/doom/doom1.wad" # No -f in case the user already has it

  # RetroDECK prepack metadata
  mkdir -p "/var/config/emulationstation/.emulationstation/gamelists/doom"
  cp "/app/retrodeck/rd_prepacks/doom/gamelist.xml" "/var/config/emulationstation/.emulationstation/gamelists/doom/gamelist.xml"
  mkdir -p "$media_folder/doom"
  unzip -oq "/app/retrodeck/rd_prepacks/doom/doom.zip" -d "$media_folder/doom/"

  tools_init
  prepare_emulator "reset" "all"
  if [[ $rpcs_firmware_install == "true" ]]; then
    update_rpcs3_firmware
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
  # USAGE: configurator_generic_dialog "info text"
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility" \
  --text="$1"
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
