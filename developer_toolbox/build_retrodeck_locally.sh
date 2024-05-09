#!/bin/bash

# WARNING: run this script from the project root folder, not from here!!

git submodule update --init --recursive

export GITHUB_WORKSPACE="."
cp net.retrodeck.retrodeck.appdata.xml net.retrodeck.retrodeck.appdata.xml.bak
cp net.retrodeck.retrodeck.yml net.retrodeck.retrodeck.yml.bak

automation_tools/install_dependencies.sh
automation_tools/cooker_build_id.sh
automation_tools/pre_build_automation.sh
automation_tools/cooker_flatpak_portal_add.sh
automation_tools/appdata_management.sh
automation_tools/flatpak_build_download_only.sh
automation_tools/flatpak_build_only.sh
automation_tools/flatpak_build_bundle.sh

rm -f net.retrodeck.retrodeck.appdata.xml 
rm -f net.retrodeck.retrodeck.yml
cp net.retrodeck.retrodeck.appdata.xml.bak net.retrodeck.retrodeck.appdata.xml
cp net.retrodeck.retrodeck.yml.bak net.retrodeck.retrodeck.yml
