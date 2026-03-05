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
  # This function acts as a router for individual component pair functions
  # The component should provide a _get_setting_value::<component name> function in its component_functions.sh file
  # USAGE: get_setting_value $setting_file "$setting_name" $system [$section]

  local file="$1" setting="$2" component="$3" section="${4:-}"

  if [[ ! -f "$file" ]]; then
    log e "File $file does not exist, cannot get setting $setting"
    return 1
  fi

  local handler="_get_setting_value::${component}"
  if ! declare -F "$handler" > /dev/null; then
    log e "No _get_setting_value handler found for component: $component"
    return 1
  fi

  local result
  result=$("$handler" "$file" "$setting" "$section")

  if [[ -n "$result" ]]; then
    echo "$result"
    return
  else
    log e "Failed to get setting $setting value from $file"
    return 1
  fi
}

get_setting_name() {
  # Function for getting the current name of a setting from a provided full config line
  # This function acts as a router for individual component pair functions
  # The component should provide a _get_setting_name::<component name> function in its component_functions.sh file
  # USAGE: get_setting_name "$setting_line" "$system" ["$section"]

  local line="$1" component="$2" section="${3:-}"

  if [[ ! -f "$line" ]]; then
    log e "No setting line provided, cannot perform name extraction"
    return 1
  fi

  local handler="_get_setting_name::${component}"
  if ! declare -F "$handler" > /dev/null; then
    log e "No _get_setting_name handler found for component: $component"
    return 1
  fi

  local result
  result=$("$handler" "$line" "$section")

  if [[ -n "$result" ]]; then
    echo "$result"
    return
  else
    log e "Failed to get setting name from $line"
    return 1
  fi  
}

add_setting() {
  # Function for adding a setting name and value to a file. This is useful for dynamically generated config files where a setting line may not exist until the setting is changed from the default.
  # This function acts as a router for individual component pair functions
  # The component should provide a _add_setting::<component name> function in its component_functions.sh file
  # USAGE: add_setting $setting_file $setting_name $setting_value $system [$section]

  local file="$1" setting="$2" value="$3" component="$4" section="${5:-}"

  if [[ ! -f "$file" ]]; then
    log e "File $file does not exist, cannot get setting $setting"
    return 1
  fi

  local handler="_add_setting::${component}"
  if ! declare -F "$handler" > /dev/null; then
    log e "No _add_setting handler found for component: $component"
    return 1
  fi

  "$handler" "$file" "$setting" "$value" "$section"
}

delete_setting() {
  # Function for removing a setting from a file. This is useful for dynamically generated config files where a setting line may not exist until the setting is changed from the default.
  # This function acts as a router for individual component pair functions
  # The component should provide a _delete_setting::<component name> function in its component_functions.sh file
  # USAGE: delete_setting $setting_file $setting_name $system [$section]

  local file="$1" setting="$2" component="$3" section="${4:-}"

  if [[ ! -f "$file" ]]; then
    log e "File $file does not exist, cannot get setting $setting"
    return 1
  fi

  local handler="_delete_setting::${component}"
  if ! declare -F "$handler" > /dev/null; then
    log e "No _delete_setting handler found for component: $component"
    return 1
  fi

  "$handler" "$file" "$setting" "$section"
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
