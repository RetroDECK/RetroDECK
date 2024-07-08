#!/bin/bash

# VARIABLES SECTION

source /app/libexec/global.sh

# DIALOG SECTION

# Configurator Option Tree

# Welcome
#     - Presets & Settings
#       - Global: Presets & Settings
#         - Widescreen: Enable/Disable
#         - Ask-To-Exit: Enable/Disable
#         - Quick Resume: Enable/Disable
#         - RetroAchievements: Login
#         - RetroAchievements: Logout
#         - RetroAchievements: Hardcore Mode
#         - Rewind: Enable/Disable
#         - Swap A/B and X/Y Buttons: Enable/Disable
#       - RetroArch: Presets & Settings
#         - Borders: Enable/Disable
#       - Wii & GameCube: Presets & Settings
#         - Dolphin Textures: Universal Dynamic Input
#         - Primehack Textures: Universal Dynamic Input
#     - Open Emulator (Behind one-time power user warning dialog)
#       - RetroArch
#       - Cemu
#       - Citra
#       - Dolphin
#       - Duckstation
#       - MAME
#       - MelonDS
#       - PCSX2
#       - PPSSPP
#       - Primehack
#       - RPCS3
#       - Ryujinx
#       - Vita3K
#       - XEMU
#       - Yuzu
#     - Tools
#       - Tool: Move Folders
#         - Move all of RetroDECK
#         - Move ROMs folder
#         - Move BIOS folder
#         - Move Downloaded Media folder
#         - Move Saves folder
#         - Move States folder
#         - Move Themes folder
#         - Move Screenshots folder
#         - Move Mods folder
#         - Move Texture Packs folder
#       - Tool: Remove Empty ROM Folders
#       - Tool: Rebuild All ROM Folders
#       - Tool: Compress Games
#         - Compress Single Game
#         - Compress Multiple Games - CHD
#         - Compress Multiple Games - ZIP
#         - Compress Multiple Games - RVZ
#         - Compress Multiple Games - All Formats
#         - Compress All Games
#       - Tool: USB Import
#       - Install: RetroDECK Controller Layouts
#       - Install: PS3 firmware
#       - Install: PS Vita firmware
#       - RetroDECK: Change Update Setting
#     - Troubleshooting
#       - Backup: RetroDECK Userdata
#       - Check & Verify: BIOS
#       - Check & Verify: BIOS - Expert Mode
#       - Check & Verify: Multi-file structure
#       - RetroDECK: Reset
#         - Reset Emulator or Engine
#           - Reset RetroArch
#           - Reset Cemu
#           - Reset Citra
#           - Reset Dolphin
#           - Reset Duckstation
#           - Reset GZDoom
#           - Reset MAME
#           - Reset MelonDS
#           - Reset PCSX2
#           - Reset PPSSPP
#           - Reset Primehack
#           - Reset RPCS3
#           - Reset Ryujinx
#           - Reset Vita3k
#           - Reset XEMU
#           - Reset Yuzu
#         - Reset All Emulators
#         - Reset EmulationStation DE
#         - Reset RetroDECK
#     - RetroDECK: About
#       - RetroDECK Version History
#         - Full changelog
#         - Version-specific changelogs
#       - RetroDECK Credits
#     - Add to Steam
#     - Developer Options (Hidden)
#       - Change Multi-user mode
#       - Change Update channel
#       - Browse the wiki
#       - Install: RetroDECK Starter Pack

# DIALOG TREE FUNCTIONS

configurator_welcome_dialog() {
  log i "Configurator: opening welcome dialog"
  if [[ $developer_options == "true" ]]; then
    welcome_menu_options=("Presets & Settings" "Here you will find various presets, tweaks and settings to customize your RetroDECK experience" \
    "Open Emulator" "Launch and configure each emulator's settings (for advanced users)" \
    "RetroDECK: Tools" "Compress games, move RetroDECK and install optional features" \
    "RetroDECK: Troubleshooting" "Backup data, perform BIOS / multi-disc file checks and emulator resets" \
    "RetroDECK: About" "Show additional information about RetroDECK" \
    "Sync with Steam" "Sync all favorited games with Steam" \
    "Developer Options" "Welcome to the DANGER ZONE")
  else
    welcome_menu_options=("Presets & Settings" "Here you find various presets, tweaks and settings to customize your RetroDECK experience" \
    "Open Emulator" "Launch and configure each emulators settings (for advanced users)" \
    "RetroDECK: Tools" "Compress games, move RetroDECK and install optional features" \
    "RetroDECK: Troubleshooting" "Backup data, perform BIOS / multi-disc file checks checks and emulator resets" \
    "RetroDECK: About" "Show additional information about RetroDECK")
  fi

  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility" --cancel-label="Quit" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "${welcome_menu_options[@]}")

  case $choice in

  "Presets & Settings" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_presets_and_settings_dialog
  ;;

  "Open Emulator" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_power_user_warning_dialog
  ;;

  "RetroDECK: Tools" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_retrodeck_tools_dialog
  ;;

  "RetroDECK: Troubleshooting" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_retrodeck_troubleshooting_dialog
  ;;

  "RetroDECK: About" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_about_retrodeck_dialog
  ;;

  "Developer Options" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_generic_dialog "RetroDECK Configurator - Developer Options" "The following features and options are potentially VERY DANGEROUS for your RetroDECK install!\n\nThey should be considered the bleeding-edge of upcoming RetroDECK features, and never used when you have important saves/states/roms that are not backed up!\n\nYOU HAVE BEEN WARNED!"
    configurator_developer_dialog
  ;;

  "" )
    log i "Configurator: closing"
    exit 1
  ;;

  esac
}

configurator_presets_and_settings_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - Presets & Settings" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Global: Presets & Settings" "Here you find presets and settings that that span over multiple emulators" \
  "RetroArch: Presets & Settings" "Here you find presets and settings for RetroArch and its cores" \
  "Wii & GameCube: Presets & Settings" "Here you find presets and settings for Dolphin and Primehack" )

  case $choice in

  "Global: Presets & Settings" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_global_presets_and_settings_dialog
  ;;

  "RetroArch: Presets & Settings" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_retroarch_presets_and_settings_dialog
  ;;

  "Wii & GameCube: Presets & Settings" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_wii_and_gamecube_presets_and_settings_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_welcome_dialog
  ;;

  esac
}

