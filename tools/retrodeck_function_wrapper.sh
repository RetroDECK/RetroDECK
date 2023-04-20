#!/bin/bash

# This wrapper will run a single RetroDECK function with any number of arguments
# USAGE: /bin/bash retrodeck_function_wrapper.sh <function_name> <arg1> <arg2> ...

source /app/libexec/global.sh

# Check if a function was specified
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 function_name [args...]"
  exit 1
fi

# Get the function name and remove it from the list of arguments
function_name="$1"
shift

# Check if the function exists
if ! declare -f "$function_name" >/dev/null 2>&1; then
  echo "Function '$function_name' not found"
  exit 1
fi

# Call the function with any remaining arguments
"$function_name" "$@"
