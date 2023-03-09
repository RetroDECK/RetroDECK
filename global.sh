#!/bin/bash

# This file is containing some global function needed for the script such as the config file tools

source /app/libexec/functions.sh

# Static variables
rd_conf="/var/config/retrodeck/retrodeck.cfg"                   # RetroDECK config file path
rd_conf_backup="/var/config/retrodeck/retrodeck.bak"            # Backup of RetroDECK config file from update
emuconfigs="/app/retrodeck/emu-configs"                         # folder with all the default emulator configs
rd_defaults="$emuconfigs/defaults/retrodeck.cfg"                # A default RetroDECK config file
rd_update_patch="/var/config/retrodeck/rd_update.patch"         # A static location for the temporary patch file used during retrodeck.cfg updates
bios_checklist="/var/config/retrodeck/tools/bios_checklist.cfg" # A config file listing BIOS file information that can be verified
lockfile="/var/config/retrodeck/.lock"                          # where the lockfile is located
default_sd="/run/media/mmcblk0p1"                               # Steam Deck SD default path
hard_version="$(cat '/app/retrodeck/version')"                  # hardcoded version (in the readonly filesystem)
rd_repo="https://github.com/XargonWan/RetroDECK"                # The official GitHub repo of RetroDECK

# Config files for emulators with single config files

citraconf="/var/config/citra-emu/qt-config.ini"
duckstationconf="/var/data/duckstation/settings.ini"
melondsconf="/var/config/melonDS/melonDS.ini"
rpcs3conf="/var/config/rpcs3/config.yml"
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
  set_setting_value $rd_conf "sdcard" "$default_sd" retrodeck # Set SD card location if default path has changed

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
