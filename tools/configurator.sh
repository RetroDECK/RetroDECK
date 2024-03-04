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
#         - RetroAchievements: Login
#         - RetroAchievements: Logout
#         - RetroAchievements: Hardcore Mode
#         - Swap A/B and X/Y Buttons
#       - RetroArch: Presets & Settings
#         - Borders: Enable/Disable
#         - Rewind: Enable/Disable
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
#       - Tool: Compress Games
#         - Compress Single Game
#         - Compress Multiple Games - CHD
#         - Compress Multiple Games - ZIP
#         - Compress Multiple Games - RVZ
#         - Compress Multiple Games - All Formats
#         - Compress All Games
#       - Install: RetroDECK SD Controller Profile
#       - Install: PS3 firmware
#       - RetroDECK: Change Update Setting
#     - Troubleshooting
#       - Backup: RetroDECK Userdata
#       - Check & Verify: BIOS
#       - Check & Verify: Multi-file structure
#       - RetroDECK: Reset
#         - Reset Specific Emulator
#           - Reset RetroArch
#           - Reset Cemu
#           - Reset Citra
#           - Reset Dolphin
#           - Reset Duckstation
#           - Reset MelonDS
#           - Reset PCSX2
#           - Reset PPSSPP
#           - Reset Primehack
#           - Reset RPCS3
#           - Reset Ryujinx
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
#       - USB Import tool
#       - Install: RetroDECK Starter Pack

# DIALOG TREE FUNCTIONS

configurator_welcome_dialog() {
  if [[ $developer_options == "true" ]]; then
    welcome_menu_options=("Presets & Settings" "Here you find various presets, tweaks and settings to customize your RetroDECK experience" \
    "Open Emulator" "Launch and configure each emulators settings (for advanced users)" \
    "RetroDECK: Tools" "Compress games, move RetroDECK and install optional features" \
    "RetroDECK: Troubleshooting" "Backup data, perform BIOS / multi-disc file checks checks and emulator resets" \
    "RetroDECK: About" "Show additional information about RetroDECK" \
    "Sync with Steam" "Sync with Steam all the favorites games" \
    "Developer Options" "Welcome to the DANGER ZONE")
  else
    welcome_menu_options=("Presets & Settings" "Here you find various presets, tweaks and settings to customize your RetroDECK experience" \
    "Open Emulator" "Launch and configure each emulators settings (for advanced users)" \
    "RetroDECK: Tools" "Compress games, move RetroDECK and install optional features" \
    "RetroDECK: Troubleshooting" "Backup data, perform BIOS / multi-disc file checks checks and emulator resets" \
    "RetroDECK: About" "Show additional information about RetroDECK" \
    "Add to Steam" "Add to Steam all the favorite games, it will not remove added games")
  fi

  choice=$(zenity --list --title="RetroDECK Configurator Utility" --cancel-label="Quit" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "${welcome_menu_options[@]}")

  case $choice in

  "Presets & Settings" )
    configurator_presets_and_settings_dialog
  ;;

  "Open Emulator" )
    configurator_power_user_warning_dialog
  ;;

  "RetroDECK: Tools" )
    configurator_retrodeck_tools_dialog
  ;;

  "RetroDECK: Troubleshooting" )
    configurator_retrodeck_troubleshooting_dialog
  ;;

  "RetroDECK: About" )
    configurator_about_retrodeck_dialog
  ;;

  "Sync with Steam" )
    configurator_add_steam
  ;;

  "Developer Options" )
    configurator_generic_dialog "RetroDECK Configurator - Developer Options" "The following features and options are potentially VERY DANGEROUS for your RetroDECK install!\n\nThey should be considered the bleeding-edge of upcoming RetroDECK features, and never used when you have important saves/states/roms that are not backed up!\n\nYOU HAVE BEEN WARNED!"
    configurator_developer_dialog
  ;;

  "" )
    exit 1
  ;;

  esac
}

configurator_presets_and_settings_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - Presets & Settings" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Global: Presets & Settings" "Here you find presets and settings that that span over multiple emulators" \
  "RetroArch: Presets & Settings" "Here you find presets and settings for RetroArch and its cores" \
  "Wii & GameCube: Presets & Settings" "Here you find presets and settings for Dolphin and Primehack" )

  case $choice in

  "Global: Presets & Settings" )
    configurator_global_presets_and_settings_dialog
  ;;

  "RetroArch: Presets & Settings" )
    configurator_retroarch_presets_and_settings_dialog
  ;;

  "Wii & GameCube: Presets & Settings" )
    configurator_wii_and_gamecube_presets_and_settings_dialog
  ;;

  "" ) # No selection made or Back button clicked
    configurator_welcome_dialog
  ;;

  esac
}

