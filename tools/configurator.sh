#!/bin/bash

# VARIABLES SECTION

source /app/libexec/global.sh
source /app/libexec/functions.sh

# DIALOG SECTION

# Configurator Option Tree

# Welcome
#     - Move RetroDECK
#     - RetroArch Presets
#       - Change Rewind Setting
#         - Enable/Disable Rewind
#       - RetroAchivement Login
#         - Login prompt
#     - Emulator Options (Behind one-time power user warning dialog)
#       - Launch RetroArch
#       - Launch Citra
#       - Launch Dolphin
#       - Launch Duckstation
#       - Launch MelonDS
#       - Launch PCSX2
#       - Launch PPSSPP
#       - Launch Primehack
#       - Launch RPCS3
#       - Launch XEMU
#       - Launch Yuzu
#     - Tools and Troubleshooting
#       - Multi-file game check
#       - Basic BIOS file check
#       - Advanced BIOS file check
#       - Compress Games
#         - Manual single-game selection
#         - Multi-file compression (CHD)
#     - Reset
#       - Reset Specific Emulator
#           - Reset RetroArch
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
#       - Reset All Emulators
#       - Reset All

# Code for the menus should be put in reverse order, so functions for sub-menus exists before it is called by the parent menu

# DIALOG TREE FUNCTIONS

