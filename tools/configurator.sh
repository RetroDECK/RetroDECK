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
#         - Toggle Universal Dynamic Input for Dolphin
#         - Toggle Universal Dynamic Input for Primehack
#         - PortMaster
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
#       - Backup Userdata
#       - BIOS Checker
#       - Games Compressor
#         - Compress Single Game
#         - Compress Multiple Games - CHD
#         - Compress Multiple Games - ZIP
#         - Compress Multiple Games - RVZ
#         - Compress Multiple Games - All Formats
#         - Compress All Games
#       - Install: RetroDECK Controller Layouts
#       - Install: PS3 firmware
#       - Install: PS Vita firmware
#       - Update Notification
#       - Verify Multi-file Structure
#       - Ponzu - Remove Yuzu
#       - Ponzu - Remove Citra
#     - Steam Sync
#     - Data Management
#       - Move all of RetroDECK
#       - Move ROMs folder
#       - Move BIOS folder
#       - Move Downloaded Media folder
#       - Move Saves folder
#       - Move States folder
#       - Move Themes folder
#       - Move Screenshots folder
#       - Move Mods folder
#       - Move Texture Packs folder
#       - Clean Empty ROM Folders
#       - Rebuild All ROM Folders
#     - About RetroDECK
#       - RetroDECK Version History
#         - Full changelog
#         - Version-specific changelogs
#       - RetroDECK Credits
#     - Developer Options (Hidden)
#       - Change Multi-user mode
#       - Install Specific Release
#       - Browse the wiki
#       - Install: RetroDECK Starter Pack
#       - Tool: USB Import
#
# DIALOG TREE FUNCTIONS

configurator_welcome_dialog() {
  log i "Configurator: opening welcome dialog"
  welcome_menu_options=(
    "Settings" "Here you will find various presets, tweaks and settings to customize your RetroDECK experience"
    "Open Component" "Launch and configure each emulator or component's settings (for advanced users)"
    "Reset Components" "Reset specific parts or all of RetroDECK"
    "Tools" "Games Compressor, move RetroDECK and install optional features"
    "Steam Sync" "Sync all favorited games with Steam"
    "Data Management" "Move RetroDECK folders between internal/SD card or to a custom location"
    "About RetroDECK" "Show additional information about RetroDECK"
  )

  if [[ $developer_options == "true" ]]; then
    welcome_menu_options+=("Developer Options" "Welcome to the DANGER ZONE")
  fi

  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility" --cancel-label="Quit" \
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
    configurator_retrodeck_tools_dialog
  ;;

  "About RetroDECK" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_about_retrodeck_dialog
  ;;

  "Steam Sync" )
    configurator_steam_sync
  ;;

  "Developer Options" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_generic_dialog "RetroDECK Configurator - Developer Options" "The following features and options are potentially VERY DANGEROUS for your RetroDECK install!\n\nThey should be considered the bleeding-edge of upcoming RetroDECK features, and never used when you have important saves/states/roms that are not backed up!\n\nYOU HAVE BEEN WARNED!"
    configurator_developer_dialog
  ;;

  "Data Management" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_data_management_dialog
  ;;

  "" )
    log i "Configurator: closing"
    exit 1
  ;;

  esac
}