configurator_global_presets_and_settings_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - Global: Presets & Settings" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Widescreen: Enable/Disable" "Enable or disable widescreen in supported systems" \
  "Ask-to-Exit: Enable/Disable" "Enable or disable emulators confirming when quitting in supported systems" \
  "RetroAchievements: Login" "Log into the RetroAchievements service in supported systems" \
  "RetroAchievements: Logout" "Disable RetroAchievements service in ALL supported systems" \
  "RetroAchievements: Hardcore Mode" "Enable RetroAchievements hardcore mode (no cheats, rewind, save states etc.) in supported emulators" \
  "Swap A/B and X/Y Buttons" "Enable or disable a swapped A/B and X/Y button layout in supported systems" )

  case $choice in

  "Widescreen: Enable/Disable" )
    change_preset_dialog "widescreen"
    configurator_global_presets_and_settings_dialog
  ;;

  "Ask-to-Exit: Enable/Disable" )
    change_preset_dialog "ask_to_exit"
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
    change_preset_dialog "cheevos_hardcore"
    configurator_global_presets_and_settings_dialog
  ;;

  "Swap A/B and X/Y Buttons" )
    change_preset_dialog "nintendo_button_layout"
    configurator_global_presets_and_settings_dialog
  ;;

  "" ) # No selection made or Back button clicked
    configurator_presets_and_settings_dialog
  ;;

  esac
}

configurator_retroarch_presets_and_settings_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - RetroArch: Presets & Settings" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Borders: Enable/Disable" "Enable or disable borders in supported systems" \
  "Rewind: Enable/Disable" "Enable or disable the Rewind function in RetroArch." )

  case $choice in

  "Borders: Enable/Disable" )
    change_preset_dialog "borders"
    configurator_retroarch_presets_and_settings_dialog
  ;;

  "Rewind: Enable/Disable" )
    configurator_retroarch_rewind_dialog
  ;;

  "" ) # No selection made or Back button clicked
    configurator_presets_and_settings_dialog
  ;;

  esac
}

configurator_retroarch_rewind_dialog() {
  if [[ $(get_setting_value "$raconf" rewind_enable retroarch) == "true" ]]; then
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroArch Rewind" \
    --text="Rewind is currently enabled. Do you want to disable it?."

    if [ $? == 0 ]
    then
      set_setting_value "$raconf" "rewind_enable" "false" retroarch
      configurator_process_complete_dialog "disabling Rewind"
    else
      configurator_retroarch_presets_and_settings_dialog
    fi
  else
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroArch Rewind" \
    --text="Rewind is currently disabled, do you want to enable it?\n\nNOTE:\nThis may impact performance on some more demanding systems."

    if [ $? == 0 ]
    then
      set_setting_value "$raconf" "rewind_enable" "true" retroarch
      configurator_process_complete_dialog "enabling Rewind"
    else
      configurator_retroarch_presets_and_settings_dialog
    fi
  fi
}

configurator_wii_and_gamecube_presets_and_settings_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - Wii & GameCube: Presets & Settings" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Dolphin Textures: Universal Dynamic Input" "Enable/Disable Venomalia's Universal Dynamic Input Textures for Dolphin" \
  "Primehack Textures: Universal Dynamic Input" "Enable/Disable: Venomalia's Universal Dynamic Input Textures for Primehack")

  case $choice in

  "Dolphin Textures: Universal Dynamic Input" )
    configurator_dolphin_input_textures_dialog
  ;;

  "Primehack Textures: Universal Dynamic Input" )
    configurator_primehack_input_textures_dialog
  ;;

  "" ) # No selection made or Back button clicked
    configurator_presets_and_settings_dialog
  ;;

  esac
}

