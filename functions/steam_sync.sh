#!/bin/bash

steam_sync() {

    # This function looks for favorited games in all ES-DE gamelists and builds a manifest of any found.
    # It then compares the new manifest to the existing one (if it exists) and runs an SRM sync if there are differences
    # If all favorites were removed from ES-DE, it will remove all existing entries from Steam and then remove the favorites manifest entirely
    # If there is no existing manifest, this is a first time sync and games are synced automatically
    # USAGE: steam_sync

    log "i" "Starting Steam Sync"
    create_dir $steamsync_folder

    if [ ! -f "$srm_path" ]; then
      log "e" "Steam ROM Manager configuration not initialized! Initializing now."
      prepare_component "reset" "steam-rom-manager"
    fi

    # Prepare fresh log file
    echo > "$srm_log"

    # Prepare new favorites manifest
    echo "[]" > "${retrodeck_favorites_file}.new" # Initialize favorites JSON file
    favorites_found="false"

    # Static definitions for all JSON objects
    target="flatpak"
    launch_command="run net.retrodeck.retrodeck"
    startIn=""

    for system_path in "$rdhome/ES-DE/gamelists/"*/; do
        # Skip the CLEANUP folder
        if [[ "$system_path" == *"/CLEANUP/"* ]]; then
            continue
        fi
        system=$(basename "$system_path") # Extract the folder name as the system name
        gamelist="${system_path}gamelist.xml"
        system_favorites=$(xml sel -t -m "//game[favorite='true']" -v "path" -n "$gamelist")
        while read -r game; do
            if [[ -n "$game" ]]; then # Avoid empty lines created by xmlstarlet
                favorites_found="true"
                local game="${game#./}" # Remove leading ./
                # Construct launch options with the rom path in quotes, to handle spaces
                local launchOptions="$launch_command -s $system \"$roms_folder/$system/$game\""
                jq --arg title "${game%.*}" --arg target "$target" --arg launchOptions "$launchOptions" \
                '. += [{"title": $title, "target": $target, "launchOptions": $launchOptions}]' "${retrodeck_favorites_file}.new" > "${retrodeck_favorites_file}.tmp" \
                && mv "${retrodeck_favorites_file}.tmp" "${retrodeck_favorites_file}.new"
            fi
        done <<< "$system_favorites"
    done

    if [[ -f "$retrodeck_favorites_file" ]]; then # If an existing favorites manifest exists
        if [[ $favorites_found == "false" ]]; then # If no favorites were found in the gamelists
            log i "No favorites were found in current ES-DE gamelists, removing old entries"
            if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
                (
                # Remove old entries
                steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
                steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
                steam-rom-manager remove >> "$srm_log" 2>&1
                ) |
                rd_zenity --progress \
                --title="Syncing with Steam" \
                --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
                --text="<span foreground='$purple'><b>\t\t\t\tSyncing favorite games with Steam</b></span>\n\n<b>NOTE: </b>This operation may take some time depending on the size of your library.\nFeel free to leave this in the background and switch to another application.\n\n" \
                --pulsate --width=500 --height=150 --auto-close --no-cancel
            else
                # Remove old entries
                steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
                steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
                steam-rom-manager remove >> "$srm_log" 2>&1
            fi
            # Old manifest cleanup
            rm "$retrodeck_favorites_file"
            rm "${retrodeck_favorites_file}.new"
        else
            if cmp -s "$retrodeck_favorites_file" "${retrodeck_favorites_file}.new"; then # See if the favorites manifests are the same, meaning there were no changes
                log i "ES-DE favorites have not changed, no need to sync again"
                rm "${retrodeck_favorites_file}.new"
            else
                log d "New and old manifests are different, running sync"
                if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
                    (
                    # Remove old entries
                    steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
                    steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
                    steam-rom-manager remove >> "$srm_log" 2>&1

                    # Load new favorites manifest
                    mv "${retrodeck_favorites_file}.new" "$retrodeck_favorites_file"

                    # Add new favorites manifest
                    steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
                    steam-rom-manager add >> "$srm_log" 2>&1
                    ) |
                    rd_zenity --progress \
                    --title="Syncing with Steam" \
                    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
                    --text="<span foreground='$purple'><b>\t\t\t\tSyncing favorite games with Steam</b></span>\n\n<b>NOTE: </b>This operation may take some time depending on the size of your library.\nFeel free to leave this in the background and switch to another application.\n\n" \
                    --pulsate --width=500 --height=150 --auto-close --no-cancel
                else
                    # Remove old entries
                    steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
                    steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
                    steam-rom-manager remove >> "$srm_log" 2>&1

                    # Load new favorites manifest
                    mv "${retrodeck_favorites_file}.new" "$retrodeck_favorites_file"

                    # Add new favorites manifest
                    steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
                    steam-rom-manager add >> "$srm_log" 2>&1
                fi
            fi
        fi
    elif [[ $favorites_found == "true" ]]; then # Only sync if some favorites were found
        log d "First time building favorites manifest, running sync"
        mv "${retrodeck_favorites_file}.new" "$retrodeck_favorites_file"
        if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
            (
            # Add new favorites manifest
            steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
            steam-rom-manager add >> "$srm_log" 2>&1
            ) |
            rd_zenity --progress \
            --title="Syncing with Steam" \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --text="<span foreground='$purple'><b>\t\t\t\tSyncing favorite games with Steam</b></span>\n\n<b>NOTE: </b>This operation may take some time depending on the size of your library.\nFeel free to leave this in the background and switch to another application.\n\n" \
            --pulsate --width=500 --height=150 --auto-close --no-cancel
        else
            # Add new favorites manifest
            steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
            steam-rom-manager add >> "$srm_log" 2>&1
        fi
    fi
}
