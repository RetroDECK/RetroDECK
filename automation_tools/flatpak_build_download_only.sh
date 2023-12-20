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

if [ $PERSISTENCE==true ]; then
    mkdir -p "$HOME/cooker-persistent"
    GITHUB_WORKSPACE_BACKUP="$GITHUB_WORKSPACE"
    GITHUB_WORKSPACE="$HOME/cooker-persistent"
fi

mkdir -vp "${GITHUB_WORKSPACE}"/{local,retrodeck-flatpak-cooker}

flatpak-builder --user --force-clean \
    --install-deps-from=flathub \
    --install-deps-from=flathub-beta \
    --repo="${GITHUB_WORKSPACE}/.local" \
    --download-only \
    "${GITHUB_WORKSPACE}/${FOLDER}" \
    net.retrodeck.retrodeck.yml

if [ $PERSISTENCE==true ]; then
    GITHUB_WORKSPACE="$GITHUB_WORKSPACE_BACKUP"
fi
