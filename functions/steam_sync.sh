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

    # Static definitions for all JSON objects
    target="flatpak"
    launch_command="run net.retrodeck.retrodeck"
    startIn=""

    for system_path in "$rdhome/ES-DE/gamelists/"*/; do
        # Skip the CLEANUP folder
        if [[ "$system_path" == *"/CLEANUP/"* ]]; then
            continue
        fi
        # Skip folders with no gamelists
        if [[ ! -f "${system_path}gamelist.xml" ]]; then
            continue
        fi
        system=$(basename "$system_path") # Extract the folder name as the system name
        gamelist="${system_path}gamelist.xml"
        system_favorites=$(xml sel -t -m "//game[favorite='true']" -v "path" -n "$gamelist")
        while read -r game; do
            if [[ -n "$game" ]]; then # Avoid empty lines created by xmlstarlet
                local game="${game#./}" # Remove leading ./
                if [[ -f "$roms_folder/$system/$game" ]]; then # Validate file exists and isn't a stale ES-DE entry for a removed file
                    # Construct launch options with the rom path in quotes, to handle spaces
                    local launchOptions="$launch_command -s $system \"$roms_folder/$system/$game\""
                    jq --arg title "${game%.*}" --arg target "$target" --arg launchOptions "$launchOptions" \
                    '. += [{"title": $title, "target": $target, "launchOptions": $launchOptions}]' "${retrodeck_favorites_file}.new" > "${retrodeck_favorites_file}.tmp" \
                    && mv "${retrodeck_favorites_file}.tmp" "${retrodeck_favorites_file}.new"
                fi
            fi
        done <<< "$system_favorites"
    done

    if [[ -f "$retrodeck_favorites_file" && -f "${retrodeck_favorites_file}.new" ]]; then
        # Look for favorites removed between steam_sync runs, if any
        removed_items=$(jq -n \
            --slurpfile source "$retrodeck_favorites_file" \
            --slurpfile target "${retrodeck_favorites_file}.new" \
            '[$source[0][] | select(. as $item | ($target[0] | map(. == $item) | any | not))]')
    fi

    # Check if there are any missing objects
    if [[ "$(echo "$removed_items" | jq 'length')" -gt 0 ]]; then
        log d "Some favorites were removed between sync, writing to $retrodeck_removed_favorites"
        echo "$removed_items" > "$retrodeck_removed_favorites"
    fi

    # Decide if sync needs to happen
    if [[ -f "$retrodeck_favorites_file" ]]; then # If an existing favorites manifest exists
        if [[ ! "$(cat "${retrodeck_favorites_file}.new" | jq 'length')" -gt 0 ]]; then # If all favorites were removed from all gamelists, meaning new manifest is empty
            log i "No favorites were found in current ES-DE gamelists, removing old entries"
            if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
                (
                # Remove old entries
                steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
                steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
                steam-rom-manager remove >> "$srm_log" 2>&1
                ) |
                rd_zenity --progress \
                --title="Syncing with Steam" \
                --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
                --text="<span foreground='$purple'><b>\t\t\t\tRemoving unfavorited games from Steam</b></span>\n\n<b>NOTE: </b>This operation may take some time depending on the size of your library.\nFeel free to leave this in the background and switch to another application.\n\n" \
                --pulsate --width=500 --height=150 --auto-close --no-cancel
            else
                # Remove old entries
                steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
                steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
                steam-rom-manager remove >> "$srm_log" 2>&1
            fi
            # Old manifest cleanup
            rm "$retrodeck_favorites_file"
            rm "${retrodeck_favorites_file}.new"
        else # The new favorites manifest is not empty
            if cmp -s "$retrodeck_favorites_file" "${retrodeck_favorites_file}.new"; then # See if the favorites manifests are the same, meaning there were no changes
                log i "ES-DE favorites have not changed, no need to sync again"
                rm "${retrodeck_favorites_file}.new"
            else
                log d "New and old manifests are different, running sync"
                if [[ -f "$retrodeck_removed_favorites" ]]; then # If some favorites were removed between syncs
                    log d "Some favorites removed between syncs, removing unfavorited games"
                    # Load removed favorites as manifest and run SRM remove
                    mv "$retrodeck_removed_favorites" "$retrodeck_favorites_file"
                    if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
                        (
                        steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
                        steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
                        steam-rom-manager remove >> "$srm_log" 2>&1
                        ) |
                        rd_zenity --progress \
                        --title="Syncing with Steam" \
                        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
                        --text="<span foreground='$purple'><b>\t\t\t\tRemoving unfavorited games from Steam</b></span>\n\n<b>NOTE: </b>This operation may take some time depending on the size of your library.\nFeel free to leave this in the background and switch to another application.\n\n" \
                        --pulsate --width=500 --height=150 --auto-close --no-cancel
                    else
                        steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
                        steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
                        steam-rom-manager remove >> "$srm_log" 2>&1
                    fi
                fi

                # Load new favorites manifest as games to add during sync
                mv "${retrodeck_favorites_file}.new" "$retrodeck_favorites_file"

                if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
                    (
                    # Add new favorites manifest
                    steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
                    steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
                    steam-rom-manager add >> "$srm_log" 2>&1
                    ) |
                    rd_zenity --progress \
                    --title="Syncing with Steam" \
                    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
                    --text="<span foreground='$purple'><b>\t\t\t\tSyncing favorite games with Steam</b></span>\n\n<b>NOTE: </b>This operation may take some time depending on the size of your library.\nFeel free to leave this in the background and switch to another application.\n\n" \
                    --pulsate --width=500 --height=150 --auto-close --no-cancel
                else
                    steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
                    steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
                    steam-rom-manager add >> "$srm_log" 2>&1
                fi
            fi
        fi
    elif [[ "$(cat "${retrodeck_favorites_file}.new" | jq 'length')" -gt 0 ]]; then # No existing favorites manifest was found, so check if new manifest has entries
        log d "First time building favorites manifest, running sync"
        mv "${retrodeck_favorites_file}.new" "$retrodeck_favorites_file"
        if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
            (
            # Add new favorites manifest
            steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
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
            steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
            steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
            steam-rom-manager add >> "$srm_log" 2>&1
        fi
    fi
}
