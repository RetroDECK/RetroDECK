#!/bin/bash

# Set script to exit immediately on any error
set -e

# For the file paths to work correctly, call this script with this command from the cloned repo folder root:
# sh automation_tools/manifest_placeholder_replacer.sh
# Different actions need different information in the task list file
# branch: This changes the placeholder text to the currently-detected GIT branch if an automated build was started from a PR environment.
# hash: Finds the SHA256 hash of a file online and updates the placeholder in the manifest.
#     Needs the URL of the file, in this line format: hash^PLACEHOLDERTEXT^url
# latestcommit: Finds the most recent commit of a git repo and updates the placeholder in the manifest.
#     Needs the URL of the repo and the branch to find the latest commit from, in this line format: latestcommit^PLACEHOLDERTEXT^url^branch
# latestghtag: Finds the most recent tag on a GitHub repo, for repos that don't have normal releases, but also shouldn't use the latest commit
#     Needs the URL of the repo, in this line format: latestghtag^PLACEHOLDERTEXT^url
# latestghrelease: Finds the download URL and SHA256 hash of the latest release from a git repo.
#     Needs the API URL of the repo, in this line format: latestghrelease^PLACEHOLDERTEXT^https://api.github.com/repos/<owner-name>/<repo-name>/releases/latest^<file suffix>
#     As this command updates two different placeholders (one for the URL, one for the file hash) in the manifest,
#     the URL that would be used in the above example is "PLACEHOLDERTEXT" and the hash placeholder text would be "HASHPLACEHOLDERTEXT"
#     The "HASH" prefix of the hash placeholder text is hardcoded in the script.
#     The <file_suffix> will be the file extension or other identifying suffix at the end of the file name that can be used to select from multiple releases.
#     Example: If there are these file options for a given release:
#     yuzu-mainline-20240205-149629642.AppImage
#     yuzu-linux-20240205-149629642-source.tar.xz
#     yuzu-linux-20240205-149629642-debug.tar.xz
#     Entering "AppImage" (without quotes) for the <file_suffix> will identify yuzu-mainline-20240205-149629642.AppImage
#     Entering "source-.tar.xz" (without quotes) for the <file_suffix> will identify yuzu-linux-20240205-149629642-source.tar.xz
#     Entering "debug-tar.xz" (without quotes) for the <file_suffix> will identify yuzu-linux-20240205-149629642-debug.tar.xz
#     As a file extension like ".tar.xz" can apply to multiple file options, the entire part that is appended to each release name should be included.
#     The <file_suffix> will also only consider entries where the given suffix is at the end of the file name. So "AppImage" will identify "file.AppImage" but not "file.AppImage.zsync"
# latestghreleasesha: Finds the SHA256 hash of a specific asset in the latest release from a git repo.
#     Needs the API URL of the repo, in this line format: latestghreleasesha^PLACEHOLDERTEXT^https://api.github.com/repos/<owner-name>/<repo-name>/releases/latest^<file suffix>
#     This command updates the placeholder in the manifest with the SHA256 hash of the specified asset.
# outside_file: Prints the contents of a file from the build environment (such as the buildid file) and replaces the placeholder text with those contents.
# outside_env_var: Gets the value of an environmental variable from the build environment (the output of "echo $var" from the terminal) and replaces the placeholder text with that value.
# custom_command: Runs a single command explicitly as written in the $URL field of the task list, including variable and command expansion. This should work the same as if you were running the command directly from the terminal.
#     This command does not need a PLACEHOLDERTEXT field in the task list, so needs to be in this syntax: custom_command^^$COMMAND
# url: This is used to calculate a dynamic URL and the value to the $calculated_url environmental variable, for use in other subsequent commands.

# Define paths
if [ -z "$ROOT_FOLDER" ]; then
  echo "Error: ROOT_FOLDER is not set. Please set it to the root directory of the cloned repository."
  echo "You can set it by running: export ROOT_FOLDER=/path/to/repo"
  exit 1
fi

rd_manifest="$ROOT_FOLDER/net.retrodeck.retrodeck.yml"
cache_file="$ROOT_FOLDER/placeholders.cache"

# Check if cache file exists
if [ -f "$cache_file" ]; then
  echo "Warning: Cache file $cache_file is being used. If you encounter issues with hashes, consider deleting this file."
fi

# Retrieve current git branch
get_current_branch() {
  local branch=$(git rev-parse --abbrev-ref HEAD)
  if [ "$branch" == "HEAD" ]; then
    echo "$GITHUB_REF" | sed 's@refs/heads/@@'
  else
    echo "$branch"
  fi
}

# Retrieve the repository URL
get_repo_url() {
  local repo_url=$(git config --get remote.origin.url)
  # Convert SSH URL to HTTPS if needed
  if [[ "$repo_url" == git@* ]]; then
    repo_url=$(echo "$repo_url" | sed -e 's|git@|https://|' -e 's|:|/|')
  fi
  echo "$repo_url"
}

current_branch=$(get_current_branch)
current_repo_url=$(get_repo_url)

echo "Manifest location: $rd_manifest"
echo

