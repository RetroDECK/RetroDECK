#!/bin/bash

# This file is containing some global function needed for the script such as the config file tools

# pathing the retrodeck components provided libraries
# now disabled as we are importing everything in /app/lib. In case we are breaking something we need to restore this approach
# export LD_LIBRARY_PATH="/app/retrodeck/lib:/app/retrodeck/lib/debug:/app/retrodeck/lib/pkgconfig:$LD_LIBRARY_PATH"

: "${logging_level:=info}"                  # Initializing the log level variable if not already valued, this will be actually red later from the config file                                                 
rd_logs_folder="$XDG_CONFIG_HOME/retrodeck/logs" # Static location to write all RetroDECK-related logs
if [ -h "$rd_logs_folder" ]; then # Check if internal logging folder is already a symlink
  if [ ! -e "$rd_logs_folder" ]; then # Check if internal logging folder symlink is broken
    unlink "$rd_logs_folder" # Remove broken symlink so the folder is recreated when sourcing logger.sh
  fi
fi
source /app/libexec/logger.sh
rotate_logs

# OS detection
width=$(grep -oP '\d+(?=x)' /sys/class/graphics/fb0/modes)
height=$(grep -oP '(?<=x)\d+' /sys/class/graphics/fb0/modes)
if [[ $width -ne 1280 ]] || [[ $height -ne 800 ]]; then
  native_resolution=false
else
  native_resolution=true
fi
distro_name=$(flatpak-spawn --host grep '^ID=' /etc/os-release | cut -d'=' -f2)
distro_version=$(flatpak-spawn --host grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2)
gpu_info=$(flatpak-spawn --host lspci | grep -i 'vga\|3d\|2d')
cpu_cores=$(nproc)
max_threads=$(echo $(($(nproc) / 2)))

log d "Debug mode enabled"
log i "Initializing RetroDECK"
log i "Running on $XDG_SESSION_DESKTOP, $XDG_SESSION_TYPE, $distro_name $distro_version"
if [[ -n $container ]]; then
  log i "Running inside $container environment"
fi
log i "GPU: $gpu_info"
log i "Resolution: $width x $height"
if [[ $native_resolution == true ]]; then
  log i "Steam Deck native resolution detected"
fi
log i "CPU: Using $max_threads out of $cpu_cores available CPU cores for multi-threaded operations"

source /app/libexec/050_save_migration.sh
source /app/libexec/api.sh
source /app/libexec/checks.sh
source /app/libexec/compression.sh
source /app/libexec/dialogs.sh
source /app/libexec/other_functions.sh
source /app/libexec/multi_user.sh
source /app/libexec/framework.sh
source /app/libexec/post_update.sh
source /app/libexec/prepare_component.sh
source /app/libexec/presets.sh
source /app/libexec/configurator_functions.sh
source /app/libexec/run_game.sh
source /app/libexec/steam_sync.sh

