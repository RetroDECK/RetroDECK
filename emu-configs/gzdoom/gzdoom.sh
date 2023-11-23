#!/bin/bash

input_file="$1"
params=""
LOG_FILE="$rdhome/.logs/gzdoom.log"
command="gzdoom +fluid_patchset /app/share/sounds/sf2/gzdoom.sf2 -config /var/config/gzdoom/gzdoom.ini $params >> "$LOG_FILE" 2>&1"

# Function to log messages
log() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "$timestamp - $message" >> "$LOG_FILE"
    echo "$timestamp - $message"
}

# Check if the file is .wad or .WAD
if [[ $input_file =~ \.wad$ || $input_file =~ \.WAD$ ]]; then
    log "Processing file: $input_file"
    # Execute the command and check for success
    if exec "$command"; then
        log "Command executed successfully"
    else
        log "Error executing command"
    fi

# Check if the file is .doom
elif [[ $input_file =~ \.doom$ ]]; then
    log "Processing file: $input_file"
    while IFS= read -r line; do
        params+="-file $line "
        log "Added -file $line to parameters"
    done < "$input_file"
    # Execute the command and check for success
    if exec "$command"; then
        log "Command executed successfully"
        log "Expanded command:"
        log "$command"
    else
        log "Error executing command"
        log "Expanded command:"
        log "$command"
    fi
else
    echo "Unsupported file format. Please provide a .wad, .WAD, or .doom file."
    log "Unsupported file format: $input_file"
fi