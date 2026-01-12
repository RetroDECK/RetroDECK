#!/bin/bash

# Static variables
rd_conf="$XDG_CONFIG_HOME/retrodeck/retrodeck.json"                                                            # RetroDECK config file path
rd_conf_backup="$XDG_CONFIG_HOME/retrodeck/retrodeck.bak"                                                     # Backup of RetroDECK config file from update
rd_core_files="/app/retrodeck/config/retrodeck"                                                                           # Folder with RetroDECK reference and helper files
rd_defaults="$rd_core_files/retrodeck.json"                                                            # A default RetroDECK config file
rd_update_patch="$XDG_CONFIG_HOME/retrodeck/rd_update.patch"                                                  # A static location for the temporary patch file used during retrodeck.cfg updates
bios_checklist="$rd_core_files/reference_lists/bios.json"                                    # A config file listing BIOS file information that can be verified
input_validation="$rd_core_files/reference_lists/input_validation.cfg"                                # A config file listing valid CLI inputs
finit_options_list="$rd_core_files/reference_lists/finit_options_list.cfg"                            # A config file listing available optional installs during finit
splashscreen_dir="/app/retrodeck/graphics/extra_splashes"                                   # The default location of extra splash screens
current_splash_file="$XDG_CONFIG_HOME/ES-DE/resources/graphics/splash.svg"                                    # The active splash file that will be shown on boot
default_splash_file="/app/retrodeck/graphics/splash.svg"                               # The default RetroDECK splash screen
# TODO: instead of this maybe we can iterate the features.json
multi_user_emulator_config_dirs="$rd_core_files/reference_lists/multi_user_emulator_config_dirs.cfg"  # A list of emulator config folders that can be safely linked/unlinked entirely in multi-user mode
rd_es_themes="/app/share/es-de/themes"                                                                   # The directory where themes packaged with RetroDECK are stored
rd_lockfile="$XDG_CONFIG_HOME/retrodeck/.lock"                                                                   # Where the lockfile is located
sd_sdcard_default_path="/run/media/mmcblk0p1"                                                                        # Steam Deck SD default path
hard_version="$(cat '/app/retrodeck/version')"                                                           # hardcoded version (in the readonly filesystem)
rd_repo="https://github.com/RetroDECK/RetroDECK"                                                         # The URL of the main RetroDECK GitHub repo
es_themes_list="https://gitlab.com/es-de/themes/themes-list/-/raw/master/themes.json"                    # The URL of the ES-DE 2.0 themes list
remote_network_target_1="https://flathub.org"                                                            # The URL of a common internet target for testing network access
remote_network_target_2="$rd_repo"                                                                       # The URL of a common internet target for testing network access
remote_network_target_3="https://one.one.one.one"                                                        # The URL of a common internet target for testing network access
helper_files_path="$rd_core_files/helper_files"                                                     # The parent folder of RetroDECK documentation files for deployment
rd_metainfo="/app/share/metainfo/net.retrodeck.retrodeck.metainfo.xml"                                   # The shipped metainfo XML file for this version
ra_cheevos_api_url="https://retroachievements.org/dorequest.php"                                                 # API URL for RetroAchievements.org
presets_dir="$rd_core_files/presets"                                                                  # Repository for all system preset config files
git_organization_name="RetroDECK"                                                                        # The name of the organization in our git repository such as GitHub
cooker_repository_name="Cooker"                                                                          # The name of the cooker repository under RetroDECK organization
main_repository_name="RetroDECK"                                                                         # The name of the main repository under RetroDECK organization
features="$rd_core_files/reference_lists/features.json"                                               # A file where all the RetroDECK and component capabilities are kept for querying
folder_iconsets_dir="$XDG_CONFIG_HOME/retrodeck/graphics/folder-iconsets"

# API-related file locations

rd_api_dir="$XDG_CONFIG_HOME/retrodeck/api"
REQUEST_PIPE="$rd_api_dir/retrodeck_api_pipe"
PID_FILE="$rd_api_dir/retrodeck_api_server.pid"
rd_api_socket="$rd_api_dir/retrodeck_api_server.sock"

# File lock file for multi-threaded write operations to the same file

rd_file_lock="$rd_api_dir/retrodeck_file_lock"

# Base dir for all installed RetroDECK components
rd_components="/app/retrodeck/components"
rd_shared_libs="/app/retrodeck/components/shared-libs"
rd_shared_libs_kde_path="/app/retrodeck/components/shared-libs/org.kde.Platform"
rd_shared_libs_gnome_path="/app/retrodeck/components/shared-libs/org.gnome.Platform"
rd_shared_libs_freedesktop_path="/app/retrodeck/components/shared-libs/org.freedesktop.Platform" 
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/retrodeck"
DEFAULT_LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
