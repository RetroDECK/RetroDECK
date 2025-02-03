#!/bin/bash

# EDITABLES:
#rd_branch=${GITHUB_REF_NAME} # should be main

if [ -z "${GITHUB_WORKSPACE}" ]; then
    gits_folder="${GITHUB_WORKSPACE}/tmp/gits" # without last /
else
    gits_folder="/tmp/gits" # without last /
fi


rd_branch="main"
flathub_target_repo='flathub/net.retrodeck.retrodeck'
retrodeck_repo='RetroDECK/RetroDECK'
artifacts_sha_link="https://artifacts.retrodeck.net/artifacts/RetroDECK-Artifact.sha"
artifacts_link="https://artifacts.retrodeck.net/artifacts/RetroDECK-Artifact.tar.gz"

if -d "$gits_folder"; then
    rm -rf "$gits_folder"
fi
mkdir -vp "$gits_folder"
cd "$gits_folder" && echo "Moving in $gits_folder" || exit 1
if [ -d flathub ]; then
    rm -rf "$gits_folder/flathub"
fi
if [ -d flathub ]; then
    rm -rf "$gits_folder/RetroDECK"
fi
git clone --depth=1 --recursive "https://github.com/$flathub_target_repo.git" "$gits_folder/flathub"
git clone --depth=1 --recursive "https://github.com/$retrodeck_repo.git" "$gits_folder/RetroDECK"

relname=$(curl -s https://api.github.com/repos/$retrodeck_repo/releases | jq -r '[.[] | select(.prerelease == true)][0].tag_name // empty')
if [ -z "$relname" ]; then
    relname=$(curl -s https://api.github.com/repos/$retrodeck_repo/releases/latest | jq -r .tag_name)
fi
echo "Using release: $relname"

cd "$gits_folder/RetroDECK" && echo "Moving in $gits_folder/RetroDECK" && git checkout "$rd_branch"

cd "$gits_folder"/flathub && echo "Moving in $gits_folder/flathub" || exit 1
git checkout -b "$relname"
echo "Current directory: $(pwd)"
ls -lah
git rm -rf *
git clean -fxd # restroing git index

# Copying only a few files as the others are cloned by git in retrodeck.sh
files_to_copy=('LICENSE' 'README.md' 'other_licenses.txt' 'net.retrodeck.retrodeck.yml' 'net.retrodeck.retrodeck.metainfo.xml')
for file in "${files_to_copy[@]}"; do
    if ! cp -fv "$gits_folder/RetroDECK/$file" "$gits_folder/flathub"; then
        echo "Warning: $file not found in $gits_folder/RetroDECK"
    fi
done

cd "$gits_folder/flathub" && echo "Moving in $gits_folder/flathub" || exit 1
ls -lah

# Creating the manifest for flathub
manifest='net.retrodeck.retrodeck.yml'
sed -n '/cleanup/q;p' $gits_folder/RetroDECK/net.retrodeck.retrodeck.yml > $manifest
sed -i '/^[[:space:]]*#/d' $manifest
sed -i 's/[[:space:]]*#.*$//' $manifest
cat << EOF >> $manifest
    modules:

        - name: RetroDECK
          buildsystem: simple
          build-commands:
            - cp -rn files/* /app
          sources:
            - type: archive
            url: $artifacts_link
            sha256: $(curl -sL "$artifacts_sha_link")
EOF

cat << EOF >> flathub.json
{
"only-arches": ["x86_64"]
}
EOF

# If we are in a GitHub workflow...
if [ -n "${GITHUB_WORKFLOW}" ]; then
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_MAIL"
    git config --global credential.helper store
    gh auth login
elif [[ -z $(git config --get user.name) || -z $(git config --get user.email) ]]; then
    read -p "No git user.name set, please enter your name: " git_username
    git config --local user.name "$git_username"
    read -p "No git user.email set, please enter your email: " git_email
    git config --local user.email "$git_email"
fi

git add .
git commit -m "Update RetroDECK to v$relname from RetroDECK/$rd_branch"


if [ -n "${GITHUB_WORKFLOW}" ]; then
    git push --force "${GIT_NAME}@github.com/${flathub_target_repo}.git" "$relname"
else
    git push --force "https://github.com/${flathub_target_repo}" "$relname"
fi

