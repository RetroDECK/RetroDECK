#!/bin/bash

# This script is downloading the needed files to prepare the manifest build

git config protocol.file.allow always

if [ "${GITHUB_REF##*/}" = "main" ]; then
    BUNDLE_NAME="RetroDECK.flatpak"
    FOLDER=retrodeck-flatpak-main
else
    BUNDLE_NAME="RetroDECK-cooker.flatpak"
    FOLDER=retrodeck-flatpak-cooker
fi

BUILD_DIR="$HOME/cooker-persistent"
mkdir -vp ${$BUILD_DIR}/.local
mkdir -vp ${$BUILD_DIR}/"$FOLDER"

flatpak-builder --user --force-clean \
--install-deps-from=flathub \
--install-deps-from=flathub-beta \
--repo="${BUILD_DIR}/.local" \
--disable-download \
"${BUILD_DIR}/${FOLDER}" \
"${GITHUB_WORKSPACE}/net.retrodeck.retrodeck.yml"
