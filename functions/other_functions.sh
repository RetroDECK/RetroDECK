#!/bin/bash

verify_space() {
  # Function used for verifying adequate space before moving directories around
  # USAGE: verify_space $source_dir $dest_dir [$visibility]
  local source_dir="$1"
  local dest_dir="$2"
  local visibility=${3:-}

  if [[ ! -n "$source_dir" || ! -n "$dest_dir" ]]; then
    log e "Missing source or dest directory to validate."
    return 1
  fi

  if [[ "$visibility" == "zenity" ]]; then
    local progress_pipe
    progress_pipe=$(mktemp -u)
    mkfifo "$progress_pipe"

    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --width="800" \
    --title "RetroDECK Configurator - Space Validation" < "$progress_pipe" &
    local zenity_pid=$!

    local progress_fd
    exec {progress_fd}>"$progress_pipe"

    echo "# Validating adequate free space in $dest_dir, please wait..." >&$progress_fd
  fi

  source_size=$(du -sk "$1" | awk '{print $1}')
  source_size=$((source_size+(source_size/10))) # Add 10% to source size for safety
  dest_avail=$(df -k --output=avail "$2" | tail -1)

  if [[ "$visibility" == "zenity" ]]; then
    echo "100" >&$progress_fd

    exec {progress_fd}>&-
    wait "$zenity_pid" 2>/dev/null
    rm -f "$progress_pipe"
  fi

  if [[ $source_size -ge $dest_avail ]]; then
    return 1
  else
    return 0
  fi
}

move() {
  # Function to move a directory from one parent to another
  # USAGE: move $source_dir $dest_dir

  source_dir="$(echo "$1" | sed 's![^/]$!&/!')" # Add trailing slash if it is missing
  dest_dir="$(echo "$2" | sed 's![^/]$!&/!')" # Add trailing slash if it is missing

  log d "Moving \"$source_dir\" to \"$dest_dir\""

  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - Move in Progress" \
  --text="Moving directory:\n<span foreground='$purple'><b>$(basename "$1")</b></span>\n\nTo its new location:\n<span foreground='$purple'><b>$2</b></span>.\n\n<span foreground='$purple'><b>Please wait while the process finishes</b></span>.\nThis might take a while..." < "$progress_pipe" &
  local zenity_pid=$!

  local progress_fd
  exec {progress_fd}>"$progress_pipe"

  rsync -a --remove-source-files --ignore-existing --mkpath "$source_dir" "$dest_dir" # Copy files but don't overwrite conflicts
  find "$source_dir" -type d -empty -delete # Cleanup empty folders that were left behind

  echo "100" >&$progress_fd

  exec {progress_fd}>&-
  wait "$zenity_pid" 2>/dev/null
  rm -f "$progress_pipe"

  if [[ -d "$source_dir" ]]; then # Some conflicting files remain
    rd_zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Move Directories" \
    --text="Some files could not be moved because they already exist in the destination.\n\n\<span foreground='$purple'><b>All other files have been moved to the new location. You will need to handle the remaining conflicts manually.</b></span>"
  fi
}

create_dir() {
  # A simple function that creates a directory checking if is still there while logging the activity
  # If -d it will delete it prior the creation

  if [[ "$1" == "-d" ]]; then
    shift
    if [[ -e "$1" ]]; then
      rm -rf "$1" # Forcefully delete the directory
      log d "Found \"$1\", deleting it."
    fi
  fi

  if [[ -z "$1" ]]; then
    log e "No directory specified for creation"
    return 1
  fi

  if [[ ! -d "$1" ]]; then
    mkdir -p "$1"
    log d "Created directory: $1"
  else
    log d "Directory \"$1\" already exists, skipping."
  fi
}

download_file() {
  # Function to download file from the Internet, with Zenity progress bar
  # USAGE: download_file $source_url $file_dest $file_name
  # source_url is the location the file is downloaded from
  # file_dest is the destination the file should be in the filesystem, needs filename included!
  # file_name is a user-readable file name or description to be put in the Zenity dialog
  local source="$1"
  local dest="$2"
  local name="$3"

  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  rd_zenity --progress \
    --title="Downloading File" \
    --text="Downloading <span foreground='$purple'><b>$name</b></span>..." \
    --pulsate \
    --auto-close < "$progress_pipe" &
  local zenity_pid=$!

  local progress_fd
  exec {progress_fd}>"$progress_pipe"

  curl --silent --location --output "$dest" "$source"

  echo "100" >&$progress_fd

  exec {progress_fd}>&-
  wait "$zenity_pid" 2>/dev/null
  rm -f "$progress_pipe"  
}

