#!/bin/bash

# EDITABLES:
#rd_branch=${GITHUB_REF_NAME} # should be main

gits_folder="/tmp/${GITHUB_WORKSPACE}/gits" # without last /

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
cd "$gits_folder" || exit 1
git clone --depth=1 --recursive "https://github.com/$retrodeck_repo.git" RetroDECK
cd "$gits_folder/RetroDECK" || exit 1

relname=$(curl -s https://api.github.com/repos/$retrodeck_repo/releases | jq -r '[.[] | select(.prerelease == true)][0].tag_name // empty')
if [ -z "$relname" ]; then
    relname=$(curl -s https://api.github.com/repos/$retrodeck_repo/releases/latest | jq -r .tag_name)
fi
echo "Using release: $relname"

git checkout "$rd_branch"
cd "$gits_folder/flathub" || exit 1

git checkout -b "$relname"

git rm -rf *
git clean -fxd # restroing git index

# Copying only a few files as the others are cloned by git in retrodeck.sh
cd "$gits_folder/RetroDECK" || exit 1
cp -rf \
'LICENSE' \
'README.md' \
'other_licenses.txt' \ 
"$gits_folder/flathub/"

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
    git config user.name "${{ secrets.GITNAME }}"
    git config user.email "${{ secrets.GITMAIL }}"
elif [[ -z $(git config --get user.name) || -z $(git config --get user.email) ]]; then
    read -p "No git user.name set, please enter your name: " git_username
    git config --global user.name "$git_username"
    read -p "No git user.email set, please enter your email: " git_email
    git config --global user.email "$git_email"
fi

if [ -n "${GITHUB_WORKFLOW}" ]; then
    secret="${{ secrets.TRIGGER_BUILD_TOKEN }}@"
fi

git add *
git commit -m "Updated flathub/net.retrodeck.retrodeck to v$relname from RetroDECK/$rd_branch"
git push --force https://"$secret"github.com/"$flathub_target_repo.git" "$relname"