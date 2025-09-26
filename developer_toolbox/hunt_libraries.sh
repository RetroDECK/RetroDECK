#!/bin/bash

# The purpose of this script is to help determine which libraries for a component do not exist in the base flatpak and need to be included in some way.
# The script will identify the dependencies of the given binary via objdump, then generate a JSON file containing the libraries that must be found.
# Optionally a Qt version (-q) can be supplied which will be included in the library JSON object for future reference and processing, if a Qt version cannot be otherwise automatically determined.
# A path (-p) to the libraries (such as ones included in an AppImage) can also optionally be specified for future reference and processing.
# A path (-o) for the subsequent output file can also optionally be supplied, otherwise the file will be output into the directory from which the script was run.
# USAGE: hunt_libraries.sh [-qpo] /path/to/binary
# NOTE: The script should be run OUTSIDE of the Flatpak environment, and it will search through any installed Flatpak runtimes, so you should have a semi-similar environment to the build environment for best accuracy.

flatpak_runtimes_root="/var/lib/flatpak/runtime"
flatpak_user_runtimes_root="$HOME/.local/share/flatpak/runtime"
flatpak_freedesktop_runtime_root="$flatpak_runtimes_root/org.freedesktop.Platform"
flatpak_kde_runtime_root="$flatpak_runtimes_root/org.kde.Platform"
flatpak_user_freedesktop_runtime_root="$flatpak_user_runtimes_root/org.freedesktop.Platform"
flatpak_user_kde_runtime_root="$flatpak_user_runtimes_root/org.kde.Platform"

component_libs_file="./component_libs.json"
component_libs='[]'

# Update these variables over time as needed

retrodeck_runtime_version="24.08"
latest_kde5_runtime_version="5.15-24.08"
latest_kde6_runtime_version="6.9"

# Helper function to search for libraries in both system and user runtime paths
search_flatpak_runtimes() {
  local search_pattern="$1"
  local result=""
  
  # First try system runtime path
  if [[ -d "$flatpak_runtimes_root" ]]; then
    result=$(find "$flatpak_runtimes_root" -name "$search_pattern" 2>/dev/null)
  fi
  
  # If not found or system path doesn't exist, try user runtime path
  if [[ -z "$result" && -d "$flatpak_user_runtimes_root" ]]; then
    result=$(find "$flatpak_user_runtimes_root" -name "$search_pattern" 2>/dev/null)
  fi
  
  echo "$result"
}

# Helper function to get the correct runtime path (system or user)
get_runtime_path() {
  if [[ -d "$flatpak_runtimes_root" ]]; then
    echo "$flatpak_runtimes_root"
  elif [[ -d "$flatpak_user_runtimes_root" ]]; then
    echo "$flatpak_user_runtimes_root"
  else
    echo ""
  fi
}

# Helper function to get the correct freedesktop runtime path
get_freedesktop_runtime_path() {
  if [[ -d "$flatpak_freedesktop_runtime_root" ]]; then
    echo "$flatpak_freedesktop_runtime_root"
  elif [[ -d "$flatpak_user_freedesktop_runtime_root" ]]; then
    echo "$flatpak_user_freedesktop_runtime_root"
  else
    echo ""
  fi
}

# Helper function to get the correct KDE runtime path
get_kde_runtime_path() {
  if [[ -d "$flatpak_kde_runtime_root" ]]; then
    echo "$flatpak_kde_runtime_root"
  elif [[ -d "$flatpak_user_kde_runtime_root" ]]; then
    echo "$flatpak_user_kde_runtime_root"
  else
    echo ""
  fi
}

# Helper function to check if specific runtime version exists and return the path
check_freedesktop_runtime_version() {
  local version="$1"
  if [[ -d "$flatpak_freedesktop_runtime_root/x86_64/$version/active/files" ]]; then
    echo "$flatpak_freedesktop_runtime_root/x86_64/$version/active/files"
  elif [[ -d "$flatpak_user_freedesktop_runtime_root/x86_64/$version/active/files" ]]; then
    echo "$flatpak_user_freedesktop_runtime_root/x86_64/$version/active/files"
  else
    echo ""
  fi
}

# Helper function to check if specific KDE runtime version exists and return the path
check_kde_runtime_version() {
  local version="$1"
  if [[ -d "$flatpak_kde_runtime_root/x86_64/$version/active/files" ]]; then
    echo "$flatpak_kde_runtime_root/x86_64/$version/active/files"
  elif [[ -d "$flatpak_user_kde_runtime_root/x86_64/$version/active/files" ]]; then
    echo "$flatpak_user_kde_runtime_root/x86_64/$version/active/files"
  else
    echo ""
  fi
}

