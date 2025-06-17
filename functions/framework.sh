#!/bin/bash

set_setting_value() {
  # Function for editing settings
  # USAGE: set_setting_value "$setting_file" "$setting_name" "$new_setting_value" "$system" "$section_name(optional)"

  local setting_name_to_change=$(sed -e 's^\\^\\\\^g;s^`^\\`^g' <<< "$2")
  local setting_value_to_change=$(sed -e 's^\\^\\\\^g;s^`^\\`^g' <<< "$3")
  local current_section_name=$(sed -e 's/%/\\%/g' <<< "$5")

  log d "Setting $setting_name_to_change=$setting_value_to_change in $1"
  if [[ ! -f "$1" ]]; then
    log e "File $1 does not exist, cannot set setting $setting_name_to_change"
    return 1
  fi

  case $4 in

    "retrodeck")
      if [[ -z "$current_section_name" ]]; then
        if head -n 1 "$rd_conf" | grep -qE '^\s*\{\s*$'; then # If retrodeck.cfg is new JSON format
          jq --arg setting "$setting_name_to_change" --arg newval "$setting_value_to_change" '.[$setting] = $newval' "$1" > "$1".tmp.json && mv "$1".tmp.json "$1"
        else
          sed -i 's^\^'"$setting_name_to_change"'=.*^'"$setting_name_to_change"'='"$setting_value_to_change"'^' "$1"
        fi
      else
        if head -n 1 "$rd_conf" | grep -qE '^\s*\{\s*$'; then # If retrodeck.cfg is new JSON format
          if jq -e --arg section "$current_section_name" '.presets | has($section)' "$rd_conf" > /dev/null; then # If the section is a preset
            parent_key=$(jq -r --arg section "$current_section_name" --arg setting "$setting_name_to_change" '
                        .presets[$section]
                        | paths(scalars)
                        | select(.[-1] == $setting)
                        | if length > 1 then .[-2] else $section end
                        ' "$1") # Find parent key of supplied setting name, in case it is nested
            if [[ "$current_section_name" == "$parent_key" ]]; then # Setting is not nested
              jq --arg section "$current_section_name" --arg setting "$setting_name_to_change" --arg newval "$setting_value_to_change" '.presets[$section][$setting] = $newval' "$1" > "$1".tmp.json && mv "$1".tmp.json "$1"
            else
              jq --arg section "$current_section_name" --arg parent "$parent_key" --arg setting "$setting_name_to_change" --arg newval "$setting_value_to_change" '.presets[$section][$parent][$setting] = $newval' "$1" > "$1".tmp.json && mv "$1".tmp.json "$1"
            fi
          else
            jq --arg section "$current_section_name" --arg setting "$setting_name_to_change" --arg newval "$setting_value_to_change" '.[$section][$setting] = $newval' "$1" > "$1".tmp.json && mv "$1".tmp.json "$1"
          fi
        else
          sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"'=^s^\^'"$setting_name_to_change"'=.*^'"$setting_name_to_change"'='"$setting_value_to_change"'^' "$1"
        fi
      fi
      if [[ "$current_section_name" == "" || "$current_section_name" == "paths" || "$current_section_name" == "options" ]]; then
        log d "Exporting value of setting $setting_name_to_change as $setting_value_to_change"
        declare -g "$setting_name_to_change=$setting_value_to_change"
      fi
    ;;

    "melonds" | "yuzu" | "citra" | "libretro_scummvm" )
      if [[ -z $current_section_name ]]; then
        sed -i 's^\^'"$setting_name_to_change"'=.*^'"$setting_name_to_change"'='"$setting_value_to_change"'^' "$1"
      else
        sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"'=^s^\^'"$setting_name_to_change"'=.*^'"$setting_name_to_change"'='"$setting_value_to_change"'^' "$1"
      fi
    ;;

    "retroarch" )
      if [[ -z $current_section_name ]]; then
        sed -i 's^\^'"$setting_name_to_change"' = \".*\"^'"$setting_name_to_change"' = \"'"$setting_value_to_change"'\"^' "$1"
      else
        sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"' = ^s^\^'"$setting_name_to_change"' = \".*\"^'"$setting_name_to_change"' = \"'"$setting_value_to_change"'\"^' "$1"
      fi
    ;;

    "dolphin" | "duckstation" | "pcsx2" | "ppsspp" | "primehack" | "xemu" )
      if [[ -z $current_section_name ]]; then
        sed -i 's^\^'"$setting_name_to_change"' =.*^'"$setting_name_to_change"' = '"$setting_value_to_change"'^' "$1"
      else
        sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"' =^s^\^'"$setting_name_to_change"' =.*^'"$setting_name_to_change"' = '"$setting_value_to_change"'^' "$1"
      fi
    ;;

    "rpcs3" | "vita3k" )
       # This does not currently work for settings with a $ in them

      if [[ "$1" =~ (.ini)$ ]]; then # If this is a RPCS3 .ini file
        if [[ -z $current_section_name ]]; then
          sed -i 's^\^'"$setting_name_to_change"'=.*^'"$setting_name_to_change"'='"$setting_value_to_change"'^' "$1"
        else
          sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"'=^s^\^'"$setting_name_to_change"'=.*^'"$setting_name_to_change"'='"$setting_value_to_change"'^' "$1"
        fi
      elif [[ "$1" =~ (.yml)$ ]]; then # If this is an YML-based file
        if [[ -z $current_section_name ]]; then
          sed -i 's^\^'"$setting_name_to_change"': .*^'"$setting_name_to_change"': '"$setting_value_to_change"'^' "$1"
        else
          sed -i '\^\['"$current_section_name"'\]^,\^\^'"$setting_name_to_change"'.*^s^\^'"$setting_name_to_change"': .*^'"$setting_name_to_change"': '"$setting_value_to_change"'^' "$1"
        fi
      fi
    ;;

    "cemu" )
      if [[ -z "$current_section_name" ]]; then
        xml ed -L -u "//$setting_name_to_change" -v "$setting_value_to_change" "$1"
      else
        xml ed -L -u "//$current_section_name/$setting_name_to_change" -v "$setting_value_to_change" "$1"
      fi
    ;;

    "mame" )
      # In this option, $current_section_name is the <system name> in the .cfg file.

      local mame_current_value=$(get_setting_value "$1" "$setting_name_to_change" "$4" "$current_section_name")
      if [[ "$1" =~ (.ini)$ ]]; then # If this is a MAME .ini file
        sed -i '\^\^'"$setting_name_to_change"'\s^s^'"$mame_current_value"'^'"$setting_value_to_change"'^' "$1"
      elif [[ "$1" =~ (.cfg)$ ]]; then # If this is an XML-based MAME .cfg file
        sed -i '\^\<system name=\"'"$current_section_name"'\">^,\^<\/system>^s^'"$mame_current_value"'^'"$setting_value_to_change"'^' "$1"
      fi
    ;;

    "es_settings" )
      sed -i 's^'"$setting_name_to_change"'" value=".*"^'"$setting_name_to_change"'" value="'"$setting_value_to_change"'"^' "$1"
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

  "rpcs3" | "vita3k" )
    if [[ "$1" =~ (.ini)$ ]]; then # If this is a RPCS3 .ini file
      echo "$current_setting_line" | grep -o -P "^\s*?.*?(?=\s?=\s?)" | sed -e 's/^[ \t]*//;s^\\ ^ ^g;s^\\$^^'
    elif [[ "$1" =~ (.yml)$ ]]; then # If this is an YML-based file
      echo "$current_setting_line" | grep -o -P "^\s*?.*?(?=\s?:\s?)" | sed -e 's/^[ \t]*//;s^\\ ^ ^g'
    fi
    ;;

  "mame" ) # This only works for mame .ini files, not the .cfg XML files
    echo "$current_setting_line" | awk '{print $1}'
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

    "retrodeck")
    if [[ -z "$current_section_name" ]]; then
      if head -n 1 "$rd_conf" | grep -qE '^\s*\{\s*$'; then # If retrodeck.cfg is new JSON format
        jq -r --arg setting_name "$current_setting_name" '.[$setting_name] // empty' "$1"
      else
        echo $(grep -o -P "(?<=^$current_setting_name=).*" "$1")
      fi
    else
      if head -n 1 "$rd_conf" | grep -qE '^\s*\{\s*$'; then # If retrodeck.cfg is new JSON format
        if jq -e --arg section "$current_section_name" '.presets | has($section)' "$rd_conf" > /dev/null; then # If the section is a preset
          jq -r --arg section "$current_section_name" --arg setting_name "$current_setting_name" '.presets[$section] | .. | objects | select(has($setting_name)) | .[$setting_name] // empty' "$1"
        else
          jq -r --arg section "$current_section_name" --arg setting_name "$current_setting_name" '.[$section][$setting_name] // empty' "$1"
        fi
      else
        sed -n -E '\^\['"$current_section_name"'\]^,\^\^'"$current_setting_name"'|\[^{ \^\['"$current_section_name"'\]^! { \^\^'"$current_setting_name"'^ p } }' "$1" | grep -o -P "(?<=^$current_setting_name=).*"
      fi
    fi
  ;;

  "melonds" | "yuzu" ) # For files with this syntax - setting_name=setting_value
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=^$current_setting_name=).*" "$1")
    else
      sed -n -E '\^\['"$current_section_name"'\]^,\^\^'"$current_setting_name"'|\[^{ \^\['"$current_section_name"'\]^! { \^\^'"$current_setting_name"'^ p } }' "$1" | grep -o -P "(?<=^$current_setting_name=).*"
    fi
  ;;

  "retroarch" ) # For files with this syntax - setting_name = "setting_value"
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=^$current_setting_name = \").*(?=\")" "$1")
    else
      sed -n -E '\^\['"$current_section_name"'\]^,\^\^'"$current_setting_name"'|\[^{ \^\['"$current_section_name"'\]^! { \^\^'"$current_setting_name"'^ p } }' "$1" | grep -o -P "(?<=^$current_setting_name = \").*(?=\")"
    fi
  ;;

  "dolphin" | "duckstation" | "pcsx2" | "ppsspp" | "primehack" | "xemu" ) # For files with this syntax - setting_name = setting_value
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=^$current_setting_name = ).*" "$1")
    else
      sed -n -E '\^\['"$current_section_name"'\]^,\^\^'"$current_setting_name"'|\[^{ \^\['"$current_section_name"'\]^! { \^\^'"$current_setting_name"'^ p } }' "$1" | grep -o -P "(?<=^$current_setting_name = ).*"
    fi
  ;;

  "rpcs3" | "vita3k" ) # For files with this syntax - setting_name: setting_value
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=$current_setting_name: ).*" "$1")
    else
      sed -n '\^\['"$current_section_name"'\]^,\^\^'"$current_setting_name"'^{ \^\['"$current_section_name"'\]^! { \^\^'"$current_setting_name"'^ p } }' "$1" | grep -o -P "(?<=$current_setting_name: ).*"
    fi
  ;;

  "cemu" )
    if [[ -z "$current_section_name" ]]; then
      echo $(xml sel -t -v "//$current_setting_name" "$1")
    else
      echo $(xml sel -t -v "//$current_section_name/$current_setting_name" "$1")
    fi
  ;;

  "mame" ) # In this option, $current_section_name is the <system name> in the .cfg file.
    if [[ "$1" =~ (.ini)$ ]]; then # If this is a MAME .ini file
      echo $(sed -n '\^\^'"$current_setting_name"'\s^p' "$1" | awk '{print $2}')
    elif [[ "$1" =~ (.cfg)$ ]]; then # If this is an XML-based MAME .cfg file
      echo $(xml sel -t -v "/mameconfig/system[@name='$current_section_name']//*[@type='$current_setting_name']//*" -v "text()" -n "$1")
    fi
  ;;

  "es_settings" )
    echo $(grep -o -P "(?<=$current_setting_name\" value=\").*(?=\")" "$1")
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
        sed -i '$ a '"$current_setting_line"'' "$1"
      else # If the file doesn't exist, sed add doesn't work for the first line
        echo "$current_setting_line" > "$1"
      fi
    else
      sed -i '/^\s*?\['"$current_section_name"'\]|\b'"$current_section_name"':$/a '"$current_setting_line"'' "$1"
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
      sed -i '$ a '"$current_setting_name"' = "'"$current_setting_value"'"' "$1"
    else
      sed -i '/^\s*?\['"$current_section_name"'\]|\b'"$current_section_name"':$/a '"$current_setting_name"' = "'"$current_setting_value"'"' "$1"
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
      sed -i -E 's^(\s*?)'"$current_setting_line"'^\1#'"$current_setting_line"'^' "$1"
    else
      sed -i -E '\^\['"$current_section_name"'\]|\b'"$current_section_name"':$^,\^\s*?'"$current_setting_line"'^s^(\s*?)'"$current_setting_line"'^\1#'"$current_setting_line"'^' "$1"
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
      sed -i -E 's^(\s*?)#'"$current_setting_line"'^\1'"$current_setting_line"'^' "$1"
    else
      sed -i -E '\^\['"$current_section_name"'\]|\b'"$current_section_name"':$^,\^\s*?#'"$current_setting_line"'^s^(\s*?)#'"$current_setting_line"'^\1'"$current_setting_line"'^' "$1"
    fi
  ;;

  esac
}

