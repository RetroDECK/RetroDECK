#!/bin/bash

sed_escape_pattern() {
  # Escape a string for safe use in a sed pattern/match context, using ^ as the delimiter.
  # USAGE: escaped=$(sed_escape_pattern "$string")

  local input="$1"
  input="${input//\\/\\\\}"
  input="${input//./\\.}"
  input="${input//\*/\\*}"
  input="${input//\[/\\[}"
  input="${input//^/\\^}"
  input="${input//$/\\$}"
  printf '%s' "$input"
}

sed_escape_replacement() {
  # Escape a string for safe use in a sed replacement context, using ^ as the delimiter.
  # USAGE: escaped=$(sed_escape_replacement "$string")

  local input="$1"
  input="${input//\\/\\\\}"  # backslashes first
  input="${input//&/\\&}"    # ampersand
  input="${input//^/\\^}"    # delimiter
  printf '%s' "$input"
}

set_setting_value() {
  # Function for editing settings
  # This function acts as a router for individual component pair functions
  # The component should provide a _set_setting_value::<component name> function in its component_functions.sh file
  # USAGE: set_setting_value "$setting_file" "$setting_name" "$new_setting_value" "$system" ["$section_name"]

  local file="$1" setting="$2" value="$3" component="$4" section="${5:-}"

  log d "Setting $setting=$value in $file"

  if [[ ! -f "$file" ]]; then
    log e "File $file does not exist, cannot set setting $setting"
    return 1
  fi

  local set_handler="_set_setting_value::${component}"
  local get_handler="_get_setting_value::${component}"

  if ! declare -F "$set_handler" > /dev/null; then
    log e "No _set_setting_value handler found for component: $component"
    return 1
  fi

  if ! declare -F "$get_handler" > /dev/null; then
    log e "No _get_setting_value handler found for component: $component"
    return 1
  fi

  "$set_handler" "$file" "$setting" "$value" "$section"

  local result
  result=$("$get_handler" "$file" "$setting" "$section")

  if [[ "$result" != "$value" && ! "$result" == "blind_write" ]]; then
    log e "Failed to set $setting=$value in $file (got: $result)"
    return 1
  else
    log d "Successfully set $setting=$value in $file"
    return
  fi
}

get_setting_value() {
# Function for getting the current value of a setting from a config file
# USAGE: get_setting_value $setting_file "$setting_name" $system $section (optional)

  local current_setting_name="$2"
  local current_section_name="${4:-}"

  case $3 in

    "retrodeck" )
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

  "melonds" | "yuzu" | "gzdoom" ) # For files with this syntax - setting_name=setting_value
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=^$current_setting_name=).*" "$1")
    else
      sed -n -E '\^\['"$current_section_name"'\]^,\^\^'"$current_setting_name"'|\[^{ \^\['"$current_section_name"'\]^! { \^\^'"$current_setting_name"'^ p } }' "$1" | grep -o -P "(?<=^$current_setting_name=).*"
    fi
  ;;

  "azahar" ) # For files with this syntax - setting_name=setting_value but also maybe backslashes in the setting name
    escaped_setting_name=$(printf '%s\n' "$current_setting_name" | sed 's/[[\.*^$/]/\\&/g')

    if [[ -n "$current_section_name" ]]; then
        awk -F'=' -v section="[$current_section_name]" -v key="$escaped_setting_name" '
            $0 == section { in_section=1; next }
            /^\[/ { in_section=0 }
            in_section && $1 == key { print $2; exit }
        ' "$1"
    else
        awk -F'=' -v key="$escaped_setting_name" '
            /^\[/ { exit }
            $1 == key { print $2; exit }
        ' "$1"
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

  "ryubing" )
    if [[ -z "$current_section_name" ]]; then
      jq -r --arg setting_name "$current_setting_name" '.[$setting_name] // empty' "$1"
    else
      jq -r --arg section "$current_section_name" --arg setting_name "$current_setting_name" '.[$section][$setting_name] // empty' "$1"
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
  local current_section_name=$(sed -e 's/%/\\%/g' <<< "${4:-}")

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
  local current_section_name=$(sed -e 's/%/\\%/g' <<< "${5:-}")

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
  local current_section_name=$(sed -e 's/%/\\%/g' <<< "${4:-}")

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
  local current_section_name="${4:-}"

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
  local current_section_name="${4:-}"

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