configurator_global_presets_and_settings_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - Global: Presets & Settings" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Widescreen: Enable/Disable" "Enable or disable widescreen in supported systems" \
  "Ask-to-Exit: Enable/Disable" "Enable or disable emulators confirming attempts to quit in supported systems" \
  "Quick Resume: Enable/Disable" "Enable or disable save state auto-save/load in supported systems" \
  "RetroAchievements: Login" "Log into the RetroAchievements service in supported systems" \
  "RetroAchievements: Logout" "Disable RetroAchievements service in ALL supported systems" \
  "RetroAchievements: Hardcore Mode" "Enable RetroAchievements hardcore mode (no cheats, rewind, save states etc.) in supported systems" \
  "Rewind: Enable/Disable" "Enable or disable the rewind function in supported systems" \
  "Swap A/B and X/Y Buttons: Enable/Disable" "Enable or disable a swapped A/B and X/Y button layout in supported systems" )

  case $choice in

  "Widescreen: Enable/Disable" )
    log i "Configurator: opening \"$choice\" menu"
    change_preset_dialog "widescreen"
    configurator_global_presets_and_settings_dialog
  ;;

  "Ask-to-Exit: Enable/Disable" )
    log i "Configurator: opening \"$choice\" menu"
    change_preset_dialog "ask_to_exit"
    configurator_global_presets_and_settings_dialog
  ;;

  "Quick Resume: Enable/Disable" )
    change_preset_dialog "quick_resume"
    configurator_global_presets_and_settings_dialog
  ;;

  "RetroAchievements: Login" )
    local cheevos_creds=$(get_cheevos_token_dialog)
    if [[ ! "$cheevos_creds" == "failed" ]]; then
      configurator_generic_dialog "RetroDECK Configurator Utility - RetroAchievements" "RetroAchievements login successful, please select systems you would like to enable achievements for in the next dialog."
      IFS=',' read -r cheevos_username cheevos_token cheevos_login_timestamp < <(printf '%s\n' "$cheevos_creds")
      change_preset_dialog "cheevos"
    else
      configurator_generic_dialog "RetroDECK Configurator Utility - RetroAchievements" "RetroAchievements login failed, please verify your username and password and try the process again."
    fi
    configurator_global_presets_and_settings_dialog
  ;;

  "RetroAchievements: Logout" ) # This is a workaround to allow disabling cheevos without having to enter login credentials
    local cheevos_emulators=$(sed -n '/\[cheevos\]/, /\[/{ /\[cheevos\]/! { /\[/! p } }' $rd_conf | sed '/^$/d')
    for setting_line in $cheevos_emulators; do
      emulator=$(get_setting_name "$setting_line" "retrodeck")
      set_setting_value "$rdconf" "$emulator" "false" "retrodeck" "cheevos"
      build_preset_config "$emulator" "cheevos"
    done
    configurator_generic_dialog "RetroDECK Configurator Utility - RetroAchievements" "RetroAchievements has been disabled in all supported systems."
    configurator_global_presets_and_settings_dialog
  ;;

  "RetroAchievements: Hardcore Mode" )
    log i "Configurator: opening \"$choice\" menu"
    change_preset_dialog "cheevos_hardcore"
    configurator_global_presets_and_settings_dialog
  ;;

  "Rewind: Enable/Disable" )
    log i "Configurator: opening \"$choice\" menu"

    change_preset_dialog "rewind"
    configurator_global_presets_and_settings_dialog
  ;;

  "Swap A/B and X/Y Buttons: Enable/Disable" )
    log i "Configurator: opening \"$choice\" menu"

    change_preset_dialog "abxy_button_swap"
    configurator_global_presets_and_settings_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_presets_and_settings_dialog
  ;;

  esac
}

configurator_retroarch_presets_and_settings_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroArch: Presets & Settings" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Borders: Enable/Disable" "Enable or disable borders in supported systems" )

  case $choice in

  "Borders: Enable/Disable" )
    log i "Configurator: opening \"$choice\" menu"
    change_preset_dialog "borders"
    configurator_retroarch_presets_and_settings_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_presets_and_settings_dialog
  ;;

  esac
}

configurator_wii_and_gamecube_presets_and_settings_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - Wii & GameCube: Presets & Settings" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Dolphin Textures: Universal Dynamic Input" "Enable/Disable Venomalia's Universal Dynamic Input Textures for Dolphin" \
  "Primehack Textures: Universal Dynamic Input" "Enable/Disable: Venomalia's Universal Dynamic Input Textures for Primehack")

  case $choice in

  "Dolphin Textures: Universal Dynamic Input" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_dolphin_input_textures_dialog
  ;;

  "Primehack Textures: Universal Dynamic Input" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_primehack_input_textures_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_presets_and_settings_dialog
  ;;

  esac
}