# Static variables
rd_conf="$XDG_CONFIG_HOME/retrodeck/retrodeck.cfg"                                                            # RetroDECK config file path
rd_conf_backup="$XDG_CONFIG_HOME/retrodeck/retrodeck.bak"                                                     # Backup of RetroDECK config file from update
config="/app/retrodeck/config"                                                                           # folder with all the default emulator configs
rd_defaults="$config/retrodeck/retrodeck.cfg"                                                            # A default RetroDECK config file
rd_update_patch="$XDG_CONFIG_HOME/retrodeck/rd_update.patch"                                                  # A static location for the temporary patch file used during retrodeck.cfg updates
bios_checklist="$config/retrodeck/reference_lists/bios.json"                                    # A config file listing BIOS file information that can be verified
input_validation="$config/retrodeck/reference_lists/input_validation.cfg"                                # A config file listing valid CLI inputs
finit_options_list="$config/retrodeck/reference_lists/finit_options_list.cfg"                            # A config file listing available optional installs during finit
splashscreen_dir="$XDG_CONFIG_HOME/ES-DE/resources/graphics/extra_splashes"                                   # The default location of extra splash screens
current_splash_file="$XDG_CONFIG_HOME/ES-DE/resources/graphics/splash.svg"                                    # The active splash file that will be shown on boot
default_splash_file="$XDG_CONFIG_HOME/ES-DE/resources/graphics/splash-orig.svg"                               # The default RetroDECK splash screen
# TODO: instead of this maybe we can iterate the features.json
multi_user_emulator_config_dirs="$config/retrodeck/reference_lists/multi_user_emulator_config_dirs.cfg"  # A list of emulator config folders that can be safely linked/unlinked entirely in multi-user mode
rd_es_themes="/app/share/es-de/themes"                                                                   # The directory where themes packaged with RetroDECK are stored
lockfile="$XDG_CONFIG_HOME/retrodeck/.lock"                                                                   # Where the lockfile is located
default_sd="/run/media/mmcblk0p1"                                                                        # Steam Deck SD default path
hard_version="$(cat '/app/retrodeck/version')"                                                           # hardcoded version (in the readonly filesystem)
rd_repo="https://github.com/RetroDECK/RetroDECK"                                                         # The URL of the main RetroDECK GitHub repo
es_themes_list="https://gitlab.com/es-de/themes/themes-list/-/raw/master/themes.json"                    # The URL of the ES-DE 2.0 themes list
remote_network_target_1="https://flathub.org"                                                            # The URL of a common internet target for testing network access
remote_network_target_2="$rd_repo"                                                                       # The URL of a common internet target for testing network access
remote_network_target_3="https://one.one.one.one"                                                        # The URL of a common internet target for testing network access
helper_files_folder="$config/retrodeck/helper_files"                                                     # The parent folder of RetroDECK documentation files for deployment
rd_metainfo="/app/share/metainfo/net.retrodeck.retrodeck.metainfo.xml"                                   # The shipped metainfo XML file for this version
rpcs3_firmware="http://dus01.ps3.update.playstation.net/update/ps3/image/us/2024_0227_3694eb3fb8d9915c112e6ab41a60c69f/PS3UPDAT.PUP" # RPCS3 Firmware download location
RA_API_URL="https://retroachievements.org/dorequest.php"                                                 # API URL for RetroAchievements.org
presets_dir="$config/retrodeck/presets"                                                                  # Repository for all system preset config files
git_organization_name="RetroDECK"                                                                        # The name of the organization in our git repository such as GitHub
cooker_repository_name="Cooker"                                                                          # The name of the cooker repository under RetroDECK organization
main_repository_name="RetroDECK"                                                                         # The name of the main repository under RetroDECK organization
features="$config/retrodeck/reference_lists/features.json"                                               # A file where all the RetroDECK and component capabilities are kept for querying
es_systems="/app/share/es-de/resources/systems/linux/es_systems.xml"                                     # ES-DE supported system list   
es_find_rules="/app/share/es-de/resources/systems/linux/es_find_rules.xml"                               # ES-DE emulator find rules

# API-related file locations

rd_api_dir="$XDG_CONFIG_HOME/retrodeck/api"
REQUEST_PIPE="$rd_api_dir/retrodeck_api_pipe"
PID_FILE="$rd_api_dir/retrodeck_api_server.pid"

# File lock file for multi-threaded write operations to the same file

RD_FILE_LOCK="$rd_api_dir/retrodeck_file_lock"

# Godot data transfer temp files

godot_bios_files_checked="$XDG_CONFIG_HOME/retrodeck/godot/godot_bios_files_checked.tmp"
godot_current_preset_settings="$XDG_CONFIG_HOME/retrodeck/godot/godot_current_preset_settings.tmp"
godot_compression_compatible_games="$XDG_CONFIG_HOME/retrodeck/godot/godot_compression_compatible_games.tmp"
godot_empty_roms_folders="$XDG_CONFIG_HOME/retrodeck/godot/godot_empty_roms_folders.tmp"

# Config files for emulators with single config files

duckstationconf="$XDG_CONFIG_HOME/duckstation/settings.ini"
melondsconf="$XDG_CONFIG_HOME/melonDS/melonDS.ini"
ryujinxconf="$XDG_CONFIG_HOME/Ryujinx/Config.json"
xemuconf="$XDG_CONFIG_HOME/xemu/xemu.toml"
yuzuconf="$XDG_CONFIG_HOME/yuzu/qt-config.ini"
citraconf="$XDG_CONFIG_HOME/citra-emu/qt-config.ini"

# ES-DE config files

export ESDE_APPDATA_DIR="$XDG_CONFIG_HOME/ES-DE"
es_settings="$XDG_CONFIG_HOME/ES-DE/settings/es_settings.xml"
es_source_logs="$XDG_CONFIG_HOME/ES-DE/logs"

# RetroArch config files

raconf="$XDG_CONFIG_HOME/retroarch/retroarch.cfg"
ra_core_conf="$XDG_CONFIG_HOME/retroarch/retroarch-core-options.cfg"
ra_scummvm_conf="$XDG_CONFIG_HOME/retroarch/system/scummvm.ini"
ra_cores_path="$XDG_CONFIG_HOME/retroarch/cores"

