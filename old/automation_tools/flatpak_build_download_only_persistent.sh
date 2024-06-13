#!/bin/bash

# This script is downloading the needed files to prepare the manifest build

git config --global protocol.file.allow always

if [[ "${GITHUB_REF##*/}" == "main" ]]; then
    BUNDLE_NAME="RetroDECK.flatpak"
    FOLDER=retrodeck-flatpak
else
    BUNDLE_NAME="RetroDECK-cooker.flatpak"
    FOLDER=retrodeck-flatpak-cooker
fi

BUILD_DIR="$HOME/cooker-persistent"
mkdir -p "$BUILD_DIR"
mkdir -vp "${BUILD_DIR}"/{.local,retrodeck-flatpak-cooker}

flatpak-builder --user --force-clean \
--install-deps-from=flathub \
--install-deps-from=flathub-beta \
--repo="${BUILD_DIR}/.local" \
--download-only \
"${BUILD_DIR}/${FOLDER}" \
"${GITHUB_WORKSPACE}/net.retrodeck.retrodeck.yml"

