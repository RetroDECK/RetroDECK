#!/bin/bash

# This file is containing some global function needed for the script such as the config file tools

# pathing the retrodeck components provided libraries
# now disabled as we are importing everything in /app/lib. In case we are breaking something we need to restore this approach
# export LD_LIBRARY_PATH="/app/retrodeck/lib:/app/retrodeck/lib/debug:/app/retrodeck/lib/pkgconfig:$LD_LIBRARY_PATH"

: "${logging_level:=info}"                  # Initializing the log level variable if not already valued, this will be actually red later from the config file                                                 
rd_logs_folder="/var/config/retrodeck/logs" # Static location to write all RetroDECK-related logs
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

source /app/libexec/050_save_migration.sh
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

# Static variables
rd_conf="/var/config/retrodeck/retrodeck.cfg"                                                            # RetroDECK config file path
rd_conf_backup="/var/config/retrodeck/retrodeck.bak"                                                     # Backup of RetroDECK config file from update
config="/app/retrodeck/config"                                                                           # folder with all the default emulator configs
rd_defaults="$config/retrodeck/retrodeck.cfg"                                                            # A default RetroDECK config file
rd_update_patch="/var/config/retrodeck/rd_update.patch"                                                  # A static location for the temporary patch file used during retrodeck.cfg updates
bios_checklist="$config/retrodeck/reference_lists/bios.json"                                    # A config file listing BIOS file information that can be verified
input_validation="$config/retrodeck/reference_lists/input_validation.cfg"                                # A config file listing valid CLI inputs
finit_options_list="$config/retrodeck/reference_lists/finit_options_list.cfg"                            # A config file listing available optional installs during finit
splashscreen_dir="/var/config/ES-DE/resources/graphics/extra_splashes"                                   # The default location of extra splash screens
current_splash_file="/var/config/ES-DE/resources/graphics/splash.svg"                                    # The active splash file that will be shown on boot
default_splash_file="/var/config/ES-DE/resources/graphics/splash-orig.svg"                               # The default RetroDECK splash screen
# TODO: instead of this maybe we can iterate the features.json
multi_user_emulator_config_dirs="$config/retrodeck/reference_lists/multi_user_emulator_config_dirs.cfg"  # A list of emulator config folders that can be safely linked/unlinked entirely in multi-user mode
rd_es_themes="/app/share/es-de/themes"                                                                   # The directory where themes packaged with RetroDECK are stored
lockfile="/var/config/retrodeck/.lock"                                                                   # Where the lockfile is located
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

# Godot data transfer temp files

godot_bios_files_checked="/var/config/retrodeck/godot/godot_bios_files_checked.tmp"
godot_current_preset_settings="/var/config/retrodeck/godot/godot_current_preset_settings.tmp"
godot_compression_compatible_games="/var/config/retrodeck/godot/godot_compression_compatible_games.tmp"
godot_empty_roms_folders="/var/config/retrodeck/godot/godot_empty_roms_folders.tmp"

# Config files for emulators with single config files

duckstationconf="/var/config/duckstation/settings.ini"
melondsconf="/var/config/melonDS/melonDS.ini"
ryujinxconf="/var/config/Ryujinx/Config.json"
xemuconf="/var/config/xemu/xemu.toml"
yuzuconf="/var/config/yuzu/qt-config.ini"
citraconf="/var/config/citra-emu/qt-config.ini"

# ES-DE config files

export ESDE_APPDATA_DIR="/var/config/ES-DE"
es_settings="/var/config/ES-DE/settings/es_settings.xml"
es_source_logs="/var/config/ES-DE/logs"

# RetroArch config files

raconf="/var/config/retroarch/retroarch.cfg"
ra_core_conf="/var/config/retroarch/retroarch-core-options.cfg"
ra_scummvm_conf="/var/config/retroarch/system/scummvm.ini"
ra_cores_path="/var/config/retroarch/cores"  

