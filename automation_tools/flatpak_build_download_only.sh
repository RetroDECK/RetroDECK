#!/bin/bash

# This script is downloading the needed files to prepare the manifest build

git config --global protocol.file.allow always
mkdir -vp ${GITHUB_WORKSPACE}/local
mkdir -vp ${GITHUB_WORKSPACE}/retrodeck-flatpak-cooker
flatpak-builder --user --force-clean \
    --install-deps-from=flathub \
    --install-deps-from=flathub-beta \
    --repo=${GITHUB_WORKSPACE}/local \
    --download-only \
    ${GITHUB_WORKSPACE}/retrodeck-flatpak-cooker \
    net.retrodeck.retrodeck.yml