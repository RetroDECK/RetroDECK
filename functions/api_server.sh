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
  local api_version

  # Validate JSON format
  if ! echo "$json_input" | jq empty 2>/dev/null; then
    echo "Error: Invalid JSON format" >&2
    return 1
  fi

  # Extract the action and parameters from the JSON input
  action=$(jq -r '.action // empty' <<< "$json_input")
  request_id=$(jq -r '.request_id // empty' <<< "$json_input")
  api_version=$(jq -r '.version // empty' <<< "$json_input")

  if [[ -z "$request_id" ]]; then
    echo "Invalid request, missing request_id" >&2
    return 1
  fi

  local response_pipe="$rd_api_dir/response_${request_id}"

  if [[ ! -p "$response_pipe" ]]; then
    echo "Error: Response pipe $response_pipe does not exist" >&2
    return 1
  fi

  if [[ -z "$action" ]]; then
    echo "{\"status\":\"error\",\"message\":\"Missing required field: action\",\"request_id\":\"$request_id\"}" > "$response_pipe"
    return 1
  fi

  if [[ -z "$api_version" ]]; then
    echo "{\"status\":\"error\",\"message\":\"Missing required field: api_version\",\"request_id\":\"$request_id\"}" > "$response_pipe"
    return 1
  fi

  # Process request asynchronously
  {
  local request
  local request_data

  request=$(jq -r '.request' <<< "$json_input")
  request_data=$(jq -r '.data // empty' <<< "$json_input")

  case "$action" in

    "check_status" )
      echo "{\"status\":\"success\",\"request_id\":\"$request_id\"}" > "$response_pipe"
      ;;

    "get" )
      case $request in

        "compressible_games" )
          if [[ -z "$request_data" ]]; then
            echo "{\"status\":\"error\",\"message\":\"Missing required field: data\",\"request_id\":\"$request_id\"}" > "$response_pipe"
            return 1
          fi

          local compression_format=$(jq -r '.format // empty' <<< "$request_data")
          if [[ -n "$compression_format" ]]; then
            local result
            if result=$(api_get_compressible_games "$compression_format"); then
              echo "{\"status\":\"success\",\"result\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
            else
              echo "{\"status\":\"error\",\"message\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
            fi
          else
            echo "{\"status\":\"error\",\"message\":\"missing request value: format\",\"request_id\":\"$request_id\"}" > "$response_pipe"
          fi
          ;;

        "all_components" )
          local result
          if result=$(api_get_all_components); then
            echo "{\"status\":\"success\",\"result\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
          else
            echo "{\"status\":\"error\",\"message\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
          fi
        ;;

        "all_retrodeck_settings" )
          local result
          result=$(cat "$rd_conf" | jq .)
          if [[ -n "$result" ]]; then
            echo "{\"status\":\"success\",\"result\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
          else
            echo "{\"status\":\"error\",\"message\":\"retrodeck settings could not be read\",\"request_id\":\"$request_id\"}" > "$response_pipe"
          fi
        ;;

        "setting_value" )
          if [[ -z "$request_data" ]]; then
            echo "{\"status\":\"error\",\"message\":\"Missing required field: data\",\"request_id\":\"$request_id\"}" > "$response_pipe"
            return 1
          fi

          local setting_file=$(jq -r '.setting_file // empty' <<< "$request_data")
          local setting_name=$(jq -r '.setting_name // empty' <<< "$request_data")
          local system_name=$(jq -r '.system_name // empty' <<< "$request_data")
          local section_name=$(jq -r '.section_name // empty' <<< "$request_data")

          if [[ -n "$setting_file" && -n "$setting_name" && -n "$system_name" ]]; then
            local result
            result=$(echo "{\"setting_name\":\"$setting_name\",\"setting_value\":\"$(get_setting_value "$setting_file" "$setting_name" "$system_name" "$section_name")\"}" | jq .)
            echo "{\"status\":\"success\",\"result\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
          else
            echo "{\"status\":\"error\",\"message\":\"missing one or more request values\",\"request_id\":\"$request_id\"}" > "$response_pipe"
          fi
        ;;

        "current_preset_settings" )
          if [[ -z "$request_data" ]]; then
            echo "{\"status\":\"error\",\"message\":\"Missing required field: data\",\"request_id\":\"$request_id\"}" > "$response_pipe"
            return 1
          fi

          local preset=$(jq -r '.preset // empty' <<< "$request_data")
          local component=$(jq -r '.component // empty' <<< "$request_data")

          if [[ -n "$preset" ]]; then
            local result
            if result=$(api_get_current_preset_settings "$preset" "$component"); then
              echo "{\"status\":\"success\",\"result\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
            else
              echo "{\"status\":\"error\",\"message\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
            fi
          else
            echo "{\"status\":\"error\",\"message\":\"missing request value: preset\",\"request_id\":\"$request_id\"}" > "$response_pipe"
          fi
        ;;

        "bios_file_status" )
          if result=$(api_get_bios_file_status); then
            echo "{\"status\":\"success\",\"result\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
          else
            echo "{\"status\":\"error\",\"message\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
          fi
        ;;

        "check_multifile_structure" )
          local result

          if result="$(api_get_multifile_game_structure)"; then
            echo "{\"status\":\"success\",\"result\":\"$result\",\"request_id\":\"$request_id\"}" > "$response_pipe"
          else
            echo "{\"status\":\"error\",\"result\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
          fi
        ;;

        * )
        echo "{\"status\":\"error\",\"message\":\"Unknown request: $request\",\"request_id\":\"$request_id\"}" > "$response_pipe"
        ;;
      esac
      ;;

    "set" )
      if [[ -z "$request_data" ]]; then
        echo "{\"status\":\"error\",\"message\":\"Missing required field: data\",\"request_id\":\"$request_id\"}" > "$response_pipe"
        return 1
      fi

      case $request in

        "preset_state" )
          local component=$(jq -r '.component // empty' <<< "$request_data")
          local preset=$(jq -r '.preset // empty' <<< "$request_data")
          local state=$(jq -r '.state // empty' <<< "$request_data")
          cheevos_username=$(jq -r '.cheevos_username // empty' <<< "$request_data")
          cheevos_token=$(jq -r '.cheevos_token // empty' <<< "$request_data")

          if [[ -n "$component" && -n "$preset" && -n "$state" ]]; then
            local result
            if result=$(api_set_preset_state "$component" "$preset" "$state"); then
              echo "{\"status\":\"success\",\"result\":\"$result\",\"request_id\":\"$request_id\"}" > "$response_pipe"
            else
              echo "{\"status\":\"error\",\"result\":\"$result\",\"request_id\":\"$request_id\"}" > "$response_pipe"
            fi
          else
            echo "{\"status\":\"error\",\"message\":\"missing one or more required request values\",\"request_id\":\"$request_id\"}" > "$response_pipe"
          fi
        ;;

        "setting_value" )
          local setting_file=$(jq -r '.setting_file // empty' <<< "$request_data")
          local setting_name=$(jq -r '.setting_name // empty' <<< "$request_data")
          local setting_value=$(jq -r '.setting_value //empty' <<< "$request_data")
          local system_name=$(jq -r '.system_name // empty' <<< "$request_data")
          local section_name=$(jq -r '.section_name // empty' <<< "$request_data")
          local status

          if [[ -n "$setting_file" && -n "$setting_name" && -n "$setting_value" && -n "$system_name" ]]; then
            local result
            set_setting_value "$setting_file" "$setting_name" "$setting_value" "$system_name" "$section_name"
            if [[ $(get_setting_value "$setting_file" "$setting_name" "$system_name" "$section_name") == "$setting_value" ]]; then # Make sure the setting actually changed
              status="success"
              result=$(echo "{\"setting_name\":\"$setting_name\",\"setting_value\":\"$setting_value\"}" | jq .)
            else
              status="error"
              result=$(echo "{\"response\":\"Setting value on $setting_name was not able to be changed.\"}" | jq .)
            fi
            echo "{\"status\":\"$status\",\"result\":$result,\"request_id\":\"$request_id\"}" > "$response_pipe"
          else
            echo "{\"status\":\"error\",\"message\":\"missing one or more request values\",\"request_id\":\"$request_id\"}" > "$response_pipe"
          fi
        ;;

        * )
        echo "{\"status\":\"error\",\"message\":\"Unknown request: $request\",\"request_id\":\"$request_id\"}" > "$response_pipe"
        ;;
      esac
    ;;

    "do" )
      if [[ -z "$request_data" ]]; then
        echo "{\"status\":\"error\",\"message\":\"Missing required field: data\",\"request_id\":\"$request_id\"}" > "$response_pipe"
        return 1
      fi
      
      case "$request" in

        "compress_games" )
          local post_compression_cleanup

          post_compression_cleanup=$(jq -r '.post_compression_cleanup // empty' <<< "$json_input")

          if [[ -n "$post_compression_cleanup" ]]; then
            while read -r game; do
              while (( $(jobs -p | wc -l) >= $max_threads )); do
              sleep 0.1
              done
              (
              local system
              local compression_format

              system=$(echo "$game" | grep -oE "$roms_folder/[^/]+" | grep -oE "[^/]+$")
              compression_format=$(jq -r --arg game_path "$game" '.[] | select(.game == $game_path) | .format' <<< "$request_data")

              log i "Compressing $(basename "$game") into $compression_format format"
              compress_game "$compression_format" "$game" "$post_compression_cleanup" "$system"
              ) &
            done <<< "$(jq -r '.[].game' <<< "$request_data")"
            wait # wait for background tasks to finish

            echo "{\"status\":\"success\",\"result\":\"The compression process is complete\",\"request_id\":\"$request_id\"}" > "$response_pipe"
          else
            echo "{\"status\":\"error\",\"message\":\"missing request value: post_compression_cleanup\",\"request_id\":\"$request_id\"}" > "$response_pipe"
          fi
        ;;

        "reset_component" )
          local component_name

          component_name=$(jq -r '.component_name // empty' <<< "$request_data")

          if [[ -n "$component_name" ]]; then
            if prepare_component "reset" "$component_name"; then
              echo "{\"status\":\"success\",\"result\":\"reset of component $component_name is complete\",\"request_id\":\"$request_id\"}" > "$response_pipe"
            else
              echo "{\"status\":\"error\",\"result\":\"reset of component $component_name could not be completed\",\"request_id\":\"$request_id\"}" > "$response_pipe"
            fi
          else
            echo "{\"status\":\"error\",\"message\":\"missing request value: component_name\",\"request_id\":\"$request_id\"}" > "$response_pipe"
          fi
        ;;

        "install" )
          local package_name
          local result

          package_name=$(jq -r '.package_name // empty' <<< "$request_data")

          if [[ -n "$package_name" ]]; then
            if result="$(api_do_install_retrodeck_package $package_name)"; then
              echo "{\"status\":\"success\",\"result\":\"$result\",\"request_id\":\"$request_id\"}" > "$response_pipe"
            else
              echo "{\"status\":\"error\",\"result\":\"$result\",\"request_id\":\"$request_id\"}" > "$response_pipe"
            fi
          else
            echo "{\"status\":\"error\",\"message\":\"missing request value: package_name\",\"request_id\":\"$request_id\"}" > "$response_pipe"
          fi
        ;;

        * )
        echo "{\"status\":\"error\",\"message\":\"Unknown request: $request\",\"request_id\":\"$request_id\"}" > "$response_pipe"
        ;;
      esac
    ;;

    * )
      echo "{\"status\":\"error\",\"message\":\"Unknown action: $action\",\"request_id\":\"$request_id\"}" > "$response_pipe"
    ;;
  esac

  # Remove response pipe after writing response
  rm -f "$response_pipe"
  } &
}
