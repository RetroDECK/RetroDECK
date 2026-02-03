#!/bin/bash

# VARIABLES SECTION

source /app/libexec/global.sh

# DIALOG SECTION

# Configurator Option Tree

# Welcome
#     - Settings
#         - Borders
#         - Widescreen
#         - Ask-To-Exit
#         - Quick Resume
#         - Rewind
#         - Swap A/B and X/Y Buttons
#         - RetroAchievements: Login
#         - RetroAchievements: Logout
#         - RetroAchievements: Hardcore Mode
#         - Universal Dynamic Input Textures: Dolphin
#         - Universal Dynamic Input Textures: Primehack
#         - PortMaster: Hide
#     - Open Component (Behind one-time power user warning dialog)
#       - Dynamically generated list of emulators from open_component --list and --getdesc (features.json)
#     - Reset Component
#       - Reset Emulator or Engine
#         - Reset RetroArch
#         - Reset Cemu
#         - Reset Citra
#         - Reset Dolphin
#         - Reset Duckstation
#         - Reset GZDoom
#         - Reset MAME
#         - Reset MelonDS
#         - Reset PCSX2
#         - Reset PPSSPP
#         - Reset PortMaster
#         - Reset Primehack
#         - Reset Ruffle
#         - Reset RPCS3
#         - Reset Ryujinx
#         - Reset Steam ROM Manager
#         - Reset Vita3k
#         - Reset XEMU
#         - Reset Yuzu
#       - Reset RetroDECK Component
#       - Reset All Emulators and Components
#       - Reset RetroDECK
#     - Tools
#       - BIOS Checker
#       - Games Compressor
#         - Compress Single Game
#         - Compress Multiple Games: CHD
#         - Compress Multiple Games: ZIP
#         - Compress Multiple Games: RVZ
#         - Compress Multiple Games: All Formats
#         - Compress All Games
#       - Install: RetroDECK Controller Layouts
#       - Install: PS3 firmware
#       - Install: PS Vita firmware
#       - Update Notification
#       - M3U Multi-File Validator
#       - Repair RetroDECK paths
#       - Change Logging Level
#     - Steam Tools
#       - Add RetroDECK to Steam
#       - Automatic Steam Sync
#       - Manual Steam Sync
#       - Purge Steam Sync Shortcuts
#     - Data Management
#       - Backup RetroDECK
#       - ROMS Folder: Clean Empty Systems
#       - ROMS Folder: Rebuild Systems
#       - Move: All of RetroDECK
#       - Move: ROMs folder
#       - Move: BIOS folder
#       - Move: Downloaded Media folder
#       - Move: Saves folder
#       - Move: States folder
#       - Move: Themes folder
#       - Move: Screenshots folder
#       - Move: Mods folder
#       - Move: Texture Packs folder
#     - About RetroDECK
#       - RetroDECK Version History
#         - Full changelog
#         - Version-specific changelogs
#       - RetroDECK Credits
#     - Developer Options (Hidden)
#       - Change Multi-user mode
#       - Install Specific Release
#       - Browse the Wiki
#       - Install: RetroDECK Starter Pack
#       - Tool: USB Import
#
# DIALOG TREE FUNCTIONS

configurator_welcome_dialog() {
  log i "Configurator: opening welcome dialog"
  welcome_menu_options=(
    "About RetroDECK" "View patch notes, credits, and other project information."
    "Data Management" "Move, clean empty or rebuild RetroDECK directories."
    "Open Component" "Manually launch and configure individual components. Advanced Users Only." 
    "Reset Components" "Reset a specific component or restore all RetroDECK defaults."
    "Settings" "Adjust core RetroDECK: Presets, Visuals, Tweaks and Logins."
    "Steam Tools" "Synchronize ES-DE Favorites or add RetroDECK to Steam."
    "Tools" "Run various tools: BIOS Checker, File Compressor, Install optional features and more."
  )

  if [[ $developer_options == "true" ]]; then
    welcome_menu_options+=("Developer Options" "Welcome to the DANGER ZONE")
  fi

  choice=$(rd_zenity --list --title="RetroDECK Configurator" --cancel-label="Quit" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "${welcome_menu_options[@]}")

  case $choice in

  "Settings" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_global_presets_and_settings_dialog
  ;;

  "Open Component" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_power_user_warning_dialog
  ;;

  "Reset Components" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_reset_dialog
  ;;

  "Tools" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_tools_dialog
  ;;

  "About RetroDECK" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_about_retrodeck_dialog
  ;;

  "Steam Tools" )
    configurator_steam_tools_dialog
  ;;

  "Developer Options" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_generic_dialog "RetroDECK Configurator - Developer Options" "<span foreground='$purple'><b>WARNING: These features and options can be EXTREMELY DANGEROUS to your RetroDECK installation!</b></span>\n\nThey represent the bleeding edge of upcoming or experimental RetroDECK functionality and should never be used when you have important saves, states, ROMs, or other content that is not fully backed up.\n\n<b>Affected data may include (but is not limited to):</b>\n\nBIOS files\nBorders\nMedia\nGamelists\nMods\nROMs\nSaves\nStates\nScreenshots\nTexture packs\nThemes\nAnd more\n\n<span foreground='$purple'><b>All of this data may be lost, damaged, or completely corrupted if you continue.</b></span>\n\n<span foreground='$purple'><b>YOU HAVE BEEN WARNED</b></span>"
    configurator_developer_dialog
  ;;

  "Data Management" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_data_management_dialog
  ;;

  "" )
    log i "Configurator: closing"
    unset CONFIGURATOR_GUI
    exit 0
  ;;

  esac
}

