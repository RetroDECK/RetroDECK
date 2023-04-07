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
    primehack_init

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

    cp -fv $emuconfigs/citra/qt-config.ini /var/config/citra-emu/qt-config.ini
    sed -i 's#RETRODECKHOMEDIR#'$rdhome'#g' /var/config/citra-emu/qt-config.ini
    cp -fvr $emuconfigs/yuzu/* /var/config/yuzu/
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
    # - New ~/retrodeck/mods and ~/retrodeck/texture_packs directories are added and symlinked to multiple different emulators (where supported)
    # - Expose ES-DE gamelists folder to user at ~/retrodeck/gamelists
    # - Add new sections [paths] and [options] headers to retrodeck.cfg

    mkdir -p "$mods_folder"
    mkdir -p "$texture_packs_folder"
    dir_prep "$mods_folder/Primehack" "/var/data/primehack/Load/GraphicMods"
    dir_prep "$texture_packs_folder/Primehack" "/var/data/primehack/Load/Textures"
    dir_prep "$mods_folder/Dolphin" "/var/data/dolphin-emu/Load/GraphicMods"
    dir_prep "$texture_packs_folder/Dolphin" "/var/data/dolphin-emu/Load/Textures"
    dir_prep "$mods_folder/Citra" "/var/data/citra-emu/load/mods"
    dir_prep "$texture_packs_folder/Citra" "/var/data/citra-emu/load/textures"
    dir_prep "$mods_folder/Yuzu" "/var/data/yuzu/load"

    dir_prep "$rdhome/gamelists" "/var/config/emulationstation/.emulationstation/gamelists"

    sed -i '/version=.*/G' $rd_conf
    sed -i '3i [paths]' $rd_conf
    sed -i '/^power_user=.*/i [options]' $rd_conf
  fi

  # The following commands are run every time.

  update_splashscreens
  update_rd_conf
  ) |
  zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Finishing Upgrade" \
  --text="RetroDECK is finishing the upgrade process, please wait."
  create_lock
}