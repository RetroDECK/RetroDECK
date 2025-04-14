#!/bin/bash
# Input files
ES_SYSTEMS_FILE="../ES-DE/resources/systems/linux/es_systems.xml"
MIME_FILE="config/retrodeck/net.retrodeck.retrodeck.mime.xml"

# List of extensions to ignore
IGNORED_EXTENSIONS=". .appimage .cue .png .po"

# Check if xmlstarlet is installed
if ! command -v xmlstarlet &> /dev/null; then
    echo "Error: xmlstarlet is not installed."
    echo "Please install it using your package manager (e.g., sudo apt install xmlstarlet)."
    exit 1
fi

# Temporary files
EXTENSIONS_FILE=$(mktemp)

# Extract extensions from the <extension> field in es_systems.xml
grep -oP '<extension>\K.*?(?=</extension>)' "$ES_SYSTEMS_FILE" | \
tr ' ' '\n' | \
awk '{print tolower($0)}' | \
sort -u > "$EXTENSIONS_FILE"

# Create a new MIME file with the correct base structure
cat > "$MIME_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
    <mime-type type="application/retro-game">
        <comment>Retro Game</comment>
EOF

# Add new <glob> elements to the MIME file
while IFS= read -r ext; do
    # Skip ignored extensions
    if [[ "$IGNORED_EXTENSIONS" =~ (^|[[:space:]])"$ext"($|[[:space:]]) ]]; then
        echo "Skipping ignored extension: $ext"
        continue
    fi
    
    # Add the <glob> element for the extension
    echo "Adding glob pattern for extension: $ext"
    echo "        <glob pattern=\"*$ext\"/>" >> "$MIME_FILE"
done < "$EXTENSIONS_FILE"

# Close the XML tags
echo "    </mime-type>
</mime-info>" >> "$MIME_FILE"

# Ensure proper formatting using xmlstarlet
xmlstarlet fo --indent-tab "$MIME_FILE" > "$MIME_FILE.tmp" && mv "$MIME_FILE.tmp" "$MIME_FILE"

# Clean up temporary files
rm -f "$EXTENSIONS_FILE"

echo "MIME file updated successfully at $MIME_FILE"
