#!/bin/bash

# This script is intended to gather version information from various sources:
# RetroDECK repository
# Appdata.xml file
# Manifest YAML file
# It consists of three functions, each responsible for retrieving a specific version-related data.

source automation_tools/version_extractor.sh

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


fetch_repo_version(){
    # Getting latest RetroDECK release info
    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/XargonWan/RetroDECK/releases/latest")
    # Extracting tag name from the latest release
    repo_version=$(echo "$LATEST_RELEASE" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    # Printing results
    echo "$repo_version"
}

fetch_appdata_version(){
    # Extract the version from the net.retrodeck.retrodeck.appdata.xml file
    appdata_version=$(grep -oPm1 "(?<=<release version=\")[^\"]+" "$appdata")
    echo "$appdata_version"
}

fetch_manifest_version(){
    # Use awk to extract the value of the first iteration of VERSION variable
    manifest_version=$(echo "$manifest_content" | awk '/VERSION=/ && !/#/ { sub(/.*VERSION=/, ""); sub(/#.*/, ""); print; exit }')
    # Trim leading and trailing whitespace
    manifest_version=$(echo "$manifest_version" | awk '{gsub(/[^0-9.a-zA-Z]/,""); print}')
    echo "$manifest_version"
}

repo_version=$(fetch_repo_version)
echo -e "Online repository:\t$repo_version"

manifest_version=$(fetch_manifest_version)
echo -e "Manifest:\t\t$manifest_version"

appdata_version=$(fetch_appdata_version)
echo -e "Appdata:\t\t$appdata_version"

# Additional checks
if [[ "$manifest_version" == "main" || "$manifest_version" == "THISBRANCH" ]]; then
    echo "Manifest version cannot be 'main' or 'THISBRANCH'. Please fix it."
    exit 1
fi

if [[ "$appdata_version" != "$manifest_version" ]]; then
    echo "Appdata version is not equal to manifest version. Please fix it."
    exit 1
fi

compare_versions "$repo_version" "$manifest_version"
result=$?

if [ "$result" -eq 1 ]; then
    echo "Repository version is less than manifest version. Please fix it."
    exit 1
fi

echo "All checks passed. Well done!"