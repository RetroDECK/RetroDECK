#!/bin/bash

# This file is containing some global function needed for the script such as the config file tools

# pathing the retrodeck components provided libraries
# now disabled as we are importing everything in /app/lib. In case we are breaking something we need to restore this approach
# export LD_LIBRARY_PATH="/app/retrodeck/lib:/app/retrodeck/lib/debug:/app/retrodeck/lib/pkgconfig:$LD_LIBRARY_PATH"

: "${rd_logging_level:=info}"                  # Initializing the log level variable if not already valued, this will be actually red later from the config file                                                 
rd_xdg_config_logs_path="$XDG_CONFIG_HOME/retrodeck/logs" # Static location to write all RetroDECK-related logs
if [ -h "$rd_xdg_config_logs_path" ]; then # Check if internal logging folder is already a symlink
  if [ ! -e "$rd_xdg_config_logs_path" ]; then # Check if internal logging folder symlink is broken
    unlink "$rd_xdg_config_logs_path" # Remove broken symlink so the folder is recreated when sourcing logger.sh
  fi
fi
set -o allexport # Export all the variables found during sourcing, for use elsewhere
source /app/libexec/logger.sh
set +o allexport # Back to normal, otherwise every assigned variable will get exported through the rest of the run
rotate_logs

# OS detection
system_display_width=$(grep -oP '\d+(?=x)' /sys/class/graphics/fb0/modes)
system_display_height=$(grep -oP '(?<=x)\d+' /sys/class/graphics/fb0/modes)
if [[ $system_display_width -ne 1280 ]] || [[ $system_display_height -ne 800 ]]; then
  sd_native_resolution=false
else
  sd_native_resolution=true
fi
system_distro_name=$(flatpak-spawn --host grep '^ID=' /etc/os-release | cut -d'=' -f2)
system_distro_version=$(flatpak-spawn --host grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2)
system_gpu_info=$(flatpak-spawn --host lspci | grep -i 'vga\|3d\|2d')
system_cpu_info=$(flatpak-spawn --host lscpu | grep 'Model name' | cut -d':' -f2 | xargs) # Get CPU model name
system_cpu_cores=$(nproc)
system_cpu_max_threads=$(echo $(($(nproc) / 2)))

log d "Debug mode enabled"
log i "Initializing RetroDECK"
log i "Running on $XDG_SESSION_DESKTOP, $XDG_SESSION_TYPE, $system_distro_name $system_distro_version"
if [[ -n $container ]]; then
  log i "Running inside $container environment"
fi
log i "CPU: Using $system_cpu_info,$system_cpu_max_threads out of $system_cpu_cores available CPU cores for multi-threaded operations"
log i "GPU: $system_gpu_info"
log i "Resolution: $system_display_width x $system_display_height"
if [[ $sd_native_resolution == true ]]; then
  log i "Steam Deck native resolution detected"
fi