configurator_dolphin_input_textures_dialog() {
  if [[ -d "/var/data/dolphin-emu/Load/DynamicInputTextures" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Dolphin Textures: Universal Dynamic Input" \
    --text="Custom input textures are currently enabled. Do you want to disable them?"

    if [ $? == 0 ]
    then
      # set_setting_value $dolphingfxconf "HiresTextures" "False" dolphin # TODO: Break out a preset for texture packs so this can be enabled and disabled independently.
      rm -rf "/var/data/dolphin-emu/Load/DynamicInputTextures"
      configurator_process_complete_dialog "disabling Dolphin custom input textures"
    else
      configurator_wii_and_gamecube_presets_and_settings_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Dolphin Textures: Universal Dynamic Input" \
    --text="Custom input textures are currently disabled. Do you want to enable them?\n\nThis process may take several minutes to complete."

    if [ $? == 0 ]
    then
      set_setting_value $dolphingfxconf "HiresTextures" "True" dolphin
      (
        mkdir "/var/data/dolphin-emu/Load/DynamicInputTextures"
        rsync -rlD --mkpath "/app/retrodeck/extras/DynamicInputTextures/" "/var/data/dolphin-emu/Load/DynamicInputTextures/"
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Dolphin Custom Input Textures Install"
      configurator_process_complete_dialog "enabling Dolphin custom input textures"
    else
      configurator_wii_and_gamecube_presets_and_settings_dialog
    fi
  fi
}

configurator_primehack_input_textures_dialog() {
  if [[ -d "/var/data/primehack/Load/DynamicInputTextures" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Dolphin Custom Input Textures" \
    --text="Custom input textures are currently enabled. Do you want to disable them?"

    if [ $? == 0 ]
    then
      # set_setting_value $primehackgfxconf "HiresTextures" "False" primehack # TODO: Break out a preset for texture packs so this can be enabled and disabled independently.
      rm -rf "/var/data/primehack/Load/DynamicInputTextures"
      configurator_process_complete_dialog "disabling Primehack custom input textures"
    else
      configurator_wii_and_gamecube_presets_and_settings_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Primehack Custom Input Textures" \
    --text="Custom input textures are currently disabled. Do you want to enable them?\n\nThis process may take several minutes to complete."

    if [ $? == 0 ]
    then
      set_setting_value $primehackgfxconf "HiresTextures" "True" primehack
      (
        mkdir "/var/data/primehack/Load/DynamicInputTextures"
        rsync -rlD --mkpath "/app/retrodeck/extras/DynamicInputTextures/" "/var/data/primehack/Load/DynamicInputTextures/"
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Primehack Custom Input Textures Install"
      configurator_process_complete_dialog "enabling Primehack custom input textures"
    else
      configurator_wii_and_gamecube_presets_and_settings_dialog
    fi
  fi
}

configurator_power_user_warning_dialog() {
  if [[ $power_user_warning == "true" ]]; then
    choice=$(rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Never show this again" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Power User Warning" \
    --text="Making manual changes to an emulator's configuration may create serious issues,\nand some settings may be overwitten during RetroDECK updates or when using presets.\n\nSome standalone emulator functions may not work properly outside of Desktop mode.\n\nPlease continue only if you know what you're doing.\n\nDo you want to continue?")
  fi
  rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "0" ]]; then # If user clicked "Yes"
    configurator_open_emulator_dialog
  else # If any button other than "Yes" was clicked
    if [[ $choice == "No" ]]; then
      configurator_welcome_dialog
    elif [[ $choice == "Never show this again" ]]; then
      set_setting_value $rd_conf "power_user_warning" "false" retrodeck "options" # Store power user warning variable for future checks
      configurator_open_emulator_dialog
    fi
  fi
}

configurator_open_emulator_dialog() {

  local emulator_list=(
    "RetroArch" "Open the multi-emulator frontend RetroArch"
    "Cemu" "Open the Wii U emulator CEMU"
    "Dolphin" "Open the Wii & GC emulator Dolphin"
    "Duckstation" "Open the PSX emulator Duckstation"
    "MAME" "Open the Multiple Arcade Machine Emulator emulator MAME"
    "MelonDS" "Open the NDS emulator MelonDS"
    "PCSX2" "Open the PS2 emulator PSXC2"
    "PPSSPP" "Open the PSP emulator PPSSPP"
    "Primehack" "Open the Metroid Prime emulator Primehack"
    "RPCS3" "Open the PS3 emulator RPCS3"
    "Ryujinx" "Open the Switch emulator Ryujinx"
    "Vita3K" "Open the PSVita emulator Vita3K"
    "XEMU" "Open the Xbox emulator XEMU"
  )

  # Check if any ponzu is true before adding Yuzu or Citra to the list
  if [[ $(get_setting_value "$rd_conf" "kiroi_ponzu" "retrodeck" "options") == "true" ]]; then
    emulator_list+=("Yuzu" "Open the Switch emulator Yuzu")
  fi
  if [[ $(get_setting_value "$rd_conf" "akai_ponzu" "retrodeck" "options") == "true" ]]; then
    emulator_list+=("Citra" "Open the 3DS emulator Citra")
  fi

  emulator=$(rd_zenity --list \
  --title "RetroDECK Configurator Utility - Open Emulator" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --text="Which emulator do you want to launch?" \
  --hide-header \
  --column="Emulator" --column="Action" \
  "${emulator_list[@]}")

  case $emulator in

  "RetroArch" )
    log i "Configurator: \"$emulator\""
    retroarch
  ;;

  "Cemu" )
    log i "Configurator: \"$emulator\""
    Cemu-wrapper
  ;;

  "Citra" )
    log i "Configurator: \"$emulator\""
    /var/data/ponzu/Citra/bin/citra-qt
  ;;

  "Dolphin" )
    log i "Configurator: \"$emulator\""
    dolphin-emu
  ;;

  "Duckstation" )
    log i "Configurator: \"$emulator\""
    duckstation-qt
  ;;

  "MAME" )
    log i "Configurator: \"$emulator\""
    mame -inipath /var/config/mame/ini
  ;;

  "MelonDS" )
    log i "Configurator: \"$emulator\""
    melonDS
  ;;

  "PCSX2" )
    log i "Configurator: \"$emulator\""
    pcsx2-qt
  ;;

  "PPSSPP" )
    log i "Configurator: \"$emulator\""
    PPSSPPSDL
  ;;

  "Primehack" )
    log i "Configurator: \"$emulator\""
    primehack-wrapper
  ;;

  "RPCS3" )
    log i "Configurator: \"$emulator\""
    rpcs3
  ;;

  "Ryujinx" )
    log i "Configurator: \"$emulator\""
    Ryujinx.sh
  ;;

  "Vita3K" )
    log i "Configurator: \"$emulator\""
    Vita3K
  ;;

  "XEMU" )
    log i "Configurator: \"$emulator\""
    xemu
  ;;

  "Yuzu" )
    log i "Configurator: \"$emulator\""
    /var/data/ponzu/Yuzu/bin/yuzu
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_welcome_dialog
  ;;

  esac

  configurator_open_emulator_dialog
}

