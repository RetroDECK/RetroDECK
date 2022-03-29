#!/bin/bash

# if we got the .lock file it means that it's not a first run
if [ ! -f ~/retrodeck/.lock ]
then
    mkdir -p ~/retrodeck/.emulationstation
    mkdir -p ~/retrodeck/saves
    mkdir -p ~/retrodeck/states
    mkdir -p ~/retrodeck/screenshots
    mkdir -p ~/retrodeck/tools
    mkdir -p /var/config/retroarch/system
    
    ln -s ~/.var/app/com.xargon.retrodeck/config/retroarch/system/ ~/retrodeck/bios
    rm -rf ~/retrodeck/.emulationstation/es_settings.xml
    rm -rf ~/retrodeck/.emulationstation/es_input.xml
    cp /app/retrodeck/es_settings.xml ~/retrodeck/.emulationstation/es_settings.xml
    cp /app/retrodeck/es_settings.xml ~/retrodeck/.emulationstation/es_input.xml
    cp /app/retrodeck/retrodeck-retroarch.cfg /var/config/retroarch/retroarch.cfg
    cp -r /app/retrodeck/tools/* ~/retrodeck/tools/

    mkdir -p ~/retrodeck/.emulationstation/gamelists/tools/
    cp /app/retrodeck/tools-gamelist.xml ~/retrodeck/.emulationstation/gamelists/tools/gamelist.xml
    
    touch ~/retrodeck/.lock
fi

#numFields=$(xmlstarlet sel -t -m '//system' -o "." /app/share/emulationstation/resources/systems/unix/es_systems.xml | wc -c)
#for i in $(seq 1 $numFields); do
#    system=$(xmlstarlet sel -t -m "//system[$i]" -v "name" /app/share/emulationstation/resources/systems/unix/es_systems.xml)
#    if test -d ~/retrodeck/roms/${system}; then
#        mkdir -p ~/retrodeck/roms/${system}
#    fi
#done

emulationstation --home ~/retrodeck/