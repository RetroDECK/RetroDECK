#!/bin/bash

# Set the file paths
appdata="net.retrodeck.retrodeck.appdata.xml"
manifest="net.retrodeck.retrodeck.yml"
manifest_content=$(cat "$manifest")

# Getting latest RetroDECK release info
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/XargonWan/RetroDECK/releases/latest")
# Extracting tag name from the latest release
TAG=$(echo "$LATEST_RELEASE" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
# Printing results
echo "repo: $TAG"

# Extract the version from the net.retrodeck.retrodeck.appdata.xml file
appdata_version=$(grep -oPm1 "(?<=<release version=\")[^\"]+" "$appdata")
echo "xml: $appdata_version"

# Use awk to extract the value of the first iteration of VERSION variable
manifest_version=$(echo "$manifest_content" | awk '/VERSION=/ && !/#/ { sub(/.*VERSION=/, ""); sub(/#.*/, ""); print; exit }')
# Trim leading and trailing whitespace
manifest_version=$(echo "$manifest_version" | awk '{$1=$1;print}')
echo "yml: $manifest_version"

# Check if the versions are equal
if [ "$appdata_version" == "$manifest_version" ]; then
    echo "The versions in the manifest and in the appdata are equal. Well done, you didnt forget the patch notes (probably)!"
else
    echo "Error: The versions in the manifest and in the appdata mismatch."
    exit 1
fi