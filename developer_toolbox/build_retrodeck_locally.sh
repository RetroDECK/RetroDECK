#!/bin/bash

# WARNING: run this script from the project root folder, not from here!!

# Check if ccache is installed
if ! command -v ccache &> /dev/null; then
    echo "Compiler cache (ccache) is not installed. Install it to be able to use the cache and speed up your builds"
else
    read -rp "Do you want to use ccache? If you're unsure just say no [Y/n] " use_ccache_input
    use_ccache_input=${use_ccache_input:-Y}
    if [[ "$use_ccache_input" =~ ^[Yy]$ ]]; then
        # Use ccache
        export CC="ccache gcc"
        export CXX="ccache g++"
        export FLATPAK_BUILDER_CCACHE="--ccache"
    else
        echo "Proceeding without ccache"
    fi
fi

read -rp "Do you want to use the hashes cache? If you're unsure just say no [Y/n] " use_cache_input
use_cache_input=${use_cache_input:-Y}
if [[ "$use_cache_input" =~ ^[Yy]$ ]]; then
    export use_cache="true"
else
    export use_cache="false"
    rm -f "placeholders.cache"
fi

echo "Do you want to clear the build cache?"
read -rp "Keeping the build cache can speed up the build process, but it might cause issues and should be cleared occasionally [y/N] " clear_cache_input
clear_cache_input=${clear_cache_input:-N}
if [[ "$clear_cache_input" =~ ^[Yy]$ ]]; then
    # User chose to clear the build cache
    echo "Clearing build cache..."
    rm -rf "retrodeck-repo" "retrodeck-flatpak-cooker" ".flatpak-builder"

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