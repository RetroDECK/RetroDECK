#!/bin/bash

# WARNING: run this script from the project root folder, not from here!!

# Check if script is running with elevated privileges
# if [ "$EUID" -ne 0 ]; then
#     read -rp "The build might fail without some superuser permissions, please run me with sudo. Continue WITHOUT sudo (not suggested)? [y/N] " continue_without_sudo
#     if [[ "$continue_without_sudo" != "y" ]]; then
#         exit 1
#     fi
# fi

read -rp "Do you want to use the hashes cache? If you're unsure just say no [Y/n]" use_cache_input
use_cache_input=${use_cache_input:-Y}
if [[ "$use_cache_input" =~ ^[Yy]$ ]]; then
    export use_cache="true"
else
    export use_cache="false"
fi

git submodule update --init --recursive

export GITHUB_WORKSPACE="."

# Initialize the Flatpak repo
ostree init --mode=archive-z2 --repo=${GITHUB_WORKSPACE}/retrodeck-repo

# Backing up original manifest
cp net.retrodeck.retrodeck.appdata.xml net.retrodeck.retrodeck.appdata.xml.bak
cp net.retrodeck.retrodeck.yml net.retrodeck.retrodeck.yml.bak

automation_tools/install_dependencies.sh
automation_tools/cooker_build_id.sh
automation_tools/manifest_placeholder_replacer.sh
automation_tools/cooker_flatpak_portal_add.sh
# THIS SCRIPT IS BROKEN HENCE DISABLED FTM
# automation_tools/appdata_management.sh
automation_tools/flatpak_build_download_only.sh
automation_tools/flatpak_build_only.sh "${@}"
automation_tools/flatpak_build_bundle.sh

mv -f net.retrodeck.retrodeck.appdata.xml.bak net.retrodeck.retrodeck.appdata.xml
mv -f net.retrodeck.retrodeck.yml.bak net.retrodeck.retrodeck.yml
