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

# OS detection
# Detect if we're running inside a Flatpak sandbox. When inside Flatpak we
# should avoid using `flatpak-spawn` or calling host-only tools such as `xrandr`.
# We always run inside the Flatpak runtime for the app; avoid calling
# any host-only tools (flatpak-spawn, xrandr, lspci). Use sysfs, drm and
# /proc where possible.

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

# Load static variables and core functions
source /app/libexec/all_vars.sh

for file in /app/libexec/*.sh; do
  case "$(basename "$file")" in
    global.sh|cleanup.sh|logger.sh|all_vars.sh|launcher_functions.sh) continue ;;
  esac
  log d "Sourcing $file"
  source "$file"
done

# Build component manifest cache
build_component_manifest_cache

# Source framework functions for early use
source_component_functions "framework"

# Initialize directories
if [[ ! -d "$rd_api_dir" ]]; then
  log d "Creating RetroDECK API directory at $rd_api_dir"
  create_dir "$rd_api_dir"
fi

# Legacy config conversion
if [[ -f "$XDG_CONFIG_HOME/retrodeck/retrodeck.cfg" && ! -f "$XDG_CONFIG_HOME/retrodeck/retrodeck.json" ]]; then
  log i "Old-style RetroDECK config file found, converting"
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

  # If this is a pre-production build
  if [[ ! "$hard_version" =~ ^[0-9] && ! "$hard_version" =~ ^(epicure) ]]; then
    log d "Pre-production version $hard_version detected, setting debugging values in retrodeck.json"
    set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    set_setting_value "$rd_conf" "developer_options" "true" retrodeck "options"
    set_setting_value "$rd_conf" "rd_logging_level" "debug" retrodeck "options"
  fi

  log i "RetroDECK config file initialized, proceeding to finit"
  finit
else
  log i "Loading RetroDECK config file from $rd_conf"

  conf_read

  # If this is a pre-production build
  if [[ ! "$hard_version" =~ ^[0-9] && ! "$hard_version" =~ ^(epicure) ]]; then
    log d "Pre-production version $hard_version detected, setting debugging values in retrodeck.json"
    set_setting_value "$rd_conf" "update_repo" "$cooker_repository_name" retrodeck "options"
    set_setting_value "$rd_conf" "update_check" "true" retrodeck "options"
    set_setting_value "$rd_conf" "developer_options" "true" retrodeck "options"
    set_setting_value "$rd_conf" "rd_logging_level" "debug" retrodeck "options"
  fi

  # If the defined rd_home_path doesn't exist, meaning it may have been moved manually
  if [[ ! -d "$rd_home_path" || ! -L "$rd_home_path" ]]; then
    log e "Defined $rd_home_path does not exist, asking user to locate it manually"
    configurator_generic_dialog "RetroDECK Setup - Warning: No Data Folder Found" \
      "The RetroDECK data folder was not found in the expected location.\nThis may occur after a OS update or if the folder was moved manually.\n\nPlease browse to the current location of the <span foreground='$purple'><b>\"retrodeck\"</b></span> folder."
    new_home_path=$(directory_browse "RetroDECK folder location")
    if [[ -n "$new_home_path" ]]; then
      set_setting_value "$rd_conf" "rd_home_path" "$new_home_path" retrodeck "paths"
      source_component_functions
      prepare_component "postmove" "all"
    else
      log w "User exited the RetroDECK home path repair process."
      quit_retrodeck
    fi
  fi
fi

# Source component functions for further use
source_component_functions

# Build runtime caches that depend on component functions
build_compression_lookups
