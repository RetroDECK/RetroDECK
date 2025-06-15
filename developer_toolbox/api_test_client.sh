#!/bin/bash

# Set up paths for named pipes (same as in the server)
api_path="$HOME/.var/app/net.retrodeck.retrodeck/config/retrodeck/api"
api_request_pipe="$api_path/retrodeck_api_pipe"

# Function to send a request and get a response
send_request() {
  local request="$1"
  local timeout="${2:-5}"

  # Check if pipes exist
  if [[ ! -p "$api_request_pipe" ]]; then
      echo "Error: Request pipe does not exist at $api_request_pipe" >&2
      echo "Make sure the API server is running." >&2
      return 1
  fi

  # Create a unique request ID
  local request_id="client_$(date +%s)_$$"
  local api_response_pipe="$api_path/response_${request_id}"

  # Create response pipe
  mkfifo "$api_response_pipe"
  chmod 600 "$api_response_pipe"

  # Add request_id to the JSON if it doesn't have one already
  # First, validate JSON and then add the request_id
  if ! echo "$request" | jq -e . >/dev/null 2>&1; then
      echo "Error: Invalid JSON request: $request" >&2
      return 1
  fi

  if ! echo "$request" | jq -e '.request_id' >/dev/null 2>&1; then
      # We need to properly quote the request_id for jq
      request=$(echo "$request" | jq --arg rid "$request_id" '. + {request_id: $rid}')
  else
      request_id=$(echo "$request" | jq -r '.request_id')
  fi

  # Start reading the response pipe in the background with a timeout
  # Use 'cat' instead of 'read' to capture multiline responses
  local response
  # Write to pipe first, then read from response pipe
  echo "$request" > "$api_request_pipe"
  response=$(timeout "$timeout" cat "$api_response_pipe")

  # Clean up response pipe
  rm -f "$api_response_pipe"

  # Check if we got a response
  if [[ -z "$response" ]]; then
    echo "Error: No response received within $timeout seconds" >&2
    return 1
  fi

  # Return the response
  echo "$response"
}

# Function to display help
show_help() {
  echo "Bash API Client"
  echo "Usage: $0 [options] [JSON request]"
  echo ""
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -a, --action ACTION        API action to perform"
  echo "  -d, --data DATA            Data for the request"
  echo "  -t, --timeout TIMEOUT      Manually-defined timeout for the request (in seconds)"
  echo ""
  echo "Examples:"
  echo "  $0 '{\"action\":\"process_data\",\"data\":\"test\"}'"
  echo "  $0 --action process_data --data \"test data\""
}

# If no arguments, show help
if [[ $# -eq 0 ]]; then
  show_help
  exit 0
fi

# Parse arguments
ACTION=""
TIMEOUT=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -a|--action)
      ACTION="$2"
      shift 2
      ;;
    -d|--data)
      DATA="$2"
      shift 2
      ;;
    -t|--timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    *)
      # Assume it's a JSON string if it starts with {
      if [[ "$1" == {* ]]; then
        JSON_REQUEST="$1"
      else
        echo "Unknown option: $1"
        show_help
        exit 1
      fi
      shift
      ;;
  esac
done

# If we have a JSON request, use it directly
if [[ -n "$JSON_REQUEST" ]]; then
  # Validate JSON
  if ! echo "$JSON_REQUEST" | jq . >/dev/null 2>&1; then
    echo "Error: Invalid JSON request" >&2
    exit 1
  fi

  # Send the request
  echo "sending request: $JSON_REQUEST"
  response=$(send_request "$JSON_REQUEST" "$TIMEOUT")
  exit_code=$?

  # Pretty-print the response
  if [[ $exit_code -eq 0 ]]; then
    echo "$response" | jq .
  fi

  exit $exit_code
fi

# Otherwise, build a JSON request from the arguments
if [[ -n "$ACTION" ]]; then
  # Create JSON object with proper quoting
  JSON_REQUEST=$(jq -n --arg action "$ACTION" '{action: $action}')

  # Add data if provided
  if [[ -n "$DATA" ]]; then
    JSON_REQUEST=$(echo "$JSON_REQUEST" | jq --arg data "$DATA" '. + {data: $data}')
  fi

  # Send the request
  response=$(send_request "$JSON_REQUEST" "$TIMEOUT")
  exit_code=$?

  # Pretty-print the response
  if [[ $exit_code -eq 0 ]]; then
    echo "$response" | jq .
  fi

  exit $exit_code
else
  echo "Error: No action specified and no JSON request provided" >&2
  show_help
  exit 1
fi