# CEMU config files

cemuconf="/var/config/Cemu/settings.xml"
cemucontrollerconf="/var/config/Cemu/controllerProfiles/controller0.xml"

# Dolphin config files

dolphinconf="/var/config/dolphin-emu/Dolphin.ini"
dolphingcpadconf="/var/config/dolphin-emu/GCPadNew.ini"
dolphingfxconf="/var/config/dolphin-emu/GFX.ini"
dolphinhkconf="/var/config/dolphin-emu/Hotkeys.ini"
dolphinqtconf="/var/config/dolphin-emu/Qt.ini"
dolphinDynamicInputTexturesPath="/var/data/dolphin-emu/Load/DynamicInputTextures"
dolphinCheevosConf="/var/config/dolphin-emu/RetroAchievements.ini"

# PCSX2 config files

pcsx2conf="/var/config/PCSX2/inis/PCSX2.ini"
pcsx2gsconf="/var/config/PCSX2/inis/GS.ini" # This file should be deprecated since moving to PCSX2-QT
pcsx2uiconf="/var/config/PCSX2/inis/PCSX2_ui.ini" # This file should be deprecated since moving to PCSX2-QT
pcsx2vmconf="/var/config/PCSX2/inis/PCSX2_vm.ini" # This file should be deprecated since moving to PCSX2-QT

# PPSSPP-SDL config files

ppssppconf="/var/config/ppsspp/PSP/SYSTEM/ppsspp.ini"
ppssppcontrolsconf="/var/config/ppsspp/PSP/SYSTEM/controls.ini"
ppssppcheevosconf="/var/config/ppsspp/PSP/SYSTEM/ppsspp_retroachievements.dat"

# Primehack config files

primehackconf="/var/config/primehack/Dolphin.ini"
primehackgcpadconf="/var/config/primehack/GCPadNew.ini"
primehackgfxconf="/var/config/primehack/GFX.ini"
primehackhkconf="/var/config/primehack/Hotkeys.ini"
primehackqtconf="/var/config/primehack/Qt.ini"
primehackDynamicInputTexturesPath="/var/data/primehack/Load/DynamicInputTextures"

# RPCS3 config files

rpcs3conf="/var/config/rpcs3/config.yml"
rpcs3vfsconf="/var/config/rpcs3/vfs.yml"

# Vita3k config files

vita3kconf="/var/config/Vita3K/config.yml"

# MAME-SA config files

mameconf="/var/config/mame/ini/mame.ini"
mameuiconf="/var/config/mame/ini/ui.ini"
mamedefconf="/var/config/mame/cfg/default.cfg"

# Initialize logging location if it doesn't exist, before anything else happens
if [ ! -d "$rd_logs_folder" ]; then
    create_dir "$rd_logs_folder"
fi

# Initialize location of Godot temp data files, if it doesn't exist
if [[ ! -d "/var/config/retrodeck/godot" ]]; then
  create_dir "/var/config/retrodeck/godot"
fi

# We moved the lockfile in /var/config/retrodeck in order to solve issue #53 - Remove in a few versions
if [[ -f "$HOME/retrodeck/.lock" ]]; then
  mv "$HOME/retrodeck/.lock" $lockfile
fi

