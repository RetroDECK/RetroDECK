#!/bin/bash

# VARIABLES SECTION

source /app/libexec/global.sh

# Show loading screen
(
  echo "0"
  echo "# Loading RetroDECK Configurator..."
  sleep 2  # Simulate a brief delay for the loading screen
  echo "100"
) |
rd_zenity --progress --no-cancel --pulsate --auto-close \
  --title="RetroDECK Configurator" \
  --text="Loading RetroDECK Configurator..." \
  --width=400 --height=100

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
#       - Backup Userdata
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
#       - Add RetroDECK to Steam
#       - M3U Multi-File Validator
#       - Ponzu: Remove Yuzu
#       - Ponzu: Remove Citra
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
  export CONFIGURATOR_GUI="zenity"
  welcome_menu_options=(
    "Settings" "Customize your RetroDECK experience with various presets and tweaks."
    "Open Component" "Manually launch and configure settings for each emulator or component (for advanced users)."
    "Reset Components" "Reset a specific emulator, component or all of RetroDECK."
    "Tools" "Various tools for verifying files and BIOS, and installing optional features."
    "Steam Sync" "Enable / Disable: Synchronization of all favorited games with Steam."
    "Data Management" "Move RetroDECK folders between internal storage, SD card, or a custom location, and clean out empty ROM folders or rebuild all ROM folders."
    "About RetroDECK" "View additional information, including patch notes and credits."
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
    configurator_tools_dialog
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
    unset CONFIGURATOR_GUI
    exit 0
  ;;

  esac
}

