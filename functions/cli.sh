#!/bin/bash

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
      --compress-all <format>             \t  Compresses all supported games into a compatible format.\n\t\t\t\t\t\t  Available formats are \"$(get_all_compression_targets | jq -r 'keys | join(", ")')\" and \"all\"
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

parse_informational_args() {
  case "${1:-}" in
  -h|--help)
    LOG_SILENT=true
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
    if [[ "$version" =~ ^[0-9] ]]; then
      echo "RetroDECK v$version"
    else
      echo "RetroDECK $version"
    fi
    exit 0
    ;;
  --get-help)
    LOG_SILENT=true
    echo -e "\nUsed to check the state of all systems for a given preset.\n\nAvailable presets are:"
    jq -r '.presets | keys[]' "$rd_conf"
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
    echo -e "\nUsed to toggle or set a preset.\n\nAvailable presets are:"
    jq -r '.presets | keys[]' "$rd_conf"
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
}

parse_cli_args() {
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
            start::steam-rom-manager nuke
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
        source /app/tools/configurator.sh
        exit 0
      ;;
      --reset)
        component="${@:2}"
        if [ -z "$component" ]; then
          echo "You are about to reset one or more RetroDECK components or emulators."
          echo -e "Available options are:\nall\n$(jq -r '[.[] | .manifest | keys[]] | sort | (["retrodeck"] + [.[] | select (. != "retrodeck")]) | .[]' "$component_manifest_cache_file")"
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
            rd_logging_level="debug"  # Temporarily enable debug logging
            log d "User replied $response, testing upgrade from version $version"
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
        elif [[ $(jq -r '.presets | keys[]' "$rd_conf") =~ "$preset" ]]; then
          preset_compatible_systems=$(api_get_component "all" | jq -r --arg preset "$preset" '
            [.[] |
            .component_name as $comp |
            .compatible_presets |
            if . == "none" then empty
            else to_entries[] |
              if .value | type == "array" then
                select(.key == $preset) | $comp
              else
                .key as $core | .value | to_entries[] |
                select(.key == $preset) | $core
              end
            end
            ] | unique | .[]
          ')
          if [[ -z "$system" ]]; then # User provided a preset but no system argument
            echo "The systems that support the preset $preset are\n$preset_compatible_systems"
          elif [[ "$system" == "all" ]]; then
            while IFS= read -r system; do
              current_system_value=$(get_setting_value "$rd_conf" "$system" "retrodeck" "$preset")
              if [[ "$current_system_value" == "false" ]]; then
                current_system_value="disabled"
              else
                current_system_value="enabled"
              fi
              echo "The preset $preset for the system $current_system_name is $current_system_value"
            done <<< "$preset_compatible_systems"
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
        elif [[ $(jq -r '.presets | keys[]' "$rd_conf") =~ "$preset" ]]; then
          if [[ "$preset" == "cheevos" &&  "$value" =~ (true|on) ]]; then # Get cheevos login information
            current_system_value=$(get_setting_value "$rd_conf" "$system" "retrodeck" "$preset")
            if [[ "$current_system_value" == "false" ]]; then
              read -r -p "Please enter your RetroAchievements username: " cheevos_username
              read -r -s -p "Please enter your RetroAchievements password: " cheevos_password
              if cheevos_info=$(api_do_cheevos_login "$cheevos_username" "$cheevos_password"); then
                cheevos_token=$(echo "$cheevos_info" | jq -r '.Token')
                cheevos_login_timestamp=$(echo "$cheevos_info" | jq -r '.Timestamp')
                echo "RetroAchievements login succeeded, proceeding..."
              else # login failed
                echo "RetroAchievements login failed, please try again."
                exit 1
              fi
            elif [[ ! -n "$current_system_value" ]]; then
              echo "RetroAchivements are not compatible with $system."
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
              if api_set_preset_state "$system" "$preset" "$value"; then
                echo "$preset preset changes for $system are complete"
              else
                echo "Something went wrong during the preset change, please check the logs for details."
                exit 1
              fi
            fi
          else
            while read -r system; do
              if api_set_preset_state "$system" "$preset" "$value"; then
                echo "$preset preset changes for all compatible systems are complete"
              else
                echo "Something went wrong during the preset change, please check the logs for details."
                exit 1
              fi
            done < <(api_get_component "all" | jq -r --arg preset "$preset" '
                  [.[] |
                  .component_name as $comp |
                  .compatible_presets |
                  if . == "none" then empty
                  else to_entries[] |
                    if .value | type == "array" then
                      select(.key == $preset) | $comp
                    else
                      .key as $core | .value | to_entries[] |
                      select(.key == $preset) | $core
                    end
                  end
                  ] | unique | .[]
                ')
          fi
        else
          echo "Preset $preset not recognized. Use --set-help for a list of valid options."
          exit 1
        fi
        exit 0
      ;;
      --open)
        cli_open_component "${@:2}"
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
}

