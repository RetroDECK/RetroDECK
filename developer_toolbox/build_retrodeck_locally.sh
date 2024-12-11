#!/bin/bash

# WARNING: run this script from the project root folder, not from here!!

# Check if script is running with elevated privileges
if [ "$EUID" -ne 0 ]; then
    read -rp "The build might fail without some superuser permissions, please run me with sudo. Continue without sudo? [y/N] " continue_without_sudo
    if [[ "$continue_without_sudo" != "y" ]]; then
        exit 1
    fi
fi

git submodule update --init --recursive

export GITHUB_WORKSPACE="."

# Initialize the Flatpak repo
ostree init --mode=archive-z2 --repo=${GITHUB_WORKSPACE}/retrodeck-repo

# Backing up original manifest
cp net.retrodeck.retrodeck.appdata.xml net.retrodeck.retrodeck.appdata.xml.bak
cp net.retrodeck.retrodeck.yml net.retrodeck.retrodeck.yml.bak

if [[ -f "net.retrodeck.retrodeck.cached.yml" ]]; then
    read -rp "A cached manifest file with placeholder substitutions already exists. Do you want to use it? [y/N] " use_cached
    if [[ "${use_cached,,}" == "y" ]]; then
        cp net.retrodeck.retrodeck.cached.yml net.retrodeck.retrodeck.yml
    else
        use_cached="n"
    fi
else
    use_cached="n"
fi

export use_cached

automation_tools/install_dependencies.sh
automation_tools/cooker_build_id.sh
automation_tools/pre_build_automation.sh
automation_tools/cooker_flatpak_portal_add.sh
# THIS SCRIPT IS BROKEN HENCE DISABLED FTM
# automation_tools/appdata_management.sh
automation_tools/flatpak_build_download_only.sh
automation_tools/flatpak_build_only.sh "${@}"
automation_tools/flatpak_build_bundle.sh

rm -f net.retrodeck.retrodeck.appdata.xml 
rm -f net.retrodeck.retrodeck.yml
cp net.retrodeck.retrodeck.appdata.xml.bak net.retrodeck.retrodeck.appdata.xml
cp net.retrodeck.retrodeck.yml.bak net.retrodeck.retrodeck.yml
