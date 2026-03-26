#!/bin/bash

show_cli_help() {
  # Display dynamically generated CLI help from component manifests.
  # Commands are sorted by priority (if set), then alphabetically. Hidden commands are excluded.
  # USAGE: show_cli_help

  echo ""
  echo "Usage:"
  echo "  flatpak run [FLATPAK-RUN-OPTION] net.retrodeck.retrodeck [ARGUMENTS]"
  echo ""
  echo "Arguments:"

  jq -r '
    [.[] | .manifest | to_entries[] | .value |
     select(.cli_commands != null) |
     .cli_commands | to_entries[] |
     select(.value.hidden != true) |
     {
       flag: .value.flag,
       description: .value.description,
       params: (.value.params // []),
       priority: (.value.priority // 50)
     }
    ]
    | sort_by([.priority, (.flag | ascii_downcase)])
    | .[]
    | "    " + .flag +
      (if (.params | length) > 0 then
        " " + (.params | join(" "))
      else "" end) +
      "\t" + .description
  ' "$component_manifest_cache_file" | column -t -s $'\t'

  echo ""
  echo "  Game Launch:"
  echo "    [<options>] <game_path>          Start a game using the default emulator or"
  echo "                                     the one defined in ES-DE for game or system"
  echo "      Options:"
  echo "        --emulator (emulator)        Run the game with the defined emulator (optional)"
  echo "        --system (system)            Force the game running with the defined system (optional)"
  echo "        --manual (manual)            Show the list of available emulators to choose from (optional)"
  echo ""
  echo "  For flatpak run specific options please run: flatpak run -h"
  echo ""
  echo "  The RetroDECK Team"
  echo "  https://retrodeck.net"
  echo ""
}

parse_cli_args() {
  # Parse command line arguments dynamically based on CLI command definitions in component manifests.
  # Matches flags, resolves handlers, passes remaining args to the handler, and exits based on return code.
  # USAGE: parse_cli_args "$@"

  # Build a lookup of all CLI flags to their handler, detecting duplicates
  local -A flag_to_handler=()
  while IFS=$'\t' read -r flags handler component; do
    [[ -z "$flags" || -z "$handler" ]] && continue
    local IFS=','
    for flag in $flags; do
      flag=$(echo "$flag" | tr -d ' ')
      if [[ -n "${flag_to_handler[$flag]+x}" ]]; then
        log w "Duplicate CLI flag '$flag' from '$component' skipped, already registered by another component"
        continue
      fi
      flag_to_handler["$flag"]="$handler"
    done
  done < <(jq -r '
    [.[] | .manifest | to_entries[] |
     .key as $component |
     .value | select(.cli_commands != null) |
     .cli_commands | to_entries[] | .value |
     [.flag, .handler, $component]
    ] | .[] | @tsv
  ' "$component_manifest_cache_file")

  while [[ $# -gt 0 ]]; do
    # Check for game launch arguments first (static)
    if [[ -f "$1" || "$1" == "--emulator" || "$1" == "--system" || "$1" == "--manual" ]]; then
      log i "Game start option detected: $1"
      run_game "$@"
      exit 0
    fi

    local handler="${flag_to_handler[$1]}"
    if [[ -n "$handler" ]]; then
      if declare -F "$handler" > /dev/null; then
        shift
        "$handler" "$@"
        local rc=$?
        if [[ $rc -eq 255 ]]; then
          return 0
        else
          exit $rc
        fi
      else
        log e "Handler function $handler not found for flag $1"
        echo "Error: Internal error - handler not found for '$1'"
        exit 1
      fi
    elif [[ "$1" == -* ]]; then
      log e "Error: Unknown option '$1'"
      echo "Error: Unrecognized option '$1'. Use -h or --help for usage information."
      exit 1
    else
      log e "Error: Command or file '$1' not recognized."
      echo "Error: Command or file '$1' not recognized. Use -h or --help for usage information."
      exit 1
    fi
  done
}
