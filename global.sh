#!/bin/bash

# This file is containing some global function needed for the script such as the config file tools

# Static variables
rd_conf="/var/config/retrodeck/retrodeck.cfg"              # RetroDECK config file path
emuconfigs="/app/retrodeck/emu-configs"                    # folder with all the default emulator configs
lockfile="/var/config/retrodeck/.lock"                     # where the lockfile is located
default_sd="/run/media/mmcblk0p1"                          # Steam Deck SD default path
hard_version="$(cat '/app/retrodeck/version')"             # hardcoded version (in the readonly filesystem)

conf_write() {
  # writes the variables in the retrodeck config file

  echo "DEBUG: printing the config file content before writing it:"
  cat "$rd_conf"
  echo ""

  echo "Writing the config file: $rd_conf"

  # TODO: this can be optimized with a while and a list of variables to check
  if [ ! -z "$version" ] #if the variable is not null then I update it
  then
    sed -i "s%version=.*%version=$version%" ""$rd_conf""
  fi

  if [ ! -z "$rdhome" ]
  then
    sed -i "s%rdhome=.*%rdhome=$rdhome%" ""$rd_conf""
  fi

  if [ ! -z "$roms_folder" ]
  then
    sed -i "s%roms_folder=.*%roms_folder=$roms_folder%" "$rd_conf"
  fi

  if [ ! -z "$media_folder" ]
  then
    sed -i "s%media_folder=.*%media_folder=$media_folder%" ""$rd_conf""
  fi

  if [ ! -z "$themes_folder" ]
  then
    sed -i "s%themes_folder=.*%themes_folder=$themes_folder%" ""$rd_conf""
  fi

  if [ ! -z "$sdcard" ]
  then
    sed -i "s%sdcard=.*%sdcard=$sdcard%" "$rd_conf"
  fi

  echo "DEBUG: New contents:"
  cat "$rd_conf"
  echo ""

}

# If there is no config file I initalize the file with the the default values
if [ ! -f "$rd_conf" ]
then

  echo "RetroDECK config file not found in $rd_conf"
  echo "Initializing"

  # Initializing the variables
  version="$hard_version"                                    # if we are here means that the we are in a new installation, so the version is valorized with the hardcoded one
  rdhome="$HOME/retrodeck"                                   # the retrodeck home, aka ~/retrodeck
  roms_folder="$rdhome/roms"                                 # the default roms folder path
  media_folder="$rdhome/retrodeck/downloaded_media"          # the media folder, where all the scraped data is downloaded into
  themes_folder="$rdhome/retrodeck/themes"                   # the themes folder
  sdcard="$default_sd"                                       # Steam Deck SD default path

  # Writing the variables for the first time
  echo "#!/bin/bash"                          >> $rd_conf
  echo "version=$version"                     >> $rd_conf
  echo "rdhome=$rdhome"                       >> $rd_conf
  echo "roms_folder=$roms_folder"             >> $rd_conf
  echo "media_folder=$media_folder"           >> $rd_conf
  echo "themes_folder=$themes_folder"         >> $rd_conf
  echo "sdcard=$sdcard"                       >> $rd_conf

# If the config file is existing i just read the variables (source it)
else
  echo "Found RetroDECK config file in $rd_conf"
  echo "Loading it"
  source "$rd_conf"
fi