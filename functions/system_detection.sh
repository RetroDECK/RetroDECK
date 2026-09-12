#!/bin/bash

# Shared system-detection helpers used by both the main RetroDECK shell
# (run_game.sh) and the component launchers (launcher_functions.sh).
# Extracted from run_game.sh to avoid duplicate implementations.

system_exists() {
  # Checks whether a system name actually exists in es_systems.xml.
  # Guards against mistyped folder names being treated as valid systems.
  # USAGE: system_exists "$system_name"

  xmllint --recover --xpath "//system[name='$1']" "$es_systems" &>/dev/null
}

detect_system_by_extension() {
  # Finds all systems in es_systems.xml that support the ROMs file extension,
  # then presents a Zenity dialog for the user to choose if there are multiple matches.
  # USAGE: detect_system_by_extension "$game_path"

  local game_path="$1"
  local file_extension="${game_path##*.}"
  local file_extension_lower
  file_extension_lower=$(echo "$file_extension" | tr '[:upper:]' '[:lower:]')

  # Query es_systems.xml for all systems whose <extension> field contains the ROMs extension.
  local matching_systems
  matching_systems=$(xmllint --xpath \
    "//system[extension[contains(., '.$file_extension_lower')]]/fullname/text()" \
    "$es_systems" 2>/dev/null)

  if [[ -z "$matching_systems" ]]; then
    log e "No systems found supporting .$file_extension_lower"
    return 1
  fi

  local formatted_systems
  # Deduplicate while preserving order: several <system> entries can share the
  # same <fullname> (e.g. megacd/megacdjp, megadrive/genesis).
  formatted_systems=$(echo "$matching_systems" | tr '|' '\n' | awk '!seen[$0]++')

  local chosen_system
  chosen_system=$(rd_zenity --list \
    --title="Select System" \
    --column="Available Systems" \
    --text="Multiple systems support .$file_extension_lower extension. Please choose:" \
    --width=500 --height=400 <<< "$formatted_systems")

  if [[ -z "$chosen_system" ]]; then
    log e "No system selected by user"
    return 1
  fi

  # Map the human-readable fullname back to the internal system name
  local system_name
  system_name=$(xmllint --xpath \
    "string(//system[fullname='$chosen_system']/name)" \
    "$es_systems" 2>/dev/null)

  if [[ -z "$system_name" ]]; then
    log e "Could not resolve fullname=$chosen_system to system name"
    return 1
  fi

  echo "$system_name"
}

detect_system() {
  # Attempts to determine which system a ROM belongs to. Tries two methods:
  #   1. Extract from the directory structure (expects roms/<system>/... convention)
  #   2. Fall back to extension-based matching with a user picker dialog
  # USAGE: detect_system "$game_path" ["silent"]
  #
  # When the optional "silent" argument is provided (used at game launch), the
  # interactive extension picker (method 2) is skipped and the function returns
  # the path-derived system only if it is a valid es_systems.xml entry,
  # otherwise it returns nothing. This prevents a dialog from popping up during
  # a launch when the folder name is not a recognized system.

  local game_path="$1"
  local silent="$2"
  local system

  # Method 1: Extract system from the ROM path structure.
  # Take the first directory segment after "roms/" so ROMs stored in
  # subfolders (e.g. roms/snes/subdir/game.sfc) still resolve to "snes".
  system=$(echo "$game_path" | grep -oP '(?<=roms/)[^/]+' | head -n 1)

  # Only trust the folder name if it is a real system in es_systems.xml:
  # a mistyped folder (e.g. "meagadrive") must not be treated as a system.
  if [[ -n "$system" ]] && system_exists "$system"; then
    log d "Detected system=$system from path"
    echo "$system"
    return 0
  fi

  if [[ -n "$system" ]]; then
    log w "System '$system' from path not found in es_systems.xml"
  fi

  # Method 2: Fall back to extension-based detection with user dialog.
  # Skipped in silent mode (launch context) to avoid popping a picker.
  if [[ "$silent" == "silent" ]]; then
    log d "Silent mode: no valid system detected from path, skipping extension picker"
    return 1
  fi

  log i "Could not detect system from path, falling back to extension matching"
  system=$(detect_system_by_extension "$game_path")

  if [[ -n "$system" ]]; then
    echo "$system"
    return 0
  fi

  log e "Failed to detect system for: $game_path"
  return 1
}
