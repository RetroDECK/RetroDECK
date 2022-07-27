#!/bin/bash

# This file is containing some global function needed for the script such as the config file tools

rd_conf="/var/config/retrodeck/retrodeck.cfg"

conf_init() {
  # initializing and reading the retrodeck config file
  if [ ! -f $rd_conf ]
  then # I have to initialize the variables as they cannot be red from an empty config file
    echo "RetroDECK config file not found in $rd_conf"
    echo "Initializing"
    touch $rd_conf

    # Variables to manage: adding a variable here means adding it to conf_write()
    echo "#!/bin/bash" >> $rd_conf
    
    # version info taken from the version file
    version="$(cat /app/retrodeck/version)" 
    echo "version=$version" >> $rd_conf
    
    # the retrodeck home, aka ~/retrodeck
    rdhome="$HOME/retrodeck" 
    echo "rdhome=$rdhome" >> $rd_conf

    # default roms folder location (internal)
    roms_folder="$roms_folder"
    echo "roms_folder=$roms_folder" >> $rd_conf

    # default media folder location (internal)
    media_folder="$media_folder"
    echo "media_folder=$media_folder" >> $rd_conf   

    # default themes folder location (internal)
    themes_folder="$themes_folder"
    echo "themes_folder=$themes_folder" >> $rd_conf 


  else # i just read the variables
    echo "Found RetroDECK config file in $rd_conf"
    echo "Loading it"
    source $rd_conf
  fi
}

conf_write() {
  # writes the variables in the retrodeck config file

  echo "Writing the config file: $rd_conf"

  # TODO: this can be optimized with a while and a list of variables to check
  if [ ! -z "$version" ] #if the variable is not null then I update it
  then
    sed -i "s%version=.*%version=$version%" $rd_conf
  fi

  if [ ! -z "$rdhome" ]
  then
    sed -i "s%rdhome=.*%rdhome=$rdhome%" $rd_conf
  fi

  if [ ! -z "$roms_folder" ]
  then
    sed -i "s%roms_folder=.*%roms_folder=$roms_folder%" $rd_conf
  fi

  if [ ! -z "$media_folder" ]
  then
    sed -i "s%media_folder=.*%media_folder=$media_folder%" $rd_conf
  fi

  if [ ! -z "$themes_folder" ]
  then
    sed -i "s%themes_folder=.*%themes_folder=$themes_folder%" $rd_conf
  fi

}