cli_open_component() {
  local command="$1"
  shift

  if [[ "$command" == "--list" ]]; then
    echo "Installed components:"
    echo "$(api_get_component "all" | jq -r --arg component "$component" '.[] | select(.component_name != "retrodeck") | .component_name')"
  else
    if [[ "$system"]]
    local component_path=$(api_get_component "$command" | jq -r '.[] | select(.component_name != "retrodeck") | .path')
    if [[ -n "$component_path" ]]; then
      log d "Launching component '$command' with args: $@"
      /bin/bash "$component_path/component_launcher.sh" "$@"
    else
      log e "No launcher could be found for the component: $command"
    fi
  fi
}

change_presets_cli() {
  # REBUILD
  # This function will allow a user to change presets either individually or all for a preset class from the CLI.
  # USAGE: change_presets_cli "$preset" "$system/all" "$on/off"

  local preset="$1"
  local system="$2"
  local value="$3"
  local section_results
  section_results=$(sed -n '/\['"$preset"'\]/, /\[/{ /\['"$preset"'\]/! { /\[/! p } }' "$rd_conf" | sed '/^$/d')
  local all_emulators_in_preset="" # A CSV string containing all emulators in a preset block
  local all_other_emulators_in_preset="" # A CSV string containing every emulator except the one provided by the user in a preset block

  log d "Changing settings for preset: $preset"

  while IFS= read -r config_line; do
    # Build a list of all emulators in the preset block
    system_name=$(get_setting_name "$config_line" "retrodeck")
    if [[ -n $all_emulators_in_preset ]]; then
      all_emulators_in_preset+=","
    fi
    all_emulators_in_preset+="$system_name" # Build a list of all emulators in case user provides "all" as the system name

    if [[ "$value" =~ (false|off) && ! "$system" == "all" ]]; then # If the user is disabling a specific emulator, check for any other already enabled and keep them enabled
      system_value=$(get_setting_value "$rd_conf" "$system_name" "retrodeck" "$preset")
      if [[ ! "$system_name" == "$system" && "$system_value" == "true" ]]; then
        log d "Other system $system_name is enabled for preset $preset, retaining setting."
        if [[ -n $all_other_emulators_in_preset ]]; then
          all_other_emulators_in_preset+=","
        fi
        all_other_emulators_in_preset+="$system_name" # Build a list of all emulators that are currently enabled that aren't the one being disabled
      fi
    fi

  done < <(printf '%s\n' "$section_results")

  if [[ "$value" =~ (true|on) ]]; then # If user is enabling one or more systems in a preset
    if [[ "$system" == "all" ]]; then
      log d "Enabling all emualtors for preset $preset"
      choice="$all_emulators_in_preset" # All emulators in the preset will be enabled
    else
      if [[ "$all_emulators_in_preset" =~ "$system" ]]; then
        log d "Enabling preset $preset for $system"
        choice="$system"
      else
        log i "Emulator $system does not support preset $preset, please check the command options and try again."
      fi
    fi
  else # If user is disabling one or more systems in a preset
    if [[ "$system" == "all" ]]; then
      choice="" # Empty string means all systems in preset should be disabled
    else
      choice="$all_other_emulators_in_preset"
    fi
  fi

  # Call make_preset_changes if the user made a selection,
  # or if an extra button was clicked (even if the resulting choice is empty, meaning all systems are to be disabled).
    log d "Calling make_preset_changes with choice: $choice"
    make_preset_changes "$preset" "$choice"
}
