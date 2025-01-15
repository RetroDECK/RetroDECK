#!/bin/bash

# This script is downloading the needed files to prepare the manifest build

git config protocol.file.allow always

if [ "${GITHUB_REF##*/}" = "main" ]; then
    BUNDLE_NAME="RetroDECK.flatpak"
    FOLDER=retrodeck-flatpak-main
else
    BUNDLE_NAME="RetroDECK-cooker.flatpak"
    FOLDER=retrodeck-flatpak-cooker
fi

mkdir -vp ${GITHUB_WORKSPACE}/retrodeck-repo
mkdir -vp ${GITHUB_WORKSPACE}/"$FOLDER"

# Pass the args to Flatpak Builder
FLATPAK_BUILD_EXTRA_ARGS="${@}"
echo "Passing additional args to flatpak builder: $FLATPAK_BUILD_EXTRA_ARGS"

command="flatpak-builder --user --force-clean $FLATPAK_BUILD_EXTRA_ARGS \
    --install-deps-from=flathub \
    --install-deps-from=flathub-beta \
    --repo=${GITHUB_WORKSPACE}/retrodeck-repo \
    --disable-download $FLATPAK_BUILDER_CCACHE\
    \"${GITHUB_WORKSPACE}/$FOLDER\" \
    net.retrodeck.retrodeck.yml"

# Echo the command for verification
echo -e "Executing command:\n$command"

# Execute the command
eval $command