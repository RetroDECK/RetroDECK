#!/bin/bash

input_file="$1"
params=""
LOG_FILE="$rdhome/.logs/gzdoom.log"
command='gzdoom +fluid_patchset /app/share/sounds/sf2/gzdoom.sf2 $params >> "$LOG_FILE" 2>&1'

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
    exec $command
    log "Command executed with parameters: retroarch -L /app/share/libretro/cores/gzdoom_libretro.so $params"
# Check if the file is .doom
elif [[ $input_file =~ \.doom$ ]]; then
    log "Processing file: $input_file"
    while IFS= read -r line; do
        params+="-file $line "
        log "Added -file $line to parameters"
    done < "$input_file"
    exec $command
    log "Command executed with parameters: retroarch -L /app/share/libretro/cores/gzdoom_libretro.so -file $params"
else
    echo "Unsupported file format. Please provide a .wad, .WAD, or .doom file."
    log "Unsupported file format: $input_file"
fi