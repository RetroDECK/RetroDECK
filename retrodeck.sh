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
    --steam-sync [purge]                \t  Run the Steam ROM Manager sync process to update all ES-DE favorites in Steam. Add the \"purge\" argument to remove all Steam ROM Manager information from Steam.
    --repair-paths                      \t  Reconfigure broken folder locations in RetroDECK without a full reset
    --reset <component>                 \t  Reset RetroDECK or one or more component/emulator configurations to default values. WARNING: no confirmation prompt
    --factory-reset                     \t  Factory Reset, triggers the initial setup WARNING: no confirmation prompt
    --test-upgrade <version>            \t  Test upgrading RetroDECK to a specific version, developer use only
    --get <preset> [system/all]         \t  Show the current status of all systems in a given preset type. Use --get-help for more information.
    --set <preset> <system/all> <value> \t  Configure or toggle a preset. Examples: --set borders all true,\n\t\t\t\t\t\t  --set borders gba false. Use --set-help for more information
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
  --get-help)
    LOG_SILENT=true
    source /app/libexec/global.sh
    echo -e "\nUsed to check the state of all systems for a given preset.\n\nAvailable presets are:"
    fetch_all_presets | tr ' ' ',' | sed 's/,/, /g'
    echo -e "\nUsage: --get <preset> [system/all]"
    echo -e "\nExamples:"
    echo -e "  Get the list of all emulators that support the \"borders\" preset:"
    echo -e "    --get borders"
    echo -e "  Get the current state of the borders preset for the snes system:"
    echo -e "    --get borders snes"
    echo -e "  Get the current state of the borders preset for all the systems that support it:"
    echo -e "    --get borders all"
    exit 0
    ;;
  --set-help)
    LOG_SILENT=true
    source /app/libexec/global.sh
    echo -e "\nUsed to toggle or set a preset.\n\nAvailable presets are:"
    fetch_all_presets | tr ' ' ',' | sed 's/,/, /g'
    echo -e "\nUsage: --set <preset> <system/all> <value>"
    echo -e "\nExamples:"
    echo -e "  Enable borders for GBA:"
    echo -e "    --set borders gba on"
    echo -e "  Disable borders for all supported systems:"
    echo -e "    --set borders all off"
    echo -e "\nYou can also use 'true' or 'false' instead of 'on' and 'off'."
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
        --show-config)
          echo ""
          cat "$rd_conf"
          exit 0
        ;;
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
            exit 0
            ;;
        --steam-sync)
            if [[ -n "$2" ]]; then
              if [[ "$2" == "purge" ]]; then
                steam-rom-manager nuke
                rm -f "$retrodeck_favorites_file"
              else
                echo "Unknown argument \"$2\", please check the CLI help for more information."
              fi
            else
              steam_sync
            fi
            exit 0
            ;;
        --repair-paths)
            repair_paths
            exit 0
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
                read -r -p "Please enter the component you would like to reset: " component
                component=$(echo "$component" | tr '[:upper:]' '[:lower:]')
            fi
            log d "Resetting component: $component"
            prepare_component "reset" "$component"
            exit 0
            ;;
        --factory-reset)
            prepare_component "factory-reset"
            exit 0
            ;;
        --test-upgrade)
            if [[ "$2" =~ ^.+ ]]; then
                read -r -p "You are about to test upgrading RetroDECK from version $2 to $hard_version. Enter 'y' to continue ot 'n' to start RetroDECK normally: (y/N) " response
                if [[ ${response,,} == "y" ]]; then
                    version="$2"
                    logging_level="debug"  # Temporarily enable debug logging
                    log d "User replyed $response, testing upgrade from version $version"
                    shift 2
                else
                    shift 2
                fi
            else
                echo "Error: Invalid format. Usage: --test-upgrade <version>"
                exit 1
            fi
            ;;
        --get)
            preset="$2"
            system="$3"
            if [[ -z "$preset" ]]; then
              echo "Error: No preset specified. Usage: --get <preset> [system] (use --get-help for more information)"
              exit 1
            elif [[ $(fetch_all_presets | tr ' ' ',' | sed 's/,/, /g') =~ "$preset" ]]; then
              preset_compatible_systems=$(sed -n '/\['"$preset"'\]/, /\[/{ /\['"$preset"'\]/! { /\[/! p } }' "$rd_conf" | sed '/^$/d')
              if [[ -z "$system" ]]; then # User provided a preset but no system argument
                preset_compatible_systems=$(echo "$preset_compatible_systems" | cut -d= -f1 | sed ':a;N;$!ba;s/\n/, /g')
                echo "The systems that support the preset $preset are $preset_compatible_systems"
              elif [[ "$system" == "all" ]]; then
                while IFS= read -r config_line; do
                  current_system_name=$(get_setting_name "$config_line" "retrodeck")
                  current_system_value=$(get_setting_value "$rd_conf" "$current_system_name" "retrodeck" "$preset")
                  if [[ "$current_system_value" == "true" ]]; then
                    current_system_value="enabled"
                  else
                    current_system_value="disabled"
                  fi
                  echo "The preset $preset for the system $current_system_name is $current_system_value"
                done < <(printf '%s\n' "$preset_compatible_systems")
              elif [[ "$preset_compatible_systems" =~ "$system" ]]; then
                preset_state=$(get_setting_value "$rd_conf" "$system" "retrodeck" "$preset")
                if [[ "$preset_state" == "true" ]]; then
                  preset_state="enabled"
                else
                  preset_state="disabled"
                fi
                echo "The preset $preset for the system $system is $preset_state."
              else
                echo "The system $system is not compatible with the preset $preset. (use --get-help for more information)"
                exit 1
              fi
            else
              echo "Preset $preset not recognized. Use --get-help for a list of valid options."
              exit 1
            fi
            exit 0
            ;;
        --set)
            preset="$2"
            system="$3"
            value="$4"
            if [[ -z "$preset" ]]; then
              echo "Error: No preset specified. Usage: --set <preset> <system/all> <value> (use --set-help for more information)"
              exit 1
            elif [[ -z "$system" ]]; then
              echo "Error: No system specified. Usage: --set <preset> <system/all> <value> (use --set-help for more information)"
              exit 1
            elif [[ -z "$value" ]]; then
              echo "Error: No value specified. Usage: --set <preset> <system/all> <value> (use --set-help for more information)"
              exit 1
            elif [[ $(fetch_all_presets | tr ' ' ',' | sed 's/,/, /g') =~ "$preset" ]]; then
              if [[ "$preset" == "cheevos" &&  "$value" =~ (true|on) ]]; then # Get cheevos login information
                current_system_value=$(get_setting_value "$rd_conf" "$system" "retrodeck" "$preset")
                if [[ "$current_system_value" == "false" || -z "$current_system_value" ]]; then
                  read -r -p "Please enter your RetroAchievements username: " cheevos_username
                  read -r -s -p "Please enter your RetroAchievements password: " cheevos_password
                  if cheevos_info=$(get_cheevos_token "$cheevos_username" "$cheevos_password"); then
                    cheevos_token=$(echo "$cheevos_info" | jq -r '.Token')
                    cheevos_login_timestamp=$(date +%s)
                    echo "RetroAchievements login succeeded, proceeding..."
                  else # login failed
                    echo "RetroAchievements login failed, please try again."
                    exit 1
                  fi
                else
                  echo "RetroAchivements for $system are already enabled."
                  exit 1
                fi
              fi
              if [[ ! "$system" == "all" ]]; then # Check if emulator is already set as requested
                current_system_value=$(get_setting_value "$rd_conf" "$system" "retrodeck" "$preset")
                if [[ "$value" =~ (true|on) && "$current_system_value" == "true" ]]; then
                  echo "The preset $preset is already enabled for the system $system"
                elif [[ "$value" =~ (false|off) && "$current_system_value" == "false" ]]; then
                  echo "The preset $preset is already disabled for the system $system"
                else # Otherwise needs to be changed
                  if change_presets_cli "$preset" "$system" "$value"; then
                    echo "$preset preset changes for $system are complete"
                  else
                    echo "Something went wrong during the preset change, please check the logs for details."
                    exit 1
                  fi
                fi
              else
                if change_presets_cli "$preset" "$system" "$value"; then
                  echo "$preset preset changes for all compatible systems are complete"
                else
                  echo "Something went wrong during the preset change, please check the logs for details."
                  exit 1
                fi
              fi
            else
              echo "Preset $preset not recognized. Use --set-help for a list of valid options."
              exit 1
            fi
            exit 0
            ;;
        --open)
            open_component "${@:2}"
            exit 0
            ;;
        --api)
            retrodeck_api start
            wait
            exit $?
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

check_if_updated

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