configurator_dolphin_input_textures_dialog() {
  if [[ -d "/var/data/dolphin-emu/Load/DynamicInputTextures" ]]; then
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Dolphin Textures: Universal Dynamic Input" \
    --text="Custom input textures are currently enabled. Do you want to disable them?."

    if [ $? == 0 ]
    then
      # set_setting_value $dolphingfxconf "HiresTextures" "False" dolphin # TODO: Break out a preset for texture packs so this can be enabled and disabled independently.
      rm -rf "/var/data/dolphin-emu/Load/DynamicInputTextures"
      configurator_process_complete_dialog "disabling Dolphin custom input textures"
    else
      configurator_wii_and_gamecube_presets_and_settings_dialog
    fi
  else
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Dolphin Textures: Universal Dynamic Input" \
    --text="Custom input textures are currently disabled. Do you want to enable them?.\n\nThis process may take several minutes to complete."

    if [ $? == 0 ]
    then
      set_setting_value $dolphingfxconf "HiresTextures" "True" dolphin
      (
        mkdir "/var/data/dolphin-emu/Load/DynamicInputTextures"
        rsync -rlD --mkpath "/app/retrodeck/extras/DynamicInputTextures/" "/var/data/dolphin-emu/Load/DynamicInputTextures/"
      ) |
      zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
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
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Dolphin Custom Input Textures" \
    --text="Custom input textures are currently enabled. Do you want to disable them?."

    if [ $? == 0 ]
    then
      # set_setting_value $primehackgfxconf "HiresTextures" "False" primehack # TODO: Break out a preset for texture packs so this can be enabled and disabled independently.
      rm -rf "/var/data/primehack/Load/DynamicInputTextures"
      configurator_process_complete_dialog "disabling Primehack custom input textures"
    else
      configurator_wii_and_gamecube_presets_and_settings_dialog
    fi
  else
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Primehack Custom Input Textures" \
    --text="Custom input textures are currently disabled. Do you want to enable them?.\n\nThis process may take several minutes to complete."

    if [ $? == 0 ]
    then
      set_setting_value $primehackgfxconf "HiresTextures" "True" primehack
      (
        mkdir "/var/data/primehack/Load/DynamicInputTextures"
        rsync -rlD --mkpath "/app/retrodeck/extras/DynamicInputTextures/" "/var/data/primehack/Load/DynamicInputTextures/"
      ) |
      zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
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
    choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Never show this again" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Power User Warning" \
    --text="Making manual changes to an emulators configuration may create serious issues,\nand some settings may be overwitten during RetroDECK updates or when using presets.\n\nSome standalone emulator functions may not work properly outside of Desktop mode.\n\nPlease continue only if you know what you're doing.\n\nDo you want to continue?")
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
  emulator=$(zenity --list \
  --title "RetroDECK Configurator Utility - Open Emulator" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --text="Which emulator do you want to launch?" \
  --hide-header \
  --column="Emulator" --column="Action" \
  "RetroArch" "Open the multi-emulator frontend RetroArch" \
  "Cemu" "Open the Wii U emulator CEMU" \
  "Citra" "Open the N3DS emulator Citra" \
  "Dolphin" "Open the Wii & GC emulator Dolphin" \
  "Duckstation" "Open the PSX emulator Duckstation" \
  "MAME" "Open the Multiple Arcade Machine Emulator emulator MAME" \
  "MelonDS" "Open the NDS emulator MelonDS" \
  "PCSX2" "Open the PS2 emulator PSXC2" \
  "PPSSPP" "Open the PSP emulator PPSSPP" \
  "Primehack" "Open the Metroid Prime emulator Primehack" \
  "RPCS3" "Open the PS3 emulator RPCS3" \
  "Ryujinx" "Open the Switch emulator Ryujinx" \
  "Vita3K" "Open the PSVita emulator Vita3K" \
  "XEMU" "Open the Xbox emulator XEMU" \
  "Yuzu" "Open the Switch emulator Yuzu")

  case $emulator in

  "RetroArch" )
    retroarch
  ;;

  "Cemu" )
    Cemu-wrapper
  ;;

  "Citra" )
    citra-qt
  ;;

  "Dolphin" )
    dolphin-emu
  ;;

  "Duckstation" )
    duckstation-qt
  ;;

  "MAME" )
    mame
  ;;

  "MelonDS" )
    melonDS
  ;;

  "PCSX2" )
    pcsx2-qt
  ;;

  "PPSSPP" )
    PPSSPPSDL
  ;;

  "Primehack" )
    primehack-wrapper
  ;;

  "RPCS3" )
    rpcs3
  ;;

  "Ryujinx" )
    ryujinx-wrapper
  ;;

  "Vita3K" )
    Vita3K
  ;;

  "XEMU" )
    xemu
  ;;

  "Yuzu" )
    yuzu
  ;;

  "" ) # No selection made or Back button clicked
    configurator_welcome_dialog
  ;;

  esac

  configurator_open_emulator_dialog
}

configurator_retrodeck_tools_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Tools" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Tool: Move Folders" "Move RetroDECK folders between internal/SD card or to a custom location" \
  "Tool: Compress Games" "Compress games for systems that support it" \
  "Install: RetroDECK SD Controller Profile" "Install the custom RetroDECK controller layout for the Steam Deck" \
  "Install: PS3 Firmware" "Download and install PS3 firmware for use with the RPCS3 emulator" \
  "RetroDECK: Change Update Setting" "Enable or disable online checks for new versions of RetroDECK" )

  case $choice in

  "Tool: Move Folders" )
    configurator_retrodeck_move_tool_dialog
  ;;

  "Tool: Compress Games" )
    configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "Depending on your library and compression choices, the process can sometimes take a long time.\nPlease be patient once it is started!"
    configurator_compression_tool_dialog
  ;;

  "Install: RetroDECK SD Controller Profile" )
    configurator_generic_dialog "RetroDECK Configurator - Install: RetroDECK Controller Profile" "We are now offering a new official RetroDECK controller profile!\nIt is an optional component that helps you get the most out of RetroDECK with a new in-game radial menu for unified hotkeys across emulators.\n\nThe files need to be installed outside of the normal ~/retrodeck folder, so we wanted your permission before proceeding.\n\nThe files will be installed at the following shared Steam locations:\n\n$HOME/.steam/steam/tenfoot/resource/images/library/controller/binding_icons/\n$HOME/.steam/steam/controller_base/templates"
    if [[ $(configurator_generic_question_dialog "Install: RetroDECK Controller Profile" "Would you like to install the official RetroDECK controller profile?") == "true" ]]; then
      install_retrodeck_controller_profile
      configurator_generic_dialog "RetroDECK Configurator - Install: RetroDECK Controller Profile" "The RetroDECK controller profile install is complete.\nSee the Wiki for more details on how to use it to its fullest potential!"
    fi
    configurator_retrodeck_tools_dialog
  ;;

  "Install: PS3 Firmware" )
    if [[ $(check_network_connectivity) == "true" ]]; then
      configurator_generic_dialog "RetroDECK Configurator - Install: PS3 firmware" "This tool will download firmware required by RPCS3 to emulate PS3 games.\n\nThe process will take several minutes, and the emulator will launch to finish the installation.\nPlease close RPCS3 manually once the installation is complete."
      (
        update_rpcs3_firmware
      ) |
        zenity --progress --pulsate \
        --icon-name=net.retrodeck.retrodeck \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title="Downloading PS3 Firmware" \
        --no-cancel \
        --auto-close
    else
      configurator_generic_dialog "RetroDECK Configurator - Install: PS3 Firmware" "You do not appear to currently have Internet access, which is required by this tool. Please try again when network access has been restored."
      configurator_retrodeck_tools_dialog
    fi
  ;;

  "RetroDECK: Change Update Setting" )
    configurator_online_update_setting_dialog
  ;;

  "" ) # No selection made or Back button clicked
    configurator_welcome_dialog
  ;;

  esac
}

