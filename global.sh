#!/bin/bash

# This file is containing some global function needed for the script such as the config file tools

source /app/libexec/functions.sh

# Static variables
rd_conf="/var/config/retrodeck/retrodeck.cfg"                                                                         # RetroDECK config file path
rd_conf_backup="/var/config/retrodeck/retrodeck.bak"                                                                  # Backup of RetroDECK config file from update
emuconfigs="/app/retrodeck/emu-configs"                                                                               # folder with all the default emulator configs
rd_defaults="$emuconfigs/defaults/retrodeck/retrodeck.cfg"                                                            # A default RetroDECK config file
rd_update_patch="/var/config/retrodeck/rd_update.patch"                                                               # A static location for the temporary patch file used during retrodeck.cfg updates
bios_checklist="$emuconfigs/defaults/retrodeck/reference_lists/bios_checklist.cfg"                                    # A config file listing BIOS file information that can be verified
compression_targets="$emuconfigs/defaults/retrodeck/reference_lists/compression_targets.cfg"                          # A config file containing supported compression types per system
zip_compressable_extensions="$emuconfigs/defaults/retrodeck/reference_lists/zip_compressable_extensions.cfg"          # A config file containing every file extension that is allowed to be compressed to .zip format, because there are a lot!
easter_egg_checklist="$emuconfigs/defaults/retrodeck/reference_lists/easter_egg_checklist.cfg"                        # A config file listing days and times when special splash screens should show up
input_validation="$emuconfigs/defaults/retrodeck/reference_lists/input_validation.cfg"                                # List of valid CLI inputs
splashscreen_dir="/var/config/emulationstation/.emulationstation/resources/graphics/extra-splashes"                   # The default location of extra splash screens
current_splash_file="/var/config/emulationstation/.emulationstation/resources/graphics/splash.svg"                    # The active splash file that will be shown on boot
default_splash_file="/var/config/emulationstation/.emulationstation/resources/graphics/splash-orig.svg"               # The default RetroDECK splash screen
multi_user_data_folder="$rdhome/multi-user-data"                                                                      # The default location of multi-user environment profiles
multi_user_emulator_config_dirs="$emuconfigs/defaults/retrodeck/reference_lists/multi_user_emulator_config_dirs.cfg"  # A list of emulator config folders that can be safely linked/unlinked entirely in multi-user mode
backups_folder="$rdhome/backups"                                                                                      # A standard location for backup file storage
rd_es_themes="/app/share/emulationstation/themes"                                                                     # The directory where themes packaged with RetroDECK are stored
lockfile="/var/config/retrodeck/.lock"                                                                                # where the lockfile is located
default_sd="/run/media/mmcblk0p1"                                                                                     # Steam Deck SD default path
hard_version="$(cat '/app/retrodeck/version')"                                                                        # hardcoded version (in the readonly filesystem)
rd_repo="https://github.com/XargonWan/RetroDECK"                                                                      # The URL of the main RetroDECK GitHub repo
es_themes_list="https://gitlab.com/es-de/themes/themes-list/-/raw/master/themes.json"                                 # The URL of the ES-DE 2.0 themes list
remote_network_target="https://one.one.one.one"                                                                       # The URL of a common internet target for testing network access
rpcs3_firmware="http://dus01.ps3.update.playstation.net/update/ps3/image/us/2023_0228_05fe32f5dc8c78acbcd84d36ee7fdc5b/PS3UPDAT.PUP"

# Config files for emulators with single config files

cemuconf="/var/config/Cemu/settings.xml"
citraconf="/var/config/citra-emu/qt-config.ini"
duckstationconf="/var/data/duckstation/settings.ini"
melondsconf="/var/config/melonDS/melonDS.ini"
ppssppconf="/var/config/ppsspp/PSP/SYSTEM/ppsspp.ini"
ryujinxconf="/var/config/Ryujinx/Config.json"
xemuconf="/var/config/xemu/xemu.toml"
yuzuconf="/var/config/yuzu/qt-config.ini"

# ES-DE config files

es_settings="/var/config/emulationstation/.emulationstation/es_settings.xml"

# RetroArch config files