configurator_retrodeck_tools_dialog() {

  local choices=(
  "Tool: Move Folders" "Move RetroDECK folders between internal/SD card or to a custom location"
  "Tool: Remove Empty ROM Folders" "Remove some or all of the empty ROM folders"
  "Tool: Rebuild All ROM Folders" "Rebuild any missing default ROM folders"
  "Tool: Compress Games" "Compress games for systems that support it"
  "Tool: USB Import" "Prepare a USB device for ROMs or import an existing collection"
  "Install: RetroDECK Controller Layouts" "Install the custom RetroDECK controller layouts on Steam"
  "Install: PS3 Firmware" "Download and install PS3 firmware for use with the RPCS3 emulator"
  "Install: PS Vita Firmware" "Download and install PS Vita firmware for use with the Vita3K emulator"
  "RetroDECK: Change Update Setting" "Enable or disable online checks for new versions of RetroDECK"
  )

  if [[ $(get_setting_value "$rd_conf" "kiroi_ponzu" "retrodeck" "options") == "true" ]]; then
    choices+=("Ponzu - Remove Yuzu" "Run Ponzu to remove Yuzu from RetroDECK. Configurations and saves will be mantained.")
  fi
  if [[ $(get_setting_value "$rd_conf" "akai_ponzu" "retrodeck" "options") == "true" ]]; then
    choices+=("Ponzu - Remove Citra" "Run Ponzu to remove Citra from RetroDECK. Configurations and saves will be mantained.")
  fi
  if [[ $(rclone listremotes) =~ "RetroDECK:" ]]; then
    choices+=("Cloud: Manual Sync" "Run a manual sync with the configured cloud instance. Functionality is in ALPHA.")
  fi

  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Tools" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "${choices[@]}")

  case $choice in

  "Tool: Move Folders" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_retrodeck_move_tool_dialog
  ;;

  "Tool: Remove Empty ROM Folders" )
    log i "Configurator: opening \"$choice\" menu"

    configurator_generic_dialog "RetroDECK Configurator - Remove Empty ROM Folders" "Before removing any identified empty ROM folders,\nplease make sure your ROM collection is backed up, just in case!"
    configurator_generic_dialog "RetroDECK Configurator - Remove Empty ROM Folders" "Searching for empty rom folders, please be patient..."
    find_empty_rom_folders

    choice=$(rd_zenity \
        --list --width=1200 --height=720 --title "RetroDECK Configurator - RetroDECK: Remove Empty ROM Folders" \
        --checklist --hide-column=3 --ok-label="Remove Selected" --extra-button="Remove All" \
        --separator="," --print-column=2 \
        --text="Choose which ROM folders to remove:" \
        --column "Remove?" \
        --column "System" \
        "${empty_rom_folders_list[@]}")

    local rc=$?
    if [[ $rc == "0" && ! -z $choice ]]; then # User clicked "Remove Selected" with at least one system selected
      IFS="," read -ra folders_to_remove <<< "$choice"
      for folder in "${folders_to_remove[@]}"; do
        log i "Removing empty folder $folder"
        rm -rf "$folder"
      done
      configurator_generic_dialog "RetroDECK Configurator - Remove Empty ROM Folders" "The removal process is complete."
    elif [[ ! -z $choice ]]; then # User clicked "Remove All"
      for folder in "${all_empty_folders[@]}"; do
        log i "Removing empty folder $folder"
        rm -rf "$folder"
      done
      configurator_generic_dialog "RetroDECK Configurator - Remove Empty ROM Folders" "The removal process is complete."
    fi

    configurator_retrodeck_tools_dialog
  ;;

  "Tool: Rebuild All ROM Folders" )
    log i "Configurator: opening \"$choice\" menu"
    es-de --create-system-dirs
    configurator_generic_dialog "RetroDECK Configurator - Rebuild All ROM Folders" "The rebuilding process is complete.\n\nAll missing default ROM folders will now exist in $roms_folder"
    configurator_retrodeck_tools_dialog
  ;;

  "Tool: Compress Games" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "Depending on your library and compression choices, the process can sometimes take a long time.\nPlease be patient once it is started!"
    configurator_compression_tool_dialog
  ;;

  "Tool: USB Import" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_usb_import_dialog
  ;;

  "Install: RetroDECK Controller Layouts" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_generic_dialog "RetroDECK Configurator - Install: RetroDECK Controller Profile" "We are now offering a new official RetroDECK controller profile!\nIt is an optional component that helps you get the most out of RetroDECK with a new in-game radial menu for unified hotkeys across emulators.\n\nThe files need to be installed outside of the normal ~/retrodeck folder, so we wanted your permission before proceeding.\n\nThe files will be installed at the following shared Steam locations:\n\n$HOME/.steam/steam/tenfoot/resource/images/library/controller/binding_icons/\n$HOME/.steam/steam/controller_base/templates"
    if [[ $(configurator_generic_question_dialog "Install: RetroDECK Controller Profile" "Would you like to install the official RetroDECK controller profile?") == "true" ]]; then
      install_retrodeck_controller_profile
      configurator_generic_dialog "RetroDECK Configurator - Install: RetroDECK Controller Profile" "The RetroDECK controller profile install is complete.\nSee the Wiki for more details on how to use it to its fullest potential!"
    fi
    configurator_retrodeck_tools_dialog
  ;;

  "Install: PS3 Firmware" )
    log i "Configurator: opening \"$choice\" menu"
    if [[ $(check_network_connectivity) == "true" ]]; then
      configurator_generic_dialog "RetroDECK Configurator - Install: PS3 firmware" "This tool will download firmware required by RPCS3 to emulate PS3 games.\n\nThe process will take several minutes, and the emulator will launch to finish the installation.\nPlease close RPCS3 manually once the installation is complete."
      (
        update_rpcs3_firmware
      ) |
        rd_zenity --progress --no-cancel --pulsate --auto-close \
        --icon-name=net.retrodeck.retrodeck \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title="Downloading PS3 Firmware" \
        --width=400 --height=200 \
        --text="Dowloading and installing PS3 Firmware, please be patient.\n\n<span foreground='$purple' size='larger'><b>NOTICE - If the process is taking too long:</b></span>\n\nSome windows might be running in the background that could require your attention: pop-ups from emulators or the upgrade itself that needs user input to continue.\n\n"

    else
      configurator_generic_dialog "RetroDECK Configurator - Install: PS3 Firmware" "You do not appear to currently have Internet access, which is required by this tool. Please try again when network access has been restored."
      configurator_retrodeck_tools_dialog
    fi
  ;;

  "Install: PS Vita Firmware" )
    if [[ $(check_network_connectivity) == "true" ]]; then
      configurator_generic_dialog "RetroDECK Configurator - Install: PS Vita firmware" "This tool will download firmware required by Vita3K to emulate PS Vita games.\n\nThe process will take several minutes, and the emulator will launch to finish the installation.\nPlease close Vita3K manually once the installation is complete."
      (
        update_vita3k_firmware
      ) |
        rd_zenity --progress --pulsate \
        --icon-name=net.retrodeck.retrodeck \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title="Downloading PS Vita Firmware" \
        --no-cancel \
        --auto-close
    else
      configurator_generic_dialog "RetroDECK Configurator - Install: PS Vita Firmware" "You do not appear to currently have Internet access, which is required by this tool. Please try again when network access has been restored."
      configurator_retrodeck_tools_dialog
    fi
  ;;

  "RetroDECK: Change Update Setting" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_online_update_setting_dialog
  ;;

  "Ponzu - Remove Yuzu" )
    ponzu_remove "yuzu"
  ;;

  "Ponzu - Remove Citra" )
    ponzu_remove "citra"
  ;;

  "Cloud: Manual Sync" )
    sync_cloud newer
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_welcome_dialog
  ;;

  esac
}

configurator_retrodeck_move_tool_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Move Tool" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Move all of RetroDECK" "Move the entire retrodeck folder to a new location" \
  "Move ROMs folder" "Move only the ROMs folder to a new location" \
  "Move BIOS folder" "Move only the BIOS folder to a new location" \
  "Move Downloaded Media folder" "Move only the Downloaded Media folder to a new location" \
  "Move Saves folder" "Move only the Saves folder to a new location" \
  "Move States folder" "Move only the States folder to a new location" \
  "Move Themes folder" "Move only the Themes folder to a new location" \
  "Move Screenshots folder" "Move only the Screenshots folder to a new location" \
  "Move Mods folder" "Move only the Mods folder to a new location" \
  "Move Texture Packs folder" "Move only the Texture Packs folder to a new location" )

  case $choice in

  "Move all of RetroDECK" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_move_folder_dialog "rdhome"
  ;;

  "Move ROMs folder" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_move_folder_dialog "roms_folder"
  ;;

  "Move BIOS folder" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_move_folder_dialog "bios_folder"
  ;;

  "Move Downloaded Media folder" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_move_folder_dialog "media_folder"
  ;;

  "Move Saves folder" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_move_folder_dialog "saves_folder"
  ;;

  "Move States folder" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_move_folder_dialog "states_folder"
  ;;

  "Move Themes folder" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_move_folder_dialog "themes_folder"
  ;;

  "Move Screenshots folder" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_move_folder_dialog "screenshots_folder"
  ;;

  "Move Mods folder" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_move_folder_dialog "mods_folder"
  ;;

  "Move Texture Packs folder" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_move_folder_dialog "texture_packs_folder"
  ;;

  esac

  configurator_retrodeck_tools_dialog
}

configurator_compression_tool_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Compression Tool" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Compress Single Game" "Compress a single game into a compatible format" \
  "Compress Multiple Games - CHD" "Compress one or more games compatible with the CHD format" \
  "Compress Multiple Games - ZIP" "Compress one or more games compatible with the ZIP format" \
  "Compress Multiple Games - RVZ" "Compress one or more games compatible with the RVZ format" \
  "Compress Multiple Games - All Formats" "Compress one or more games compatible with any format" \
  "Compress All Games" "Compress all games into compatible formats" )

  case $choice in

  "Compress Single Game" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_single_game_dialog
  ;;

  "Compress Multiple Games - CHD" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "chd"
  ;;

  "Compress Multiple Games - ZIP" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "zip"
  ;;

  "Compress Multiple Games - RVZ" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "rvz"
  ;;

  "Compress Multiple Games - All Formats" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "all"
  ;;

  "Compress All Games" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "everything"
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_retrodeck_tools_dialog
  ;;

  esac
}

