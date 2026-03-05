#!/bin/bash

# Static variables
export rd_conf="$XDG_CONFIG_HOME/retrodeck/retrodeck.json"                                                            # RetroDECK config file path
export rd_conf_backup="$XDG_CONFIG_HOME/retrodeck/retrodeck.bak"                                                     # Backup of RetroDECK config file from update
export rd_core_files="/app/retrodeck/config/retrodeck"                                                                           # Folder with RetroDECK reference and helper files
export rd_defaults="$rd_core_files/retrodeck.json"                                                            # A default RetroDECK config file
export rd_update_patch="$XDG_CONFIG_HOME/retrodeck/rd_update.patch"                                                  # A static location for the temporary patch file used during retrodeck.cfg updates
export input_validation="$rd_core_files/reference_lists/input_validation.cfg"                                # A config file listing valid CLI inputs
export splashscreen_dir="/app/retrodeck/graphics/extra_splashes"                                   # The default location of extra splash screens
export current_splash_file="$XDG_CONFIG_HOME/ES-DE/resources/graphics/splash.svg"                                    # The active splash file that will be shown on boot
export default_splash_file="/app/retrodeck/graphics/splash.svg"                               # The default RetroDECK splash screen
export rd_lockfile="$XDG_CONFIG_HOME/retrodeck/.lock"                                                                   # Where the lockfile is located
export sdcard_default_path="/run/media/mmcblk0p1"                                                                        # Steam Deck SD default path
export hard_version="$(cat '/app/retrodeck/version')"                                                           # hardcoded version (in the readonly filesystem)
export rd_repo="https://github.com/RetroDECK/RetroDECK"                                                         # The URL of the main RetroDECK GitHub repo
export es_themes_list="https://gitlab.com/es-de/themes/themes-list/-/raw/master/themes.json"                    # The URL of the ES-DE 2.0 themes list
export remote_network_target_1="https://flathub.org"                                                            # The URL of a common internet target for testing network access
export remote_network_target_2="$rd_repo"                                                                       # The URL of a common internet target for testing network access
export remote_network_target_3="https://one.one.one.one"                                                        # The URL of a common internet target for testing network access
export rd_metainfo="/app/share/metainfo/net.retrodeck.retrodeck.metainfo.xml"                                   # The shipped metainfo XML file for this version
export ra_cheevos_api_url="https://retroachievements.org/dorequest.php"                                                 # API URL for RetroAchievements.org
export git_organization_name="RetroDECK"                                                                        # The name of the organization in our git repository such as GitHub
export cooker_repository_name="Cooker"                                                                          # The name of the cooker repository under RetroDECK organization
export main_repository_name="RetroDECK"                                                                         # The name of the main repository under RetroDECK organization
export features="$rd_core_files/reference_lists/features.json"                                               # A file where all the RetroDECK and component capabilities are kept for querying
export folder_iconsets_dir="$XDG_CONFIG_HOME/retrodeck/graphics/folder-iconsets"

# API-related file locations

export rd_api_dir="$XDG_CONFIG_HOME/retrodeck/api"
export REQUEST_PIPE="$rd_api_dir/retrodeck_api_pipe"
export PID_FILE="$rd_api_dir/retrodeck_api_server.pid"
export rd_api_socket="$rd_api_dir/retrodeck_api_server.sock"

# File lock file for multi-threaded write operations to the same file

export rd_file_lock="$rd_api_dir/retrodeck_file_lock"

# Base dir for all installed RetroDECK components
export rd_components="/app/retrodeck/components"
export rd_shared_libs="/app/retrodeck/components/shared-libs"
export rd_shared_libs_kde_path="/app/retrodeck/components/shared-libs/org.kde.Platform"
export rd_shared_libs_gnome_path="/app/retrodeck/components/shared-libs/org.gnome.Platform"
export rd_shared_libs_freedesktop_path="/app/retrodeck/components/shared-libs/org.freedesktop.Platform" 
export runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/retrodeck"
export DEFAULT_LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
