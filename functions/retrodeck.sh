#!/bin/bash

# Debug override
args=()
for arg in "$@"; do
  if [[ "$arg" == "--debug" ]]; then
    export rd_logging_override="debug"
    export rd_logging_level="debug"
  else
    args+=("$arg")
  fi
done
set -- "${args[@]}"

source /app/libexec/global.sh

parse_informational_args "$@"

parse_cli_args "$@"

start_retrodeck

quit_retrodeck