disable_file() {
  # This function adds the suffix ".disabled" to the end of a file to prevent it from being used entirely.
  # USAGE: disable_file $file_name
  # NOTE: $filename can be a defined variable from global.sh or must have the full path to the file

  mv "$(realpath "$1")" "$(realpath "$1")".disabled
}

enable_file() {
  # This function removes the suffix ".disabled" to the end of a file to allow it to be used.
  # USAGE: enable_file $file_name
  # NOTE: $filename can be a defined variable from global.sh or must have the full path to the file and should not have ".disabled" as a suffix

  mv "$(realpath "$1".disabled)" "$(realpath "$(echo "$1" | sed -e 's/\.disabled//')")"
}

install_preset_files() {
  # This function will copy a file or complete directory from a given source to a target location.
  # rsync is used for all file copying operations, for speed and to update files in place if needed.
  # USAGE: install_preset_files "$source" "$target"
  local source="$1"
  local target="$2"

  # If source or target are a directory, ensure there is a trailing slash for proper rsync functionality. Files do not need this
  if [[ -d "$source" ]]; then
  source="${source%/}/"
  fi
  if [[ -d "$target" ]]; then
  target="${target%/}/"
  fi

  rsync -rlD --mkpath "$source" "$target"
  log d "Preset files installed at: $target"
}

