#!/bin/bash

# Steam Deck SD path: /run/media/mmcblk0p1

is_mounted() {
    mount | awk -v DIR="$1" '{if ($3 == DIR) { exit 0}} ENDFILE{exit -1}'
}

# if we got the .lock file it means that it's not a first run
if [ ! -f ~/retrodeck/.lock ]
then
    internal=`kdialog --title "RetroDECK" -- yes-label "Internal" --no-label "SD Card" --yesno "Where do you want your rom folder to be located?"`
    if $internal #yes - Internal
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
    mkdir -p $roms_folder
    rm -rf /var/config/.emulationstation/ROMs
    rm -rf /var/config/.emulationstation/roms
    ln -s $roms_folder /var/config/.emulationstation/roms
    kdialog --Title "RetroDECK" --msgbox "Done, please put your roms in: $roms_folder. In order to change location you may use the tool provided in the tools section of RetroDECK."

    mkdir -p /var/config/.emulationstation
    rm -rf /var/config/.emulationstation/es_settings.xml
    rm -rf /var/config/.emulationstation/es_input.xml
    cp /app/retrodeck/es_settings.xml /var/config/.emulationstation/es_settings.xml
    cp /app/retrodeck/es_settings.xml /var/config/.emulationstation/es_input.xml

    mkdir -p ~/retrodeck/saves
    mkdir -p ~/retrodeck/states
    mkdir -p ~/retrodeck/screenshots

    mkdir -p /var/config/retrodeck/tools
    cp -r /app/retrodeck/tools/* /var/config/retrodeck/tools

    mkdir -p /var/config/retroarch/system
    ln -s ~/.var/app/com.xargon.retrodeck/config/retroarch/system/ ~/retrodeck/bios
        
    cp /app/retrodeck/retrodeck-retroarch.cfg /var/config/retroarch/retroarch.cfg
    
    mkdir -p /var/config/.emulationstation/gamelists/tools/
    cp /app/retrodeck/tools-gamelist.xml /var/config/.emulationstation/gamelists/tools/gamelist.xml

    mkdir -p /var/config/retroarch/cores/
    cp /app/share/libretro/cores/* /var/config/retroarch/cores/
    
    touch ~/retrodeck/.lock
fi

#numFields=$(xmlstarlet sel -t -m '//system' -o "." /app/share/emulationstation/resources/systems/unix/es_systems.xml | wc -c)
#for i in $(seq 1 $numFields); do
#    system=$(xmlstarlet sel -t -m "//system[$i]" -v "name" /app/share/emulationstation/resources/systems/unix/es_systems.xml)
#    if test -d ~/retrodeck/roms/${system}; then
#        mkdir -p ~/retrodeck/roms/${system}
#    fi
#done

emulationstation --home /var/config/