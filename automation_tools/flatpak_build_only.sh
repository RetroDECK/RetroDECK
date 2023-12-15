#!/bin/bash

# This script is downloading the needed files to prepare the manifest build

git config --global protocol.file.allow always

if [ "${GITHUB_REF##*/}" = "main" ]; then
    BUNDLE_NAME="RetroDECK.flatpak"
    FOLDER=retrodeck-flatpak-main
else
    BUNDLE_NAME="RetroDECK-cooker.flatpak"
    FOLDER=retrodeck-flatpak-cooker
fi

mkdir -vp ${GITHUB_WORKSPACE}/.local
mkdir -vp ${GITHUB_WORKSPACE}/"$FOLDER"

flatpak-builder --user --force-clean \
    --install-deps-from=flathub \
    --install-deps-from=flathub-beta \
    --repo=${GITHUB_WORKSPACE}/.local \
    --disable-download \
    ${GITHUB_WORKSPACE}/"$FOLDER" \
    net.retrodeck.retrodeck.yml