remove_preset_files() {
  # This function will remove a single target file or directory
  # The purpose is to remove files related to a preset which need to be present to be active and removed to be disabled, as there is no associated setting value that can be changed.
  # USAGE: remove_preset_files "$target"
  local target="$1"

  rm -rf "$target"
  log d "Preset files deleted: $target"
}

generate_single_patch() {
  # generate_single_patch $original_file $modified_file $patch_file $system

  local original_file="$1"
  local modified_file="$2"
  local patch_file="$3"
  local system="$4"

  if [[ -f "$patch_file" ]]; then
    rm "$patch_file" # Remove old patch file (maybe change this to create a backup instead?)
  fi

  while read -r current_setting_line; # Look for changes from the original file to the modified one
  do
    printf -v escaped_setting_line '%q' "$current_setting_line" # Take care of special characters before they mess with future commands
    escaped_setting_line=$(sed -E 's^\+^\\+^g' <<< "$escaped_setting_line") # Need to escape plus signs as well

    if [[ (! -z $current_setting_line) && (! $current_setting_line == "#!/bin/bash") && (! $current_setting_line == "[]") ]]; then # Ignore empty lines, empty arrays or Bash start lines
      if [[ ! -z $(grep -o -P "^\[.+?\]$" <<< "$current_setting_line") || ! -z $(grep -o -P "^\b.+?:$" <<< "$current_setting_line") ]]; then # Capture section header lines
        if [[ $current_setting_line =~ ^\[.+\] ]]; then # If normal section line
          action="section"
          current_section=$(sed 's^[][]^^g' <<< "$current_setting_line") # Remove brackets from section name
        elif [[ ! -z $(grep -o -P "^\b.+?:$" <<< "$current_setting_line") ]]; then # If RPCS3 section name
          action="section"
          current_section=$(sed 's^:$^^' <<< "$current_setting_line") # Remove colon from section name
        fi
      elif [[ (! -z "$current_section") ]]; then # If line is in a section...
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
              new_setting_value=$(get_setting_value "$2" "$current_setting_name" "$system" "$current_section")
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
              new_setting_value=$(get_setting_value "$2" "$current_setting_name" "$system")
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
        current_section=$(sed 's^[][]^^g' <<< "$current_setting_line") # Remove brackets from section name
      elif [[ ! -z $(grep -o -P "^\b.+?:$" <<< "$current_setting_line") ]]; then # If RPCS3 section name
        action="section"
        current_section=$(sed 's^:$^^' <<< "$current_setting_line") # Remove colon from section name
      fi
      elif [[ (! -z $current_section) ]]; then
        current_setting_name=$(get_setting_name "$escaped_setting_line" "$4")
        if [[ -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\b'"$current_setting_name"'.*^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\b'"$current_setting_name"'^p } }' "$1" ) ]]; then # If setting name is not found in this section of the original file...
          action="add_setting_line" # TODO: This should include the previous line, so that new lines can be inserted in the correct place rather than at the end.
          echo $action"^"$current_section"^"$current_setting_line"^^"$4 >> "$3"
        fi
      elif [[ (-z $current_section) ]]; then
        current_setting_name=$(get_setting_name "$escaped_setting_line" "$4")
        if [[ -z $(sed -n -E '\^\s*?\b'"$current_setting_name"'\s*?[:=]^p' "$1") ]]; then # If setting name is not found in the original file...
          action="add_setting_line" # TODO: This should include the previous line, so that new lines can be inserted in the correct place rather than at the end.
          echo $action"^"$current_section"^"$current_setting_line"^^"$4 >> "$3"
        fi
      fi
    fi
  done < "$modified_file"
}

