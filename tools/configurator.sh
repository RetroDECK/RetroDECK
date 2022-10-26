#!/bin/bash

# VARIABLES SECTION

#rd_conf="retrodeck.cfg" # uncomment for standalone testing
#source functions.sh # uncomment for standalone testing

source /app/libexec/global.sh # uncomment for flatpak testing
source /app/libexec/functions.sh # uncomment for flatpak testing

# DIALOG SECTION

# Configurator Option Tree

# Welcome
#     - Move Directories
#       - Migrate ROM directory
#       - Migrate BIOS directory
#       - Migrate downloaded_media
#       - Migrate everything
#     - Change Emulator Options
#         - RetroArch
#           - Change Rewind Setting
#           - Enable/disable borders
#           - Enable disable widescreen
#     - Add or Update Files
#       - Add specific cores
#       - Grab all missing cores
#       - Update all cores to nightly
#     - RetroAchivement login
#       - Login prompt
#     - Reset RetroDECK
#       - Reset RetroArch
#       - Reset Specific Standalone Emulator
#           - Reset Yuzu
#           - Reset Dolphin
#           - Reset PCSX2
#           - Reset MelonDS
#           - Reset Citra
#           - Reset RPCS3
#           - Reset XEMU
#           - Reset PPSSPP
#           - Reset Duckstation
#       - Reset All Standalone Emulators
#       - Reset Tools
#       - Reset All

# Code for the menus should be put in reverse order, so functions for sub-menus exists before it is called by the parent menu

# DIALOG TREE FUNCTIONS

configurator_reset_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - Reset Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --column="Choice" --column="Action" \
  "Reset RetroArch" "Reset RetroArch to default settings" \
  "Reset Specific Standalone" "Reset only one specific standalone emulator to default settings" \
  "Reset All Standalones" "Reset all standalone emulators to default settings" \
  "Reset Tools" "Reset Tools menu entries" \
  "Reset All" "Reset RetroDECK to default settings" )

  case $choice in

  "Reset RetroArch" )
    debug_dialog "ra_init"
    configurator_process_complete_dialog "resetting RetroArch"
    ;;

  "Reset Specific Standalone" )
    emulator_to_reset=$(zenity --list \
    --title "RetroDECK Configurator Utility - Reset Specific Standalone Emulator" --cancel-label="Back" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="Which emulator do you want to reset to default?" \
    --hide-header \
    --column=emulator \
    "RetroArch" \
    "Citra" \
    "Dolphin" \
    "Duckstation" \
    "MelonDS" \
    "PCSX2" \
    "PPSSPP" \
    "RPCS3" \
    "XEMU" \
    "Yuzu")

    case $emulator_to_reset in

    "RetroArch" )
      debug_dialog "ra_init"
      configurator_process_complete_dialog "resetting $emulator_to_reset"
    ;;

    "Citra" )
      debug_dialog "citra_init"
      configurator_process_complete_dialog "resetting $emulator_to_reset"
    ;;

    "Dolphin" )
      debug_dialog "dolphin_init"
      configurator_process_complete_dialog "resetting $emulator_to_reset"
    ;;

    "Duckstation" )
      debug_dialog "duckstation_init"
      configurator_process_complete_dialog "resetting $emulator_to_reset"
    ;;

    "MelonDS" )
      debug_dialog "melonds_init"
      configurator_process_complete_dialog "resetting $emulator_to_reset"
    ;;

    "PCSX2" )
      debug_dialog "pcsx2_init"
      configurator_process_complete_dialog "resetting $emulator_to_reset"
    ;;

    "PPSSPP" )
      debug_dialog "ppssppsdl_init"
      configurator_process_complete_dialog "resetting $emulator_to_reset"
    ;;

    "RPCS3" )
      debug_dialog "rpcs3_init"
      configurator_process_complete_dialog "resetting $emulator_to_reset"
    ;;

    "XEMU" )
      debug_dialog "xemu_init"
      configurator_process_complete_dialog "resetting $emulator_to_reset"
    ;;

    "Yuzu" )
      debug_dialog "yuzu_init"
      configurator_process_complete_dialog "resetting $emulator_to_reset"
    ;;

    "" ) # No selection made or Back button clicked
      configurator_reset_dialog
    ;;

    esac
  ;;

"Reset All Standalones" )
  debug_dialog "standalones_init"
  configurator_process_complete_dialog "resetting standalone emulators"
;;