conf_read() {
  # Read the RetroDECK JSON config file and load version, paths, options, and component paths into global variables.
  # USAGE: conf_read

  while IFS=$'\t' read -r name value; do
    [[ -z "$name" ]] && continue
    declare -g "$name=$value"
    export "$name"
  done < <(jq -r '
    ({ version: .version }
    + (.paths   // {})
    + (.options // {})
    + (reduce (.component_paths // {} | to_entries[] | .value | to_entries[]) as $entry
        ({}; . + {($entry.key): ($entry.value | tostring)}))
    )
    | to_entries[]
    | [.key, (.value | tostring)]
    | @tsv
  ' "$rd_conf")

  if [[ -n "$rd_logging_override" ]]; then
    rd_logging_level="$rd_logging_override"
    export rd_logging_level
  fi

  log d "retrodeck.json read and loaded"
}

conf_write() {
  # DEPRECATED: Remove when all users are running 0.11.0+
  # Write current in-memory values for version, paths, and options back to the RetroDECK JSON config file.
  # USAGE: conf_write

  local tmp jq_args=() filter

  jq_args+=(--arg version "$version")
  filter='.version = $version'

  while read -r setting_name; do
    [[ -z "$setting_name" ]] && continue
    local setting_value="${!setting_name}"
    jq_args+=(--arg "$setting_name" "$setting_value")
    filter+=" | .paths.$setting_name = \$$setting_name"
  done < <(jq -r '(.paths // {}) | keys[]' "$rd_conf")

  while read -r setting_name; do
    [[ -z "$setting_name" ]] && continue
    local setting_value="${!setting_name}"
    jq_args+=(--arg "$setting_name" "$setting_value")
    filter+=" | .options.$setting_name = \$$setting_name"
  done < <(jq -r '(.options // {}) | keys[]' "$rd_conf")

  tmp=$(mktemp)
  jq "${jq_args[@]}" "$filter" "$rd_conf" > "$tmp" && mv "$tmp" "$rd_conf"

  log d "retrodeck.json written"
}

dir_prep() {
  # Create a symlink at a specified location pointing to a real directory, merging any existing data.
  # If conflicting files exist during the merge, they are preserved in a lost+found directory.
  # USAGE: dir_prep "$real_dir" "$symlink_location"

  if [[ -z "$1" || -z "$2" ]]; then
    log e "dir_prep requires both a real directory and symlink location"
    return 1
  fi

  local real symlink
  real=$(realpath -s "$1")
  symlink=$(realpath -s "$2")

  log d "Preparing directory: real=$real symlink=$symlink"

  if [[ -L "$symlink" ]]; then
    log d "$symlink is already a symlink, unlinking"
    unlink "$symlink"
  fi

  local staged_dir=""
  if [[ -d "$symlink" ]]; then
    staged_dir=$(mktemp -d "${symlink}.merging.XXXXXX" 2>/dev/null) || staged_dir=$(mktemp -d)
    log d "$symlink is an existing directory, staging as $staged_dir"
    mv -f "$symlink" "$staged_dir/contents"
  fi

  if [[ -L "$real" ]]; then
    log d "$real is already a symlink, unlinking"
    unlink "$real"
  fi

  if [[ ! -d "$real" ]]; then
    log d "$real not found, creating"
    create_dir "$real"
  fi

  create_dir "$(dirname "$symlink")"
  ln -svf "$real" "$symlink"
  log d "Linked $symlink -> $real"

  if [[ -n "$staged_dir" && -d "$staged_dir/contents" ]]; then
    # Merge non-conflicting files into real, skipping any that already exist
    rsync -a --ignore-existing "$staged_dir/contents/" "$real/"

    # Remove successfully merged files, leaving only conflicts behind
    rsync -a --ignore-existing --delete "$real/" "$staged_dir/contents/" 2>/dev/null

    # Anything remaining in staged is a conflict
    if [[ -n "$(find "$staged_dir/contents" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
      local lost_found="$real/lost_and_found"
      create_dir "$lost_found"
      rsync -a "$staged_dir/contents/" "$lost_found/"
      log w "Conflicting files preserved in $lost_found"
    fi

    rm -rf "$staged_dir"
    log d "Merge complete"
  fi

  log i "$symlink is now linked to $real"
}

finit() {
  # First-time initialization and setup of RetroDECK.
  # Guides the user through storage location selection and optional component setup.
  # USAGE: finit

  log i "Executing finit"

  local finit_dest_choice
  local path_choice

  finit_dest_choice=$(configurator_destination_choice_dialog "RetroDECK data" \
    "<b>Welcome to RetroDECKs first-time setup!</b>\n\nRead each prompt carefully during installation so everything is configured correctly.\n\nChoose where RetroDECK should store its data.\n\nA data folder named <span foreground='$purple'><b>retrodeck</b></span> will be created at the location you choose.\n\nThis folder will hold all of your important files:\n\n<span foreground='$purple'><b>ROMs and Games \nBIOS and Firmware \nGame Saves \nArt Data \nEtc...</b></span>.")

  case "${finit_dest_choice:-}" in

    "Quit" | "Back" | "")
      log i "User closed the window or chose to quit"
      rm -f "$rd_conf"
      exit 2
      ;;

    "Internal Storage" | "Home Directory")
      log i "Internal selected"
      set_setting_value "$rd_conf" "rd_home_path" "$HOME/retrodeck" "retrodeck" "paths"
      if [[ -L "$rd_home_path" ]]; then
        unlink "$rd_home_path"
      fi
      ;;

    "SD Card")
      log i "SD Card selected"
      local -a external_devices=()

      while read -r size device_path; do
        local device_name
        device_name=$(basename "$device_path")
        log d "External device $device_path found"
        external_devices+=("$device_name" "$size" "$device_path")
      done < <(df --output=size,target -h | grep "/run/media/" | awk '{$1=$1;print}')

      if [[ ${#external_devices[@]} -gt 0 ]]; then
        configurator_generic_dialog "RetroDeck Installation - SD Card" \
          "One or more external storage devices have been detected.\n\nPlease select the device where you would like to create the <span foreground='$purple'><b>retrodeck</b></span> data folder."
        path_choice=$(rd_zenity --list --title="RetroDECK Configurator - USB Migration Tool" --cancel-label="Back" \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
          --hide-column=3 --print-column=3 \
          --column "Device Name" \
          --column "Device Size" \
          --column "path" \
          "${external_devices[@]}")

        if [[ ! -n "$path_choice" ]]; then
          log i "User closed the window or chose to quit"
          rm -f "$rd_conf"
          exit 2
        fi
      else
        log e "No external storage detected"
        rd_zenity --error --no-wrap \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK" \
          --ok-label "Browse" \
          --text="No external drives were detected.\n\nPlease select the device where you would like to create the <span foreground='$purple'><b>retrodeck</b></span> data folder."
        if path_choice="$(directory_browse "SD card location")"; then
          log i "User closed the window or chose to quit"
          rm -f "$rd_conf"
          exit 2
        fi
      fi

      if [[ ! -w "$path_choice" ]]; then
        log e "SD card found but not writable"
        rd_zenity --error --no-wrap \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK" \
          --ok-label "Quit" \
          --text="SD card detected, but it cannot be written to.\n\nThis often occurs when the card was formatted on a PC.\n\nWhat to do:\n\nSwitch the Steam Deck to <span foreground='$purple'><b>Game Mode</b></span>.\nSettings > System > Format SD Card\n\nRun RetroDECK again."
        rm -f "$rd_conf"
        log i "Now quitting"
        quit_retrodeck
      else
        set_setting_value "$rd_conf" "rd_home_path" "$path_choice/retrodeck" "retrodeck" "paths"
      fi
      ;;

    "Custom Location")
      log i "Custom Location selected"
      rd_zenity --info --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK" \
        --ok-label "Browse" \
        --text="Choose a location for the <span foreground='$purple'><b>retrodeck</b></span> data folder."
      if path_choice="$(directory_browse "custom storage location")"; then
        set_setting_value "$rd_conf" "rd_home_path" "$path_choice/retrodeck" "retrodeck" "paths"
      else
        log i "User closed the window or chose to quit"
        rm -f "$rd_conf"
        exit 2
      fi
      ;;

  esac

  log i "\"retrodeck\" folder will be located in \"$rd_home_path\""

  rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK Initial Install - Start" \
    --text="RetroDECK is now going to install the required files.\nWhen the installation finishes, RetroDECK will launch automatically.\n\n<span foreground='$purple'><b>This may take up to a minute or two</b></span>\n\nPress <span foreground='$purple'><b>OK</b></span> to continue."

  # Set up progress pipe for zenity
  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --pulsate --no-cancel --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK: Installing" \
    --text="RetroDECK is completing its initial setup.\n\nPlease check for any background <span foreground='$purple'><b>windows or pop-ups</b></span> that may require your attention.\n\n<span foreground='$purple'><b>Please wait while the setup process completes...</b></span>" \
    < "$progress_pipe" &
  local zenity_pid=$!

  # Open the pipe for writing
  local progress_fd
  exec {progress_fd}>"$progress_pipe"

  echo "# Building component manifest cache..." >&$progress_fd
  build_component_manifest_cache

  # Set up framework paths and write initial config
  echo "# Setting up RetroDECK core..." >&$progress_fd
  prepare_component "reset" "retrodeck"

  echo "# Initializing component paths in main config..." >&$progress_fd
  init_all_component_paths
  conf_read

  echo "# Loading component functions..." >&$progress_fd
  source_component_functions

  echo "# Initializing component settings in main config..." >&$progress_fd
  reset_component_options "all"

  echo "# Setting up components for the first time..." >&$progress_fd
  prepare_component "reset" "all-installed"

  echo "# Applying presets..." >&$progress_fd
  update_component_presets

  echo "# Deploying helper files..." >&$progress_fd
  deploy_helper_files

  # Gather finit options from component manifests
  local -a finit_choices=()
  
  # Get user decisions on finit optional actions
  while IFS= read -r finit_entry; do
    [[ -z "$finit_entry" ]] && continue
    local option_dialog option_action
    IFS=$'\t' read -r option_dialog option_action < <(jq -r '[.dialog, .action] | @tsv' <<< "$finit_entry")
    if launch_command "$option_dialog"; then
      finit_choices+=("$option_action")
    fi
  done < <(jq -c --slurpfile manifests "$component_manifest_cache_file" '
    [$manifests[0][] | .manifest | .. | objects | select(has("finit_options")) | .finit_options[]] | .[]
  ' <<< 'null')

  # Perform any optional finit actions the user agreed to
  if [[ ${#finit_choices[@]} -gt 0 ]]; then
    local total_choices=${#finit_choices[@]}
    local choice_idx=0
    for choice in "${finit_choices[@]}"; do
      choice_idx=$((choice_idx + 1))
      local progress=$((70 + (30 * choice_idx / total_choices)))
      echo "$progress" >&$progress_fd
      echo "# Processing: $choice..." >&$progress_fd
      log d "Processing finit user choice $choice"
      launch_command "$choice"
    done
  else
    echo "100" >&$progress_fd
  fi

  # Close the pipe and clean up
  exec {progress_fd}>&-
  wait "$zenity_pid" 2>/dev/null
  rm -f "$progress_pipe"

  rd_zenity --question --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --ok-label="Start RetroDECK" \
    --cancel-label="Return to Desktop" \
    --title "RetroDECK Initial Setup - Complete" \
    --text="RetroDECK initial setup is Complete!\n\nEither <span foreground='$purple'><b>Start RetroDECK</b></span> or <span foreground='$purple'><b>Return to Desktop</b></span>.\n\nPlace your <span foreground='$purple'><b>Game Files</b></span> in the following directory:\n\n<span foreground='$purple'><b>$rd_home_path/roms\n\n</b></span>Place your <span foreground='$purple'><b>BIOS and Firmware Files</b></span> in the following directory:\n\n<span foreground='$purple'><b>$rd_home_path/bios</b></span>\n\nTIP: Check out the <span foreground='$purple'><b>RetroDECK Wiki and Website</b></span>\n\nThey contain detailed guides and tips on getting the most out of RetroDECK.\n\nHave a fantastic time!\n\nRetroDECK Team"

  if [[ $? -eq 1 ]]; then
    quit_retrodeck
  fi
}

quit_retrodeck() {
  log i "See you next time"
  
  prepare_component "shutdown" "all"
  
  exit
}

start_retrodeck() {
  log i "Starting RetroDECK v$version"

  prepare_component "startup" "all"
}

convert_to_markdown() {
  # Function to convert XML tags to Markdown
  local xml_content=$(cat "$1")
  local output_file="$1.md"

  # Convert main tags
  echo "$xml_content" | \
    sed -e 's|<p>\(.*\)</p>|## \1|g' \
      -e 's|<ul>||g' \
      -e 's|</ul>||g' \
      -e 's|<h1>\(.*\)</h1>|# \1|g' \
      -e 's|<li>\(.*\)</li>|- \1|g' \
      -e 's|<description>||g' \
      -e 's|</description>||g' \
      -e '/<[^>]*>/d' > "$output_file" # Remove any other XML tags and output to .md file
}

repair_paths() {
  # Verify that all folders defined in the [paths] and [component_paths] sections of retrodeck.json exist.
  # If a folder doesn't exist at its configured location, the user is prompted to browse to its new location.
  # USAGE: repair_paths
  
  local invalid_path_found="false"
  local section path_name path_value new_path
  log i "Checking that all RetroDECK paths are valid"

  while IFS=$'\t' read -r section path_name path_value; do
    if [[ -d "$path_value" ]]; then
      continue
    fi

    log i "$path_name does not exist as defined, having user locate it manually"
    configurator_generic_dialog "RetroDECK Configurator - Path Repair" \
      "The RetroDECK <span foreground='$purple'><b>$path_name</b></span> was not found in the expected location.\nThis may occur if the folder was moved manually.\n\nPlease browse to the current location of the <span foreground='$purple'><b>$path_name</b></span>."

    if new_path=$(directory_browse "RetroDECK $path_name location"); then
      set_setting_value "$rd_conf" "$path_name" "$new_path" "retrodeck" "$section"
      invalid_path_found="true"
    else
      configurator_generic_dialog "RetroDECK Configurator - Path Repair" "No path for $path_name chosen, cannot repair."
    fi
  done < <(jq -r '
    (
      (.paths // {})
      | to_entries[]
      | select(.key | test("^(rd_home_path|sdcard)$") | not)
      | ["paths", .key, .value]
    ),
    (
      (.component_paths // {})
      | to_entries[]
      | .key as $component
      | .value
      | to_entries[]
      | ["component_paths." + $component, .key, .value]
    )
    | @tsv
  ' "$rd_conf")

  if [[ "$invalid_path_found" == "true" ]]; then
    log i "One or more invalid paths repaired, fixing internal RetroDECK structures"
    prepare_component "postmove" "all"
    configurator_generic_dialog "RetroDECK Configurator - Path Repair" "<span foreground='$purple'><b>One or more incorrectly configured paths were repaired.</b></span>"
  else
    log i "All folders were found at their expected locations"
    configurator_generic_dialog "RetroDECK Configurator - Path Repair" "<span foreground='$purple'><b>All RetroDECK folders were found at their expected locations.</b></span>"
  fi
}

update_rd_conf() {
  # Update the retrodeck.json file with any new settings from the shipped defaults file.
  # New sections and settings are added with their default values. Existing settings are not modified.
  # New settings in the "paths" section have their base path rewritten to match the user's actual rd_home_path.
  # USAGE: update_rd_conf

  local tmp
  tmp=$(mktemp)

  jq -s '
    .[0] as $current |
    .[1] as $defaults |
    ($current.paths.rd_home_path // $defaults.paths.rd_home_path) as $actual_home |
    ($defaults.paths.rd_home_path) as $default_home |
    reduce ($defaults | to_entries[] | select(.key != "version")) as $section (
      $current;
      if has($section.key) then
        .[$section.key] = (
          ($section.value // {}) as $default_settings |
          .[$section.key] as $current_settings |
          reduce ($default_settings | to_entries[]) as $setting (
            $current_settings;
            if has($setting.key) then .
            else
              . + {($setting.key): (
                if $section.key == "paths" and ($setting.value | type) == "string" and ($setting.value | startswith($default_home)) then
                  ($setting.value | sub($default_home; $actual_home))
                else
                  $setting.value
                end
              )}
            end
          )
        )
      else
        if $section.key == "paths" then
          . + {($section.key): (
            $section.value | with_entries(
              if (.value | type) == "string" and (.value | startswith($default_home)) then
                .value |= sub($default_home; $actual_home)
              else . end
            )
          )}
        else
          . + {($section.key): $section.value}
        end
      end
    )
  ' "$rd_conf" "$rd_defaults" > "$tmp" && mv "$tmp" "$rd_conf"

  log d "retrodeck.json updated with any new default settings"
}

merge_directories() {
  # Create a merged directory combining files from multiple source directories using symlinks.
  # Each run ensures the merged directory is up to date, adding and removing symlinks as needed.
  # Later source directories take priority over earlier ones for conflicting paths.
  # USAGE: merge_directories "$merged_dir" "$source_dir_1" "$source_dir_2" ("$more_source_dirs")
  
  if [[ $# -lt 2 ]]; then
    log e "Usage: merge_directories merged_dir source_dir1 [source_dir2...]"
    return 1
  fi

  local merged_dir="$1"
  shift
  local source_dirs=("$@")

  mkdir -p "$merged_dir"
  log i "Merging ${#source_dirs[@]} locations into $merged_dir"

  # Build directory structure from all sources
  for source_dir in "${source_dirs[@]}"; do
    if [[ ! -d "$source_dir" ]]; then
      log d "Source directory $source_dir doesn't exist, skipping"
      continue
    fi
    while IFS= read -r -d '' dir; do
      local relative_path
      relative_path=$(realpath --relative-to="$source_dir" "$dir")
      [[ "$relative_path" == "." ]] && continue
      mkdir -p "$merged_dir/$relative_path"
    done < <(find "$source_dir" -type d -print0)
  done

  # Track valid merged paths for stale symlink detection
  local -A valid_files=()

  log i "Creating symlinks for files..."
  for source_dir in "${source_dirs[@]}"; do
    if [[ ! -d "$source_dir" ]]; then
      log d "$source_dir does not exist, skipping"
      continue
    fi
    while IFS= read -r -d '' file; do
      local relative_path merged_file
      relative_path=$(realpath --relative-to="$source_dir" "$file")
      merged_file="$merged_dir/$relative_path"
      valid_files["$merged_file"]=1

      if [[ -L "$merged_file" ]]; then
        local target
        target=$(readlink "$merged_file")
        if [[ "$target" == "$file" ]]; then
          continue
        fi
        if [[ -f "$target" ]]; then
          log d "Keeping existing symlink at $merged_file (target $target still exists)"
          continue
        fi
        log d "Removing stale symlink $merged_file"
        rm "$merged_file"
      elif [[ -f "$merged_file" ]]; then
        log w "Real file exists at $merged_file, skipping symlink creation"
        continue
      fi

      mkdir -p "$(dirname "$merged_file")"
      log d "Creating symlink: $merged_file -> $file"
      ln -sf "$file" "$merged_file"
    done < <(find "$source_dir" -type f -print0)
  done

  log i "Removing stale symlinks..."
  while IFS= read -r -d '' symlink; do
    if [[ -z "${valid_files[$symlink]+x}" ]] && [[ ! -e "$(readlink "$symlink")" ]]; then
      log d "Removing stale symlink: $symlink"
      rm "$symlink"
    fi
  done < <(find "$merged_dir" -type l -print0)

  # Clean up empty directories left behind
  find "$merged_dir" -mindepth 1 -type d -empty -delete 2>/dev/null

  log i "Merge complete"
}

launch_command() {
  input="$1"
  set -- $input
  # Get the function name and remove it from the list of arguments
  function_name="$1"
  shift

  # Check if the function exists
  if ! declare -f "$function_name" >/dev/null 2>&1; then
    log e "Function \'$function_name\' not found"
    exit 1
  fi

  # Call the function with any remaining arguments
  "$function_name" "$@"
}

prune_empty_parents() {
  # Remove empty directories walking up from start_dir to stop_dir (inclusive).
  # USAGE: prune_empty_parents "$start_dir" "$stop_dir"

  local current="$1"
  local stop="$2"

  while [[ -d "$current" && -z "$(ls -A "$current" 2>/dev/null)" ]]; do
    log d "Directory $current is empty, removing"
    rmdir "$current"
    [[ "$current" == "$stop" ]] && break
    current=$(dirname "$current")
    # Don't go above the stop directory
    [[ "${current}" != "${stop}"* ]] && break
  done
}

finit_default_yes() {
  log i "Defaulting setting "$@" enabled."
  return 0
}

handle_folder_iconsets() {
  local iconset="$1"

  if [[ ! "$iconset" == "false" ]]; then
    if [[ -d "$folder_iconsets_dir/$iconset" ]]; then
      while read -r icon; do
        local icon_relative_path="${icon#$folder_iconsets_dir/$iconset/}"
        local icon_relative_path="${icon_relative_path%.ico}"
        local icon_relative_root="${icon_relative_path%%/*}"
        local path_var_name="${icon_relative_root}_path"
        local path_name=""

        if [[ "$icon_relative_path" =~ (sync) ]]; then # If the icon is for a hidden folder, add the leading dot temporarily for searching
          icon_relative_path=".${icon_relative_path}"
        fi

        if [[ -v "$path_var_name" ]]; then
          path_name="${!path_var_name}"
          if [[ ! "$icon_relative_path" == "$icon_relative_root" ]]; then
            path_name="$path_name/${icon_relative_path#$icon_relative_root/}"
          fi
          if [[ ! -d "$path_name" ]]; then
            log w "Path for icon $icon could not be found, skipping..."
            continue
          fi
        elif [[ -d "$rd_home_path/$icon_relative_path" ]]; then
          path_name="$rd_home_path/$icon_relative_path"
          icon_relative_path="${icon_relative_path#.}" # Remove leading dot from actual icon name reference
        else
          log w "Path for icon $icon could not be found, skipping..."
          continue
        fi

        log d "Creating file $path_name/.directory"
        echo '[Desktop Entry]' > "$path_name/.directory"
        echo "Icon=$folder_iconsets_dir/$iconset/$icon_relative_path.ico" >> "$path_name/.directory"
      done < <(find "$folder_iconsets_dir/$iconset" -maxdepth 2 -type f -iname "*.ico")
      set_setting_value "$rd_conf" "iconset" "$iconset" retrodeck "options"
    else
      configurator_generic_dialog "RetroDeck Configurator - Toggle Folder Iconsets" "The chosen iconset <span foreground='$purple'><b>$iconset</b></span> could not be found in the RetroDECK assets."
      return 1
    fi
  else
    while read -r path; do
      find -L "$path" -maxdepth 2 -type f -iname '.directory' -exec rm {} \;
    done < <(jq -r 'del(.paths.downloaded_media_path, .paths.themes_path, .paths.sdcard) | .paths[]' "$rd_conf")
    set_setting_value "$rd_conf" "iconset" "false" retrodeck "options"
  fi
}

url_encode() {
  # URL-encode a string, escaping all special characters for safe use in URLs and form data.
  # USAGE: url_encode "$string"

  jq -sRr @uri <<< "$1"
}

set_build_options() {
  # If this is a pre-production build
  if [[ ! "$hard_version" =~ ^[0-9] && ! "$hard_version" =~ ^(epicure) ]]; then
    log d "Pre-production version $hard_version detected, setting debugging values in retrodeck.json"
    set_setting_value "$rd_conf" "power_user_warning" "false" retrodeck "options"
    set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    set_setting_value "$rd_conf" "developer_options" "true" retrodeck "options"
    set_setting_value "$rd_conf" "rd_logging_level" "debug" retrodeck "options"
  else
    log d "Production version $hard_version detected, resetting debugging values in retrodeck.json"
    set_setting_value "$rd_conf" "power_user_warning" "true" retrodeck "options"
    set_setting_value "$rd_conf" "update_repo" "RetroDECK" retrodeck "options"
    set_setting_value "$rd_conf" "update_check" "false" retrodeck "options"
    set_setting_value "$rd_conf" "update_ignore" "" retrodeck "options"
    set_setting_value "$rd_conf" "developer_options" "false" retrodeck "options"
    set_setting_value "$rd_conf" "rd_logging_level" "info" retrodeck "options"
  fi
}

get_external_usb_devices() {
  # USAGE: get_external_usb_devices "array_name" ["--with-import-folder"]

  declare -n devices="$1"
  local filter="$2"

  devices=()

  while read -r size device_path; do
    if [[ "$filter" == "--with-import-folder" && ! -d "$device_path/RetroDECK Import" ]]; then
      continue
    fi
    local device_name
    device_name=$(basename "$device_path")
    devices+=("$device_name" "$size" "$device_path")
  done < <(df --output=size,target -h | grep "/run/media/" | grep -v "$sdcard" | awk '{$1=$1;print}')
}

detect_host() {
  # Detect system information: GPU
  system_gpu_info=""
  for drmdev in /sys/class/drm/*; do
    devdir="$drmdev/device"
    if [[ -d "$devdir" ]]; then
      vendor_id=""
      device_id=""
      driver=""
      [[ -r "$devdir/vendor" ]] && vendor_id=$(cat "$devdir/vendor" 2>/dev/null || true)
      [[ -r "$devdir/device" ]] && device_id=$(cat "$devdir/device" 2>/dev/null || true)
      [[ -r "$devdir/uevent" ]] && driver=$(grep -i '^DRIVER=' "$devdir/uevent" 2>/dev/null | cut -d'=' -f2 || true)
      if [[ -n "$driver" ]]; then
        system_gpu_info="$driver"
        [[ -n "$vendor_id" || -n "$device_id" ]] && system_gpu_info+=" (${vendor_id:-unknown}:${device_id:-unknown})"
        break
      fi
    fi
  done
  if [[ -z "$system_gpu_info" ]]; then
    for drmdev in /sys/class/drm/*/device/modalias; do
      if [[ -r "$drmdev" ]]; then
        modalias=$(cat "$drmdev" 2>/dev/null || true)
        if [[ -n "$modalias" ]]; then
          system_gpu_info="$modalias"
          break
        fi
      fi
    done
  fi
  : "${system_gpu_info:=unknown}"

  # Detect system information: Display
  system_display_width=""
  system_display_height=""
  drm_modes=$(grep -h --binary-files=without-match -oE '[0-9]+x[0-9]+' /sys/class/drm/*/modes 2>/dev/null || true)
  if [[ -n "$drm_modes" ]]; then
    mode=$(echo "$drm_modes" | head -n1)
    system_display_width="${mode%%x*}"
    system_display_height="${mode##*x}"
  fi

  # Check for Steam Deck native resolution
  if [[ -n "$system_display_width" && -n "$system_display_height" && "$system_display_width" -eq 1280 && "$system_display_height" -eq 800 ]]; then
    sd_native_resolution=true
  else
    sd_native_resolution=false
  fi

  # Detect system information: OS and CPU
  system_distro_name=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"' || true)
  system_distro_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"' || true)
  system_cpu_info=$(grep -m1 'model name' /proc/cpuinfo | cut -d':' -f2 | xargs || true)
  system_cpu_cores=$(nproc)
  system_cpu_max_threads=$(( system_cpu_cores / 2 ))

  export system_gpu_info system_display_width system_display_height sd_native_resolution
  export system_distro_name system_distro_version system_cpu_info system_cpu_cores system_cpu_max_threads

  log d "Debug mode enabled"
  log i "Initializing RetroDECK"
  log i "Running on $XDG_SESSION_DESKTOP, $XDG_SESSION_TYPE, $system_distro_name $system_distro_version"
  [[ -n "${container:-}" ]] && log i "Running inside $container environment"
  log i "CPU: Using $system_cpu_info, $system_cpu_max_threads out of $system_cpu_cores available CPU cores for multi-threaded operations"
  log i "GPU: $system_gpu_info"
  log i "Resolution: ${system_display_width:-unknown} x ${system_display_height:-unknown}"
  [[ "$sd_native_resolution" == true ]] && log i "Steam Deck native resolution detected"
}
