#!/bin/bash

source /app/libexec/cleanup.sh

# Initialize logging
: "${rd_logging_level:=info}"
rd_xdg_config_logs_path="$XDG_CONFIG_HOME/retrodeck/logs"
if [[ -L "$rd_xdg_config_logs_path" && ! -e "$rd_xdg_config_logs_path" ]]; then
  unlink "$rd_xdg_config_logs_path"
fi
if [[ ! -d "$rd_xdg_config_logs_path" ]]; then
  echo "Creating RetroDECK logs directory at $rd_xdg_config_logs_path"
  mkdir -p "$rd_xdg_config_logs_path"
fi
source /app/libexec/logger.sh
export rd_logging_level rd_xdg_config_logs_path
rotate_logs

# Handle early multi-user login override
args=()
for ((i=1; i<=$#; i++)); do
  if [[ "${!i}" == "--user" ]]; then
    next=$((i + 1))
    export multi_user_cli_override="${!next}"
    i=$((i + 1))
  else
    args+=("${!i}")
  fi
done
set -- "${args[@]}"

# Load application static variables
source /app/libexec/static_vars.sh

# Load core libraries
for file in /app/libexec/*.sh; do
  case "$(basename "$file")" in
    cleanup.sh|dyn_vars.sh|global.sh|launcher_functions.sh|logger.sh|static_vars.sh) continue ;;
  esac
  log d "Sourcing $file"
  source "$file"
done
# Load per-session variables
source /app/libexec/dyn_vars.sh

# Detect host details
detect_host

# Source framework functions for early use
source_component_functions "framework"

# Legacy config conversion
if [[ -f "$XDG_CONFIG_HOME/retrodeck/retrodeck.cfg" && ! -f "$XDG_CONFIG_HOME/retrodeck/retrodeck.json" ]]; then
  log i "Old-style RetroDECK config file found, converting"
  source "/app/tools/convert_cfg_to_json.sh"
  if convert_cfg_to_json "$XDG_CONFIG_HOME/retrodeck/retrodeck.cfg" "$XDG_CONFIG_HOME/retrodeck/retrodeck.json"; then
    log i "Conversion successful, backing up legacy file"
    mv "$XDG_CONFIG_HOME/retrodeck/retrodeck.cfg" "$XDG_CONFIG_HOME/retrodeck/retrodeck.bak"
    update_rd_conf
  fi
fi

# Load or initialize config file
if [[ ! -f "$rd_conf" ]]; then
  log w "RetroDECK config file not found in $rd_conf, initializing with default values"

  cp "$rd_defaults" "$rd_conf"
  chmod +rw "$rd_conf"

  conf_read

  if [[ -z "$version" ]]; then
    if [[ -f "$rd_lockfile" ]]; then
      lock_version=$(cat "$rd_lockfile")
      if [[ "$lock_version" == *"0.4."* || "$lock_version" == *"0.3."* || "$lock_version" == *"0.2."* || "$lock_version" == *"0.1."* ]]; then
        log w "Upgrading from very old version, running version workaround using lockfile version $lock_version"
        set_setting_value "$rd_conf" "version" "$lock_version" retrodeck
      fi
    else
      log d "Setting version to $hard_version"
      set_setting_value "$rd_conf" "version" "$hard_version" retrodeck
    fi
  fi

  # Determine SD card path if possible
  if [[ ! -d "$sdcard_default_path" && $(find "/run/media/deck/"* -maxdepth 0 -type d -print 2>/dev/null | wc -l) -eq 1 ]]; then
    sdcard_default_path=$(find "/run/media/deck/"* -maxdepth 0 -type d -print 2>/dev/null | head -n 1)
    log d "sdcard_default_path not found, assigning $sdcard_default_path"
    set_setting_value "$rd_conf" "sdcard" "$sdcard_default_path" retrodeck "paths"
  else
    sdcard_default_path=""
    log d "sdcard_default_path could not be determined, clearing setting value in retrodeck.json"
    set_setting_value "$rd_conf" "sdcard" "$sdcard_default_path" retrodeck "paths"
  fi

  set_build_options

  log i "RetroDECK config file initialized, proceeding to finit"
  
  finit
else
  log i "Loading RetroDECK config file from $rd_conf"

  conf_read

  build_component_manifest_cache

  # If the defined rd_home_path doesn't exist, meaning it may have been moved manually
  if [[ ! -d "$rd_home_path" && ! -L "$rd_home_path" ]]; then
    log e "Defined $rd_home_path does not exist, asking user to locate it manually"
    configurator_generic_dialog "RetroDECK Setup - Warning: No Data Folder Found" \
      "The RetroDECK data folder was not found in the expected location.\nThis may occur after a OS update or if the folder was moved manually.\n\nPlease browse to the current location of the <span foreground='$purple'><b>\"retrodeck\"</b></span> folder."
    if new_home_path=$(directory_browse "RetroDECK folder location"); then
      set_setting_value "$rd_conf" "rd_home_path" "$new_home_path" retrodeck "paths"
      source_component_functions
      prepare_component "postmove" "all"
    else
      log w "User exited the RetroDECK home path repair process."
      quit_retrodeck
    fi
  fi

  set_build_options
fi

# Source component functions for further use
source_component_functions

# Build runtime caches that depend on component functions
build_compression_lookups