"Reset Tools" )
  debug_dialog "tools_init"
  configurator_process_complete_dialog "resetting the tools menu"
;;

"Reset All" )
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - Reset RetroDECK" \
  --text="You are resetting RetroDECK to its default state.\n\nAfter the process is complete you will need to exit RetroDECK and run it again."
  debug_dialog "rm -f "$lockfile""
  configurator_process_complete_dialog "resetting RetroDECK"
;;

"" ) # No selection made or Back button clicked
  configurator_welcome_dialog
;;

  esac
}

configurator_retroachivement_dialog() {
  login=$(zenity --forms --title="RetroDECK Configurator Utility - RetroAchievements Login" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="Enter your RetroAchievements Account details.\n\nBe aware that this tool cannot verify your login details.\nFor registration and more info visit\nhttps://retroachievements.org/\n" \
  --separator="=SEP=" \
  --add-entry="Username" \
  --add-password="Password")

  if [ $? == 1 ] # Cancel button clicked
  then
    configurator_welcome_dialog
  fi

  arrIN=(${login//=SEP=/ })
  user=${arrIN[0]}
  pass=${arrIN[1]}

  #set_setting_value $raconf cheevos_enable true retroarch
  #set_setting_value $raconf cheevos_username $user retroarch
  #set_setting_value $raconf cheevos_password $pass retroarch

  debug_dialog "set_setting_value $raconf cheevos_enable true retroarch\n\nset_setting_value $raconf cheevos_username $user retroarch\n\nset_setting_value $raconf cheevos_password $pass retroarch"

  configurator_process_complete_dialog "logging in to RetroAchievements"
}

configurator_update_dialog() {
  configurator_generic_dialog "This feature is not available yet"
  configurator_welcome_dialog
}

configurator_power_user_changes_dialog() {
  zenity --title "RetroDECK Configurator Utility - Power User Options" --question --no-wrap --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="Making manual changes to an emulators configuration may create serious issues,\nand some settings may be overwitten during RetroDECK updates.\n\nplease continue only if you know what you're doing.\n\nDo you want to continue?"

  if [ $? == 1 ] # Cancel button clicked
  then
    configurator_options_dialog
  fi

  emulator=$(zenity --list \
  --title "RetroDECK Configurator Utility - Power User Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="Which emulator do you want to configure?" \
  --hide-header \
  --column=emulator \
  "RetroArch" \
  "Citra" \
  "Dolphin" \
  "Duckstation" \
  "MelonDS" \
  "PCSX2-QT" \
  "PCSX2-Legacy" \
  "PPSSPP" \
  "RPCS3" \
  "XEMU" \
  "Yuzu")

  case $emulator in

  "RetroArch" )
    retroarch
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

  "MelonDS" )
    melonDS
  ;;

  "PCSX2-QT" )
    pcsx2-qt
  ;;

  "PCSX2-Legacy" )
    pcsx2
  ;;

  "PPSSPP" )
    PPSSPPSDL
  ;;

  "RPCS3" )
    rpcs3
  ;;

  "XEMU" )
    xemu
  ;;

  "Yuzu" )
    yuzu
    ;;

  "" ) # No selection made or Back button clicked
    configurator_options_dialog
  ;;

  esac
}

configurator_retroarch_rewind_dialog() {
  if [[ $(get_setting_value $raconf rewind_enable retroarch) == "true" ]]; then
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Rewind" \
    --text="Rewind is currently enabled. Do you want to disable it?."

    if [ $? == 0 ]
    then
      debug_dialog "set_setting_value $raconf rewind_enable true retroarch"
      configurator_process_complete_dialog "enabling Rewind"
    else
      configurator_options_dialog
    fi
  else
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Rewind" \
    --text="Rewind is currently disabled, do you want to enable it?\n\nNOTE:\nThis may impact performance expecially on the latest systems."

    if [ $? == 0 ]
    then
      debug_dialog "set_setting_value $raconf rewind_enable false retroarch"
      configurator_process_complete_dialog "disabling Rewind"
    else
      configurator_options_dialog
    fi
  fi
}

configurator_retroarch_options_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - RetroArch Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --column="Choice" --column="Action" \
  "Change Rewind Setting" "Enable or disable the Rewind function in RetroArch" )

  case $choice in

  "Change Rewind Setting" )
    configurator_retroarch_rewind_dialog
  ;;

  "" ) # No selection made or Back button clicked
    configurator_options_dialog
  ;;

  esac
}

