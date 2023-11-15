#!/bin/bash

# This script is downloading the needed files to prepare the manifest build

git config --global protocol.file.allow always

if [[ "${GITHUB_REF##*/}" == "main" ]]; then
    BUNDLE_NAME="RetroDECK.flatpak"
    FOLDER=retrodeck-flatpak-cooker
else
    BUNDLE_NAME="RetroDECK-cooker.flatpak"
    FOLDER=retrodeck-flatpak-cooker
fi

mkdir -vp "${GITHUB_WORKSPACE}"/{local,retrodeck-flatpak-cooker}

flatpak-builder --user --force-clean \
    --install-deps-from=flathub \
    --install-deps-from=flathub-beta \
    --repo="${GITHUB_WORKSPACE}/local" \
    --download-only \
    "${GITHUB_WORKSPACE}/${FOLDER}" \
    net.retrodeck.retrodeck.yml
