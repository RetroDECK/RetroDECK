#!/bin/bash

# This script is intended to gather version information from various sources:
# RetroDECK repository
# Metainfo.xml file
# It consists of three functions, each responsible for retrieving a specific version-related data.

metainfo="net.retrodeck.retrodeck.metainfo.xml"

fetch_repo_version(){
    # Getting latest RetroDECK release info
    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/RetroDECK/RetroDECK/releases/latest")
    # Extracting tag name from the latest release
    repo_version=$(echo "$LATEST_RELEASE" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    # Printing results
    echo "$repo_version"
}

fetch_metainfo_version(){
    # Extract the version number from the metainfo XML file
    VERSION=$(xmlstarlet sel -t -v "/component/releases/release[1]/@version" net.retrodeck.retrodeck.metainfo.xml)
    echo "$VERSION"
}

# TODO: cooker_build_id logic can be moved here

fetch_actual_version(){
    # If the current Git branch is not 'main', append 'cooker-' to the version number
    if [[ "${GITHUB_REF_NAME}" != "main" ]]; then
        VERSION="cooker-$(cat ./version)-$(cat buildid)"
    else # Otherwise, if we're on main, use the version number as is
        VERSION=$(cat ./version)
    fi
    echo "$VERSION"
}

echo "Version extractor functions loaded"