# Function to get hash from cache or calculate it
get_hash() {
  local url="$1"
  local hash

  # Check if cache should be used and if cache file exists
  # the use_cache variable is initialized by retrodeck_builder only so in the pipeline it will never use cache
  if [ "$use_cache" == "true" ] && [ -f "$cache_file" ]; then
    # Try to retrieve hash from cache
    hash=$(grep "^$url " "$cache_file" | cut -d ' ' -f2)
  fi

  # If hash is not found in cache, calculate it
  if [ -z "$hash" ]; then
    hash=$(curl -sL "$url" | sha256sum | cut -d ' ' -f1)
    # Save the calculated hash to cache if caching is enabled
    if [ "$use_cache" == "true" ]; then
      echo "$url $hash" >> "$cache_file"
    fi
  fi

  # Return the hash
  echo "$hash"
}

# Functions to handle different actions
handle_branch() {
  local placeholder="$1"
  echo "Replacing placeholder $placeholder with branch $current_branch"
  /bin/sed -i 's^'"$placeholder"'^'"$current_branch"'^g' "$rd_manifest"
}

handle_hash() {
  local placeholder="$1"
  local url="$2"
  local calculated_url=$(eval echo "$url")
  local hash=$(get_hash "$calculated_url")
  echo "Replacing placeholder $placeholder with hash $hash"
  /bin/sed -i 's^'"$placeholder"'^'"$hash"'^g' "$rd_manifest"
}

handle_latestcommit() {
  local placeholder="$1"
  local url="$2"
  local branch="$3"
  local commit=$(git ls-remote "$url" "$branch" | cut -f1)
  echo "Replacing placeholder $placeholder with latest commit $commit"
  /bin/sed -i 's^'"$placeholder"'^'"$commit"'^g' "$rd_manifest"
}

handle_latestghtag() {
  local placeholder="$1"
  local url="$2"
  local tag=$(git ls-remote --tags "$url" | tail -n 1 | cut -f2 | sed 's|refs/tags/||')
  echo "Replacing placeholder $placeholder with latest tag $tag"
  /bin/sed -i 's^'"$placeholder"'^'"$tag"'^g' "$rd_manifest"
}

handle_latestghrelease() {
  local placeholder="$1"
  local url="$2"
  local suffix="$3"
  echo "Fetching release data from: $url"
  local release_data=$(curl -s "$url")
  echo "Release data fetched."
  local ghreleaseurl=$(echo "$release_data" | jq -r ".assets[] | select(.name | endswith(\"$suffix\")).browser_download_url")
  
  if [[ -z "$ghreleaseurl" ]]; then
    echo "Error: No asset found with suffix $suffix"
    exit 1
  fi
  
  local ghreleasehash=$(get_hash "$ghreleaseurl")
  
  echo "Replacing placeholder $placeholder with URL $ghreleaseurl and hash $ghreleasehash"
  /bin/sed -i 's^'"$placeholder"'^'"$ghreleaseurl"'^g' "$rd_manifest"
  /bin/sed -i 's^'"HASHFOR$placeholder"'^'"$ghreleasehash"'^g' "$rd_manifest"
}

handle_latestghreleasesha() {
  local placeholder="$1"
  local url="$2"
  local suffix="$3"
  echo "Fetching release data from: $url"
  local release_data=$(curl -s "$url")
  echo "Release data fetched."
  local ghreleaseurl=$(echo "$release_data" | jq -r ".assets[] | select(.name | endswith(\"$suffix\")).browser_download_url")
  
  if [[ -z "$ghreleaseurl" ]]; then
    echo "Error: No asset found with suffix $suffix"
    exit 1
  fi
  
  local ghreleasehash=$(get_hash "$ghreleaseurl")
  
  echo "Replacing placeholder $placeholder with hash $ghreleasehash"
  /bin/sed -i 's^'"$placeholder"'^'"$ghreleasehash"'^g' "$rd_manifest"
}

handle_outside_file() {
  local placeholder="$1"
  local file_path="$2"
  if [[ "$file_path" == \$* ]]; then
    eval file_path="$file_path"
  fi
  local content=$(cat "$file_path")
  echo "Replacing placeholder $placeholder with content of file $file_path"
  /bin/sed -i 's^'"$placeholder"'^'"$content"'^g' "$rd_manifest"
}

handle_outside_env_var() {
  local placeholder="$1"
  local var_name="$2"
  if [[ "$var_name" == \$* ]]; then
    eval var_name="$var_name"
  fi
  local value=$(echo "$var_name")
  echo "Replacing placeholder $placeholder with environment variable $value"
  /bin/sed -i 's^'"$placeholder"'^'"$value"'^g' "$rd_manifest"
}

handle_custom_command() {
  local command="$1"
  echo "Executing custom command: $command"
  eval "$command"
}

handle_url() {
  local placeholder="$1"
  local url="$2"
  local calculated_url=$(eval echo "$url")
  echo "Replacing placeholder $placeholder with calculated URL $calculated_url"
  /bin/sed -i 's^'"$placeholder"'^'"$calculated_url"'^g' "$rd_manifest"
}

# Handle the THISREPO placeholder
handle_thisrepo() {
  local placeholder="$1"
  echo "Replacing placeholder $placeholder with repository URL $current_repo_url"
  /bin/sed -i 's^'"$placeholder"'^'"$current_repo_url"'^g' "$rd_manifest"
}

