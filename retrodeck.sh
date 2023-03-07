#!/bin/bash

source /app/libexec/global.sh
source /app/libexec/post_update.sh

# Arguments section

for i in "$@"; do
  case $i in
    -h*|--help*)
      echo "RetroDECK v""$version"
      echo "
      Usage:
flatpak run [FLATPAK-RUN-OPTION] net.retrodeck-retrodeck [ARGUMENTS]

Arguments:
    -h, --help                    Print this help
    -v, --version                 Print RetroDECK version
    --info-msg                    Print paths and config informations
    --configure                   Starts the RetroDECK Configurator
    --compress <file>             Compresses target file to .chd format. Supports .cue, .iso and .gdi formats
    --reset-emulator <emulator>   Reset one or more emulator configs to the default values
    --reset-tools                 Reset the RetroDECK Tools section
    --reset-retrodeck             Starts the initial RetroDECK installer (backup your data first!)

For flatpak run specific options please run: flatpak run -h

https://retrodeck.net
"
      exit
      ;;
    --version*|-v*)
      echo "RetroDECK v$version"
      exit
      ;;
    --info-msg*)
      echo "RetroDECK v$version"
      echo "RetroDECK config file is in: $rd_conf"
      echo "Contents:"
      cat $rd_conf
      exit
      ;;
    --compress*)
      if [[ ! -z $2 ]]; then
      	if [[ -f $2 ]]; then
        	validate_for_chd $2
        else
        	echo "File not found, please specify the full path to the file to be compressed."
        fi
      else
        echo "Please use this command format \"--compress <full path to cue/gdi/iso file>\""
      fi      
      exit
      ;;
    --configure*)
      sh /var/config/retrodeck/tools/configurator.sh
      exit
      ;;
    --reset-emulator*)
      echo "You are about to reset one or more RetroDECK emulators."
      echo "Available options are: retroarch citra dolphin duckstation melonds pcsx2 ppsspp primehack rpcs3 xemu yuzu all-emulators"
      read -p "Please enter the emulator you would like to reset: " emulator
      if [[ "$emulator" =~ ^(retroarch|citra|dolphin|duckstation|melonds|pcsx2|ppsspp|primehack|rpcs3|xemu|yuzu|all-emulators)$ ]]; then
        read -p "You are about to reset $emulator to default settings. Press 'y' to continue, 'n' to stop: " response
        if [[ $response == [yY] ]]; then
          cli_emulator_reset $emulator
          read -p "The process has been completed, press any key to start RetroDECK."
          shift # Continue launch after previous command is finished
        else
          read -p "The process has been cancelled, press any key to exit."
          exit
        fi
      else
        echo "$emulator is not a valid selection, exiting..."
        exit
      fi
      ;;
    --reset-tools*)
      echo "You are about to reset the RetroDECK tools."
      read -p "Press 'y' to continue, 'n' to stop: " response
      if [[ $response == [yY] ]]; then
        tools_init
        read -p "The process has been completed, press any key to start RetroDECK."
        shift # Continue launch after previous command is finished
      else
        read -p "The process has been cancelled, press any key to exit."
        exit
      fi
      ;;
    --reset-retrodeck*)
      echo "You are about to reset RetroDECK completely."
      read -p "Press 'y' to continue, 'n' to stop: " response
      if [[ $response == [yY] ]]; then
        rm -f "$lockfile"
        read -p "The process has been completed, press any key to start RetroDECK."
        shift # Continue launch after previous command is finished
      else
        read -p "The process has been cancelled, press any key to exit."
        exit
      fi
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

# UPDATE TRIGGERED
# if lockfile exists
if [ -f "$lockfile" ]
then
  # ...but the version doesn't match with the config file
  if [ "$hard_version" != "$version" ];
  then
    echo "Config file's version is $version but the actual version is $hard_version"
    post_update       # Executing post update script
  fi
# Else, LOCKFILE IS NOT EXISTING (WAS REMOVED)
# if the lock file doesn't exist at all means that it's a fresh install or a triggered reset
else
  echo "Lockfile not found"
  finit             # Executing First/Force init
fi

# Normal Startup

start_retrodeck