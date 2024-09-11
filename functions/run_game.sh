#!/bin/bash

run_game() {
  # Initialize variables
  emulator=""
  system=""
  manual_mode=false

  # Parse options
  while getopts ":e:s:m" opt; do  # Use `m` for manual mode flag
      case ${opt} in
          e )
              emulator=$OPTARG
              ;;
          s )
              system=$OPTARG
              ;;
          m )
              manual_mode=true
              log i "Run game: manual mode enabled"
              ;;
          \? )
              echo "Usage: $0 --run [-e emulator] [-s system] [-m manual] game"
              exit 1
              ;;
      esac
  done
  shift $((OPTIND -1))

  # Check for game argument
  if [[ -z "$1" ]]; then
      log e "Game path is required."
      log i "Usage: $0 start [-e emulator] [-s system] [-m manual] game"
      exit 1
  fi

  game=$1

  # If no system is provided, extract it from the game path
  if [[ -z "$system" ]]; then
    system=$(echo "$game" | grep -oP '(?<=roms/)[^/]+')
  fi

  log d "Game: \"$game\""
  log d "System: \"$system\""
  
  # Try finding the <altemulator> inside the specific game block
  altemulator=$(xmllint --recover --xpath "string(//game[path='$game']/altemulator)" "$rdhome/ES-DE/gamelists/$system/gamelist.xml" 2>/dev/null)

  if [[ -n "$altemulator" ]]; then
      log d "Alternate emulator found in <altemulator>: $altemulator"
      emulator_name=$(echo "$altemulator" | sed -e 's/ (Standalone)//')  # Strip " (Standalone)" from name
      emulator=$(find_emulator "$emulator_name")

      if [[ -n "$emulator" ]]; then
          log d "Using alternate emulator: $emulator"
      else
          log e "No valid path found for emulator: $altemulator"
          exit 1
      fi
  else
    # Try to fetch <alternativeEmulator> from anywhere in the document
    alternative_emulator=$(xmllint --recover --xpath 'string(//alternativeEmulator/label)' "$rdhome/ES-DE/gamelists/$system/gamelist.xml" 2>/dev/null)

    if [[ -n "$alternative_emulator" ]]; then
        log d "Alternate emulator found in <alternativeEmulator> header: $alternative_emulator"
        
        # Find the emulator name from the label in es_systems.xml
        emulator_name=$(find_emulator_name_from_label "$alternative_emulator")
        
        if [[ -n "$emulator_name" ]]; then
            # Pass the extracted emulator name to find_emulator function
            emulator=$(find_emulator "$emulator_name")
        fi
        
        if [[ -n "$emulator" ]]; then
            log d "Using alternate emulator from <alternativeEmulator>: $emulator"
        else
            log e "No valid path found for emulator: $alternative_emulator"
            exit 1
        fi
    else
        log i "No alternate emulator found in game block or header, proceeding to auto mode."
    fi
  fi

  # If an emulator is found, substitute placeholders in the command before running
  if [[ -n "$emulator" ]]; then
    # Ensure command substitution
    find_system_commands "$emulator"
    # TODO: almost there, we need just to start the emulator without Zenity: maybe we have to edit THAT function to pass the emulator to run
    log d "Final command: $command"
    eval "$command"
  else
    log e "No emulator found or selected. Exiting."
    return 1
  fi
  
  # If the emulator is not specified or manual mode is set, ask the user to select it via Zenity
  if [[ -z "$emulator" && "$manual_mode" == true ]]; then
    emulator=$(find_system_commands)
  fi

  # If emulator is still not set, fall back to the first available emulator
  if [[ -z "$emulator" ]]; then
    emulator=$(get_first_emulator)
  fi

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
        selected_command=$(zenity --list \
            --title="Select an emulator for $system_name" \
            --column="Emulator" --column="Hidden Command" "${command_list[@]}" \
            --width=800 --height=400 --print-column=2 --hide-column=2)
    fi

    echo "$selected_command"
}

