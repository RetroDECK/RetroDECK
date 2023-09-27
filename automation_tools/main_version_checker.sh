#!/bin/bash
# This script is used to check that the versions are correct and stopping the pipeline if something is wrong.
# This is designed to be run on the main pipeline to check that everything is in order before building RetroDECK.

source automation_tools/version_extractor.sh

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