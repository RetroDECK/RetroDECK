#!/bin/bash

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
    manifest_version=$(echo "$manifest_version" | awk '{$1=$1;print}')
    echo "$manifest_version"
}
