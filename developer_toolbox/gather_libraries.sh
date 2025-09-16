#!/bin/bash

# This script is meant to process component_libs.json files created by the build_missing_libs_json.sh script.
# It will iterate all the objects in the output JSON files, search for the defined libraries and copy them to the specified locations if they do not already exist there.
# A path to search for component_libs.json files can optionally be specified. The script will search this path 1 level deep, so will investigate any direct sub-folders of the supplied path. Otherwise the script will search the directory from which it was run.
# A destination path can be specified which will override the "shared-libs" destination, which is used when any specific destination is not defined for a given library in the component_libs.json file.
# USAGE: gather_libs.sh [-pd]

root_to_search="."
gathered_libs_dest_root="./shared-libs"
flatpak_runtime_dir="/var/lib/flatpak/runtime"
current_rd_runtime="24.08"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--path)
      root_to_search="$2"
      shift 2
    ;;
    -d|--dest)
      gathered_libs_dest_root="$2"
      shift 2
    ;;
  esac
done

gathered_libs_dest_root=$(realpath $gathered_libs_dest_root)

if [[ ! -e "$gathered_libs_dest_root" ]]; then
  mkdir -p "$gathered_libs_dest_root"
fi

while IFS= read -r component_libs_file; do
  component_libs_file=$(realpath $component_libs_file)
  echo "Found $component_libs_file"
  while read -r lib; do
    qt_version=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .qt_version // empty' "$component_libs_file")
    lib_type=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .type // empty' "$component_libs_file")
    lib_src=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .source // empty' "$component_libs_file")
    lib_dest=$(jq -r --arg lib "$lib" '.[] | select(.library == $lib) | .dest // empty' "$component_libs_file")
    if [[ -n $qt_version ]]; then
      if [[ $lib_type == "qt_plugin" ]]; then
        echo "Looking for Qt plugin at $flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/plugins/$lib"
        if [[ -e "$flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/plugins/$lib" ]]; then
          if [[ ! -n "$lib_dest" ]]; then
              lib_dest="$gathered_libs_dest_root/qt-$qt_version/plugins/$lib/"
          fi
          if [[ -e "$lib_dest" ]]; then
            echo "Qt plugin folder already found in destination location $lib_dest, skipping..."
          else
            if [[ ! -e "$lib_dest" ]]; then
              mkdir -p "$lib_dest"
            fi
            echo "Qt plugin not found in destination location $lib_dest, copying..."
            cp -ar "$flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/plugins/$lib/"* "$lib_dest"
          fi
        else
          echo "ERROR: Qt plugin folder not found at expected location."
        fi
      else
        echo "Looking for Qt lib at $flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/x86_64-linux-gnu/$lib"
        if [[ -e "$flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/x86_64-linux-gnu/$lib" ]]; then
          if [[ ! -n "$lib_dest" ]]; then
              lib_dest="$gathered_libs_dest_root/qt-$qt_version"
          fi
          if [[ -e "$lib_dest/$lib" ]]; then
            echo "Lib already found in destination location $lib_dest/$lib, skipping..."
          else
            if [[ ! -e "$lib_dest" ]]; then
              mkdir -p "$lib_dest"
            fi
            echo "Library not found in destination location $lib_dest, copying..."
            cp -a "$flatpak_runtime_dir/org.kde.Platform/x86_64/$qt_version/active/files/lib/x86_64-linux-gnu/$lib"* "$lib_dest/"
          fi
        else
          echo "ERROR: Lib not found at expected location."
        fi
      fi
      continue
    fi
    if [[ ! -n "$lib_src" ]]; then
      lib_src="$flatpak_runtime_dir/$current_rd_runtime/active/files/lib/x86_64-linux-gnu"
    fi
    echo "Looking for lib at $lib_src/$lib"
    if [[ -e "$lib_src/$lib" ]]; then
      if [[ ! -n "$lib_dest" ]]; then
        lib_dest="$gathered_libs_dest_root"
      fi
      if [[ -e "$lib_dest/$lib" ]]; then
          echo "Lib already found in destination location $lib_dest, skipping..."
        else
          if [[ ! -e "$lib_dest" ]]; then
            mkdir -p "$lib_dest"
          fi
          echo "Library not found in destination location $lib_dest, copying..."
          cp -a "$lib_src/$lib"* "$lib_dest/"
        fi
    else
      echo "ERROR: Lib not found at expected location."
    fi
  done <<< "$(jq -r '.[].library' "$component_libs_file")"
done < <(find "$root_to_search" -maxdepth 2 -type f -name "component_libs.json")
