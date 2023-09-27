#!/bin/bash

# This script is building the flatpak is the needed files are already downloaded

git config --global protocol.file.allow always
mkdir -vp ${GITHUB_WORKSPACE}/local
mkdir -vp ${GITHUB_WORKSPACE}/retrodeck-flatpak-cooker
flatpak-builder --user --force-clean \
    --install-deps-from=flathub \
    --install-deps-from=flathub-beta \
    --repo=${GITHUB_WORKSPACE}/local \
    --disable-download \
    ${GITHUB_WORKSPACE}/retrodeck-flatpak-cooker \
    net.retrodeck.retrodeck.yml