configurator_retrodeck_move_tool_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Move Tool" --cancel-label="Back" \
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
    configurator_move_folder_dialog "rdhome"
  ;;

  "Move ROMs folder" )
    configurator_move_folder_dialog "roms_folder"
  ;;

  "Move BIOS folder" )
    configurator_move_folder_dialog "bios_folder"
  ;;

  "Move Downloaded Media folder" )
    configurator_move_folder_dialog "media_folder"
  ;;

  "Move Saves folder" )
    configurator_move_folder_dialog "saves_folder"
  ;;

  "Move States folder" )
    configurator_move_folder_dialog "states_folder"
  ;;

  "Move Themes folder" )
    configurator_move_folder_dialog "themes_folder"
  ;;

  "Move Screenshots folder" )
    configurator_move_folder_dialog "screenshots_folder"
  ;;

  "Move Mods folder" )
    configurator_move_folder_dialog "mods_folder"
  ;;

  "Move Texture Packs folder" )
    configurator_move_folder_dialog "texture_packs_folder"
  ;;

  esac

  configurator_retrodeck_tools_dialog
}

configurator_compression_tool_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Compression Tool" --cancel-label="Back" \
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
    configurator_compress_single_game_dialog
  ;;

  "Compress Multiple Games - CHD" )
    configurator_compress_multiple_games_dialog "chd"
  ;;

  "Compress Multiple Games - ZIP" )
    configurator_compress_multiple_games_dialog "zip"
  ;;

  "Compress Multiple Games - RVZ" )
    configurator_compress_multiple_games_dialog "rvz"
  ;;

  "Compress Multiple Games - All Formats" )
    configurator_compress_multiple_games_dialog "all"
  ;;

  "Compress All Games" )
    configurator_compress_multiple_games_dialog "everything"
  ;;

  "" ) # No selection made or Back button clicked
    configurator_retrodeck_tools_dialog
  ;;

  esac
}

configurator_compress_single_game_dialog() {
  local file=$(file_browse "Game to compress")
  if [[ ! -z "$file" ]]; then
    local compatible_compression_format=$(find_compatible_compression_format "$file")
    if [[ ! $compatible_compression_format == "none" ]]; then
      local post_compression_cleanup=$(configurator_compression_cleanup_dialog)
      (
      if [[ $compatible_compression_format == "chd" ]]; then
        if [[ $(validate_for_chd "$file") == "true" ]]; then
          echo "# Compressing $(basename "$file") to $compatible_compression_format format"
          compress_game "chd" "$file"
          if [[ $post_compression_cleanup == "true" ]]; then # Remove file(s) if requested
            if [[ "$file" == *".cue" ]]; then
              local cue_bin_files=$(grep -o -P "(?<=FILE \").*(?=\".*$)" "$file")
              local file_path=$(dirname "$(realpath "$file")")
              while IFS= read -r line
              do
                rm -f "$file_path/$line"
              done < <(printf '%s\n' "$cue_bin_files")
              rm -f "$file"
            else
              rm -f "$file"
            fi
          fi
        fi
      else
        echo "# Compressing $(basename "$file") to $compatible_compression_format format"
        compress_game "$compatible_compression_format" "$file"
        if [[ $post_compression_cleanup == "true" ]]; then # Remove file(s) if requested
          rm -f "$file"
        fi
      fi
      ) |
      zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Compression in Progress"
      configurator_generic_dialog "RetroDECK Configurator - RetroDECK: Compression Tool" "The compression process is complete!"
      configurator_compression_tool_dialog

    else
      configurator_generic_dialog "RetroDECK Configurator - RetroDECK: Compression Tool" "The selected file does not have any compatible compressed format."
      configurator_compression_tool_dialog
    fi
  else
    configurator_compression_tool_dialog
  fi
}

