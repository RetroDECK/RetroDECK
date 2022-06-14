#!/bin/bash

# This file is containing some global function needed for the script such as the config file tools

conf_init() {
  # initializing and reading the retrodeck config file
  if [ ! -f $rd_conf ]
  then # I have to initialize the variables as they cannot be red from an empty config file
    touch $rd_conf
    version="$(cat /app/retrodeck/version)"    # version info taken from the version file
    rdhome="$HOME/retrodeck"                   # the retrodeck home, aka ~/retrodeck
    roms_folder="$rdhome/roms"                 # default roms folder location (intenral)
  else # i just read the variables
    source $rd_conf
  fi
}

conf_write() {
  # writes the variables in the retrodeck config file

  # TODO: this can be optimized with a while and a list of variables to check
  if [ ! -z "$version" ] then #if the variable is not null then I update it
    sed -i "s%version=.*%version=$version%" $rd_conf
  fi

  if [ ! -z "$rdhome" ] then
    sed -i "s%rdhome=.*%rdhome=$rdhome%" $rd_conf
  fi

  if [ ! -z "$roms_folder" ] then
    sed -i "s%rdhome=.*%rdhome=$roms_folder" $rd_conf
  fi

}