configurator_global_presets_and_settings_dialog() {
  choice=$(rd_zenity --list --title="RetroDECK Configurator Utility - Global: Presets & Settings" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Borders" "Enable / Disable: Borders in supported systems in RetroArch." \
  "Widescreen" "Enable / Disable: Widescreen in supported systems." \
  "Ask-to-Exit" "Enable / Disable: Popups that asks - Are sure you want to Quit? in supported systems." \
  "Quick Resume" "Enable / Disable: Save state auto-save/load in supported systems." \
  "Rewind" "Enable / Disable: the rewind function in supported systems." \
  "Swap A/B and X/Y Buttons" "Enable / Disable: Swapped A/B and X/Y button layout in supported systems." \
  "RetroAchievements: Login" "Login the RetroAchievements in supported systems." \
  "RetroAchievements: Logout" "Logout RetroAchievements service in ALL supported systems" \
  "RetroAchievements: Hardcore Mode" "Enable / Disable: RetroAchievements Hardcore Mode (no cheats, rewind, save states, etc.) in supported systems." \
  "Universal Dynamic Input Textures: Dolphin" "Enable / Disable: Universal Dynamic Input Textures for Dolphin." \
  "Universal Dynamic Input Textures: Primehack" "Enable / Disable: Universal Dynamic Input Textures for Primehack." \
  "PortMaster: Hide" "Enable / Disable: PortMaster in ES-DE."
  )

  case $choice in

  "Borders" )
    log i "Configurator: opening \"$choice\" menu"
    if [[ $native_resolution == false ]]; then 
        rd_zenity --question --text="Borders are actually supported for ${width}x${height} resolution at the moment. This can be set in the Steam shortcut.\n\nDo you still want to continue?"
        response=$?  # Capture the exit code immediately
        if [ "$response" -eq 0 ]; then
            change_preset_dialog "borders"
        else
            configurator_global_presets_and_settings_dialog
        fi
    else
        change_preset_dialog "borders"
    fi
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
      set_setting_value "$rd_conf" "$emulator" "false" "retrodeck" "cheevos"
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

  "Universal Dynamic Input Textures: Dolphin" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_dolphin_input_textures_dialog
  ;;

  "Universal Dynamic Input Textures: Primehack" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_primehack_input_textures_dialog
  ;;

  "PortMaster: Hide" )
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
  if [[ -d "$dolphinDynamicInputTexturesPath" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Universal Dynamic Input Textures: Dolphin" \
    --text="Custom input textures are currently enabled. Do you want to disable them?"

    if [ $? == 0 ]
    then
      # set_setting_value $dolphingfxconf "HiresTextures" "False" dolphin # TODO: Break out a preset for texture packs so this can be enabled and disabled independently.
      rm -rf "$dolphinDynamicInputTexturesPath" && log d "Dolphin custom input textures folder deleted: $dolphinDynamicInputTexturesPath"
      configurator_process_complete_dialog "disabling Dolphin custom input textures"
    else
      configurator_global_presets_and_settings_dialog
    fi
  else
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Universal Dynamic Input Textures: Dolphin" \
    --text="Custom input textures are currently disabled. Do you want to enable them?\n\nThis process may take several minutes to complete."

    if [ $? == 0 ]
    then
      set_setting_value $dolphingfxconf "HiresTextures" "True" dolphin
      (
        mkdir -p "$dolphinDynamicInputTexturesPath" && log d "Dolphin custom input textures folder created: $dolphinDynamicInputTexturesPath"
        rsync -rlD --mkpath "/app/retrodeck/extras/DynamicInputTextures/" "$dolphinDynamicInputTexturesPath/" && log d "Dolphin custom input textures folder populated: $dolphinDynamicInputTexturesPath"
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --text="Enabling Dolphin custom input textures, please wait..." \
      --title "RetroDECK Configurator Utility - Dolphin Custom Input Textures Install"
      configurator_process_complete_dialog "enabling Dolphin custom input textures"
    else
      configurator_global_presets_and_settings_dialog
    fi
  fi
}

configurator_primehack_input_textures_dialog() {
  if [[ -d "$primehackDynamicInputTexturesPath" ]]; then
    rd_zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Dolphin Custom Input Textures" \
    --text="Custom input textures are currently enabled. Do you want to disable them?"

    if [ $? == 0 ]
    then
      # TODO: unify this in a single function
      # set_setting_value $primehackgfxconf "HiresTextures" "False" primehack # TODO: Break out a preset for texture packs so this can be enabled and disabled independently.
      rm -rf "$primehackDynamicInputTexturesPath" && log d "Primehack custom input textures folder deleted: $primehackDynamicInputTexturesPath"
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
        # TODO: unify this in a single function
        mkdir "$primehackDynamicInputTexturesPath" && log d "Primehack custom input textures folder created: $primehackDynamicInputTexturesPath"
        rsync -rlD --mkpath "/app/retrodeck/extras/DynamicInputTextures/" "$primehackDynamicInputTexturesPath/" && log d "Primehack custom input textures folder populated: $primehackDynamicInputTexturesPath"
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --text="Enabling Primehack custom input textures, please wait..." \
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

configurator_tools_dialog() {

  local choices=(
  "Backup Userdata" "Compress and backup RetroDECK userdata folders."
  "BIOS Checker" "Checks and shows information about BIOS files."
  "Games Compressor" "Compress games to save space for supported systems."
  "Install: RetroDECK Controller Layouts" "Install RetroDECK controller templates into Steam."
  "Install: PS3 Firmware" "Download and Install: Playstation 3 firmware for the RPCS3 emulator."
  "Install: PS Vita Firmware" "Download and Install: PlayStation Vita firmware for the Vita3K emulator."
  "Update Notification" "Enable / Disable: Notifications for new RetroDECK versions."
  "Add RetroDECK to Steam" "Add RetroDECK shortcut to Steam. Steam restart required."
  "M3U Multi-File Validator" "Verify the proper structure of multi-file or multi-disc games."
  )

  if [[ $(get_setting_value "$rd_conf" "kiroi_ponzu" "retrodeck" "options") == "true" ]]; then
    choices+=("Ponzu: Remove Yuzu" "Run Ponzu to remove Yuzu from RetroDECK. Configurations and saves will be mantained.")
  fi
  if [[ $(get_setting_value "$rd_conf" "akai_ponzu" "retrodeck" "options") == "true" ]]; then
    choices+=("Ponzu: Remove Citra" "Run Ponzu to remove Citra from RetroDECK. Configurations and saves will be mantained.")
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
    configurator_bios_checker
  ;;

  "Games Compressor" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "Depending on your library and compression choices, the process can sometimes take a long time.\nPlease be patient once it is started!"
    configurator_compression_tool_dialog
  ;;

  "Install: RetroDECK Controller Layouts" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_generic_dialog "RetroDECK Configurator - Install: RetroDECK Controller Profile" "We are now offering a new official RetroDECK controller profile!\nIt is an optional component that helps you get the most out of RetroDECK with a new in-game radial menu for unified hotkeys across emulators.\n\nThe files need to be installed outside of the normal ~/retrodeck folder, so we wanted your permission before proceeding.\n\nThe files will be installed at the following shared Steam locations:\n\n$HOME/.steam/steam/tenfoot/resource/images/library/controller/binding_icons/\n$HOME/.steam/steam/controller_base/templates"
    if [[ $(configurator_generic_question_dialog "Install: RetroDECK Controller Profile" "Would you like to install the official RetroDECK controller profile?") == "true" ]]; then
      install_retrodeck_controller_profile
      configurator_generic_dialog "RetroDECK Configurator - Install: RetroDECK Controller Profile" "The RetroDECK controller profile install is complete.\nSee the Wiki for more details on how to use it to its fullest potential!"
    fi
    configurator_tools_dialog
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
      configurator_tools_dialog
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
      configurator_tools_dialog
    fi
  ;;

  "Update Notification" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_update_notify_dialog
  ;;

  "Add RetroDECK to Steam" )
    add_retrodeck_to_steam
  ;;

  "M3U Multi-File Validator" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_check_multifile_game_structure
  ;;

  "Ponzu: Remove Yuzu" )
    ponzu_remove "yuzu"
  ;;

  "Ponzu: Remove Citra" )
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
  "Move all of RetroDECK" "Move the entire RetroDECK folder to a new location." \
  "Move ROMs folder" "Move the ROMs folder to a new location." \
  "Move BIOS folder" "Move the BIOS folder to a new location." \
  "Move Downloaded Media folder" "Move the Downloaded Media folder to a new location." \
  "Move Saves folder" "Move the Saves folder to a new location." \
  "Move States folder" "Move the States folder to a new location." \
  "Move Themes folder" "Move the Themes folder to a new location." \
  "Move Screenshots folder" "Move the Screenshots folder to a new location." \
  "Move Mods folder" "Move the Mods folder to a new location." \
  "Move Texture Packs folder" "Move the Texture Packs folder to a new location" \
  "Move Cheats folder" "Move the Cheats folder to a new location" \
  "Move Shaders folder" "Move the Shaders folder to a new location" \
  "Clean Empty ROM Folders" "Removes some or all of the empty ROM folders." \
  "Rebuild All ROM Folders" "Rebuilds any missing ROM folders." )

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

  "Move Cheats folder" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_move_folder_dialog "cheats_folder"
  ;;

  "Move Shaders folder" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_move_folder_dialog "shaders_folder"
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
  "Compress Single Game" "Compress a single game into a compatible format." \
  "Compress Multiple Games: CHD" "Compress one or more games into the CHD format." \
  "Compress Multiple Games: ZIP" "Compress one or more games into the ZIP format." \
  "Compress Multiple Games: RVZ" "Compress one or more games into the RVZ format." \
  "Compress Multiple Games: All Formats" "Compress one or more games into any format." \
  "Compress All Games" "Compress all games into compatible formats." )

  case $choice in

  "Compress Single Game" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_single_game_dialog
  ;;

  "Compress Multiple Games: CHD" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "chd"
  ;;

  "Compress Multiple Games: ZIP" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "zip"
  ;;

  "Compress Multiple Games: RVZ" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "rvz"
  ;;

  "Compress Multiple Games: All Formats" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "all"
  ;;

  "Compress All Games" )
    log i "Configurator: opening \"$choice\" menu"
    configurator_compress_multiple_games_dialog "everything"
  ;;

  "" ) # No selection made or Back button clicked
    log i "Configurator: going back"
    configurator_tools_dialog
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
      --width="800" \
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
  log d "Starting to compress \"$1\""
  local output_file="${godot_compression_compatible_games}"
  [ -f "$output_file" ] && rm -f "$output_file"
  touch "$output_file"

  ## --- SEARCH PHASE WITH LOADING SCREEN ---
  local progress_pipe
  progress_pipe=$(mktemp -u)
  mkfifo "$progress_pipe"

  # Launch find_compatible_games in the background (its output goes to the file)
  find_compatible_games "$1" > "$output_file" &
  local finder_pid=$!

  # Launch a background process that writes loading messages until the search completes.
  (
    while kill -0 "$finder_pid" 2>/dev/null; do
      echo "# Loading: Searching for compatible games..."
      sleep 1
    done
    echo "100"
  ) > "$progress_pipe" &
  local progress_writer_pid=$!

  rd_zenity --progress --pulsate --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title="RetroDECK Configurator Utility - Searching for Compressable Games" \
    --text="Searching for compressable games, please wait..." < "$progress_pipe"

  wait "$finder_pid"
  wait "$progress_writer_pid"
  rm "$progress_pipe"

  if [[ -s "$output_file" ]]; then
    mapfile -t all_compressable_games < "$output_file"
    log d "Found the following games to compress: ${all_compressable_games[*]}"
  else
    configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "No compressable files were found."
    return
  fi

  local games_to_compress=()
  if [[ "$1" != "everything" ]]; then
    local checklist_entries=()
    for line in "${all_compressable_games[@]}"; do
      IFS="^" read -r game comp <<< "$line"
      local short_game="${game#$roms_folder}"
      checklist_entries+=( "TRUE" "$short_game" "$line" )
    done

    local choice
    choice=$(rd_zenity \
      --list --width=1200 --height=720 --title "RetroDECK Configurator - Compression Tool" \
      --checklist --hide-column=3 --ok-label="Compress Selected" --extra-button="Compress All" \
      --separator="," --print-column=3 \
      --text="Choose which games to compress:" \
      --column "Compress?" \
      --column "Game" \
      --column "Game Full Path" \
      "${checklist_entries[@]}")

    local rc=$?
    log d "User choice: $choice"
    if [[ $rc == 0 && -n "$choice" ]]; then
      IFS="," read -ra games_to_compress <<< "$choice"
    elif [[ -n "$choice" ]]; then
      games_to_compress=("${all_compressable_games[@]}")
    else
      return
    fi
  else
    games_to_compress=("${all_compressable_games[@]}")
  fi

  local total_games=${#games_to_compress[@]}
  local games_left=$total_games

  ## --- COMPRESSION PHASE WITH PROGRESS SCREEN ---
  local comp_pipe
  comp_pipe=$(mktemp -u)
  mkfifo "$comp_pipe"

  (
    for game_line in "${games_to_compress[@]}"; do
      IFS="^" read -r game compression_format <<< "$game_line"
      local system
      system=$(echo "$game" | grep -oE "$roms_folder/[^/]+" | grep -oE "[^/]+$")
      log i "Compressing $(basename "$game") into $compression_format format"

      # Launch the compression in the background.
      compress_game "$compression_format" "$game" "$system" &
      local comp_pid=$!

      # While the compression is in progress, write a status message every second.
      while kill -0 "$comp_pid" 2>/dev/null; do
        echo "# Compressing $(basename "$game") into $compression_format format"
        sleep 1
      done

      # When finished, update the progress percentage.
      local progress=$(( 100 - (( 100 / total_games ) * games_left) ))
      echo "$progress"
      games_left=$(( games_left - 1 ))
    done
    echo "100"
  ) > "$comp_pipe" &
  local comp_pid_group=$!

  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck/retrodeck.svg" \
    --width="800" \
    --title "RetroDECK Configurator Utility - Compression in Progress" < "$comp_pipe"

  wait "$comp_pid_group"
  rm "$comp_pipe"

  configurator_generic_dialog "RetroDECK Configurator - Compression Tool" "The compression process is complete!"
  configurator_compression_tool_dialog
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
      configurator_tools_dialog
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
      configurator_tools_dialog
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
      configurator_tools_dialog
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
      configurator_tools_dialog
    fi
  fi
  configurator_tools_dialog
}