while [[ $# -gt 1 ]]; do
  case "$1" in
    -q|--qt-version)
      qt_version="$2"
      shift 2
    ;;
    -p|--path)
      path_to_search="$2"
      shift 2
    ;;
    -o|--output)
      component_libs_file="$2"
      shift 2
    ;;
  esac
done

while read -r lib; do
  if [[ -n $(jq -r '.[].library' <<< "$component_libs") ]]; then # If component_libs list is not empty
    if jq -e --arg lib "$lib" '.[] | select(.library == $lib)' <<< "$component_libs" >/dev/null; then # Check if lib dep is already on the list
      echo "Library $lib already added, skipping..."
      continue
    fi
  fi

  shared_libs_subfolder="UNKNOWN"
  lib_found="false"

  # PHASE 1 - Locating component dependency

  freedesktop_runtime_files_path=$(check_freedesktop_runtime_version "$retrodeck_runtime_version")
  if [[ -n "$freedesktop_runtime_files_path" && -n $(find "$freedesktop_runtime_files_path" -name "$lib" 2>/dev/null) ]]; then # Check if lib is already provided by RetroDECK runtime
    echo "Library $lib found in RetroDECK base runtime, skipping..."
    continue
  fi

  if [[ "$lib" =~ "libQt" ]]; then # If library is a Qt lib
    if [[ "$lib" =~ "libQt5" ]]; then
      shared_libs_subfolder="qt5"
      if [[ ! -n "$qt_version" ]]; then
        qt_version="$latest_kde5_runtime_version"
      fi
    elif [[ "$lib" =~ "libQt6" ]]; then
      shared_libs_subfolder="qt6"
      if [[ ! -n "$qt_version" ]]; then
        qt_version="$latest_kde6_runtime_version"
      fi
    fi
    kde_runtime_files_path=$(check_kde_runtime_version "$qt_version")
    if [[ -n "$kde_runtime_files_path" ]]; then
      found_lib_path=$(find "$kde_runtime_files_path" -name "$lib" 2>/dev/null)
      json_obj=$(jq -n --arg lib "$lib" --arg qt_ver "$qt_version" --arg subfolder "$shared_libs_subfolder" '{ library: $lib, qt_version: $qt_ver, subfolder: $subfolder }')
      component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
      lib_found="true"
    fi
  else # If library is not a Qt lib
    found_lib_all_runtimes=$(search_flatpak_runtimes "$lib") # Check if lib is provided by any installed runtime
    if [[ -n "$found_lib_all_runtimes" ]]; then # Library was found in at least one Flatpak runtime
      found_lib_runtime=$(echo "$found_lib_all_runtimes" | awk -F/ '{print $6, $8}' | sort -k1,1 -k2,2Vr | head -n1) # Find latest version of runtime that contains that library
      read runtime_name runtime_version <<< "$found_lib_runtime"
      runtime_root=$(get_runtime_path)
      if [[ -n "$runtime_root" ]]; then
        found_lib_path=$(find "$runtime_root/$runtime_name/x86_64/$runtime_version/active/files" -name "$lib" 2>/dev/null)
        json_obj=$(jq -n --arg lib "$lib" --arg runtime_name "$runtime_name" --arg runtime_version "$runtime_version" '{ library: $lib, runtime_name: $runtime_name, subfolder: $runtime_version }')
        component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
        lib_found="true"
      fi
    elif [[ -n "$path_to_search" ]]; then # Search optional provided path
      found_lib_custom_path=$(find "$path_to_search" -name "$lib")
      if [[ -n "$found_lib_custom_path" ]]; then # Library was found in provided path
        found_lib_path="$found_lib_custom_path"
        json_obj=$(jq -n --arg lib "$lib" --arg subfolder "$shared_libs_subfolder" --arg source "$found_lib_path" '{ library: $lib, subfolder: $subfolder, source: $source }')
        component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
        lib_found="true"
      fi
    fi
    if [[ "$lib_found" == "false" ]]; then # Library could not be found automatically
      echo "Library $lib could not be found at all, skipping further search..."
      json_obj=$(jq -n --arg lib "$lib" --arg subfolder "$shared_libs_subfolder" '{ library: $lib, subfolder: $subfolder }')
      component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
      continue
    fi
  fi

  # PHASE 2 - Locating dependency dependencies

  while read -r lib_dep; do
    if jq -e --arg lib_dep "$lib_dep" '.[] | select(.library == $lib_dep)' <<< "$component_libs" >/dev/null; then # Check if library dependency is already on the list
      echo "Library dependency $lib_dep already added, skipping..."
      continue
    fi

    shared_libs_subfolder="UNKNOWN"
    lib_dep_found="false"

    freedesktop_runtime_files_path=$(check_freedesktop_runtime_version "$retrodeck_runtime_version")
    if [[ -n "$freedesktop_runtime_files_path" && -n $(find "$freedesktop_runtime_files_path" -name "$lib_dep" 2>/dev/null) ]]; then # Check if library dependency is already provided by RetroDECK runtime
      echo "Library dependency $lib_dep found in RetroDECK base runtime, skipping..."
      continue
    fi

    if [[ "$lib_dep" =~ "libQt" ]]; then # If library dependency is a Qt lib
      if [[ "$lib_dep" =~ "libQt5" ]]; then
        shared_libs_subfolder="qt5"
        if [[ ! -n "$qt_version" ]]; then
          qt_version="$latest_kde5_runtime_version"
        fi
      elif [[ "$lib_dep" =~ "libQt6" ]]; then
        shared_libs_subfolder="qt6"
        if [[ ! -n "$qt_version" ]]; then
          qt_version="$latest_kde6_runtime_version"
        fi
      fi
      kde_runtime_files_path=$(check_kde_runtime_version "$qt_version")
      if [[ -n "$kde_runtime_files_path" ]]; then
        found_lib_dep_path=$(find "$kde_runtime_files_path" -name "$lib_dep" 2>/dev/null)
        json_obj=$(jq -n --arg lib_dep "$lib_dep" --arg qt_ver "$qt_version" --arg subfolder "$shared_libs_subfolder" '{ library: $lib_dep, qt_version: $qt_ver, subfolder: $subfolder }')
        component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
        lib_dep_found="true"
      fi
    else # If library dependency is not a Qt lib
      found_lib_dep_all_runtimes=$(search_flatpak_runtimes "$lib_dep") # Check if lib is provided by any installed runtime
      if [[ -n "$found_lib_dep_all_runtimes" ]]; then # Library was found in at least one Flatpak runtime
        found_lib_dep_runtime=$(echo "$found_lib_dep_all_runtimes" | awk -F/ '{print $6, $8}' | sort -k1,1 -k2,2Vr | head -n1) # Find latest version of runtime that contains that library
        read dep_runtime_name dep_runtime_version <<< "$found_lib_dep_runtime"
        runtime_root=$(get_runtime_path)
        if [[ -n "$runtime_root" ]]; then
          found_lib_dep_path=$(find "$runtime_root/$dep_runtime_name/x86_64/$dep_runtime_version/active/files" -name "$lib_dep" 2>/dev/null)
          json_obj=$(jq -n --arg lib_dep "$lib_dep" --arg runtime_name "$dep_runtime_name" --arg runtime_version "$dep_runtime_version" '{ library: $lib_dep, runtime_name: $runtime_name, subfolder: $runtime_version }')
          component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
          lib_dep_found="true"
        fi
      elif [[ -n "$path_to_search" ]]; then # Search optional provided path
        found_lib_dep_custom_path=$(find "$path_to_search" -name "$lib_dep")
        if [[ -n "$found_lib_dep_custom_path" ]]; then # Library dependency was found in provided path
          json_obj=$(jq -n --arg lib_dep "$lib_dep" --arg subfolder "$shared_libs_subfolder" --arg source "$found_lib_dep_custom_path" '{ library: $lib_dep, subfolder: $subfolder, source: $source }')
          component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
          lib_dep_found="true"
        fi
      fi
      if [[ "$lib_dep_found" == "false" ]]; then # Library could not be found automatically
        echo "Library dependency $lib_dep could not be found at all, skipping further search..."
        json_obj=$(jq -n --arg lib_dep "$lib_dep" --arg subfolder "$shared_libs_subfolder" '{ library: $lib_dep, subfolder: $subfolder }')
        component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
        continue
      fi
    fi
  done < <(objdump -p "$found_lib_path" | awk '/NEEDED/ {print $2}')
done < <(objdump -p "$1" | awk '/NEEDED/ {print $2}')

echo "$component_libs" | jq > "$component_libs_file"
