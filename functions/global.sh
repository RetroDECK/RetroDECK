#!/bin/bash

# This file is containing some global function needed for the script such as the config file tools

# pathing the retrodeck components provided libraries
# now disabled as we are importing everything in /app/lib. In case we are breaking something we need to restore this approach
# export LD_LIBRARY_PATH="/app/retrodeck/lib:/app/retrodeck/lib/debug:/app/retrodeck/lib/pkgconfig:$LD_LIBRARY_PATH"

: "${logging_level:=info}"                  # Initializing the log level variable if not already valued, this will be actually red later from the config file                                                 
rd_logs_folder="$XDG_CONFIG_HOME/retrodeck/logs" # Static location to write all RetroDECK-related logs
if [ -h "$rd_logs_folder" ]; then # Check if internal logging folder is already a symlink
  if [ ! -e "$rd_logs_folder" ]; then # Check if internal logging folder symlink is broken
    unlink "$rd_logs_folder" # Remove broken symlink so the folder is recreated when sourcing logger.sh
  fi
fi
source /app/libexec/logger.sh
rotate_logs

# OS detection
width=$(grep -oP '\d+(?=x)' /sys/class/graphics/fb0/modes)
height=$(grep -oP '(?<=x)\d+' /sys/class/graphics/fb0/modes)
if [[ $width -ne 1280 ]] || [[ $height -ne 800 ]]; then
  native_resolution=false
else
  native_resolution=true
fi
distro_name=$(flatpak-spawn --host grep '^ID=' /etc/os-release | cut -d'=' -f2)
distro_version=$(flatpak-spawn --host grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2)
gpu_info=$(flatpak-spawn --host lspci | grep -i 'vga\|3d\|2d')
cpu_cores=$(nproc)
max_threads=$(echo $(($(nproc) / 2)))

log d "Debug mode enabled"
log i "Initializing RetroDECK"
log i "Running on $XDG_SESSION_DESKTOP, $XDG_SESSION_TYPE, $distro_name $distro_version"
if [[ -n $container ]]; then
  log i "Running inside $container environment"
fi
log i "GPU: $gpu_info"
log i "Resolution: $width x $height"
if [[ $native_resolution == true ]]; then
  log i "Steam Deck native resolution detected"
fi
log i "CPU: Using $max_threads out of $cpu_cores available CPU cores for multi-threaded operations"

for file in /app/libexec/*.sh; do
  if [[ -f "$file" && ! "$file" == "/app/libexec/global.sh" && ! "$file" == "/app/libexec/post_build_check.sh" ]]; then
    source "$file"
  fi
done

# Base dir for all installed RetroDECK components
rd_components="/app/retrodeck/components"

source_component_functions "retrodeck" # Source this first as future functions will need to know these paths
source_component_functions "internal"
source_component_functions "external"

# Initialize logging location if it doesn't exist, before anything else happens
if [ ! -d "$rd_logs_folder" ]; then
    create_dir "$rd_logs_folder"
fi

# Initialize the API location and required files, if they don't already exist
if [[ ! -d "$rd_api_dir" ]]; then
  create_dir "$rd_api_dir"
fi
if [[ ! -e "$RD_FILE_LOCK" ]]; then
  touch "$RD_FILE_LOCK"
fi

# We moved the lockfile in $XDG_CONFIG_HOME/retrodeck in order to solve issue #53 - Remove in a few versions
if [[ -f "$HOME/retrodeck/.lock" ]]; then
  mv "$HOME/retrodeck/.lock" "$lockfile"
fi

# If there is no config file I initalize the file with the the default values
if [[ ! -f "$rd_conf" ]]; then
  log w "RetroDECK config file not found in $rd_conf"
  log i "Initializing"
  # if we are here means that the we are in a new installation, so the version is valorized with the hardcoded one
  # Initializing the variables
  if [[ -z "$version" ]]; then
    if [[ -f "$lockfile" ]]; then
      if [[ $(cat "$lockfile") == *"0.4."* ]] || [[ $(cat "$lockfile") == *"0.3."* ]] || [[ $(cat "$lockfile") == *"0.2."* ]] || [[ $(cat "$lockfile") == *"0.1."* ]]; then # If the previous version is very out of date, pre-rd_conf
        log d "Running version workaround"
        version=$(cat "$lockfile")
      fi
    else
      version="$hard_version"
    fi
  fi

  # Check if SD card path has changed from SteamOS update
  if [[ ! -d "$default_sd" && "$(ls -A "/run/media/deck/")" ]]; then
    if [[ $(find "/run/media/deck/"* -maxdepth 0 -type d -print | wc -l) -eq 1 ]]; then # If there is only one SD card found in the new SteamOS 3.5 location, assign it as the default
      default_sd="$(find "/run/media/deck/"* -maxdepth 0 -type d -print)"
    else # If the default legacy path cannot be found, and there are multiple entries in the new Steam OS 3.5 SD card path, let the user pick which one to use
      configurator_generic_dialog "RetroDECK Setup" "The SD card was not found in the default location, and multiple drives were detected.\nPlease browse to the location of the desired SD card.\n\nIf you are not using an SD card, please click \"Cancel\"."
      default_sd="$(directory_browse "SD Card Location")"
    fi
  fi

  cp "$rd_defaults" "$rd_conf" # Load default settings file
  set_setting_value "$rd_conf" "version" "$version" retrodeck # Set current version for new installs
  set_setting_value "$rd_conf" "sdcard" "$default_sd" retrodeck "paths" # Set SD card location if default path has changed

  if grep -qF "cooker" <<< "$hard_version" || grep -qF "PR-" <<< "$hard_version"; then # If newly-installed version is a "cooker" or PR build
    set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    set_setting_value "$rd_conf" "developer_options" "true" retrodeck "options"
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

  # Verify rdhome is where it is supposed to be.
  if [[ ! -d "$rdhome" ]]; then
    configurator_generic_dialog "RetroDECK Setup" "The RetroDECK data folder was not found in the expected location.\nThis may happen when SteamOS is updated or if the folder was moved manually.\n\nPlease browse to the current location of the \"retrodeck\" folder."
    new_home_path=$(directory_browse "RetroDECK folder location")
    set_setting_value "$rd_conf" "rdhome" "$new_home_path" retrodeck "paths"
    conf_read
    prepare_component "postmove" "retrodeck"
    prepare_component "postmove" "all"
    conf_write
  fi

  # Static variables dependent on $rd_conf values, need to be set after reading $rd_conf
  multi_user_data_folder="$rdhome/multi-user-data"                                                                      # The default location of multi-user environment profiles
fi

export GLOBAL_SOURCED=true
