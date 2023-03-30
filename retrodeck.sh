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
    --configurator                Starts the RetroDECK Configurator
    --compress-one <file>         Compresses target file to a compatible format
    --compress-all <format>       Compresses all supported games into compatible format. Available formats are \"chd\", \"zip\", \"rvz\" and \"all\".
    --reset-emulator <emulator>   Reset one or more emulator configs to the default values
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
    --compress-one*)
      cli_compress_single_game "$2"
      exit
      ;;
    --compress-all*)
      cli_compress_all_games "$2"
      ;;
    --configurator*)
      sh /app/tools/configurator.sh
      exit
      ;;
    --reset-emulator*)
      echo "You are about to reset one or more RetroDECK emulators."
      echo "Available options are: retroarch citra dolphin duckstation melonds pcsx2 ppsspp primehack rpcs3 xemu yuzu all-emulators"
      read -p "Please enter the emulator you would like to reset: " emulator
      if [[ "$emulator" =~ ^(retroarch|citra|dolphin|duckstation|melonds|pcsx2|ppsspp|primehack|rpcs3|xemu|yuzu|all-emulators)$ ]]; then
        read -p "You are about to reset $emulator to default settings. Enter 'y' to continue, 'n' to stop: " response
        if [[ $response == [yY] ]]; then
          cli_emulator_reset $emulator
          read -p "The process has been completed, press Enter key to start RetroDECK."
          shift # Continue launch after previous command is finished
        else
          read -p "The process has been cancelled, press Enter key to exit."
          exit
        fi
      else
        echo "$emulator is not a valid selection, exiting..."
        exit
      fi
      ;;
    --reset-retrodeck*)
      echo "You are about to reset RetroDECK completely!"
      read -p "Enter 'y' to continue, 'n' to stop: " response
      if [[ $response == [yY] ]]; then
        rm -f "$lockfile"
        rm -f "$rd_conf"
        read -p "The process has been completed, press Enter key to start the initial RetroDECK setup process."
        shift # Continue launch after previous command is finished
      else
        read -p "The process has been cancelled, press Enter key to exit."
        exit
      fi
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      validate_input "$i"
      if [[ ! $input_validated == "true" ]]; then
        echo "Please specify a valid option. Use -h for more information."
      fi
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
  if [[ check_network_connectivity == "true" ]]; then
    finit             # Executing First/Force init
  else
    configurator_generic_dialog "You do not appear to be connected to a network with internet access.\n\nThe initial RetroDECK setup requires some files from the internet to function properly.\n\nPlease retry this process once a network connection is available."
    exit 1
  fi
fi

if [[ $multi_user_mode == "true" ]]; then
  multi_user_determine_current_user
fi

# Check if running in Desktop mode and warn if true, unless desktop_mode_warning=false in retrodeck.cfg

desktop_mode_warning

# Check if there is a new version of RetroDECK available, if update_check=true in retrodeck.cfg and there is network connectivity available.
if [[ check_network_connectivity == "true" ]] && [[ $update_check == "true" ]]; then
  check_for_version_update
fi

# Normal Startup

start_retrodeck