configurator_global_presets_and_settings_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - Global: Presets & Settings" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Borders" "Enable or disable borders in supported systems (only RetroArch is supported at this moment)" \
  "Widescreen" "Enable or disable widescreen in supported systems" \
  "Ask-to-Exit" "Enable or disable emulators confirming attempts to quit in supported systems" \
  "Quick Resume" "Enable or disable save state auto-save/load in supported systems" \
  "Rewind" "Enable or disable the rewind function in supported systems" \
  "Swap A/B and X/Y Buttons" "Enable or disable a swapped A/B and X/Y button layout in supported systems" \
  "RetroAchievements: Login" "Log into the RetroAchievements service in supported systems" \
  "RetroAchievements: Logout" "Disable RetroAchievements service in ALL supported systems" \
  "RetroAchievements: Hardcore Mode" "Enable RetroAchievements hardcore mode (no cheats, rewind, save states etc.) in supported systems" \
  "Toggle Universal Dynamic Input for Dolphin" "Enable or disable universal dynamic input textures for Dolphin" \
  "Toggle Universal Dynamic Input for Primehack" "Enable or disable universal dynamic input textures for Primehack" \
  "PortMaster" "Hide or show PortMaster in ES-DE"
  )

  case $choice in

  "Borders" )
    log i "Configurator: opening \"$choice\" menu"
    change_preset_dialog "borders"
    configurator_global_presets_and_settings_dialog
  ;;

  "Widescreen" )
    log i "Configurator: opening \"$choice\" menu"
    change_preset_dialog "widescreen"
    configurator_global_presets_and_settings_dialog
  ;;

  "Ask-to-Exit" )
    log i "Configurator: opening \"$choice\" menu"
    change_preset_dialog "ask_to_exit"
    configurator_global_presets_and_settings_dialog
  ;;

  "Quick Resume" )
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

  "Rewind" )
    log i "Configurator: opening \"$choice\" menu"

    change_preset_dialog "rewind"
    configurator_global_presets_and_settings_dialog
  ;;

  "Swap A/B and X/Y Buttons" )
    log i "Configurator: opening \"$choice\" menu"

    change_preset_dialog "abxy_button_swap"
    configurator_global_presets_and_settings_dialog
  ;;

  "Toggle Universal Dynamic Input for Dolphin" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_dolphin_input_textures_dialog
  ;;

  "Toggle Universal Dynamic Input for Primehack" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_primehack_input_textures_dialog
  ;;

  "PortMaster" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_portmaster_toggle_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_welcome_dialog
  ;;

  esac
}

configurator_dolphin_input_textures_dialog() {
  if [[ -d "/var/data/dolphin-emu/Load/DynamicInputTextures" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Toggle Universal Dynamic Input for Dolphin" \
    --text="Custom input textures are currently enabled. Do you want to disable them?"

    if [ $? == 0 ]
    then
      # set_setting_value $dolphingfxconf "HiresTextures" "False" dolphin # TODO: Break out a preset for texture packs so this can be enabled and disabled independently.
      rm -rf "/var/data/dolphin-emu/Load/DynamicInputTextures"
      configurator_process_complete_dialog "disabling Dolphin custom input textures"
    else
      configurator_global_presets_and_settings_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Toggle Universal Dynamic Input for Dolphin" \
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
      configurator_global_presets_and_settings_dialog
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
      configurator_global_presets_and_settings_dialog
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
      configurator_global_presets_and_settings_dialog
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
  # This function displays a dialog to the user for selecting an emulator to open.
  # It first constructs a list of available emulators and their descriptions by reading
  # from the output of `open_component --list` and `open_component --getdesc`.
  # If certain settings (kiroi_ponzu or akai_ponzu) are enabled, it adds Yuzu and Citra
  # to the list of emulators.
  # The function then uses `rd_zenity` to display a graphical list dialog with the
  # available emulators and their descriptions.
  # If the user selects an emulator, it calls `open_component` with the selected emulator.
  # If the user cancels the dialog, it calls `configurator_welcome_dialog` to return to the
  # welcome screen.

  local emulator_list=()
  while IFS= read -r emulator && IFS= read -r desc; do
    if [[ "$emulator" != "RetroDECK" ]]; then
      emulator_list+=("$emulator" "$desc")
    fi
  done < <(paste -d '\n' <(open_component --list) <(open_component --getdesc))

  emulator=$(rd_zenity --list \
  --title "RetroDECK Configurator Utility - Open Component" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --text="Which emulator do you want to launch?" \
  --hide-header \
  --column="Emulator" --column="Description" \
  "${emulator_list[@]}")

  if [[ -n "$emulator" ]]; then
    open_component "$emulator"
  else
    configurator_welcome_dialog
  fi
}

configurator_retrodeck_tools_dialog() {

  local choices=(
  "Backup Userdata" "Compress and backup important RetroDECK user data folders"
  "BIOS Checker" "Show information about common BIOS files"
  "Games Compressor" "Games Compressor for systems that support it"
  "Install: RetroDECK Controller Layouts" "Install the custom RetroDECK controller layouts on Steam"
  "Install: PS3 Firmware" "Download and install PS3 firmware for use with the RPCS3 emulator"
  "Install: PS Vita Firmware" "Download and install PS Vita firmware for use with the Vita3K emulator"
  "Update Notification" "Enable or disable online checks for new versions of RetroDECK"
  "Verify Multi-file Structure" "Verify the proper structure of multi-file or multi-disc games"
  )

  if [[ $(get_setting_value "$rd_conf" "kiroi_ponzu" "retrodeck" "options") == "true" ]]; then
    choices+=("Ponzu - Remove Yuzu" "Run Ponzu to remove Yuzu from RetroDECK. Configurations and saves will be mantained.")
  fi
  if [[ $(get_setting_value "$rd_conf" "akai_ponzu" "retrodeck" "options") == "true" ]]; then
    choices+=("Ponzu - Remove Citra" "Run Ponzu to remove Citra from RetroDECK. Configurations and saves will be mantained.")
  fi

  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - Tools" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "${choices[@]}")

  case $choice in

  "Backup Userdata" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "This tool will compress important RetroDECK userdata (basically everything except the ROMs folder) into a zip file.\n\nThis process can take several minutes, and the resulting zip file can be found in the ~/retrodeck/backups folder."
    (
      backup_retrodeck_userdata
    ) |
    rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - Backup in Progress" \
            --text="Backing up RetroDECK userdata, please wait..."
    if [[ -f "$backups_folder/$(date +"%0m%0d")_retrodeck_userdata.zip" ]]; then
      configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The backup process is now complete."
    else
      configurator_generic_dialog "RetroDECK Configurator - Backup Userdata" "The backup process could not be completed,\nplease check the logs folder for more information."
    fi
    configurator_welcome_dialog
  ;;

  "BIOS Checker" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_check_bios_files
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

  "Update Notification" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_update_notify_dialog
  ;;

  "Verify Multi-file Structure" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_check_multifile_game_structure
  ;;

  "Ponzu - Remove Yuzu" )
    ponzu_remove "yuzu"
  ;;

  "Ponzu - Remove Citra" )
    ponzu_remove "citra"
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_welcome_dialog
  ;;

  esac
}

