#!/bin/bash

# This is building the bundle RetroDECK.flatpak after the download and build steps are done

if [[ "${GITHUB_REF##*/}" == "main" ]]; then
    flatpak = "RetroDECK.flatpak"
else
    flatpak = "RetroDECK-cooker.flatpak"
fi

flatpak build-bundle "${GITHUB_WORKSPACE}/local" "${flatpak}" net.retrodeck.retrodeck
