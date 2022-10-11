#!/bin/bash

source global.sh

zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="Quit" --ok-label "Continue" --text="WARNING: this script is experimental\nplease be sure to backup your data before continuing.\n\nDo you want to continue?"
if [ $? == 1 ] #cancel
then
    exit 0
fi

#conf_init

zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="Cancel" --ok-label "Browse" --text="The roms folder is now: $roms_folder\nplease select the new location.\nA retrodeck/roms folder will be created starting from the directory that you selected."
if [ $? == 1 ] #cancel
then
    exit 0
fi

new_roms_path="$(zenity --file-selection --title="Choose a new roms folder location" --directory)"/retrodeck/roms

zenity --title "RetroDECK" --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --text="Should I move the roms from\n\n$roms_folder\n\nto\n\n$new_roms_path?"
if [ $? == 0 ] #yes
then
    mkdir -p $new_roms_path
    mv -f $roms_folder $new_roms_path
    rm -f /var/config/emulationstation/ROMs
    ln -s $new_roms_path /var/config/emulationstation/ROMs
    rm -f $roms_folder
    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --text="Done\nYour roms are now located in:\n\n$roms_folder\n\nPress OK to continue."
    $roms_folder=$new_roms_path     # Updating variable
    conf_write                      # Writing variables in the config file (sourced from global.sh)
fi