deploy_single_patch() {

# This function will take an "original" file and a patch file and generate a ready to use modified file
# USAGE: deploy_single_patch $original_file $patch_file $output_file

cp -fv "$1" "$3" # Create a copy of the original file to be patched

while IFS="^" read -r action current_section setting_name setting_value system_name || [[ -n "$action" ]];
do
  if [[ ! $action == "#"* ]] && [[ ! -z "$action" ]]; then
    case $action in

    "disable_file" )
      eval disable_file "$setting_name"
    ;;

    "enable_file" )
      eval enable_file "$setting_name"
    ;;

    "add_setting_line" )
      add_setting_line "$3" "$setting_name" "$system_name" "$current_section"
    ;;

    "disable_setting" )
      disable_setting "$3" "$setting_name" "$system_name" "$current_section"
    ;;

    "enable_setting" )
      enable_setting "$3" "$setting_name" "$system_name" "$current_section"
    ;;

    "change" )
      if [[ "$setting_value" = \$* ]]; then # If patch setting value is a reference to an internal variable name
        eval setting_value="$setting_value"
      fi
      set_setting_value "$3" "$setting_name" "$setting_value" "$system_name" "$current_section"
    ;;

    * )
      log e "Config line malformed: $action"
    ;;

    esac
  fi
done < "$2"
}

