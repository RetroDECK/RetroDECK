#!/bin/bash

export GITHUB_WORKSPACE="."

automation_tools/install_dependencies.sh
automation_tools/cooker_build_id.sh
automation_tools/pre_build_automation.sh
automation_tools/cooker_flatpak_portal_add.sh
automation_tools/appdata_management.sh
automation_tools/flatpak_build_download_only.sh
automation_tools/flatpak_build_only.sh
automation_tools/flatpak_build_bundle.sh