configurator_compress_single_game_dialog() {
  local file=$(file_browse "Game to compress")
  if [[ ! -z "$file" ]]; then
    local system=$(echo "$file" | grep -oE "$roms_folder/[^/]+" | grep -oE "[^/]+$")
    local compatible_compression_format=$(find_compatible_compression_format "$file")
    if [[ ! $compatible_compression_format == "none" ]]; then
      local post_compression_cleanup=$(configurator_compression_cleanup_dialog)
      (
      echo "# Compressing $(basename "$file") to $compatible_compression_format format" # This updates the Zenity dialog
      log i "Compressing $(basename "$file") to $compatible_compression_format format"
      compress_game "$compatible_compression_format" "$file" "$system"
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Compression in Progress"
      configurator_generic_dialog "RetroDECK Configurator - RetroDECK: Compression Tool" "The compression process is complete."
      configurator_compression_tool_dialog

    else
      configurator_generic_dialog "RetroDECK Configurator - RetroDECK: Compression Tool" "The selected file does not have any compatible compression formats."
      configurator_compression_tool_dialog
    fi
  else
    configurator_compression_tool_dialog
  fi
}

configurator_compress_multiple_games_dialog() {
  # This dialog will display any games it finds to be compressable, from the systems listed under each compression type in compression_targets.cfg

  find_compatible_games "$1"

  if [[ ! $(echo "${#all_compressable_games[@]}") == "0" ]]; then
    if [[ ! "$target_selection" == "everything" ]]; then # If the user chose to not auto-compress everything
      choice=$(rd_zenity \
          --list --width=1200 --height=720 --title "RetroDECK Configurator - RetroDECK: Compression Tool" \
          --checklist --hide-column=3 --ok-label="Compress Selected" --extra-button="Compress All" \
          --separator="," --print-column=3 \
          --text="Choose which games to compress:" \
          --column "Compress?" \
          --column "Game" \
          --column "Game Full Path" \
          "${compressable_games_list[@]}")

      local rc=$?
      if [[ $rc == "0" && ! -z $choice ]]; then # User clicked "Compress Selected" with at least one game selected
        IFS="," read -ra games_to_compress <<< "$choice"
        local total_games_to_compress=${#games_to_compress[@]}
        local games_left_to_compress=$total_games_to_compress
      elif [[ ! -z $choice ]]; then # User clicked "Compress All"
        games_to_compress=("${all_compressable_games[@]}")
        local total_games_to_compress=${#all_compressable_games[@]}
        local games_left_to_compress=$total_games_to_compress
      fi
    else # The user chose to auto-compress everything
      games_to_compress=("${all_compressable_games[@]}")
      local total_games_to_compress=${#all_compressable_games[@]}
      local games_left_to_compress=$total_games_to_compress
    fi
  else
    configurator_generic_dialog "RetroDECK Configurator - RetroDECK: Compression Tool" "No compressable files were found."
  fi

  if [[ ! $(echo "${#games_to_compress[@]}") == "0" ]]; then
    local post_compression_cleanup=$(configurator_compression_cleanup_dialog)
    (
    for file in "${games_to_compress[@]}"; do
      local system=$(echo "$file" | grep -oE "$roms_folder/[^/]+" | grep -oE "[^/]+$")
      local compression_format=$(find_compatible_compression_format "$file")
      echo "# Compressing $(basename "$file") into $compression_format format" # Update Zenity dialog text
      log i "Compressing $(basename "$file") into $compression_format format"
      progress=$(( 100 - (( 100 / "$total_games_to_compress" ) * "$games_left_to_compress" )))
      echo $progress
      games_left_to_compress=$((games_left_to_compress-1))
      log i "Games left to compress: $games_left_to_compress"
      compress_game "$compression_format" "$file" "$system"
    done
    ) |
    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Compression in Progress"
      configurator_generic_dialog "RetroDECK Configurator - RetroDECK: Compression Tool" "The compression process is complete!"
      configurator_compression_tool_dialog
  else
    configurator_compression_tool_dialog
  fi
}

configurator_compression_cleanup_dialog() {
  rd_zenity --icon-name=net.retrodeck.retrodeck --question --no-wrap --cancel-label="No" --ok-label="Yes" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - RetroDECK: Compression Tool" \
  --text="Do you want to remove old files after they are compressed?\n\nClicking \"No\" will leave all files behind which will need to be cleaned up manually and may result in game duplicates showing in the RetroDECK library.\n\nPlease make sure you have a backup of your ROMs before using automatic cleanup!"
  local rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "0" ]]; then # If user clicked "Yes"
    echo "true"
  else # If "No" was clicked
    echo "false"
  fi
}

configurator_usb_import_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - Developer Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Prepare USB device" "Create ROM and BIOS folders on a selected USB device" \
  "Import from USB" "Import collection from a previously prepared device" )

  case $choice in

  "Prepare USB device" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_generic_dialog "RetroDeck Configurator - USB Import" "If you have an SD card installed that is not currently configured in RetroDECK it may show up in this list, but not be suitable for USB import.\n\nPlease select your desired drive carefully."

    external_devices=()

    while read -r size device_path; do
      device_name=$(basename "$device_path")
      external_devices=("${external_devices[@]}" "$device_name" "$size" "$device_path")
    done < <(df --output=size,target -h | grep "/run/media/" | grep -v "$sdcard" | awk '{$1=$1;print}')

    if [[ "${#external_devices[@]}" -gt 0 ]]; then
      choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - USB Migration Tool" --cancel-label="Back" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ ! -z "$choice" ]]; then
        es-de --home "$choice/RetroDECK Import" --create-system-dirs
        rm -rf "$choice/RetroDECK Import/ES-DE" # Cleanup unnecessary folder
        create_dir "$choice/RetroDECK Import/BIOS"

        # Prepare default BIOS folder subfolders
        create_dir "$choice/RetroDECK Import/BIOS/np2kai"
        create_dir "$choice/RetroDECK Import/BIOS/dc"
        create_dir "$choice/RetroDECK Import/BIOS/Mupen64plus"
        create_dir "$choice/RetroDECK Import/BIOS/quasi88"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/samples"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/cheats"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/blend"
        create_dir "$choice/RetroDECK Import/BIOS/fbneo/patched"
        create_dir "$choice/RetroDECK Import/BIOS/citra/sysdata"
        create_dir "$choice/RetroDECK Import/BIOS/cemu"
        create_dir "$choice/RetroDECK Import/BIOS/pico-8/carts"
        create_dir "$choice/RetroDECK Import/BIOS/pico-8/cdata"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_hdd0"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_hdd1"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_flash"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_flash2"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_flash3"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_bdvd"
        create_dir "$choice/RetroDECK Import/BIOS/rpcs3/dev_usb000"
        create_dir "$choice/RetroDECK Import/BIOS/Vita3K/"
        create_dir "$choice/RetroDECK Import/BIOS/mame-sa/samples"
        create_dir "$choice/RetroDECK Import/BIOS/gzdoom"
      fi
    else
      configurator_generic_dialog "RetroDeck Configurator - USB Import" "There were no USB devices found."
    fi
    configurator_usb_import_dialog
  ;;

  "Import from USB" )
    log i "Configurator: opening \"$choice\" menu"
    external_devices=()

    while read -r size device_path; do
      if [[ -d "$device_path/RetroDECK Import/ROMs" ]]; then
        device_name=$(basename "$device_path")
        external_devices=("${external_devices[@]}" "$device_name" "$size" "$device_path")
      fi
    done < <(df --output=size,target -h | grep "/run/media/" | grep -v "$sdcard" | awk '{$1=$1;print}')

    if [[ "${#external_devices[@]}" -gt 0 ]]; then
      choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - USB Migration Tool" --cancel-label="Back" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ ! -z "$choice" ]]; then
        if [[ $(verify_space "$choice/RetroDECK Import/ROMs" "$roms_folder") == "false" || $(verify_space "$choice/RetroDECK Import/BIOS" "$bios_folder") == "false" ]]; then
          if [[ $(configurator_generic_question_dialog "RetroDECK Configurator Utility - USB Migration Tool" "You MAY not have enough free space to import this ROM/BIOS library.\n\nThis utility only imports new additions from the USB device, so if there are a lot of the same files in both locations you are likely going to be fine\nbut we are not able to verify how much data will be transferred before it happens.\n\nIf you are unsure, please verify your available free space before continuing.\n\nDo you want to continue now?") == "true" ]]; then
            (
            rsync -a --mkpath "$choice/RetroDECK Import/ROMs/"* "$roms_folder"
            rsync -a --mkpath "$choice/RetroDECK Import/BIOS/"* "$bios_folder"
            ) |
            rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - USB Import In Progress"
            configurator_generic_dialog "RetroDECK Configurator - USB Migration Tool" "The import process is complete!"
          fi
        else
          (
          rsync -a --mkpath "$choice/RetroDECK Import/ROMs/"* "$roms_folder"
          rsync -a --mkpath "$choice/RetroDECK Import/BIOS/"* "$bios_folder"
          ) |
          rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK Configurator Utility - USB Import In Progress"
          configurator_generic_dialog "RetroDECK Configurator - USB Migration Tool" "The import process is complete!"
        fi
      fi
    else
      configurator_generic_dialog "RetroDeck Configurator - USB Import" "There were no USB devices found with an importable folder."
    fi
    configurator_usb_import_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_retrodeck_tools_dialog
  ;;
  esac
}

