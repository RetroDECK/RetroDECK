#!/bin/bash


# Add games to Steam function
add_to_steam() {
    log "i" "Starting Steam Sync"

    steamsync_folder="$rdhome/.sync"
    steamsync_folder_tmp="$rdhome/.sync-tmp"
    create_dir $steamsync_folder
    mv $steamsync_folder $steamsync_folder_tmp
    create_dir $steamsync_folder

    local srm_path="/var/config/steam-rom-manager/userData/userConfigurations.json"
    if [ ! -f "$srm_path" ]; then
      log "e" "Steam ROM Manager configuration not initialized! Initializing now."
      prepare_component "reset" "steam-rom-manager"
    fi

    # Build the systems array from space-separated systems
    local systems_string=$(jq -r '.system | keys[]' "$features" | paste -sd' ')
    IFS=' ' read -r -a systems <<< "$systems_string" # TODO: do we need this line?

    local games=()

    for system in "${systems[@]}"; do

        local gamelist="$rdhome/ES-DE/gamelists/$system/gamelist.xml"

        if [ -f "$gamelist" ]; then

        # Extract all <game> elements that are marked as favorite="true"
        game_blocks=$(xmllint --recover --xpath '//game[favorite="true"]' "$gamelist" 2>/dev/null)
        log d "Extracted favorite game blocks:\n\n$game_blocks\n\n"

        # Split the game_blocks into an array, where each element is a full <game> block
        IFS=$'\n' read -r -d '' -a game_array <<< "$(echo "$game_blocks" | xmllint --recover --format - | sed -n '/<game>/,/<\/game>/p' | tr '\n' ' ')"

        # Iterate over each full <game> block in the array
        for game_block in "${game_array[@]}"; do
          log "d" "Processing game block:\n$game_block"

          # Extract the game's name and path from the full game block
          local name=$(echo "$game_block" | xmllint --xpath 'string(//game/name)' - 2>/dev/null)
          local path=$(echo "$game_block" | xmllint --xpath 'string(//game/path)' - 2>/dev/null | sed 's|^\./||') # removing the ./

          log "d" "Game name: $name"
          log "d" "Game path: $path"

          # Ensure the extracted name and path are valid
          if [ -n "$name" ] && [ -n "$path" ]; then
              # Check for an alternative emulator if it exists
              # local emulator=$(echo "$game_block" | xmllint --xpath 'string(//game/altemulator)' - 2>/dev/null)
              # if [ -z "$emulator" ]; then
              #     games+=("$name ${command_list_default[$system]} '$roms_folder/$system/$path'")
              # else
              #     games+=("$name ${alt_command_list[$emulator]} '$roms_folder/$system/$path'")
              # fi
              log "d" "Steam Sync: found favorite game: $name"
          else
              log "w" "Steam Sync: failed to find valid name or path for favorite game"
          fi

          # Sanitize the game name for the filename: replace special characters with underscores
          local sanitized_name=$(echo "$name" | sed -e 's/^A-Za-z0-9._-/ /g')
          local sanitized_name=$(echo "$sanitized_name" | sed -e 's/:/ -/g')
          local sanitized_name=$(echo "$sanitized_name" | sed -e 's/&/and/g')
          local sanitized_name=$(echo "$sanitized_name" | sed -e 's%/%and%g')
          local sanitized_name=$(echo "$sanitized_name" | sed -e 's/   / - /g')
          local sanitized_name=$(echo "$sanitized_name" | sed -e 's/  / /g')
          log d "File Path: $path"
          log d "Game Name: $name"

          # If the filename is too long, shorten it
          if [ ${#sanitized_name} -gt 100 ]; then
              sanitized_name=$(echo "$sanitized_name" | cut -c 1-100)
          fi

          log d "Sanitized Name: $sanitized_name"

          local launcher="$steamsync_folder/${sanitized_name}.sh"
          local launcher_tmp="$steamsync_folder_tmp/${sanitized_name}.sh"

          if [ ! -e "$launcher_tmp" ]; then

            log d "Creating desktop file: $launcher"

          # if [[ -v command_list_default[$system] ]]; then
          #   command="${command_list_default[$system]}"
          # else
          #   log e "$system is not included in the commands array."
          #   continue
          # fi

          # Populate the .sync script with the correct command
          # TODO: if there is any emulator defined in the xml we use that, else... how we can know which is the default one?
          # TODO: if steam is flatpak the command wrapping will change in .desktop
            local command="flatpak run net.retrodeck.retrodeck start '$roms_folder/$system/$path'"
          # Create the launcher file using a heredoc - if you enable .desktp this remember to edit .desktop in SRM userConfigurations.json and the above launcher variable (and vice versa)
#           cat <<EOF > "$launcher"
# [Desktop Entry]
# Version=1.0
# Name=$name
# Comment=$name via RetroDECK
# Exec=$command
# Icon=net.retrodeck.retrodeck
# Terminal=false
# Type=Application
# Categories=Game;Emulator;
# EOF
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
        done
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

  log i "Steam Sync: completed"
}

remove_from_steam() {
  log d "Creating fake game"
  cat "" > "$steamsync_folder/CUL0.sh"
  log d "Cleaning the shortcut"
  steam-rom-manager remove
  log d "Removing fake game"
  rm "$steamsync_folder/CUL0.sh"
}
