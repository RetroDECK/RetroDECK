#!/bin/bash

# Check if GITHUB_WORKSPACE is set, if not, set gits_folder to /tmp/gits
if [ -z "${GITHUB_WORKSPACE}" ]; then
    gits_folder="${GITHUB_WORKSPACE}/tmp/gits" # without last /
else
    gits_folder="/tmp/gits" # without last /
fi

rd_branch="main"
flathub_target_repo='flathub/net.retrodeck.retrodeck'
retrodeck_repo='RetroDECK/RetroDECK'

# Get the latest artifact SHA and download URL from the RetroDECK Artifacts repository
artifacts_sha_link=$(curl -s https://api.github.com/repos/RetroDECK/Artifacts/releases/latest | jq -r '.assets[] | select(.name == "RetroDECK-Artifact.sha").browser_download_url')
artifacts_link=$(curl -s https://api.github.com/repos/RetroDECK/Artifacts/releases/latest | jq -r '.assets[] | select(.name == "RetroDECK-Artifact.tar.gz").browser_download_url')

# Remove existing gits_folder if it exists and create a new one
if [ -d "$gits_folder" ] ; then
    rm -rf "$gits_folder"
fi
mkdir -vp "$gits_folder"
cd "$gits_folder" && echo "Moving in $gits_folder" || exit 1

# Remove existing flathub and RetroDECK directories if they exist
if [ -d flathub ]; then
    rm -rf "$gits_folder/flathub"
fi
if [ -d flathub ]; then
    rm -rf "$gits_folder/RetroDECK"
fi

# Clone the flathub and RetroDECK repositories
git clone --depth=1 --recursive "https://github.com/$flathub_target_repo.git" "$gits_folder/flathub"
git clone --depth=1 --recursive "https://github.com/$retrodeck_repo.git" "$gits_folder/RetroDECK"

# Get the latest release name, preferring prereleases if available and published after 2025-01-01
relname=$(curl -s "https://api.github.com/repos/$retrodeck_repo/releases" | jq -r '[.[] | select(.prerelease == true and (.published_at | fromdateiso8601) > 1735689600)][0].tag_name // empty')
if [ -z "$relname" ]; then
    relname=$(curl -s https://api.github.com/repos/$retrodeck_repo/releases/latest | jq -r .tag_name)
fi
echo "Using release: $relname"

# Checkout the main branch in the RetroDECK repository
cd "$gits_folder/RetroDECK" && echo "Moving in $gits_folder/RetroDECK" && git checkout "$rd_branch"

# Create a new branch in the flathub repository with the release name
cd "$gits_folder"/flathub && echo "Moving in $gits_folder/flathub" || exit 1
git checkout -b "$relname"
echo "Current directory: $(pwd)"
ls -lah

# Remove all files in the flathub repository and clean the git index
git rm -rf *
git clean -fxd # restoring git index

# Copy specific files from the RetroDECK repository to the flathub repository
files_to_copy=('LICENSE' 'README.md' 'other_licenses.txt' 'net.retrodeck.retrodeck.yml' 'net.retrodeck.retrodeck.metainfo.xml')
for file in "${files_to_copy[@]}"; do
    if ! cp -fv "$gits_folder/RetroDECK/$file" "$gits_folder/flathub"; then
        echo "Warning: $file not found in $gits_folder/RetroDECK"
    fi
done

cd "$gits_folder/flathub" && echo "Moving in $gits_folder/flathub" || exit 1
ls -lah

# Create the manifest for flathub
manifest='net.retrodeck.retrodeck.yml'
sed -n '/cleanup:/q;p' "$gits_folder/RetroDECK/net.retrodeck.retrodeck.yml" > "$manifest"
sed -i '/^[[:space:]]*#/d' "$manifest"
sed -i 's/[[:space:]]*#.*$//' "$manifest"

# Fetch the asset list from the latest release
release_json=$(curl -s https://api.github.com/repos/RetroDECK/Artifacts/releases/latest)
artifacts_sha_link=$(echo "$release_json" | jq -r '.assets[] | select(.name == "RetroDECK-Artifact.sha").browser_download_url')

# Check if there are .7z split parts
mapfile -t part_urls < <(echo "$release_json" | jq -r '.assets[] | select(.name | test("\\.7z\\.\\d{3}$")) | .browser_download_url')
mapfile -t part_names < <(echo "$release_json" | jq -r '.assets[] | select(.name | test("\\.7z\\.\\d{3}$")) | .name')

cat << EOF >> "$manifest"
modules:

    - name: p7zip
      no-autogen: true
      sources:
        - type: archive
          url: https://github.com/p7zip-project/p7zip/archive/v17.04/p7zip-v17.04.tar.gz
          sha256: ea029a2e21d2d6ad0a156f6679bd66836204aa78148a4c5e498fe682e77127ef
        - type: shell
          commands:
            - sed -i 's|/usr/local|${FLATPAK_DEST}|g' makefile.common
      cleanup:
        - /man

    - name: RetroDECK
      buildsystem: simple
      build-commands:
EOF

if [[ ${#part_urls[@]} -gt 0 ]]; then
  echo "Found 7z split parts! Adding them as sources in manifest..."
  cat << EOF >> "$manifest"
       - 7z x RetroDECK-Artifact.7z.001 -o. || (echo "Failed to extract 7z split archive" && exit 1)
       - cp -rn files/* /app || echo "Some files have been skipped"
      sources:
EOF
  for i in "${!part_urls[@]}"; do
    sha256=$(curl -sL "${artifacts_sha_link}" | grep "${part_names[$i]}" | cut -d' ' -f1)
    cat << EOF >> "$manifest"
        - type: file
          url: ${part_urls[$i]}
          sha256: $sha256
          dest: RetroDECK-Artifact.${part_names[$i]##*.}
EOF
  done
else
  echo "No 7z split parts found, using .tar.gz as source in manifest..."
  artifact_url=$(echo "$release_json" | jq -r '.assets[] | select(.name == "RetroDECK-Artifact.tar.gz").browser_download_url')
  artifact_sha=$(curl -sL "$artifacts_sha_link")
  cat << EOF >> "$manifest"
       - tar -xf RetroDECK-Artifact.tar.gz -C . || (echo "Failed to extract tar.gz" && exit 1)
       - cp -rn files/* /app || echo "Some files have been skipped"
      sources:
        - type: archive
          url: $artifact_url
          sha256: $artifact_sha
EOF
fi

# Create a flathub.json file specifying the architecture
cat << EOF >> flathub.json
{
"only-arches": ["x86_64"]
}
EOF

# If running in a GitHub workflow, configure git and authenticate with GitHub
if [ -n "${GITHUB_WORKFLOW}" ]; then
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_MAIL"
    git config --global credential.helper store
    gh auth login
# If not in a GitHub workflow, prompt the user for git configuration if not already set
elif [[ -z $(git config --get user.name) || -z $(git config --get user.email) ]]; then
    read -p "No git user.name set, please enter your name: " git_username
    git config --local user.name "$git_username"
    read -p "No git user.email set, please enter your email: " git_email
    git config --local user.email "$git_email"
fi

# Commit the changes and push to the new branch
git add .
git commit -m "Update RetroDECK to v$relname from RetroDECK/$rd_branch"

# Push the changes to the remote repository, using authentication if in a GitHub workflow
if [ -n "${GITHUB_WORKFLOW}" ]; then
    git remote set-url origin https://x-access-token:${GH_TOKEN}@github.com/${flathub_target_repo}
    git push --force origin "$relname"
else
    git push --force "https://github.com/${flathub_target_repo}" "$relname"
fi

