#!/bin/bash

declare -a cleanup_handlers=()

register_cleanup() {
  # Register a function to be called during application shutdown.
  # Functions are called in reverse order of registration (LIFO). Duplicates are ignored.
  # USAGE: register_cleanup "$function_name"

  local handler="$1"
  for existing in "${cleanup_handlers[@]}"; do
    [[ "$existing" == "$handler" ]] && return
  done
  log d "Adding EXIT cleanup handler $1"
  cleanup_handlers+=("$handler")
}

run_cleanup_handlers() {
  # Execute all registered cleanup handlers in reverse order.
  # USAGE: called automatically via EXIT trap

  log d "Running EXIT cleanup handlers"

  local i
  for (( i=${#cleanup_handlers[@]}-1; i>=0; i-- )); do
    ${cleanup_handlers[$i]} 2>/dev/null
  done
}

trap run_cleanup_handlers EXIT
