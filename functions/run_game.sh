#!/bin/bash

shell_quote() {
  # Safely quotes a string for embedding in an eval'd command.
  printf "'%s'" "${1//\'/\'\\\'\'}"
}

get_command_by_label() {
  # Looks up the <command> element with a matching label attribute for the
  # given system in es_systems.xml.
  # USAGE: get_command_by_label "$system_name" "$label"

  local system_name="$1"
  local label="$2"
  local command

  command=$(xmllint --recover --xpath \
    "string(//system[name=\"$system_name\"]/command[@label=\"$label\"])" \
    "$es_systems" 2>/dev/null)

  if [[ -z "$command" ]]; then
    log d "No command found for system=$system_name label=$label"
    return 1
  fi

  echo "$command"
}

get_default_command() {
  # Gets the first <command> element for the given system in es_systems.xml.
  # This is the fallback when no emulator override is specified anywhere.
  # USAGE: get_default_command "$system_name"

  local system_name="$1"
  local command

  command=$(xmllint --recover --xpath \
    "string(//system[name='$system_name']/command[1])" \
    "$es_systems" 2>/dev/null)

  if [[ -z "$command" ]]; then
    log e "No commands found for system: $system_name"
    return 1
  fi

  echo "$command"
}

get_system_fullname() {
  # Looks up the human-readable <fullname> for a system in es_systems.xml.
  # USAGE: get_system_fullname "$system_name"

  local system_name="$1"
  local fullname

  fullname=$(xmllint --recover --xpath \
    "string(//system[name='$system_name']/fullname)" \
    "$es_systems" 2>/dev/null)

  if [[ -z "$fullname" ]]; then
    log d "No fullname found for system: $system_name"
    return 1
  fi

  echo "$fullname"
}

resolve_emulator_path() {
  # Resolves an emulator name (e.g. "RETROARCH", "MAME") to its actual binary path by searching es_find_rules.xml.
  # USAGE: resolve_emulator_path "$emulator_name"

  local emulator_name="$1"
  local emulator_section
  local found_path=""

  emulator_section=$(xmllint --xpath "//emulator[@name='$emulator_name']" "$es_find_rules" 2>/dev/null)

  if [[ -z "$emulator_section" ]]; then
    log e "Emulator not found in find rules: $emulator_name"
    return 1
  fi

  # Try systempath entries first (binaries available on $PATH)
  local entry_values
  mapfile -t entry_values < <(
    echo "$emulator_section" \
      | xmllint --xpath "//rule[@type='systempath']/entry" - 2>/dev/null \
      | grep -oP '(?<=<entry>)[^<]+' || true
  )

  local cmd_path
  for cmd_path in "${entry_values[@]}"; do
    if [[ -n "$cmd_path" ]] && command -v "$cmd_path" &>/dev/null; then
      found_path="$cmd_path"
      break
    fi
  done

  # If not found on PATH, try staticpath entries (absolute paths)
  # These entries may use pipe-delimited format: check_path|run_command
  if [[ -z "$found_path" ]]; then
    mapfile -t entry_values < <(
      echo "$emulator_section" \
        | xmllint --xpath "//rule[@type='staticpath']/entry" - 2>/dev/null \
        | grep -oP '(?<=<entry>)[^<]+' || true
    )

    for cmd_path in "${entry_values[@]}"; do
      [[ -z "$cmd_path" ]] && continue

      local check_path="$cmd_path"
      local run_command=""

      # Check for pipe-delimited override: /path/to/binary|command to run
      if [[ "$cmd_path" == *"|"* ]]; then
        check_path="${cmd_path%%|*}"
        run_command="${cmd_path#*|}"
      fi

      if [[ -x "$check_path" ]]; then
        # Use the override command if present, otherwise use the check path
        found_path="${run_command:-$check_path}"
        break
      fi
    done
  fi

  if [[ -z "$found_path" ]]; then
    log e "No valid path found for emulator: $emulator_name"
    return 1
  fi

  log d "Resolved $emulator_name to $found_path"
  echo "$found_path"
}

