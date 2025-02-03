#!/bin/bash

# EDITABLES:
#rd_branch=${GITHUB_REF_NAME} # should be main

if [ -z "${GITHUB_WORKSPACE}" ]; then
    GITHUB_WORKSPACE="."
fi

gits_folder="${GITHUB_WORKSPACE}/tmp/gits" # without last /

rd_branch="main"
flathub_target_repo='flathub/net.retrodeck.retrodeck'
retrodeck_repo='RetroDECK/RetroDECK'
artifacts_sha_link="https://artifacts.retrodeck.net/artifacts/RetroDECK-Artifact.sha"
artifacts_link="https://artifacts.retrodeck.net/artifacts/RetroDECK-Artifact.tar.gz"

mkdir -vp "$gits_folder"
cd "$gits_folder" || exit 1
if [ -d flathub ]; then
    rm -rf flathub
fi
git clone --depth=1 --recursive "https://github.com/$flathub_target_repo.git" flathub
git clone --depth=1 --recursive "https://github.com/$retrodeck_repo.git" RetroDECK

relname=$(curl -s https://api.github.com/repos/$retrodeck_repo/releases | jq -r '[.[] | select(.prerelease == true)][0].tag_name // empty')
if [ -z "$relname" ]; then
    relname=$(curl -s https://api.github.com/repos/$retrodeck_repo/releases/latest | jq -r .tag_name)
fi
echo "Using release: $relname"

cd "$gits_folder/RetroDECK" && git checkout "$rd_branch"

cd "$gits_folder/flathub" || exit 1
git checkout -b "$relname"
git rm -rf *
git clean -fxd # restroing git index

# Copying only a few files as the others are cloned by git in retrodeck.sh
files_to_copy=('LICENSE' 'README.md' 'other_licenses.txt')
for file in "${files_to_copy[@]}"; do
    if [ -f "$file" ]; then
        cp -fv "$gits_folder/RetroDECK/$file" "$gits_folder/flathub"
    else
        echo "Warning: $file not found in $gits_folder/RetroDECK"
    fi
done

cd "$gits_folder/flathub" || exit 1
ls -lah

# Creating the manifest for flathub
manifest='net.retrodeck.retrodeck.yml'
sed -n '/cleanup/q;p' $gits_folder/RetroDECK/net.retrodeck.retrodeck.yml > $manifest
sed -i '/^[[:space:]]*#/d' $manifest
sed -i 's/[[:space:]]*#.*$//' $manifest
cat << EOF >> $manifest
modules:
- name: retrodeck
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

if [ -n "${GITHUB_WORKFLOW}" ]; then
    git config --local user.name "$GIT_NAME"
    git config --local user.email "$GIT_MAIL"
elif [[ -z $(git config --get user.name) || -z $(git config --get user.email) ]]; then
    read -p "No git user.name set, please enter your name: " git_username
    git config --local user.name "$git_username"
    read -p "No git user.email set, please enter your email: " git_email
    git config --local user.email "$git_email"
fi

if [ -n "${GITHUB_WORKFLOW}" ]; then
    echo "RD_BRANCH=$rd_branch" >> $GITHUB_ENV
    echo "RELNAME=$relname" >> $GITHUB_ENV
    echo "FOLDER_TO_PUSH="$gits_folder/flathub"" >> $GITHUB_ENV
    echo "TARGET_REPO=https://github.com/${flathub_target_repo}" >> $GITHUB_ENV
fi

git add .
git commit -m "Updated flathub/net.retrodeck.retrodeck to v$relname from RetroDECK/$rd_branch"

if [ -n "${GITHUB_WORKFLOW}" ]; then
    git push --force "https://github.com/${flathub_target_repo}.git" "$relname"
fi
