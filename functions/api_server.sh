#!/bin/bash

# This is the main processing point for the RetroDECK API
# It will accept JSON objects as requests in a single FIFO request pipe ($REQUEST_PIPE)
# and return each processed response through a unique named pipe, which MUST be created by the requesting client.
# Each JSON object needs, at minimum a "action" element with a valid value and a "request_id" with a unique value.
# Each processed response will be returned on a FIFO named pipe at the location "/tmp/response_$request_id" so that actions can be processed asynchronously
# If the response pipe does not exist when the data is done processing the response will not be sent at all, so the client must ensure that the response pipe exists when the JSON object is sent to the server!
# The response ID can be any unique value, an example ID generation statement in Bash is            request_id="retrodeck_request_$(date +%s)_$$"
# The server can be started, stopped or have its running status checked by calling the script like this: retrodeck_api start
#                                                                                                        retrodeck_api stop
#                                                                                                        retrodeck_api status

retrodeck_api() {
# Handle command-line arguments
case "$1" in
    start) start_server ;;
    stop) stop_server ;;
    status) status_server ;;
    *)
      echo "Usage: $0 {start|stop|status}"
      exit 1
      ;;
esac
}

start_server() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    log d "Server is already running (PID: $(cat "$PID_FILE"))"
    return 1
  fi

  if [[ ! -p "$REQUEST_PIPE" ]]; then # Create the request pipe if it doesn't exist.
    mkfifo "$REQUEST_PIPE"
    chmod 600 "$REQUEST_PIPE"
  fi

  run_server & # Run server in background
  local SERVER_PID=$!
  echo "$SERVER_PID" > "$PID_FILE"
  log d "Server started (PID: $SERVER_PID)"
}

stop_server() {
  if [[ -f "$PID_FILE" ]]; then
    local PID
    PID=$(cat "$PID_FILE")
    if kill "$PID" 2>/dev/null; then
      log d "Stopping server (PID: $PID)..."
      rm -f "$PID_FILE" "$REQUEST_PIPE"
      return 0
    else
      log d "Server not running; cleaning up residual files"
      rm -f "$PID_FILE" "$REQUEST_PIPE"
      return 1
    fi
  else
    log d "No running server found."
    return 1
  fi
}

status_server() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    log d "Server is running (PID: $(cat "$PID_FILE"))."
  else
    log d "Server is not running."
  fi
}

run_server() {
  log d "Server is running with PID $$ (Process Group $$)..."
  log d "Request pipe: $REQUEST_PIPE"

  cleanup() {
    # Cleanup function to ensure named pipe is removed on exit
    log d "Cleaning up server resources..."
    rm -f "$PID_FILE" "$REQUEST_PIPE"
    exit 0
  }

  trap cleanup EXIT INT TERM

  local buffer="" # Buffer to accumulate lines from the request pipe, needed for multi-line JSON requests
  while true; do
    if IFS= read -r line; then # Read one line from the request pipe
      buffer+="$line"$'\n' # Append the line (plus a newline) to the buffer
      if echo "$buffer" | jq empty 2>/dev/null; then # Check if the accumulated buffer is valid JSON
        log d "Received complete request:"
        log d "$buffer"
        process_request "$buffer" & # Process the complete JSON request asynchronously
        buffer="" # Clear the buffer for the next request.
      fi
    fi
  done < "$REQUEST_PIPE"
}

process_request() {
  # This is the main API function loop. From the passed JSON object $1, it will check for values in the "action", "request_id" (which are always required fields) as well as any function-specific data.
  # The "request_id" is also used in the construction of the response named_pipe the requesting client needs to create. The response named pipe will always be /tmp/response_$request_id and will be cleaned up by the server once the response has been sent.
  # USAGE: process_request "$JSON_OBJECT"
  local json_input="$1"
  local action
  local request_id

  # Validate JSON format
  if ! echo "$json_input" | jq empty 2>/dev/null; then
    echo "Error: Invalid JSON format" >&2
    return 1
  fi

  # Extract the action and parameters from the JSON input
  action=$(echo "$json_input" | jq -r '.action // empty')
  request_id=$(echo "$json_input" | jq -r '.request_id // empty')

  if [[ -z "$action" || -z "$request_id" ]]; then
    echo "Invalid request: missing action or request_id" >&2
    return 1
  fi

  local response_pipe="/home/deck/.var/app/net.retrodeck.retrodeck/config/retrodeck/api/response_${request_id}"

  if [[ ! -p "$response_pipe" ]]; then
    echo "Error: Response pipe $response_pipe does not exist" >&2
    return 1
  fi

  if [[ -z "$action" ]]; then
    echo "{\"status\":\"error\",\"message\":\"Missing required field: action\",\"request_id\":\"$request_id\"}" > "$response_pipe"
    return 1
  fi

  # Process request asynchronously
  {
  local data
  data=$(echo "$json_input" | jq -r '.data // empty')
  if [[ -z "$data" ]]; then
    echo "{\"status\":\"error\",\"message\":\"Missing required field: data\",\"request_id\":\"$request_id\"}" > "$response_pipe"
    return 1
  fi
  case "$action" in
    "check_status")
      echo "{\"status\":\"success\",\"request_id\":\"$request_id\"}" > "$response_pipe"
      ;;
    "wait")
      local result=$(wait_example_function "$data")
      echo "{\"status\":\"success\",\"result\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
      ;;
    "get")
      case $data in
        "compressible_games")
          local compression_format=$(echo "$json_input" | jq -r '.format // empty')
          if [[ -n "$compression_format" ]]; then
            local result
            if result=$(api_find_compatible_games "$compression_format"); then
              echo "{\"status\":\"success\",\"result\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
            else
              echo "{\"status\":\"error\",\"message\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
            fi
          fi
          ;;
      esac
      ;;
    *)
      echo "{\"status\":\"error\",\"message\":\"Unknown action: $action\",\"request_id\":\"$request_id\"}" > "$response_pipe"
      ;;
  esac

  # Remove response pipe after writing response
  rm -f "$response_pipe"
  } &

}

wait_example_function() {
  # This is a dummy function used for API testing only. All it does is sleep for the amount of seconds provided in the "data" field of the received JSON object
  local input="$1"
  sleep "$1"   # Dummy implementation for demonstration
  echo "{\"waited\":\"waited $input seconds\"}"
}
