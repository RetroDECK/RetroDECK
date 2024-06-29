#!/bin/bash

post_update() {

  # post update script
  log i "Executing post-update script"

  if [[ $(check_version_is_older_than "0.5.0b") == "true" ]]; then # If updating from prior to save sorting change at 0.5.0b
    save_migration
  fi

  # Everything within the following ( <code> ) will happen behind the Zenity dialog. The save migration was a long process so it has its own individual dialogs.

  (
  if [[ $(check_version_is_older_than "0.6.2b") == "true" ]]; then
    # In version 0.6.2b, the following changes were made that required config file updates/reset:
    # - Primehack preconfiguration completely redone. "Stop emulation" hotkey set to Start+Select, Xbox and Nintendo keymap profiles were created, Xbox set as default.
    # - Duckstation save and state locations were dir_prep'd to the rdhome/save and /state folders, which was not previously done. Much safer now!
    # - Fix PICO-8 folder structure. ROM and save folders are now sane and binary files will go into ~/retrodeck/bios/pico-8/

    rm -rf /var/config/primehack # Purge old Primehack config files. Saves are safe as they are linked into /var/data/primehack.
    prepare_component "reset" "primehack"

    dir_prep "$rdhome/saves/duckstation" "/var/data/duckstation/memcards"
    dir_prep "$rdhome/states/duckstation" "/var/data/duckstation/savestates"

    mv "$bios_folder/pico8" "$bios_folder/pico8_olddata" # Move legacy (and incorrect / non-functional ) PICO-8 location for future cleanup / less confusion
    dir_prep "$bios_folder/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
    dir_prep "$roms_folder/pico8" "$bios_folder/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
    dir_prep "$bios_folder/pico-8/cdata" "$saves_folder/pico-8" # PICO-8 saves folder
  fi
  if [[ $(check_version_is_older_than "0.6.3b") == "true" ]]; then
    # In version 0.6.3b, the following changes were made that required config file updates/reset:
    # - Put Dolphin and Primehack save states in different folders inside $rd_home/states
    # - Fix symlink to hard-coded PICO-8 config folder (dir_prep doesn't like ~)
    # - Overwrite Citra and Yuzu configs, as controller mapping was broken due to emulator updates.

    dir_prep "$rdhome/states/dolphin" "/var/data/dolphin-emu/StateSaves"
    dir_prep "$rdhome/states/primehack" "/var/data/primehack/StateSaves"

    rm -rf "$HOME/~/" # Remove old incorrect location from 0.6.2b
    rm -f "$HOME/.lexaloffle/pico-8" # Remove old symlink to prevent recursion
    dir_prep "$bios_folder/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
    dir_prep "$saves_folder/pico-8" "$bios_folder/pico-8/cdata" # PICO-8 saves folder structure was backwards, fixing for consistency.

    cp -f "$emuconfigs/citra/qt-config.ini" /var/config/citra-emu/qt-config.ini
    sed -i 's#RETRODECKHOMEDIR#'$rdhome'#g' /var/config/citra-emu/qt-config.ini
    cp -fr "$emuconfigs/yuzu/"* /var/config/yuzu/
    sed -i 's#RETRODECKHOMEDIR#'$rdhome'#g' /var/config/yuzu/qt-config.ini

    # Remove unneeded tools folder, as location has changed to RO space
    rm -rfv /var/config/retrodeck/tools/
  fi
  if [[ $(check_version_is_older_than "0.6.4b") == "true" ]]; then
    # In version 0.6.4b, the following changes were made:
    # Changed settings in Primehack: The audio output was not selected by default, default AR was also incorrect.
    # Changed settings in Duckstation and PCSX2: The "ask on exit" was disabled and "save on exit" was enabled.
    # The default configs have been updated for new installs and resets, a patch was created to address existing installs.

    deploy_multi_patch "emu-configs/patches/updates/064b_update.patch"
  fi
  if [[ $(check_version_is_older_than "0.6.5b") == "true" ]]; then
    # In version 0.6.5b, the following changes were made:
    # Change Yuzu GPU accuracy to normal for better performance

    set_setting_value $yuzuconf "gpu_accuracy" "0" "yuzu" "Renderer"
  fi
  if [[ $(check_version_is_older_than "0.7.0b") == "true" ]]; then
    # In version 0.7.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Update retrodeck.cfg and set new paths to $rdhome by default
    # - Update PCSX2 and Duckstation configs to latest templates (to accomadate RetroAchievements feature) and move Duckstation config folder from /var/data to /var/config
    # - New ~/retrodeck/mods and ~/retrodeck/texture_packs directories are added and symlinked to multiple different emulators (where supported)
    # - Expose ES-DE gamelists folder to user at ~/retrodeck/gamelists
    # - Copy new borders into RA config location
    # - Copy new RetroArch control remaps into RA config location
    # - Add shipped Amiga bios if it doesn't already exist
    # - Update RPCS3 vfs file contents. migrate from old location if needed
    # - Disable ESDE update checks for existing installs
    # - Move Duckstation saves and states to new locations
    # - Clean up legacy tools files (Configurator is now accessible through the main ES-DE menu)
    # - Move Dolphin and Primehack save folder names
    # - Move PPSSPP saves/states to appropriate folders
    # - Set ESDE user themes folder directly
    # - Disable auto-save/load in existing RA / PCSX2 / Duckstation installs for proper preset functionality
    # - Disable ask-on-exit in existing Citra / Dolphin / Duckstation / Primehack installs for proper preset functionality
    # - Disable auto-load-state in existing PPSSPP installs for proper preset functionality
    # - Init Cemu as it is a new emulator
    # - Init PICO-8 as it has newly-shipped config files

    update_rd_conf # Expand retrodeck.cfg to latest template
    set_setting_value $rd_conf "screenshots_folder" "$rdhome/screenshots"
    set_setting_value $rd_conf "mods_folder" "$rdhome/mods"
    set_setting_value $rd_conf "texture_packs_folder" "$rdhome/texture_packs"
    set_setting_value $rd_conf "borders_folder" "$rdhome/borders"
    conf_read

    mv -f "$pcsx2conf" "$pcsx2conf.bak"
    generate_single_patch "$emuconfigs/PCSX2/PCSX2.ini" "$pcsx2conf.bak" "/var/config/PCSX2/inis/PCSX2-cheevos-upgrade.patch" pcsx2
    deploy_single_patch "$emuconfigs/PCSX2/PCSX2.ini" "/var/config/PCSX2/inis/PCSX2-cheevos-upgrade.patch" "$pcsx2conf"
    rm -f "/var/config/PCSX2/inis/PCSX2-cheevos-upgrade.patch"
    dir_prep "/var/config/duckstation" "/var/data/duckstation"
    mv -f "$duckstationconf" "$duckstationconf.bak"
    generate_single_patch "$emuconfigs/duckstation/settings.ini" "$duckstationconf.bak" "/var/config/duckstation/duckstation-cheevos-upgrade.patch" pcsx2
    deploy_single_patch "$emuconfigs/duckstation/settings.ini" "/var/config/duckstation/duckstation-cheevos-upgrade.patch" "$duckstationconf"
    rm -f "/var/config/duckstation/duckstation-cheevos-upgrade.patch"

    create_dir "$mods_folder"
    create_dir "$texture_packs_folder"
    create_dir "$borders_folder"

    dir_prep "$mods_folder/Primehack" "/var/data/primehack/Load/GraphicMods"
    dir_prep "$texture_packs_folder/Primehack" "/var/data/primehack/Load/Textures"
    dir_prep "$mods_folder/Dolphin" "/var/data/dolphin-emu/Load/GraphicMods"
    dir_prep "$texture_packs_folder/Dolphin" "/var/data/dolphin-emu/Load/Textures"
    dir_prep "$mods_folder/Citra" "/var/data/citra-emu/load/mods"
    dir_prep "$texture_packs_folder/Citra" "/var/data/citra-emu/load/textures"
    dir_prep "$mods_folder/Yuzu" "/var/data/yuzu/load"
    dir_prep "$texture_packs_folder/RetroArch-Mesen" "/var/config/retroarch/system/HdPacks"
    dir_prep "$texture_packs_folder/PPSSPP" "/var/config/ppsspp/PSP/TEXTURES"
    dir_prep "$texture_packs_folder/PCSX2" "/var/config/PCSX2/textures"
    dir_prep "$texture_packs_folder/RetroArch-Mupen64Plus/cache" "/var/config/retroarch/system/Mupen64plus/cache"
    dir_prep "$texture_packs_folder/RetroArch-Mupen64Plus/hires_texture" "/var/config/retroarch/system/Mupen64plus/hires_texture"
    dir_prep "$texture_packs_folder/Duckstation" "/var/config/duckstation/textures"

    dir_prep "$rdhome/gamelists" "/var/config/emulationstation/ES-DE/gamelists"

    dir_prep "$borders_folder" "/var/config/retroarch/overlays/borders"
    rsync -rlD --mkpath "/app/retrodeck/emu-configs/retroarch/borders/" "/var/config/retroarch/overlays/borders/"

    rsync -rlD --mkpath "$emuconfigs/defaults/retrodeck/presets/remaps/" "/var/config/retroarch/config/remaps/"

    if [[ ! -f "$bios_folder/capsimg.so" ]]; then
      cp -f "/app/retrodeck/extras/Amiga/capsimg.so" "$bios_folder/capsimg.so"
    fi

    cp -f $emuconfigs/rpcs3/vfs.yml /var/config/rpcs3/vfs.yml
    sed -i 's^\^$(EmulatorDir): .*^$(EmulatorDir): '"$bios_folder/rpcs3/"'^' "$rpcs3vfsconf"
    set_setting_value "$rpcs3vfsconf" "/games/" "$roms_folder/ps3/" "rpcs3"
    if [[ -d "$roms_folder/ps3/emudir" ]]; then # The old location exists, meaning the emulator was run at least once.
      mkdir "$bios_folder/rpcs3"
      mv "$roms_folder/ps3/emudir/"* "$bios_folder/rpcs3/"
      rm "$roms_folder/ps3/emudir"
      configurator_generic_dialog "RetroDECK 0.7.0b Upgrade" "As part of this update and due to a RPCS3 config upgrade, the files that used to exist at\n\n~/retrodeck/roms/ps3/emudir\n\nare now located at\n\n~/retrodeck/bios/rpcs3.\nYour existing files have been moved automatically."
    fi
    create_dir "$bios_folder/rpcs3/dev_hdd0"
    create_dir "$bios_folder/rpcs3/dev_hdd1"
    create_dir "$bios_folder/rpcs3/dev_flash"
    create_dir "$bios_folder/rpcs3/dev_flash2"
    create_dir "$bios_folder/rpcs3/dev_flash3"
    create_dir "$bios_folder/rpcs3/dev_bdvd"
    create_dir "$bios_folder/rpcs3/dev_usb000"
    dir_prep "$bios_folder/rpcs3/dev_hdd0/home/00000001/savedata" "$saves_folder/ps3/rpcs3"

    set_setting_value $es_settings "ApplicationUpdaterFrequency" "never" "es_settings"

    if [[ -f "$saves_folder/duckstation/shared_card_1.mcd" || -f "$saves_folder/duckstation/shared_card_2.mcd" ]]; then
      configurator_generic_dialog "RetroDECK 0.7.0b Upgrade" "As part of this update, the location of saves and states for Duckstation has been changed.\n\nYour files will be moved automatically, and can now be found at\n\n~.../saves/psx/duckstation/memcards/\nand\n~.../states/psx/duckstation/"
    fi
    create_dir "$saves_folder/psx/duckstation/memcards"
    mv "$saves_folder/duckstation/"* "$saves_folder/psx/duckstation/memcards/"
    rmdir "$saves_folder/duckstation" # File-safe folder cleanup
    unlink "/var/config/duckstation/memcards"
    set_setting_value "$duckstationconf" "Card1Path" "$saves_folder/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
    set_setting_value "$duckstationconf" "Card2Path" "$saves_folder/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
    set_setting_value "$duckstationconf" "Directory" "$saves_folder/psx/duckstation/memcards" "duckstation" "MemoryCards"
    set_setting_value "$duckstationconf" "RecursivePaths" "$roms_folder/psx" "duckstation" "GameList"
    create_dir "$states_folder/psx"
    mv -t "$states_folder/psx/" "$states_folder/duckstation"
    unlink "/var/config/duckstation/savestates"
    dir_prep "$states_folder/psx/duckstation" "/var/config/duckstation/savestates"

    rm -rf /var/config/retrodeck/tools
    rm -rf /var/config/emulationstation/ES-DE/gamelists/tools/

    mv "$saves_folder/gc/dolphin/EUR" "$saves_folder/gc/dolphin/EU"
    mv "$saves_folder/gc/dolphin/USA" "$saves_folder/gc/dolphin/US"
    mv "$saves_folder/gc/dolphin/JAP" "$saves_folder/gc/dolphin/JP"
    dir_prep "$saves_folder/gc/dolphin/EU" "/var/data/dolphin-emu/GC/EUR"
    dir_prep "$saves_folder/gc/dolphin/US" "/var/data/dolphin-emu/GC/USA"
    dir_prep "$saves_folder/gc/dolphin/JP" "/var/data/dolphin-emu/GC/JAP"
    mv "$saves_folder/gc/primehack/EUR" "$saves_folder/gc/primehack/EU"
    mv "$saves_folder/gc/primehack/USA" "$saves_folder/gc/primehack/US"
    mv "$saves_folder/gc/primehack/JAP" "$saves_folder/gc/primehack/JP"
    dir_prep "$saves_folder/gc/primehack/EU" "/var/data/primehack/GC/EUR"
    dir_prep "$saves_folder/gc/primehack/US" "/var/data/primehack/GC/USA"
    dir_prep "$saves_folder/gc/primehack/JP" "/var/data/primehack/GC/JAP"

    dir_prep "$saves_folder/PSP/PPSSPP-SA" "/var/config/ppsspp/PSP/SAVEDATA"
    dir_prep "$states_folder/PSP/PPSSPP-SA" "/var/config/ppsspp/PSP/PPSSPP_STATE"

    set_setting_value "$es_settings" "ROMDirectory" "$roms_folder" "es_settings"
    set_setting_value "$es_settings" "MediaDirectory" "$media_folder" "es_settings"
    sed -i '$ a <string name="UserThemeDirectory" value="" />' "$es_settings" # Add new default line to existing file
    set_setting_value "$es_settings" "UserThemeDirectory" "$themes_folder" "es_settings"
    unlink "/var/config/emulationstation/ROMs"
    unlink "/var/config/emulationstation/ES-DE/downloaded_media"
    unlink "/var/config/emulationstation/ES-DE/themes"

    set_setting_value "$raconf" "savestate_auto_load" "false" "retroarch"
    set_setting_value "$raconf" "savestate_auto_save" "false" "retroarch"
    set_setting_value "$pcsx2conf" "SaveStateOnShutdown" "false" "pcsx2" "EmuCore"
    set_setting_value "$duckstationconf" "SaveStateOnExit" "false" "duckstation" "Main"
    set_setting_value "$duckstationconf" "Enabled" "false" "duckstation" "Cheevos"

    set_setting_value "$citraconf" "confirmClose" "false" "citra" "UI"
    set_setting_value "$citraconf" "confirmClose\default" "false" "citra" "UI"
    set_setting_value "$dolphinconf" "ConfirmStop" "False" "dolphin" "Interface"
    set_setting_value "$duckstationconf" "ConfirmPowerOff" "false" "duckstation" "Main"
    set_setting_value "$primehackconf" "ConfirmStop" "False" "primehack" "Interface"

    set_setting_value "$ppssppconf" "AutoLoadSaveState" "0" "ppsspp" "General"

    prepare_component "reset" "cemu"

    prepare_component "reset" "pico8"

    configurator_generic_dialog "RetroDECK 0.7.0b Upgrade" "Would you like to install the official controller profile?\n(this will reset your custom emulator settings)\n\nAfter installation you can enable it from from Controller Settings -> Templates."
    if [[ $(configurator_generic_question_dialog "RetroDECK Official Controller Profile" "Would you like to install the official RetroDECK controller profile?") == "true" ]]; then
      install_retrodeck_controller_profile
      prepare_component "reset" "all"
    fi
  fi
  if [[ $(check_version_is_older_than "0.7.1b") == "true" ]]; then
    # In version 0.7.1b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Force update PPSSPP standalone keybinds for L/R.
    set_setting_value "$ppssppcontrolsconf" "L" "1-45,10-193" "ppsspp" "ControlMapping"
    set_setting_value "$ppssppcontrolsconf" "R" "1-51,10-192" "ppsspp" "ControlMapping"
  fi

  if [[ $(check_version_is_older_than "0.7.3b") == "true" ]]; then
    # In version 0.7.3b, there was a bug that prevented the correct creations of the roms/system folders, so we force recreate them.
    emulationstation --home /var/config/emulationstation --create-system-dirs
  fi

  if [[ $(check_version_is_older_than "0.8.0b") == "true" ]]; then
    log i "In version 0.8.0b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
    log i "- Remove RetroDECK controller profile from existing template location"
    log i "- Change section name in retrodeck.cfg for ABXY button swap preset"
    log i "- Force disable global rewind in RA in prep for preset system"
    log i "- The following components are been added and need to be initialized: es-de 3.0, MAME-SA, Vita3K, GZDoom"


    # Removing old controller configs
    local controller_configs_path="$HOME/.steam/steam/controller_base/templates"
    local controller_configs=(
      "$controller_configs_path/RetroDECK_controller_config.vdf"
      "$controller_configs_path/RetroDECK_controller_generic_standard.vdf"
      "$controller_configs_path/RetroDECK_controller_ps3_dualshock3.vdf"
      "$controller_configs_path/RetroDECK_controller_ps4_dualshock4.vdf"
      "$controller_configs_path/RetroDECK_controller_ps5_dualsense.vdf"
      "$controller_configs_path/RetroDECK_controller_steam_controller_gordon.vdf"
      "$controller_configs_path/RetroDECK_controller_neptune.vdf"
      "$controller_configs_path/RetroDECK_controller_switch_pro.vdf"
      "$controller_configs_path/RetroDECK_controller_xbox360.vdf"
      "$controller_configs_path/RetroDECK_controller_xboxone.vdf"
    )

    for this_vdf in "${controller_configs[@]}"; do
        if [[ -f "$this_vdf" ]]; then
            log d "Found an old Steam Controller profile, removing it: \"$this_vdf\""
            rm -f "$this_vdf"
        fi
    done

    log d "Renaming \"nintendo_button_layout\" into \"abxy_button_swap\" in the retrodeck config file: \"$rd_conf\""
    sed -i 's^nintendo_button_layout^abxy_button_swap^' "$rd_conf" # This is a one-off sed statement as there are no functions for replacing section names
    log i "Force disabling rewind, you can re-enable it via the Configurator"
    set_setting_value "$raconf" "rewind_enable" "false" "retroarch"

    # in 3.0 .emulationstation was moved into ES-DE
    log i "Renaming old \"/var/config/emulationstation\" folder as \"/var/config/ES-DE\""
    mv -f /var/config/emulationstation /var/config/ES-DE

    prepare_component "reset" "es-de"
    prepare_component "reset" "mame"
    prepare_component "reset" "vita3k"
    prepare_component "reset" "gzdoom"

    if [ -d "$rdhome/.logs" ]; then
      mv "$rdhome/.logs" "$logs_folder"
      log i "Old log folder \"$rdhome/.logs\" found. Renamed it as \"$logs_folder\""
    fi

    # The save folder of rpcs3 was inverted so we're moving the saves into the real one
    log i "RPCS3 saves needs to be migrated, executing."
    if [[ "$(ls -A $bios_folder/rpcs3/dev_hdd0/home/00000001/savedata)" ]]; then
      log i "Existing RPCS3 savedata found, backing up..."
      create_dir "$backups_folder"
      zip -rq9 "$backups_folder/$(date +"%0m%0d")_rpcs3_save_data.zip" "$bios_folder/rpcs3/dev_hdd0/home/00000001/savedata"
    fi
    dir_prep "$saves_folder/ps3/rpcs3" "$bios_folder/rpcs3/dev_hdd0/home/00000001/savedata"
    log i "RPCS3 saves migration completed, a backup was made here: \"$backups_folder/$(date +"%0m%0d")_rpcs3_save_data.zip\"."

    log i "Switch firmware folder should be moved in \"$bios_folder/switch/firmware\" from \"$bios_folder/switch/registered\""
    mv "$bios_folder/switch/registered" "$bios_folder/switch/firmware"

    log i "New systems were added in this version, regenerating system folders."
    #es-de --home "/var/config/" --create-system-dirs
    es-de --create-system-dirs

  fi

  if [[ $(check_version_is_older_than "0.8.1b") == "true" ]]; then
    log i "In version 0.8.1b, the following changes were made that required config file updates/reset or other changes to the filesystem:"
    log i "- ES-DE files were moved inside the retrodeck folder, migrating to the new structure"
    log i "- Give the user the option to reset Ryujinx, which was not properly initialized in 0.8.0b"
    
    log d "ES-DE files were moved inside the retrodeck folder, migrating to the new structure"
    dir_prep "$rdhome/ES-DE/collections" "/var/config/ES-DE/collections"
    dir_prep "$rdhome/ES-DE/gamelists" "/var/config/ES-DE/gamelists"
    log i "Moving ES-DE collections, downloaded_media, gamelist, and themes from \"$rdhome\" to \"$rdhome/ES-DE\""
    set_setting_value "$es_settings" "MediaDirectory" "$rdhome/ES-DE/downloaded_media" "es_settings"
    set_setting_value "$es_settings" "UserThemeDirectory" "$rdhome/ES-DE/themes" "es_settings"
    mv -f "$rdhome/themes" "$rdhome/ES-DE/themes" && log d "Move of \"$rdhome/themes\" completed"
    mv -f "$rdhome/downloaded_media" "$rdhome/ES-DE/downloaded_media" && log d "Move of \"$rdhome/downloaded_media\" completed"
    mv -f "$rdhome/gamelists/"* "$rdhome/ES-DE/gamelists" && log d "Move of \"$rdhome/gamelists/\" completed" && rm -rf "$rdhome/gamelists"

    log i "MAME-SA, migrating samples to the new exposed folder: from \"/var/data/mame/assets/samples\" to \"$bios_folder/mame-sa/samples\""
    create_dir "$bios_folder/mame-sa/samples"
    mv -f "/var/data/mame/assets/samples/"* "$bios_folder/mame-sa/samples"
    set_setting_value "$mameconf" "samplepath" "$bios_folder/mame-sa/samples" "mame"

    log i "Installing the missing ScummVM assets and renaming \"$mods_folder/RetroArch/ScummVM/themes\" into \"theme\""
    mv -f "$mods_folder/RetroArch/ScummVM/themes" "$mods_folder/RetroArch/ScummVM/theme"
    unzip -o "$emuconfigs/retroarch/ScummVM.zip" 'scummvm/extra/*' -d /tmp
    unzip -o "$emuconfigs/retroarch/ScummVM.zip" 'scummvm/theme/*' -d /tmp
    mv -f /tmp/scummvm/extra "$mods_folder/RetroArch/ScummVM"
    mv -f /tmp/scummvm/theme "$mods_folder/RetroArch/ScummVM"
    rm -rf /tmp/extra /tmp/theme

    log i "Placing cheats in \"/var/data/mame/cheat\""
    unzip -j -o "$emuconfigs/mame/cheat0264.zip" 'cheat.7z' -d "/var/data/mame/cheat"

    log d "Verifying with user if they want to reset Ryujinx"
    if [[ "$(configurator_generic_question_dialog "RetroDECK 0.8.1b Ryujinx Reset" "In RetroDECK 0.8.0b the Ryujinx emulator was not properly initialized for upgrading users.\nThis would cause Ryujinx to not work properly.\n\nWould you like to reset Ryujinx to default RetroDECK settings now?\n\nIf you have made your own changes to the Ryujinx config, you can decline this reset.")" == "true" ]]; then
      log d "User agreed to Ryujinx reset"
      prepare_component "reset" "ryujinx"
    fi
  fi

  if [[ $(check_version_is_older_than "0.8.2b") == "true" ]]; then
      log i "Vita3K changed some paths, reflecting them: moving \"/var/data/Vita3K\" in \"/var/config/Vita3K\""
      mv -f "/var/data/Vita3K" "/var/config/Vita3K"
      log i "Moving ES-DE downloaded_media, gamelist, and themes from \"$rdhome\" to \"$rdhome/ES-DE\" due to a RetroDECK Framework bug"
      mv -f "$rdhome/themes" "$rdhome/ES-DE/themes" && log d "Move of \"$rdhome/themes\" completed"
      mv -f "$rdhome/downloaded_media" "$rdhome/ES-DE/downloaded_media" && log d "Move of \"$rdhome/downloaded_media\" completed"
      mv -f "$rdhome/gamelists/"* "$rdhome/ES-DE/gamelists" && log d "Move of \"$rdhome/gamelists/\" completed" && rm -rf "$rdhome/gamelists"
  fi

  # if [[ $(check_version_is_older_than "0.9.0b") == "true" ]]; then
  #   # Placeholder for version 0.9.0b
  #   rm /var/config/emulationstation/.emulationstation # remving the old symlink to .emulationstation as it might be not needed anymore
  # TODO: change <mlc_path>RETRODECKHOMEDIR/bios/cemu</mlc_path> in emu-configs/cemu/settings.xml into <mlc_path>RETRODECKHOMEDIR/bios/cemu/mlc</mlc_path>
  #   if [ ! -d "$bios_folder/cemu/mlc" ]; then
  #     log i "Cemu MLC folder was moved from \"$bios_folder/cemu\" to \"$bios_folder/cemu/mlc\", migrating it"
  #     mv -f "$bios_folder/cemu" "$bios_folder/cemu/mlc"
  #     # TODO: set setting value mlc_path in settings.xml (check prepare script)
  #   fi
  #   if [ -f "/var/data/Cemu/keys.txt" ]; then
  #     log AND ZENITY "Found Cemu keys.txt" in "/var/data/Cemu/keys.txt", for a better compatibility is better to move it into "$bios_folder/cemu/mlc/keys.txt, do you want to continue?
  #     if yes: mv "/var/data/Cemu/keys.txt" "$bios_folder/cemu/mlc/keys.txt"
  #     ln -s "$bios_folder/cemu/mlc/keys.txt" "/var/data/Cemu/keys.txt" <--- AND THIS SHOULD BE EVEN PUT IN THE PREPARATION SCRIPT
  #   fi 
  # fi

  # The following commands are run every time.

  if [[ -d "/var/data/dolphin-emu/Load/DynamicInputTextures" ]]; then # Refresh installed textures if they have been enabled
    rsync -rlD --mkpath "/app/retrodeck/extras/DynamicInputTextures/" "/var/data/dolphin-emu/Load/DynamicInputTextures/"
  fi
  if [[ -d "/var/data/primehack/Load/DynamicInputTextures" ]]; then # Refresh installed textures if they have been enabled
    rsync -rlD --mkpath "/app/retrodeck/extras/DynamicInputTextures/" "/var/data/primehack/Load/DynamicInputTextures/"
  fi

  if [[ ! -z $(find "$HOME/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") || ! -z $(find "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/controller_base/templates/" -maxdepth 1 -type f -iname "RetroDECK*.vdf") ]]; then # If RetroDECK controller profile has been previously installed
    install_retrodeck_controller_profile
  fi

  update_splashscreens
  deploy_helper_files
  build_retrodeck_current_presets
  ) |
  rd_zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK - Upgrade Process" \
  --width=400 --height=200 \
  --text="RetroDECK is finishing up the upgrading process, please be patient.\n\n<span foreground='$purple' size='larger'><b>NOTICE - If the process is taking too long:</b></span>\n\nSome windows might be running in the background that could require your attention: pop-ups from emulators or the upgrade itself that needs user input to continue.\n\n"

  version=$hard_version
  conf_write

  if grep -qF "cooker" <<< $hard_version; then
    changelog_dialog "$(echo $version | cut -d'-' -f2)"
  else
    changelog_dialog "$version"
  fi
}
