#!/bin/bash

# THIS SCRIPT IS BROKEN HENCE DISABLED FTM
# This script is getting the latest release notes from the wiki and add them to the metainfo

source automation_tools/version_extractor.sh

# Fetch metainfo version
metainfo_version=$(fetch_metainfo_version)
echo -e "metainfo:\t\t$metainfo_version"

# Defining manifest file location
metainfo_file="net.retrodeck.retrodeck.metainfo.xml"

# Check if release with metainfo_version already exists
if grep -q "version=\"$metainfo_version\"" "$metainfo_file"; then
    echo -e "Deleting existing release version $metainfo_version..."
    
    # Remove the existing release entry
    sed -i "/<release version=\"$metainfo_version\"/,/<\/release>/d" "$metainfo_file"
fi

echo -e "Adding new release version $metainfo_version..."

# Get today's date in the required format (YYYY-MM-DD)
today_date=$(date +"%Y-%m-%d")
echo -e "Today is $today_date"

# Construct the release snippet
release_snippet="\
<releases>
        <release version=\"$metainfo_version\" date=\"$today_date\">
            <url>https://github.com/RetroDECK/RetroDECK/releases/tag/$metainfo_version</url>
            <description>
                RELEASE_NOTES_PLACEHOLDER
            </description>
        </release>"

# Read the entire content of the XML file
xml_content=$(cat "$metainfo_file")

# Replace RELEASE_NOTES_PLACEHOLDER with the actual release notes
# TODO
rm -rf /tmp/wiki
git clone https://github.com/RetroDECK/RetroDECK.wiki.git /tmp/wiki

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
echo "$modified_xml_content" > "$metainfo_file"

# Format the XML file
#xmlstarlet fo --omit-decl "$metainfo_file"