configurator_global_presets_and_settings_dialog() {
  build_zenity_menu_array choices settings # Build Zenity bash array for given menu type

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Global: Presets and Settings" --cancel-label="Back" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${choices[@]}")

    local rc="$?"

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    log d "choice: $choice"

    launch_command "$choice"
  else # User hit cancel
    configurator_welcome_dialog
  fi
}

configurator_open_component_dialog() {
  # This function displays a dialog to the user for selecting an emulator to open.
  # It first constructs a list of available emulators and their descriptions by reading
  # from the output of `open_component --list` and `open_component --getdesc`.
  # to the list of emulators.
  # The function then uses `rd_zenity` to display a graphical list dialog with the
  # available emulators and their descriptions.
  # If the user selects an emulator, it calls `open_component` with the selected emulator.
  # If the user cancels the dialog, it calls `configurator_welcome_dialog` to return to the
  # welcome screen.

  (
  build_zenity_open_component_menu_array open_component_list

  component=$(rd_zenity --list \
  --title "RetroDECK Configurator - Open Component" --cancel-label="Back" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --text="Which component do you want to launch?" \
  --hide-header --hide-column=3 --print-column=3\
  --column="Component" --column="Description" --column="component_path"\
  "${open_component_list[@]}")

  if [[ -n "$component" ]]; then
    /bin/bash "$component/component_launcher.sh"
  else
    configurator_welcome_dialog
  fi
  ) |
    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Open Component" \
      --text="The RetroDECK Component List is currently open.\n\n<span foreground='$purple'><b>To continue, open a component, close the active one, or exit the list.</b></span>"
}

configurator_tools_dialog() {
  build_zenity_menu_array choices tools # Build Zenity bash array for given menu type

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Tools" --cancel-label="Back" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${choices[@]}")

  local rc="$?"

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    log i "Configurator: opening \"$choice\" menu"
    launch_command "$choice"
  else # User hit cancel
    configurator_welcome_dialog
  fi
}

configurator_data_management_dialog() {
  build_zenity_menu_array choices data_management # Build Zenity bash array for given menu type

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Data Management" --cancel-label="Back" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${choices[@]}")

  local rc="$?"

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    log d "choice: $choice"

    launch_command "$choice"
  else # User hit cancel
    configurator_welcome_dialog
  fi
}

