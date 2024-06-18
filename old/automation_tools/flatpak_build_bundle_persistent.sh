#!/bin/bash

# This is building the bundle RetroDECK.flatpak after the download and build steps are done

BUILD_DIR="$HOME/cooker-persistent"
mkdir -p "$BUILD_DIR"

if [ "${GITHUB_REF##*/}" = "main" ]; then
    flatpak build-bundle "${BUILD_DIR}/.local" "$GITHUB_WORKSPACE/RetroDECK.flatpak" net.retrodeck.retrodeck
else
    flatpak build-bundle "${BUILD_DIR}/.local" "$GITHUB_WORKSPACE/RetroDECK-cooker.flatpak" net.retrodeck.retrodeck
fi
