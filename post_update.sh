#!/bin/bash

source /app/libexec/save_migration.sh

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
    
    rm -rf /var/config/primehack # Purge old Primehack config files. Saves are safe as they are linked into /var/data/primehack.
    primehack_init

    dir_prep "$rdhome/saves/duckstation" "/var/data/duckstation/memcards"
    dir_prep "$rdhome/states/duckstation" "/var/data/duckstation/savestates"
  fi

  # The following commands are run every time.

  tools_init
  update_splashscreens
  update_rd_conf
  ) |
  zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Finishing Upgrade" \
  --text="RetroDECK is finishing the upgrade process, please wait."

  create_lock
}