deploy_multi_patch() {

# This function will take a single "batch" patch file and run all patches listed in it, across multiple config files
# USAGE: deploy_multi_patch $patch_file
# Patch file format should be as follows, with optional entries in (). Optional settings can be left empty, but must still have ^ dividers:
# $action^($current_section)^$setting_name^$setting_value^$system_name^($config file)

while IFS="^" read -r action current_section setting_name setting_value system_name config_file || [[ -n "$action" ]];
do
  if [[ ! $action == "#"* ]] && [[ ! -z "$action" ]]; then
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
      add_setting_line "$config_file" "$setting_name" "$system_name" "$current_section"
    ;;

    "disable_setting" )
      if [[ "$config_file" = \$* ]]; then # If patch setting value is a reference to an internal variable name
        eval config_file="$config_file"
      fi
      disable_setting "$config_file" "$setting_name" "$system_name" "$current_section"
    ;;

    "enable_setting" )
      if [[ "$config_file" = \$* ]]; then # If patch setting value is a reference to an internal variable name
        eval config_file="$config_file"
      fi
      enable_setting "$config_file" "$setting_name" "$system_name" "$current_section"
    ;;

    "change" )
      if [[ "$setting_value" = \$* ]]; then # If patch setting value is a reference to an internal variable name
        eval setting_value="$setting_value"
      fi
      set_setting_value "$config_file" "$setting_name" "$setting_value" "$system_name" "$current_section"
    ;;

    * )
      log e "Config line malformed: $action"
    ;;

    esac
  fi
done < "$1"
}

