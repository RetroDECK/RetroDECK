#!/bin/bash

# Function to sanitize strings for filenames
sanitize() {
    # Replace sequences of underscores with a single space
    echo "$1" | sed -e 's/_\{2,\}/ /g' -e 's/_/ /g' -e 's/:/ -/g' -e 's/&/and/g' -e 's%/%and%g' -e 's/  / /g'
}

add_to_steam() {

    log "i" "Starting Steam Sync"

    create_dir $steamsync_folder
    create_dir $steamsync_folder_tmp

    local srm_path="/var/config/steam-rom-manager/userData/userConfigurations.json"
    if [ ! -f "$srm_path" ]; then
      log "e" "Steam ROM Manager configuration not initialized! Initializing now."
      prepare_component "reset" "steam-rom-manager"
    fi

    # Iterate through all gamelist.xml files in the folder structure
    for system_path in "$rdhome/ES-DE/gamelists/"*/; do
        system=$(basename "$system_path") # Extract the folder name as the system name
        gamelist="${system_path}gamelist.xml"

        log d "Reading favorites for $system"

        # Ensure gamelist.xml exists in the current folder
        if [ -f "$gamelist" ]; then
            while IFS= read -r line; do
                # Detect the start of a <game> block
                if [[ "$line" =~ \<game\> ]]; then
                    to_be_added=false # Reset the flag for a new block
                    path=""
                    name=""
                fi

                # Check for <favorite>true</favorite>
                if [[ "$line" =~ \<favorite\>true\<\/favorite\> ]]; then
                    to_be_added=true
                fi

                # Extract the <path> and remove leading "./" if present
                if [[ "$line" =~ \<path\>(.*)\<\/path\> ]]; then
                    path="${BASH_REMATCH[1]#./}"
                fi

                # Extract and sanitize <name>
                if [[ "$line" =~ \<name\>(.*)\<\/name\> ]]; then
                    name=$(sanitize "${BASH_REMATCH[1]}")
                fi

                # Detect the end of a </game> block
                if [[ "$line" =~ \<\/game\> ]]; then
                    # If the block is meaningful (marked as favorite), generate the launcher
                    if [ "$to_be_added" = true ] && [ -n "$path" ] && [ -n "$name" ]; then
                        local launcher="$steamsync_folder/${name}.sh"
                        local launcher_tmp="$steamsync_folder_tmp/${name}.sh"

                        # Create the launcher file
                        if [ ! -e "$launcher_tmp" ]; then
                            log d "Creating launcher file: $launcher"
                            command="flatpak run net.retrodeck.retrodeck '$roms_folder/$system/$path'"
                            cat <<EOF > "$launcher"
#!/bin/bash
if [ test "\$(whereis flatpak)" = "flatpak:" ]; then
  flatpak-spawn --host $command
else
  $command
fi
EOF
                            chmod +x "$launcher"
                        else
                            log d "$launcher desktop file already exists"
                            mv "$launcher_tmp" "$launcher"
                        fi
                    fi

                    # Clean up variables for safety
                    to_be_added=false
                    path=""
                    name=""
                fi
            done < "$gamelist"
        else
            log "e" "Gamelist file not found: $gamelist"
        fi
    done

    rm -r $steamsync_folder_tmp

    if [ -z "$( ls -A $steamsync_folder )" ]; then
        log d "No games found, cleaning shortcut"
        remove_from_steam
    else
        log d "Updating game list"
        steam-rom-manager add
    fi
}

remove_from_steam() {
  log d "Creating fake game"
  cat "" > "$steamsync_folder/CUL0.sh"
  log d "Cleaning the shortcut"
  steam-rom-manager remove
  log d "Removing fake game"
  rm "$steamsync_folder/CUL0.sh"
}
