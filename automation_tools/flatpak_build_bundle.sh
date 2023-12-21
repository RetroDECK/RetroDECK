#!/bin/bash

# This is building the bundle RetroDECK.flatpak after the download and build steps are done

if [ $PERSISTENCE==true ]; then
    GITHUB_WORKSPACE_BACKUP="$GITHUB_WORKSPACE"
    GITHUB_WORKSPACE="$HOME/cooker-persistent"
fi

if [ "${GITHUB_REF##*/}" = "main" ]; then
    flatpak build-bundle ${GITHUB_WORKSPACE}/.local $GITHUB_WORKSPACE/RetroDECK.flatpak net.retrodeck.retrodeck
else
    flatpak build-bundle ${GITHUB_WORKSPACE}/.local $GITHUB_WORKSPACE/RetroDECK-cooker.flatpak net.retrodeck.retrodeck
fi

if [ $PERSISTENCE==true ]; then
    GITHUB_WORKSPACE="$GITHUB_WORKSPACE_BACKUP"
fi