configurator_compress_multiple_games_dialog() {
  # This dialog will display any games it finds to be compressable, from the systems listed under each compression type in compression_targets.cfg

  local compressable_games_list=()
  local all_compressable_games=()
  local games_to_compress=()
  local target_selection="$1"

  if [[ "$1" == "everything" ]]; then
    local compression_format="all"
  else
    local compression_format="$1"
  fi

  if [[ $compression_format == "all" ]]; then
    local compressable_systems_list=$(cat $compression_targets | sed '/^$/d' | sed '/^\[/d')
  else
    local compressable_systems_list=$(sed -n '/\['"$compression_format"'\]/, /\[/{ /\['"$compression_format"'\]/! { /\[/! p } }' $compression_targets | sed '/^$/d')
  fi

  while IFS= read -r system # Find and validate all games that are able to be compressed with this compression type
  do
    compression_candidates=$(find "$roms_folder/$system" -type f -not -iname "*.txt")
    if [[ ! -z $compression_candidates ]]; then
      while IFS= read -r game
      do
        local compatible_compression_format=$(find_compatible_compression_format "$game")
        if [[ $compression_format == "chd" ]]; then
          if [[ $compatible_compression_format == "chd" ]]; then
            all_compressable_games=("${all_compressable_games[@]}" "$game")
            compressable_games_list=("${compressable_games_list[@]}" "false" "${game#$roms_folder}" "$game")
          fi
        elif [[ $compression_format == "zip" ]]; then
          if [[ $compatible_compression_format == "zip" ]]; then
            all_compressable_games=("${all_compressable_games[@]}" "$game")
            compressable_games_list=("${compressable_games_list[@]}" "false" "${game#$roms_folder}" "$game")
          fi
        elif [[ $compression_format == "rvz" ]]; then
          if [[ $compatible_compression_format == "rvz" ]]; then
            all_compressable_games=("${all_compressable_games[@]}" "$game")
            compressable_games_list=("${compressable_games_list[@]}" "false" "${game#$roms_folder}" "$game")
          fi
        elif [[ $compression_format == "all" ]]; then
          if [[ ! $compatible_compression_format == "none" ]]; then
            all_compressable_games=("${all_compressable_games[@]}" "$game")
            compressable_games_list=("${compressable_games_list[@]}" "false" "${game#$roms_folder}" "$game")
          fi
        fi
      done < <(printf '%s\n' "$compression_candidates")
    fi
  done < <(printf '%s\n' "$compressable_systems_list")

  if [[ ! "$target_selection" == "everything" ]]; then # If the user chose to not auto-compress everything
    choice=$(zenity \
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
  fi

  if [[ ! $(echo "${#games_to_compress[@]}") == "0" ]]; then
    local post_compression_cleanup=$(configurator_compression_cleanup_dialog)
    (
    for file in "${games_to_compress[@]}"; do
      local compression_format=$(find_compatible_compression_format "$file")
      echo "# Compressing $(basename "$file") into $compression_format format" # Update Zenity dialog text
      progress=$(( 100 - (( 100 / "$total_games_to_compress" ) * "$games_left_to_compress" )))
      echo $progress
      games_left_to_compress=$((games_left_to_compress-1))
      compress_game "$compression_format" "$file"
      if [[ $post_compression_cleanup == "true" ]]; then # Remove file(s) if requested
        if [[ "$file" == *".cue" ]]; then
          local cue_bin_files=$(grep -o -P "(?<=FILE \").*(?=\".*$)" "$file")
          local file_path=$(dirname "$(realpath "$file")")
          while IFS= read -r line
          do
            rm -f "$file_path/$line"
          done < <(printf '%s\n' "$cue_bin_files")
          rm -f $(realpath "$file")
        else
          rm -f "$(realpath "$file")"
        fi
      fi
    done
    ) |
    zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Compression in Progress"
      configurator_generic_dialog "RetroDECK Configurator - RetroDECK: Compression Tool" "The compression process is complete!"
      configurator_compression_tool_dialog
  else
    configurator_compression_tool_dialog
  fi
}

configurator_compression_cleanup_dialog() {
  zenity --icon-name=net.retrodeck.retrodeck --question --no-wrap --cancel-label="No" --ok-label="Yes" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator - RetroDECK: Compression Tool" \
  --text="Do you want to remove old files after they are compressed?\n\nClicking \"No\" will leave all files behind which will need to be cleaned up manually and may result in game duplicates showing in the RetroDECK library."
  local rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "0" ]]; then # If user clicked "Yes"
    echo "true"
  else # If "No" was clicked
    echo "false"
  fi
}

