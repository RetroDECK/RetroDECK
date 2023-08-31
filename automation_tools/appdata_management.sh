#!/bin/bash

source automation_tools/version_extractor.sh

# Fetch appdata version
appdata_version=$(fetch_appdata_version)
echo -e "Appdata:\t\t$appdata_version"
# Fetch manifest version
manifest_version=$(fetch_manifest_version)
echo -e "Manifest:\t\t$manifest_version"

# Defining manifest file location
appdata_file="net.retrodeck.retrodeck.appdata.xml"

# Check if release with manifest_version already exists
if grep -q "version=\"$manifest_version\"" "$appdata_file"; then
    echo "The release notes for the latest version are already present in the appdata"
else
    # Get today's date in the required format (YYYY-MM-DD)
    today_date=$(date +"%Y-%m-%d")
    echo "Today is $today_date"

    # Construct the release snippet
    release_snippet="\
<releases>
        <release version=\"$manifest_version\" date=\"$today_date\">
            <url>https://github.com/XargonWan/RetroDECK/releases/tag/$manifest_version</url>
            <description>
                RELEASE_NOTES_PLACEHOLDER
            </description>
        </release>"

    # Read the entire content of the XML file
    xml_content=$(cat "$appdata_file")

    # Replace RELEASE_NOTES_PLACEHOLDER with the actual release notes
    # TODO

    # Append the new release snippet to the content
    modified_xml_content="${xml_content/<releases>/$release_snippet}"

    # Overwrite the original XML file with the modified content
    echo "$modified_xml_content" > "$appdata_file"
fi
    # Format the XML file
    xmlstarlet fo --omit-decl "$appdata_file"