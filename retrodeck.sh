#!/bin/bash

# Function to display CLI help
show_cli_help() {
    echo -e "
Usage:
flatpak run [FLATPAK-RUN-OPTION] net.retrodeck.retrodeck [ARGUMENTS]

Arguments:
    -h, --help                          \t  Print this help
    -v, --version                       \t  Print RetroDECK version
    --show-config                       \t  Print information about the RetroDECK configuration file and its contents
    --debug                             \t  Enable debug logging for this run of RetroDECK
    --configurator                      \t  Starts the RetroDECK Configurator
    --compress-one <file>               \t  Compresses target file to a compatible format
    --compress-all <format>             \t  Compresses all supported games into a compatible format.\n\t\t\t\t\t\t  Available formats are \"chd\", \"zip\", \"rvz\" and \"all\"
    --reset <component>                 \t  Reset RetroDECK or one or more component/emulator configurations to default values. WARNING: no confirmation prompt
    --factory-reset                     \t  Factory Reset, triggers the initial setup WARNING: no confirmation prompt
    --test-upgrade <version>            \t  Test upgrading RetroDECK to a specific version, developer use only
    --set <preset> <system/all> [value] \t  Configure or toggle a preset. Examples: --set borders, --set borders all true,\n\t\t\t\t\t\t  --set borders gba false. Use --set help for more information
    --open <component/emulator>         \t  Open a specific component or emulator\n\t\t\t\t\t\t  --open --list for a list of available components

Game Launch:
    [<options>] <game_path>             \t  Start a game using the default emulator or\n\t\t\t\t\t\t  the one defined in ES-DE for game or system
    \t Options:
    \t \t-e (emulator)\t Run the game with the defined emulator (optional)
    \t \t-s (system)\t Force the game running with the defined system, for example running a gb game on gba (optional)
    \t \t-m (manual)\t Manual mode: show the list of available emulator to choose from (optional)

For flatpak run specific options please run: flatpak run -h

The RetroDECK Team
https://retrodeck.net
"
}

# Check if is an infromational message
# If so, set LOG_SILENT to true, source the global.sh script,
# show the needed information and quit
case "$1" in
  -h|--help)
    LOG_SILENT=true
    source /app/libexec/global.sh
    if [[ "$version" =~ ^[0-9] ]]; then
      echo "RetroDECK v$version"
    else
      echo "RetroDECK $version"
    fi
    show_cli_help
    exit 0
    ;;
  -v|--version)
    LOG_SILENT=true
    source /app/libexec/global.sh
    if [[ "$version" =~ ^[0-9] ]]; then
      echo "RetroDECK v$version"
    else
      echo "RetroDECK $version"
    fi
    exit 0
    ;;
  --show-config)
    LOG_SILENT=true
    source /app/libexec/global.sh
    echo "RetroDECK config file is in: $rd_conf"
    echo "Contents:"
    cat "$rd_conf"
    exit 0
    ;;
esac

source /app/libexec/global.sh