get_steam_user() {
  # This function populates environment variables with the actual logged Steam user data
  if [ -f "$HOME/.steam/steam/config/loginusers.vdf" ]; then
    # Extract the Steam ID of the most recent user
    export steam_id=$(awk '
      /"users"/ {flag=1}
      flag && /^[ \t]*"[0-9]+"/ {id=$1}
      flag && /"MostRecent".*"1"/ {print id; exit}' "$HOME/.steam/steam/config/loginusers.vdf" | tr -d '"')

    # Extract the Steam username (AccountName)
    export steam_username=$(awk -v steam_id="$steam_id" '
      $0 ~ steam_id {flag=1}
      flag && /"AccountName"/ {gsub(/"/, "", $2); print $2; exit}' "$HOME/.steam/steam/config/loginusers.vdf")

    # Extract the Steam pretty name (PersonaName)
    export steam_prettyname=$(awk -v steam_id="$steam_id" '
      $0 ~ steam_id {flag=1}
      flag && /"PersonaName"/ {gsub(/"/, "", $2); print $2; exit}' "$HOME/.steam/steam/config/loginusers.vdf")

    # Log success
    log i "Steam user found:"
    log i "SteamID: $steam_id"
    log i "Username: $steam_username"
    log i "Name: $steam_prettyname"

    if [[ -d "$srm_userdata" ]]; then
      populate_steamuser_srm
    fi

  else
    # Log warning if file not found
    log w "No Steam user found, proceeding" >&2
  fi
}

populate_steamuser_srm() {
  config_file="$XDG_CONFIG_HOME/steam-rom-manager/userData/userConfigurations.json"
  temp_file="${config_file}.tmp"

  if [[ ! -f "$config_file" ]]; then
    log e "Config file not found: $config_file"
    return 1
  fi

  log d "Validating $config_file..."
  if ! jq empty "$config_file" >/dev/null 2>&1; then
    log e "File is not valid JSON: $config_file"
    return 1
  fi

  log d "Applying jq transformation with username: $steam_username"
  jq --arg username "$steam_username" '
    map(
      if .userAccounts.specifiedAccounts then
        .userAccounts.specifiedAccounts = [$username]
      else
        .
      end
    )
  ' "$config_file" > "$temp_file"

  if [[ $? -eq 0 ]]; then
    mv "$temp_file" "$config_file"
    log i "Successfully updated $config_file"
  else
    log e "jq failed to write output"
    rm -f "$temp_file"
    return 1
  fi
}

prepare_component() {
  # This function will perform one of several actions on one or more components
  # The actions currently include "reset" and "postmove"
  # The "reset" action will initialize the component
  # The "postmove" action will update the component settings after one or more RetroDECK folders were moved
  # An component can be called by name, by parent folder name in the $XDG_CONFIG_HOME root or use the option "all" to perform the action on all components equally
  # USAGE: prepare_component "$action" "$component" "$call_source(optional)"

  if [[ "$1" == "factory-reset" ]]; then
    log i "User requested full RetroDECK reset"
    rm -f "$rd_lockfile" && log d "Lockfile removed"
    retrodeck
  fi

  action="$1"
  component="$2"
  call_source="$3"
  component_found="false"

  if [[ -z "$component" ]]; then
    echo "No components or action specified. Exiting."
    exit 1
  fi
  log d "Preparing component: \"$component\", action: \"$action\""

  conf_read

  # If component is "all", iterate over all components in $rd_components
  if [[ "$component" == "all" ]]; then
    for comp_dir in "$rd_components"/*; do
      comp=$(basename "$comp_dir")
      found_this_component="false"
      while IFS= read -r prepare_component_file; do
        if [[ "$(basename "$(dirname "$prepare_component_file")")" == "$comp" ]]; then
          log d "Found component file $prepare_component_file for component $comp"
          source "$prepare_component_file"
          found_this_component="true"
          component_found="true"
        fi
      done < <(find "$rd_components" -maxdepth 2 -mindepth 2 -type f -name "component_prepare.sh")
      if [[ "$found_this_component" == "false" ]]; then
        log w "Component $comp not found"
      fi
    done
  else
    # Read install components component_prepare.sh files for specified components
    for comp in $component; do
      found_this_component="false"
      while IFS= read -r prepare_component_file; do
        if [[ "$(basename "$(dirname "$prepare_component_file")")" == "$comp" ]]; then
          log d "Found component file $prepare_component_file for component $comp"
          source "$prepare_component_file"
          found_this_component="true"
          component_found="true"
        fi
      done < <(find "$rd_components" -maxdepth 2 -mindepth 2 -type f -name "component_prepare.sh")
      if [[ "$found_this_component" == "false" ]]; then
        log w "Component $comp not found"
      fi
    done
  fi

  if [[ $component_found == "false" ]]; then
    log e "Supplied component $component not found, not resetting"
    return 1
  else
    # Update presets for all components after any reset or move
    if [[ ! "$component" =~ ^(retrodeck|es-de) ]]; then
      build_retrodeck_current_presets
    fi
  fi

  conf_write
}
