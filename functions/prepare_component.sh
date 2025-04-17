#!/bin/bash

prepare_component() {
  # This function will perform one of several actions on one or more components
  # The actions currently include "reset" and "postmove"
  # The "reset" action will initialize the component
  # The "postmove" action will update the component settings after one or more RetroDECK folders were moved
  # An component can be called by name, by parent folder name in the $XDG_CONFIG_HOME root or use the option "all" to perform the action on all components equally
  # USAGE: prepare_component "$action" "$component" "$call_source(optional)"

  if [[ "$1" == "--factory-reset" ]]; then
    log i "User requested full RetroDECK reset"
    rm -f "$lockfile" && log d "Lockfile removed"
    retrodeck
  fi

  action="$1"
  component="$2"
  call_source="$3"
  component_found="false"

  log d "component: $component"

  if [[ -z "$component" ]]; then
    echo "No components or action specified. Exiting."
    exit 1
  fi
  log d "Preparing component: \"$component\", action: \"$action\""

  if [[ "$component" == "retrodeck" ]]; then
    log i "--------------------------------"
    log i "Preparing RetroDECK framework"
    log i "--------------------------------"
    component_found="true"
    if [[ "$action" == "reset" ]]; then # Update the paths of all folders in retrodeck.cfg and create them
      while read -r config_line; do
        local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
        if [[ ! $current_setting_name =~ (rdhome|sdcard) ]]; then # Ignore these locations
          local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
          log d "Red setting: $current_setting_name=$current_setting_value"
          # Extract the part of the setting value after "retrodeck/"
          local relative_path="${current_setting_value#*retrodeck/}"
          # Construct the new setting value
          local new_setting_value="$rdhome/$relative_path"
          log d "New setting: $current_setting_name=$new_setting_value"
          # Declare the global variable with the new setting value
          declare -g "$current_setting_name=$new_setting_value"
          log d "Setting: $current_setting_name=$current_setting_value"
          if [[ ! $current_setting_name == "logs_folder" ]]; then # Don't create a logs folder normally, we want to maintain the current files exactly to not lose early-install logs.
            create_dir "$new_setting_value"
          else # Log folder-specific actions
            mv "$rd_logs_folder" "$logs_folder" # Move existing logs folder from internal to userland
            ln -sf "$logs_folder" "$rd_logs_folder" # Link userland logs folder back to statically-written location
            log d "Logs folder moved to $logs_folder and linked back to $rd_logs_folder"
          fi
        fi
      done < <(grep -v '^\s*$' "$rd_conf" | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f')
    fi
    if [[ "$action" == "postmove" ]]; then # Update the paths of any folders that came with the retrodeck folder during a move
      while read -r config_line; do
        local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
        if [[ ! $current_setting_name =~ (rdhome|sdcard) ]]; then # Ignore these locations
          local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
          if [[ -d "$rdhome/${current_setting_value#*retrodeck/}" ]]; then # If the folder exists at the new ~/retrodeck location
              declare -g "$current_setting_name=$rdhome/${current_setting_value#*retrodeck/}"
          fi
        fi
      done < <(grep -v '^\s*$' "$rd_conf" | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f')
      dir_prep "$logs_folder" "$rd_logs_folder"
    fi
  fi

  if [[ "$component" =~ ^(steam-rom-manager|steamrommanager|all)$ ]]; then
    component_found="true"
    log i "-----------------------------"
    log i "Preparing Steam ROM Manager"
    log i "-----------------------------"

    create_dir -d "$srm_userdata"
    cp -fv "$config/steam-rom-manager/"*.json "$srm_userdata"
    cp -fvr "$config/steam-rom-manager/manifests" "$srm_userdata"

    log i "Updating steamDirectory and romDirectory lines in $srm_userdata/userSettings.json"
    jq '.environmentVariables.steamDirectory = "'"$HOME"'/.steam/steam"' "$srm_userdata/userSettings.json" > "$srm_userdata/tmp.json" && mv -f "$srm_userdata/tmp.json" "$srm_userdata/userSettings.json"
    jq '.environmentVariables.romsDirectory = "'"$rdhome"'/.sync"' "$srm_userdata/userSettings.json" > "$srm_userdata/tmp.json" && mv -f "$srm_userdata/tmp.json" "$srm_userdata/userSettings.json"

    get_steam_user
  fi

  # Read install components framework.sh files
  while IFS= read -r prepare_component_file; do
    log d "Found component file $prepare_component_file"
    source "$prepare_component_file"
  done < <(find "$RD_MODULES" -type f -name "framework.sh")

  if [[ $component_found == "false" ]]; then
    log e "Supplied component $component not found, not resetting"
  else
    # Update presets for all components after any reset or move
    if [[ ! "$component" == "retrodeck" ]]; then
      build_retrodeck_current_presets
    fi
  fi
}