configurator_online_update_setting_dialog() {
  if [[ $(get_setting_value $rd_conf "update_check" retrodeck "options") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Online Update Check" \
    --text="Online update checks for RetroDECK are currently enabled.\n\nDo you want to disable them?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value $rd_conf "update_check" "false" retrodeck "options"
    else # User clicked "Cancel"
      configurator_retrodeck_tools_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Online Update Check" \
    --text="Online update checks for RetroDECK are currently disabled.\n\nDo you want to enable them?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value $rd_conf "update_check" "true" retrodeck "options"
    else # User clicked "Cancel"
      configurator_retrodeck_tools_dialog
    fi
  fi
}

configurator_retrodeck_troubleshooting_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Troubleshooting" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Backup: RetroDECK Userdata" "Compress and backup important RetroDECK user data folders" \
  "Check & Verify: BIOS Files" "Show information about common BIOS files" \
  "Check & Verify: BIOS Files - Expert Mode" "Show information about common BIOS files, with additional information useful for troubleshooting" \
  "Check & Verify: Multi-file structure" "Verify the proper structure of multi-file or multi-disc games" \
  "RetroDECK: Reset" "Reset specific parts or all of RetroDECK" )

  case $choice in

  "Backup: RetroDECK Userdata" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_generic_dialog "RetroDECK Configurator - Backup: RetroDECK Userdata" "This tool will compress important RetroDECK userdata (basically everything except the ROMs folder) into a zip file.\n\nThis process can take several minutes, and the resulting zip file can be found in the ~/retrodeck/backups folder."
    (
      backup_retrodeck_userdata
    ) |
    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - Backup in Progress" \
            --text="Backing up RetroDECK userdata, please wait..."
    if [[ -f "$backups_folder/$(date +"%0m%0d")_retrodeck_userdata.zip" ]]; then
      configurator_generic_dialog "RetroDECK Configurator - Backup: RetroDECK Userdata" "The backup process is now complete."
    else
      configurator_generic_dialog "RetroDECK Configurator - Backup: RetroDECK Userdata" "The backup process could not be completed,\nplease check the logs folder for more information."
    fi
    configurator_retrodeck_troubleshooting_dialog
  ;;

  "Check & Verify: BIOS Files" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_check_bios_files
  ;;

  "Check & Verify: BIOS Files - Expert Mode" )
    configurator_check_bios_files_expert_mode
  ;;

  "Check & Verify: Multi-file structure" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_check_multifile_game_structure
  ;;

  "RetroDECK: Reset" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_reset_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_welcome_dialog
  ;;

  esac
}

configurator_check_bios_files() {
  configurator_generic_dialog "RetroDECK Configurator - Check & Verify: BIOS Files" "This check will look for BIOS files that RetroDECK has identified as working.\n\nNot all BIOS files are required for games to work, please check the BIOS description for more information on its purpose.\n\nBIOS files not known to this tool could still function.\n\nSome more advanced emulators such as Ryujinx will have additional methods to verify that the BIOS files are in working order."
  bios_checked_list=()

  check_bios_files "basic"

  rd_zenity --list --title="RetroDECK Configurator Utility - Check & Verify: BIOS Files" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column "BIOS File Name" \
  --column "System" \
  --column "BIOS File Found" \
  --column "BIOS Hash Match" \
  --column "BIOS File Description" \
  "${bios_checked_list[@]}"

  configurator_retrodeck_troubleshooting_dialog
}

configurator_check_bios_files_expert_mode() {
  configurator_generic_dialog "RetroDECK Configurator - Check & Verify: BIOS Files - Expert Mode" "This check will look for BIOS files that RetroDECK has identified as working.\n\nNot all BIOS files are required for games to work, please check the BIOS description for more information on its purpose.\n\nBIOS files not known to this tool could still function.\n\nSome more advanced emulators such as Ryujinx will have additional methods to verify that the BIOS files are in working order."
  bios_checked_list=()

  check_bios_files "expert"

  rd_zenity --list --title="RetroDECK Configurator Utility - Check & Verify: BIOS Files" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column "BIOS File Name" \
  --column "System" \
  --column "BIOS File Found" \
  --column "BIOS Hash Match" \
  --column "BIOS File Description" \
  --column "BIOS File Subdirectory" \
  --column "BIOS File Hash" \
  "${bios_checked_list[@]}"

  configurator_retrodeck_troubleshooting_dialog
}