# This function checks and verifies BIOS files for RetroDECK.
# It reads a list of required BIOS files from a JSON file, checks if they exist in the specified folder,
# verifies their MD5 hashes if provided, and displays the results in a Zenity dialog.
configurator_bios_checker() {

  log d "Starting BIOS checker"

  (
    # Read the BIOS checklist from bios.json using jq
    total_bios=$(jq '.bios | length' "$bios_checklist")
    current_bios=0

    log d "Total BIOS files to check: $total_bios"

    declare -a bios_checked_list

    while read -r entry; do
        # Extract the key (element name) and the fields
        bios_file=$(echo "$entry" | jq -r '.key // "Unknown"')
        bios_md5=$(echo "$entry" | jq -r '.value.md5 | if type=="array" then join(", ") else . end // "Unknown"')
        bios_systems=$(echo "$entry" | jq -r '.value.system | if type=="array" then join(", ") else . end // "Unknown"')
        bios_desc=$(echo "$entry" | jq -r '.value.description // "No description provided"')
        required=$(echo "$entry" | jq -r '.value.required // "No"')
        bios_paths=$(echo "$entry" | jq -r '.value.paths // "'"$bios_folder"'" | if type=="array" then join(", ") else . end')

        log d "Checking entry $bios_entry"

        # Expand any embedded shell variables (e.g. $saves_folder or $bios_folder) with their actual values
        bios_paths=$(echo "$bios_paths" | envsubst)

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
  rd_zenity --progress --auto-close --no-cancel \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility - BIOS Check in Progress" \
    --text="This check will look for BIOS files that RetroDECK has identified as working.\n\nNot all BIOS files are required for games to work, please check the BIOS description for more information on its purpose.\n\nBIOS files not known to this tool could still function.\n\nSome more advanced emulators such as Ryujinx will have additional methods to verify that the BIOS files are in working order.\n\nRetroDECK is now checking your BIOS files, please wait...\n\n" \
    --width=400 --height=100

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
  --checklist --ok-label="Reset Selected" --extra-button="Reset All" --extra-button="Factory Reset" \
  --print-column=2 \
  --text="Which components do you want to reset?" \
  --column "Reset" \
  --column "Emulator" --hide-column=2 \
  --column "Name" \
  --column "Description" \
  "${components_list[@]}")

  log d "User selected: $choice"

  if [[ "$choice" == "Factory Reset" ]]; then
    rd_zenity --question \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Factory Reset" \
      --text="This will reset all RetroDECK settings and configurations to their default state, RetroDECk will restart with the first time setup.\n\n<span foreground='$purple'><b>Your personal data, such as games, saves and scraped content will remain untouched.</b></span>\n\nAre you sure you want to proceed?"
    if [[ $? == 0 ]]; then # User clicked "Yes"
      prepare_component --factory-reset
      configurator_process_complete_dialog "performing a factory reset"
    else # User clicked "Cancel"
      configurator_welcome_dialog
    fi
  elif [[ "$choice" == "Reset All" ]]; then
    rd_zenity --question \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Factory Reset" \
      --text="This will reset all RetroDECK components to their default settings.\n\n<span foreground='$purple'><b>Your personal data, such as games, saves and scraped content will remain untouched.</b></span>\n\nAre you sure you want to proceed?"
    if [[ $? == 0 ]]; then # User clicked "Yes"
      (
        prepare_component "reset" "all"
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Reset in Progress" \
      --text="Resetting all components, please wait...\n\n"
      configurator_process_complete_dialog "resetting all components"
    else # User clicked "Cancel"
      configurator_welcome_dialog
    fi
  elif [[ -n "$choice" ]]; then
    choice=$(echo "$choice" | tr '|' ' ')
    log d "...and selected: ${choice// / }"
    pretty_choice=$(echo "$choice" | tr ' ' '\n' | while read -r emulator; do
      jq -r --arg emulator "$emulator" '.emulator[$emulator].name' "$features"
    done | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
    rd_zenity --question \
      --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator - Reset Components" \
      --text="You selected the following components to be reset:\n\n${pretty_choice}\n\nDo you want to continue?"
    if [[ $? == 0 ]]; then # User clicked "Yes"
      (
      prepare_component "reset" ${choice// / }
      ) |
      rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Reset in Progress" \
      --text="Resetting selected components, please wait...\n\n"
    else # User clicked "Cancel"
      configurator_reset_dialog
    fi
    configurator_process_complete_dialog "resetting selected emulators"
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
