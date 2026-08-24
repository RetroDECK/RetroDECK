#!/bin/bash

# Pre-launch BIOS check for component launchers.
# This library is sourced automatically by launcher_functions.sh (which is itself
# sourced by every component_launcher.sh). It reuses the existing
# api_get_bios_file_status / build_zenity_bios_checker_menu_array helpers rather
# than re-implementing BIOS detection.

rd_get_missing_required_bios() {
  # Given a JSON array of systems (e.g. '["gc","wii"]'), returns a JSON array of
  # unconditionally-required BIOS entries that are currently missing.
  # Only strict manifest values block the launch:
  #   - "Required" / "required"
  #   - "Yes" (bare)
  #   - "At least one ..." groups (satisfied when any member file is found)
  # Conditional variants are informational only and never trigger the warning:
  #   - "Required, for certain Arcade Boards and Games"
  #   - "Required for some Japanese games." / "Required if ..."
  #   - "Yes, for certain games" / "Yes for KEGS"
  #   - "Optional*" (any variant)
  # USAGE: rd_get_missing_required_bios "$systems_json"

  local systems_json="$1"
  local status
  status=$(api_get_bios_file_status "$systems_json") || return 0

  # Determine which "At least one" groups are already satisfied.
  local satisfied_groups
  satisfied_groups=$(echo "$status" | jq '
    [ .[]
      | ((.required // "") | ascii_downcase | gsub("^\\s+|\\s+$"; "")) as $req
      | select($req | test("^at least one"))
      | select(.file_found == "Yes")
      | (.systems + "|" + .description)
    ] | unique')

  # Keep only strictly-required entries that are not found, dropping satisfied groups.
  echo "$status" | jq --argjson satisfied "$satisfied_groups" '
    map(. as $it |
      (($it.required // "") | ascii_downcase | gsub("^\\s+|\\s+$"; "")) as $req |
      select(
        ($req == "required" or $req == "yes" or ($req | test("^at least one")))
        and ($it.file_found != "Yes")
        and (if ($req | test("^at least one"))
             then ($satisfied | any(. == ($it.systems + "|" + $it.description)) | not)
             else true end)
      ))
  '
}

rd_open_bios_checker() {
  # Reuses the existing Configurator BIOS checker, passing the system filter so it
  # scans only the relevant system. USAGE: rd_open_bios_checker "$systems_json"
  configurator_bios_checker_dialog "$1"
}

rd_pre_launch_bios_check_continue_prompt() {
  # Second-chance prompt shown after the user reviewed the BIOS checker.
  # USAGE: rd_pre_launch_bios_check_continue_prompt "$system_label"

  local system_label="$1"
  rd_zenity --question --no-wrap \
    --title="RetroDECK - Missing BIOS Files" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --ok-label="Yes" --cancel-label="No" \
    --text="Continue launching <b>$system_label</b> anyway?" >/dev/null
  if [[ $? -eq 1 ]]; then
    log i "User aborted launch after reviewing BIOS checker"
    exit 0
  fi
  return 0
}

rd_pre_launch_bios_check() {
  # Automatic BIOS presence check run before a game launches.
  # Shows a 3-button Zenity dialog when required BIOS files are missing:
  #   Yes        -> continue launching
  #   No         -> abort the launch
  #   Bios Check -> open the existing BIOS checker for the detected system
  # USAGE: rd_pre_launch_bios_check "$@"   (called with the launcher arguments)

  # Ensure core variables are available in the launcher environment.
  if [[ -f /app/libexec/dyn_vars.sh ]]; then
    # shellcheck disable=SC1091
    source /app/libexec/dyn_vars.sh
  fi

  # Fallbacks for paths that may not be exported in every launcher context.
  roms_path="${roms_path:-$(jq -r '.paths.roms_path // empty' "$rd_conf")}"
  bios_path="${bios_path:-$(jq -r '.paths.bios_path // empty' "$rd_conf")}"
  logs_path="${logs_path:-$(jq -r '.paths.logs_path // empty' "$rd_conf")}"
  es_systems="${es_systems:-$rd_components/es-de/share/es-de/resources/systems/linux/es_systems.xml}"

  # Skip condition 1: preset disabled?
  local preset_state
  preset_state=$(jq -r '.presets.bios_check_on_launch.retrodeck // "true"' "$rd_conf" 2>/dev/null)
  if [[ "$preset_state" == "false" ]]; then
    log d "bios_check_on_launch preset disabled, skipping pre-launch BIOS check"
    return 0
  fi

  # Skip condition 2: find the ROM argument (a path under the roms directory).
  local rom_path=""
  local arg
  for arg in "$@"; do
    if [[ "$arg" == *"roms/"* ]]; then
      rom_path="$arg"
      break
    fi
  done
  if [[ -z "$rom_path" ]]; then
    log d "No ROM path detected in launcher arguments, skipping pre-launch BIOS check"
    return 0
  fi

  # Skip condition 3: detect the system (silent: no interactive picker at launch).
  local system
  system=$(detect_system "$rom_path" "silent")
  if [[ -z "$system" ]]; then
    log d "Could not detect system for $rom_path, skipping pre-launch BIOS check"
    return 0
  fi

  # Skip condition 4: component manifests have no BIOS section for this system.
  local has_bios
  has_bios=$(jq --arg sys "$system" '
    [ .[] | .manifest | .. | objects | select(has("bios")) | .bios ]
    | flatten | map(select([.system] | flatten | index($sys))) | length > 0
  ' "$component_manifest_cache_file" 2>/dev/null)
  if [[ "$has_bios" != "true" ]]; then
    log d "No BIOS entries for system $system, skipping pre-launch BIOS check"
    return 0
  fi

  # Find missing required BIOS files.
  local systems_json
  systems_json=$(jq -nc --arg sys "$system" '[$sys]')
  local missing
  missing=$(rd_get_missing_required_bios "$systems_json")
  if [[ -z "$missing" || "$missing" == "[]" ]]; then
    log d "All required BIOS files present for system $system"
    return 0
  fi

  # Build the human-readable missing list for the dialog.
  local missing_text
  missing_text=$(echo "$missing" | jq -r '.[] | "• " + .file + " (" + .description + ")"' 2>/dev/null | head -n 20)
  local system_label
  system_label=$(echo "$missing" | jq -r '.[0].systems // empty' 2>/dev/null)

  local choice
  choice=$(rd_zenity --info --no-wrap \
    --title="RetroDECK - Missing BIOS Files" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --ok-label="Yes" --extra-button="No" --extra-button="Bios Check" \
    --text="The following required BIOS file(s) for <b>$system_label</b> appear to be missing:\n\n<span foreground='#FF5555'>$missing_text</span>\n\nDo you want to continue launching anyway?\n\nNOTE: you can disable this check in the RetroDECK Configurator." )
  local rc=$?
  log d "Pre-launch BIOS prompt outcome: rc=$rc choice='${choice:-<empty>}'"

  if [[ "$rc" -eq 1 || "$choice" == "No" ]]; then
    # "No" or dialog closed -> abort the launch.
    log i "User aborted launch due to missing required BIOS files for $system"
    exit 0
  fi

  if [[ "$choice" == "Bios Check" ]]; then
    # Open the existing BIOS checker for this system, then ask again.
    log i "User opened BIOS Checker for system $system"
    if declare -F configurator_bios_checker_dialog > /dev/null; then
      rd_open_bios_checker "$systems_json"
    else
      log e "configurator_bios_checker_dialog not available in launcher context"
      rd_zenity --error --no-wrap \
        --title="RetroDECK - BIOS Checker" \
        --text="The BIOS Checker could not be opened from this context.\nPlease run it manually from:\nConfigurator -> Tools -> BIOS Checker."
    fi
    rd_pre_launch_bios_check_continue_prompt "$system_label"
    return $?
  fi

  # "Yes" -> continue launching.
  log d "User chose to continue launch despite missing BIOS files for $system"
  return 0
}