configurator_data_management_dialog() {
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
  "Move Texture Packs folder" "Move only the Texture Packs folder to a new location" \
  "Clean Empty ROM Folders" "Remove some or all of the empty ROM folders" \
  "Rebuild All ROM Folders" "Rebuild any missing default ROM folders" )

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

  "Clean Empty ROM Folders" )
    log i "Configurator: opening \"$choice\" menu"

    configurator_generic_dialog "RetroDECK Configurator - Clean Empty ROM Folders" "Before removing any identified empty ROM folders,\nplease make sure your ROM collection is backed up, just in case!"
    configurator_generic_dialog "RetroDECK Configurator - Clean Empty ROM Folders" "Searching for empty rom folders, please be patient..."
    find_empty_rom_folders

    choice=$(rd_zenity \
        --list --width=1200 --height=720 --title "RetroDECK Configurator - RetroDECK: Clean Empty ROM Folders" \
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
      configurator_generic_dialog "RetroDECK Configurator - Clean Empty ROM Folders" "The removal process is complete."
    elif [[ ! -z $choice ]]; then # User clicked "Remove All"
      for folder in "${all_empty_folders[@]}"; do
        log i "Removing empty folder $folder"
        rm -rf "$folder"
      done
      configurator_generic_dialog "RetroDECK Configurator - Clean Empty ROM Folders" "The removal process is complete."
    fi

    configurator_welcome_dialog
  ;;

  "Rebuild All ROM Folders" )
    log i "Configurator: opening \"$choice\" menu"
    es-de --create-system-dirs
    configurator_generic_dialog "RetroDECK Configurator - Rebuild All ROM Folders" "The rebuilding process is complete.\n\nAll missing default ROM folders will now exist in $roms_folder"
    configurator_welcome_dialog
  ;;

  esac

  configurator_welcome_dialog
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
  # This dialog will display any games it finds to be compressable, from the systems listed under each compression type in features.json

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

