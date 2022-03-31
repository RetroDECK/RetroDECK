#!/bin/bash

# Steam Deck SD path: /run/media/mmcblk0p1

is_mounted() {
    mount | awk -v DIR="$1" '{if ($3 == DIR) { exit 0}} ENDFILE{exit -1}'
}

# if we got the .lock file it means that it's not a first run
if [ ! -f ~/retrodeck/.lock ]
then
    kdialog --title "RetroDECK" --yes-label "Internal" --no-label "SD Card" --yesno "Where do you want your rom folder to be located?"
    if [ $? == 0 ] #yes - Internal
    then
        roms_folder=~/retrodeck/roms
    else #no - SD Card
        if is_mounted "/run/media/mmcblk0p1"
        then
            roms_folder=/run/media/mmcblk0p1/retrodeck/roms
        else
            kdialog --title "RetroDECK" --error "SD Card is not readable, please check if it inserted or mounted correctly and run RetroDECK again."
            exit 0
        fi
    fi

    # initializing ES-DE

    mkdir -p /var/config/retrodeck/tools

    # Cleaning
    rm -rf /var/config/emulationstation/
    rm ~/retrodeck/bios
    rm /var/config/retrodeck/tools/*

    ls -ln /var/config/ #DEBUG
    ls -ln /var/config/emulationstation/.emulationstation #DEBUG
    read -n 1 -r -s -p $'Press enter to continue...\n' #DEBUG

    kdialog --title "RetroDECK" --msgbox "EmulationStation will now initialize the system, please don't edit the rom location.\nJust select CREATE DIRECTORIES, YES, QUIT buttons.\nRetroDECK will manage the rest."

    mkdir -p /var/config/emulationstation/

    emulationstation --home /var/config/emulationstation

    mv /var/config/emulationstation/ROMs /var/config/emulationstation/ROMs.bak
    ln -s $roms_folder /var/config/emulationstation/ROMs
    mv /var/config/emulationstation/ROMs.bak $roms_folder

    # XMLSTARLET HERE
    cp /app/retrodeck/es_settings.xml /var/config/emulationstation/.emulationstation/es_settings.xml

    mkdir -p ~/retrodeck/saves
    mkdir -p ~/retrodeck/states
    mkdir -p ~/retrodeck/screenshots

    cp -r /app/retrodeck/tools/* /var/config/retrodeck/tools

    mkdir -p /var/config/retroarch/system
    ln -s ~/.var/app/com.xargon.retrodeck/config/retroarch/system ~/retrodeck/bios

    cp /app/retrodeck/retrodeck-retroarch.cfg /var/config/retroarch/retroarch.cfg

    mkdir -p /var/config/emulationstation/.emulationstation/gamelists/tools/
    cp /app/retrodeck/tools-gamelist.xml /var/config/emulationstation/.emulationstation/custom_systems/tools/gamelist.xml

    mkdir -p /var/config/retroarch/cores/
    cp /app/share/libretro/cores/* /var/config/retroarch/cores/

    touch ~/retrodeck/.lock

    kdialog --title "RetroDECK" --msgbox "Initialization completed, please put your roms in: $roms_folder.\nIf you wish to change the roms location you may use the tool located the tools section of RetroDECK."
else
    emulationstation --home /var/config/emulationstation
fi