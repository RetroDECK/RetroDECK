#!/bin/bash

# This script extracts an AppImage or a Flatpak artifact and sets up a wrapper script to run the application.
# Usage: $0 [artifact_file] <AppName>
# If no artifact_file is specified, the script first searches for an AppImage in the current directory.
# If found, it extracts the AppImage and exits.
# If not, it searches for an archive (zip, tar.gz, or tar) and extracts it as a Flatpak artifact.

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 [artifact_file] <AppName>"
    exit 1
fi

# Determine the application name (always the last argument)
APPNAME="${@: -1}"
WRAPPER_SCRIPT="/app/bin/$APPNAME"

# Determine the artifact file:
# If two arguments are provided, the first is the artifact.
# If only one argument is provided, search for an AppImage first,
# then for a supported archive.
if [ "$#" -eq 2 ]; then
    ARTIFACT="$1"
else
    ARTIFACT=$(find . -maxdepth 1 -type f -name "*.AppImage" | head -n 1)
    if [ -z "$ARTIFACT" ]; then
        ARTIFACT=$(find . -maxdepth 1 -type f \( -name "*.zip" -o -name "*.tar.gz" -o -name "*.tar" \) | head -n 1)
    fi
fi

# Ensure an artifact was found
if [ -z "$ARTIFACT" ]; then
    echo "No artifact found in the current directory."
    exit 1
fi

# Check if the artifact is an AppImage; if so, extract it; otherwise, treat it as a Flatpak artifact.
if [[ "$ARTIFACT" == *.AppImage ]]; then
    APPIMAGE="$ARTIFACT"
    extract_appimage
    exit 0
else
    echo "Not an AppImage, treating as a Flatpak artifact."
    extract_flatpak_artifact
    exit 0
fi

extract_appimage() {
    # Ensure the AppImage is executable
    chmod +x "$APPIMAGE"
    echo "Extracting AppImage: $APPIMAGE"
    "$APPIMAGE" --appimage-extract

    DEST_FOLDER="/app/bin/rd-components/$APPNAME"
    mkdir -p "$DEST_FOLDER"
    mv squashfs-root "$DEST_FOLDER"

    # Create a wrapper script to run the application
    cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
cd "$DEST_FOLDER"
./AppRun "\$@"
EOF

    chmod +x "$WRAPPER_SCRIPT"

    echo "AppImage for \"$APPNAME\" extracted and set up in \"$DEST_FOLDER\""
    echo "Wrapper created in \"$WRAPPER_SCRIPT\""
}

extract_flatpak_artifact() {
    EXTRACT_DIR="extracted"

    # Determine the file type and extract accordingly
    case "$ARTIFACT" in
        *.zip)
            echo "Extracting ZIP file: $ARTIFACT"
            unzip -q "$ARTIFACT" -d "$EXTRACT_DIR"
            ;;
        *.tar.gz)
            echo "Extracting TAR.GZ file: $ARTIFACT"
            mkdir -p "$EXTRACT_DIR"
            tar -xzf "$ARTIFACT" -C "$EXTRACT_DIR"
            ;;
        *.tar)
            echo "Extracting TAR file: $ARTIFACT"
            mkdir -p "$EXTRACT_DIR"
            tar -xf "$ARTIFACT" -C "$EXTRACT_DIR"
            ;;
        *)
            echo "Unsupported file type: $ARTIFACT"
            exit 1
            ;;
    esac

    COMPONENT_ROOT="/app/bin/rd-components/$APPNAME"
    mkdir -p "$COMPONENT_ROOT"

    rm -f "$EXTRACT_DIR/manifest.json"
    mv -f "$EXTRACT_DIR/lib" "$COMPONENT_ROOT"
    chmod +x "$EXTRACT_DIR/bin/"*
    cp -r "$EXTRACT_DIR"/* "$COMPONENT_ROOT"
    rm -rf "$EXTRACT_DIR"

    cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
LD_LIBRARY_PATH="$COMPONENT_ROOT/lib:\$LD_LIBRARY_PATH" "$COMPONENT_ROOT/bin/$(basename "$APPNAME")" "\$@"
EOF

    chmod +x "$WRAPPER_SCRIPT"

    echo "Flatpak artifact for \"$APPNAME\" extracted and set up in \"$COMPONENT_ROOT\""
    echo "Wrapper created in \"$WRAPPER_SCRIPT\""
}