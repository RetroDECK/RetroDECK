#!/bin/bash

# This script is downloading the needed files to prepare the manifest build

git config --global protocol.file.allow always

# Getting token from env
TOKEN=$GITHUB_TOKEN

export GIT_CURL_VERBOSE=1
export GIT_ASKPASS=echo
export GIT_USERNAME=token
export GIT_PASSWORD=$TOKEN

sed -i "s|Authorization: token .*|Authorization: token ${TOKEN}|" "${GITHUB_WORKSPACE}/net.retrodeck.retrodeck.yml"

if [[ "${GITHUB_REF##*/}" == "main" ]]; then
    BUNDLE_NAME="RetroDECK.flatpak"
    FOLDER=retrodeck-flatpak
else
    BUNDLE_NAME="RetroDECK-cooker.flatpak"
    FOLDER=retrodeck-flatpak-cooker
fi

mkdir -vp "${GITHUB_WORKSPACE}"/{retrodeck-repo,retrodeck-flatpak-cooker}

flatpak-builder --user --force-clean \
    --install-deps-from=flathub \
    --install-deps-from=flathub-beta \
    --repo="${GITHUB_WORKSPACE}/retrodeck-repo" \
    --download-only \
    "${GITHUB_WORKSPACE}/${FOLDER}" \
    net.retrodeck.retrodeck.yml
    