raconf="/var/config/retroarch/retroarch.cfg"
ra_core_conf="/var/config/retroarch/retroarch-core-options.cfg"

# Dolphin config files

dolphinconf="/var/config/dolphin-emu/Dolphin.ini"
dolphingcpadconf="/var/config/dolphin-emu/GCPadNew.ini"
dolphingfxconf="/var/config/dolphin-emu/GFX.ini"
dolphinhkconf="/var/config/dolphin-emu/Hotkeys.ini"
dolphinqtconf="/var/config/dolphin-emu/Qt.ini"

# PCSX2 config files

pcsx2conf="/var/config/PCSX2/inis/GS.ini"
pcsx2uiconf="/var/config/PCSX2/inis/PCSX2_ui.ini"
pcsx2vmconf="/var/config/PCSX2/inis/PCSX2_vm.ini"

# PCSX2-QT config file

pcsx2qtconf="/var/config/PCSX2/inis/PCSX2.ini"

# Primehack config files

primehackconf="/var/config/primehack/Dolphin.ini"
primehackgcpadconf="/var/config/primehack/GCPadNew.ini"
primehackgfxconf="/var/config/primehack/GFX.ini"
primehackhkconf="/var/config/primehack/Hotkeys.ini"
primehackqtconf="/var/config/primehack/Qt.ini"

# RPCS3 config files

rpcs3conf="/var/config/rpcs3/config.yml"
rpcs3vfsconf="/var/config/rpcs3/vfs.yml"

# We moved the lockfile in /var/config/retrodeck in order to solve issue #53 - Remove in a few versions
if [ -f "$HOME/retrodeck/.lock" ]
then
  mv "$HOME/retrodeck/.lock" $lockfile
fi

# If there is no config file I initalize the file with the the default values
if [ ! -f "$rd_conf" ]
then
  mkdir -p /var/config/retrodeck
  echo "RetroDECK config file not found in $rd_conf"
  echo "Initializing"
  # if we are here means that the we are in a new installation, so the version is valorized with the hardcoded one
  # Initializing the variables
  if [ -z $version]; then
    if [[ $(cat $lockfile) == *"0.4."* ]] || [[ $(cat $lockfile) == *"0.3."* ]] || [[ $(cat $lockfile) == *"0.2."* ]] || [[ $(cat $lockfile) == *"0.1."* ]]; then # If the previous version is very out of date, pre-rd_conf
      echo "Running version workaround"
      version=$(cat $lockfile)
    else
      version="$hard_version"
    fi
  fi

  # Check if SD card path has changed from SteamOS update
  if [[ ! -d $default_sd && "$(ls -A /run/media/deck/)" ]]; then
    configurator_generic_dialog "The SD card was not found in the expected location.\nThis may happen when SteamOS is updated.\n\nPlease browse to the current location of the SD card.\n\nIf you are not using an SD card, please click \"Cancel\"."
    default_sd=$(directory_browse "SD Card Location")
  fi

  cp $rd_defaults $rd_conf # Load default settings
  set_setting_value $rd_conf "version" "$version" retrodeck # Set current version for new installs
  set_setting_value $rd_conf "sdcard" "$default_sd" retrodeck "paths" # Set SD card location if default path has changed

  echo "Setting config file permissions"
  chmod +rw $rd_conf
  echo "RetroDECK config file initialized. Contents:"
  echo
  cat $rd_conf
  source $rd_conf # Load new variables into memory

# If the config file is existing i just read the variables (source it)
else
  echo "Found RetroDECK config file in $rd_conf"
  echo "Loading it"
  source "$rd_conf"

  # Verify rdhome is where it is supposed to be.
  if [[ ! -d $rdhome ]]; then
    prev_home_path=$rdhome
    configurator_generic_dialog "The RetroDECK data folder was not found in the expected location.\nThis may happen when SteamOS is updated.\n\nPlease browse to the current location of the \"retrodeck\" folder."
    new_home_path=$(directory_browse "RetroDECK folder location")
    sed -i 's#'$prev_home_path'#'$new_home_path'#g' $rd_conf
    source "$rd_conf"
    emulators_post_move
  fi
fi