# Process command-line arguments
while [[ $# -gt 0 ]]; do
    # If the first argument is -e, -s, -m, or a valid file, attempt to launch the game
    if [ -f "$1" ] || [[ "$1" == "-e" || "$1" == "-s" || "$1" == "-m" ]]; then
        echo "$LOG_BUFFER"
        log i "Game start option detected: $1"
        run_game "$@"
        exit 0
    fi

    case "$1" in
        --debug)
            logging_level="debug"
            shift
            ;;
        --compress-one)
            cli_compress_single_game "$2"
            exit 0
            ;;
        --compress-all)
            cli_compress_all_games "$2"
            shift 2
            ;;
        --configurator)
            sh /app/tools/configurator.sh
            exit 0
            ;;
        --reset)
            component="${@:2}"
            if [ -z "$component" ]; then
                echo "You are about to reset one or more RetroDECK components or emulators."
                echo -e "Available options are:\nall, $(prepare_component --list | tr ' ' ',' | sed 's/,/, /g')"
                read -p "Please enter the component you would like to reset: " component
                component=$(echo "$component" | tr '[:upper:]' '[:lower:]')
            fi
            log d "Resetting component: $component"
            prepare_component "reset" "$component"
            exit 0
            ;;
        --factory-reset)
            prepare_component --factory-reset
            exit 0
            ;;
        --test-upgrade)
            if [[ "$2" =~ ^.+ ]]; then
                echo "You are about to test upgrading RetroDECK from version $2 to $hard_version"
                read -p "Enter 'y' to continue, 'n' to start RetroDECK normally: " response
                if [[ $response == [yY] ]]; then
                    version="$2"
                    logging_level="debug"  # Temporarily enable debug logging
                    shift 2
                else
                    shift
                fi
            else
                echo "Error: Invalid format. Usage: --test-upgrade <version>"
                exit 1
            fi
            ;;
        --set)
            preset="$2"
            if [ "$preset" == "cheevos" ]; then
                echo "Error: The 'cheevos' preset is not yet supported via CLI. Please use the RetroDECK Configurator."
                exit 1
            fi
            value="$3"
            if [ -z "$preset" ]; then
                echo "Error: No preset specified. Usage: --set <preset> [value] (use --set help for more information)"
                exit 1
            fi
            if [ "$preset" == "help" ]; then
                echo "Used to toggle or set a preset. Available presets are:"
                fetch_all_presets
                echo "Usage: --set <preset> [value]"
                echo "Examples:"
                echo "  Force borders to be true for GBA:"
                echo "    make_preset_changes borders gba true"
                echo "  Force borders to be true for all supported systems:"
                echo "    make_preset_changes borders all true"
                echo "  Toggle GBA in preset borders (this will disable if enabled and vice versa):"
                echo "    make_preset_changes borders gba true"
                echo "  Toggle all in preset borders:"
                echo "    make_preset_changes borders all"
                exit 0
            fi
            make_preset_changes "$preset" "$value"
            exit 0
            ;;
        --open)
            open_component "${@:2}"
            exit 0
            ;;
        -*)
            # Catch-all for unrecognized options starting with a dash
            log e "Error: Unknown option '$1'"
            echo "Error: Unrecognized option '$1'. Use -h or --help for usage information."
            exit 1
            ;;
        *)
            # If it reaches here and is an unrecognized argument, report the error
            log e "Error: Command or file '$1' not recognized."
            echo "Error: Command or file '$1' not recognized. Use -h or --help for usage information."
            exit 1
            ;;
    esac
done