# CEMU config files

cemuconf="$XDG_CONFIG_HOME/Cemu/settings.xml"
cemucontrollerconf="$XDG_CONFIG_HOME/Cemu/controllerProfiles/controller0.xml"

# Dolphin config files

dolphinconf="$XDG_CONFIG_HOME/dolphin-emu/Dolphin.ini"
dolphingcpadconf="$XDG_CONFIG_HOME/dolphin-emu/GCPadNew.ini"
dolphingfxconf="$XDG_CONFIG_HOME/dolphin-emu/GFX.ini"
dolphinhkconf="$XDG_CONFIG_HOME/dolphin-emu/Hotkeys.ini"
dolphinqtconf="$XDG_CONFIG_HOME/dolphin-emu/Qt.ini"
dolphinDynamicInputTexturesPath="$XDG_DATA_HOME/dolphin-emu/Load/DynamicInputTextures"
dolphinCheevosConf="$XDG_CONFIG_HOME/dolphin-emu/RetroAchievements.ini"

# PCSX2 config files

pcsx2conf="$XDG_CONFIG_HOME/PCSX2/inis/PCSX2.ini"
pcsx2gsconf="$XDG_CONFIG_HOME/PCSX2/inis/GS.ini" # This file should be deprecated since moving to PCSX2-QT
pcsx2uiconf="$XDG_CONFIG_HOME/PCSX2/inis/PCSX2_ui.ini" # This file should be deprecated since moving to PCSX2-QT
pcsx2vmconf="$XDG_CONFIG_HOME/PCSX2/inis/PCSX2_vm.ini" # This file should be deprecated since moving to PCSX2-QT

# PPSSPP-SDL config files

ppssppconf="$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/ppsspp.ini"
ppssppcontrolsconf="$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/controls.ini"
ppssppcheevosconf="$XDG_CONFIG_HOME/ppsspp/PSP/SYSTEM/ppsspp_retroachievements.dat"

# Primehack config files

primehackconf="$XDG_CONFIG_HOME/primehack/Dolphin.ini"
primehackgcpadconf="$XDG_CONFIG_HOME/primehack/GCPadNew.ini"
primehackgfxconf="$XDG_CONFIG_HOME/primehack/GFX.ini"
primehackhkconf="$XDG_CONFIG_HOME/primehack/Hotkeys.ini"
primehackqtconf="$XDG_CONFIG_HOME/primehack/Qt.ini"
primehackDynamicInputTexturesPath="$XDG_DATA_HOME/primehack/Load/DynamicInputTextures"

# RPCS3 config files

rpcs3conf="$XDG_CONFIG_HOME/rpcs3/config.yml"
rpcs3vfsconf="$XDG_CONFIG_HOME/rpcs3/vfs.yml"

# Vita3k config files

vita3kconf="$XDG_CONFIG_HOME/Vita3K/config.yml"

# MAME-SA config files

mameconf="$XDG_CONFIG_HOME/mame/ini/mame.ini"
mameuiconf="$XDG_CONFIG_HOME/mame/ini/ui.ini"
mamedefconf="$XDG_CONFIG_HOME/mame/cfg/default.cfg"

# Initialize logging location if it doesn't exist, before anything else happens
if [ ! -d "$rd_logs_folder" ]; then
    create_dir "$rd_logs_folder"
fi

# Initialize location of Godot temp data files, if it doesn't exist
if [[ ! -d "$XDG_CONFIG_HOME/retrodeck/godot" ]]; then
  create_dir "$XDG_CONFIG_HOME/retrodeck/godot"
fi

# We moved the lockfile in $XDG_CONFIG_HOME/retrodeck in order to solve issue #53 - Remove in a few versions
if [[ -f "$HOME/retrodeck/.lock" ]]; then
  mv "$HOME/retrodeck/.lock" "$lockfile"
fi