configurator_check_multifile_game_structure() {
  local folder_games=($(find $roms_folder -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3"))
  if [[ ${#folder_games[@]} -gt 1 ]]; then
    echo "$(find $roms_folder -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3")" > $logs_folder/multi_file_games_"$(date +"%Y_%m_%d_%I_%M_%p").log"
    rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Check & Verify: Multi-file structure" \
    --text="The following games were found to have the incorrect folder structure:\n\n$(find $roms_folder -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3")\n\nIncorrect folder structure can result in failure to launch games or saves being in the incorrect location.\n\nPlease see the RetroDECK wiki for more details!\n\nYou can find this list of games in ~/retrodeck/logs"
  else
    configurator_generic_dialog "RetroDECK Configurator - Check & Verify: Multi-file structure" "No incorrect multi-file game folder structures found."
  fi
  configurator_retrodeck_troubleshooting_dialog
}

configurator_reset_dialog() {

  local choices=(
    "Reset Emulator or Engine" "Reset only one specific emulator or engine to default settings"
    "Reset RetroDECK Component" "Reset a single component, components are parts of RetroDECK that are not emulators"
    "Reset All Emulators and Components" "Reset all emulators and components to default settings"
    "Reset RetroDECK" "Reset RetroDECK to default settings"
  )

  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Reset" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "${choices[@]}")

  local emulator_list=(
    "RetroArch" "Reset the multi-emulator frontend RetroArch to default settings"
    "Cemu" "Reset the Wii U emulator Cemu to default settings"
    "Dolphin" "Reset the Wii/GameCube emulator Dolphin to default settings"
    "Duckstation" "Reset the PSX emulator Duckstation to default settings"
    "GZDoom" "Reset the GZDoom Doom engine to default settings"
    "MAME" "Reset the Multiple Arcade Machine Emulator (MAME) to default settings"
    "MelonDS" "Reset the NDS emulator MelonDS to default settings"
    "PCSX2" "Reset the PS2 emulator PCSX2 to default settings"
    "PPSSPP" "Reset the PSP emulator PPSSPP to default settings"
    "Primehack" "Reset the Metroid Prime emulator Primehack to default settings"
    "RPCS3" "Reset the PS3 emulator RPCS3 to default settings"
    "Ryujinx" "Reset the Switch emulator Ryujinx to default settings"
    "Vita3k" "Reset the PS Vita emulator Vita3k to default settings"
    "XEMU" "Reset the XBOX emulator XEMU to default settings"
  )

  # Check if any ponzu is true before adding Yuzu or Citra to the list
  if [[ $(get_setting_value "$rd_conf" "kiroi_ponzu" "retrodeck" "options") == "true" ]]; then
    emulator_list+=("Yuzu" "Reset the Switch emulator Yuzu")
  fi
  if [[ $(get_setting_value "$rd_conf" "akai_ponzu" "retrodeck" "options") == "true" ]]; then
    emulator_list+=("Citra" "Reset the 3DS emulator Citra")
  fi

  case $choice in

  "Reset Emulator or Engine" )
    log i "Configurator: opening \"$choice\" menu"
    component_to_reset=$(rd_zenity --list \
    --title "RetroDECK Configurator Utility - Reset Specific Standalone Emulator" --cancel-label="Back" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
    --text="Which emulator or engine do you want to reset to default?" \
    --column="Emulator" --column="Action" \
    "${emulator_list[@]}")

    case $component_to_reset in

    "RetroArch" | "Vita3k" | "XEMU" ) # Emulators that require network access
      if [[ $(check_network_connectivity) == "true" ]]; then
        if [[ $(configurator_reset_confirmation_dialog "$component_to_reset" "Are you sure you want to reset the $component_to_reset emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
          prepare_component "reset" "$component_to_reset" "configurator"
          configurator_process_complete_dialog "resetting $component_to_reset"
        else
          configurator_generic_dialog "RetroDeck Configurator - RetroDECK: Reset" "Reset process cancelled."
          configurator_reset_dialog
        fi
      else
        configurator_generic_dialog "RetroDeck Configurator - RetroDECK: Reset" "Resetting this emulator requires active network access.\nPlease try again when you are connected to an Internet-capable network.\n\nReset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "Cemu" | "Citra" | "Dolphin" | "Duckstation" | "GZDoom" | "Yuzu" | "MelonDS" | "MAME" | "PCSX2" | "PPSSPP" | "Primehack" | "RPCS3" | "Ryujinx" )
      if [[ $(configurator_reset_confirmation_dialog "$component_to_reset" "Are you sure you want to reset the $component_to_reset emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        prepare_component "reset" "$component_to_reset" "configurator"
        configurator_process_complete_dialog "resetting $component_to_reset"
      else
        configurator_generic_dialog "RetroDeck Configurator - RetroDECK: Reset" "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "" ) # No selection made or Back button clicked
      configurator_reset_dialog
    ;;

    esac
  ;;

  "Reset RetroDECK Component" )
    component_to_reset=$(rd_zenity --list \
    --title "RetroDECK Configurator Utility - Reset Specific RetroDECK Component" --cancel-label="Back" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
    --text="Which component do you want to reset to default settings?" \
    --column="Component" --column="Action" \
    "ES-DE" "Reset the ES-DE frontend" \ )
    # TODO: "GyroDSU" "Reset the gyroscope manager GyroDSU"

    case $component_to_reset in

    "ES-DE" ) # TODO: GyroDSU
      if [[ $(configurator_reset_confirmation_dialog "$component_to_reset" "Are you sure you want to reset $component_to_reset to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        prepare_component "reset" "$component_to_reset" "configurator"
        configurator_process_complete_dialog "resetting $component_to_reset"
      else
        configurator_generic_dialog "RetroDeck Configurator - RetroDECK: Reset" "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "" ) # No selection made or Back button clicked
      configurator_reset_dialog
    ;;

    esac
  ;;

"Reset All Emulators and Components" )
  log i "Configurator: opening \"$choice\" menu"
  if [[ $(check_network_connectivity) == "true" ]]; then
    if [[ $(configurator_reset_confirmation_dialog "all emulators" "Are you sure you want to reset all emulators to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
      (
      prepare_component "reset" "all"
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Finishing Initialization" \
      --text="RetroDECK is finishing the reset process, please wait."
      configurator_process_complete_dialog "resetting all emulators"
    else
      configurator_generic_dialog "RetroDeck Configurator - RetroDECK: Reset" "Reset process cancelled."
      configurator_reset_dialog
    fi
  else
    configurator_generic_dialog "RetroDeck Configurator - RetroDECK: Reset" "Resetting all emulators requires active network access.\nPlease try again when you are connected to an Internet-capable network.\n\nReset process cancelled."
    configurator_reset_dialog
  fi
;;

"Reset RetroDECK" )
  log i "Configurator: opening \"$choice\" menu"
  if [[ $(configurator_reset_confirmation_dialog "RetroDECK" "Are you sure you want to reset RetroDECK entirely?\n\nThis process cannot be undone.") == "true" ]]; then
    rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility - Reset RetroDECK" \
    --text="You are resetting RetroDECK to its default state.\n\nAfter the process is complete you will need to exit RetroDECK and run it again, where you will go through the initial setup process."
    rm -f "$lockfile"
    rm -f "$rd_conf"
    configurator_process_complete_dialog "resetting RetroDECK"
  else
    configurator_generic_dialog "RetroDeck Configurator - RetroDECK: Reset" "Reset process cancelled."
    configurator_reset_dialog
  fi
;;

"" ) # No selection made or Back button clicked
  configurator_retrodeck_troubleshooting_dialog
;;

  esac
}

configurator_about_retrodeck_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroDECK: About" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Version History" "View the version changelogs for RetroDECK" \
  "Credits" "View the contribution credits for RetroDECK" )

  case $choice in

  "Version History" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_version_history_dialog
  ;;

  "Credits" )
    log i "Configurator: opening \"$choice\" menu"
    rd_zenity --icon-name=net.retrodeck.retrodeck --text-info --width=1200 --height=720 \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Credits" \
    --filename="$emuconfigs/defaults/retrodeck/reference_lists/retrodeck_credits.txt"
    configurator_about_retrodeck_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_welcome_dialog
  ;;

  esac
}

configurator_version_history_dialog() {
  local version_array=($(xml sel -t -v '//component/releases/release/@version' -n $rd_appdata))
  local all_versions_list=()

  for rd_version in ${version_array[*]}; do
    all_versions_list=("${all_versions_list[@]}" "RetroDECK $rd_version Changelog" "View the changes specific to version $rd_version")
  done

  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - RetroDECK Version History" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Full RetroDECK Changelog" "View the list of all changes that have ever been made to RetroDECK" \
  "${all_versions_list[@]}")

  case $choice in

  "Full RetroDECK Changelog" )
    log i "Configurator: opening \"$choice\" menu"
    changelog_dialog "all"
  ;;

  "RetroDECK"*"Changelog" )
    log i "Configurator: opening \"$choice\" menu"
    local version=$(echo "$choice" | sed 's/^RetroDECK \(.*\) Changelog$/\1/')
    changelog_dialog "$version"
  ;;

  esac

  configurator_about_retrodeck_dialog
}

configurator_developer_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - Developer Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Change Multi-user mode" "Enable or disable multi-user support" \
  "Change Update Channel" "Change between normal and cooker builds" \
  "Configure Cloud Sync" "Enable, disable, or edit cloud configuration" \
  "Browse the Wiki" "Browse the RetroDECK wiki online" \
  "Install RetroDECK Starter Pack" "Install the optional RetroDECK starter pack" )

  case $choice in

  "Change Multi-user mode" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_retrodeck_multiuser_dialog
  ;;

  "Change Update Channel" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_online_update_channel_dialog
  ;;

  "Configure Cloud Sync" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_cloud_sync_dialog
  ;;

  "Browse the Wiki" )
    log i "Configurator: opening \"$choice\" menu"
    xdg-open "https://github.com/XargonWan/RetroDECK/wiki"
    configurator_developer_dialog
  ;;

  "Install RetroDECK Starter Pack" )
    log i "Configurator: opening \"$choice\" menu"
    if [[ $(configurator_generic_question_dialog "Install: RetroDECK Starter Pack" "The RetroDECK creators have put together a collection of classic retro games you might enjoy!\n\nWould you like to have them automatically added to your library?") == "true" ]]; then
      install_retrodeck_starterpack
    fi
    configurator_developer_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_welcome_dialog
  ;;
  esac
}

configurator_retrodeck_multiuser_dialog() {
  if [[ $(get_setting_value $rd_conf "multi_user_mode" retrodeck "options") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Multi-user Support" \
    --text="Multi-user support is currently enabled. Do you want to disable it?\n\nIf there is more than one user configured,\nyou will be given a choice of which to use as the single RetroDECK user.\n\nThis user's files will be moved to the default locations.\n\nOther users' files will remain in the mutli-user-data folder.\n"

    if [ $? == 0 ] # User clicked "Yes"
    then
      multi_user_disable_multi_user_mode
    else # User clicked "Cancel"
      configurator_developer_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Multi-user support" \
    --text="Multi-user support is currently disabled. Do you want to enable it?\n\nThe current user's saves and states will be backed up and then moved to the \"retrodeck/multi-user-data\" folder.\nAdditional users will automatically be stored in their own folder here as they are added."

    if [ $? == 0 ]
    then
      multi_user_enable_multi_user_mode
    else
      configurator_developer_dialog
    fi
  fi
}

configurator_online_update_channel_dialog() {
  if [[ $(get_setting_value $rd_conf "update_repo" retrodeck "options") == "RetroDECK" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Change Update Branch" \
    --text="You are currently on the production branch of RetroDECK updates. Would you like to switch to the cooker branch?\n\nAfter installing a cooker build, you may need to remove the \"stable\" branch install of RetroDECK to avoid overlap."

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value $rd_conf "update_repo" "RetroDECK-cooker" retrodeck "options"
    else # User clicked "Cancel"
      configurator_developer_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Change Update Branch" \
    --text="You are currently on the cooker branch of RetroDECK updates. Would you like to switch to the production branch?\n\nAfter installing a production build, you may need to remove the \"cooker\" branch install of RetroDECK to avoid overlap."

    if [ $? == 0 ] # User clicked "Yes"
    then
      set_setting_value $rd_conf "update_repo" "RetroDECK" retrodeck "options"
    else # User clicked "Cancel"
      configurator_developer_dialog
    fi
  fi
}

configurator_cloud_sync_dialog() {
  if [[ $(rclone listremotes) =~ "RetroDECK:" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Cloud Sync" \
    --text="You currently have cloud sync set up. Would you like to disable cloud sync?\n\nDisabling cloud syncing and then setting it up again has NOT been tested. Please backup your data.\n\n(We recognise the irony of this statement.)"

    if [ $? == 0 ] # User clicked "Yes"
    then
      unset_cloud
    else # User clicked "Cancel"
      configurator_developer_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Change Update Branch" \
    --text="No cloud sync config was detected. Would you like to set it up?\n\nThis functionality is in ALPHA, and RetroDECK is not responsible for any lost data. You have been warned."

    if [ $? == 0 ] # User clicked "Yes"
    then
      configurator_cloud_provider_dialog
    else # User clicked "Cancel"
      configurator_developer_dialog
    fi
  fi
}

configurator_cloud_provider_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Cloud Cloud Sync - Cloud Provider" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" \
  "Box" \
  "Dropbox" \
  "Google Drive" \
  "OneDrive" )

  case $choice in

  "Box" )
    set_cloud box newer
  ;;

  "Dropbox" )
    set_cloud dropbox newer
  ;;

  "Google Drive" )
    set_cloud drive newer
  ;;

  "OneDrive" )
    set_cloud onedrive newer
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_developer_dialog
  ;;
  esac
}

# START THE CONFIGURATOR

configurator_welcome_dialog
