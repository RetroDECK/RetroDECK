#!/bin/bash

# For the file paths to work correctly, call this script with this command from the cloned repo folder root:
# sh automation_tools/update_sha.sh

rd_manifest=${GITHUB_WORKSPACE}/net.retrodeck.retrodeck.yml
sha_update_list=${GITHUB_WORKSPACE}/automation_tools/sha_update_list.cfg

while IFS="^" read -r url placeholder
do
  hash=$(curl -sL "$url" | sha256sum | cut -d ' ' -f1)
  sed -i 's^'"$placeholder"'^'"$hash"'^' $rd_manifest
done < $sha_update_list