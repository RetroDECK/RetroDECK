#!/bin/bash

# The purpose of this script is to help determine which libraries for a component do not exist in the base flatpak and need to be included in some way.
# The script will identify the dependencies of the given binary via ldd, then generate a JSON file containing the libraries that must be found.
# Optionally a Qt version (-q) can be supplied which will be included in the library JSON object for future reference and processing.
# A path (-p) to the libraries (such as ones included in an AppImage) can also optionally be specified for future reference and processing.
# A path (-o) for the subsequent output file can also optionally be supplied, otherwise the file will be output into the directory from which the script was run.
# USAGE: build_missing_libs_json.sh [-qpo] /path/to/binary

flatpak_system_runtimes_root="/var/lib/flatpak/runtime"
flatpak_user_runtimes_root="$HOME/.local/share/flatpak/runtime"

component_libs_file="./component_libs.json"
component_libs='[]'

# Update these variables over time as needed

retrodeck_runtime_version="25.08"
latest_kde5_runtime_version="5.15-25.08"
latest_kde6_runtime_version="6.10"
default_dest="shared-libs"

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

  lib_found="false"

  # PHASE 1 - Locating component dependency

  # Check if lib is already provided by RetroDECK runtime
  if [[ -d "$flatpak_user_runtimes_root/org.freedesktop.Platform/x86_64/$retrodeck_runtime_version" ]]; then
    if [[ -n $(find "$flatpak_user_runtimes_root/org.freedesktop.Platform/x86_64/$retrodeck_runtime_version/active/files" -name "$lib") ]]; then
      echo "Library $lib found in RetroDECK base runtime, skipping..."
      continue
    fi
  elif [[ -d "$flatpak_system_runtimes_root/org.freedesktop.Platform/x86_64/$retrodeck_runtime_version" ]]; then
    if [[ -n $(find "$flatpak_system_runtimes_root/org.freedesktop.Platform/x86_64/$retrodeck_runtime_version/active/files" -name "$lib") ]]; then
      echo "Library $lib found in RetroDECK base runtime, skipping..."
      continue
    fi
  else
    echo "ERROR: RetroDECK base runtime not installed, unable to check if library is included."
  fi

  if [[ "$lib" =~ "libQt" ]]; then # If library is a Qt lib, which we know the location of already
    runtime_name="org.kde.Platform"
    if [[ ! -n "$qt_version" ]]; then
      if [[ "$lib" =~ "libQt5" ]]; then
        qt_version="$latest_kde5_runtime_version"
      elif [[ "$lib" =~ "libQt6" ]]; then
        qt_version="$latest_kde6_runtime_version"
      fi
    fi
    found_lib_path=$(find "$flatpak_user_runtimes_root/$runtime_name/x86_64/$qt_version/active/files" -name "$lib" 2>/dev/null)
    if [[ ! -n "$found_lib_path" ]]; then # If library was not found in a user-mode runtime
      found_lib_path=$(find "$flatpak_system_runtimes_root/$runtime_name/x86_64/$qt_version/active/files" -name "$lib" 2>/dev/null)
    fi
    if [[ ! -n "$found_lib_path" ]]; then
      echo "ERROR: Library $lib could not be found in the expected KDE runtime, the runtime may not be installed."
    else
      json_obj=$(jq -n --arg lib "$lib" --arg runtime_name "$runtime_name" --arg runtime_version "$qt_version" --arg dest "$default_dest" '{ library: $lib, runtime_name: $runtime_name, runtime_version: $runtime_version, dest: $dest }')
      component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
      lib_found="true"
    fi
  fi
  if [[ "$lib_found" == "false" ]]; then
    # Check if lib is provided by any installed runtime, starting with the latest

    if [[ -n "$(find "$flatpak_user_runtimes_root" -name "$lib" 2>/dev/null)" ]]; then # Library was found in some user-mode Flatpak runtime
      found_lib_runtime=$(find "$flatpak_user_runtimes_root" -name "$lib" | awk -F/ '{print $8, $10}' | sort -k1,1 -k2,2Vr | head -n1)
      read runtime_name runtime_version <<< "$found_lib_runtime"
      found_lib_path=$(find "$flatpak_user_runtimes_root/$runtime_name/x86_64/$runtime_version/active/files" -name "$lib")
      json_obj=$(jq -n --arg lib "$lib" --arg runtime_name "$runtime_name" --arg runtime_version "$runtime_version" --arg dest "$default_dest" '{ library: $lib, runtime_name: $runtime_name, runtime_version: $runtime_version, dest: $dest }')
      component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
      lib_found="true"
    elif [[ -n "$(find "$flatpak_system_runtimes_root" -name "$lib" 2>/dev/null)" ]]; then
      found_lib_runtime=$(find "$flatpak_system_runtimes_root" -name "$lib" | awk -F/ '{print $6, $8}' | sort -k1,1 -k2,2Vr | head -n1)
      read runtime_name runtime_version <<< "$found_lib_runtime"
      found_lib_path=$(find "$flatpak_system_runtimes_root/$runtime_name/x86_64/$runtime_version/active/files" -name "$lib")
      json_obj=$(jq -n --arg lib "$lib" --arg runtime_name "$runtime_name" --arg runtime_version "$runtime_version" --arg dest "$default_dest" '{ library: $lib, runtime_name: $runtime_name, runtime_version: $runtime_version, dest: $dest }')
      component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
      lib_found="true"
    elif [[ -n "$path_to_search" ]]; then # Search optional provided path
      found_lib_custom_path="$(find "$path_to_search" -name "$lib")"
      if [[ -n "$found_lib_custom_path" ]]; then # Library was found in provided path
        found_lib_path="$found_lib_custom_path"
        found_lib_src="$(find "$path_to_search" -name "$lib" -exec dirname {} \; | xargs -I{} realpath --relative-to="$(pwd)" "{}")"
        json_obj=$(jq -n --arg lib "$lib" --arg source "$found_lib_src" --arg dest "$default_dest" '{ library: $lib, source: $source, dest: $dest }')
        component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
        lib_found="true"
      fi
    fi
  fi
  # Library could not be found automatically
  if [[ "$lib_found" == "false" ]]; then
    echo "Library $lib could not be found at all, skipping further search..."
    json_obj=$(jq -n --arg lib "$lib" '{ library: $lib }')
    component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
    continue
  fi

  # PHASE 2 - Locating dependency dependencies

  while read -r lib_dep; do
    if jq -e --arg lib_dep "$lib_dep" '.[] | select(.library == $lib_dep)' <<< "$component_libs" >/dev/null; then # Check if lib dep is already on the list
      echo "Library dependency $lib_dep already added, skipping..."
      continue
    fi

    # Check if lib dependency is already provided by RetroDECK runtime
    if [[ -d "$flatpak_user_runtimes_root/org.freedesktop.Platform/x86_64/$retrodeck_runtime_version" ]]; then
      if [[ -n $(find "$flatpak_user_runtimes_root/org.freedesktop.Platform/x86_64/$retrodeck_runtime_version/active/files" -name "$lib_dep") ]]; then
        echo "Library dependency $lib_dep found in RetroDECK base runtime, skipping..."
        continue
      fi
    elif [[ -d "$flatpak_system_runtimes_root/org.freedesktop.Platform/x86_64/$retrodeck_runtime_version" ]]; then
      if [[ -n $(find "$flatpak_system_runtimes_root/org.freedesktop.Platform/x86_64/$retrodeck_runtime_version/active/files" -name "$lib_dep") ]]; then
        echo "Library dependency $lib_dep found in RetroDECK base runtime, skipping..."
        continue
      fi
    else
      echo "ERROR: RetroDECK base runtime not installed, unable to check if library is included."
    fi

    if [[ "$lib_dep" =~ "libQt" ]]; then # If library dependency is a Qt lib
      runtime_name="org.kde.Platform"
      if [[ ! -n "$qt_version" ]]; then
        if [[ "$lib_dep" =~ "libQt5" ]]; then
          qt_version="$latest_kde5_runtime_version"
        elif [[ "$lib_dep" =~ "libQt6" ]]; then
          qt_version="$latest_kde6_runtime_version"
        fi
      fi
      found_lib_dep_path=$(find "$flatpak_user_runtimes_root/$runtime_name/x86_64/$qt_version/active/files" -name "$lib_dep" 2>/dev/null)
      if [[ ! -n "$found_lib_dep_path" ]]; then # If library was not found in a user-mode runtime
        found_lib_dep_path=$(find "$flatpak_system_runtimes_root/$runtime_name/x86_64/$qt_version/active/files" -name "$lib" 2>/dev/null)
      fi
      if [[ ! -n "$found_lib_dep_path" ]]; then
        echo "ERROR: Library dependency $lib_dep could not be found in the expected KDE runtime, the runtime may not be installed."
      else
        json_obj=$(jq -n --arg lib "$lib_dep" --arg runtime_name "$runtime_name" --arg runtime_version "$qt_version" --arg dest "$default_dest" '{ library: $lib, runtime_name: $runtime_name, runtime_version: $runtime_version, dest: $dest }')
        component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
        continue
      fi
    fi
    # Check if library dependency is provided by any installed runtime, starting with the latest
    if [[ -n "$(find "$flatpak_user_runtimes_root" -name "$lib_dep" 2>/dev/null)" ]]; then
      found_lib_dep_runtime=$(find "$flatpak_user_runtimes_root" -name "$lib_dep" | awk -F/ '{print $8, $10}' | sort -k1,1 -k2,2Vr | head -n1)
      read dep_runtime_name dep_runtime_version <<< "$found_lib_dep_runtime"
      json_obj=$(jq -n --arg lib "$lib_dep" --arg runtime_name "$dep_runtime_name" --arg runtime_version "$dep_runtime_version" --arg dest "$default_dest" '{ library: $lib, runtime_name: $runtime_name, runtime_version: $runtime_version, dest: $dest }')
      component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
      continue
    elif [[ -n "$(find "$flatpak_system_runtimes_root" -name "$lib_dep" 2>/dev/null)" ]]; then
      found_lib_dep_runtime=$(find "$flatpak_system_runtimes_root" -name "$lib_dep" | awk -F/ '{print $6, $8}' | sort -k1,1 -k2,2Vr | head -n1)
      read dep_runtime_name dep_runtime_version <<< "$found_lib_dep_runtime"
      json_obj=$(jq -n --arg lib "$lib_dep" --arg runtime_name "$dep_runtime_name" --arg runtime_version "$dep_runtime_version" --arg dest "$default_dest" '{ library: $lib, runtime_name: $runtime_name, runtime_version: $runtime_version, dest: $dest }')
      component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
      continue
    elif [[ -n "$path_to_search" ]]; then # Search optional provided path
      found_lib_dep_custom_path=$(find "$path_to_search" -name "$lib_dep" 2>/dev/null)
      if [[ -n "$found_lib_dep_custom_path" ]]; then # Library dependency was found in provided path
        found_lib_dep_src="$(find "$path_to_search" -name "$lib_dep" -exec dirname {} \; | xargs -I{} realpath --relative-to="$(pwd)" "{}")"
        json_obj=$(jq -n --arg lib "$lib_dep" --arg source "$found_lib_dep_src" --arg dest "$default_dest" '{ library: $lib, source: $source, dest: $dest }')
        component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
        continue
      fi
    fi
    # Library dependency could not be found automatically
    echo "Library $lib could not be found at all, skipping further search..."
    json_obj=$(jq -n --arg lib "$lib_dep" '{ library: $lib }')
    component_libs=$(jq --argjson new_obj "$json_obj" '. + [$new_obj]' <<< "$component_libs")
    continue
  done < <(objdump -p "$found_lib_path" | awk '/NEEDED/ {print $2}')
done < <(objdump -p "$1" | awk '/NEEDED/ {print $2}')

echo "$component_libs" | jq > "$component_libs_file"
