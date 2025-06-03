#!/bin/bash

echo "Found the following components in the components directory:"
ls -1 components/*.tar.gz || ( echo "Wait... No components found actually." && exit 1 ) 

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

    [ -e "$archive" ] || continue
    echo "Extracting $archive..."
    mkdir -p "$component_path"
    tar -xzf "$archive" -C "$component_path" && echo "$archive extracted successfully in $component_path." || echo "Failed to extract $archive."

    # Symlink component_launcher.sh if it exists
    launcher_path="$component_path/component_launcher.sh"
    if [ -f "$launcher_path" ]; then
        # Check if FLATPAK_DEST contains 'current/active/files' (i.e., injecting into a Flatpak)
        if [[ "$FLATPAK_DEST" == *current/active/files* ]]; then
            # Use Flatpak's virtual path for the symlink target
            virtual_launcher_path="/app/retrodeck/components/${component_name}/component_launcher.sh"
            echo "Creating symlink for $component_name from $virtual_launcher_path to ${FLATPAK_DEST}/bin/${component_name} (Flatpak injection context)"
            ln -sf "$virtual_launcher_path" "${FLATPAK_DEST}/bin/${component_name}" || echo "Failed to create symlink for $component_name"
        else
            echo "Creating symlink for $component_name from $launcher_path to ${FLATPAK_DEST}/bin/${component_name}"
            ln -sf "$launcher_path" "${FLATPAK_DEST}/bin/${component_name}" || echo "Failed to create symlink for $component_name"
        fi
    else
        echo "Warning: component_launcher.sh not found for $component_name, skipping symlink creation."
    fi
done

# Check if components_version_list.md file exists and copy or warn
if [ -f components_version_list.md ]; then
    cp components_version_list.md "${FLATPAK_DEST}/retrodeck/components_version_list.md"
    echo "Component version file copied successfully."
    echo "Component version:"
    cat "${FLATPAK_DEST}/retrodeck/components_version_list.md"
else
    echo "Warning: components_version_list.md file not found, skipping."
fi