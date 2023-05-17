#!/bin/bash

source /app/libexec/global.sh

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
      launched_from_cli="true"
      sh /app/tools/configurator.sh
      exit
      ;;
    --reset-emulator*)
      echo "You are about to reset one or more RetroDECK emulators."
      echo "Available options are: retroarch cemu citra dolphin duckstation melonds pcsx2 ppsspp primehack rpcs3 xemu yuzu all-emulators"
      read -p "Please enter the emulator you would like to reset: " emulator
      if [[ "$emulator" =~ ^(retroarch|cemu|citra|dolphin|duckstation|melonds|pcsx2|ppsspp|primehack|rpcs3|xemu|yuzu|all-emulators)$ ]]; then
        read -p "You are about to reset $emulator to default settings. Enter 'y' to continue, 'n' to stop: " response
        if [[ $response == [yY] ]]; then
          prepare_emulator "reset" "$emulator" "cli"
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
if [ -f "$lockfile" ]; then
  # ...but the version doesn't match with the config file
  if [ "$hard_version" != "$version" ]; then
    echo "Config file's version is $version but the actual version is $hard_version"
    if grep -qF "cooker" <<< $hard_version; then # If newly-installed version is a "cooker" build
      cooker_base_version=$(echo $hard_version | cut -d'-' -f2)
      choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Upgrade" --extra-button="Don't Upgrade" --extra-button="Fresh Install" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Cooker Upgrade" \
      --text="You appear to be upgrading to a \"cooker\" build of RetroDECK.\n\nWould you like to perform the standard post-update process, skip the post-update process or remove ALL existing RetroDECK data to start from a fresh install?\n\nPerforming the normal post-update process multiple times may lead to unexpected results.")
      rc=$? # Capture return code, as "Yes" button has no text value
      if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
        if [[ $choice == "Don't Upgrade" ]]; then # If user wants to bypass the post_update.sh process this time.
          echo "Skipping upgrade process for cooker build, updating stored version in retrodeck.cfg"
          set_setting_value $rd_conf "version" "$hard_version" retrodeck # Set version of currently running RetroDECK to updated retrodeck.cfg
        elif [[ $choice == "Fresh Install" ]]; then # Remove all RetroDECK data and start a fresh install
          echo "Removing RetroDECK data and starting fresh"
          rm -rf /var
          rm -rf "$HOME/retrodeck"
          source /app/libexec/global.sh
          finit
        fi
      else
        echo "Performing normal upgrade process for version" $cooker_base_version
        version=$cooker_base_version # Temporarily assign cooker base version to $version so update script can read it properly.
        post_update
      fi
    else # If newly-installed version is a normal build.
      if grep -qF "cooker" <<< $version; then # If previously installed version was a cooker build
        cooker_base_version=$(echo $version | cut -d'-' -f2)
        version=$cooker_base_version # Temporarily assign cooker base version to $version so update script can read it properly.
        set_setting_value $rd_conf "update_repo" "RetroDECK" retrodeck "options"
        set_setting_value $rd_conf "update_check" "false" retrodeck "options"
        set_setting_value $rd_conf "update_ignore" "" retrodeck "options"
      fi
      post_update       # Executing post update script
    fi
  fi
# Else, LOCKFILE IS NOT EXISTING (WAS REMOVED)
# if the lock file doesn't exist at all means that it's a fresh install or a triggered reset
else
  echo "Lockfile not found"
  finit             # Executing First/Force init
fi

if [[ $multi_user_mode == "true" ]]; then
  multi_user_determine_current_user
fi

# Run optional startup checks

desktop_mode_warning
low_space_warning

# Check if there is a new version of RetroDECK available, if update_check=true in retrodeck.cfg and there is network connectivity available.
if [[ $(check_network_connectivity) == "true" ]] && [[ $update_check == "true" ]]; then
  check_for_version_update
fi

# Normal Startup

start_retrodeck
