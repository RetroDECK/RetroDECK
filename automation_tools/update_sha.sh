#!/bin/bash

# For the file paths to work correctly, call this script with this command from the cloned repo folder root:
# sh automation_tools/update_sha.sh

rd_manifest=${GITHUB_WORKSPACE}/net.retrodeck.retrodeck.yml
sha_update_list=${GITHUB_WORKSPACE}/automation_tools/sha_update_list.cfg

echo "Manifest location: $rd_manifest"
echo "Hash update list location: $sha_update_list"
echo
echo "Update list contents:"
cat "$sha_update_list"
echo

while IFS="^" read -r url placeholder
do
  echo "Placeholder text: $placeholder"
  echo "URL to hash: $url"
  hash=$(curl -sL "$url" | sha256sum | cut -d ' ' -f1)
  sed -i 's^'"$placeholder"'^'"$hash"'^' $rd_manifest
done < <(cat "$sha_update_list")