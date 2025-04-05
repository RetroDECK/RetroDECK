#!/bin/bash
# This script installs an application from either a flatpak artifact or an AppImage.
#
# Usage:
#   ./script.sh <AppName> [artifact_file]
#
# The script logic is as follows:
# 1. The first parameter is the application name (APPNAME).
# 2. The second parameter is optional and represents the artifact.
#    Supported artifact types are:
#      - An extracted directory (indicated by "."), which corresponds to
#        "files/bin/<AppName>"
#      - An AppImage file (*.AppImage)
#      - A compressed file (*.tar, *.tar.gz, *.zip)
#
# If no artifact parameter is provided, the script searches in the following order:
#   a. Check if the extracted directory "files/bin/<AppName>" exists.
#   b. Look for an AppImage file in the current directory.
#   c. Look for a compressed file in the current directory.
#
# Depending on the artifact type:
# - For an extracted directory, install_flatpak_artifact is called.
# - For an AppImage, install_appimage is called.
# - For a compressed file, the archive is extracted to a temporary directory (EXTRACT_DIR)
#   and then install_flatpak_artifact is called on the extracted files.
#
# The functions install_appimage and install_flatpak_artifact create a wrapper script
# to launch the installed application.
#
# Note: The script assumes that the artifact's internal layout corresponds to the expected structure.

#---------------------------------------------
# Function: install_appimage
# Installs an application from an AppImage artifact.
#---------------------------------------------
install_appimage() {
    # Ensure the AppImage is executable
    chmod +x "$APPIMAGE"
    echo "Extracting AppImage: $APPIMAGE"
    "$APPIMAGE" --appimage-extract

    DEST_FOLDER="/app/bin/rd-components/$APPNAME"
    mkdir -p "$DEST_FOLDER"
    mv squashfs-root/* "$DEST_FOLDER"

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

#---------------------------------------------
# Function: install_flatpak_artifact
# Installs an application from a flatpak artifact extracted directory.
# Relies on the EXTRACT_DIR variable set in the main script.
#---------------------------------------------
install_flatpak_artifact() {

    echo "Installing flatpak artifact for \"$APPNAME\""

    COMPONENT_ROOT="/app/bin/rd-components/$APPNAME"
    mkdir -p "$COMPONENT_ROOT"

    # Remove manifest.json if it exists
    if [ -f "$EXTRACT_DIR/manifest.json" ]; then
        rm -f "$EXTRACT_DIR/manifest.json"
    fi

    # If a 'lib' directory exists, move it to COMPONENT_ROOT
    if [ -d "$EXTRACT_DIR/lib" ]; then
        mv -f "$EXTRACT_DIR/lib" "$COMPONENT_ROOT"
    fi

    # Make binaries executable if the bin directory exists
    if [ -d "$EXTRACT_DIR/bin" ]; then
        chmod +x "$EXTRACT_DIR/bin/"*
    fi

    rm -rf "metadata"* || echo "No metadata files found, no need for removal, proceding."

    # Copy all extracted files to COMPONENT_ROOT
    cp -r "$EXTRACT_DIR"/* "$COMPONENT_ROOT"

    # Create a wrapper script to launch the application
    cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
LD_LIBRARY_PATH="$COMPONENT_ROOT/files/lib:$COMPONENT_ROOT/var/lib:\$LD_LIBRARY_PATH" "$COMPONENT_ROOT/files/bin/$(basename "$APPNAME")" "\$@"
EOF

    chmod +x "$WRAPPER_SCRIPT"

    echo "Flatpak artifact for \"$APPNAME\" set up in \"$COMPONENT_ROOT\""
    echo "Wrapper created in \"$WRAPPER_SCRIPT\""
}

list_files(){

        echo ""
        echo "Contents of the current directory:"
        ls .
        echo ""
        if [ -d "files" ]; then
            echo "Contents of 'files' directory:"
            ls -l "files"
            echo ""
            if [ -d "files/bin" ]; then
                echo "Contents of 'files/bin' directory:"
                ls -l "files/bin"
                echo ""
            fi
        fi

}

#---------------------------------------------
# Main Script Logic
#---------------------------------------------

# Validate the number of arguments: allow 1 or 2 parameters.
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <AppName> [artifact_file]"
    exit 1
fi

APPNAME="$1"
ARTIFACT_PARAM="$2"  # This parameter is optional.
WRAPPER_SCRIPT="/app/bin/$APPNAME"

# Determine which artifact to use.
if [ -n "$ARTIFACT_PARAM" ]; then
    # If an artifact parameter is provided.
    if [ "$ARTIFACT_PARAM" == "." ]; then
        # If the parameter is ".", check for the extracted directory.
        if [ -d "files/bin/$APPNAME" ]; then
            ARTIFACT="extracted_dir"
            EXTRACT_DIR="files"
        else
            echo "Artifact set to current directory but 'files/bin/$APPNAME' not found."
            list_files
            exit 1
        fi
    else
        # Use the provided artifact file.
        if [ ! -f "$ARTIFACT_PARAM" ]; then
            echo "Artifact file '$ARTIFACT_PARAM' does not exist."
            list_files
            exit 1
        fi
        ARTIFACT="$ARTIFACT_PARAM"
    fi
else
    # No artifact parameter provided; search in order.
    # 1. Check for an extracted directory artifact.
    if [ -f "files/bin/$APPNAME" ]; then
        ARTIFACT="extracted_dir"
        EXTRACT_DIR="."
    else
        # 2. Search for an AppImage in the current directory.
        ARTIFACT=$(find . -maxdepth 1 -type f -name "*.AppImage" | head -n 1)
        if [ -n "$ARTIFACT" ]; then
            APPIMAGE="$ARTIFACT"
            echo "AppImage artifact found: $APPIMAGE"
            install_appimage
            exit 0
        fi
        # 3. Search for a compressed artifact (zip, tar.gz, or tar).
        ARTIFACT=$(find . -maxdepth 1 -type f \( -name "*.zip" -o -name "*.tar.gz" -o -name "*.tar" \) | head -n 1)
    fi
fi

# If no artifact was found, list the directory contents and exit.
if [ -z "$ARTIFACT" ]; then
    echo "No artifact found in the current directory. Listing contents:"
    list_files
    exit 1
fi

echo "Artifact found: $ARTIFACT"

# Process the artifact based on its type.
case "$ARTIFACT" in
    *.AppImage)
        APPIMAGE="$ARTIFACT"
        echo "AppImage found: $APPIMAGE, installing..."
        install_appimage
        exit 0
        ;;
    *.tar | *.tar.gz | *.zip)
        EXTRACT_DIR="extracted"
        echo "Compressed artifact found: $ARTIFACT. Extracting..."
        # Extract the artifact based on its file extension.
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

        install_flatpak_artifact
        exit 0
        ;;
    "extracted_dir")
        # Artifact is already extracted.
        install_flatpak_artifact
        exit 0
        ;;
    *)
        echo "Artifact '$ARTIFACT' is not supported. Listing contents:"
        list_files
        exit 1
        ;;
esac