# Function to substitute placeholders in the command
substitute_placeholders() {
    local cmd="$1"
    local rom_path="$game"
    local rom_dir=$(dirname "$rom_path")
    
    # Strip all file extensions from the base name
    local base_name=$(basename "$rom_path")
    base_name="${base_name%%.*}"

    local file_name=$(basename "$rom_path")
    local rom_raw="$rom_path"
    local rom_dir_raw="$rom_dir"
    local es_path=""
    local emulator_path=""

    # Manually replace %EMULATOR_*% placeholders
    while [[ "$cmd" =~ (%EMULATOR_[A-Z0-9_]+%) ]]; do
        placeholder="${BASH_REMATCH[1]}"
        emulator_path=$(replace_emulator_placeholder "$placeholder")
        cmd="${cmd//$placeholder/$emulator_path}"
    done

    # Substitute %BASENAME% and other placeholders
    cmd="${cmd//"%BASENAME%"/"'$base_name'"}"
    cmd="${cmd//"%FILENAME%"/"'$file_name'"}"
    cmd="${cmd//"%ROMRAW%"/"'$rom_raw'"}"
    cmd="${cmd//"%ROMPATH%"/"'$rom_dir'"}"
    
    # Ensure paths are quoted correctly
    cmd="${cmd//"%ROM%"/"'$rom_path'"}"
    cmd="${cmd//"%GAMEDIR%"/"'$rom_dir'"}"
    cmd="${cmd//"%GAMEDIRRAW%"/"'$rom_dir_raw'"}"
    cmd="${cmd//"%CORE_RETROARCH%"/"/var/config/retroarch/cores"}"

    log d "Command after %BASENAME% and other substitutions: $cmd"

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

# Function to get the first available emulator in the list
get_first_emulator() {
    local system_name=$system
    system_section=$(xmllint --xpath "//system[name='$system_name']" "$es_systems" 2>/dev/null)

    if [ -z "$system_section" ]; then
        log e "System not found: $system_name"
        exit 1
    fi

    # Extract the first command and use it as the selected emulator
    first_command=$(echo "$system_section" | xmllint --xpath "string(//command[1])" - 2>/dev/null)

    if [[ -n "$first_command" ]]; then
        # Substitute placeholders in the command
        first_command=$(substitute_placeholders "$first_command")
        log d "Automatically selected the first emulator: $first_command"
        echo "$first_command"
    else
        log e "No command found for the system: $system_name"
        return 1
    fi
}

find_emulator() {
  local emulator_name=$1
  local found_path=""

  # Search the es_find_rules.xml file for the emulator
  emulator_section=$(xmllint --xpath "//emulator[@name='$emulator_name']" "$es_find_rules" 2>/dev/null)
  
  if [ -z "$emulator_section" ]; then
      log e "Emulator not found: $emulator_name"
      return 1
  fi
  
  # Search systempath entries
  while IFS= read -r line; do
      command_path=$(echo "$line" | sed -n 's/.*<entry>\(.*\)<\/entry>.*/\1/p')
      if [ -x "$(command -v $command_path)" ]; then
          found_path=$command_path
          break
      fi
  done <<< "$(echo "$emulator_section" | xmllint --xpath "//rule[@type='systempath']/entry" - 2>/dev/null)"
  
  # If not found, search staticpath entries
  if [ -z "$found_path" ]; then
      while IFS= read -r line; do
          command_path=$(eval echo "$line" | sed -n 's/.*<entry>\(.*\)<\/entry>.*/\1/p')
          if [ -x "$command_path" ]; then
              found_path=$command_path
              break
          fi
      done <<< "$(echo "$emulator_section" | xmllint --xpath "//rule[@type='staticpath']/entry" - 2>/dev/null)"
  fi
  
  if [ -z "$found_path" ]; then
      log e "No valid path found for emulator: $emulator_name"
      return 1
  else
      log d "Found emulator: \"$found_path\""
      echo "$found_path"
      return 0
  fi
}

# Function to find the emulator name from the label in es_systems.xml
find_emulator_name_from_label() {
    local label="$1"
    
    # Search for the emulator matching the label in the es_systems.xml file
    extracted_emulator_name=$(xmllint --recover --xpath "string(//system[name='$system']/command[@label='$label']/text())" "$es_systems" 2>/dev/null | sed 's/%//g' | sed 's/EMULATOR_//g' | cut -d' ' -f1)

    if [[ -n "$extracted_emulator_name" ]]; then
        log d "Found emulator by label: $extracted_emulator_name"
        echo "$extracted_emulator_name"
    else
        log e "Emulator name not found for label: $label"
        return 1
    fi
}
