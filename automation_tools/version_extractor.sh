#!/bin/bash

# This script is intended to gather version information from various sources:
# RetroDECK repository
# Appdata.xml file
# Manifest YAML file
# It consists of three functions, each responsible for retrieving a specific version-related data.

appdata="net.retrodeck.retrodeck.appdata.xml"
manifest="net.retrodeck.retrodeck.yml"
manifest_content=$(cat "$manifest")

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
