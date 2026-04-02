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
        rd_zenity --icon-name=net.retrodeck.retrodeck --warning --title="RetroDECK Multi-User - Steam Not Found" \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --text="Could not detect an active Steam user.\nPlease make sure Steam is installed and try again,\nor choose a different identity method."
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
      entered_name=$(rd_zenity --icon-name=net.retrodeck.retrodeck --entry \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title="RetroDECK Multi-User - User Profile" \
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
    # Early read of current user retrodeck.json so the paths can be used in component preparation
    conf_read
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
  selected=$(rd_zenity --icon-name=net.retrodeck.retrodeck --list \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="RetroDECK Multi-user - Select User" \
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

configurator_multi_user_toggle_dialog() {
  # Entry point for enabling or disabling multi-user mode from the Configurator
  # USAGE: configurator_multi_user_toggle_dialog
  
  if [[ "${multi_user_enabled:-false}" == "true" ]]; then
    if configurator_generic_question_dialog "RetroDECK - Disable Multi-User Mode" "Disabling multi-user mode will revert to single-user operation.\n\nThe primary user's data will remain unchanged.\nOther user profiles will be preserved but inactive.\n\nDisable multi-user mode?"; then
      jq '.multi_user_enabled = false' "$rd_multi_user_conf" > "${rd_multi_user_conf}.tmp" \
        && mv "${rd_multi_user_conf}.tmp" "$rd_multi_user_conf"
      multi_user_enabled="false"
      export multi_user_enabled
      log i "Multi-user mode disabled"
      configurator_generic_dialog "RetroDECK - Multi-User Mode" "Multi-user mode has been disabled.\nThe application will operate as single-user on next launch."
    fi
  else
    configurator_multi_user_enable_dialog
  fi
}

configurator_multi_user_enable_dialog() {
  # Walk the user through enabling multi-user mode for the first time, or re-enabling it if the config already exists
  # USAGE: configurator_multi_user_enable_dialog

  # Check for existing config from a previous enablement
  if [[ -f "$rd_multi_user_conf" ]]; then
    rd_zenity --icon-name=net.retrodeck.retrodeck --question \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title="RetroDECK Multi-User - Re-enable Multi-User Mode" \
      --text="A previous multi-user configuration was found.\n\nWould you like to restore the previous configuration,\nor start fresh with a new setup?" \
      --ok-label="Restore Previous" \
      --cancel-label="Start Fresh"

    if [[ $? -eq 0 ]]; then
      # Restore: just flip the enabled flag
      jq '.multi_user_enabled = true' "$rd_multi_user_conf" > "${rd_multi_user_conf}.tmp" \
        && mv "${rd_multi_user_conf}.tmp" "$rd_multi_user_conf"
      multi_user_enabled="true"
      export multi_user_enabled
      log i "Multi-user mode re-enabled with previous configuration"
      configurator_generic_dialog "RetroDECK Multi-User Mode" "Multi-user mode has been re-enabled with your previous settings."
      return
    fi
    # Start fresh: continue with the full setup flow below
    multi_user_cleanup_stale_data
  fi

  if ! configurator_generic_question_dialog "RetroDECK Multi-User - Enable Multi-User Mode" "Multi-user mode allows multiple people to have separate saves, settings, and game progress on this device.\n\nYour current data will be preserved as the primary user.\nAdditional users can be added after setup.\n\nContinue with setup?"; then
    log d "Multi-user enablement cancelled by user"
    return
  fi

  # Set up User 1 identity
  local user_1_display_name=""
  local -a user_1_identities=()

  if ! multi_user_setup_identity "user_1_display_name" "user_1_identities"; then
    log d "Multi-user enablement cancelled during identity setup"
    return
  fi

  # Configure path scopes
  local path_scopes_json=""

  if ! multi_user_setup_path_scopes "path_scopes_json"; then
    log d "Multi-user enablement cancelled during path scope setup"
    return
  fi

  # Read resolver defaults from framework manifest
  local resolver_defaults
  resolver_defaults=$(jq -c '
    .[] | .manifest | select(has("retrodeck")) | .retrodeck.identity_resolvers // []
  ' "$component_manifest_cache_file")

  if [[ -z "$resolver_defaults" || "$resolver_defaults" == "null" ]]; then
    resolver_defaults="[]"
  fi

  # Convert manifest resolver format to config format
  local resolvers_json
  resolvers_json=$(echo "$resolver_defaults" | jq -c '
    [.[] | {type: .type, enabled: .default_enabled, priority: .default_priority}]
  ')

  # Build and write the config file
  local identities_json
  identities_json=$(printf '%s\n' "${user_1_identities[@]}" | jq -s '.')

  jq -n \
    --arg display_name "$user_1_display_name" \
    --argjson identities "$identities_json" \
    --argjson path_scopes "$path_scopes_json" \
    --argjson resolvers "$resolvers_json" \
    '{
      multi_user_enabled: true,
      default_user: null,
      identity_resolvers: $resolvers,
      users: {
        user_1: {
          display_name: $display_name,
          is_primary: true,
          initialized: true,
          identities: $identities
        }
      },
      path_scopes: $path_scopes
    }' > "$rd_multi_user_conf"

  # Update in-memory values
  multi_user_enabled="true"
  multi_user_current_user="user_1"
  multi_user_is_primary="true"
  multi_user_current_display_name="$user_1_display_name"
  export multi_user_enabled multi_user_current_user multi_user_is_primary multi_user_current_display_name

  log i "Multi-user mode enabled, primary user: $user_1_display_name"

  configurator_generic_dialog "RetroDECK Multi-User - Multi-User Mode Enabled" "Multi-user mode is now active.\n\nYou are set up as the primary user: $user_1_display_name\n\nYou can add additional users from the Multi-User section of the Configurator."
}

multi_user_setup_identity() {
  # Present identity source options built from manifest-declared resolvers, plus a manual option. Capture the users display name and identity mappings
  # USAGE: multi_user_setup_identity "display_name_var" "identities_array_var"

  local -n display_name="$1"
  local -n identities="$2"

  # Read resolver definitions from framework manifest, sorted by priority
  local resolvers_json
  resolvers_json=$(jq -c '
    [
      .[] | .manifest | select(has("retrodeck")) | .retrodeck.identity_resolvers // [] | .[]
    ] | sort_by(.default_priority)
  ' "$component_manifest_cache_file")

  if [[ -z "$resolvers_json" || "$resolvers_json" == "[]" ]]; then
    resolvers_json="[]"
  fi

  # Build dialog entries from resolvers
  local -a dialog_args=()
  local resolver_count
  resolver_count=$(echo "$resolvers_json" | jq 'length')

  for ((i=0; i<resolver_count; i++)); do
    local resolver_type resolver_description
    resolver_type=$(echo "$resolvers_json" | jq -r ".[$i].type")
    resolver_description=$(echo "$resolvers_json" | jq -r ".[$i].description // .[$i].type")
    dialog_args+=("$resolver_type" "$resolver_description")
  done

  # Always add manual as fallback option
  dialog_args+=("manual" "Configure manually")

  local identity_source
  identity_source=$(rd_zenity --icon-name=net.retrodeck.retrodeck --list \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="RetroDECK Multi-User - User Identity Setup" \
    --text="How would you like to set up your user profile?" \
    --column="ID" \
    --column="Method" \
    --hide-column=1 \
    --print-column=1 \
    --width=500 \
    --height=300 \
    "${dialog_args[@]}")

  if [[ -z "$identity_source" ]]; then
    return 1
  fi

  # Route to the appropriate setup handler
  local handler_func="multi_user_identity_handler::${identity_source}"

  if ! declare -f "$handler_func" > /dev/null 2>&1; then
    log e "No identity setup function found for type: $identity_source"
    return 1
  fi

  if ! "$handler_func" "setup" "display_name" "identities"; then
    # Handler failed (e.g., Steam not found), let user choose again
    multi_user_setup_identity "display_name" "identities"
    return $?
  fi
}

multi_user_setup_path_scopes() {
  # Present all configurable paths from framework and component manifests, allowing the user to choose which are per-user vs shared
  # Paths are shown with their recommended defaults pre-selected
  # USAGE: multi_user_setup_path_scopes "result_var"

  local -n result="$1"

  # Gather all paths with scope metadata from all manifests
  local all_paths_json
  all_paths_json=$(jq -c '
    [
      .[] | .manifest | to_entries[] |
      .value.component_paths // {} | to_entries[] |
      {
        key: .key,
        recommended_scope: .value.recommended_scope,
        description: (.value.description // .key)
      }
    ]
  ' "$component_manifest_cache_file")

  if [[ -z "$all_paths_json" || "$all_paths_json" == "[]" ]]; then
    log w "No configurable paths found in manifests, using empty scope list"
    result="{}"
    return 0
  fi

  # Build the Zenity checklist arguments
  local -a dialog_args=()
  local path_count
  path_count=$(echo "$all_paths_json" | jq 'length')

  for ((i=0; i<path_count; i++)); do
    local key description recommended
    key=$(echo "$all_paths_json" | jq -r ".[$i].key")
    description=$(echo "$all_paths_json" | jq -r ".[$i].description")
    recommended=$(echo "$all_paths_json" | jq -r ".[$i].recommended_scope")

    if [[ "$recommended" == "per-user" ]]; then
      dialog_args+=("TRUE" "$key" "$description")
    else
      dialog_args+=("FALSE" "$key" "$description")
    fi
  done

  local selected
  selected=$(rd_zenity --icon-name=net.retrodeck.retrodeck --list \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="RetroDECK Multi-User - Multi-User Path Configuration" \
    --text="Select which data should be separate for each user (checked = per-user, unchecked = shared between all users):" \
    --checklist \
    --column="Per-User" \
    --column="Path" \
    --column="Description" \
    --hide-column=2 \
    --print-column=2 \
    --separator="^" \
    --width=600 \
    --height=500 \
    "${dialog_args[@]}")
  local rc=$?

  if [[ $rc -ne 0 ]]; then
    log d "Path scope selection cancelled by user"
    return 1
  fi

  local scope_object="{}"
  local -a per_user_paths=()
  if [[ -n "$selected" ]]; then
    IFS='^' read -ra per_user_paths <<< "$selected"
  fi

  for ((i=0; i<path_count; i++)); do
    local key
    key=$(echo "$all_paths_json" | jq -r ".[$i].key")
    local scope="shared"

    for per_user_key in "${per_user_paths[@]}"; do
      if [[ "$per_user_key" == "$key" ]]; then
        scope="per-user"
        break
      fi
    done

    scope_object=$(echo "$scope_object" | jq --arg key "$key" --arg scope "$scope" '. + {($key): $scope}')
  done

  result="$scope_object"
  log d "Path scopes configured: $scope_object"
}

multi_user_cleanup_stale_data() {
  # Check for existing per-user data from a previous multi-user configuration and offer to clean up or archive it
  # USAGE: multi_user_cleanup_stale_data

  local rd_users_xdg_base="/var/config/rd_users"
  local rd_users_data_base="$rd_home_path/users"

  local -a stale_dirs=()

  # Check both XDG and data locations for leftover user directories
  if [[ -d "$rd_users_xdg_base" ]]; then
    while IFS= read -r dir; do
      stale_dirs+=("$dir")
    done < <(find "$rd_users_xdg_base" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  fi

  if [[ -d "$rd_users_data_base" ]]; then
    while IFS= read -r dir; do
      stale_dirs+=("$dir")
    done < <(find "$rd_users_data_base" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  fi

  if [[ ${#stale_dirs[@]} -eq 0 ]]; then
    log d "No stale multi-user data found"
    return
  fi

  local action
  action=$(rd_zenity --icon-name=net.retrodeck.retrodeck --list \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="RetroDECK Multi-User - Existing User Data Found" \
    --text="Data from a previous multi-user configuration was found.\n\nWhat would you like to do with it?" \
    --column="ID" \
    --column="Action" \
    --hide-column=1 \
    --print-column=1 \
    --width=500 \
    --height=250 \
    "keep" "Keep existing data in place" \
    "archive" "Archive data to backups and remove" \
    "delete" "Delete existing data permanently")
  local dialog_rc=$?

  if [[ $dialog_rc -ne 0 || -z "$action" ]]; then
    log d "Stale data cleanup skipped by user"
    return
  fi

  case "$action" in

    keep)
      log i "Keeping existing multi-user data in place"
      ;;

    archive)
      local timestamp
      timestamp=$(date +%Y%m%d_%H%M%S)
      local archive_path="$backups_path/multi_user_backup_${timestamp}.tar.gz"

      log i "Archiving stale multi-user data to $archive_path"

      local -a tar_args=()
      for dir in "${stale_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
          tar_args+=("-C" "$(dirname "$dir")" "$(basename "$dir")")
        fi
      done

      if tar czf "$archive_path" "${tar_args[@]}" 2>/dev/null; then
        log i "Archive created: $archive_path"

        # Remove archived directories
        for dir in "${stale_dirs[@]}"; do
          if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            log d "Removed: $dir"
          fi
        done

        configurator_generic_dialog "RetroDECK Multi-User - Data Archived" "Previous user data has been archived to:\n$archive_path"
      else
        log e "Failed to create archive at $archive_path"
        rd_zenity --icon-name=net.retrodeck.retrodeck --error --title="RetroDECK Multi-User - Archive Failed" \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --text="Failed to archive user data.\nExisting data has been left in place." \
          --width=400 --height=150
      fi
      ;;

    delete)
      if configurator_generic_question_dialog "RetroDECK Multi-User - Confirm Deletion" "This will permanently delete all previous user data.\nThis cannot be undone.\n\nAre you sure?"; then
        for dir in "${stale_dirs[@]}"; do
          if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            log d "Deleted: $dir"
          fi
        done
        log i "Stale multi-user data deleted"
      else
        log d "Deletion cancelled by user"
      fi
      ;;

  esac
}

get_per_user_relative_path() {
  # Derive the intended relative path tree for a given path key by extracting the variable reference from the default value, 
  # resolving it against the default core config, and finding the longest matching core path prefix
  # USAGE: relative=$(get_per_user_relative_path "$path_key")
  
  local path_key="$1"

  # Get the default value for this path key
  local default_value=""

  # First check the default core config paths block
  default_value=$(jq -r --arg key "$path_key" '.paths[$key] // empty' "$rd_defaults")

  # If not found in core defaults, check component manifests
  if [[ -z "$default_value" ]]; then
    default_value=$(jq -r --arg key "$path_key" '
      .[] | .manifest | to_entries[] |
      .value.component_paths // {} |
      .[$key].path // empty
    ' "$component_manifest_cache_file" | head -1)
  fi

  if [[ -z "$default_value" ]]; then
    log w "No default path found for $path_key"
    return 1
  fi

  # Extract the leading variable name and the remainder of the path
  local var_name="${default_value%%/*}"
  var_name="${var_name#\$}"
  local remainder="${default_value#\$${var_name}}"
  remainder="${remainder#/}"

  # Look up the extracted variable name in the default core config paths block
  local var_resolved
  var_resolved=$(jq -r --arg key "$var_name" '.paths[$key] // empty' "$rd_defaults")

  if [[ -z "$var_resolved" ]]; then
    # Variable not found in core paths block
    if [[ -n "$remainder" ]]; then
      # Use the remainder as the relative tree
      log d "Path $path_key: variable $var_name not in core paths, using remainder: $remainder"
      echo "$remainder"
      return 0
    else
      # Variable is the entire path and not in core paths
      # Resolve from current environment as last resort, use basename
      local env_resolved="${!var_name:-}"
      if [[ -z "$env_resolved" ]]; then
        log e "Path $path_key: variable $var_name could not be resolved from core paths or environment"
        return 1
      fi

      local base
      base=$(basename "$env_resolved")

      # Validate no conflict with existing per-user relative paths
      # by checking if this basename already exists as a relative tree for another path
      log w "Path $path_key: resolved to basename '$base' from unrecognized variable $var_name. Verify for conflicts"
      echo "$base"
      return 0
    fi
  fi

  # Variable found in core paths, build the fully resolved path
  local resolved_path
  if [[ -n "$remainder" ]]; then
    resolved_path="$var_resolved/$remainder"
  else
    resolved_path="$var_resolved"
  fi

  # Collect all core paths from defaults, sorted by length descending so we match the most specific prefix first
  local -a core_paths=()
  mapfile -t core_paths < <(jq -r '.paths | to_entries[] | .value' "$rd_defaults" | \
    awk '{ print length, $0 }' | sort -rn | cut -d' ' -f2-)

  # Find the longest matching core path prefix
  local best_match=""
  for core_path in "${core_paths[@]}"; do
    if [[ "$resolved_path" == "$core_path/"* ]]; then
      best_match="$core_path"
      break
    fi
  done

  if [[ -n "$best_match" ]]; then
    local relative="${resolved_path#$best_match/}"
    log d "Path $path_key: resolved=$resolved_path, matched prefix=$best_match, relative=$relative"
    echo "$relative"
    return 0
  fi

  # No core path matched as a prefix, use basename
  local base
  base=$(basename "$resolved_path")
  log d "Path $path_key: resolved=$resolved_path is a core path itself, using basename: $base"
  echo "$base"
}

multi_user_create() {
  # Create a new multi-user profile
  # Sets up identity, per-user directories, XDG symlinks, and a default core config
  # USAGE: multi_user_create
  
  # Determine next user ID
  local highest_id
  highest_id=$(jq -r '.users | keys[]' "$rd_multi_user_conf" | \
    sed 's/user_//' | sort -n | tail -1)
  local next_num=$((highest_id + 1))
  local new_user_id="user_${next_num}"

  log i "Creating new user: $new_user_id"

  # Identity setup
  local new_display_name=""
  local -a new_identities=()

  if ! multi_user_setup_identity "new_display_name" "new_identities"; then
    log d "User creation cancelled during identity setup"
    return
  fi

  # Create per-user data directories for paths scoped as per-user
  local rd_users_data_base="$rd_home_path/users/$new_user_id"
  local per_user_paths
  per_user_paths=$(jq -r '.path_scopes | to_entries[] | select(.value == "per-user") | .key' "$rd_multi_user_conf")

  while IFS= read -r path_key; do
    [[ -z "$path_key" ]] && continue

    local relative_tree
    if ! relative_tree=$(get_per_user_relative_path "$path_key"); then
      log w "Could not determine relative path for $path_key, skipping"
      continue
    fi

    local new_user_path="$rd_users_data_base/$relative_tree"
    create_dir "$new_user_path"

    log d "Created per-user directory: $new_user_path"
  done <<< "$per_user_paths"

  # Create per-user XDG directories with symlinks from Flatpak-static paths
  local rd_users_xdg_base="/var/config/rd_users/$new_user_id"

  dir_prep "$rd_users_data_base/config" "$rd_users_xdg_base/config"
  dir_prep "$rd_users_data_base/data" "$rd_users_xdg_base/data"
  dir_prep "$rd_users_data_base/cache" "$rd_users_xdg_base/cache"

  # Copy default core config and rewrite per-user paths
  local new_user_conf_dir="$rd_users_data_base/config/retrodeck"
  create_dir "$new_user_conf_dir"

  local new_user_conf="$new_user_conf_dir/retrodeck.json"
  cp "$rd_defaults" "$new_user_conf"

  # Build the paths block: shared paths from the current install, per-user paths rewritten
  local current_paths
  current_paths=$(jq -c '.paths' "$rd_conf")
  local updated_paths="$current_paths"

  while IFS= read -r path_key; do
    [[ -z "$path_key" ]] && continue

    local relative_tree
    if ! relative_tree=$(get_per_user_relative_path "$path_key"); then
      continue
    fi

    local new_path="$rd_users_data_base/$relative_tree"
    updated_paths=$(echo "$updated_paths" | jq --arg key "$path_key" --arg path "$new_path" \
      'if has($key) then .[$key] = $path else . end')
  done <<< "$per_user_paths"

  jq --argjson paths "$updated_paths" '.paths = $paths' "$new_user_conf" > "${new_user_conf}.tmp" \
    && mv "${new_user_conf}.tmp" "$new_user_conf"

  # Build the component_paths block with per-user paths rewritten
  local current_component_paths
  current_component_paths=$(jq -c '.component_paths // {}' "$rd_conf")

  local updated_component_paths="$current_component_paths"
  local component_names
  component_names=$(echo "$current_component_paths" | jq -r 'keys[]')

  while IFS= read -r comp_name; do
    [[ -z "$comp_name" ]] && continue

    local comp_path_keys
    comp_path_keys=$(echo "$current_component_paths" | jq -r --arg comp "$comp_name" '.[$comp] | keys[]')

    while IFS= read -r comp_path_key; do
      [[ -z "$comp_path_key" ]] && continue

      local scope
      scope=$(jq -r --arg key "$comp_path_key" '.path_scopes[$key] // "shared"' "$rd_multi_user_conf")

      if [[ "$scope" == "per-user" ]]; then
        local relative_tree
        if relative_tree=$(get_per_user_relative_path "$comp_path_key"); then
          local new_comp_path="$rd_users_data_base/$relative_tree"
          updated_component_paths=$(echo "$updated_component_paths" | \
            jq --arg comp "$comp_name" --arg key "$comp_path_key" --arg path "$new_comp_path" \
            '.[$comp][$key] = $path')
        fi
      fi
    done <<< "$comp_path_keys"
  done <<< "$component_names"

  jq --argjson comp_paths "$updated_component_paths" '.component_paths = $comp_paths' "$new_user_conf" > "${new_user_conf}.tmp" \
    && mv "${new_user_conf}.tmp" "$new_user_conf"

  log i "Core config created for $new_user_id at $new_user_conf"

  # Add user entry to multi-user config
  local identities_json
  if [[ ${#new_identities[@]} -gt 0 ]]; then
    identities_json=$(printf '%s\n' "${new_identities[@]}" | jq -s '.')
  else
    identities_json="[]"
  fi

  jq --arg uid "$new_user_id" --arg name "$new_display_name" --argjson idents "$identities_json" '
    .users[$uid] = {
      display_name: $name,
      is_primary: false,
      initialized: false,
      identities: $idents
    }
  ' "$rd_multi_user_conf" > "${rd_multi_user_conf}.tmp" \
    && mv "${rd_multi_user_conf}.tmp" "$rd_multi_user_conf"

  log i "User $new_user_id ($new_display_name) added to multi-user config"

  # Prompt for restart
  configurator_generic_dialog "RetroDECK Multi-User - User Created" "User profile '$new_display_name' has been created.\n\nOn next launch, log in as '$new_display_name' to complete setup."
}

configurator_multi_user_resolvers() {
  # Configure identity resolver priorities and enabled state.
  # Allows reordering resolvers and toggling them on/off.
  # USAGE: configurator_multi_user_resolvers
  
  local resolvers
  resolvers=$(jq -c '[.identity_resolvers // [] | .[] | .]' "$rd_multi_user_conf")

  local resolver_count
  resolver_count=$(echo "$resolvers" | jq 'length')

  if [[ "$resolver_count" -eq 0 ]]; then
    configurator_generic_dialog "RetroDECK Configurator: Configure Identity Resolvers" "No identity resolvers are configured."
    return
  fi

  # Build the list dialog with current state
  local -a dialog_args=()
  for ((i=0; i<resolver_count; i++)); do
    local rtype enabled priority description
    rtype=$(echo "$resolvers" | jq -r ".[$i].type")
    enabled=$(echo "$resolvers" | jq -r ".[$i].enabled")
    priority=$(echo "$resolvers" | jq -r ".[$i].priority")

    # Look up description from framework manifest
    description=$(jq -r --arg t "$rtype" '
      .[] | .manifest | select(has("retrodeck")) |
      .retrodeck.identity_resolvers // [] | .[] |
      select(.type == $t) | .description // .type
    ' "$component_manifest_cache_file")

    if [[ -z "$description" ]]; then
      description="$rtype"
    fi

    local enabled_display="Enabled"
    if [[ "$enabled" != "true" ]]; then
      enabled_display="Disabled"
    fi

    dialog_args+=("$rtype" "$priority" "$description" "$enabled_display")
  done

  local selected
  selected=$(rd_zenity --list --icon-name=net.retrodeck.retrodeck \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="RetroDECK Configurator: Multi-User Identity Resolver Settings" \
    --text="Select a resolver to configure.\n\nResolvers are checked in priority order (lowest number = highest priority).\nThe first resolver to identify the current user wins." \
    --column="Type" \
    --column="Priority" \
    --column="Description" \
    --column="Status" \
    --hide-column=1 \
    --print-column=1 \
    --width=600 \
    --height=350 \
    "${dialog_args[@]}")
  local dialog_rc=$?

  if [[ $dialog_rc -ne 0 || -z "$selected" ]]; then
    return
  fi

  configurator_nav="configurator_multi_user_resolver_edit $selected"
}

configurator_multi_user_resolver_edit() {
  # Edit settings for a specific identity resolver.
  # USAGE: configurator_multi_user_resolver_edit "$resolver_type"
  
  local resolver_type="$1"

  local current_enabled current_priority
  current_enabled=$(jq -r --arg t "$resolver_type" \
    '[.identity_resolvers[] | select(.type == $t)][0].enabled' "$rd_multi_user_conf")
  current_priority=$(jq -r --arg t "$resolver_type" \
    '[.identity_resolvers[] | select(.type == $t)][0].priority' "$rd_multi_user_conf")

  local action
  action=$(rd_zenity --list --icon-name=net.retrodeck.retrodeck \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="Configure: $resolver_type" \
    --text="Current settings:\n  Priority: $current_priority\n  Status: $([ "$current_enabled" == "true" ] && echo "Enabled" || echo "Disabled")" \
    --column="ID" \
    --column="Action" \
    --hide-column=1 \
    --print-column=1 \
    --width=450 \
    --height=300 \
    "toggle" "$([ "$current_enabled" == "true" ] && echo "Disable" || echo "Enable") this resolver" \
    "priority" "Change priority" \
    "back" "Go back")
  local rc=$?

  if [[ $rc -ne 0 || -z "$action" ]]; then
    return
  fi

  case "$action" in

    toggle)
      local new_enabled
      if [[ "$current_enabled" == "true" ]]; then
        new_enabled="false"
      else
        new_enabled="true"
      fi

      jq --arg t "$resolver_type" --argjson e "$new_enabled" '
        .identity_resolvers = [
          .identity_resolvers[] |
          if .type == $t then .enabled = $e else . end
        ]
      ' "$rd_multi_user_conf" > "${rd_multi_user_conf}.tmp" \
        && mv "${rd_multi_user_conf}.tmp" "$rd_multi_user_conf"

      log i "Resolver $resolver_type enabled=$new_enabled"

      configurator_nav="refresh"
      ;;

    priority)
      local new_priority
      new_priority=$(rd_zenity --entry --icon-name=net.retrodeck.retrodeck \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title="Set Priority" \
        --text="Enter new priority for $resolver_type.\n\nLower numbers are checked first (1 = highest priority).\nCurrent priority: $current_priority" \
        --entry-text="$current_priority" \
        --width=400 \
        --height=180)
      local entry_rc=$?

      if [[ $entry_rc -ne 0 || -z "$new_priority" ]]; then
        configurator_nav="refresh"
        return
      fi

      # Validate numeric input
      if ! [[ "$new_priority" =~ ^[0-9]+$ ]]; then
        rd_zenity --icon-name=net.retrodeck.retrodeck --warning --title="Invalid Input" \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --text="Priority must be a positive number." \
          --width=300 --height=120
        configurator_nav="refresh"
        return
      fi

      jq --arg t "$resolver_type" --argjson p "$new_priority" '
        .identity_resolvers = [
          .identity_resolvers[] |
          if .type == $t then .priority = $p else . end
        ]
      ' "$rd_multi_user_conf" > "${rd_multi_user_conf}.tmp" \
        && mv "${rd_multi_user_conf}.tmp" "$rd_multi_user_conf"

      log i "Resolver $resolver_type priority=$new_priority"

      configurator_nav="refresh"
      ;;

  esac
}