configurator_reset_dialog() {
  # This function displays a dialog to the user for selecting components to reset.
  # It first constructs a list of available components and their descriptions by reading
  # from the features.json file.
  # The function then uses `rd_zenity` to display a graphical checklist dialog with the
  # available components and their descriptions.
  # If the user selects components, it calls `prepare_component` with the selected components.
  # If the user cancels the dialog, it calls `configurator_welcome_dialog` to return to the welcome screen.

  (
  build_zenity_reset_component_menu_array reset_component_list
  
  choice=$(rd_zenity --list \
  --title "RetroDECK Configurator - Reset Components" --cancel-label="Cancel"  \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --checklist --ok-label="Reset Selected" --extra-button="Reset All" --extra-button="Factory Reset" \
  --print-column=2 --hide-column=2 \
  --separator="^" \
  --text="Which components do you want to reset?" \
  --column "Reset" \
  --column "Component" \
  --column "Name" \
  --column "Description" \
  "${reset_component_list[@]}")

  log d "User selected: $choice"

  if [[ "$choice" =~ "Factory Reset" ]]; then
    rd_zenity --question \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Factory Reset" \
      --text="<span foreground='$purple'><b>This action will reset all RetroDECK settings to their default values.</b></span> It will also restart the first-time setup process.\n\nYour personal data: including games, saves, and scraped artwork, will not be affected.\n\n<span foreground='$purple'><b>Are you sure you want to proceed?</b></span>"
    if [[ $? == 0 ]]; then # User clicked "Yes"
      prepare_component "factory-reset"
      configurator_process_complete_dialog "performing a factory reset"
    else # User clicked "Cancel"
      configurator_welcome_dialog
    fi
  elif [[ "$choice" =~ "Reset All" ]]; then
    rd_zenity --question \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Factory Reset" \
      --text="<span foreground='$purple'><b>This action will reset all RetroDECK settings to their default values.</b></span> It will also restart the first-time setup process.\n\nYour personal data: including games, saves, and scraped artwork, will not be affected.\n\n<span foreground='$purple'><b>Are you sure you want to proceed?</b></span>"
    if [[ $? == 0 ]]; then # User clicked "Yes"
      (
        prepare_component "reset" "all"
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Reset in Progress" \
      --text="Resetting all components\n\nPlease wait while the process finishes..."
      configurator_process_complete_dialog "resetting all components"
    else # User clicked "Cancel"
      configurator_welcome_dialog
    fi
  elif [[ -n "$choice" ]]; then
    pretty_choices=()
    IFS='^' read -ra choices <<< "$choice"
    for current_choice in "${choices[@]}"; do
      pretty_choices+=("$(jq -r --arg component "$current_choice" '.[$component].name' "$rd_components/$current_choice/component_manifest.json")")
    done
    rd_zenity --question \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Reset Components" \
      --text="You selected the following components to be reset:\n\n$(printf '%s\n' ${pretty_choices[@]})\n\nDo you want to continue?"
    if [[ $? == 0 ]]; then # User clicked "Yes"
      (
      for component_to_reset in "${choices[@]}"; do
        prepare_component "reset" "$component_to_reset"
      done
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Reset in Progress" \
      --text="Resetting selected components.\n\n<span foreground='$purple'><b>Please wait while the process finishes...</b></span>"
    else # User clicked "Cancel"
      configurator_reset_dialog
    fi
    configurator_process_complete_dialog "resetting selected emulators"
  else
    log d "User selected \"Cancel\""
    configurator_welcome_dialog
  fi
  ) |
    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Reset Component" \
      --text="The RetroDECK Component List is currently open.\n\n<span foreground='$purple'><b>To continue, reset one or more components or exit the list.</b></span>"
}

configurator_about_retrodeck_dialog() {
  build_zenity_menu_array choices about_retrodeck # Build Zenity bash array for given menu type

  choice=$(rd_zenity --list --title="RetroDECK Configurator - About RetroDECK" --cancel-label="Back" --ok-label="OK"\
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${choices[@]}")

  local rc="$?"

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    log d "choice: $choice"

    launch_command "$choice"
  else # User hit cancel
    configurator_welcome_dialog
  fi
}

configurator_steam_tools_dialog() {
  build_zenity_menu_array choices steam_tools # Build Zenity bash array for given menu type

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Steam Tools" --cancel-label="Back" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${choices[@]}")

  local rc="$?"

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    log d "choice: $choice"

    launch_command "$choice"
  else # User hit cancel
    configurator_welcome_dialog
  fi
}

configurator_developer_dialog() {
  build_zenity_menu_array choices developer_options # Build Zenity bash array for given menu type

  choice=$(rd_zenity --list --title="RetroDECK Configurator - Developer Options" --cancel-label="Back" --ok-label="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" --column="command" --hide-column=3 --print-column=3 \
  "${choices[@]}")

  local rc="$?"

  if [[ "$rc" -eq 0 && -n "$choice" ]]; then # User made a selection
    log d "choice: $choice"

    launch_command "$choice"
  else # User hit cancel
    configurator_welcome_dialog
  fi
}

# START THE CONFIGURATOR

# Show loading screen
(
  echo "0"
  echo "# Loading RetroDECK Configurator..."
  sleep 2  # Simulate a brief delay for the loading screen
  echo "100"
) 

rd_zenity --progress --no-cancel --pulsate --auto-close \
  --title="RetroDECK Configurator" \
  --text="Starting RetroDECK Configurator" \
  --width=400 --height=100 &

configurator_welcome_dialog
