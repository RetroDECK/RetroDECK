#!/bin/bash

# This file is containing some global function needed for the script such as the config file tools

source /app/libexec/functions.sh

# Static variables
rd_conf="/var/config/retrodeck/retrodeck.cfg"              # RetroDECK config file path
emuconfigs="/app/retrodeck/emu-configs"                    # folder with all the default emulator configs
lockfile="/var/config/retrodeck/.lock"                     # where the lockfile is located
default_sd="/run/media/mmcblk0p1"                          # Steam Deck SD default path
hard_version="$(cat '/app/retrodeck/version')"             # hardcoded version (in the readonly filesystem)

# Config files for emulators with single config files

citraconf="/var/config/citra-emu/qt-config.ini"
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

# If there is no config file I initalize the file with the the default values
if [ ! -f "$rd_conf" ]
then

  mkdir -p /var/config/retrodeck
  echo "RetroDECK config file not found in $rd_conf"
  echo "Initializing"
  # if we are here means that the we are in a new installation, so the version is valorized with the hardcoded one
  # Initializing the variables
  if [ -z $version]; then
    if [[ $(cat $lockfile) == *"0.4."* ]] || [[ $(cat $lockfile) == *"0.3."* ]] || [[ $(cat $lockfile) == *"0.2."* ]] || [[ $(cat $lockfile) == *"0.1."* ]]; then
      echo "Running version workaround"
      version=$(cat $lockfile)
    else
      version="$hard_version"
    fi
  fi

  rdhome="$HOME/retrodeck"                                   # the retrodeck home, aka ~/retrodeck
  roms_folder="$rdhome/roms"                                 # the default roms folder path
  saves_folder="$rdhome/saves"                               # the default saves folder path
  states_folder="$rdhome/states"                             # the default states folder path
  bios_folder="$rdhome/bios"                                 # the default bios folder
  media_folder="$rdhome/downloaded_media"                    # the media folder, where all the scraped data is downloaded into
  themes_folder="$rdhome/themes"                             # the themes folder
  sdcard="$default_sd"                                       # Steam Deck SD default path

  # Writing the variables for the first time
  echo '#!/bin/bash'                          >> $rd_conf
  echo "version=$version"                     >> $rd_conf
  echo "rdhome=$rdhome"                       >> $rd_conf
  echo "roms_folder=$roms_folder"             >> $rd_conf
  echo "saves_folder=$saves_folder"           >> $rd_conf
  echo "states_folder=$states_folder"         >> $rd_conf
  echo "bios_folder=$bios_folder"             >> $rd_conf
  echo "media_folder=$media_folder"           >> $rd_conf
  echo "themes_folder=$themes_folder"         >> $rd_conf
  echo "sdcard=$sdcard"                       >> $rd_conf

  echo "Setting config file permissions"
  chmod +rw $rd_conf

# If the config file is existing i just read the variables (source it)
else
  echo "Found RetroDECK config file in $rd_conf"
  echo "Loading it"
  source "$rd_conf"
fi