resolve_core_path() {
  # Resolves a core name (e.g. "RETROARCH") to its core directory path by searching <core> entries in es_find_rules.xml.
  # USAGE: resolve_core_path "$core_name"

  local core_name="$1"
  local core_section

  core_section=$(xmllint --xpath "//core[@name='$core_name']" "$es_find_rules" 2>/dev/null)

  if [[ -z "$core_section" ]]; then
    log e "Core not found in find rules: $core_name"
    return 1
  fi

  local entry_values
  mapfile -t entry_values < <(
    echo "$core_section" \
      | xmllint --xpath "//rule[@type='corepath']/entry" - 2>/dev/null \
      | grep -oP '(?<=<entry>)[^<]+' || true
  )

  local core_dir
  for core_dir in "${entry_values[@]}"; do
    if [[ -n "$core_dir" && -d "$core_dir" ]]; then
      log d "Resolved $core_name to $core_dir"
      echo "$core_dir"
      return 0
    fi
  done

  log e "No valid core path found for: $core_name"
  return 1
}

get_altemulator_label() {
  # USAGE: get_altemulator_label "$system" "$game_basename"
  # Searches the gamelist.xml for the given system to find a per-game <altemulator> tag. 
  # NOTE: The game_basename should be in the format "./filename.ext" to match the <path> entries in the gamelist.

  local system="$1"
  local game_basename="$2"
  local gamelist="$esde_gamelists_path/$system/gamelist.xml"

  if [[ ! -f "$gamelist" ]]; then
    log d "No gamelist found at $gamelist"
    return 1
  fi

  # The awk script scans for <game> blocks, looks for one whose <path> matches
  # the game basename, then extracts the <altemulator> value from that block.
  local label
  label=$(awk -v path="$game_basename" '
    /<game>/,/<\/game>/ {
      if ($0 ~ "<path>" path "</path>") found = 1
      if (found && $0 ~ /<altemulator>/) {
        gsub(/.*<altemulator>|<\/altemulator>.*/, "")
        print
        exit
      }
      if (found && $0 ~ /<\/game>/) exit
    }
  ' "$gamelist" 2>/dev/null)

  if [[ -z "$label" ]]; then
    log d "No altemulator found for game: $game_basename"
    return 1
  fi

  log d "Found label=$label for game=$game_basename"
  echo "$label"
}

get_alternative_emulator_label() {
  # Searches the gamelist.xml for the given system to find a system-wide <alternativeEmulator> tag.
  # USAGE: get_alternative_emulator_label "$system"

  local system="$1"
  local gamelist="$esde_gamelists_path/$system/gamelist.xml"

  if [[ ! -f "$gamelist" ]]; then
    log d "No gamelist found at $gamelist"
    return 1
  fi

  # The <alternativeEmulator> block is at the top level of the file, outside <gameList>. We extract the <label> value from within it.
  local label
  label=$(awk '
    /<alternativeEmulator>/,/<\/alternativeEmulator>/ {
      if ($0 ~ /<label>/) {
        gsub(/.*<label>|<\/label>.*/, "")
        print
        exit
      }
    }
  ' "$gamelist" 2>/dev/null)

  if [[ -z "$label" ]]; then
    log d "No alternativeEmulator found for system: $system"
    return 1
  fi

  log d "Found label=$label for system=$system"
  echo "$label"
}

detect_system() {
  # Attempts to determine which system a ROM belongs to. Tries two methods:
  #   1. Extract from the directory structure (expects roms/<system>/... convention)
  #   2. Fall back to extension-based matching with a user picker dialog
  # USAGE: detect_system "$game_path"

  local game_path="$1"
  local system

  # Method 1: Extract system from the ROM path structure.
  system=$(echo "$game_path" | grep -oP '(?<=roms/)[^/]+')

  if [[ -n "$system" ]]; then
    log d "Detected system=$system from path"
    echo "$system"
    return 0
  fi

  # Method 2: Fall back to extension-based detection with user dialog.
  log i "Could not detect system from path, falling back to extension matching"
  system=$(detect_system_by_extension "$game_path")

  if [[ -n "$system" ]]; then
    echo "$system"
    return 0
  fi

  log e "Failed to detect system for: $game_path"
  return 1
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
  formatted_systems=$(echo "$matching_systems" | tr '|' '\n')

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

resolve_command_template() {
  # Determines which command template to use for launching a game, following
  # this priority chain (highest to lowest):
  #
  #   1. CLI-provided emulator (-e flag) - used directly as the command template
  #   2. Manual mode (-m flag) - user picks from a Zenity list of all commands
  #   3. Per-game <altemulator> - label from gamelist.xml, resolved against es_systems.xml
  #   4. Per-system <alternativeEmulator> - label from gamelist.xml, resolved against es_systems.xml
  #   5. Default - first <command> in es_systems.xml for this system
  # USAGE: resolve_command_template "$system" "$game_basename" "$cli_emulator" "$manual_mode"

  local system="$1"
  local game_basename="$2"
  local cli_emulator="$3"
  local manual_mode="$4"

  # Priority 1: Emulator provided via CLI -e flag
  if [[ -n "$cli_emulator" ]]; then
    log d "Using CLI-provided emulator: $cli_emulator"
    echo "$cli_emulator"
    return 0
  fi

  # Priority 2: Manual mode - show Zenity picker
  if [[ "$manual_mode" == "true" ]]; then
    log d "Manual mode, showing emulator selection dialog"
    local selected
    selected=$(select_command_manual "$system")
    if [[ -z "$selected" ]]; then
      log e "No emulator selected in manual mode"
      return 1
    fi
    echo "$selected"
    return 0
  fi

  # Priority 3: Per-game <altemulator> override
  local label
  if label=$(get_altemulator_label "$system" "$game_basename"); then
    log d "Found per-game altemulator label: $label"
    local command
    if command=$(get_command_by_label "$system" "$label"); then
      echo "$command"
      return 0
    fi
    log d "altemulator label=$label did not match any command in es_systems.xml, continuing to next priority"
  fi

  # Priority 4: Per-system <alternativeEmulator> override
  if label=$(get_alternative_emulator_label "$system"); then
    log d "Found system-wide alternativeEmulator label: $label"
    local command
    if command=$(get_command_by_label "$system" "$label"); then
      echo "$command"
      return 0
    fi
    log d "alternativeEmulator label=$label did not match any command in es_systems.xml, continuing to default"
  fi

  # Priority 5: Default - first command for the system
  log d "Using default (first) command for system: $system"
  get_default_command "$system"
}

select_command_manual() {
  # Presents a Zenity dialog listing all available emulator commands for the
  # given system, extracted from es_systems.xml. If only one command exists,
  # it is returned directly without showing a dialog.
  # USAGE: select_command_manual "$system"

  local system_name="$1"
  local system_section

  system_section=$(xmllint --xpath "//system[name='$system_name']" "$es_systems" 2>/dev/null)

  if [[ -z "$system_section" ]]; then
    log e "System not found: $system_name"
    return 1
  fi

  # Extract label-command pairs from all <command> elements.
  local command_list=()
  local raw_commands
  raw_commands=$(echo "$system_section" | xmllint --xpath "//command" - 2>/dev/null) || true

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local label command
    label=$(echo "$line" | sed -n 's/.*label="\([^"]*\)".*/\1/p')
    command=$(echo "$line" | sed -n 's/.*<command[^>]*>\(.*\)<\/command>.*/\1/p')

    if [[ -n "$label" && -n "$command" ]]; then
      command_list+=("$label" "$command")
    fi
  done <<< "$raw_commands"

  if [[ ${#command_list[@]} -eq 0 ]]; then
    log e "No commands found for system: $system_name"
    return 1
  fi

  # If there's exactly one <command>, skip the dialog
  if [[ ${#command_list[@]} -eq 2 ]]; then
    log d "Only one command available, using it directly: ${command_list[0]}"
    echo "${command_list[1]}"
    return 0
  fi

  local selected
  selected=$(rd_zenity --list \
    --title="RetroDECK - Run Game - Select a component for $system_name" \
    --column="Emulator" --column="command" \
    "${command_list[@]}" \
    --width=800 --height=400 \
    --print-column=2 --hide-column=2)

  if [[ -z "$selected" ]]; then
    log e "User cancelled emulator selection"
    return 1
  fi

  echo "$selected"
}

substitute_placeholders() {
  # Takes a raw ES-DE command template and a game file path, replaces all
  # placeholder tokens with their actual values, and returns an executable
  # command string suitable for eval.
  #
  # Substitution phases:
  #   Phase 1: %PRECOMMAND_*% - pre-command binaries (e.g. Wine), resolved via find_rules
  #   Phase 2: %EMULATOR_*%   - emulator binaries, resolved via find_rules
  #   Phase 3: %CORE_*%       - emulator core directories, resolved via find_rules
  #   Phase 4: %STARTDIR%     - working directory directive, parsed and removed from command
  #   Phase 5: Path placeholders - %ROM%, %BASENAME%, %FILENAME%, %ROMPATH%, etc.
  #   Phase 6: Standalone %EMUDIR%, %EMUPATH%, %ESPATH% - derived from resolved paths
  #   Phase 7: Flag placeholders - %RUNINBACKGROUND%, %ENABLESHORTCUTS% stripped (only used internally by ES-DE)
  #   Phase 8: %INJECT%       - file content injection (depends on %BASENAME% from phase 5)
  #   Phase 9: Prepend cd for %STARTDIR% if applicable
  #
  # Placeholder reference (https://gitlab.com/es-de/emulationstation-de/-/blob/master/INSTALL.md?ref_type=heads#es_systemsxml):
  #   %ROM%               - absolute path to the ROM file
  #   %ROMRAW%            - same as %ROM%
  #   %BASENAME%          - ROM filename without extension
  #   %FILENAME%          - ROM filename with extension
  #   %ROMPATH%           - directory containing the ROM
  #   %GAMEDIR%           - same as %ROMPATH%
  #   %GAMEDIRRAW%        - same as %ROMPATH%
  #   %CORE_*%            - core directory resolved via es_find_rules.xml corepath rules
  #   %EMUDIR%            - directory containing the resolved emulator binary
  #   %EMUPATH%           - same as emulator binary path (for core location checking)
  #   %ESPATH%            - path to the ES-DE binary
  #   %EMULATOR_*%        - resolved to binary path via es_find_rules.xml emulator rules
  #   %PRECOMMAND_*%      - resolved to binary path via es_find_rules.xml (for Wine/Proton)
  #   %STARTDIR%=<path>   - sets working directory for the command (parsed and removed)
  #   %INJECT%=<file>     - replaced with the contents of the specified file
  # USAGE: substitute_placeholders "$command_template" "$game_path"
  
  local cmd="$1"
  local game_path="$2"

  log d "Input command: $cmd"

  # Derive all path components from the game path
  local rom_dir
  rom_dir=$(dirname "$game_path")
  local base_name
  base_name=$(basename "$game_path")
  base_name="${base_name%%.*}"  # strip extension
  local file_name
  file_name=$(basename "$game_path")

  # Build quoted versions for safe embedding in eval'd commands
  local quoted_rom quoted_dir quoted_basename quoted_filename
  quoted_rom=$(shell_quote "$game_path")
  quoted_dir=$(shell_quote "$rom_dir")
  quoted_basename=$(shell_quote "$base_name")
  quoted_filename=$(shell_quote "$file_name")

  # Phase 1: Resolve %PRECOMMAND_*% placeholders
  while [[ "$cmd" =~ (%PRECOMMAND_[A-Z0-9_-]+%) ]]; do
    local placeholder="${BASH_REMATCH[1]}"
    local precmd_name="${placeholder#%PRECOMMAND_}"
    precmd_name="${precmd_name%%%}"

    local resolved_path
    if ! resolved_path=$(resolve_emulator_path "$precmd_name"); then
      log e "Failed to resolve precommand: $precmd_name"
      return 1
    fi

    cmd="${cmd//$placeholder/$resolved_path}"
  done

  # Phase 2: Resolve %EMULATOR_*% placeholders
  local emulator_path=""
  while [[ "$cmd" =~ (%EMULATOR_[A-Z0-9_-]+%) ]]; do
    local placeholder="${BASH_REMATCH[1]}"

    # Extract the emulator name: strip %EMULATOR_ prefix and % suffix
    local emu_name="${placeholder#%EMULATOR_}"
    emu_name="${emu_name%%%}"

    # Special case: OS-SHELL is always /bin/sh
    if [[ "$emu_name" == "OS-SHELL" ]]; then
      cmd="${cmd//$placeholder//bin/sh}"
      continue
    fi

    local resolved_path
    if ! resolved_path=$(resolve_emulator_path "$emu_name"); then
      log e "Failed to resolve emulator: $emu_name"
      return 1
    fi

    emulator_path="$resolved_path"
    cmd="${cmd//$placeholder/$resolved_path}"
  done

  # Phase 3: Resolve %CORE_*% placeholders
  while [[ "$cmd" =~ (%CORE_[A-Z0-9_-]+%) ]]; do
    local placeholder="${BASH_REMATCH[1]}"
    local core_name="${placeholder#%CORE_}"
    core_name="${core_name%%%}"

    local core_dir
    if ! core_dir=$(resolve_core_path "$core_name"); then
      log e "Failed to resolve core path: $core_name"
      return 1
    fi

    cmd="${cmd//$placeholder/$core_dir}"
  done

  # Phase 4: Process %STARTDIR%
  local start_dir=""
  if [[ "$cmd" == *"%STARTDIR%"* ]]; then
    if ! process_startdir cmd start_dir "$emulator_path" "$game_path"; then
      log e "%STARTDIR% processing failed"
      return 1
    fi
  fi

  # Phase 5: Substitute simple path placeholders
  cmd="${cmd//"%ROM%"/$quoted_rom}"
  cmd="${cmd//"%ROMRAW%"/$quoted_rom}"
  cmd="${cmd//"%ROMPATH%"/$quoted_dir}"
  cmd="${cmd//"%BASENAME%"/$quoted_basename}"
  cmd="${cmd//"%FILENAME%"/$quoted_filename}"
  cmd="${cmd//"%GAMEDIR%"/$quoted_dir}"
  cmd="${cmd//"%GAMEDIRRAW%"/$quoted_dir}"

  # Phase 6: Standalone emulator/path placeholders
  if [[ -n "$emulator_path" ]]; then
    local emu_dir
    emu_dir=$(dirname "$emulator_path")
    cmd="${cmd//"%EMUDIR%"/$emu_dir}"
    cmd="${cmd//"%EMUPATH%"/$emulator_path}"
  fi
  cmd="${cmd//"%ESPATH%"/${es_de_bin_path:-}}"

  # Phase 7: Strip ES-DE behavioral flags
  cmd="${cmd//"%ENABLESHORTCUTS%"/}"
  cmd="${cmd//"%RUNINBACKGROUND%"/}"

  # Phase 8: Process %INJECT%
  if [[ "$cmd" == *"%INJECT%"* ]]; then
    cmd=$(process_inject "$cmd" "$rom_dir")
  fi

  # Phase 9: Prepend working directory change if %STARTDIR% was found
  if [[ -n "$start_dir" ]]; then
    cmd="cd $(shell_quote "$start_dir") && $cmd"
  fi

  # Clean up any double spaces left by stripped placeholders
  while [[ "$cmd" == *"  "* ]]; do
    cmd="${cmd//  / }"
  done

  log d "Final command: $cmd"
  echo "$cmd"
}

process_startdir() {
  # Parses the %STARTDIR%=<path> directive out of a command string, creates the directory if it doesn't exist.
  # USAGE: process_startdir <cmd_varname> <startdir_varname> "$emulator_path" "$game_path"

  local -n _sd_cmd="$1"
  local -n _sd_result="$2"
  local emulator_path="$3"
  local game_path="$4"
 
  local start_dir=""
  local before="" after=""
 
  if [[ "$_sd_cmd" =~ ^(.*)%STARTDIR%=\"([^\"]*)\"(.*)$ ]]; then # Try quoted form first: %STARTDIR%="path with spaces"
    before="${BASH_REMATCH[1]}"
    start_dir="${BASH_REMATCH[2]}"
    after="${BASH_REMATCH[3]}"
  elif [[ "$_sd_cmd" =~ ^(.*)%STARTDIR%=([^ ]+)(.*)$ ]]; then # Try unquoted form: %STARTDIR%=path (delimited by space or end-of-string)
    before="${BASH_REMATCH[1]}"
    start_dir="${BASH_REMATCH[2]}"
    after="${BASH_REMATCH[3]}"
  else
    log e "Could not parse %STARTDIR% directive"
    return 1
  fi
 
  # Remove the %STARTDIR% directive from the command
  _sd_cmd="${before}${after}"
  _sd_cmd="${_sd_cmd#"${_sd_cmd%%[![:space:]]*}"}"  # trim leading whitespace
  _sd_cmd="${_sd_cmd%"${_sd_cmd##*[![:space:]]}"}"  # trim trailing whitespace
 
  # Expand tilde to $HOME
  start_dir="${start_dir/#\~/$HOME}"
 
  # Expand environment variables
  start_dir=$(echo "$start_dir" | envsubst)
 
  # Resolve sub-placeholders within the start directory path
  if [[ -n "$emulator_path" ]]; then
    start_dir="${start_dir//%EMUDIR%/$(dirname "$emulator_path")}"
  fi
  start_dir="${start_dir//%GAMEDIR%/$(dirname "$game_path")}"
  start_dir="${start_dir//%GAMEENTRYDIR%/$game_path}"
 
  # Create the directory if it doesn't exist
  if [[ ! -d "$start_dir" ]]; then
    if ! mkdir -p "$start_dir"; then
      log e "Could not create directory: $start_dir (permission issue?)"
      return 1
    fi
  fi
 
  # Normalize to absolute path
  start_dir=$(realpath "$start_dir")
  log d "Resolved start directory: $start_dir"
 
  _sd_result="$start_dir"
}

process_inject() {
  # Handles %INJECT%='filename'.extension placeholders in a command string.
  # USAGE: process_inject "$command" "$rom_dir"

  local cmd="$1"
  local rom_dir="$2"
  local max_inject_size=4096

  while [[ "$cmd" =~ (%INJECT%=\'([^\']+)\')(.[^ ]+)? ]]; do
    local full_match="${BASH_REMATCH[0]}"
    local inject_file="${BASH_REMATCH[2]}"
    local extension="${BASH_REMATCH[3]}"
    local inject_path="$rom_dir/$inject_file$extension"

    log d "Found placeholder for file: $inject_path"

    # Escape sed special characters
    local escaped_match
    escaped_match=$(printf '%s' "$full_match" | sed 's/[]\/$*.^[]/\\&/g')

    if [[ -f "$inject_path" ]]; then
      # Check file size per ES-DE's 4096-byte safety limit
      local file_size
      file_size=$(stat -c%s "$inject_path" 2>/dev/null || echo 0)

      if [[ "$file_size" -gt "$max_inject_size" ]]; then
        log w "File exceeds ${max_inject_size}-byte limit ($file_size bytes): $inject_path (skipping)"
        cmd=$(echo "$cmd" | sed "s|$escaped_match||g")
        continue
      fi

      # Collapse newlines to spaces for inline injection
      local inject_content
      inject_content=$(tr '\n' ' ' < "$inject_path")
      log i "Injecting contents of $inject_path"

      cmd=$(echo "$cmd" | sed "s|$escaped_match|$inject_content|g")
    else
      log d "File not found: $inject_path (removing placeholder)"
      cmd=$(echo "$cmd" | sed "s|$escaped_match||g")
    fi
  done

  log d "Result: $cmd"
  echo "$cmd"
}

run_event_scripts() {
  # Executes all Bash scripts found in $esde_scripts_dir/<event_name>/.
  # Each script receives four positional arguments matching the ES-DE convention:
  #   $1 - ROM path (absolute path to the game file)
  #   $2 - Game name (ROM filename without extension)
  #   $3 - System name (short name, e.g. "snes")
  #   $4 - System full name (display name, e.g. "Nintendo SNES (Super Nintendo)")
  # USAGE: run_event_scripts "$event_name" "$rom_path" "$game_name" "$system_name" "$system_fullname"

  local event_name="$1"
  local rom_path="$2"
  local game_name="$3"
  local system_name="$4"
  local system_fullname="$5"

  local scripts_dir="$esde_scripts_dir/$event_name"

  if [[ ! -d "$scripts_dir" ]]; then
    log d "No scripts directory for event: $event_name"
    return 0
  fi

  local script_count=0
  local script

  for script in "$scripts_dir"/*.sh; do
    [[ ! -f "$script" ]] && continue

    if [[ ! -x "$script" ]]; then
      log w "Skipping non-executable script: $script"
      continue
    fi

    log i "Executing $event_name script: $script"
    bash "$script" "$rom_path" "$game_name" "$system_name" "$system_fullname" &
    script_count=$((script_count + 1))
  done

  if [[ "$script_count" -gt 0 ]]; then
    log i "Launched $script_count script(s) for event: $event_name"
  fi
}

launch_desktop_file() {
  # Handles launching games packaged as .desktop files. Extracts the Exec= line and runs it directly.
  # USAGE: launch_desktop_file "$desktop_file_path"

  local desktop_file="$1"

  # Extract the Exec= line, stripping the key prefix
  local exec_cmd
  exec_cmd=$(grep '^Exec=' "$desktop_file" | sed 's/^Exec=//')

  if [[ -z "$exec_cmd" ]]; then
    log e "No Exec= line found in: $desktop_file"
    exit 1
  fi

  # RPCS3 workaround: convert doubled percent signs back to single
  exec_cmd="${exec_cmd//%%RPCS3_GAMEID%%/%RPCS3_GAMEID%}"

  log i "==========================================="
  log i " RetroDECK is now booting the game"
  log i " Game path: $desktop_file"
  log i " Recognized system: desktop file"
  log i " Command line: $exec_cmd"
  log i "==========================================="

  eval "$exec_cmd"
  exit $?
}

run_game() {
  local emulator=""
  local system=""
  local manual_mode=false
  local usage="Usage: flatpak run net.retrodeck.retrodeck [--emulator <name>] [--system <system>] [--manual] <game_path>"
  local game_arg=""
 
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --emulator|-e)
        emulator="$2"
        shift 2
        ;;
      --system|-s)
        system="$2"
        shift 2
        ;;
      --manual|-m)
        manual_mode=true
        log i "Manual mode enabled"
        shift
        ;;
      --*)
        log e "Unknown argument '$1'"
        log i "$usage"
        return 1
        ;;
      *)
        game_arg="$1"
        shift
        ;;
    esac
  done

  # Validate that a game path was provided
  if [[ -z "$game_arg" ]]; then
    log e "Game path is required"
    log i "$usage"
    return 1
  fi

  # Handle .desktop files
  if [[ "$game_arg" == *.desktop ]]; then
    launch_desktop_file "$game_arg"
  fi

  local game
  game=$(realpath "$game_arg" 2>/dev/null) || true

  # Handle "directory as a file"
  if [[ -d "$game" ]]; then
    log d "Game path is a directory, looking for inner file"
    game="$game/$(basename "$game")"
    log d "Resolved inner file: $game"
  fi

  # Validate the game file exists
  if [[ -z "$game" || ! -e "$game" ]]; then
    rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
      --ok-label="OK" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK - Run Game" \
      --text="File: <span foreground='$purple'><b>\"${game:-$game_arg}\"</b></span> not found.\n\nMake sure RetroDECK's Flatpak has permission to access the specified path.\n\nIf needed, add the path in Flatseal or terminal and try again."
    log e "File not found: ${game:-$game_arg}"
    return 1
  fi

  # Build the game basename in gamelist.xml format
  local game_basename="./$(basename "$game")"

  # Detect system
  if [[ -z "$system" ]]; then
    if ! system=$(detect_system "$game"); then
      log e "Could not determine system for: $game"
      return 1
    fi
  fi
  log d "system=$system"

  # Derive event script arguments from resolved game and system info.
  local game_name
  game_name=$(basename "$game")
  game_name="${game_name%%.*}"
  local system_fullname
  system_fullname=$(get_system_fullname "$system") || system_fullname="$system"

  # Resolve command template
  local command_template
  if ! command_template=$(resolve_command_template "$system" "$game_basename" "$emulator" "$manual_mode"); then
    log e "Could not resolve an emulator command for system=$system"
    return 1
  fi

  # Substitute placeholders
  local final_command
  if ! final_command=$(substitute_placeholders "$command_template" "$game"); then
    log e "Placeholder substitution failed"
    return 1
  fi

  # Determine if event script should be used
  local event_scripts_enabled=$(get_component_option "es-de" "esde_engine_launch_scripts")

  # Execute
  log d "Launching with command: $final_command"

  log i "==========================================="
  log i " RetroDECK is now booting the game"
  log i " Game path: $game"
  log i " Recognized system: $system"
  log i " Command template: $command_template"
  log i " Event scripts enabled: $event_scripts_enabled"
  log i "==========================================="

  if [[ "$event_scripts_enabled" == "true" ]]; then
    run_event_scripts "game-start" "$game" "$game_name" "$system" "$system_fullname"
  fi

  log i "Launching with command: $final_command"
  eval "$final_command"

  if [[ "$event_scripts_enabled" == "true" ]]; then
    run_event_scripts "game-end" "$game" "$game_name" "$system" "$system_fullname"
  fi
}