# if lockfile exists
if [ -f "$lockfile" ]; then
  if [ "$hard_version" != "$version" ]; then
    log d "Update triggered"
    log d "Lockfile found but the version doesn't match with the config file"
    log i "Config file's version is $version but the actual version is $hard_version"
    if grep -qF "cooker" <<< $hard_version; then # If newly-installed version is a "cooker" build
      log d "Newly-installed version is a \"cooker\" build"
      configurator_generic_dialog "RetroDECK Cooker Warning" "RUNNING COOKER VERSIONS OF RETRODECK CAN BE EXTREMELY DANGEROUS AND ALL OF YOUR RETRODECK DATA\n(INCLUDING BIOS FILES, BORDERS, DOWNLOADED MEDIA, GAMELISTS, MODS, ROMS, SAVES, STATES, SCREENSHOTS, TEXTURE PACKS AND THEMES)\nARE AT RISK BY CONTINUING!"
      set_setting_value $rd_conf "update_repo" "$cooker_repository_name" retrodeck "options"
      set_setting_value $rd_conf "update_check" "true" retrodeck "options"
      set_setting_value $rd_conf "developer_options" "true" retrodeck "options"
      cooker_base_version=$(echo $version | cut -d'-' -f2)
      choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Upgrade" --extra-button="Don't Upgrade" --extra-button="Full Wipe and Fresh Install" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Cooker Upgrade" \
      --text="You appear to be upgrading to a \"cooker\" build of RetroDECK.\n\nWould you like to perform the standard post-update process, skip the post-update process or remove ALL existing RetroDECK folders and data (including ROMs and saves) to start from a fresh install?\n\nPerforming the normal post-update process multiple times may lead to unexpected results.")
      rc=$? # Capture return code, as "Yes" button has no text value
      if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
        if [[ $choice == "Don't Upgrade" ]]; then # If user wants to bypass the post_update.sh process this time.
          log i "Skipping upgrade process for cooker build, updating stored version in retrodeck.cfg"
          set_setting_value $rd_conf "version" "$hard_version" retrodeck # Set version of currently running RetroDECK to updated retrodeck.cfg
        elif [[ $choice == "Full Wipe and Fresh Install" ]]; then # Remove all RetroDECK data and start a fresh install
          if [[ $(configurator_generic_question_dialog "RetroDECK Cooker Reset" "This is going to remove all of the data in all locations used by RetroDECK!\n\n(INCLUDING BIOS FILES, BORDERS, DOWNLOADED MEDIA, GAMELISTS, MODS, ROMS, SAVES, STATES, SCREENSHOTS, TEXTURE PACKS AND THEMES)\n\nAre you sure you want to contine?") == "true" ]]; then
            if [[ $(configurator_generic_question_dialog "RetroDECK Cooker Reset" "Are you super sure?\n\nThere is no going back from this process, everything is gonzo.\nDust in the wind.\n\nYesterdays omelette.") == "true" ]]; then
              if [[ $(configurator_generic_question_dialog "RetroDECK Cooker Reset" "But are you super DUPER sure? We REAAAALLLLLYY want to make sure you know what is happening here.\n\nThe ~/retrodeck and ~/.var/app/net.retrodeck.retrodeck folders and ALL of their contents\nare about to be PERMANENTLY removed.\n\nStill sure you want to proceed?") == "true" ]]; then
                configurator_generic_dialog "RetroDECK Cooker Reset" "Ok, if you're that sure, here we go!"
                if [[ $(configurator_generic_question_dialog "RetroDECK Cooker Reset" "(Are you actually being serious here? Because we are...\n\nNo backsies.)") == "true" ]]; then
                  log w "Removing RetroDECK data and starting fresh"
                  rm -rf /var
                  rm -rf "$HOME/retrodeck"
                  rm -rf "$rdhome"
                  source /app/libexec/global.sh
                  finit
                fi
              fi
            fi
          fi
        fi
      else
        log i "Performing normal upgrade process for version $cooker_base_version"
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
        set_setting_value $rd_conf "developer_options" "false" retrodeck "options"
      fi
      post_update       # Executing post update script
    fi
  fi
# Else, LOCKFILE IS NOT EXISTING (WAS REMOVED)
# if the lock file doesn't exist at all means that it's a fresh install or a triggered reset
else
  log w "Lockfile not found"
  finit             # Executing First/Force init
fi

if [[ $multi_user_mode == "true" ]]; then
  multi_user_determine_current_user
fi

# Run optional startup checks
if [[ $(check_is_steam_deck) == "true" ]]; then # Only warn about Desktop Mode on Steam Deck, ignore for other platforms
  desktop_mode_warning
fi
low_space_warning

# Check if there is a new version of RetroDECK available, if update_check=true in retrodeck.cfg and there is network connectivity available.
log i "Check if there is a new version of RetroDECK available"
if [[ $update_check == "true" ]]; then
  if [[ $(check_network_connectivity) == "true" ]]; then
    log d "Running function check_for_version_update"
    check_for_version_update
  fi
  log i "You're running the latest version"
fi

# Normal Startup
start_retrodeck
# After everything is closed we run the quit function
quit_retrodeck