configurator_online_update_setting_dialog() {
  if [[ $(get_setting_value $rd_conf "update_check" retrodeck "options") == "true" ]]; then
    zenity --question \
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
    zenity --question \
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
  choice=$(zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Troubleshooting" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Backup: RetroDECK Userdata" "Compress and backup important RetroDECK user data folders" \
  "Check & Verify: BIOS Files" "Show information about common BIOS files" \
  "Check & Verify: Multi-file structure" "Verify the proper structure of multi-file or multi-disc games" \
  "RetroDECK: Reset" "Reset specific parts or all of RetroDECK" )

  case $choice in

  "Backup: RetroDECK Userdata" )
    configurator_generic_dialog "RetroDECK Configurator - Backup: RetroDECK Userdata" "This tool will compress important RetroDECK userdata (basically everything except the ROMs folder) into a zip file.\n\nThis process can take several minutes, and the resulting zip file can be found in the ~/retrodeck/backups folder."
    (
      backup_retrodeck_userdata
    ) |
    zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
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
    configurator_check_bios_files
  ;;

  "Check & Verify: Multi-file structure" )
    configurator_check_multifile_game_structure
  ;;

  "RetroDECK: Reset" )
    configurator_reset_dialog
  ;;

  "" ) # No selection made or Back button clicked
    configurator_welcome_dialog
  ;;

  esac
}

configurator_check_bios_files() {
  configurator_generic_dialog "RetroDECK Configurator - Check & Verify: BIOS Files" "This check will look for BIOS files that RetroDECK has identified as working.\n\nNot all BIOS files are required for games to work, please check the BIOS description for more information on its purpose.\n\nThere may be additional BIOS files that will function with the emulators that are not checked.\n\nSome more advanced emulators such as Yuzu will have additional methods for verifiying the BIOS files are in working order."
  bios_checked_list=()

  while IFS="^" read -r bios_file bios_subdir bios_hash bios_system bios_desc
  do
    bios_file_found="No"
    bios_hash_matched="No"
    if [[ -f "$bios_folder/$bios_subdir$bios_file" ]]; then
      bios_file_found="Yes"
      if [[ $bios_hash == "Unknown" ]]; then
        bios_hash_matched="Unknown"
      elif [[ $(md5sum "$bios_folder/$bios_subdir$bios_file" | awk '{ print $1 }') == "$bios_hash" ]]; then
        bios_hash_matched="Yes"
      fi
    fi
    bios_checked_list=("${bios_checked_list[@]}" "$bios_file" "$bios_system" "$bios_file_found" "$bios_hash_matched" "$bios_desc")
  done < $bios_checklist

  zenity --list --title="RetroDECK Configurator Utility - Check & Verify: BIOS Files" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column "BIOS File Name" \
  --column "System" \
  --column "BIOS File Found" \
  --column "BIOS Hash Match" \
  --column "BIOS File Description" \
  "${bios_checked_list[@]}"

  configurator_retrodeck_troubleshooting_dialog
}

