#!/bin/bash

# if we got the .lock file it means that it's not a first run
if [ ! -f ~/retrodeck/.lock ]
then
    #mkdir -p /tmp/retrodeck_logs/
    #ln -s /tmp/retrodeck_logs/ ~/retrodeck/logs/
    #touch ~/retrodeck/logs/retrodeck.log
    #echo "RetroDECK: .lock file not found, initializing."
    mkdir -p ~/retrodeck/.emulationstation
    mkdir -p ~/retrodeck/saves
    mkdir -p ~/retrodeck/states
    mkdir -p ~/retrodeck/screenshots
    mkdir -p /var/config/retroarch/
    rm -rf ~/retrodeck/.emulationstation/es_settings.xml
    rm -rf ~/retrodeck/.emulationstation/es_input.xml
    cp /app/retrodeck/es_settings.xml ~/retrodeck/.emulationstation/es_settings.xml
    cp /app/retrodeck/es_settings.xml ~/retrodeck/.emulationstation/es_input.xml
    cp /app/retrodeck/retrodeck-retroarch.cfg /var/config/retroarch/retroarch.cfg
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