# If there is no config file I initalize the file with the the default values
if [[ ! -f "$rd_conf" ]]; then
  log w "RetroDECK config file not found in $rd_conf"
  log i "Initializing"
  # if we are here means that the we are in a new installation, so the version is valorized with the hardcoded one
  # Initializing the variables
  if [[ -z "$version" ]]; then
    if [[ -f "$lockfile" ]]; then
      if [[ $(cat "$lockfile") == *"0.4."* ]] || [[ $(cat "$lockfile") == *"0.3."* ]] || [[ $(cat "$lockfile") == *"0.2."* ]] || [[ $(cat "$lockfile") == *"0.1."* ]]; then # If the previous version is very out of date, pre-rd_conf
        log d "Running version workaround"
        version=$(cat "$lockfile")
      fi
    else
      version="$hard_version"
    fi
  fi

  # Check if SD card path has changed from SteamOS update
  if [[ ! -d "$default_sd" && "$(ls -A "/run/media/deck/")" ]]; then
    if [[ $(find "/run/media/deck/"* -maxdepth 0 -type d -print | wc -l) -eq 1 ]]; then # If there is only one SD card found in the new SteamOS 3.5 location, assign it as the default
      default_sd="$(find "/run/media/deck/"* -maxdepth 0 -type d -print)"
    else # If the default legacy path cannot be found, and there are multiple entries in the new Steam OS 3.5 SD card path, let the user pick which one to use
      configurator_generic_dialog "RetroDECK Setup" "The SD card was not found in the default location, and multiple drives were detected.\nPlease browse to the location of the desired SD card.\n\nIf you are not using an SD card, please click \"Cancel\"."
      default_sd="$(directory_browse "SD Card Location")"
    fi
  fi

  cp "$rd_defaults" "$rd_conf" # Load default settings file
  set_setting_value "$rd_conf" "version" "$version" retrodeck # Set current version for new installs
  set_setting_value "$rd_conf" "sdcard" "$default_sd" retrodeck "paths" # Set SD card location if default path has changed

  if grep -qF "cooker" <<< "$hard_version" || grep -qF "PR-" <<< "$hard_version"; then # If newly-installed version is a "cooker" or PR build
    set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    set_setting_value "$rd_conf" "developer_options" "true" retrodeck "options"
  fi

  log i "Setting config file permissions"
  chmod +rw "$rd_conf"
  log i "RetroDECK config file initialized. Contents:\n\n$(cat "$rd_conf")\n"
  conf_read # Load new variables into memory

else # If the config file is existing i just read the variables
  log i "Loading RetroDECK config file in $rd_conf"

  if grep -qF "cooker" <<< "$hard_version"; then # If newly-installed version is a "cooker" build
    set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    set_setting_value "$rd_conf" "developer_options" "true" retrodeck "options"
  fi

  conf_read

  # Verify rdhome is where it is supposed to be.
  if [[ ! -d "$rdhome" ]]; then
    configurator_generic_dialog "RetroDECK Setup" "The RetroDECK data folder was not found in the expected location.\nThis may happen when SteamOS is updated or if the folder was moved manually.\n\nPlease browse to the current location of the \"retrodeck\" folder."
    new_home_path=$(directory_browse "RetroDECK folder location")
    set_setting_value "$rd_conf" "rdhome" "$new_home_path" retrodeck "paths"
    conf_read
    prepare_component "postmove" "retrodeck"
    prepare_component "postmove" "all"
    conf_write
  fi

  # Static variables dependent on $rd_conf values, need to be set after reading $rd_conf
  backups_folder="$rdhome/backups"                                                                                      # A standard location for backup file storage
  multi_user_data_folder="$rdhome/multi-user-data"                                                                      # The default location of multi-user environment profiles
fi

# Steam ROM Manager user files and paths

steamsync_folder="$rdhome/.sync"                                                                                        # Folder containing favorites manifest for SRM
retrodeck_favorites_file="$steamsync_folder/retrodeck_favorites.json"                                                   # The current SRM manifest of all games that have been favorited in ES-DE
srm_log="$logs_folder/srm_log.log"                                                                                      # Log file for capturing the output of the most recent SRM run, for debugging purposes
retrodeck_added_favorites="$steamsync_folder/retrodeck_added_favorites.json"                                            # Temporary manifest of any games that were newly added to the ES-DE favorites and should be added to Steam
retrodeck_removed_favorites="$steamsync_folder/retrodeck_removed_favorites.json"                                        # Temporary manifest of any games that were unfavorited in ES-DE and should be removed from Steam

export GLOBAL_SOURCED=true

