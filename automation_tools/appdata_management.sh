#!/bin/bash

# THIS SCRIPT IS BROKEN HENCE DISABLED FTM
# This script is getting the latest release notes from the wiki and add them to the appdata

source automation_tools/version_extractor.sh

# Fetch appdata version
appdata_version=$(fetch_appdata_version)
echo -e "Appdata:\t\t$appdata_version"

# Defining manifest file location
appdata_file="net.retrodeck.retrodeck.appdata.xml"

# Check if release with appdata_version already exists
if grep -q "version=\"$appdata_version\"" "$appdata_file"; then
    echo "Deleting existing release version $appdata_version..."
    
    # Remove the existing release entry
    sed -i "/<release version=\"$appdata_version\"/,/<\/release>/d" "$appdata_file"
fi

echo "Adding new release version $appdata_version..."

# Get today's date in the required format (YYYY-MM-DD)
today_date=$(date +"%Y-%m-%d")
echo "Today is $today_date"

# Construct the release snippet
release_snippet="\
<releases>
        <release version=\"$appdata_version\" date=\"$today_date\">
            <url>https://github.com/XargonWan/RetroDECK/releases/tag/$appdata_version</url>
            <description>
                RELEASE_NOTES_PLACEHOLDER
            </description>
        </release>"

# Read the entire content of the XML file
xml_content=$(cat "$appdata_file")

# Replace RELEASE_NOTES_PLACEHOLDER with the actual release notes
# TODO
git clone https://github.com/XargonWan/RetroDECK.wiki.git /tmp/wiki

# Path to the markdown file
wiki="/tmp/wiki/Version-history:-Patch-Notes.md"
# Read the markdown file until the first occurrence of "---"
latest_version_notes=""
while IFS= read -r line; do
    if [ "$line" = "---" ]; then
        break
    fi
    latest_version_notes+="$line\n"
done < "$wiki"

# Extract the version number
version_number="${latest_version_notes#*# RetroDECK }"  # Remove text before "# RetroDECK "
version_number="${version_number%% -*}"                # Remove text after " - "

# Extract sections from the latest version notes
sections=$(echo "$latest_version_notes" | awk '/##/ { print; }')

# Create a formatted section list
section_list=""
current_section=""
while IFS= read -r line; do
    if [[ "$line" == "##"* ]]; then
        if [ -n "$current_section" ]; then
            section_list+="</ul>"
        fi
        section_name="${line##*# }"
        section_list+="<p>${section_name}</p><ul>"
    elif [[ "$line" == "- "* ]]; then
        entry="${line#*- }"
        section_list+="<li>${entry}</li>"
    fi
done <<< "$sections"

if [ -n "$current_section" ]; then
    section_list+="</ul>"
fi

# Replace RELEASE_NOTES_PLACEHOLDER with the actual release notes
release_description="${release_snippet/RELEASE_NOTES_PLACEHOLDER/$section_list}"

# Append the new release snippet to the content
modified_xml_content="${xml_content/<releases>/$release_description}"

# Overwrite the original XML file with the modified content
echo "$modified_xml_content" > "$appdata_file"

# Format the XML file
#xmlstarlet fo --omit-decl "$appdata_file"
