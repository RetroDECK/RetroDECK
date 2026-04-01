#!/bin/bash

# Define multi-user config file location prior to XDG remap
export rd_multi_user_conf="/var/config/retrodeck/rd_multi_user.json"

get_multi_user_cli_override() {
  # Check for an early --user flag in the application arguments.
  # Must be called before general argument parsing.
  # Sets multi_user_cli_override if found.
  # USAGE: get_multi_user_cli_override "$@"
  
  local args=("$@")
  for ((i=0; i<${#args[@]}; i++)); do
    if [[ "${args[$i]}" == "--user" && -n "${args[$((i+1))]:-}" ]]; then
      multi_user_cli_override="${args[$((i+1))]}"
      export multi_user_cli_override
      log d "CLI user override: $multi_user_cli_override"
      return
    fi
  done
}

multi_user_conf_read() {
  # Read the multi-user config file and export key values as global variables
  # USAGE: multi_user_conf_read
  
  if [[ ! -f "$rd_multi_user_conf" ]]; then
    multi_user_enabled="false"
    export multi_user_enabled
    log d "Multi-user config not found, multi-user disabled"
    return
  fi

  multi_user_enabled=$(jq -r '.multi_user_enabled // false' "$rd_multi_user_conf")
  multi_user_default_user=$(jq -r '.default_user // empty' "$rd_multi_user_conf")
  export multi_user_enabled multi_user_default_user

  if [[ "$multi_user_enabled" != "true" ]]; then
    log d "Multi-user mode is not enabled"
    return
  fi

  log d "Multi-user mode is enabled"
}

multi_user_determine_current() {
  # Determine the current user through the resolver chain:
  # CLI override > identity resolvers (by priority) > default user > manual selection
  # USAGE: multi_user_determine_current
  
  local resolved_user=""

  # CLI override
  if [[ -n "${multi_user_cli_override:-}" ]]; then
    if jq -e --arg uid "$multi_user_cli_override" '.users[$uid]' "$rd_multi_user_conf" > /dev/null 2>&1; then
      resolved_user="$multi_user_cli_override"
      log i "Current user set by CLI override: $resolved_user"
    else
      log w "CLI override user $multi_user_cli_override not found in config, continuing resolver chain"
    fi
  fi

  # Identity resolvers by priority
  if [[ -z "$resolved_user" ]]; then
    local resolvers
    resolvers=$(jq -c '
      [.identity_resolvers // [] | .[] | select(.enabled == true)]
      | sort_by(.priority)
    ' "$rd_multi_user_conf")

    local resolver_count
    resolver_count=$(echo "$resolvers" | jq 'length')

    for ((i=0; i<resolver_count; i++)); do
      local resolver_type
      resolver_type=$(echo "$resolvers" | jq -r ".[$i].type")
      local result
      if result=$(multi_user_resolve_identity "$resolver_type"); then
        resolved_user="$result"
        log i "Current user resolved by $resolver_type: $resolved_user"
        break
      fi
    done
  fi

  # Default user fallback
  if [[ -z "$resolved_user" && -n "${multi_user_default_user:-}" ]]; then
    if jq -e --arg uid "$multi_user_default_user" '.users[$uid]' "$rd_multi_user_conf" > /dev/null 2>&1; then
      resolved_user="$multi_user_default_user"
      log i "Current user set by default_user: $resolved_user"
    else
      log w "Default user $multi_user_default_user not found in config"
    fi
  fi

  # Manual selection dialog
  if [[ -z "$resolved_user" ]]; then
    resolved_user=$(multi_user_manual_selection_dialog)
    if [[ -z "$resolved_user" ]]; then
      log e "Current user could not be determined by any means, exiting..."
      exit 1
    fi
    log i "Current user set by manual selection: $resolved_user"
  fi

  # Export resolved user info
  multi_user_current_user="$resolved_user"
  multi_user_is_primary=$(jq -r --arg uid "$resolved_user" \
    '.users[$uid].is_primary // false' "$rd_multi_user_conf")
  multi_user_current_display_name=$(jq -r --arg uid "$resolved_user" \
    '.users[$uid].display_name // $uid' "$rd_multi_user_conf")
  export multi_user_current_user multi_user_is_primary multi_user_current_display_name

  log i "Active user: $multi_user_current_display_name ($multi_user_current_user, primary=$multi_user_is_primary)"
}

multi_user_resolve_identity() {
  # Route to a specific identity resolver function
  # USAGE: multi_user_resolve_identity "$resolver_type"

  local resolver_type="$1"
  local resolver_func="multi_user_identity_handler::${resolver_type}"

  if ! declare -f "$resolver_func" > /dev/null 2>&1; then
    log w "No resolver function found for type: $resolver_type"
    return 1
  fi

  "$resolver_func" "resolve"
}

multi_user_identity_handler::steam() {
  # Handle multi-user Steam identity
  # In "setup" mode: interactively capture Steam identity
  # In "resolve" mode: detect active Steam user and return matching RetroDECK user ID
  # USAGE: multi_user_identity_handler::steam "setup" "display_name_var" "identities_array_var"
  # USAGE: multi_user_identity_handler::steam "resolve"
  
  local mode="$1"

  case "$mode" in

    setup)
      local -n display_name="$2"
      local -n identities="$3"

      local steam_id
      steam_id=$(get_active_steam_user_id)

      if [[ -z "$steam_id" ]]; then
        rd_zenity --warning --title="Steam Not Found" \
          --text="Could not detect an active Steam user.\nPlease make sure Steam is running and try again,\nor choose a different identity method." \
          --width=400 --height=180
        return 1
      fi

      local user_name=""
      local steam_paths=(
        "$HOME/.steam/steam"
        "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam"
      )

      for steam_path in "${steam_paths[@]}"; do
        local loginusers="$steam_path/config/loginusers.vdf"
        if [[ -f "$loginusers" ]]; then
          user_name=$(awk -v steam_id="$steam_id" '
            $0 ~ steam_id { flag=1 }
            flag && /"PersonaName"/ { gsub(/"/, "", $2); print $2; exit }
          ' "$loginusers")
          if [[ -n "$user_name" ]]; then
            break
          fi
        fi
      done

      if [[ -z "$user_name" ]]; then
        user_name="Player"
      fi

      display_name="$user_name"
      identities=("{\"type\": \"steam\", \"value\": \"$steam_id\"}")

      log i "Steam identity imported: $user_name (ID: $steam_id)"
      ;;

    resolve)
      local active_steam_id
      active_steam_id=$(get_active_steam_user_id) || return 1

      if [[ -z "$active_steam_id" ]]; then
        log d "Could not determine active Steam user ID"
        return 1
      fi

      local matched_user
      matched_user=$(jq -r --arg steam_id "$active_steam_id" '
        .users | to_entries[] |
        select(.value.identities[]? | select(.type == "steam" and .value == $steam_id)) |
        .key
      ' "$rd_multi_user_conf")

      if [[ -z "$matched_user" ]]; then
        log d "No user matched Steam ID: $active_steam_id"
        return 1
      fi

      echo "$matched_user"
      ;;

  esac
}

multi_user_identity_handler::system() {
  # Handle multi-user system username identity
  # In "setup" mode: capture current system username as identity
  # In "resolve" mode: match current system username against stored identities
  # USAGE: multi_user_identity_handler::system "setup" "display_name_var" "identities_array_var"
  # USAGE: multi_user_identity_handler::system "resolve"
  
  local mode="$1"

  case "$mode" in

    setup)
      local -n display_name="$2"
      local -n identities="$3"

      local system_user
      system_user=$(whoami)

      display_name="$system_user"
      identities=("{\"type\": \"system\", \"value\": \"$system_user\"}")

      log i "System identity imported: $system_user"
      ;;

    resolve)
      local current_user
      current_user=$(whoami)

      if [[ -z "$current_user" ]]; then
        log d "Could not determine system username"
        return 1
      fi

      local matched_user
      matched_user=$(jq -r --arg sys_user "$current_user" '
        .users | to_entries[] |
        select(.value.identities[]? | select(.type == "system" and .value == $sys_user)) |
        .key
      ' "$rd_multi_user_conf")

      if [[ -z "$matched_user" ]]; then
        log d "No user matched system username: $current_user"
        return 1
      fi

      echo "$matched_user"
      ;;

  esac
}

multi_user_identity_handler::manual() {
  # Handle multi-user manual identity configuration. Only used during multi-user setup process
  # USAGE: multi_user_identity_handler::manual "setup" "display_name_var" "identities_array_var"
  
  local mode="$1"

  case "$mode" in

    setup)
      local -n display_name="$2"
      local -n identities="$3"

      local entered_name
      entered_name=$(rd_zenity --entry \
        --title="User Profile" \
        --text="Enter a display name for your user profile:" \
        --entry-text="Player" \
        --width=400 \
        --height=150)

      if [[ -z "$entered_name" ]]; then
        return 1
      fi

      display_name="$entered_name"
      identities=()

      log i "Manual identity configured: $entered_name"
      ;;

    resolve)
      # Manual identity has no auto-detection mechanism
      return 1
      ;;

  esac
}

get_active_steam_user_id() {
  # Detect the currently logged-in Steam user ID by checking loginusers.vdf for the most recent active user. Checks both native and Flatpak Steam locations
  # USAGE: steam_id=$(get_active_steam_user_id)

  local steam_paths=(
    "$HOME/.steam/steam"
    "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam"
  )

  local steam_path
  for steam_path in "${steam_paths[@]}"; do
    local loginusers="$steam_path/config/loginusers.vdf"
    if [[ ! -f "$loginusers" ]]; then
      continue
    fi

    local steam_id
    steam_id=$(awk '
      /"users"/ { in_users=1 }
      in_users && /^[[:space:]]*"[0-9]+"/ {
        gsub(/"/, "", $1)
        current_id=$1
      }
      in_users && /"MostRecent"[[:space:]]*"1"/ {
        print current_id
        exit
      }
    ' "$loginusers")

    if [[ -n "$steam_id" ]]; then
      log d "Active Steam user ID found: $steam_id (from $steam_path)"
      echo "$steam_id"
      return 0
    fi
  done

  log d "No active Steam user found in any known location"
  return 1
}

multi_user_remap_xdg() {
  # Remap XDG environment variables to per-user paths for non-primary users
  # USAGE: multi_user_remap_xdg "$user_id"

  local user_id="$1"

  XDG_CONFIG_HOME="/var/config/rd_users/${user_id}/config"
  XDG_DATA_HOME="/var/config/rd_users/${user_id}/data"
  XDG_CACHE_HOME="/var/config/rd_users/${user_id}/cache"
  export XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME

  log i "XDG paths remapped for user $user_id:"
  log i "  XDG_CONFIG_HOME=$XDG_CONFIG_HOME"
  log i "  XDG_DATA_HOME=$XDG_DATA_HOME"
  log i "  XDG_CACHE_HOME=$XDG_CACHE_HOME"
}

multi_user_boot() {
  # Reads the multi-user config, determines the current user, remaps XDG if needed and triggers first-login initialization for new users
  # USAGE: multi_user_boot "$@"
  
  multi_user_conf_read

  if [[ "$multi_user_enabled" != "true" ]]; then
    return
  fi

  get_multi_user_cli_override "$@"
  multi_user_determine_current

  if [[ "$multi_user_is_primary" == "true" ]]; then
    log i "Primary user active, no XDG remap needed"
    return
  fi

  multi_user_remap_xdg "$multi_user_current_user"

  # Check if this user needs first-login initialization
  local initialized
  initialized=$(jq -r --arg uid "$multi_user_current_user" \
    '.users[$uid].initialized // false' "$rd_multi_user_conf")

  if [[ "$initialized" != "true" ]]; then
    multi_user_first_login_init "$multi_user_current_user"
  fi
}

multi_user_first_login_init() {
  # Run first-login initialization for a newly created user
  # Resets all installed components to generate configs and symlinks against the user's per-user paths, then marks the user as initialized
  # USAGE: multi_user_first_login_init "$user_id"
  
  local user_id="$1"

  log i "Running first-login initialization for $user_id"

  prepare_component "reset" "all-installed"

  # Mark user as initialized
  jq --arg uid "$user_id" '
    .users[$uid].initialized = true
  ' "$rd_multi_user_conf" > "${rd_multi_user_conf}.tmp" \
    && mv "${rd_multi_user_conf}.tmp" "$rd_multi_user_conf"

  log i "First-login initialization complete for $user_id"
}

multi_user_manual_selection_dialog() {
  # Present a dialog for manual user selection when identity cannot be auto-determined
  # USAGE: selected_user=$(multi_user_manual_selection)

  local -a dialog_args=()
  local user_ids
  mapfile -t user_ids < <(jq -r '.users | keys[]' "$rd_multi_user_conf")

  for user_id in "${user_ids[@]}"; do
    local display_name
    display_name=$(jq -r --arg uid "$user_id" '.users[$uid].display_name // $uid' "$rd_multi_user_conf")
    dialog_args+=("$user_id" "$display_name")
  done

  local selected
  selected=$(rd_zenity --list \
    --title="Select User" \
    --text="Select which user profile to load:" \
    --column="ID" \
    --column="Name" \
    --hide-column=1 \
    --print-column=1 \
    --width=400 \
    --height=300 \
    "${dialog_args[@]}")

  if [[ -z "$selected" ]]; then
    log e "No user selected, cannot continue"
    return 1
  fi

  echo "$selected"
}
