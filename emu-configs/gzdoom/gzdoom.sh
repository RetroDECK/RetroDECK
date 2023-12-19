#!/bin/bash

# Define the IWAD files list
IWAD_FILES=("DOOM1.WAD" "DOOM.WAD" "DOOM2.WAD" "DOOM2F.WAD" "DOOM64.WAD" "TNT.WAD"
            "PLUTONIA.WAD" "HERETIC1.WAD" "HERETIC.WAD" "HEXEN.WAD" "HEXDD.WAD"
            "STRIFE0.WAD" "STRIFE1.WAD" "VOICES.WAD" "CHEX.WAD"
            "CHEX3.WAD" "HACX.WAD" "freedoom1.wad" "freedoom2.wad" "freedm.wad"
            "doom_complete.pk3"
)

# Function to log messages to terminal and a log file
log() {
    local message="$1"
    echo "$(date +"[%Y-%m-%d %H:%M:%S]"): $message"
    echo "$(date +"[%Y-%m-%d %H:%M:%S]"): $message" >> "$rdhome/.logs/gzdoom.log"
}

# Function to check if a file is an IWAD
is_iwad() {
    local file="$1"
    for iwad in "${IWAD_FILES[@]}"; do
        if [[ "${iwad,,}" == "$(basename "${file,,}")" ]]; then
            echo "true"
            return
        fi
    done
    echo "false"
}

# Function to search for files recursively
search_file_recursive() {
    local file="$1"
    local directory="$2"
    local found_file=""
    
    # Check if the file exists in the current directory
    if [[ -e "$directory/$file" ]]; then
        found_file="$directory/$file"
    else
        # Search recursively
        found_file=$(find "$directory" -type f -name "$file" | head -n 1)
    fi

    echo "$found_file"
}

# Main script

# Check if $1 is not a .doom file
if [[ "${1##*.}" != "doom" ]]; then
    # Check if the file is in the IWAD list
    if [[ $(is_iwad "$1") == "true" ]]; then
        command="gzdoom -config /var/config/gzdoom/gzdoom.ini -iwad $1"
    else
        command="gzdoom -config /var/config/gzdoom/gzdoom.ini -file $1"
    fi

    # Log the command
    log "Command: $command"

    # Execute the command
    eval "$command"

# Check if $1 is a .doom file
else
    doom_file="$1"

    # Check if the .doom file exists
    if [[ ! -e "$doom_file" ]]; then
        log "Error: .doom file not found - $doom_file"
        zenity --error --no-wrap \
	    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
	    --title "RetroDECK" \
	    --text="File \"$doom_file\" not found. Quitting."
        exit 1
    fi

    # Read the .doom file and compose the command
    command="gzdoom -config /var/config/gzdoom/gzdoom.ini"

    while IFS= read -r line; do
        # Search for the file recursively
        found_file=$(search_file_recursive "$line" "$(dirname "$doom_file")")

        # If the file is not found, exit with an error
        if [[ -z "$found_file" ]]; then
            log "Error: File not found - $line"
            zenity --error --no-wrap \
	    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
	    --title "RetroDECK" \
	    --text="File \"$doom_file\" not found. Quitting."
            exit 1
        fi

        # Check if the file is an IWAD
        if [[ $(is_iwad "$found_file") == "true" ]]; then
            command+=" -iwad $found_file"
        else
            command+=" -file $found_file"
        fi
    done < "$doom_file"

    # Log the command
    log "Command: $command"

    # Execute the command
    eval "$command"
fi