# If there is no config file I initalize the file with the the default values
if [[ ! -f "$rd_conf" ]]; then
  log w "RetroDECK config file not found in $rd_conf"
  log i "Initializing"
  # if we are here means that the we are in a new installation, so the version is valorized with the hardcoded one
  # Initializing the variables
  if [[ -z "$version" ]]; then
    if [[ -f "$lockfile" ]]; then
      if [[ $(cat $lockfile) == *"0.4."* ]] || [[ $(cat $lockfile) == *"0.3."* ]] || [[ $(cat $lockfile) == *"0.2."* ]] || [[ $(cat $lockfile) == *"0.1."* ]]; then # If the previous version is very out of date, pre-rd_conf
        log d "Running version workaround"
        version=$(cat $lockfile)
      fi
    else
      version="$hard_version"
    fi
  fi

  # Check if SD card path has changed from SteamOS update
  if [[ ! -d "$default_sd" && "$(ls -A /run/media/deck/)" ]]; then
    if [[ $(find /run/media/deck/* -maxdepth 0 -type d -print | wc -l) -eq 1 ]]; then # If there is only one SD card found in the new SteamOS 3.5 location, assign it as the default
      default_sd="$(find /run/media/deck/* -maxdepth 0 -type d -print)"
    else # If the default legacy path cannot be found, and there are multiple entries in the new Steam OS 3.5 SD card path, let the user pick which one to use
      configurator_generic_dialog "RetroDECK Setup" "The SD card was not found in the default location, and multiple drives were detected.\nPlease browse to the location of the desired SD card.\n\nIf you are not using an SD card, please click \"Cancel\"."
      default_sd="$(directory_browse "SD Card Location")"
    fi
  fi

  cp $rd_defaults $rd_conf # Load default settings file
  set_setting_value $rd_conf "version" "$version" retrodeck # Set current version for new installs
  set_setting_value $rd_conf "sdcard" "$default_sd" retrodeck "paths" # Set SD card location if default path has changed

  if grep -qF "cooker" <<< "$hard_version" || grep -qF "PR-" <<< "$hard_version"; then # If newly-installed version is a "cooker" or PR build
    set_setting_value $rd_conf "update_repo" "$cooker_repository_name" retrodeck "options"
    set_setting_value $rd_conf "update_check" "true" retrodeck "options"
    set_setting_value $rd_conf "developer_options" "true" retrodeck "options"
  fi

  log i "Setting config file permissions"
  chmod +rw $rd_conf
  log i "RetroDECK config file initialized. Contents:\n\n$(cat $rd_conf)\n"
  conf_read # Load new variables into memory
  #tmplog_merger # This function is tempry(?) removed

# If the config file is existing i just read the variables
else
  log i "Loading RetroDECK config file in $rd_conf"

  if grep -qF "cooker" <<< $hard_version; then # If newly-installed version is a "cooker" build
    set_setting_value $rd_conf "update_repo" "$cooker_repository_name" retrodeck "options"
    set_setting_value $rd_conf "update_check" "true" retrodeck "options"
    set_setting_value $rd_conf "developer_options" "true" retrodeck "options"
  fi

  conf_read

  # Verify rdhome is where it is supposed to be.
  if [[ ! -d "$rdhome" ]]; then
    prev_home_path="$rdhome"
    configurator_generic_dialog "RetroDECK Setup" "The RetroDECK data folder was not found in the expected location.\nThis may happen when SteamOS is updated.\n\nPlease browse to the current location of the \"retrodeck\" folder."
    new_home_path=$(directory_browse "RetroDECK folder location")
    set_setting_value $rd_conf "rdhome" "$new_home_path" retrodeck "paths"
    conf_read
    #tmplog_merger # This function is tempry(?) removed
    prepare_component "retrodeck" "postmove"
    prepare_component "all" "postmove"
    conf_write
  fi

  # Static variables dependent on $rd_conf values, need to be set after reading $rd_conf
  backups_folder="$rdhome/backups"                                                                                      # A standard location for backup file storage
  multi_user_data_folder="$rdhome/multi-user-data"                                                                      # The default location of multi-user environment profiles
fi

logs_folder="$rdhome/logs"                # The path of the logs folder, here we collect all the logs
steamsync_folder="$rdhome/.sync"          # Folder containing all the steam sync launchers for SRM
steamsync_folder_tmp="$rdhome/.sync-tmp"  # Temp folder containing all the steam sync launchers for SRM
backups_folder="$rdhome/backups"          # Folder containing all the RetroDECK backups

export GLOBAL_SOURCED=true
