#!/bin/bash
# This script is used to check that the versions are correct and topping the pipeline if something is wrong.
# This is designed to be run on main pipeline to check that everything is in order before building RetroDECK.

# Set the file paths
appdata="net.retrodeck.retrodeck.appdata.xml"
manifest="net.retrodeck.retrodeck.yml"
manifest_content=$(cat "$manifest")

compare_versions() {
    local manifest_version_cleaned=$(echo "$1" | sed 's/[a-zA-Z]//g')
    local appdata_version_cleaned=$(echo "$2" | sed 's/[a-zA-Z]//g')

    if [[ "$manifest_version_cleaned" == "$appdata_version_cleaned" ]]; then
        return 0  # Versions are equal
    fi

    local IFS=.
    local manifest_parts=($manifest_version_cleaned)
    local appdata_parts=($appdata_version_cleaned)

    for ((i=0; i<${#manifest_parts[@]}; i++)); do
        if ((manifest_parts[i] > appdata_parts[i])); then
            return 1  # Manifest version is greater
        elif ((manifest_parts[i] < appdata_parts[i])); then
            return 2  # Appdata version is greater
        fi
    done

    return 0  # Versions are equal
}

# Getting latest RetroDECK release info
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/XargonWan/RetroDECK/releases/latest")
# Extracting tag name from the latest release
repo_version=$(echo "$LATEST_RELEASE" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
# Printing results
echo -e "Online repository:\t$repo_version"

# Extract the version from the net.retrodeck.retrodeck.appdata.xml file
appdata_version=$(grep -oPm1 "(?<=<release version=\")[^\"]+" "$appdata")
echo -e "appdata.yml:\t\t$appdata_version"

# Use awk to extract the value of the first iteration of VERSION variable
manifest_version=$(echo "$manifest_content" | awk '/VERSION=/ && !/#/ { sub(/.*VERSION=/, ""); sub(/#.*/, ""); print; exit }')
# Trim leading and trailing whitespace
manifest_version=$(echo "$manifest_version" | awk '{$1=$1;print}')
echo -e "manifest.xml:\t\t$manifest_version"

echo ""

compare_versions "$manifest_version" "$appdata_version"
result=$?

if [ "$result" -eq 1 ]; then
    echo "Manifest version is greater than appdata version. Please fix it."
elif [ "$result" -eq 2 ]; then
    echo "Appdata version is greater than manifest version. Please fix it."
    exit 1
else
    echo "The versions in the manifest and in the appdata are equal. Well done, you didnt forget the patch notes (probably)!"
fi