configurator_options_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - Change Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --column="Choice" --column="Action" \
  "Change RetroArch Settings" "Change settings specific to RetroArch" \
  "Power User Changes" "Make changes directly in an emulator" )

  case $choice in

  "Change RetroArch Settings" )
    configurator_retroarch_options_dialog
  ;;

  "Power User Changes" )
    configurator_power_user_changes_dialog
  ;;

  "" ) # No selection made or Back button clicked
    configurator_welcome_dialog
  ;;

  esac
}

configurator_move_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - Move Directories" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --column="Choice" --column="Action" \
  "Move ROMs" "Move your ROMs directory to a new location" \
  "Move BIOS" "Move your BIOS directory to a new location" \
  "Move Downloaded Media" "Move your downloaded media directory to a new location" \
  "Move Everything" "Move the entire RetroDECK user directory to a new location" )

  case $choice in

  "Move ROMs" )
    if [[ -d $roms_folder ]]; then
      configurator_generic_dialog "The current ROMs folder was found at $roms_folder.\n\nPlease select the location you would like to move it."
      destination=$(configurator_destination_choice_dialog "ROMs" "Please choose a destination for the ROMs folder.")
      case $destination in
      "Back" )
        configurator_move_dialog
      ;;
      "Internal Storage" )
        if [[ $roms_folder == "$rdhome/roms" ]]; then
          configurator_generic_dialog "The ROMs folder is already at that location, please pick a new one."
          configurator_move_dialog
        else
          configurator_generic_dialog "Moving ROMs folder to $destination"
          debug_dialog "move $roms_folder "$rdhome/roms""
          roms_folder="$rdhome/roms"
          debug_dialog "dir_prep $roms_folder "/var/config/emulationstation/ROMs""
          debug_dialog "conf_write"
          configurator_process_complete_dialog "moving the ROMs directory to internal storage"
        fi
      ;;
      "SD Card" )
        if [[ $roms_folder == "$sdcard/retrodeck/roms" ]]; then
          configurator_generic_dialog "The ROMs folder is already at that location, please pick a new one."
          configurator_move_dialog
        else
          configurator_generic_dialog "Moving ROMs folder to $destination"
          debug_dialog "move $roms_folder "$sdcard/retrodeck/roms""
          debug_dialog "ln -svf $roms_folder $rdhome/roms" # Link back to "default" location for standalone compatibilty
          roms_folder="$sdcard/retrodeck/roms"
          debug_dialog "dir_prep $roms_folder "/var/config/emulationstation/ROMs""
          debug_dialog "conf_write"
          configurator_process_complete_dialog "moving the ROMs directory to SD card"
        fi
      ;;
      "Custom Location" )
        configurator_generic_dialog "Please select the custom location to move the ROMs folder to."
        destination=$(browse "ROMs directory destination")
        if [[ $destination == $roms_folder ]]; then
          configurator_generic_dialog "The ROMs folder is already at that location, please pick a new one."
          configurator_move_dialog
        else
          configurator_generic_dialog "Moving ROMs folder from $roms_folder\n\nto $destination.\n\nClick OK to continue."
          debug_dialog "move $roms_folder $destination"
          debug_dialog "ln -svf $roms_folder $rdhome/roms" # Link back to "default" location for standalone compatibilty
          roms_folder=$destination
          debug_dialog "dir_prep $roms_folder "/var/config/emulationstation/ROMs""
          debug_dialog "conf_write"
          configurator_process_complete_dialog "moving the ROMs directory to $destination"
        fi
      ;;
      esac
    else
      configurator_generic_dialog "The ROMs folder was not found at the configured location.\n\nThis may have happened if the folder was moved manually.\n\nPlease select the current location of the ROMs folder."
      roms_folder=$(browse "ROMs directory location")
      conf_write
      configurator_generic_dialog "ROMs folder now configured at $roms_folder. Please start the moving process again."
      configurator_move_dialog
    fi
  ;;

  "Move BIOS" )
    if [[ -d $bios_folder ]]; then
      configurator_generic_dialog "The current BIOS folder was found at $bios_folder.\n\nPlease select the location you would like to move it."
      destination=$(configurator_destination_choice_dialog "BIOS" "Please choose a destination for the BIOS folder.")
      case $destination in
      "Back" )
        configurator_move_dialog
      ;;
      "Internal Storage" )
        if [[ $bios_folder == "$rdhome/bios" ]]; then
          configurator_generic_dialog "The BIOS folder is already at that location, please pick a new one."
          configurator_move_dialog
        else
          configurator_generic_dialog "Moving BIOS folder to $destination"
          move $bios_folder "$rdhome/bios"
          bios_folder="$rdhome/bios"
          debug_dialog "dir_prep $bios_folder "$rdhome/bios""
          debug_dialog "conf_write"
          configurator_process_complete_dialog "moving the BIOS directory to internal storage"
        fi
      ;;
      "SD Card" )
        if [[ $bios_folder == "$sdcard/retrodeck/bios" ]]; then
          configurator_generic_dialog "The BIOS folder is already at that location, please pick a new one."
          configurator_move_dialog
        else
          configurator_generic_dialog "Moving BIOS folder to $destination"
          move $bios_folder "$sdcard/retrodeck/bios"
          bios_folder="$sdcard/retrodeck/bios"
          debug_dialog "dir_prep $bios_folder "$rdhome/bios""
          debug_dialog "conf_write"
          configurator_process_complete_dialog "moving the BIOS directory to SD card"
        fi
      ;;
      "Custom Location" )
        configurator_generic_dialog "Please select the custom location to move the BIOS folder to."
        destination=$(browse "BIOS directory destination")
        if [[ $destination == $bios_folder ]]; then
          configurator_generic_dialog "The BIOS folder is already at that location, please pick a new one."
          configurator_move_dialog
        else
          configurator_generic_dialog "Moving BIOS folder from $bios_folder\n\nto $destination.\n\nClick OK to continue."
          move $bios_folder $destination
          bios_folder=$destination
          debug_dialog "dir_prep $bios_folder "$rdhome/bios""
          debug_dialog "conf_write"
          configurator_process_complete_dialog "moving the BIOS directory to $destination"
        fi
      ;;
      esac
    else
      configurator_generic_dialog "The BIOS folder was not found at the configured location.\n\nThis may have happened if the folder was moved manually.\n\nPlease select the current location of the BIOS folder."
      bios_folder=$(browse "BIOS directory location")
      conf_write
      configurator_generic_dialog "BIOS folder now configured at $bios_folder. Please start the moving process again."
      configurator_move_dialog
    fi
  ;;

  "Move Downloaded Media" )
    if [[ -d $media_folder ]]; then
      configurator_generic_dialog "The current media folder was found at $media_folder.\n\nPlease select the location you would like to move it."
      destination=$(configurator_destination_choice_dialog "Media" "Please choose a destination for the Media folder.")
      case $destination in
      "Back" )
        configurator_move_dialog
      ;;
      "Internal Storage" )
        if [[ $media_folder == "$rdhome/downloaded_media" ]]; then
          configurator_generic_dialog "The media folder is already at that location, please pick a new one."
          configurator_move_dialog
        else
          configurator_generic_dialog "Moving media folder to $destination"
          debug_dialog "move $media_folder "$rdhome/downloaded_media""
          media_folder="$rdhome/downloaded_media"
          debug_dialog "dir_prep $media_folder "/var/config/emulationstation/.emulationstation/downloaded_media""
          debug_dialog "conf_write"
          configurator_process_complete_dialog "moving the media directory to internal storage"
        fi
      ;;
      "SD Card" )
        if [[ $media_folder == "$sdcard/retrodeck/downloaded_media" ]]; then
          configurator_generic_dialog "The media folder is already at that location, please pick a new one."
          configurator_move_dialog
        else
          configurator_generic_dialog "Moving media folder to $destination"
          debug_dialog "move $media_folder "$sdcard/retrodeck/downloaded_media""
          media_folder="$sdcard/retrodeck/downloaded_media"
          debug_dialog "dir_prep $media_folder "/var/config/emulationstation/.emulationstation/downloaded_media""
          debug_dialog "conf_write"
          configurator_process_complete_dialog "moving the media directory to SD card"
        fi
      ;;
      "Custom Location" )
        configurator_generic_dialog "Please select the custom location to move the media folder to."
        destination=$(browse "Media directory destination")
        if [[ $destination == $media_folder ]]; then
          configurator_generic_dialog "The media folder is already at that location, please pick a new one."
          configurator_move_dialog
        else
          configurator_generic_dialog "Moving media folder from $media_folder\n\nto $destination.\n\nClick OK to continue."
          debug_dialog "move $media_folder $destination"
          media_folder=$destination
          debug_dialog "dir_prep $media_folder "/var/config/emulationstation/.emulationstation/downloaded_media""
          debug_dialog "conf_write"
          configurator_process_complete_dialog "moving the media directory to $destination"
        fi
      ;;
      esac
    else
      configurator_generic_dialog "The media folder was not found at the configured location.\n\nThis may have happened if the folder was moved manually.\n\nPlease select the current location of the media folder."
      media_folder=$(browse "Media directory location")
      conf_write
      configurator_generic_dialog "Media folder now configured at $media_folder. Please start the moving process again."
      configurator_move_dialog
    fi
  ;;

  "Move Everything" )
    if [[ -d $rdhome ]]; then
      configurator_generic_dialog "This option will move the RetroDECK data folder (ROMs, saves, BIOS etc.) to a new location.\n\nPlease choose where to move the RetroDECK data folder."
      destination=$(configurator_destination_choice_dialog "RetroDECK Data" "Please choose a destination for the RetroDECK data folder.")
      case $destination in
      "Back" )
        configurator_move_dialog
      ;;
      "Internal Storage" )
        if [[ ! -L /home/deck/retrodeck && -d /home/deck/retrodeck ]]; then
          configurator_generic_dialog "The RetroDECK data folder is already at that location, please pick a new one."
          configurator_move_dialog
        else
          configurator_generic_dialog "Moving RetroDECK data folder to $destination"
          debug_dialog "unlink /home/deck/retrodeck" # Remove symlink for $rdhome
          debug_dialog "move $sdcard/retrodeck "/home/deck/""
          debug_dialog "roms_folder="$rdhome/roms""
          debug_dialog "dir_prep $roms_folder "/var/config/emulationstation/ROMs""
          debug_dialog "conf_write"
          configurator_process_complete_dialog "moving the RetroDECK data directory to internal storage"
        fi
      ;;
      "SD Card" )
        if [[ -L $rdhome && -d $sdcard/retrodeck ]]; then
          configurator_generic_dialog "The RetroDECK data folder is already at that location, please pick a new one."
          configurator_move_dialog
        else
          if [[ ! -w $sdcard ]]; then
            configurator_generic_dialog "The SD card was found but is not writable\nThis can happen with cards formatted on PC or for other reasons.\nPlease format the SD card through the Steam Deck's Game Mode and try the moving process again."
            configurator_welcome_dialog
          else
            configurator_generic_dialog "Moving RetroDECK data folder to $destination"
            if [[ -L $rdhome/roms ]]; then # Check for ROMs symlink user may have created
                debug dialog "unlink $rdhome/roms"
            fi
            debug_dialog "dir_prep "$sdcard/retrodeck" $rdhome"
            debug_dialog "roms_folder="$sdcard/retrodeck/roms""
            debug_dialog "dir_prep $roms_folder "/var/config/emulationstation/ROMs""
            debug_dialog "conf_write"
            configurator_process_complete_dialog "moving the RetroDECK data directory to SD card"
          fi
        fi
      ;;
      esac
    else
      configurator_generic_dialog "The RetroDECK data folder was not found at the expected location.\n\nThis may have happened if the folder was moved manually.\n\nPlease select the current location of the RetroDECK data folder."
      debug_dialog "rdhome=$(browse "RetroDECK directory location")"
      debug_dialog "conf_write"
      configurator_generic_dialog "RetroDECK data folder now configured at $rdhome. Please start the moving process again."
      configurator_move_dialog
    fi
  ;;

  "" ) # No selection made or Back button clicked
      configurator_welcome_dialog
  ;;

  esac
}

configurator_welcome_dialog() {
  # Clear the variables
  source=
  destination=
  action=
  setting=
  setting_value=

  choice=$(zenity --list --title="RetroDECK Configurator Utility" --cancel-label="Quit" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --column="Choice" --column="Action" \
  "Move Files" "Move files between internal/SD card or to custom locations" \
  "Change Options" "Adjust how RetroDECK behaves" \
  "Update" "Update parts of RetroDECK" \
  "RetroAchivements" "Log in to RetroAchievements" \
  "Reset" "Reset parts of RetroDECK" )

  case $choice in

  "Move Files" )
    configurator_move_dialog
  ;;

  "Change Options" )
    configurator_options_dialog
  ;;

  "Update" )
    configurator_update_dialog
  ;;

  "RetroAchivements" )
    configurator_retroachivement_dialog
  ;;

  "Reset" )
    configurator_reset_dialog
  ;;

  "Quit" )
    exit 0
  ;;

  esac
}

# START THE CONFIGURATOR

configurator_welcome_dialog