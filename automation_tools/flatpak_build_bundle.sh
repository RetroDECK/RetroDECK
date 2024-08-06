#!/bin/bash

# This is building the bundle RetroDECK.flatpak after the download and build steps are done

if [ "${GITHUB_REF##*/}" = "main" ]; then
    flatpak build-bundle "${GITHUB_WORKSPACE}/retrodeck-repo" "$GITHUB_WORKSPACE/RetroDECK.flatpak" net.retrodeck.retrodeck
    sha256sum RetroDECK.flatpak > RetroDECK.flatpak.sha
else
    flatpak build-bundle "${GITHUB_WORKSPACE}/retrodeck-repo" "$GITHUB_WORKSPACE/RetroDECK-cooker.flatpak" net.retrodeck.retrodeck
    sha256sum RetroDECK-cooker.flatpak > RetroDECK-cooker.flatpak.sha
fi