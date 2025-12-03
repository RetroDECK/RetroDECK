#!/bin/bash

run_game() {
    # Initialize variables
    emulator=""
    system=""
    manual_mode=false

    usage="Usage: flatpak run net.retrodeck.retrodeck [-e emulator] [-s system] [-m] game"

    # Parse options for system, emulator, and manual mode
    while getopts ":e:s:m" opt; do
        case ${opt} in
            e)
                emulator=$OPTARG  # Emulator provided via -e
                ;;
            s)
                system=$OPTARG  # System provided via -s
                ;;
            m)
                manual_mode=true  # Manual mode enabled via -m
                log i "Run game: manual mode enabled"
                ;;
            \?)
                echo "$usage"
                exit 1
                ;;
        esac
    done
    shift $((OPTIND - 1))

    # Check for game argument
    if [[ -z "$1" ]]; then
        log e "Game path is required."
        log i "$usage"
        exit 1
    fi

    game="$(realpath "$1")"

    # Check if the game is a .desktop file
    if [[ "$game" == *.desktop ]]; then
        # Extract the Exec command from the .desktop file
        exec_cmd=$(grep '^Exec=' "$game" | sed 's/^Exec=//')
        # Workaround for RPCS3 games, replace placeholder with actual game ID
        exec_cmd=$(echo "$exec_cmd" | sed 's/%%RPCS3_GAMEID%%/%RPCS3_GAMEID%/g')
        if [[ -n "$exec_cmd" ]]; then
            log i "-------------------------------------------"
            log i " RetroDECK is now booting the game"
            log i " Game path: \"$game\""
            log i " Recognized system: desktop file"
            log i " Command line: $exec_cmd"
            log i "-------------------------------------------"
            # Execute the command from the .desktop file
            eval "$exec_cmd"
            exit 1
        else
            log e "No Exec command found in .desktop file."
            exit 1
        fi
    fi

    if [[ -d "$game" ]]; then
        log d "$(basename "$game") is a directory, parsing it like a \"directory as a file\""
        game="$game/$(basename "$game")"
        log d "Actual file is in \"$game\""
    fi 

    game_basename="./$(basename "$game")"

    # Check if realpath succeeded
    if [[ -z "$game" || ! -e "$game" ]]; then
        rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK 🟢"  \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK - 🛑 Warning! 🛑 - File not found!" \
            --text="🛑 Warning! 🛑 File: <span foreground='$purple'><b>\"$game\"</b></span> not found.\n\nMake sure RetroDECKs Flatpak has permission to access the specified path.\n\nf needed, add the path in Flatseal or terminal and try again."
        log e "File \"$game\" not found.\n\nPlease make sure that RetroDECK's Flatpak is correctly configured to reach the given path and try again."
        exit 1
    fi

    # Step 1: System Recognition
    if [[ -z "$system" ]]; then
        # Automatically detect system from game path
        system=$(echo "$game" | grep -oP '(?<=roms/)[^/]+')
        if [[ -z "$system" ]]; then
            log i "Failed to detect system from game path, asking user action"
            system=$(find_system_by_extension "$game_basename")
        fi
    fi

    # Step 2: Emulator Definition
    if [[ -n "$emulator" ]]; then
        log d "Emulator provided via command-line: $emulator"
    elif [[ "$manual_mode" = true ]]; then
        log d "Manual mode: showing Zenity emulator selection"
        emulator=$(find_system_commands "$system")
        if [[ -z "$emulator" ]]; then
            log e "No emulator selected in manual mode."
            exit 1
        fi
    else
        log d "Automatically searching for an emulator for system: $system"

        # Check for <altemulator> in the game block in gamelist.xml
        altemulator=$(awk -v path="$game_basename" '
                      /<game>/,/<\/game>/ {
                          if ($0 ~ "<path>" path "<\/path>") found = 1
                          if (found && $0 ~ /<altemulator>/) {
                          gsub(/.*<altemulator>|<\/altemulator>.*/,"")
                          print
                          exit
                          }
                          if (found && $0 ~ /<\/game>/) exit
                      }
                      ' "$rd_home_path/ES-DE/gamelists/$system/gamelist.xml" 2>/dev/null)

        if [[ -n "$altemulator" ]]; then

            log d "Found <altemulator> for game: $altemulator"
            emulator=$(xmllint --recover --xpath "string(//system[name=\"$system\"]/command[@label=\"$altemulator\"])" "$es_systems" 2>/dev/null)
            
        else # if no altemulator is found we search if a global one is set

            log d "No altemulator found in the game entry, searching for alternativeEmulator to check if a global emulator is set for the system $system"
            alternative_emulator=$(awk '
                                   /<alternativeEmulator>/,/<\/alternativeEmulator>/ {
                                       if ($0 ~ /<label>/) {
                                       gsub(/.*<label>|<\/label>.*/,"")
                                       print
                                       exit
                                       }
                                   }
                                   ' "$rd_home_path/ES-DE/gamelists/$system/gamelist.xml" 2>/dev/null)
            log d "Alternate emulator found in <alternativeEmulator> header: $alternative_emulator"
            emulator=$(xmllint --recover --xpath "string(//system[name='$system']/command[@label=\"$alternative_emulator\"])" "$es_systems" 2>/dev/null)

        fi

        # Fallback to first available emulator in es_systems.xml if no <altemulator> found
        if [[ -z "$emulator" ]]; then
            log d "No alternate emulator found, using first available emulator in es_systems.xml"
            emulator=$(xmllint --recover --xpath "string(//system[name='$system']/command[1])" "$es_systems")
        fi

        if [[ -z "$emulator" ]]; then
            log e "No valid emulator found for system: $system"
            exit 1
        fi
    fi

    # Step 3: Construct and Run the Command
    log i "-------------------------------------------"
    log i " RetroDECK is now booting the game"
    log i " Game path: \"$game\""
    log i " Recognized system: $system"
    log i " Command line: $emulator"
    log i "-------------------------------------------"

    # Now pass the final constructed command to substitute_placeholders function
    final_command=$(substitute_placeholders "$emulator")

    # Log and execute the command
    log i "Launching game with command: $final_command"
    eval "$final_command"
}

# Function to extract commands from es_systems.xml and present them in Zenity
find_system_commands() {
    local system_name=$system
    # Use xmllint to extract the system commands from the XML
    system_section=$(xmllint --xpath "//system[name='$system_name']" "$es_systems" 2>/dev/null)
    
    if [ -z "$system_section" ]; then
        log e "System not found: $system_name"
        exit 1
    fi

    # Extract commands and labels
    commands=$(echo "$system_section" | xmllint --xpath "//command" - 2>/dev/null)

    # Prepare Zenity command list
    command_list=()
    while IFS= read -r line; do
        label=$(echo "$line" | sed -n 's/.*label="\([^"]*\)".*/\1/p')
        command=$(echo "$line" | sed -n 's/.*<command[^>]*>\(.*\)<\/command>.*/\1/p')
        
        # Substitute placeholders in the command
        command=$(substitute_placeholders "$command")
        
        # Add label and command to Zenity list (label first, command second)
        command_list+=("$label" "$command")
    done <<< "$commands"

    # Check if there's only one command
    if [ ${#command_list[@]} -eq 2 ]; then
        log d "Only one command found for $system_name, running it directly: ${command_list[1]}"
        selected_command="${command_list[1]}"
    else
        # Show the list with Zenity and return the **command** (second column) selected
        selected_command=$(rd_zenity --list \
            --title="Select an component for $system_name" \
            --column="Emulator" --column="Hidden Command" "${command_list[@]}" \
            --width=800 --height=400 --print-column=2 --hide-column=2)
    fi

    echo "$selected_command"
}

substitute_placeholders() {
    local cmd="$1"
    log d "Substitute placeholder: working on $cmd"

    game=$(echo "$game" | sed "s/'/'\\\\''/g") # escaping internal '
    # Use the absolute path for %ROM%
    local rom_path="$game"
    log d "rom_path is: \"$game\""
    local rom_dir=$(dirname "$rom_path")
    local base_name=$(basename "$rom_path")
    base_name="${base_name%%.*}"
    local file_name=$(basename "$rom_path")
    local rom_raw="$rom_path"
    local rom_dir_raw="$rom_dir"
    local es_path=""
    local emulator_path=""
    local start_dir=""

    # Substitute placeholders with the absolute path and other variables
    cmd="${cmd//"%ROM%"/"'$rom_path'"}"
    cmd="${cmd//"%ROMPATH%"/"'$rom_dir'"}"

    # Manually replace %EMULATOR_*% placeholders
    while [[ "$cmd" =~ (%EMULATOR_[A-Z0-9_]+%) ]]; do
        placeholder="${BASH_REMATCH[1]}"
        emulator_path=$(replace_emulator_placeholder "$placeholder")
        cmd="${cmd//$placeholder/$emulator_path}"
    done

    # Process %STARTDIR%
    local start_dir_pos=$(echo "$cmd" | grep -b -o "%STARTDIR%" | cut -d: -f1)
    if [[ -n "$start_dir_pos" ]]; then
        # Validate and extract %STARTDIR% value
        if [[ "${cmd:start_dir_pos+10:1}" != "=" ]]; then
            log e "Error: Invalid %STARTDIR% entry in command"
            return 1
        fi

        if [[ "${cmd:start_dir_pos+11:1}" == "\"" ]]; then
            # Quoted path
            local closing_quotation=$(echo "${cmd:start_dir_pos+12}" | grep -bo '"' | head -n 1 | cut -d: -f1)
            if [[ -z "$closing_quotation" ]]; then
                log e "Error: Invalid %STARTDIR% entry (missing closing quotation)"
                return 1
            fi
            start_dir="${cmd:start_dir_pos+12:closing_quotation}"
            cmd="${cmd:0:start_dir_pos}${cmd:start_dir_pos+12+closing_quotation+1}"
        else
            # Non-quoted path
            local space_pos=$(echo "${cmd:start_dir_pos+11}" | grep -bo ' ' | head -n 1 | cut -d: -f1)
            if [[ -n "$space_pos" ]]; then
                start_dir="${cmd:start_dir_pos+11:space_pos}"
                cmd="${cmd:0:start_dir_pos}${cmd:start_dir_pos+11+space_pos+1}"
            else
                start_dir="${cmd:start_dir_pos+11}"
                cmd="${cmd:0:start_dir_pos}"
            fi
        fi

        # Expand paths in %STARTDIR%
        start_dir=$(eval echo "$start_dir") # Expand ~ or environment variables
        start_dir="${start_dir//%EMUDIR%/$(dirname "$emulator_path")}"
        start_dir="${start_dir//%GAMEDIR%/$(dirname "$rom_path")}"
        start_dir="${start_dir//%GAMEENTRYDIR%/$rom_path}"

        # Create directory if it doesn't exist
        if [[ ! -d "$start_dir" ]]; then
            mkdir -p "$start_dir" || {
                log e "Error: Directory \"$start_dir\" could not be created. Permission problems?"
                return 1
            }
        fi

        # Normalize the path
        start_dir=$(realpath "$start_dir")
        log d "Setting start directory to: $start_dir"
    fi

    # Substitute %BASENAME% and other placeholders
    cmd="${cmd//"%BASENAME%"/"'$base_name'"}"
    cmd="${cmd//"%FILENAME%"/"'$file_name'"}"
    cmd="${cmd//"%ROMRAW%"/"'$rom_raw'"}"
    cmd="${cmd//"%ROMPATH%"/"'$rom_dir'"}"
    cmd="${cmd//"%ENABLESHORTCUTS%"/""}"
    cmd="${cmd//"%EMULATOR_OS-SHELL%"/"/bin/sh"}"
    
    # Ensure paths are quoted correctly
    cmd="${cmd//"%ROM%"/"'$rom_path'"}"
    cmd="${cmd//"%GAMEDIR%"/"'$rom_dir'"}"
    cmd="${cmd//"%GAMEDIRRAW%"/"'$rom_dir_raw'"}"
    cmd="${cmd//"%CORE_RETROARCH%"/"$ra_cores_path"}"

    # Log the result
    log d "Command after placeholders substitutions: $cmd"

    # Now handle %INJECT% after %BASENAME% has been substituted
    cmd=$(handle_inject_placeholder "$cmd")

    echo "$cmd"
}

# Function to replace %EMULATOR_SOMETHING% with the actual path of the emulator
replace_emulator_placeholder() {
    local placeholder=$1
    # Extract emulator name from placeholder without changing case
    local emulator_name="${placeholder//"%EMULATOR_"/}"  # Extract emulator name after %EMULATOR_
    emulator_name="${emulator_name//"%"/}"  # Remove the trailing %

    # Use the find_emulator function to get the emulator path using the correct casing
    local emulator_exec=$(find_emulator "$emulator_name")
    
    if [[ -z "$emulator_exec" ]]; then
        log e "Emulator '$emulator_name' not found."
        exit 1
    fi
    echo "$emulator_exec"
}

# Function to handle the %INJECT% placeholder
handle_inject_placeholder() {
    local cmd="$1"
    local rom_dir=$(dirname "$game") # Get the ROM directory based on the game path

    # Find and process all occurrences of %INJECT%='something'.extension
    while [[ "$cmd" =~ (%INJECT%=\'([^\']+)\')(.[^ ]+)? ]]; do
        inject_file="${BASH_REMATCH[2]}"  # Extract the quoted file name
        extension="${BASH_REMATCH[3]}"    # Extract the extension (if any)
        inject_file_full_path="$rom_dir/$inject_file$extension"  # Form the full path

        log d "Found inject part: %INJECT%='$inject_file'$extension"

        # Check if the file exists
        if [[ -f "$inject_file_full_path" ]]; then
            # Read the content of the file and replace newlines with spaces
            inject_content=$(cat "$inject_file_full_path" | tr '\n' ' ')
            log i "File \"$inject_file_full_path\" found. Replacing %INJECT% with content."

            # Escape special characters in the inject part for the replacement
            escaped_inject_part=$(printf '%s' "%INJECT%='$inject_file'$extension" | sed 's/[]\/$*.^[]/\\&/g')

            # Replace the entire %INJECT%=...'something'.extension part with the file content
            cmd=$(echo "$cmd" | sed "s|$escaped_inject_part|$inject_content|g")

            log d "Replaced cmd: $cmd"
        else
            log e "File \"$inject_file_full_path\" not found. Removing %INJECT% placeholder."

            # Use sed to remove the entire %INJECT%=...'something'.extension
            escaped_inject_part=$(printf '%s' "%INJECT%='$inject_file'$extension" | sed 's/[]\/$*.^[]/\\&/g')
            cmd=$(echo "$cmd" | sed "s|$escaped_inject_part||g")

            log d "sedded cmd: $cmd"
        fi
    done

    log d "Returning the command with injected content: $cmd"
    echo "$cmd"
}

# Find the emulator path from the es_find_rules.xml file
find_emulator() {
    local emulator_name="$1"
    found_path=""

    # Search the es_find_rules.xml file for the emulator
    emulator_section=$(xmllint --xpath "//emulator[@name='$emulator_name']" "$es_find_rules" 2>/dev/null)

    if [ -z "$emulator_section" ]; then
        log e "Find emulator: emulator not found: $emulator_name"
        return 1
    fi

    # Search systempath entries
    while IFS= read -r line; do
        command_path=$(echo "$line" | sed -n 's/.*<entry>\(.*\)<\/entry>.*/\1/p')
        # Check if the command specified by the variable 'command_path' exists and is executable
        if [ -x "$(command -v "$command_path")" ]; then
            found_path="$command_path"
            break
        fi
    done <<< "$(echo "$emulator_section" | xmllint --xpath "//rule[@type='systempath']/entry" - 2>/dev/null)"

    # If not found, search staticpath entries
    if [ -z "$found_path" ]; then
        while IFS= read -r line; do
            command_path=$(echo "$line" | sed -n 's/.*<entry>\(.*\)<\/entry>.*/\1/p')
            if [ -x "$command_path" ]; then
                found_path="$command_path"
                break
            fi
        done <<< "$(echo "$emulator_section" | xmllint --xpath "//rule[@type='staticpath']/entry" - 2>/dev/null)"
    fi

    if [ -z "$found_path" ]; then
        log e "Find emulator: no valid path found for emulator: $emulator_name"
        return 1
    else
        log d "Find emulator: found emulator \"$found_path\""
        echo "$found_path"
        return 0
    fi
}

# Function to find systems by file extension and let user choose
find_system_by_extension() {
    local file_path="$1"
    local file_extension="${file_path##*.}"
    local file_extension_lower=$(echo "$file_extension" | tr '[:upper:]' '[:lower:]')

    # Use xmllint to directly extract the systems supporting the extension
    local matching_systems=$(xmllint --xpath "//system[extension[contains(., '.$file_extension_lower')]]/fullname/text()" "$es_systems")

    # If no matching systems found, exit with an error
    if [[ -z "$matching_systems" ]]; then
        log e "No systems found supporting .${file_extension_lower} extension"
        exit 1
    fi

    # Ensure each matching system is on its own line for Zenity
    local formatted_systems=$(echo "$matching_systems" | tr '|' '\n')

    # Use Zenity to create a selection dialog
    local chosen_system=$(zenity --list --title="Select System" --column="Available Systems" --text="Multiple systems support .${file_extension_lower} extension. Please choose:" --width=500 --height=400 <<< "$formatted_systems")

    # If no system was chosen, exit
    if [[ -z "$chosen_system" ]]; then
        log e "No system selected"
        exit 1
    fi

    # Find the <name> corresponding to the chosen <fullname>
    local detected_system=$(xmllint --xpath "string(//system[fullname='$chosen_system']/name)" "$es_systems")

    # Return the detected system
    echo "$detected_system"
}