# Check if an update has happened
if [ -f "$lockfile" ]; then
  if [ "$hard_version" != "$version" ]; then
    log d "Update triggered"
    log d "Lockfile found but the version doesn't match with the config file"
    log i "Config file's version is $version but the actual version is $hard_version"
    if grep -qF "cooker" <<< "$hard_version"; then # If newly-installed version is a "cooker" build
      log d "Newly-installed version is a \"cooker\" build"
      configurator_generic_dialog "RetroDECK Cooker Warning" "RUNNING COOKER VERSIONS OF RETRODECK CAN BE EXTREMELY DANGEROUS AND ALL OF YOUR RETRODECK DATA\n(INCLUDING BIOS FILES, BORDERS, DOWNLOADED MEDIA, GAMELISTS, MODS, ROMS, SAVES, STATES, SCREENSHOTS, TEXTURE PACKS AND THEMES)\nARE AT RISK BY CONTINUING!"
      set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
      set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
      set_setting_value "$rd_conf" "developer_options" "true" retrodeck "options"
      set_setting_value "$rd_conf" "logging_level" "debug" retrodeck "options"
      cooker_base_version=$(echo "$version" | cut -d'-' -f2)
      choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Upgrade" --extra-button="Don't Upgrade" --extra-button="Full Wipe and Fresh Install" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Cooker Upgrade" \
      --text="You appear to be upgrading to a \"cooker\" build of RetroDECK.\n\nWould you like to perform the standard post-update process, skip the post-update process or remove ALL existing RetroDECK folders and data (including ROMs and saves) to start from a fresh install?\n\nPerforming the normal post-update process multiple times may lead to unexpected results.")
      rc=$? # Capture return code, as "Yes" button has no text value
      if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
        if [[ "$choice" == "Don't Upgrade" ]]; then # If user wants to bypass the post_update.sh process this time.
          log i "Skipping upgrade process for cooker build, updating stored version in retrodeck.cfg"
          set_setting_value "$rd_conf" "version" "$hard_version" retrodeck # Set version of currently running RetroDECK to updated retrodeck.cfg
        elif [[ "$choice" == "Full Wipe and Fresh Install" ]]; then # Remove all RetroDECK data and start a fresh install
          if [[ $(configurator_generic_question_dialog "RetroDECK Cooker Reset" "This is going to remove all of the data in all locations used by RetroDECK!\n\n(INCLUDING BIOS FILES, BORDERS, DOWNLOADED MEDIA, GAMELISTS, MODS, ROMS, SAVES, STATES, SCREENSHOTS, TEXTURE PACKS AND THEMES)\n\nAre you sure you want to contine?") == "true" ]]; then
            if [[ $(configurator_generic_question_dialog "RetroDECK Cooker Reset" "Are you super sure?\n\nThere is no going back from this process, everything is gonzo.\nDust in the wind.\n\nYesterdays omelette.") == "true" ]]; then
              if [[ $(configurator_generic_question_dialog "RetroDECK Cooker Reset" "But are you super DUPER sure? We REAAAALLLLLYY want to make sure you know what is happening here.\n\nThe ~/retrodeck and ~/.var/app/net.retrodeck.retrodeck folders and ALL of their contents\nare about to be PERMANENTLY removed.\n\nStill sure you want to proceed?") == "true" ]]; then
                configurator_generic_dialog "RetroDECK Cooker Reset" "Ok, if you're that sure, here we go!"
                if [[ $(configurator_generic_question_dialog "RetroDECK Cooker Reset" "(Are you actually being serious here? Because we are...\n\nNo backsies.)") == "true" ]]; then
                  log w "Removing RetroDECK data and starting fresh"
                  rm -rf /var
                  rm -rf "$HOME/retrodeck"
                  rm -rf "$rdhome"
                  source /app/libexec/global.sh
                  finit
                fi
              fi
            fi
          fi
        fi
      else
        log i "Performing normal upgrade process for version $cooker_base_version"
        version="$cooker_base_version" # Temporarily assign cooker base version to $version so update script can read it properly.
        post_update
      fi
    else # If newly-installed version is a normal build.
      if grep -qF "cooker" <<< "$version"; then # If previously installed version was a cooker build
        cooker_base_version=$(echo "$version" | cut -d'-' -f2)
        version="$cooker_base_version" # Temporarily assign cooker base version to $version so update script can read it properly.
        set_setting_value "$rd_conf" "update_repo" "RetroDECK" retrodeck "options"
        set_setting_value "$rd_conf" "update_check" "false" retrodeck "options"
        set_setting_value "$rd_conf" "update_ignore" "" retrodeck "options"
        set_setting_value "$rd_conf" "developer_options" "false" retrodeck "options"
        set_setting_value "$rd_conf" "logging_level" "info" retrodeck "options"
      fi
      post_update       # Executing post update script
    fi
  fi
# Else, LOCKFILE IS NOT EXISTING (WAS REMOVED)
# if the lock file doesn't exist at all means that it's a fresh install or a triggered reset
else
  log w "Lockfile not found"
  finit             # Executing First/Force init
fi