configurator_check_multifile_game_structure() {
  local folder_games=($(find $roms_folder -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3"))
  if [[ ${#folder_games[@]} -gt 1 ]]; then
    echo "$(find $roms_folder -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3")" > $logs_folder/multi_file_games_"$(date +"%Y_%m_%d_%I_%M_%p").log"
    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Check & Verify: Multi-file structure" \
    --text="The following games were found to have the incorrect folder structure:\n\n$(find $roms_folder -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3")\n\nIncorrect folder structure can result in failure to launch games or saves being in the incorrect location.\n\nPlease see the RetroDECK wiki for more details!\n\nYou can find this list of games in ~/retrodeck/.logs"
  else
    configurator_generic_dialog "RetroDECK Configurator - Check & Verify: Multi-file structure" "No incorrect multi-file game folder structures found."
  fi
  configurator_retrodeck_troubleshooting_dialog
}

configurator_reset_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - RetroDECK: Reset" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Reset Specific Emulator" "Reset only one specific emulator to default settings" \
  "Reset All Emulators" "Reset all emulators to default settings" \
  "Reset EmulationStation DE" "Reset the ES-DE frontend" \
  "Reset RetroDECK" "Reset RetroDECK to default settings" )

  case $choice in

  "Reset Specific Emulator" )
    emulator_to_reset=$(zenity --list \
    --title "RetroDECK Configurator Utility - Reset Specific Standalone Emulator" --cancel-label="Back" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
    --text="Which emulator do you want to reset to default?" \
    --column="Emulator" --column="Action" \
    "RetroArch" "Reset the multi-emulator frontend RetroArch to default settings" \
    "Cemu" "Reset the Wii U emulator Cemu to default settings" \
    "Citra" "Reset the N3DS emulator Citra to default settings" \
    "Dolphin" "Reset the Wii/GameCube emulator Dolphin to default settings" \
    "Duckstation" "Reset the PSX emulator Duckstation to default settings" \
    "MelonDS" "Reset the NDS emulator MelonDS to default settings" \
    "PCSX2" "Reset the PS2 emulator PCSX2 to default settings" \
    "PPSSPP" "Reset the PSP emulator PPSSPP to default settings" \
    "Primehack" "Reset the Metroid Prime emulator Primehack to default settings" \
    "RPCS3" "Reset the PS3 emulator RPCS3 to default settings" \
    "Ryujinx" "Reset the Switch emulator Ryujinx to default settings" \
    "XEMU" "Reset the XBOX emulator XEMU to default settings" \
    "Yuzu" "Reset the Switch emulator Yuzu to default settings" )

    case $emulator_to_reset in

    "RetroArch" | "XEMU" ) # Emulators that require network access
      if [[ $(configurator_reset_confirmation_dialog "$emulator_to_reset" "Are you sure you want to reset the $emulator_to_reset emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        prepare_emulator "reset" "$emulator_to_reset" "configurator"
        configurator_process_complete_dialog "resetting $emulator_to_reset"
      else
        configurator_generic_dialog "RetroDeck Configurator - RetroDECK: Reset" "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "Cemu" | "Citra" | "Dolphin" | "Duckstation" | "MelonDS" | "PCSX2" | "PPSSPP" | "Primehack" | "RPCS3" | "Ryujinx" | "Yuzu" )
      if [[ $(configurator_reset_confirmation_dialog "$emulator_to_reset" "Are you sure you want to reset the $emulator_to_reset emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        prepare_emulator "reset" "$emulator_to_reset" "configurator"
        configurator_process_complete_dialog "resetting $emulator_to_reset"
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

"Reset All Emulators" )
  if [[ $(configurator_reset_confirmation_dialog "all emulators" "Are you sure you want to reset all emulators to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
    (
    prepare_emulator "reset" "all"
    ) |
    zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Finishing Initialization" \
    --text="RetroDECK is finishing the reset process, please wait."
    configurator_process_complete_dialog "resetting all emulators"
  else
    configurator_generic_dialog "RetroDeck Configurator - RetroDECK: Reset" "Reset process cancelled."
    configurator_reset_dialog
  fi
;;

"Reset EmulationStation DE" )
  if [[ $(configurator_reset_confirmation_dialog "EmulationStation DE" "Are you sure you want to reset EmulationStation DE to default settings?\n\nYour scraped media, downloaded themes and gamelists will not be touched.\n\nThis process cannot be undone.") == "true" ]]; then
    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility - Reset EmulationStation DE" \
    --text="You are resetting EmulationStation DE to its default settings.\n\nAfter the process is complete you will need to exit RetroDECK and run it again."
    prepare_emulator "reset" "emulationstation" "configurator"
    configurator_process_complete_dialog "resetting EmulationStation DE"
  else
    configurator_generic_dialog "RetroDeck Configurator - EmulationStation DE: Reset" "Reset process cancelled."
    configurator_reset_dialog
  fi
;;

"Reset RetroDECK" )
  if [[ $(configurator_reset_confirmation_dialog "RetroDECK" "Are you sure you want to reset RetroDECK entirely?\n\nThis process cannot be undone.") == "true" ]]; then
    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
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
  choice=$(zenity --list --title="RetroDECK Configurator Utility - RetroDECK: About" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Version History" "View the version changelogs for RetroDECK" \
  "Credits" "View the contribution credits for RetroDECK" )

  case $choice in

  "Version History" )
    configurator_version_history_dialog
  ;;

  "Credits" )
    zenity --icon-name=net.retrodeck.retrodeck --text-info --width=1200 --height=720 \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Credits" \
    --filename="$emuconfigs/defaults/retrodeck/reference_lists/retrodeck_credits.txt"
    configurator_about_retrodeck_dialog
  ;;

  "" ) # No selection made or Back button clicked
    configurator_welcome_dialog
  ;;

  esac
}

configurator_add_steam() {
    python3 /app/libexec/steam-sync/steam-sync.py
    configurator_welcome_dialog
}

configurator_version_history_dialog() {
  local version_array=($(xml sel -t -v '//component/releases/release/@version' -n $rd_appdata))
  local all_versions_list=()

  for rd_version in ${version_array[*]}; do
    all_versions_list=("${all_versions_list[@]}" "RetroDECK $rd_version Changelog" "View the changes specific to version $rd_version")
  done

  choice=$(zenity --list --title="RetroDECK Configurator Utility - RetroDECK Version History" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Full RetroDECK Changelog" "View the list of all changes that have ever been made to RetroDECK" \
  "${all_versions_list[@]}")

  case $choice in

  "Full RetroDECK Changelog" )
    changelog_dialog "all"
  ;;

  "RetroDECK"*"Changelog" )
    local version=$(echo "$choice" | sed 's/^RetroDECK \(.*\) Changelog$/\1/')
    changelog_dialog "$version"
  ;;

  esac

  configurator_about_retrodeck_dialog
}

configurator_developer_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - Developer Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Change Multi-user mode" "Enable or disable multi-user support" \
  "Change Update Channel" "Change between normal and cooker builds" \
  "Browse the Wiki" "Browse the RetroDECK wiki online" \
  "USB Import" "Prepare a USB device for ROMs or import an existing collection" \
  "Install RetroDECK Starter Pack" "Install the optional RetroDECK starter pack" )

  case $choice in

  "Change Multi-user mode" )
    configurator_retrodeck_multiuser_dialog
  ;;

  "Change Update Channel" )
    configurator_online_update_channel_dialog
  ;;

  "Browse the Wiki" )
    xdg-open "https://github.com/XargonWan/RetroDECK/wiki"
    configurator_developer_dialog
  ;;

  "USB Import" )
    configurator_usb_import_dialog
  ;;

  "Install RetroDECK Starter Pack" )
    if [[ $(configurator_generic_question_dialog "Install: RetroDECK Starter Pack" "The RetroDECK creators have put together a collection of classic retro games you might enjoy!\n\nWould you like to have them automatically added to your library?") == "true" ]]; then
      install_retrodeck_starterpack
    fi
    configurator_developer_dialog
  ;;

  "" ) # No selection made or Back button clicked
    configurator_welcome_dialog
  ;;
  esac
}

