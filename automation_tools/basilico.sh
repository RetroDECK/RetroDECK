#!/bin/bash

# This script extracts an AppImage and sets it up in a specific folder
# then it creates a wrapper script to run the application located in /app/bin/bundled-components
# This should ensure that the components are running with their own libraries and dependencies

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 [<AppImage>] <AppName>"
    exit 1
fi

APPNAME=${@: -1} # The last argument is always the AppName

if [ "$#" -eq 2 ]; then
    APPIMAGE=$1
else
    # Find the first AppImage in the current directory
    APPIMAGE=$(find . -maxdepth 1 -type f -name "*.AppImage" | head -n 1)
    if [ -z "$APPIMAGE" ]; then
        echo "No AppImage found in the current directory."
        exit 1
    fi
fi

# Ensure the AppImage is executable
chmod +x "$APPIMAGE"

# Extract the AppImage
echo "Extracting AppImage: $APPIMAGE"
"$APPIMAGE" --appimage-extract

# Create the destination folder
DEST_FOLDER="/app/bin/bundled-components/$APPNAME"
mkdir -p "$DEST_FOLDER"

# Move the extracted AppImage to the destination folder
mv squashfs-root "$DEST_FOLDER"

# Create a wrapper script to run the application
WRAPPER_SCRIPT="/app/bin/$APPNAME"
cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
cd "$DEST_FOLDER"
./AppRun "\$@"
EOF

# Make the wrapper script executable
chmod +x "$WRAPPER_SCRIPT"

echo "AppImage for \"$APPNAME\" extracted and set up in \"$DEST_FOLDER\""
echo "Wrapper created in \"$WRAPPER_SCRIPT\""