for file in /app/libexec/*.sh; do
  if [[ -f "$file" && ! "$file" == "/app/libexec/global.sh" && ! "$file" == "/app/libexec/post_build_check.sh" ]]; then
    log d "Sourcing $file"
    source "$file"
  fi
done

# Base dir for all installed RetroDECK components
export rd_components="/app/retrodeck/components"
export rd_shared_libs="/app/retrodeck/components/shared-libs"
export rd_shared_libs_kde_path="/app/retrodeck/components/shared-libs/org.kde.Platform"
export rd_shared_libs_gnome_path="/app/retrodeck/components/shared-libs/org.gnome.Platform"
export rd_shared_libs_freedesktop_path="/app/retrodeck/components/shared-libs/org.freedesktop.Platform" 
export runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/retrodeck"

source_component_functions "framework" # Source this first as future functions will need to know these paths

# Initialize logging location if it doesn't exist, before anything else happens
if [ ! -d "$rd_xdg_config_logs_path" ]; then
    log d "Creating RetroDECK logs directory at $rd_xdg_config_logs_path"
    create_dir "$rd_xdg_config_logs_path"
fi

# Initialize the API location and required files, if they don't already exist
if [[ ! -d "$rd_api_dir" ]]; then
  log d "Creating RetroDECK API directory at $rd_api_dir"
  create_dir "$rd_api_dir"
fi
if [[ ! -e "$rd_file_lock" ]]; then
  log d "Creating RetroDECK API lockfile at $rd_file_lock"
  touch "$rd_file_lock" || log e "Failed to create RetroDECK API lockfile at $rd_file_lock"
fi

# We moved the lockfile in $XDG_CONFIG_HOME/retrodeck in order to solve issue #53 - Remove in a few versions
if [[ -f "$HOME/retrodeck/.lock" ]]; then
  mv "$HOME/retrodeck/.lock" "$rd_lockfile"
fi

# To handle crossover to new config file style
if [[ -f "$XDG_CONFIG_HOME/retrodeck/retrodeck.json" ]]; then
  log i "New-style RetroDECK config file found, setting to load"
  rd_conf="$XDG_CONFIG_HOME/retrodeck/retrodeck.json"
fi

# If there is no config file I initalize the file with the the default values
if [[ ! -f "$rd_conf" ]]; then
  log w "RetroDECK config file not found in $rd_conf, initializing with default values"
  # if we are here means that the we are in a new installation, so the version is valorized with the hardcoded one
  # Initializing the variables
  if [[ -z "$version" ]]; then
    if [[ -f "$rd_lockfile" ]]; then
      if [[ $(cat "$rd_lockfile") == *"0.4."* ]] || [[ $(cat "$rd_lockfile") == *"0.3."* ]] || [[ $(cat "$rd_lockfile") == *"0.2."* ]] || [[ $(cat "$rd_lockfile") == *"0.1."* ]]; then # If the previous version is very out of date, pre-rd_conf
        log d "Running version workaround"
        version=$(cat "$rd_lockfile")
      fi
    else
      version="$hard_version"
      log d "Setting version to $version"
    fi
  fi

  # Check if SD card path has changed from SteamOS update
  if [[ ! -d "$sd_sdcard_default_path" && "$(ls -A "/run/media/deck/" 2>/dev/null)" ]]; then
    if [[ $(find "/run/media/deck/"* -maxdepth 0 -type d -print 2>/dev/null | wc -l) -eq 1 ]]; then # If there is only one SD card found in the new SteamOS 3.5 location, assign it as the default
      sd_sdcard_default_path="$(find "/run/media/deck/"* -maxdepth 0 -type d -print 2>/dev/null)"
    else # If the default legacy path cannot be found, and there are multiple entries in the new Steam OS 3.5 SD card path, pick the first one silently
      sd_sdcard_default_path="$(find "/run/media/deck/"* -maxdepth 0 -type d -print 2>/dev/null | head -n 1)"
    fi
  fi

  cp "$rd_defaults" "$rd_conf" # Load default settings file
  set_setting_value "$rd_conf" "version" "$version" retrodeck # Set current version for new installs
  set_setting_value "$rd_conf" "sdcard" "$sd_sdcard_default_path" retrodeck "paths" # Set SD card location if default path has changed

  if grep -qF "cooker" <<< "$hard_version" || grep -qF "PR-" <<< "$hard_version"; then # If newly-installed version is a "cooker" or PR build
    set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    set_setting_value "$rd_conf" "developer_options" "true" retrodeck "options"
    set_setting_value "$rd_conf" "rd_logging_level" "debug" retrodeck "options"
  fi

  log i "Setting config file permissions"
  chmod +rw "$rd_conf"
  log i "RetroDECK config file initialized. Contents:\n\n$(cat "$rd_conf")\n"
  conf_read # Load new variables into memory

else # If the config file is existing i just read the variables
  log i "Loading RetroDECK config file in $rd_conf"

  if grep -qF "cooker" <<< "$hard_version"; then # If newly-installed version is a "cooker" build
    set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    set_setting_value "$rd_conf" "developer_options" "true" retrodeck "options"
  fi

  conf_read

  # Verify rd_home_path is where it is supposed to be.
  if [[ ! -d "$rd_home_path" ]]; then
    configurator_generic_dialog "RetroDECK Setup" "The RetroDECK data folder was not found in the expected location.\nThis may happen when SteamOS is updated or if the folder was moved manually.\n\nPlease browse to the current location of the \"retrodeck\" folder."
    new_home_path=$(directory_browse "RetroDECK folder location")
    set_setting_value "$rd_conf" "rd_home_path" "$new_home_path" retrodeck "paths"
    conf_read
    prepare_component "postmove" "framework"
    prepare_component "postmove" "all"
    conf_write
  fi

  # Static variables dependent on $rd_conf values, need to be set after reading $rd_conf
  multi_user_data_folder="$rd_home_path/multi-user-data"                                                                      # The default location of multi-user environment profiles
fi

# Source other component functions after retrodeck.cfg paths have been read
source_component_functions "internal"
source_component_functions "external"
export GLOBAL_SOURCED=true