configurator_retrodeck_multiuser_dialog() {
  if [[ $(get_setting_value $rd_conf "multi_user_mode" retrodeck "options") == "true" ]]; then
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Multi-user Support" \
    --text="Multi-user support is current enabled. Do you want to disable it?\n\nIf there are more than one user configured,\nyou will be given a choice of which to use as the single RetroDECK user.\n\nThis users files will be moved to the default locations.\n\nOther users files will remain in the mutli-user-data folder.\n"

    if [ $? == 0 ] # User clicked "Yes"
    then
      multi_user_disable_multi_user_mode
    else # User clicked "Cancel"
      configurator_developer_dialog
    fi
  else
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Multi-user support" \
    --text="Multi-user support is current disabled. Do you want to enable it?\n\nThe current users saves and states will be backed up and then moved to the \"retrodeck/multi-user-data\" folder.\nAdditional users will automatically be stored in their own folder here as they are added."

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
    zenity --question \
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
    zenity --question \
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

configurator_usb_import_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - Developer Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Description" \
  "Prepare USB device" "Create ROM folders on a selected USB device" \
  "Import from USB" "Import collection from a previously prepared device" )

  case $choice in

  "Prepare USB device" )
    external_devices=()

    while read -r size device_path; do
      device_name=$(basename "$device_path")
      external_devices=("${external_devices[@]}" "$device_name" "$size" "$device_path")
    done < <(df --output=size,target | grep media | grep -v $default_sd | awk '{$1=$1;print}')

    if [[ "${#external_devices[@]}" -gt 0 ]]; then
      choice=$(zenity --list --title="RetroDECK Configurator Utility - USB Migration Tool" --cancel-label="Back" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ ! -z "$choice" ]]; then
        emulationstation --home "$choice" --create-system-dirs
        rm -rf "$choice/.emulationstation" # Cleanup unnecessary folder
      fi
    else
      configurator_generic_dialog "RetroDeck Configurator - USB Import" "There were no USB devices found."
    fi
    configurator_usb_import_dialog
  ;;

  "Import from USB" )
    external_devices=()

    while read -r size device_path; do
      if [[ -d "$device_path/ROMs" ]]; then
        device_name=$(basename "$device_path")
        external_devices=("${external_devices[@]}" "$device_name" "$size" "$device_path")
      fi
    done < <(df --output=size,target | grep media | grep -v $default_sd | awk '{$1=$1;print}')

    if [[ "${#external_devices[@]}" -gt 0 ]]; then
      choice=$(zenity --list --title="RetroDECK Configurator Utility - USB Migration Tool" --cancel-label="Back" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --hide-column=3 --print-column=3 \
      --column "Device Name" \
      --column "Device Size" \
      --column "path" \
      "${external_devices[@]}")

      if [[ ! -z "$choice" ]]; then
        if [[ $(verify_space "$choice/ROMs" "$roms_folder") == "false" ]]; then
          if [[ $(configurator_generic_question_dialog "RetroDECK Configurator Utility - USB Migration Tool" "You MAY not have enough free space to import this ROM library.\n\nThis utility only imports new additions from the USB device, so if there are a lot of the same ROMs in both locations you are likely going to be fine\nbut we are not able to verify how much data will be transferred before it happens.\n\nIf you are unsure, please verify your available free space before continuing.\n\nDo you want to continue now?") == "true" ]]; then
            (
            rsync -a --mkpath "$choice/ROMs/"* "$roms_folder"
            ) |
            zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - USB Import In Progress"
            configurator_generic_dialog "RetroDECK Configurator - USB Migration Tool" "The import process is complete!"
          fi
        else
          (
          rsync -a --mkpath "$choice/ROMs/"* "$roms_folder"
          ) |
          zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
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
    configurator_developer_dialog
  ;;
  esac

}

# START THE CONFIGURATOR

configurator_welcome_dialog