configurator_reset_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - Reset Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Reset Specific Emulator" "Reset only one specific emulator to default settings" \
  "Reset All Emulators" "Reset all emulators to default settings" \
  "Reset RetroDECK" "Reset RetroDECK to default settings" )

  case $choice in

  "Reset Specific Emulator" )
    emulator_to_reset=$(zenity --list \
    --title "RetroDECK Configurator Utility - Reset Specific Standalone Emulator" --cancel-label="Back" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
    --text="Which emulator do you want to reset to default?" \
    --column="Emulator" --column="Action" \
    "RetroArch" "Reset RetroArch to default settings" \
    "Citra" "Reset Citra to default settings" \
    "Dolphin" "Reset Dolphin to default settings" \
    "Duckstation" "Reset Duckstation to default settings" \
    "MelonDS" "Reset MelonDS to default settings" \
    "PCSX2" "Reset PCSX2 to default settings" \
    "PPSSPP" "Reset PPSSPP to default settings" \
    "Primehack" "Reset Primehack to default settings" \
    "RPCS3" "Reset RPCS3 to default settings" \
    "XEMU" "Reset XEMU to default settings" \
    "Yuzu" "Reset Yuzu to default settings" )

    case $emulator_to_reset in

    "RetroArch" )
      if [[ $(configurator_reset_confirmation_dialog "RetroArch" "Are you sure you want to reset the RetroArch emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        ra_init
        configurator_process_complete_dialog "resetting $emulator_to_reset"
      else
        configurator_generic_dialog "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "Citra" )
      if [[ $(configurator_reset_confirmation_dialog "Citra" "Are you sure you want to reset the Citra emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        citra_init
        configurator_process_complete_dialog "resetting $emulator_to_reset"
      else
        configurator_generic_dialog "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "Dolphin" )
      if [[ $(configurator_reset_confirmation_dialog "Dolphin" "Are you sure you want to reset the Dolphin emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        dolphin_init
        configurator_process_complete_dialog "resetting $emulator_to_reset"
      else
        configurator_generic_dialog "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "Duckstation" )
      if [[ $(configurator_reset_confirmation_dialog "Duckstation" "Are you sure you want to reset the Duckstation emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        duckstation_init
        configurator_process_complete_dialog "resetting $emulator_to_reset"
      else
        configurator_generic_dialog "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "MelonDS" )
      if [[ $(configurator_reset_confirmation_dialog "MelonDS" "Are you sure you want to reset the MelonDS emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        melonds_init
        configurator_process_complete_dialog "resetting $emulator_to_reset"
      else
        configurator_generic_dialog "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "PCSX2" )
      if [[ $(configurator_reset_confirmation_dialog "PCSX2" "Are you sure you want to reset the PCSX2 emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        pcsx2_init
        configurator_process_complete_dialog "resetting $emulator_to_reset"
      else
        configurator_generic_dialog "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "PPSSPP" )
      if [[ $(configurator_reset_confirmation_dialog "PPSSPP" "Are you sure you want to reset the PPSSPP emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        ppssppsdl_init
        configurator_process_complete_dialog "resetting $emulator_to_reset"
      else
        configurator_generic_dialog "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "Primehack" )
      if [[ $(configurator_reset_confirmation_dialog "Primehack" "Are you sure you want to reset the Primehack emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        primehack_init
        configurator_process_complete_dialog "resetting $emulator_to_reset"
      else
        configurator_generic_dialog "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "RPCS3" )
      if [[ $(configurator_reset_confirmation_dialog "RPCS3" "Are you sure you want to reset the RPCS3 emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        rpcs3_init
        configurator_process_complete_dialog "resetting $emulator_to_reset"
      else
        configurator_generic_dialog "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "XEMU" )
      if [[ $(configurator_reset_confirmation_dialog "XEMU" "Are you sure you want to reset the XEMU emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        xemu_init
        configurator_process_complete_dialog "resetting $emulator_to_reset"
      else
        configurator_generic_dialog "Reset process cancelled."
        configurator_reset_dialog
      fi
    ;;

    "Yuzu" )
      if [[ $(configurator_reset_confirmation_dialog "Yuzu" "Are you sure you want to reset the Yuzu emulator to default settings?\n\nThis process cannot be undone.") == "true" ]]; then
        yuzu_init
        configurator_process_complete_dialog "resetting $emulator_to_reset"
      else
        configurator_generic_dialog "Reset process cancelled."
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
    ra_init
    standalones_init
    configurator_process_complete_dialog "resetting all emulators"
  else
    configurator_generic_dialog "Reset process cancelled."
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
    configurator_generic_dialog "Reset process cancelled."
    configurator_reset_dialog
  fi
;;

"" ) # No selection made or Back button clicked
  configurator_welcome_dialog
;;

  esac
}

configurator_retroachivement_dialog() {
  login=$(zenity --forms --title="RetroDECK Configurator Utility - RetroArch RetroAchievements Login" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --text="Enter your RetroAchievements Account details.\n\nBe aware that this tool cannot verify your login details and currently only supports logging in with RetroArch.\nFor registration and more info visit\nhttps://retroachievements.org/\n" \
  --separator="=SEP=" \
  --add-entry="Username" \
  --add-password="Password")

  if [ $? == 0 ]; then # OK button clicked
    arrIN=(${login//=SEP=/ })
    user=${arrIN[0]}
    pass=${arrIN[1]}

    set_setting_value $raconf cheevos_enable true retroarch
    set_setting_value $raconf cheevos_username $user retroarch
    set_setting_value $raconf cheevos_password $pass retroarch

    configurator_process_complete_dialog "logging in to RetroArch RetroAchievements"
  else
    configurator_welcome_dialog
  fi
}

configurator_power_user_warning_dialog() {
  if [[ $power_user_warning == "true" ]]; then
    choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Never show this again" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Desktop Mode Warning" \
    --text="Making manual changes to an emulators configuration may create serious issues,\nand some settings may be overwitten during RetroDECK updates.\n\nSome standalone emulator functions may not work properly outside of Desktop mode.\n\nPlease continue only if you know what you're doing.\n\nDo you want to continue?")
  fi
  rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "0" ]]; then # If user clicked "Yes"
    configurator_power_user_changes_dialog
  else # If any button other than "Yes" was clicked
    if [[ $choice == "No" ]]; then
      configurator_welcome_dialog
    elif [[ $choice == "Never show this again" ]]; then
      set_setting_value $rd_conf "power_user_warning" "false" retrodeck # Store desktop mode warning variable for future checks
      configurator_power_user_changes_dialog
    fi
  fi
}

configurator_power_user_changes_dialog() {
  emulator=$(zenity --list \
  --title "RetroDECK Configurator Utility - Emulator Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --text="Which emulator do you want to launch?" \
  --hide-header \
  --column=emulator \
  "RetroArch" \
  "Citra" \
  "Dolphin" \
  "Duckstation" \
  "MelonDS" \
  "PCSX2" \
  "PPSSPP" \
  "Primehack" \
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
}

configurator_retroarch_rewind_dialog() {
  if [[ $(get_setting_value $raconf rewind_enable retroarch) == "true" ]]; then
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Rewind" \
    --text="Rewind is currently enabled. Do you want to disable it?."

    if [ $? == 0 ]
    then
      set_setting_value $raconf "rewind_enable" "false" retroarch
      configurator_process_complete_dialog "disabling Rewind"
    else
      configurator_retroarch_options_dialog
    fi
  else
    zenity --question \
    --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Rewind" \
    --text="Rewind is currently disabled, do you want to enable it?\n\nNOTE:\nThis may impact performance on some more demanding systems."

    if [ $? == 0 ]
    then
      set_setting_value $raconf "rewind_enable" "true" retroarch
      configurator_process_complete_dialog "enabling Rewind"
    else
      configurator_retroarch_options_dialog
    fi
  fi
}

configurator_retroarch_options_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - RetroArch Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Change Rewind Setting" "Enable or disable the Rewind function in RetroArch." \
  "RetroAchievements Login" "Log into the RetroAchievements service in RetroArch." )

  case $choice in

  "Change Rewind Setting" )
    configurator_retroarch_rewind_dialog
  ;;

  "RetroAchievements Login" )
    configurator_retroachivement_dialog
  ;;

  "" ) # No selection made or Back button clicked
    configurator_welcome_dialog
  ;;

  esac
}

configurator_compress_single_game_dialog() {
  local file=$(file_browse "Game to compress")
  if [[ ! -z "$file" ]]; then
    if [[ $(validate_for_chd "$file") == "true" ]]; then
      local post_compression_cleanup=$(configurator_compression_cleanup_dialog)
      local filename_no_path=$(basename "$file")
      local filename_no_extension="${filename_no_path%.*}"
      local source_file=$(dirname "$(realpath "$file")")"/"$(basename "$file")
      local dest_file=$(dirname "$(realpath "$file")")"/""$filename_no_extension"
      (
      echo "# Compressing $filename_no_path, please wait..."
      compress_to_chd "$source_file" "$dest_file"
      if [[ $post_compression_cleanup == "true" ]]; then # Remove file(s) if requested
        if [[ "$file" == *".cue" ]]; then
          local cue_bin_files=$(grep -o -P "(?<=FILE \").*(?=\".*$)" "$file")
          local file_path=$(dirname "$(realpath "$file")")
          while IFS= read -r line
          do
            echo "# Removing file $line"
            rm -f "$file_path/$line"
          done < <(printf '%s\n' "$cue_bin_files")
          echo "# Removing file $filename_no_path"
          rm -f "$file"
        else
          echo "# Removing file $filename_no_path"
          rm -f "$file"
        fi
      fi
      ) |
      zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Compression in Progress"
      configurator_generic_dialog "The compression process is complete!"
      configurator_compress_games_dialog
    else
      configurator_generic_dialog "File type not recognized. Supported file types are .cue, .gdi and .iso"
      configurator_compress_games_dialog
    fi
  else
    configurator_generic_dialog "No file selected, returning to main menu"
    configurator_welcome_dialog
  fi
}

configurator_compress_multi_game_dialog() {
  # This dialog will display any games it finds to be compressable, from the systems listed under each compression type in
  local compression_format=$1
  local compressable_game=""
  local compressable_games_list=()
  local all_compressable_games=()
  local compressable_systems_list=$(sed -n '/\['"$compression_format"'\]/, /\[/{ /\['"$compression_format"'\]/! { /\[/! p } }' $compression_targets | sed '/^$/d')

  while IFS= read -r system # Find and validate all games that are able to be compressed with this compression type
  do
    if [[ $compression_format == "chd" ]]; then
      compression_candidates=$(find "$roms_folder/$system" -type f \( -name "*.cue" -o -name "*.iso" -o -name "*.gdi" \) ! -path "*.m3u*")
    # TODO: Add ZIP file compression search here
    fi
    while IFS= read -r game
    do
      if [[ $(validate_for_chd "$game") == "true" ]]; then
        all_compressable_games=("${all_compressable_games[@]}" "$game")
        compressable_games_list=("${compressable_games_list[@]}" "false" "${game#$roms_folder}" "$game")
      fi
    done < <(printf '%s\n' "$compression_candidates")
  done < <(printf '%s\n' "$compressable_systems_list")

  choice=$(zenity \
      --list --width=1200 --height=720 \
      --checklist --hide-column=3 --ok-label="Compress Selected" --extra-button="Compress All" \
      --separator="," --print-column=3 \
      --text="Choose which games to compress:" \
      --column "Compress?" \
      --column "Game" \
      --column "Game Full Path" \
      "${compressable_games_list[@]}")

  local rc=$?
  if [[ $rc == "0" && ! -z $choice ]]; then # User clicked "Compress Selected" with at least one game selected
    local post_compression_cleanup=$(configurator_compression_cleanup_dialog)
    IFS="," read -ra games_to_compress <<< "$choice"
    (
    for file in "${games_to_compress[@]}"; do
      local filename_no_path=$(basename "$file")
      local filename_no_extension="${filename_no_path%.*}"
      local source_file=$(dirname "$(realpath "$file")")"/"$(basename "$file")
      local dest_file=$(dirname "$(realpath "$file")")"/""$filename_no_extension"
      echo "# Compressing $filename_no_path" # Update Zenity dialog text
      compress_to_chd "$source_file" "$dest_file"
      if [[ $post_compression_cleanup == "true" ]]; then # Remove file(s) if requested
        if [[ "$file" == *".cue" ]]; then
          local cue_bin_files=$(grep -o -P "(?<=FILE \").*(?=\".*$)" "$file")
          local file_path=$(dirname "$(realpath "$file")")
          while IFS= read -r line
          do
            echo "# Removing file $line"
            rm -f "$file_path/$line"
          done < <(printf '%s\n' "$cue_bin_files")
          echo "# Removing file $filename_no_path"
          rm -f $(realpath "$file")
        else
          echo "# Removing file $filename_no_path"
          rm -f "$(realpath "$file")"
        fi
      fi
    done
    ) |
    zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Compression in Progress"
  else
    if [[ ! -z $choice ]]; then # User clicked "Compress All"
      local post_compression_cleanup=$(configurator_compression_cleanup_dialog)
      (
      for file in "${all_compressable_games[@]}"; do
        local filename_no_path=$(basename "$file")
        local filename_no_extension="${filename_no_path%.*}"
        local source_file=$(dirname "$(realpath "$file")")"/"$(basename "$file")
        local dest_file=$(dirname "$(realpath "$file")")"/""$filename_no_extension"
        echo "# Compressing $filename_no_path" # Update Zenity dialog text
        compress_to_chd "$source_file" "$dest_file"
        if [[ $post_compression_cleanup == "true" ]]; then # Remove file(s) if requested
          if [[ "$file" == *".cue" ]]; then
            local cue_bin_files=$(grep -o -P "(?<=FILE \").*(?=\".*$)" "$file")
            local file_path=$(dirname "$(realpath "$file")")
            while IFS= read -r line
            do
              echo "# Removing file $line"
              rm -f "$file_path/$line"
            done < <(printf '%s\n' "$cue_bin_files")
            echo "# Removing file $filename_no_path"
            rm -f $(realpath "$file")
          else
            echo "# Removing file $filename_no_path"
            rm -f $(realpath "$file")
          fi
        fi
      done
    ) |
    zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility - Compression in Progress"
    configurator_generic_dialog "The compression process is complete!"
    configurator_compress_games_dialog
    else
      configurator_compress_games_dialog
    fi
  fi
}

configurator_compression_cleanup_dialog() {
  zenity --icon-name=net.retrodeck.retrodeck --question --no-wrap --cancel-label="No" --ok-label="Yes" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Compression Cleanup" \
  --text="Do you want to remove old files after they are compressed?\n\nClicking \"No\" will leave all files behind which will need to be cleaned up manually and may result in game duplicates showing in the RetroDECK library."
  local rc=$? # Capture return code, as "Yes" button has no text value
  if [[ $rc == "0" ]]; then # If user clicked "Yes"
    echo "true"
  else # If "No" was clicked
    echo "false"
  fi
}

configurator_compress_games_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - Change Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Compress Single Game" "Compress a single game into a compatible format" \
  "Compress Multiple Games - CHD" "Compress one or more games compatible with the CHD format" )

  case $choice in

  "Compress Single Game" )
    configurator_compress_single_game_dialog
  ;;

  "Compress Multiple Games - CHD" )
    configurator_compress_multi_game_dialog "chd"
  ;;

  # TODO: Add ZIP compression option

  "" ) # No selection made or Back button clicked
    configurator_welcome_dialog
  ;;

  esac
}

configurator_check_multifile_game_structure() {
  local folder_games=($(find $roms_folder -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3"))
  if [[ ${#folder_games[@]} -gt 1 ]]; then
    echo "$(find $roms_folder -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3")" > $logs_folder/multi_file_games_"$(date +"%Y_%m_%d_%I_%M_%p").log"
    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK" \
    --text="The following games were found to have the incorrect folder structure:\n\n$(find $roms_folder -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3")\n\nIncorrect folder structure can result in failure to launch games or saves being in the incorrect location.\n\nPlease see the RetroDECK wiki for more details!\n\nYou can find this list of games in ~/retrodeck/.logs"
  else
    configurator_generic_dialog "No incorrect multi-file game folder structures found."
  fi
  configurator_troubleshooting_tools_dialog
}

configurator_check_bios_files_basic() {
  configurator_generic_dialog "This check will look for BIOS files that RetroDECK has identified as working.\n\nThere may be additional BIOS files that will function with the emulators that are not checked.\n\nSome more advanced emulators such as Yuzu will have additional methods for verifiying the BIOS files are in working order."
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
    if [[ $bios_file_found == "Yes" && ($bios_hash_matched == "Yes" || $bios_hash_matched == "Unknown") && ! " ${bios_checked_list[*]} " =~ " ${bios_system} " ]]; then
      bios_checked_list=("${bios_checked_list[@]}" "$bios_system" )
    fi
  done < $bios_checklist
  systems_with_bios=${bios_checked_list[@]}

  configurator_generic_dialog "The following systems have been found to have at least one valid BIOS file.\n\n$systems_with_bios\n\nFor more information on the BIOS files found please use the Advanced check tool."

  configurator_troubleshooting_tools_dialog
}

configurator_check_bios_files_advanced() {
  configurator_generic_dialog "This check will look for BIOS files that RetroDECK has identified as working.\n\nThere may be additional BIOS files that will function with the emulators that are not checked.\n\nSome more advanced emulators such as Yuzu will have additional methods for verifiying the BIOS files are in working order."
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

  zenity --list --title="RetroDECK Configurator Utility - Verify BIOS Files" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column "BIOS File Name" \
  --column "System" \
  --column "BIOS File Found" \
  --column "BIOS Hash Match" \
  --column "BIOS File Description" \
  "${bios_checked_list[@]}"

  configurator_troubleshooting_tools_dialog
}

configurator_troubleshooting_tools_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility - Change Options" --cancel-label="Back" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "Move RetroDECK" "Move RetroDECK files between internal/SD card or to a custom location" \
  "Multi-file game structure check" "Verify the proper structure of multi-file or multi-disc games" \
  "Basic BIOS file check" "Show a list of systems that BIOS files are found for" \
  "Advanced BIOS file check" "Show advanced information about common BIOS files" \
  "Compress Games" "Compress games to CHD format for systems that support it" )

  case $choice in

  "Move RetroDECK" )
    configurator_generic_dialog "This option will move the RetroDECK data folder (ROMs, saves, BIOS etc.) to a new location.\n\nPlease choose where to move the RetroDECK data folder."
    configurator_move_dialog
  ;;

  "Multi-file game structure check" )
    configurator_check_multifile_game_structure
  ;;

  "Basic BIOS file check" )
    configurator_check_bios_files_basic
  ;;

  "Advanced BIOS file check" )
    configurator_check_bios_files_advanced
  ;;

  "Compress Games" )
    configurator_compress_games_dialog
  ;;

  "" ) # No selection made or Back button clicked
    configurator_welcome_dialog
  ;;

  esac
}

configurator_move_dialog() {
  if [[ -d $rdhome ]]; then
    destination=$(configurator_destination_choice_dialog "RetroDECK Data" "Please choose a destination for the RetroDECK data folder.")
    case $destination in

    "Back" )
      configurator_move_dialog
    ;;

    "Internal Storage" )
      if [[ ! -L "$HOME/retrodeck" && -d "$HOME/retrodeck" ]]; then
        configurator_generic_dialog "The RetroDECK data folder is already at that location, please pick a new one."
        configurator_move_dialog
      else
        configurator_generic_dialog "Moving RetroDECK data folder to $destination"
        unlink $HOME/retrodeck # Remove symlink for $rdhome
        move $rdhome "$HOME"
        if [[ ! -d $rdhome && -d $HOME/retrodeck ]]; then # If the move succeeded
          rdhome="$HOME/retrodeck"
          roms_folder="$rdhome/roms"
          saves_folder="$rdhome/saves"
          states_folder="$rdhome/states"
          bios_folder="$rdhome/bios"
          media_folder="$rdhome/downloaded_media"
          themes_folder="$rdhome/themes"
          emulators_post_move
          conf_write

          configurator_process_complete_dialog "moving the RetroDECK data directory to internal storage"
        else
          configurator_generic_dialog "The moving process was not completed, please try again."
        fi
      fi
    ;;

    "SD Card" )
      if [[ -L "$HOME/retrodeck" && -d "$sdcard/retrodeck" && "$rdhome" == "$sdcard/retrodeck" ]]; then
        configurator_generic_dialog "The RetroDECK data folder is already configured to that location, please pick a new one."
        configurator_move_dialog
      else
        if [[ ! -w $sdcard ]]; then
          configurator_generic_dialog "The SD card was found but is not writable\nThis can happen with cards formatted on PC or for other reasons.\nPlease format the SD card through the Steam Deck's Game Mode and try the moving process again."
          configurator_welcome_dialog
        else
          if [[ $(verify_space $rdhome $sdcard) == "true" ]]; then
            configurator_generic_dialog "Moving RetroDECK data folder to $destination"
            if [[ -L "$HOME/retrodeck/roms" ]]; then # Check for ROMs symlink user may have created
                unlink "$HOME/retrodeck/roms"
            fi
            unlink $HOME/retrodeck # Remove symlink for $rdhome

            (
            dir_prep "$sdcard/retrodeck" "$rdhome"
            ) |
            zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - Move in Progress" \
            --text="Moving directory $rdhome to new location of $sdcard/retrodeck, please wait."

            if [[ -L $rdhome && ! $rdhome == "$HOME/retrodeck" ]]; then # Clean up extraneus symlinks from previous moves
              unlink $rdhome
            fi

            if [[ ! -L "$HOME/retrodeck" ]]; then # Always link back to original directory
              ln -svf "$sdcard/retrodeck" "$HOME"
            fi

            rdhome="$sdcard/retrodeck"
            roms_folder="$rdhome/roms"
            saves_folder="$rdhome/saves"
            states_folder="$rdhome/states"
            bios_folder="$rdhome/bios"
            media_folder="$rdhome/downloaded_media"
            themes_folder="$rdhome/themes"
            emulators_post_move
            conf_write
            configurator_process_complete_dialog "moving the RetroDECK data directory to SD card"
          else
            zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK Configurator Utility - Move Directories" \
            --text="The destination directory you have selected does not have enough free space for the files you are trying to move.\n\nPlease select a new destination or free up some space."
          fi
        fi
      fi
    ;;

    "Custom Location" )
      configurator_generic_dialog "Select the root folder you would like to store the RetroDECK data folder in.\n\nA new folder \"retrodeck\" will be created in the destination chosen."
      custom_dest=$(directory_browse "RetroDECK directory location")
      if [[ ! -w $custom_dest ]]; then
          configurator_generic_dialog "The destination was found but is not writable\n\nThis can happen if RetroDECK does not have permission to write to this location.\n\nThis can typically be solved through the utility Flatseal, please make the needed changes and try the moving process again."
          configurator_welcome_dialog
      else
        if [[ $(verify_space $rdhome $custom_dest) ]];then
          configurator_generic_dialog "Moving RetroDECK data folder to $custom_dest/retrodeck"
          if [[ -L $rdhome/roms ]]; then # Check for ROMs symlink user may have created
            unlink $rdhome/roms
          fi

          unlink $HOME/retrodeck # Remove symlink for $rdhome if the previous location was not internal

          (
          dir_prep "$custom_dest/retrodeck" "$rdhome"
          ) |
          zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK Configurator Utility - Move in Progress" \
          --text="Moving directory $rdhome to new location of $custom_dest/retrodeck, please wait."

          if [[ ! -L "$HOME/retrodeck" ]]; then
            ln -svf "$custom_dest/retrodeck" "$HOME"
          fi

          if [[ -L $rdhome && ! $rdhome == "$HOME/retrodeck" ]]; then # Clean up extraneus symlinks from previous moves
            unlink $rdhome
          fi

          rdhome="$custom_dest/retrodeck"
          roms_folder="$rdhome/roms"
          saves_folder="$rdhome/saves"
          states_folder="$rdhome/states"
          bios_folder="$rdhome/bios"
          media_folder="$rdhome/downloaded_media"
          themes_folder="$rdhome/themes"
          emulators_post_move
          conf_write
          configurator_process_complete_dialog "moving the RetroDECK data directory to SD card"
        else
          zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK Configurator Utility - Move Directories" \
          --text="The destination directory you have selected does not have enough free space for the files you are trying to move.\n\nPlease select a new destination or free up some space."
        fi
      fi
    ;;

    esac
  else
    configurator_generic_dialog "The RetroDECK data folder was not found at the expected location.\n\nThis may have happened if the folder was moved manually.\n\nPlease select the current location of the RetroDECK data folder."
    rdhome=$(directory_browse "RetroDECK directory location")
    roms_folder="$rdhome/roms"
    saves_folder="$rdhome/saves"
    states_folder="$rdhome/states"
    bios_folder="$rdhome/bios"
    media_folder="$rdhome/downloaded_media"
    themes_folder="$rdhome/themes"
    emulator_post_move
    conf_write
    configurator_generic_dialog "RetroDECK data folder now configured at $rdhome. Please start the moving process again."
    configurator_move_dialog
  fi
}

configurator_welcome_dialog() {
  choice=$(zenity --list --title="RetroDECK Configurator Utility" --cancel-label="Quit" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=1200 --height=720 \
  --column="Choice" --column="Action" \
  "RetroArch Presets" "Change RetroArch presets, log into RetroAchievements etc." \
  "Emulator Options" "Launch and configure each emulators settings (for advanced users)" \
  "Tools and Troubleshooting" "Move RetroDECK to a new location, compress games and perform basic troubleshooting" \
  "Reset" "Reset specific parts or all of RetroDECK" )

  case $choice in

  "RetroArch Presets" )
    configurator_retroarch_options_dialog
  ;;

  "Emulator Options" )
    configurator_power_user_warning_dialog
  ;;

  "Tools and Troubleshooting" )
    configurator_troubleshooting_tools_dialog
  ;;

  "Reset" )
    configurator_reset_dialog
  ;;

  esac
}

# START THE CONFIGURATOR

configurator_welcome_dialog