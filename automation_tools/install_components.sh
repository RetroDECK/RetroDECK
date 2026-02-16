#!/bin/bash

echo "Found the following components in the components directory:"
ls -1 components/*.tar.gz || ( echo "Wait... No components found actually." && exit 1 )

if [[ -z "$FLATPAK_DEST" ]]; then
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
  if [[ ! -e "$archive" ]]; then
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

      cp -a --no-clobber --verbose "$component_path/shared-libs/." "${FLATPAK_DEST}/retrodeck/components/shared-libs/"

      rm -rf "$component_path/shared-libs" # Cleanup leftover shared-libs folder in component folder
    else
      echo "Component $component_path does not contain any shared-libs, no merge needed."
    fi

    if [[ -d "$component_path/shared-data" ]]; then # If component includes a shared-data folder
      echo "$component_path/shared-data folder found, merging with core shared-data"

      if [[ ! -d "${FLATPAK_DEST}/retrodeck/components/shared-data" ]]; then
        mkdir -p "${FLATPAK_DEST}/retrodeck/components/shared-data"
      fi

      cp -a --no-clobber --verbose "$component_path/shared-data/." "${FLATPAK_DEST}/retrodeck/components/shared-data/"

      rm -rf "$component_path/shared-data" # Cleanup leftover shared-data folder in component folder
    else
      echo "Component $component_path does not contain any shared-data, no merge needed."
    fi

    rm -rf "$archive"
    echo "Deleted $archive to reclaim space."
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

# Check if components_metadata.json file exists and copy or warn
if [[ -f "components_metadata.json" ]]; then
  cp "components_metadata.json" "${FLATPAK_DEST}/retrodeck/components_metadata.json"
  echo "Component version file copied successfully."
  echo "Component version:"
  cat "${FLATPAK_DEST}/retrodeck/components_metadata.json"
else
  echo "Warning: components_metadata.json file not found, skipping."
fi
