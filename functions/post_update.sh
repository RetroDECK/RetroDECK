#!/bin/bash

post_update() {

  # post update script
  echo "Executing post-update script"

  local prev_version=$(sed -e 's/[\.a-z]//g' <<< $version)

  if [[ $prev_version -le "050" ]]; then # If updating from prior to save sorting change at 0.5.0b
    save_migration
  fi

  # Everything within the following ( <code> ) will happen behind the Zenity dialog. The save migration was a long process so it has its own individual dialogs.

  (
  if [[ $prev_version -le "062" ]]; then
    # In version 0.6.2b, the following changes were made that required config file updates/reset:
    # - Primehack preconfiguration completely redone. "Stop emulation" hotkey set to Start+Select, Xbox and Nintendo keymap profiles were created, Xbox set as default.
    # - Duckstation save and state locations were dir_prep'd to the rdhome/save and /state folders, which was not previously done. Much safer now!
    # - Fix PICO-8 folder structure. ROM and save folders are now sane and binary files will go into ~/retrodeck/bios/pico-8/

    rm -rf /var/config/primehack # Purge old Primehack config files. Saves are safe as they are linked into /var/data/primehack.
    prepare_emulator "reset" "primehack"

    dir_prep "$rdhome/saves/duckstation" "/var/data/duckstation/memcards"
    dir_prep "$rdhome/states/duckstation" "/var/data/duckstation/savestates"

    mv "$bios_folder/pico8" "$bios_folder/pico8_olddata" # Move legacy (and incorrect / non-functional ) PICO-8 location for future cleanup / less confusion
    dir_prep "$bios_folder/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
    dir_prep "$roms_folder/pico8" "$bios_folder/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
    dir_prep "$bios_folder/pico-8/cdata" "$saves_folder/pico-8" # PICO-8 saves folder
  fi
  if [[ $prev_version -le "063" ]]; then
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
  if [[ $prev_version -le "064" ]]; then
    # In version 0.6.4b, the following changes were made:
    # Changed settings in Primehack: The audio output was not selected by default, default AR was also incorrect.
    # Changed settings in Duckstation and PCSX2: The "ask on exit" was disabled and "save on exit" was enabled.
    # The default configs have been updated for new installs and resets, a patch was created to address existing installs.

    deploy_multi_patch "emu-configs/patches/updates/064b_update.patch"
  fi
  if [[ $prev_version -le "065" ]]; then
    # In version 0.6.5b, the following changes were made:
    # Change Yuzu GPU accuracy to normal for better performance

    set_setting_value $yuzuconf "gpu_accuracy" "0" "yuzu" "Renderer"
  fi
  if [[ $prev_version -le "070" ]]; then
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

    mkdir -p "$mods_folder"
    mkdir -p "$texture_packs_folder"
    mkdir -p "$borders_folder"

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

    dir_prep "$rdhome/gamelists" "/var/config/emulationstation/.emulationstation/gamelists"

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
    mkdir -p "$bios_folder/rpcs3/dev_hdd0"
    mkdir -p "$bios_folder/rpcs3/dev_hdd1"
    mkdir -p "$bios_folder/rpcs3/dev_flash"
    mkdir -p "$bios_folder/rpcs3/dev_flash2"
    mkdir -p "$bios_folder/rpcs3/dev_flash3"
    mkdir -p "$bios_folder/rpcs3/dev_bdvd"
    mkdir -p "$bios_folder/rpcs3/dev_usb000"
    dir_prep "$bios_folder/rpcs3/dev_hdd0/home/00000001/savedata" "$saves_folder/ps3/rpcs3"

    set_setting_value $es_settings "ApplicationUpdaterFrequency" "never" "es_settings"

    if [[ -f "$saves_folder/duckstation/shared_card_1.mcd" || -f "$saves_folder/duckstation/shared_card_2.mcd" ]]; then
      configurator_generic_dialog "RetroDECK 0.7.0b Upgrade" "As part of this update, the location of saves and states for Duckstation has been changed.\n\nYour files will be moved automatically, and can now be found at\n\n~.../saves/psx/duckstation/memcards/\nand\n~.../states/psx/duckstation/"
    fi
    mkdir -p "$saves_folder/psx/duckstation/memcards"
    mv "$saves_folder/duckstation/"* "$saves_folder/psx/duckstation/memcards/"
    rmdir "$saves_folder/duckstation" # File-safe folder cleanup
    unlink "/var/config/duckstation/memcards"
    set_setting_value "$duckstationconf" "Card1Path" "$saves_folder/psx/duckstation/memcards/shared_card_1.mcd" "duckstation" "MemoryCards"
    set_setting_value "$duckstationconf" "Card2Path" "$saves_folder/psx/duckstation/memcards/shared_card_2.mcd" "duckstation" "MemoryCards"
    set_setting_value "$duckstationconf" "Directory" "$saves_folder/psx/duckstation/memcards" "duckstation" "MemoryCards"
    set_setting_value "$duckstationconf" "RecursivePaths" "$roms_folder/psx" "duckstation" "GameList"
    mkdir -p "$states_folder/psx"
    mv -t "$states_folder/psx/" "$states_folder/duckstation"
    unlink "/var/config/duckstation/savestates"
    dir_prep "$states_folder/psx/duckstation" "/var/config/duckstation/savestates"

    rm -rf /var/config/retrodeck/tools
    rm -rf /var/config/emulationstation/.emulationstation/gamelists/tools/

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
    unlink "/var/config/emulationstation/.emulationstation/downloaded_media"
    unlink "/var/config/emulationstation/.emulationstation/themes"

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

    prepare_emulator "reset" "cemu"

    prepare_emulator "reset" "pico8"

    configurator_generic_dialog "RetroDECK 0.7.0b Upgrade" "Would you like to install the official controller profile?\n(this will reset your custom emulator settings)\n\nAfter installation you can enable it from from Controller Settings -> Templates."
    if [[ $(configurator_generic_question_dialog "RetroDECK Official Controller Profile" "Would you like to install the official RetroDECK controller profile?") == "true" ]]; then
      install_retrodeck_controller_profile
      prepare_emulator "reset" "all"
    fi
  fi
  if [[ $prev_version -le "071" ]]; then
    # In version 0.7.1b, the following changes were made that required config file updates/reset or other changes to the filesystem:
    # - Force update PPSSPP standalone keybinds for L/R.
    set_setting_value "$ppssppcontrolsconf" "L" "1-45,10-193" "ppsspp" "ControlMapping"
    set_setting_value "$ppssppcontrolsconf" "R" "1-51,10-192" "ppsspp" "ControlMapping"
  fi

  if [[ $prev_version -le "073" ]]; then
    # In version 0.7.3b, there was a bug that prevented the correct creations of the roms/system folders, so we force recreate them.
    emulationstation --home /var/config/emulationstation --create-system-dirs
  fi

  # The following commands are run every time.

  if [[ -d "/var/data/dolphin-emu/Load/DynamicInputTextures" ]]; then # Refresh installed textures if they have been enabled
    rsync -rlD --mkpath "/app/retrodeck/extras/DynamicInputTextures/" "/var/data/dolphin-emu/Load/DynamicInputTextures/"
  fi
  if [[ -d "/var/data/primehack/Load/DynamicInputTextures" ]]; then # Refresh installed textures if they have been enabled
    rsync -rlD --mkpath "/app/retrodeck/extras/DynamicInputTextures/" "/var/data/primehack/Load/DynamicInputTextures/"
  fi

  if [[ -f "$HOME/.steam/steam/controller_base/templates/RetroDECK_controller_config.vdf" ]]; then # If RetroDECK controller profile has been previously installed
    install_retrodeck_controller_profile
  fi

  update_splashscreens
  deploy_helper_files
  build_retrodeck_current_presets
  ) |
  zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Finishing Upgrade" \
  --text="RetroDECK is finishing the upgrade process, please wait."

  version=$hard_version
  conf_write

  if grep -qF "cooker" <<< $hard_version; then
    changelog_dialog "$(echo $version | cut -d'-' -f2)"
  else
    changelog_dialog "$version"
  fi
}
