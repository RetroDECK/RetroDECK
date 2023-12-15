#!/bin/bash

# This is building the bundle RetroDECK.flatpak after the download and build steps are done

if [ "${GITHUB_REF##*/}" = "main" ]; then
    flatpak build-bundle ${GITHUB_WORKSPACE}/.local RetroDECK.flatpak net.retrodeck.retrodeck
else
    flatpak build-bundle ${GITHUB_WORKSPACE}/.local RetroDECK-cooker.flatpak net.retrodeck.retrodeck
fi