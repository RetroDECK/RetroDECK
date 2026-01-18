#!/bin/bash

echo "Found the following components in the components directory:"
ls -1 components/*.tar.gz || ( echo "Wait... No components found actually." && exit 1 )


# When CI/CD mode is enabled, delete components after installation to save space
CICD="false"
if [[ "$1" == "--cicd" ]]; then
  echo "Running in CI/CD mode (--cicd argument detected)."
  CICD="true"
fi

if [ -z "$FLATPAK_DEST" ]; then
  echo "FLATPAK_DEST is not set. Please run this script inside a Flatpak build environment or export it manually."
  exit 1
fi

shopt -s nullglob
archives=(components/*.tar.gz)
if [ ${#archives[@]} -eq 0 ]; then
  echo "Error: No components found in components directory."
  exit 1
fi

for archive in "${archives[@]}"; do
  component_name="$(basename "${archive%.tar.gz}")"
  component_path="${FLATPAK_DEST}/retrodeck/components/${component_name}"

  echo "-------------------------------------"
  echo "Installing component $component_name"
  echo "-------------------------------------"

  # Skip if archive does not exist
  if [ ! -e "$archive" ]; then
      continue
  fi

  echo "Extracting $archive..."
  mkdir -p "$component_path"

  if tar -xzf "$archive" -C "$component_path"; then
    echo "$archive extracted successfully in $component_path."
    echo "Contents of $component_path:"
    ls "$component_path"

    if [[ -d "$component_path/shared-libs" ]]; then # If component includes a shared-libs folder
      echo "$component_path/shared-libs folder found, merging with core shared-libs"
      
      if [[ ! -d "${FLATPAK_DEST}/retrodeck/components/shared-libs" ]]; then
        mkdir -p "${FLATPAK_DEST}/retrodeck/components/shared-libs"
      fi

      while read -r source_file; do
        relative_filepath="${source_file##$component_path/shared-libs/}"
        if [[ ! -e "${FLATPAK_DEST}/retrodeck/components/shared-libs/$relative_filepath" ]]; then
            echo "$relative_filepath not found in core shared-libs, copying..."
            if [[ ! -d "$(dirname "${FLATPAK_DEST}/retrodeck/components/shared-libs/$relative_filepath")" ]]; then
              mkdir -p "$(dirname "${FLATPAK_DEST}/retrodeck/components/shared-libs/$relative_filepath")"
            fi
            cp -a "$source_file" "${FLATPAK_DEST}/retrodeck/components/shared-libs/$relative_filepath"
        else
            echo "${FLATPAK_DEST}/retrodeck/components/shared-libs/$relative_filepath already exists in core shared-libs, skipping..."
        fi
      done < <(find "$component_path/shared-libs" -not -type d)

      rm -rf "$component_path/shared-libs" # Cleanup leftover shared-libs folder in component folder
    else
      echo "Component $component_path does not contain any shared-libs, no merge needed."
    fi

    if [[ -d "$component_path/shared-data" ]]; then # If component includes a shared-data folder
      echo "$component_path/shared-data folder found, merging with core shared-data"

      if [[ ! -d "${FLATPAK_DEST}/retrodeck/components/shared-data" ]]; then
        mkdir -p "${FLATPAK_DEST}/retrodeck/components/shared-data"
      fi

      while read -r source_file; do
        relative_filepath="${source_file##$component_path/shared-data/}"
        if [[ ! -e "${FLATPAK_DEST}/retrodeck/components/shared-data/$relative_filepath" ]]; then
            echo "$relative_filepath not found in core shared-data, copying..."
            if [[ ! -d "$(dirname "${FLATPAK_DEST}/retrodeck/components/shared-data/$relative_filepath")" ]]; then
              mkdir -p "$(dirname "${FLATPAK_DEST}/retrodeck/components/shared-data/$relative_filepath")"
            fi
            cp -a "$source_file" "${FLATPAK_DEST}/retrodeck/components/shared-data/$relative_filepath"
        else
            echo "${FLATPAK_DEST}/retrodeck/components/shared-data/$relative_filepath already exists in core shared-data, skipping..."
        fi
      done < <(find "$component_path/shared-data" -not -type d)

      rm -rf "$component_path/shared-data" # Cleanup leftover shared-data folder in component folder
    else
      echo "Component $component_path does not contain any shared-data, no merge needed."
    fi

    # If running in CI/CD, delete the components folder to reclaim space
    # This solves an issue where the  runner runs out of space and some components are not installed

    if [ "$CICD" == "true" ]; then
      echo "Running in CI/CD mode, deleting components folder to reclaim space."
      rm -rf "$archive"
      echo "Deleted $archive to reclaim space."
    fi
  else
    echo "Failed to extract $archive."
  fi
done

echo "-------------------------------------"
echo "  Finished installing components."
echo "-------------------------------------"
echo ""

echo "Listing installed components in ${FLATPAK_DEST}/retrodeck/components:"
ls -1 "${FLATPAK_DEST}/retrodeck/components" || echo "No components installed."

# Check if components_version_list.md file exists and copy or warn
if [ -f components_version_list.md ]; then
  found_file=$(find . -name components_version_list.md | head -n 1)
  if [ -n "$found_file" ]; then
      cp "$found_file" "${FLATPAK_DEST}/retrodeck/components_version_list.md"
  else
      echo "Warning: components_version_list.md file not found by find, skipping."
  fi
  echo "Component version file copied successfully."
  echo "Component version:"
  cat "${FLATPAK_DEST}/retrodeck/components_version_list.md"
else
  echo "Warning: components_version_list.md file not found, skipping."
fi
