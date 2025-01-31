# Source the global.sh script if not already sourced
if [ -z "${GLOBAL_SOURCED+x}" ]; then
    source /app/libexec/global.sh
fi

# Define the IWAD files list
IWAD_FILES=("DOOM1.WAD" "DOOM.WAD" "DOOM2.WAD" "DOOM2F.WAD" "DOOM64.WAD" "TNT.WAD"
            "PLUTONIA.WAD" "HERETIC1.WAD" "HERETIC.WAD" "HEXEN.WAD" "HEXDD.WAD"
            "STRIFE0.WAD" "STRIFE1.WAD" "VOICES.WAD" "CHEX.WAD"
            "CHEX3.WAD" "HACX.WAD" "freedoom1.wad" "freedoom2.wad" "freedm.wad"
            "doom_complete.pk3"
)

# Function to check if a file is an IWAD
is_iwad() {
    local file="$1"
    local lowercase_file="$(basename "${file,,}")"
    
    # Loop through the list of IWAD files
    for iwad in "${IWAD_FILES[@]}"; do
        # Check if the lowercase version of the IWAD file matches the input file
        if [[ "${iwad,,}" == "$lowercase_file" ]]; then
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
        local lowercase_file="$(echo "$file" | tr '[:upper:]' '[:lower:]')"
        found_file=$(find "$directory" -type f -iname "$lowercase_file" | head -n 1)
    fi
    echo "$found_file"
}

# Main script
log d "RetroDECK GZDOOM wrapper init"

# Check if the filename contains a single quote
if [[ "$1" == *"'"* ]]; then
    log e "Invalid filename: \"$1\" contains a single quote.\nPlease rename the file in a proper way before continuing."
    rd_zenity --error --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK" \
        --text="<span foreground='$purple'><b>Invalid filename\n\n</b></span>\"$1\" contains a single quote.\nPlease rename the file in a proper way before continuing."
    exit 1
fi

# Check if $1 is not a .doom file
if [[ "${1##*.}" != "doom" ]]; then
    # Check if the file is in the IWAD list
    if [[ $(is_iwad "$1") == "true" ]]; then
        command="gzdoom -config /var/config/gzdoom/gzdoom.ini -iwad $1"
    else
        command="gzdoom -config /var/config/gzdoom/gzdoom.ini -file $1"
    fi

    # Log the command
    log i "Loading: \"$1\""
    log i "Executing command \"$command\""

    # Execute the command with double quotes
    eval "$command"

# Check if $1 is a .doom file
else
    doom_file="$1"
    log i "Found a doom file: \"$1\""

    # Check if the .doom file exists
    if [[ ! -e "$doom_file" ]]; then
        log e "doom file not found in \"$doom_file\""
        rd_zenity --error --no-wrap \
	    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
	    --title "RetroDECK" \
	    --text="File \"$doom_file\" not found. Quitting."
        exit 1
    fi

    # Read the .doom file and compose the command
    command="gzdoom -config /var/config/gzdoom/gzdoom.ini"

    while IFS= read -r line; do
        # Check if the line contains a single quote
        if [[ "$line" == *"'"* ]]; then
            log e "Invalid filename: A file containined in \"$1\" contains a single quote"
            rd_zenity --error --no-wrap \
                --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
                --title "RetroDECK" \
                --text="<span foreground='$purple'><b>Invalid filename\n\n</b></span>A file containined in \"$1\" contains a single quote.\nPlease rename the file and fix its name in the .doom file."
            exit 1
        fi

        # Search for the file recursively
        found_file=$(search_file_recursive "$line" "$(dirname "$doom_file")")

        # If the file is not found, exit with an error
        if [[ -z "$found_file" ]]; then
            log "[ERROR] File not found in \"$line\""
            rd_zenity --error --no-wrap \
                --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
                --title "RetroDECK" \
                --text="File \"$doom_file\" not found. Quitting."
            exit 1
        fi

        # Check if the file is an IWAD
        if [[ $(is_iwad "$found_file") == "true" ]]; then
            command+=" -iwad $found_file"
            log i "Appending the param \"-iwad $found_file\""
        else
            command+=" -file $found_file"
            log i "Appending the param \"-file $found_file\""
        fi
    done < "$doom_file"

    # Log the command
    log i "Executing command \"$command\""

    # Execute the command with double quotes
    eval "$command"
fi
