#!/bin/bash

prepare_component() {
  # This function will perform one of several actions on one or more components
  # The actions currently include "reset" and "postmove"
  # The "reset" action will initialize the component
  # The "postmove" action will update the component settings after one or more RetroDECK folders were moved
  # An component can be called by name, by parent folder name in the /var/config root or use the option "all" to perform the action on all components equally
  # The function will also behave differently depending on if the initial request was from the Configurator, the CLI interface or a normal function call if needed
  # USAGE: prepare_component "$action" "$component" "$call_source(optional)"

  action="$1"
  component="$2"
  call_source="$3"

  if [[ "$component" == "retrodeck" ]]; then
    if [[ "$action" == "reset" ]]; then # Update the paths of all folders in retrodeck.cfg and create them
      while read -r config_line; do
        local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
        if [[ ! $current_setting_name =~ (rdhome|sdcard) ]]; then # Ignore these locations
          local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
          declare -g "$current_setting_name=$rdhome/$(basename $current_setting_value)"
          mkdir -p "$rdhome/$(basename $current_setting_value)"
        fi
      done < <(grep -v '^\s*$' $rd_conf | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f')
      mkdir -p "/var/config/retrodeck/godot"
    fi
    if [[ "$action" == "postmove" ]]; then # Update the paths of any folders that came with the retrodeck folder during a move
      while read -r config_line; do
        local current_setting_name=$(get_setting_name "$config_line" "retrodeck")
        if [[ ! $current_setting_name =~ (rdhome|sdcard) ]]; then # Ignore these locations
          local current_setting_value=$(get_setting_value "$rd_conf" "$current_setting_name" "retrodeck" "paths")
          if [[ -d "$rdhome/$(basename $current_setting_value)" ]]; then # If the folder exists at the new ~/retrodeck location
              declare -g "$current_setting_name=$rdhome/$(basename $current_setting_value)"
          fi
        fi
      done < <(grep -v '^\s*$' $rd_conf | awk '/^\[paths\]/{f=1;next} /^\[/{f=0} f')
    fi
  fi

  if [[ "$component" =~ ^(es-de|ES-DE|all)$ ]]; then # For use after ESDE-related folders are moved or a reset
    if [[ "$action" == "reset" ]]; then
      rm -rf /var/config/ES-DE
      mkdir -p /var/config/ES-DE/settings
      cp -f /app/retrodeck/es_settings.xml /var/config/ES-DE/settings/es_settings.xml
      set_setting_value "$es_settings" "ROMDirectory" "$roms_folder" "es_settings"
      set_setting_value "$es_settings" "MediaDirectory" "$media_folder" "es_settings"
      set_setting_value "$es_settings" "UserThemeDirectory" "$themes_folder" "es_settings"
      dir_prep "$rdhome/gamelists" "/var/config/ES-DE/gamelists"
      es-de --home /var/config/ES-DE --create-system-dirs
      update_splashscreens
    fi
    if [[ "$action" == "postmove" ]]; then
      set_setting_value "$es_settings" "ROMDirectory" "$roms_folder" "es_settings"
      set_setting_value "$es_settings" "MediaDirectory" "$media_folder" "es_settings"
      set_setting_value "$es_settings" "UserThemeDirectory" "$themes_folder" "es_settings"
      dir_prep "$rdhome/gamelists" "/var/config/ES-DE/gamelists"
    fi
  fi

  if [[ "$component" =~ ^(retroarch|RetroArch|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/retroarch"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/retroarch"
        cp -fv $emuconfigs/retroarch/retroarch.cfg "$multi_user_data_folder/$SteamAppUser/config/retroarch/"
        cp -fv $emuconfigs/retroarch/retroarch-core-options.cfg "$multi_user_data_folder/$SteamAppUser/config/retroarch/"
      else # Single-user actions
        rm -rf /var/config/retroarch
        mkdir -p /var/config/retroarch
        dir_prep "$bios_folder" "/var/config/retroarch/system"
        dir_prep "$logs_folder/retroarch" "/var/config/retroarch/logs"
        mkdir -pv /var/config/retroarch/shaders/
        cp -rf /app/share/libretro/shaders /var/config/retroarch/
        dir_prep "$rdhome/shaders/retroarch" "/var/config/retroarch/shaders"
        rsync -rlD --mkpath "/app/share/libretro/cores/" "/var/config/retroarch/cores/"
        cp -fv $emuconfigs/retroarch/retroarch.cfg /var/config/retroarch/
        cp -fv $emuconfigs/retroarch/retroarch-core-options.cfg /var/config/retroarch/
        rsync -rlD --mkpath "$emuconfigs/retroarch/core-overrides/" "/var/config/retroarch/config/"
        rsync -rlD --mkpath "$emuconfigs/defaults/retrodeck/presets/remaps/" "/var/config/retroarch/config/remaps/"
        dir_prep "$borders_folder" "/var/config/retroarch/overlays/borders"
        rsync -rlD --mkpath "/app/retrodeck/emu-configs/retroarch/borders/" "/var/config/retroarch/overlays/borders/"
        set_setting_value "$raconf" "savefile_directory" "$saves_folder" "retroarch"
        set_setting_value "$raconf" "savestate_directory" "$states_folder" "retroarch"
        set_setting_value "$raconf" "screenshot_directory" "$screenshots_folder" "retroarch"
        set_setting_value "$raconf" "log_dir" "$logs_folder" "retroarch"
      fi
      # Shared actions

      # PPSSPP
      echo "--------------------------------"
      echo "Initializing PPSSPP_LIBRETRO"
      echo "--------------------------------"
      if [ -d $bios_folder/PPSSPP/flash0/font ]
      then
        mv -fv $bios_folder/PPSSPP/flash0/font $bios_folder/PPSSPP/flash0/font.bak
      fi
      cp -rf "/app/retrodeck/extras/PPSSPP" "$bios_folder/PPSSPP"
      if [ -d $bios_folder/PPSSPP/flash0/font.bak ]
      then
        mv -f $bios_folder/PPSSPP/flash0/font.bak $bios_folder/PPSSPP/flash0/font
      fi

      # MSX / SVI / ColecoVision / SG-1000
      echo "-----------------------------------------------------------"
      echo "Initializing MSX / SVI / ColecoVision / SG-1000 LIBRETRO"
      echo "-----------------------------------------------------------"
      cp -rf "/app/retrodeck/extras/MSX/Databases" "$bios_folder/Databases"
      cp -rf "/app/retrodeck/extras/MSX/Machines" "$bios_folder/Machines"

      # AMIGA
      echo "-----------------------------------------------------------"
      echo "Initializing AMIGA LIBRETRO"
      echo "-----------------------------------------------------------"
      cp -f "/app/retrodeck/extras/Amiga/capsimg.so" "$bios_folder/capsimg.so"
    
      dir_prep "$texture_packs_folder/RetroArch-Mesen" "/var/config/retroarch/system/HdPacks"
      dir_prep "$texture_packs_folder/RetroArch-Mupen64Plus/cache" "/var/config/retroarch/system/Mupen64plus/cache"
      dir_prep "$texture_packs_folder/RetroArch-Mupen64Plus/hires_texture" "/var/config/retroarch/system/Mupen64plus/hires_texture"
    
      # Reset default preset settings
      set_setting_value "$rd_conf" "retroarch" "$(get_setting_value "$rd_defaults" "retroarch" "retrodeck" "cheevos")" "retrodeck" "cheevos"
      set_setting_value "$rd_conf" "retroarch" "$(get_setting_value "$rd_defaults" "retroarch" "retrodeck" "cheevos_hardcore")" "retrodeck" "cheevos_hardcore"
      set_setting_value "$rd_conf" "gb" "$(get_setting_value "$rd_defaults" "gb" "retrodeck" "borders")" "retrodeck" "borders"
      set_setting_value "$rd_conf" "gba" "$(get_setting_value "$rd_defaults" "gba" "retrodeck" "borders")" "retrodeck" "borders"
      set_setting_value "$rd_conf" "gbc" "$(get_setting_value "$rd_defaults" "gbc" "retrodeck" "borders")" "retrodeck" "borders"
      set_setting_value "$rd_conf" "genesis" "$(get_setting_value "$rd_defaults" "genesis" "retrodeck" "borders")" "retrodeck" "borders"
      set_setting_value "$rd_conf" "gg" "$(get_setting_value "$rd_defaults" "gg" "retrodeck" "borders")" "retrodeck" "borders"
      set_setting_value "$rd_conf" "n64" "$(get_setting_value "$rd_defaults" "n64" "retrodeck" "borders")" "retrodeck" "borders"
      set_setting_value "$rd_conf" "psx_ra" "$(get_setting_value "$rd_defaults" "psx_ra" "retrodeck" "borders")" "retrodeck" "borders"
      set_setting_value "$rd_conf" "snes" "$(get_setting_value "$rd_defaults" "snes" "retrodeck" "borders")" "retrodeck" "borders"
      set_setting_value "$rd_conf" "genesis" "$(get_setting_value "$rd_defaults" "genesis" "retrodeck" "widescreen")" "retrodeck" "widescreen"
      set_setting_value "$rd_conf" "n64" "$(get_setting_value "$rd_defaults" "n64" "retrodeck" "widescreen")" "retrodeck" "widescreen"
      set_setting_value "$rd_conf" "psx_ra" "$(get_setting_value "$rd_defaults" "psx_ra" "retrodeck" "widescreen")" "retrodeck" "widescreen"
      set_setting_value "$rd_conf" "snes" "$(get_setting_value "$rd_defaults" "snes" "retrodeck" "widescreen")" "retrodeck" "widescreen"
      set_setting_value "$rd_conf" "gb" "$(get_setting_value "$rd_defaults" "gb" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
      set_setting_value "$rd_conf" "gba" "$(get_setting_value "$rd_defaults" "gba" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
      set_setting_value "$rd_conf" "gbc" "$(get_setting_value "$rd_defaults" "gbc" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
      set_setting_value "$rd_conf" "n64" "$(get_setting_value "$rd_defaults" "gb" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
      set_setting_value "$rd_conf" "snes" "$(get_setting_value "$rd_defaults" "gba" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
      set_setting_value "$rd_conf" "retroarch" "$(get_setting_value "$rd_defaults" "retroarch" "retrodeck" "savestate_auto_load")" "retrodeck" "savestate_auto_load"
      set_setting_value "$rd_conf" "retroarch" "$(get_setting_value "$rd_defaults" "retroarch" "retrodeck" "savestate_auto_save")" "retrodeck" "savestate_auto_save"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$bios_folder" "/var/config/retroarch/system"
      dir_prep "$logs_folder/retroarch" "/var/config/retroarch/logs"
      dir_prep "$rdhome/shaders/retroarch" "/var/config/retroarch/shaders"
      dir_prep "$texture_packs_folder/RetroArch-Mesen" "/var/config/retroarch/system/HdPacks"
      dir_prep "$texture_packs_folder/RetroArch-Mupen64Plus/cache" "/var/config/retroarch/system/Mupen64plus/cache"
      dir_prep "$texture_packs_folder/RetroArch-Mupen64Plus/hires_texture" "/var/config/retroarch/system/Mupen64plus/hires_texture"
      set_setting_value "$raconf" "savefile_directory" "$saves_folder" "retroarch"
      set_setting_value "$raconf" "savestate_directory" "$states_folder" "retroarch"
      set_setting_value "$raconf" "screenshot_directory" "$screenshots_folder" "retroarch"
      set_setting_value "$raconf" "log_dir" "$logs_folder" "retroarch"
    fi
  fi

  if [[ "$component" =~ ^(cemu|Cemu|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing CEMU"
      echo "----------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/Cemu"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/Cemu"
        cp -fr "$emuconfigs/cemu/"* "$multi_user_data_folder/$SteamAppUser/config/Cemu/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/Cemu/settings.ini" "mlc_path" "$bios_folder/cemu" "cemu"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/Cemu/settings.ini" "Entry" "$roms_folder/wiiu" "cemu" "GamePaths"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/Cemu" "/var/config/Cemu"
      else
        rm -rf /var/config/Cemu
        mkdir -pv /var/config/Cemu/
        cp -fr "$emuconfigs/cemu/"* /var/config/Cemu/
        set_setting_value "$cemuconf" "mlc_path" "$bios_folder/cemu" "cemu"
        set_setting_value "$cemuconf" "Entry" "$roms_folder/wiiu" "cemu" "GamePaths"
      fi
      # Shared actions
      dir_prep "$saves_folder/wiiu/cemu" "$bios_folder/cemu/usr/save"
    fi
    if [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
      set_setting_value "$cemuconf" "mlc_path" "$bios_folder/cemu" "cemu"
      set_setting_value "$cemuconf" "Entry" "$roms_folder/wiiu" "cemu" "GamePaths"
      dir_prep "$saves_folder/wiiu/cemu" "$bios_folder/cemu/usr/save"
    fi
  fi

  if [[ "$component" =~ ^(citra|citra-emu|Citra|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "------------------------"
      echo "Initializing CITRA"
      echo "------------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/citra-emu"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/citra-emu"
        cp -fv $emuconfigs/citra/qt-config.ini "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini" "nand_directory" "$saves_folder/n3ds/citra/nand/" "citra" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini" "sdmc_directory" "$saves_folder/n3ds/citra/sdmc/" "citra" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini" "Paths\gamedirs\3\path" "$roms_folder/n3ds" "citra" "UI"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/citra-emu/qt-config.ini" "Paths\screenshotPath" "$screenshots_folder" "citra" "UI"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/citra-emu" "/var/config/citra-emu"
      else # Single-user actions
        rm -rf /var/config/citra-emu
        mkdir -pv /var/config/citra-emu/
        cp -f $emuconfigs/citra/qt-config.ini /var/config/citra-emu/qt-config.ini
        set_setting_value "$citraconf" "nand_directory" "$saves_folder/n3ds/citra/nand/" "citra" "Data%20Storage"
        set_setting_value "$citraconf" "sdmc_directory" "$saves_folder/n3ds/citra/sdmc/" "citra" "Data%20Storage"
        set_setting_value "$citraconf" "Paths\gamedirs\3\path" "$roms_folder/n3ds" "citra" "UI"
        set_setting_value "$citraconf" "Paths\screenshotPath" "$screenshots_folder" "citra" "UI"
      fi
      # Shared actions
      mkdir -pv "$saves_folder/n3ds/citra/nand/"
      mkdir -pv "$saves_folder/n3ds/citra/sdmc/"
      dir_prep "$bios_folder/citra/sysdata" "/var/data/citra-emu/sysdata"
      dir_prep "$logs_folder/citra" "/var/data/citra-emu/log"
      dir_prep "$mods_folder/Citra" "/var/data/citra-emu/load/mods"
      dir_prep "$texture_packs_folder/Citra" "/var/data/citra-emu/load/textures"

      # Reset default preset settings
      set_setting_value "$rd_conf" "citra" "$(get_setting_value "$rd_defaults" "citra" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
      set_setting_value "$rd_conf" "citra" "$(get_setting_value "$rd_defaults" "citra" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$rdhome/bios/citra/sysdata" "/var/data/citra-emu/sysdata"
      dir_prep "$rdhome/logs/citra" "/var/data/citra-emu/log"
      dir_prep "$mods_folder/Citra" "/var/data/citra-emu/load/mods"
      dir_prep "$texture_packs_folder/Citra" "/var/data/citra-emu/load/textures"
      set_setting_value "$citraconf" "nand_directory" "$saves_folder/n3ds/citra/nand/" "citra" "Data%20Storage"
      set_setting_value "$citraconf" "sdmc_directory" "$saves_folder/n3ds/citra/sdmc/" "citra" "Data%20Storage"
      set_setting_value "$citraconf" "Paths\gamedirs\3\path" "$roms_folder/n3ds" "citra" "UI"
      set_setting_value "$citraconf" "Paths\screenshotPath" "$screenshots_folder" "citra" "UI"
    fi
  fi

  if [[ "$component" =~ ^(dolphin|dolphin-emu|Dolphin|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing DOLPHIN"
      echo "----------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu"
        cp -fvr "$emuconfigs/dolphin/"* "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "BIOS" "$bios_folder" "dolphin" "GBA"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "SavesPath" "$saves_folder/gba" "dolphin" "GBA"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "ISOPath0" "$roms_folder/wii" "dolphin" "General"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "ISOPath1" "$roms_folder/gc" "dolphin" "General"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu/Dolphin.ini" "WiiSDCardPath" "$saves_folder/wii/dolphin/sd.raw" "dolphin" "General"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/dolphin-emu" "/var/config/dolphin-emu"
      else # Single-user actions
        rm -rf /var/config/dolphin-emu
        mkdir -pv /var/config/dolphin-emu/
        cp -fvr "$emuconfigs/dolphin/"* /var/config/dolphin-emu/
        set_setting_value "$dolphinconf" "BIOS" "$bios_folder" "dolphin" "GBA"
        set_setting_value "$dolphinconf" "SavesPath" "$saves_folder/gba" "dolphin" "GBA"
        set_setting_value "$dolphinconf" "ISOPath0" "$roms_folder/wii" "dolphin" "General"
        set_setting_value "$dolphinconf" "ISOPath1" "$roms_folder/gc" "dolphin" "General"
        set_setting_value "$dolphinconf" "WiiSDCardPath" "$saves_folder/wii/dolphin/sd.raw" "dolphin" "General"
      fi
      # Shared actions
      dir_prep "$saves_folder/gc/dolphin/EU" "/var/data/dolphin-emu/GC/EUR" # TODO: Multi-user one-off
      dir_prep "$saves_folder/gc/dolphin/US" "/var/data/dolphin-emu/GC/USA" # TODO: Multi-user one-off
      dir_prep "$saves_folder/gc/dolphin/JP" "/var/data/dolphin-emu/GC/JAP" # TODO: Multi-user one-off
      dir_prep "$screenshots_folder" "/var/data/dolphin-emu/ScreenShots"
      dir_prep "$states_folder/dolphin" "/var/data/dolphin-emu/StateSaves"
      dir_prep "$saves_folder/wii/dolphin" "/var/data/dolphin-emu/Wii"
      dir_prep "$mods_folder/Dolphin" "/var/data/dolphin-emu/Load/GraphicMods"
      dir_prep "$texture_packs_folder/Dolphin" "/var/data/dolphin-emu/Load/Textures"

      # Reset default preset settings
      set_setting_value "$rd_conf" "dolphin" "$(get_setting_value "$rd_defaults" "dolphin" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$saves_folder/gc/dolphin/EU" "/var/data/dolphin-emu/GC/EUR"
      dir_prep "$saves_folder/gc/dolphin/US" "/var/data/dolphin-emu/GC/USA"
      dir_prep "$saves_folder/gc/dolphin/JP" "/var/data/dolphin-emu/GC/JAP"
      dir_prep "$screenshots_folder" "/var/data/dolphin-emu/ScreenShots"
      dir_prep "$states_folder/dolphin" "/var/data/dolphin-emu/StateSaves"
      dir_prep "$saves_folder/wii/dolphin" "/var/data/dolphin-emu/Wii"
      dir_prep "$mods_folder/Dolphin" "/var/data/dolphin-emu/Load/GraphicMods"
      dir_prep "$texture_packs_folder/Dolphin" "/var/data/dolphin-emu/Load/Textures"
      set_setting_value "$dolphinconf" "BIOS" "$bios_folder" "dolphin" "GBA"
      set_setting_value "$dolphinconf" "SavesPath" "$saves_folder/gba" "dolphin" "GBA"
      set_setting_value "$dolphinconf" "ISOPath0" "$roms_folder/wii" "dolphin" "General"
      set_setting_value "$dolphinconf" "ISOPath1" "$roms_folder/gc" "dolphin" "General"
      set_setting_value "$dolphinconf" "WiiSDCardPath" "$saves_folder/wii/dolphin/sd.raw" "dolphin" "General"
    fi
  fi

  if [[ "$component" =~ ^(duckstation|Duckstation|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "------------------------"
      echo "Initializing DUCKSTATION"
      echo "------------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/duckstation"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/data/duckstation/"
        cp -fv "$emuconfigs/duckstation/"* "$multi_user_data_folder/$SteamAppUser/data/duckstation"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "SearchDirectory" "$bios_folder" "duckstation" "BIOS"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "Card1Path" "$saves_folder/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "Card2Path" "$saves_folder/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "Directory" "$saves_folder/psx/duckstation/memcards" "duckstation" "MemoryCards"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/data/duckstation/settings.ini" "RecursivePaths" "$roms_folder/psx" "duckstation" "GameList"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/duckstation" "/var/config/duckstation"
      else # Single-user actions
        rm -rf "/var/config/duckstation"
        mkdir -p "/var/config/duckstation/"
        mkdir -p "$saves_folder/psx/duckstation/memcards"
        cp -fv "$emuconfigs/duckstation/"* /var/config/duckstation
        set_setting_value "$duckstationconf" "SearchDirectory" "$bios_folder" "duckstation" "BIOS"
        set_setting_value "$duckstationconf" "Card1Path" "$saves_folder/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
        set_setting_value "$duckstationconf" "Card2Path" "$saves_folder/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
        set_setting_value "$duckstationconf" "Directory" "$saves_folder/psx/duckstation/memcards" "duckstation" "MemoryCards"
        set_setting_value "$duckstationconf" "RecursivePaths" "$roms_folder/psx" "duckstation" "GameList"
      fi
      # Shared actions
      dir_prep "$states_folder/psx/duckstation" "/var/config/duckstation/savestates" # This is hard-coded in Duckstation, always needed
      dir_prep "$texture_packs_folder/Duckstation" "/var/config/duckstation/textures"

      # Reset default preset settings
      set_setting_value "$rd_conf" "duckstation" "$(get_setting_value "$rd_defaults" "duckstation" "retrodeck" "cheevos")" "retrodeck" "cheevos"
      set_setting_value "$rd_conf" "duckstation" "$(get_setting_value "$rd_defaults" "duckstation" "retrodeck" "cheevos_hardcore")" "retrodeck" "cheevos_hardcore"
      set_setting_value "$rd_conf" "duckstation" "$(get_setting_value "$rd_defaults" "duckstation" "retrodeck" "savestate_auto_save")" "retrodeck" "savestate_auto_save"
      set_setting_value "$rd_conf" "duckstation" "$(get_setting_value "$rd_defaults" "duckstation" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      set_setting_value "$duckstationconf" "SearchDirectory" "$bios_folder" "duckstation" "BIOS"
      set_setting_value "$duckstationconf" "Card1Path" "$saves_folder/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
      set_setting_value "$duckstationconf" "Card2Path" "$saves_folder/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
      set_setting_value "$duckstationconf" "Directory" "$saves_folder/psx/duckstation/memcards" "duckstation" "MemoryCards"
      set_setting_value "$duckstationconf" "RecursivePaths" "$roms_folder/psx" "duckstation" "GameList"
      dir_prep "$states_folder/psx/duckstation" "/var/config/duckstation/savestates" # This is hard-coded in Duckstation, always needed
      dir_prep "$texture_packs_folder/Duckstation" "/var/config/duckstation/textures"
    fi
  fi

  if [[ "$component" =~ ^(melonds|melonDS|MelonDS|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing MELONDS"
      echo "----------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/melonDS"
        mkdir -pv "$multi_user_data_folder/$SteamAppUser/config/melonDS/"
        cp -fvr $emuconfigs/melonds/melonDS.ini "$multi_user_data_folder/$SteamAppUser/config/melonDS/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "BIOS9Path" "$bios_folder/bios9.bin" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "BIOS7Path" "$bios_folder/bios7.bin" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "FirmwarePath" "$bios_folder/firmware.bin" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "SaveFilePath" "$saves_folder/nds/melonds" "melonds"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/melonDS/melonDS.ini" "SavestatePath" "$states_folder/nds/melonds" "melonds"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/melonDS" "/var/config/melonDS"
      else # Single-user actions
        rm -rf /var/config/melonDS
        mkdir -pv /var/config/melonDS/
        cp -fvr $emuconfigs/melonds/melonDS.ini /var/config/melonDS/
        set_setting_value "$melondsconf" "BIOS9Path" "$bios_folder/bios9.bin" "melonds"
        set_setting_value "$melondsconf" "BIOS7Path" "$bios_folder/bios7.bin" "melonds"
        set_setting_value "$melondsconf" "FirmwarePath" "$bios_folder/firmware.bin" "melonds"
        set_setting_value "$melondsconf" "SaveFilePath" "$saves_folder/nds/melonds" "melonds"
        set_setting_value "$melondsconf" "SavestatePath" "$states_folder/nds/melonds" "melonds"
      fi
      # Shared actions
      mkdir -pv "$saves_folder/nds/melonds"
      mkdir -pv "$states_folder/nds/melonds"
      dir_prep "$bios_folder" "/var/config/melonDS/bios"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$bios_folder" "/var/config/melonDS/bios"
      set_setting_value "$melondsconf" "BIOS9Path" "$bios_folder/bios9.bin" "melonds"
      set_setting_value "$melondsconf" "BIOS7Path" "$bios_folder/bios7.bin" "melonds"
      set_setting_value "$melondsconf" "FirmwarePath" "$bios_folder/firmware.bin" "melonds"
      set_setting_value "$melondsconf" "SaveFilePath" "$saves_folder/nds/melonds" "melonds"
      set_setting_value "$melondsconf" "SavestatePath" "$states_folder/nds/melonds" "melonds"
    fi
  fi

  if [[ "$component" =~ ^(pcsx2|PCSX2|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing PCSX2"
      echo "----------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/PCSX2"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis"
        cp -fvr "$emuconfigs/PCSX2/"* "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "Bios" "$bios_folder" "pcsx2" "Folders"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "Snapshots" "$screenshots_folder" "pcsx2" "Folders"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "SaveStates" "$states_folder/ps2/pcsx2" "pcsx2" "Folders"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "MemoryCards" "$saves_folder/ps2/pcsx2/memcards" "pcsx2" "Folders"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/PCSX2/inis/PCSX2.ini" "RecursivePaths" "$roms_folder/ps2" "pcsx2" "GameList"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/PCSX2" "/var/config/PCSX2"
      else # Single-user actions
        rm -rf /var/config/PCSX2
        mkdir -pv "/var/config/PCSX2/inis"
        cp -fvr "$emuconfigs/PCSX2/"* /var/config/PCSX2/inis/
        set_setting_value "$pcsx2conf" "Bios" "$bios_folder" "pcsx2" "Folders"
        set_setting_value "$pcsx2conf" "Snapshots" "$screenshots_folder" "pcsx2" "Folders"
        set_setting_value "$pcsx2conf" "SaveStates" "$states_folder/ps2/pcsx2" "pcsx2" "Folders"
        set_setting_value "$pcsx2conf" "MemoryCards" "$saves_folder/ps2/pcsx2/memcards" "pcsx2" "Folders"
        set_setting_value "$pcsx2conf" "RecursivePaths" "$roms_folder/ps2" "pcsx2" "GameList"
      fi
      # Shared actions
      mkdir -pv "$saves_folder/ps2/pcsx2/memcards"
      mkdir -pv "$states_folder/ps2/pcsx2"
      dir_prep "$texture_packs_folder/PCSX2" "/var/config/PCSX2/textures"

      # Reset default preset settings
      set_setting_value "$rd_conf" "pcsx2" "$(get_setting_value "$rd_defaults" "pcsx2" "retrodeck" "cheevos")" "retrodeck" "cheevos"
      set_setting_value "$rd_conf" "pcsx2" "$(get_setting_value "$rd_defaults" "pcsx2" "retrodeck" "cheevos_hardcore")" "retrodeck" "cheevos_hardcore"
      set_setting_value "$rd_conf" "pcsx2" "$(get_setting_value "$rd_defaults" "pcsx2" "retrodeck" "savestate_auto_save")" "retrodeck" "savestate_auto_save"
      set_setting_value "$rd_conf" "pcsx2" "$(get_setting_value "$rd_defaults" "pcsx2" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      set_setting_value "$pcsx2conf" "Bios" "$bios_folder" "pcsx2" "Folders"
      set_setting_value "$pcsx2conf" "Snapshots" "$screenshots_folder" "pcsx2" "Folders"
      set_setting_value "$pcsx2conf" "SaveStates" "$states_folder/ps2/pcsx2" "pcsx2" "Folders"
      set_setting_value "$pcsx2conf" "MemoryCards" "$saves_folder/ps2/pcsx2/memcards" "pcsx2" "Folders"
      set_setting_value "$pcsx2conf" "RecursivePaths" "$roms_folder/ps2" "pcsx2" "GameList"
      dir_prep "$texture_packs_folder/PCSX2" "/var/config/PCSX2/textures"
    fi
  fi

  if [[ "$component" =~ ^(pico8|pico-8|all)$ ]]; then
    if [[ ("$action" == "reset") || ("$action" == "postmove") ]]; then
      dir_prep "$bios_folder/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
      dir_prep "$roms_folder/pico8" "$bios_folder/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
      dir_prep "$saves_folder/pico-8" "$bios_folder/pico-8/cdata"  # PICO-8 saves folder
      cp -fv "$emuconfigs/pico-8/config.txt" "$bios_folder/pico-8/config.txt"
      cp -fv "$emuconfigs/pico-8/sdl_controllers.txt" "$bios_folder/pico-8/sdl_controllers.txt"
    fi
  fi

  if [[ "$component" =~ ^(ppsspp|PPSSPP|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "------------------------"
      echo "Initializing PPSSPPSDL"
      echo "------------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/ppsspp"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/ppsspp/PSP/SYSTEM/"
        cp -fv "$emuconfigs/ppssppsdl/"* "$multi_user_data_folder/$SteamAppUser/config/ppsspp/PSP/SYSTEM/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/ppsspp/PSP/SYSTEM/ppsspp.ini" "CurrentDirectory" "$roms_folder/psp" "ppsspp" "General"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/ppsspp" "/var/config/ppsspp"
      else # Single-user actions
        rm -rf /var/config/ppsspp
        mkdir -p /var/config/ppsspp/PSP/SYSTEM/
        cp -fv "$emuconfigs/ppssppsdl/"* /var/config/ppsspp/PSP/SYSTEM/
        set_setting_value "$ppssppconf" "CurrentDirectory" "$roms_folder/psp" "ppsspp" "General"
      fi
      # Shared actions
      dir_prep "$saves_folder/PSP/PPSSPP-SA" "/var/config/ppsspp/PSP/SAVEDATA"
      dir_prep "$states_folder/PSP/PPSSPP-SA" "/var/config/ppsspp/PSP/PPSSPP_STATE"
      dir_prep "$texture_packs_folder/PPSSPP" "/var/config/ppsspp/PSP/TEXTURES"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      set_setting_value "$ppssppconf" "CurrentDirectory" "$roms_folder/psp" "ppsspp" "General"
      dir_prep "$saves_folder/PSP/PPSSPP-SA" "/var/config/ppsspp/PSP/SAVEDATA"
      dir_prep "$states_folder/PSP/PPSSPP-SA" "/var/config/ppsspp/PSP/PPSSPP_STATE"
      dir_prep "$texture_packs_folder/PPSSPP" "/var/config/ppsspp/PSP/TEXTURES"
    fi
  fi

  if [[ "$component" =~ ^(primehack|Primehack|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing Primehack"
      echo "----------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/primehack"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/primehack"
        cp -fvr "$emuconfigs/primehack/"* "$multi_user_data_folder/$SteamAppUser/config/primehack/"
        set_setting_value ""$multi_user_data_folder/$SteamAppUser/config/primehack/Dolphin.ini"" "ISOPath0" "$roms_folder/gc" "primehack" "General"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/primehack" "/var/config/primehack"
      else # Single-user actions
        rm -rf /var/config/primehack
        mkdir -pv /var/config/primehack/
        cp -fvr "$emuconfigs/primehack/"* /var/config/primehack/
        set_setting_value "$primehackconf" "ISOPath0" "$roms_folder/gc" "primehack" "General"
      fi
      # Shared actions
      dir_prep "$saves_folder/gc/primehack/EU" "/var/data/primehack/GC/EUR"
      dir_prep "$saves_folder/gc/primehack/US" "/var/data/primehack/GC/USA"
      dir_prep "$saves_folder/gc/primehack/JP" "/var/data/primehack/GC/JAP"
      dir_prep "$screenshots_folder" "/var/data/primehack/ScreenShots"
      dir_prep "$states_folder/primehack" "/var/data/primehack/StateSaves"
      mkdir -pv /var/data/primehack/Wii/
      dir_prep "$saves_folder/wii/primehack" "/var/data/primehack/Wii"
      dir_prep "$mods_folder/Primehack" "/var/data/primehack/Load/GraphicMods"
      dir_prep "$texture_packs_folder/Primehack" "/var/data/primehack/Load/Textures"

      # Reset default preset settings
      set_setting_value "$rd_conf" "primehack" "$(get_setting_value "$rd_defaults" "primehack" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$saves_folder/gc/primehack/EU" "/var/data/primehack/GC/EUR"
      dir_prep "$saves_folder/gc/primehack/US" "/var/data/primehack/GC/USA"
      dir_prep "$saves_folder/gc/primehack/JP" "/var/data/primehack/GC/JAP"
      dir_prep "$screenshots_folder" "/var/data/primehack/ScreenShots"
      dir_prep "$states_folder/primehack" "/var/data/primehack/StateSaves"
      dir_prep "$saves_folder/wii/primehack" "/var/data/primehack/Wii/"
      dir_prep "$mods_folder/Primehack" "/var/data/primehack/Load/GraphicMods"
      dir_prep "$texture_packs_folder/Primehack" "/var/data/primehack/Load/Textures"
      set_setting_value "$primehackconf" "ISOPath0" "$roms_folder/gc" "primehack" "General"
    fi
  fi

  if [[ "$component" =~ ^(rpcs3|RPCS3|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "------------------------"
      echo "Initializing RPCS3"
      echo "------------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/rpcs3"
        mkdir -pv "$multi_user_data_folder/$SteamAppUser/config/rpcs3/"
        cp -fr "$emuconfigs/rpcs3/"* "$multi_user_data_folder/$SteamAppUser/config/rpcs3/"
        # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
        sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_folder/rpcs3/"'^' "$multi_user_data_folder/$SteamAppUser/config/rpcs3/vfs.yml"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/rpcs3/vfs.yml" "/games/" "$roms_folder/ps3/" "rpcs3"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/rpcs3" "/var/config/rpcs3"
      else # Single-user actions
        rm -rf /var/config/rpcs3
        mkdir -pv /var/config/rpcs3/
        cp -fr "$emuconfigs/rpcs3/"* /var/config/rpcs3/
        # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
        sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_folder/rpcs3/"'^' "$rpcs3vfsconf"
        set_setting_value "$rpcs3vfsconf" "/games/" "$roms_folder/ps3/" "rpcs3"
        dir_prep "$saves_folder/ps3/rpcs3" "$bios_folder/rpcs3/dev_hdd0/home/00000001/savedata"
      fi
      # Shared actions
      mkdir -p "$bios_folder/rpcs3/dev_hdd0"
      mkdir -p "$bios_folder/rpcs3/dev_hdd1"
      mkdir -p "$bios_folder/rpcs3/dev_flash"
      mkdir -p "$bios_folder/rpcs3/dev_flash2"
      mkdir -p "$bios_folder/rpcs3/dev_flash3"
      mkdir -p "$bios_folder/rpcs3/dev_bdvd"
      mkdir -p "$bios_folder/rpcs3/dev_usb000"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      # This is an unfortunate one-off because set_setting_value does not currently support settings with $ in the name.
      sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_folder/rpcs3"'^' "$rpcs3vfsconf"
      set_setting_value "$rpcs3vfsconf" "/games/" "$roms_folder/ps3" "rpcs3"
    fi
  fi

  if [[ "$component" =~ ^(ryujunx|Ryujinx|all)$ ]]; then
    # NOTE: for techincal reasons the system folder of Ryujinx IS NOT a sumlink of the bios/switch/keys as not only the keys are located there
    # When RetroDECK starts there is a "manage_ryujinx_keys" function that symlinks the keys only in Rryujinx/system.
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "------------------------"
      echo "Initializing RYUJINX"
      echo "------------------------"
      if [[ $multi_user_mode == "true" ]]; then
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/Ryujinx"
        #mkdir -p "$multi_user_data_folder/$SteamAppUser/config/Ryujinx/system"
        # TODO: add /var/config/Ryujinx/system system folder management
        cp -fv $emuconfigs/ryujinx/* "$multi_user_data_folder/$SteamAppUser/config/Ryujinx"
        sed -i 's#RETRODECKHOMEDIR#'$rdhome'#g' "$multi_user_data_folder/$SteamAppUser/config/Ryujinx/Config.json"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/Ryujinx" "/var/config/Ryujinx"
        # TODO: add nand (saves) folder management
        # TODO: add nand (saves) folder management
        # TODO: add "registered" folder management
      else
        # removing config directory to wipe legacy files
        rm -rf /var/config/Ryujinx
        mkdir -p /var/config/Ryujinx/system
        cp -fv $emuconfigs/ryujinx/* /var/config/Ryujinx
        sed -i 's#RETRODECKHOMEDIR#'$rdhome'#g' "$ryujinxconf"
        # Linking switch nand/saves folder
        rm -rf /var/config/Ryujinx/bis
        dir_prep "$saves_folder/switch/ryujinx/nand" "/var/config/Ryujinx/bis"
        dir_prep "$saves_folder/switch/ryujinx/sdcard" "/var/config/Ryujinx/sdcard"
        dir_prep "$bios_folder/switch/ryujinx/registered" "/var/config/Ryujinx/bis/system/Contents/registered"
      fi
    fi
    # if [[ "$action" == "reset" ]] || [[ "$action" == "postmove" ]]; then # Run commands that apply to both resets and moves
    #   dir_prep "$bios_folder/switch/keys" "/var/config/Ryujinx/system"
    # fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      sed -i 's#RETRODECKHOMEDIR#'$rdhome'#g' "$ryujinxconf" # This is an unfortunate one-off because set_setting_value does not currently support JSON
    fi
  fi

  if [[ "$component" =~ ^(xemu|XEMU|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "------------------------"
      echo "Initializing XEMU"
      echo "------------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf /var/config/xemu
        rm -rf /var/data/xemu
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/xemu"
        mkdir -pv "$multi_user_data_folder/$SteamAppUser/config/xemu/"
        cp -fv $emuconfigs/xemu/xemu.toml "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "screenshot_dir" "'$screenshots_folder'" "xemu" "General"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "bootrom_path" "'$bios_folder/mcpx_1.0.bin'" "xemu" "sys.files"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "flashrom_path" "'$bios_folder/Complex.bin'" "xemu" "sys.files"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "eeprom_path" "'$saves_folder/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/xemu/xemu.toml" "hdd_path" "'$bios_folder/xbox_hdd.qcow2'" "xemu" "sys.files"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/xemu" "/var/config/xemu" # Creating config folder in /var/config for consistentcy and linking back to original location where component will look
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/xemu" "/var/data/xemu/xemu"
      else # Single-user actions
        rm -rf /var/config/xemu
        rm -rf /var/data/xemu
        dir_prep "/var/config/xemu" "/var/data/xemu/xemu" # Creating config folder in /var/config for consistentcy and linking back to original location where component will look
        cp -fv $emuconfigs/xemu/xemu.toml "$xemuconf"
        set_setting_value "$xemuconf" "screenshot_dir" "'$screenshots_folder'" "xemu" "General"
        set_setting_value "$xemuconf" "bootrom_path" "'$bios_folder/mcpx_1.0.bin'" "xemu" "sys.files"
        set_setting_value "$xemuconf" "flashrom_path" "'$bios_folder/Complex.bin'" "xemu" "sys.files"
        set_setting_value "$xemuconf" "eeprom_path" "'$saves_folder/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
        set_setting_value "$xemuconf" "hdd_path" "'$bios_folder/xbox_hdd.qcow2'" "xemu" "sys.files"
      fi # Shared actions
      mkdir -pv $saves_folder/xbox/xemu/
      # Preparing HD dummy Image if the image is not found
      if [ ! -f $bios_folder/xbox_hdd.qcow2 ]
      then
        cp -f "/app/retrodeck/extras/XEMU/xbox_hdd.qcow2" "$bios_folder/xbox_hdd.qcow2"
      fi
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      set_setting_value "$xemuconf" "screenshot_dir" "'$screenshots_folder'" "xemu" "General"
      set_setting_value "$xemuconf" "bootrom_path" "'$bios_folder/mcpx_1.0.bin'" "xemu" "sys.files"
      set_setting_value "$xemuconf" "flashrom_path" "'$bios_folder/Complex.bin'" "xemu" "sys.files"
      set_setting_value "$xemuconf" "eeprom_path" "'$saves_folder/xbox/xemu/xbox-eeprom.bin'" "xemu" "sys.files"
      set_setting_value "$xemuconf" "hdd_path" "'$bios_folder/xbox_hdd.qcow2'" "xemu" "sys.files"
    fi
  fi

  if [[ "$component" =~ ^(yuzu|Yuzu|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing YUZU"
      echo "----------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        rm -rf "$multi_user_data_folder/$SteamAppUser/config/yuzu"
        mkdir -p "$multi_user_data_folder/$SteamAppUser/config/yuzu"
        cp -fvr "$emuconfigs/yuzu/"* "$multi_user_data_folder/$SteamAppUser/config/yuzu/"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "nand_directory" "$saves_folder/switch/yuzu/nand" "yuzu" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "sdmc_directory" "$saves_folder/switch/yuzu/sdmc" "yuzu" "Data%20Storage"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "Paths\gamedirs\4\path" "$roms_folder/switch" "yuzu" "UI"
        set_setting_value "$multi_user_data_folder/$SteamAppUser/config/yuzu/qt-config.ini" "Screenshots\screenshot_path" "$screenshots_folder" "yuzu" "UI"
        dir_prep "$multi_user_data_folder/$SteamAppUser/config/yuzu" "/var/config/yuzu"
      else # Single-user actions
        rm -rf /var/config/yuzu
        mkdir -pv /var/config/yuzu/
        cp -fvr "$emuconfigs/yuzu/"* /var/config/yuzu/
        set_setting_value "$yuzuconf" "nand_directory" "$saves_folder/switch/yuzu/nand" "yuzu" "Data%20Storage"
        set_setting_value "$yuzuconf" "sdmc_directory" "$saves_folder/switch/yuzu/sdmc" "yuzu" "Data%20Storage"
        set_setting_value "$yuzuconf" "Paths\gamedirs\4\path" "$roms_folder/switch" "yuzu" "UI"
        set_setting_value "$yuzuconf" "Screenshots\screenshot_path" "$screenshots_folder" "yuzu" "UI"
      fi
      # Shared actions
      dir_prep "$saves_folder/switch/yuzu/nand" "/var/data/yuzu/nand"
      dir_prep "$saves_folder/switch/yuzu/sdmc" "/var/data/yuzu/sdmc"
      dir_prep "$bios_folder/switch/keys" "/var/data/yuzu/keys"
      dir_prep "$bios_folder/switch/registered" "/var/data/yuzu/nand/system/Contents/registered"
      dir_prep "$logs_folder/yuzu" "/var/data/yuzu/log"
      dir_prep "$screenshots_folder" "/var/data/yuzu/screenshots"
      dir_prep "$mods_folder/Yuzu" "/var/data/yuzu/load"
      mkdir -pv "$rdhome/customs/yuzu"
      # removing dead symlinks as they were present in a past version
      if [ -d $bios_folder/switch ]; then
        find $bios_folder/switch -xtype l -exec rm {} \;
      fi

      # Reset default preset settings
      set_setting_value "$rd_conf" "yuzu" "$(get_setting_value "$rd_defaults" "yuzu" "retrodeck" "abxy_button_swap")" "retrodeck" "abxy_button_swap"
      set_setting_value "$rd_conf" "yuzu" "$(get_setting_value "$rd_defaults" "yuzu" "retrodeck" "ask_to_exit")" "retrodeck" "ask_to_exit"
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$bios_folder/switch/keys" "/var/data/yuzu/keys"
      dir_prep "$bios_folder/switch/registered" "/var/data/yuzu/nand/system/Contents/registered"
      dir_prep "$saves_folder/switch/yuzu/nand" "/var/data/yuzu/nand"
      dir_prep "$saves_folder/switch/yuzu/sdmc" "/var/data/yuzu/sdmc"
      dir_prep "$logs_folder/yuzu" "/var/data/yuzu/log"
      dir_prep "$screenshots_folder" "/var/data/yuzu/screenshots"
      dir_prep "$mods_folder/Yuzu" "/var/data/yuzu/load"
      set_setting_value "$yuzuconf" "nand_directory" "$saves_folder/switch/yuzu/nand" "yuzu" "Data%20Storage"
      set_setting_value "$yuzuconf" "sdmc_directory" "$saves_folder/switch/yuzu/sdmc" "yuzu" "Data%20Storage"
      set_setting_value "$yuzuconf" "Paths\gamedirs\4\path" "$roms_folder/switch" "yuzu" "UI"
      set_setting_value "$yuzuconf" "Screenshots\screenshot_path" "$screenshots_folder" "yuzu" "UI"
    fi
  fi

  if [[ "$component" =~ ^(vita3k|Vita3K|all)$ ]]; then
    if [[ "$action" == "reset" ]]; then # Run reset-only commands
      echo "----------------------"
      echo "Initializing Vita3K"
      echo "----------------------"
      if [[ $multi_user_mode == "true" ]]; then # Multi-user actions
        echo "Figure out what Vita3k needs for multi-user"
      else # Single-user actions
        # NOTE: the component is writing in "." so it must be placed in the rw filesystem. A symlink of the binary is already placed in /app/bin/Vita3K
        rm -rf "/var/data/Vita3K"
        mkdir -p "/var/data/Vita3K/Vita3K"
        cp -fvr "$emuconfigs/vita3k/config.yml" "/var/data/Vita3K" # component config
        cp -fvr "$emuconfigs/vita3k/ux0" "$bios_folder/Vita3K/Vita3K" # User config
        set_setting_value "$vita3kconf" "pref-path" "$rdhome/bios/Vita3K/Vita3K/" "vita3k"
      fi
      # Shared actions
      dir_prep "$saves_folder/psvita/vita3k" "$bios_folder/Vita3K/Vita3K/ux0/user/00/savedata" # Multi-user safe?
    fi
    if [[ "$action" == "postmove" ]]; then # Run only post-move commands
      dir_prep "$saves_folder/psvita/vita3k" "$bios_folder/Vita3K/Vita3K/ux0/user/00/savedata" # Multi-user safe?
      set_setting_value "$vita3kconf" "pref-path" "$rdhome/bios/Vita3K/Vita3K/" "vita3k"
    fi
  fi

  if [[ "$component" =~ ^(mame|MAME|all)$ ]]; then
    # TODO: do a proper script
    # This is just a placeholder script to test the component's flow
    echo "----------------------"
    echo "Initializing MAME"
    echo "----------------------"

    # TODO: probably some of these needs to be put elsewhere
    mkdir -p "$saves_folder/mame-sa"
    mkdir -p "$saves_folder/mame-sa/nvram"
    mkdir -p "$states_folder/mame-sa"
    mkdir -p "$rdhome/screenshots/mame-sa"
    mkdir -p "$saves_folder/mame-sa/diff"

    mkdir -p "/var/config/ctrlr"
    mkdir -p "/var/config/mame/ini"
    mkdir -p "/var/config/mame/cfg"
    mkdir -p "/var/config/mame/inp"

    mkdir -p "/var/data/mame/plugin-data"
    mkdir -p "/var/data/mame/hash"
    mkdir -p "/var/data/mame/assets/samples"
    mkdir -p "/var/data/mame/assets/artwork"
    mkdir -p "/var/data/mame/assets/fonts"
    mkdir -p "/var/data/mame/cheat"
    mkdir -p "/var/data/mame/assets/crosshair"
    mkdir -p "/var/data/mame/plugins"
    mkdir -p "/var/data/mame/assets/language"
    mkdir -p "/var/data/mame/assets/software"
    mkdir -p "/var/data/mame/assets/comments"
    mkdir -p "/var/data/mame/assets/share"
    mkdir -p "/var/data/mame/dats"
    mkdir -p "/var/data/mame/folders"
    mkdir -p "/var/data/mame/assets/cabinets"
    mkdir -p "/var/data/mame/assets/cpanel"
    mkdir -p "/var/data/mame/assets/pcb"
    mkdir -p "/var/data/mame/assets/flyers"
    mkdir -p "/var/data/mame/assets/titles"
    mkdir -p "/var/data/mame/assets/ends"
    mkdir -p "/var/data/mame/assets/marquees"
    mkdir -p "/var/data/mame/assets/artwork-preview"
    mkdir -p "/var/data/mame/assets/bosses"
    mkdir -p "/var/data/mame/assets/logo"
    mkdir -p "/var/data/mame/assets/scores"
    mkdir -p "/var/data/mame/assets/versus"
    mkdir -p "/var/data/mame/assets/gameover"
    mkdir -p "/var/data/mame/assets/howto"
    mkdir -p "/var/data/mame/assets/select"
    mkdir -p "/var/data/mame/assets/icons"
    mkdir -p "/var/data/mame/assets/covers"
    mkdir -p "/var/data/mame/assets/ui"

    dir_prep "$saves_folder/mame-sa/hiscore" "/var/config/mame/hiscore"
    cp -fvr "$emuconfigs/mame/mame.ini" "$mameconf"
    cp -fvr "$emuconfigs/mame/ui.ini" "$mameuiconf"
    cp -fvr "$emuconfigs/mame/default.cfg" "$mamedefconf"

    sed -i 's#RETRODECKROMSDIR#'$roms_folder'#g' "$mameconf" # one-off as roms folders are a lot
    set_setting_value "$mameconf" "nvram_directory" "$saves_folder/mame-sa/nvram" "mame"
    set_setting_value "$mameconf" "state_directory" "$states_folder/mame-sa" "mame"
    set_setting_value "$mameconf" "snapshot_directory" "$screenshots_folder/mame-sa" "mame"
    set_setting_value "$mameconf" "diff_directory" "$saves_folder/mame-sa/diff" "mame"

  fi

  if [[ "$component" =~ ^(gzdoom|GZDOOM|all)$ ]]; then
    # TODO: do a proper script
    # This is just a placeholder script to test the component's flow
    echo "----------------------"
    echo "Initializing GZDOOM"
    echo "----------------------"

    mkdir -p "/var/config/gzdoom"
    mkdir -p "/var/data/gzdoom"
    cp -fvr "$emuconfigs/gzdoom/gzdoom.ini" "/var/config/gzdoom"
    cp -fvr "$emuconfigs/gzdoom/gzdoom.pk3" "/var/data/gzdoom"

    sed -i 's#RETRODECKROMSDIR#'$roms_folder'#g' "/var/config/gzdoom/gzdoom.ini" # This is an unfortunate one-off because set_setting_value does not currently support JSON
    sed -i 's#RETRODECKSAVESDIR#'$saves_folder'#g' "/var/config/gzdoom/gzdoom.ini" # This is an unfortunate one-off because set_setting_value does not currently support JSON
  fi

  if [[ "$component" =~ ^(boilr|BOILR|all)$ ]]; then
    echo "----------------------"
    echo "Initializing BOILR"
    echo "----------------------"

    mkdir -p "/var/config/boilr"
    cp -fvr "/app/libexec/steam-sync/config.toml" "/var/config/boilr"
    
  fi

  # Update presets for all components after any reset or move
  if [[ ! "$component" == "retrodeck" ]]; then
    build_retrodeck_current_presets
  fi
}
