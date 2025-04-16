#!/bin/bash

steam_sync() {

  # This function looks for favorited games in all ES-DE gamelists and builds a manifest of any found.
  # It then compares the new manifest to the existing one (if it exists) and runs an SRM sync if there are differences
  # If all favorites were removed from ES-DE, it will remove all existing entries from Steam and then remove the favorites manifest entirely
  # If there is no existing manifest, this is a first time sync and games are synced automatically
  # USAGE: steam_sync

  log "i" "Starting Steam Sync"
  create_dir "$steamsync_folder"

  if [[ ! -d "$srm_userdata" ]]; then
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
    log d "Checking system $system for favorites..."
    gamelist="${system_path}gamelist.xml"
    # Use AWK instead of xmlstarlet because ES-DE can create invalid XML structures in some cases
    system_favorites=$(awk 'BEGIN { RS="</game>"; FS="\n" }
                            /<favorite>true<\/favorite>/ {
                              if (match($0, /<path>([^<]+)<\/path>/, arr))
                                print arr[1]
     }' "$gamelist")
    log d "Favorites found:"
    log d "$system_favorites"
    while read -r game_path; do
      local game="${game_path#./}" # Remove leading ./
      if [[ -f "$roms_folder/$system/$game" ]]; then # Validate file exists and isn't a stale ES-DE entry for a removed file
        # Construct launch options with the rom path in quotes, to handle spaces
        local game_title=$(awk -v search_path="$game_path" 'BEGIN { RS="</game>"; FS="\n" }
                                                            /<path>/ {
                                                            if (match($0, /<path>([^<]+)<\/path>/, path) && path[1] == search_path) {
                                                              if (match($0, /<name>([^<]+)<\/name>/, name))
                                                                print name[1]
                                                              }
                                                            }' "$gamelist")
        local launchOptions="$launch_command -s $system \"$roms_folder/$system/$game\""
        log d "Adding entry $launchOptions to favorites manifest."
        jq --arg title "$game_title" --arg target "$target" --arg launchOptions "$launchOptions" \
        '. += [{"title": $title, "target": $target, "launchOptions": $launchOptions}]' "${retrodeck_favorites_file}.new" > "${retrodeck_favorites_file}.tmp" \
        && mv "${retrodeck_favorites_file}.tmp" "${retrodeck_favorites_file}.new"
      else
        log d "Game file $roms_folder/$system/$game not found, skipping..."
      fi
    done <<< "$system_favorites"
  done

  # Decide if sync needs to happen
  if [[ -f "$retrodeck_favorites_file" ]]; then # If an existing favorites manifest exists
    if [[ ! "$(cat "${retrodeck_favorites_file}.new" | jq 'length')" -gt 0 ]]; then # If all favorites were removed from all gamelists, meaning new manifest is empty
      log i "No favorites were found in current ES-DE gamelists, removing old entries"
      steam_sync_remove
      # Old manifest cleanup
      rm "$retrodeck_favorites_file"
      rm "${retrodeck_favorites_file}.new"
    else # The new favorites manifest is not empty
      if cmp -s "$retrodeck_favorites_file" "${retrodeck_favorites_file}.new"; then # See if the favorites manifests are the same, meaning there were no changes
        log i "ES-DE favorites have not changed, no need to sync again"
        rm "${retrodeck_favorites_file}.new"
      else
        # Make new favorites manifest the current one
        mv "${retrodeck_favorites_file}.new" "$retrodeck_favorites_file"
        steam_sync_add
      fi
    fi
  elif [[ "$(cat "${retrodeck_favorites_file}.new" | jq 'length')" -gt 0 ]]; then # No existing favorites manifest was found, so check if new manifest has entries
    log d "First time building favorites manifest, running sync"
    mv "${retrodeck_favorites_file}.new" "$retrodeck_favorites_file"
    steam_sync_add
  fi
}

steam_sync_add() {
  if [[ "$CONFIGURATOR_GUI" == "zenity" ]]; then
    (
    steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
    steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
    steam-rom-manager add >> "$srm_log" 2>&1
    ) |
    rd_zenity --progress \
    --title="Syncing with Steam" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="<span foreground='$purple'><b>\t\t\t\tAdding new favorited games to Steam</b></span>\n\n<b>NOTE: </b>This operation may take some time depending on the size of your library.\nFeel free to leave this in the background and switch to another application.\n\n" \
    --pulsate --width=500 --height=150 --auto-close --no-cancel
  else
    steam-rom-manager disable --names "RetroDECK Launcher" >> "$srm_log" 2>&1
    steam-rom-manager enable --names "RetroDECK Steam Sync" >> "$srm_log" 2>&1
    steam-rom-manager add >> "$srm_log" 2>&1
  fi
}

steam_sync_remove() {
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
}
