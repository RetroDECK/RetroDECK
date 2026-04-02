#!/bin/bash

# Static variables

export rd_core_files="/app/retrodeck/config/retrodeck"                                                          # Folder with RetroDECK reference and helper files
export rd_defaults="$rd_core_files/retrodeck.json"                                                              # A default RetroDECK config file
export input_validation="$rd_core_files/reference_lists/input_validation.cfg"                                   # A config file listing valid CLI inputs
export sdcard_default_path="/run/media/mmcblk0p1"                                                               # Steam Deck SD default path
export hard_version="$(cat '/app/retrodeck/version')"                                                           # hardcoded version (in the readonly filesystem)
export rd_metainfo="/app/share/metainfo/net.retrodeck.retrodeck.metainfo.xml"                                   # The shipped metainfo XML file for this version
export low_space_threshold=90
export purple="#a864fc"
export blue="#6fbfff"

# Network / Online-related variables

export remote_network_target_1="https://flathub.org"                                                            # The URL of a common internet target for testing network access
export remote_network_target_2="$rd_repo_url"                                                                   # The URL of a common internet target for testing network access
export remote_network_target_3="https://one.one.one.one"                                                        # The URL of a common internet target for testing network access
export ra_cheevos_api_url="https://retroachievements.org/dorequest.php"                                         # API URL for RetroAchievements.org
export git_organization_name="RetroDECK"                                                                        # The name of the organization in our git repository such as GitHub
export main_repository_name="RetroDECK"                                                                         # The name of the main repository under RetroDECK organization
export cooker_repository_name="Cooker"                                                                          # The name of the cooker repository under RetroDECK organization
export rd_repo_url="https://github.com/$git_organization_name/$main_repository_name"                            # The URL of the main RetroDECK GitHub repo
export rd_wiki_url="https://retrodeck.readthedocs.io"
export rd_gh_api_url="https://api.github.com/repos/$git_organization_name/$main_repository_name/releases/latest"

# Components-related variables

export rd_components="/app/retrodeck/components"
export rd_shared_libs="/app/retrodeck/components/shared-libs"
export rd_shared_libs_kde_path="/app/retrodeck/components/shared-libs/org.kde.Platform"
export rd_shared_libs_gnome_path="/app/retrodeck/components/shared-libs/org.gnome.Platform"
export rd_shared_libs_freedesktop_path="/app/retrodeck/components/shared-libs/org.freedesktop.Platform"
export DEFAULT_LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
