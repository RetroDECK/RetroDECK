#!/bin/bash

# The purpose of this script is to help determine which libraries for a component do not exist in the base flatpak and need to be included in some way.
# The script will identify the dependencies of the given binary via ldd, then generate a JSON file containing the libraries that must be found.
# Optionally a Qt version can be supplied which will be included in the library JSON object for future reference and processing.
# A path to the libraries (such as ones included in an AppImage) can also optionally be specified for future reference and processing.
# A path for the subsequent output file can also optionally be supplied, otherwise the file will be output into the directory from which the script was run.
# USAGE: build_missing_libs_json.sh [-qpo] /path/to/binary

component_libs_file="./component_libs.json"
component_libs='[]'

while [[ $# -gt 1 ]]; do
  case "$1" in
    -q|--qt-version)
      qt_version="$2"
      shift 2
    ;;
    -p|--path)
      path="$2"
      shift 2
    ;;
    -o|--output)
      component_libs_file="$2"
      shift 2
    ;;
  esac
done

while read -r lib arrow not _; do
  [[ -z "$lib" ]] && continue # skip empty lines

  if [[ "$not" == "not" ]]; then
    if [[ "$lib" =~ "libQt" ]]; then
      if [[ ! -n "$qt_version" ]]; then
        qt_version="UNKNOWN"
      fi
      json_obj=$(jq -n --arg lib "$lib" --arg qt_ver "$qt_version" '{ library: $lib, qt_version: $qt_ver }')
      component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
    else
      if [[ ! -n "$path" ]]; then
        path="UNKNOWN"
      fi
      json_obj=$(jq -n --arg lib "$lib" --arg path "$path" '{ library: $lib, path: $path }')
      component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
    fi
  fi
done <<< $(ldd "$1")

echo "$component_libs" | jq > "$component_libs_file"