configurator_update_notify_dialog() {
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

configurator_portmaster_toggle_dialog(){
  
  if [[ $(get_setting_value "$rd_conf" "portmaster_show" "retrodeck" "options") == "true" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - PortMaster Visibility" \
    --text="PortMaster is currently <span foreground='$purple'><b>visible</b></span> in ES-DE. Do you want to hide it?\n\nPlease note that the installed games will still be visible."

    if [ $? == 0 ] # User clicked "Yes"
    then
      portmaster_show "false"
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - PortMaster Visibility" \
      --text="PortMaster is now <span foreground='$purple'><b>hidden</b></span> in ES-DE.\nPlease refresh your game list or restart RetroDECK to see the changes.\n\nIn order to launch PortMaster, you can access it from:\n<span foreground='$purple'><b>Configurator -> Open Component -> PortMaster</b></span>."
    else # User clicked "Cancel"
      configurator_retrodeck_tools_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - PortMaster Visibility" \
    --text="PortMaster is currently <span foreground='$purple'><b>hidden</b></span> in ES-DE. Do you want to show it?"

    if [ $? == 0 ] # User clicked "Yes"
    then
      portmaster_show "true"
      rd_zenity --info \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - PortMaster Visibility" \
      --text="PortMaster is now <span foreground='$purple'><b>visible</b></span> in ES-DE.\nPlease refresh your game list or restart RetroDECK to see the changes."
    else # User clicked "Cancel"
      configurator_retrodeck_tools_dialog
    fi
  fi
  configurator_retrodeck_tools_dialog
}

# This function checks and verifies BIOS files for RetroDECK.
# It reads a list of required BIOS files from a JSON file, checks if they exist in the specified folder,
# verifies their MD5 hashes if provided, and displays the results in a Zenity dialog.
configurator_check_bios_files() {

  configurator_generic_dialog "RetroDECK Configurator - BIOS Checker" "This check will look for BIOS files that RetroDECK has identified as working.\n\nNot all BIOS files are required for games to work, please check the BIOS description for more information on its purpose.\n\nBIOS files not known to this tool could still function.\n\nSome more advanced emulators such as Ryujinx will have additional methods to verify that the BIOS files are in working order."

  log d "Starting BIOS check in mode: $mode"

  (

    # Read the BIOS checklist from bios.json using jq
    total_bios=$(jq '.bios | length' $bios_checklist)
    current_bios=0

    log d "Total BIOS files to check: $total_bios"

    declare -a bios_checked_list

    while read -r entry; do
        # Extract the key (element name) and the fields
        bios_file=$(echo "$entry" | jq -r '.key // "Unknown"')
        bios_md5=$(echo "$entry" | jq -r '.value.md5 | if type=="array" then join(", ") else . end // "Unknown"')
        bios_systems=$(echo "$entry" | jq -r '.value.system | if type=="array" then join(", ") else . end // "Unknown"')
        # Broken
        #bios_systems_pretty=$(echo "$bios_systems" | jq -R -r 'split(", ") | map(. as $sys | input_filename | gsub("features.json"; "") | .emulator[$sys].name) | join(", ")' --slurpfile features $features)
        bios_desc=$(echo "$entry" | jq -r '.value.description // "No description provided"')
        required=$(echo "$entry" | jq -r '.value.required // "No"')
        bios_paths=$(echo "$entry" | jq -r '.value.paths | if type=="array" then join(", ") else . end // "'"$bios_folder"'"' | sed "s|"$rdhome/"||")

      log d "Checking entry $bios_entry"

      # Replace "bios/" with $bios_folder and "roms/" with $roms_folder
      bios_paths=$(echo "$bios_paths" | sed "s|bios/|$bios_folder/|g" | sed "s|roms/|$roms_folder/|g")

      # Skip if bios_file is empty
      if [[ ! -z "$bios_file" ]]; then
        bios_file_found="Yes"
        bios_md5_matched="No"

        IFS=', ' read -r -a paths_array <<< "$bios_paths"
        for path in "${paths_array[@]}"; do
          if [[ ! -f "$path/$bios_file" ]]; then
            bios_file_found="No"
            break
          fi
        done

        if [[ $bios_file_found == "Yes" ]]; then
          IFS=', ' read -r -a md5_array <<< "$bios_md5"
          for md5 in "${md5_array[@]}"; do
            if [[ $(md5sum "$path/$bios_file" | awk '{ print $1 }') == "$md5" ]]; then
              bios_md5_matched="Yes"
              break
            fi
          done
        fi

        log d "BIOS file found: $bios_file_found, Hash matched: $bios_md5_matched"
        log d "Expected path: $path/$bios_file"
        log d "Expected MD5: $bios_md5"

      fi

      log d "Adding BIOS entry: \"$bios_file $bios_systems $bios_file_found $bios_md5_matched $bios_desc $bios_paths $bios_md5\" to the bios_checked_list"

      if [[ $bios_checked_list != "" ]]; then
        bios_checked_list=("${bios_checked_list[@]}"^"$bios_file^$bios_systems^$bios_file_found^$bios_md5_matched^$required^$bios_paths^$bios_desc^$bios_md5")
      else
        bios_checked_list=("$bios_file^$bios_systems^$bios_file_found^$bios_md5_matched^$required^$bios_paths^$bios_desc^$bios_md5")
      fi
      #echo "$bios_file"^"$bios_systems"^"$bios_file_found"^"$bios_md5_matched"^"$bios_paths"^"$bios_md5"^"$bios_desc" # Godot data transfer #TODO: this is breaking the zenity dialog, since we don't release Godot in this version I disabled it.

      current_bios=$((current_bios + 1))
      echo "$((current_bios * 100 / total_bios))"

    done < <(jq -c '.bios | to_entries[]' "$bios_checklist")

    log d "Finished checking BIOS files"

    IFS="^" # Set the Internal Field Separator to ^ to split the bios_checked_list array
    rd_zenity --list --title="RetroDECK Configurator Utility - BIOS Checker" --cancel-label="Back" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
      --column "BIOS File Name" \
      --column "Systems" \
      --column "Found" \
      --column "Hash Matches" \
      --column "Required" \
      --column "Expected Path" \
      --column "Description" \
      --column "MD5" \
      $(printf '%s\n' "${bios_checked_list[@]}")
    IFS=$' \t\n' # Reset the Internal Field Separator

  ) |
  rd_zenity --progress --no-cancel --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - BIOS Check in Progress" \
  --text="RetroDECK is checking your BIOS files, please wait..." \
  --width=400 --height=100

  configurator_welcome_dialog
}

configurator_check_multifile_game_structure() {
  local folder_games=($(find $roms_folder -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3"))
  if [[ ${#folder_games[@]} -gt 1 ]]; then
    echo "$(find $roms_folder -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3")" > $logs_folder/multi_file_games_"$(date +"%Y_%m_%d_%I_%M_%p").log"
    rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Verify Multi-file Structure" \
    --text="The following games were found to have the incorrect folder structure:\n\n$(find $roms_folder -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3")\n\nIncorrect folder structure can result in failure to launch games or saves being in the incorrect location.\n\nPlease see the RetroDECK wiki for more details!\n\nYou can find this list of games in ~/retrodeck/logs"
  else
    configurator_generic_dialog "RetroDECK Configurator - Verify Multi-file Structure" "No incorrect multi-file game folder structures found."
  fi
  configurator_welcome_dialog
}

configurator_reset_dialog() {

  # This function displays a dialog to the user for selecting components to reset.
  # It first constructs a list of available components and their descriptions by reading
  # from the features.json file.
  # The function then uses `rd_zenity` to display a graphical checklist dialog with the
  # available components and their descriptions.
  # If the user selects components, it calls `prepare_component` with the selected components.
  # If the user cancels the dialog, it calls `configurator_welcome_dialog` to return to the welcome screen.

  local components_list=()
  while IFS= read -r emulator; do
    # Extract the description and name of the current emulator using jq
    desc=$(jq -r --arg emulator "$emulator" '.emulator[$emulator].description' "$features")
    name=$(jq -r --arg emulator "$emulator" '.emulator[$emulator].name' "$features")
    components_list+=("FALSE" "$emulator" "$name" "$desc")
  done < <(prepare_component --list | tr ' ' '\n')

  choice=$(rd_zenity --list \
  --title "RetroDECK Configurator Utility - Reset Components" --cancel-label="Cancel" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --checklist --ok-label="Reset Selected" --extra-button="Reset All" \
  --print-column=2 \
  --text="Which components do you want to reset?" \
  --column "Reset" \
  --column "Emulator" --hide-column=2 \
  --column "Name" \
  --column "Description" \
  "${components_list[@]}")

  if [[ $? == 0 && -n "$choice" ]]; then
    choice=$(echo "$choice" | tr '|' ' ')
    log d "User selected \"Reset Selected\" and selected: ${choice// / }"
    prepare_component "reset" ${choice// / }
    configurator_process_complete_dialog "resetting selected emulators"
  elif [[ $? == 1 ]]; then
    log "User selected \"Reset All\""
    prepare_ccomponent "reset" "all"
    configurator_process_complete_dialog "resetting all emulators"
  else
    log d "User selected \"Cancel\""
    configurator_welcome_dialog
  fi

}

configurator_about_retrodeck_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - About RetroDECK" --cancel-label="Back" \
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
    --filename="$config/retrodeck/reference_lists/retrodeck_credits.txt"
    configurator_about_retrodeck_dialog
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_welcome_dialog
  ;;

  esac
}

configurator_steam_sync() {
  if [[ $(get_setting_value "$rd_conf" "steam_sync" retrodeck "options") == "true" ]]; then
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Steam Syncronization" \
    --text="Steam syncronization is <span foreground='$purple'><b>currently enabled</b></span>.\nDisabling Steam Sync will remove all of your favorites from Steam at the next Steam startup.\n\nDo you want to continue?\n\nTo re-add them, just reenable Steam Sync then and restart Steam."

    if [ $? == 0 ] # User clicked "Yes"
    then
      disable_steam_sync
    else # User clicked "Cancel"
      configurator_welcome_dialog
    fi
  else
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - RetroDECK Steam Syncronization" \
    --text="Steam synchronization is <span foreground='$purple'><b>currently disabled</b></span>. Do you want to enable it?\n\nAll the games marked as favorites will be synchronized with Steam ROM Manager.\nRemember to restart Steam each time to see the changes.\n\n<span foreground='$purple'><b>NOTE: games with unusual characters such as &apos;/\{}&lt;&gt;* might break the sync, please refer to the Wiki for more info.</b></span>"

    if [ $? == 0 ]
    then
      enable_steam_sync
    else
      configurator_welcome_dialog
    fi
  fi
}

enable_steam_sync() {
  set_setting_value "$rd_conf" "steam_sync" "true" retrodeck "options"
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - RetroDECK Steam Syncronization" \
      --text="Steam syncronization enabled."
  configurator_welcome_dialog
}

disable_steam_sync() {
  set_setting_value "$rd_conf" "steam_sync" "false" retrodeck "options"
  source /app/libexec/steam_sync.sh
  remove_from_steam
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="OK" \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - RetroDECK Steam Syncronization" \
      --text="Steam syncronization disabled and shortcuts removed, restart Steam to apply the changes."
  configurator_welcome_dialog
}

configurator_version_history_dialog() {
  local version_array=($(xml sel -t -v '//component/releases/release/@version' -n $rd_metainfo))
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
  "Install Specific Release" "Install any cooker release or the latest main available" \
  "Browse the Wiki" "Browse the RetroDECK wiki online" \
  "Install RetroDECK Starter Pack" "Install the optional RetroDECK starter pack" \
  "Tool: USB Import" "Prepare a USB device for ROMs or import an existing collection" \
  "Open GODOT Configurator" "Open the new Configurator made in GODOT engine")

  case $choice in

  "Change Multi-user mode" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_retrodeck_multiuser_dialog
  ;;

  "Install Specific Release" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_online_update_channel_dialog
  ;;

  "Browse the Wiki" )
    log i "Configurator: opening \"$choice\" menu"
    xdg-open "https://github.com/RetroDECK/RetroDECK/wiki"
    configurator_developer_dialog
  ;;

  "Install RetroDECK Starter Pack" )
    log i "Configurator: opening \"$choice\" menu"
    if [[ $(configurator_generic_question_dialog "Install: RetroDECK Starter Pack" "The RetroDECK creators have put together a collection of classic retro games you might enjoy!\n\nWould you like to have them automatically added to your library?") == "true" ]]; then
      install_retrodeck_starterpack
    fi
    configurator_developer_dialog
  ;;

  "Tool: USB Import" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_usb_import_dialog
  ;;

  "Open GODOT Configurator" )
    log i "Configurator: opening \"$choice\" menu"
    "godot-configurator.sh"
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
      set_setting_value $rd_conf "update_repo" "$cooker_repository_name" retrodeck "options"
    else # User clicked "Cancel"
      configurator_developer_dialog
    fi
  else
    set_setting_value $rd_conf "update_repo" "RetroDECK" retrodeck "options"
    release_selector
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
    configurator_developer_dialog
  ;;
  esac
}

# START THE CONFIGURATOR

configurator_welcome_dialog
