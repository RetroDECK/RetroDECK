#!/bin/bash

# For the file paths to work correctly, call this script with this command from the cloned repo folder root:
# sh automation_tools/pre_build_automation.sh
# Different actions need different information in the task list file
# hash: Finds the SHA256 hash of a file online and updates the placeholder in the manifest. 
#     Needs the URL of the file, in this line format: hash^PLACEHOLDERTEXT^url
# latestcommit: Finds the most recent commit of a git repo and updated the placeholder in the manifest.
#     Needs the URL of the repo and the branch to find the latest commit from, in this line format: latestcommit^PLACEHOLDERTEXT^url^branch
# latestappimage: Finds the download URL and SHA256 hash of the latest AppImage release from a git repo
#     Needs the API URL of the repo, in this line format: latestappimage^PLACEHOLDERTEXT^https://api.github.com/repos/<owner-name>/<repo-name>/releases/latest
#     As this command updates two different placeholders (one for the URL, one for the file hash) in the manifest, 
#     the URL that would be used in the above example is "PLACEHOLDERTEXT" and the hash placeholder text would be "HASHPLACEHOLDERTEXT"
#     The "HASH" prefix of the placeholder text is hardcoded in the script

rd_manifest=${GITHUB_WORKSPACE}/net.retrodeck.retrodeck.yml
automation_task_list=${GITHUB_WORKSPACE}/automation_tools/automation_task_list.cfg

echo "Manifest location: $rd_manifest"
echo "Automation task list location: $automation_task_list"
echo
echo "Task list contents:"
cat "$automation_task_list"
echo

while IFS="^" read -r action placeholder url branch
do
  if [[ ! $action == "#"* ]] && [[ ! -z "$action" ]]; then
    if [[ "$action" == "hash" ]]; then
      echo
      echo "Placeholder text: $placeholder"
      echo "URL to hash: $url"
      echo
      hash=$(curl -sL "$url" | sha256sum | cut -d ' ' -f1)
      echo "Hash found: $hash"
      /bin/sed -i 's^'"$placeholder"'^'"$hash"'^' $rd_manifest
    elif [[ "$action" == "latestcommit" ]]; then
      echo
      echo "Placeholder text: $placeholder"
      echo "Repo to get latest commit from: $url branch: $branch"
      echo
      commit=$(git ls-remote "$url" "$branch" | cut -f1)
      echo "Commit found: $commit"
      /bin/sed -i 's^'"$placeholder"'^'"$commit"'^' $rd_manifest
    elif [[ "$action" == "latestappimage" ]]; then
      echo
      echo "Placeholder text: $placeholder"
      echo "Repo to look for AppImage releases: $url"
      echo
      appimageurl=$(curl -s "$url" | grep browser_download_url | grep "\.AppImage\"" | cut -d : -f 2,3 | tr -d \" | sed -n 1p | tr -d ' ')
      echo "AppImage URL found: $appimageurl"
      /bin/sed -i 's^'"$placeholder"'^'"$appimageurl"'^' $rd_manifest
      appimagehash=$(curl -sL "$appimageurl" | sha256sum | cut -d ' ' -f1)
      echo "AppImage hash found: $appimagehash"
      /bin/sed -i 's^'"HASHFOR$placeholder"'^'"$appimagehash"'^' $rd_manifest
    fi
  fi
done < "$automation_task_list"
