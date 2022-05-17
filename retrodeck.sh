#!/bin/bash

# Steam Deck SD path: /run/media/mmcblk0p1

# Create log
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
echo "$(date) : RetroDECK started" >&3
exec 1>~/retrodeck/.retrodeck.log 2>&1

is_mounted() {
    mount | awk -v DIR="$1" '{if ($3 == DIR) { exit 0}} ENDFILE{exit -1}'
}

# if we got the .lock file it means that it's not a first run
if [ ! -f ~/retrodeck/.lock ]
then
	kdialog --title "RetroDECK" --yes-label "Yes" --no-label "Quit" --yesno "Welcome to the first configuration of RetroDECK.\n\nBefore starting, are you in Desktop Mode?\nIf not the program will quit as the first setup MUST be done in Desktop Mode."
	if [ $? == 1 ] #quit
    then
		exit 0
	fi
    kdialog --title "RetroDECK" --yes-label "Internal" --no-label "SD Card" --yesno "Where do you want your roms folder to be located?"
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

    mkdir -p $roms_folder

    # initializing ES-DE

    mkdir -p /var/config/retrodeck/tools

    # Cleaning
    rm -rf /var/config/emulationstation/
    rm /var/config/retrodeck/tools/*
    rm -f /var/config/yuzu/qt-config.ini

    kdialog --title "RetroDECK" --msgbox "EmulationStation will now initialize the system, please don't edit the roms location, just select:\n\nCREATE DIRECTORIES, YES, QUIT\n\nRetroDECK will manage the rest."

    mkdir -p /var/config/emulationstation/

    emulationstation --home /var/config/emulationstation

	kdialog --title "RetroDECK" --msgbox "RetroDECK will now install the needed files, please wait one minute, another message will notify when the process will be finished.\n\nPress OK to continue."

    # Initializing ROMs folder - Original in ~/retrodeck (or SD Card)
    mv -f /var/config/emulationstation/ROMs /var/config/emulationstation/ROMs.bak
    ln -s $roms_folder /var/config/emulationstation/ROMs
    mv -f /var/config/emulationstation/ROMs.bak/* $roms_folder/
    rm -rf /var/config/emulationstation/ROMs.bak

    # XMLSTARLET HERE
    cp /app/retrodeck/es_settings.xml /var/config/emulationstation/.emulationstation/es_settings.xml

    mkdir -p ~/retrodeck/saves
    mkdir -p ~/retrodeck/states
    mkdir -p ~/retrodeck/screenshots
    mkdir -p ~/retrodeck/bios/pico-8

    # TODO: write a function for these stuff below

    # ES-DE
    cp -r /app/retrodeck/tools/* /var/config/retrodeck/tools/
    mkdir -p /var/config/emulationstation/.emulationstation/custom_systems/tools/
    cp /app/retrodeck/tools-gamelist.xml /var/config/retrodeck/tools/gamelist.xml
    # ES-DE scraped folder - Original in ~/retrodeck
    mv -f /var/config/emulationstation/.emulationstation/downloaded_media /var/config/emulationstation/.emulationstation/downloaded_media.old
    mkdir ~/retrodeck/.downloaded_media
    ln -s ~/retrodeck/.downloaded_media /var/config/emulationstation/.emulationstation/downloaded_media
    mv -f /var/config/emulationstation/.emulationstation/downloaded_media.old/* ~/retrodeck/.downloaded_media
    rm -rf /var/config/emulationstation/.emulationstation/downloaded_media.old
    # ES-DE themes folder - Original in ~/retrodeck
    mv -f /var/config/emulationstation/.emulationstation/themes /var/config/emulationstation/.emulationstation/themes.old
    mkdir ~/retrodeck/.themes
    ln -s ~/retrodeck/.themes /var/config/emulationstation/.emulationstation/themes
    mv -f /var/config/emulationstation/.emulationstation/themes.old/* ~/retrodeck/.themes
    rm -rf /var/config/emulationstation/.emulationstation/themes.old

    # Initializing emulators configs
    emuconfigs=/app/retrodeck/emu-configs/

    # RetroArch
    mkdir -p /var/config/retroarch/cores/
    rm -rf /var/config/retroarch/system
    ln -s ~/retrodeck/bios /var/config/retroarch/system
    cp /app/share/libretro/cores/* /var/config/retroarch/cores/
    cp $emuconfigs/retroarch.cfg /var/config/retroarch/
    rm -f ~/retrodeck/bios/bios # in some situations a double bios link is created

    # Yuzu
    find ~/retrodeck/bios/switch -xtype l -exec rm {} \; # removing dead symlinks
    # initializing the keys folder
    mkdir -p ~/retrodeck/bios/switch/keys
    rm -rf /var/data/yuzu/keys
    ln -s ~/retrodeck/bios/switch/keys /var/data/yuzu/keys
    # initializing the firmware folder
    mkdir -p ~/retrodeck/bios/switch/registered
    rm -rf /var/data/yuzu/nand/system/Contents/registered/
    ln -s ~/retrodeck/bios/switch/registered /var/data/yuzu/nand/system/Contents/registered/
    # configuring Yuzu
    cp $emuconfigs/yuzu-qt-config.ini /var/config/yuzu/qt-config.ini

    # Dolphin
    mkdir -p /var/config/dolphin-emu/
    cp $emuconfigs/Dolphin.ini /var/config/dolphin-emu/

    # pcsx2
    mkdir -p /var/config/PCSX2/inis/
    cp $emuconfigs/PCSX2_ui.ini /var/config/PCSX2/inis/

    # MelonDS
    mkdir -p /var/config/melonDS/
    ln -s ~/retrodeck/bios /var/config/melonDS/bios
    cp $emuconfigs/melonDS.ini /var/config/melonDS/

    # CITRA
    mkdir -p /var/config/citra-emu/
    cp $emuconfigs/citra-qt-config.ini /var/config/citra-emu/qt-config.ini

    # RPCS3
    mkdir -p /var/config/rpcs3/
    cp $emuconfigs/config.yml /var/config/rpcs3/

    # PICO-8
    mkdir -p $roms_folder/pico-8
    

    # Locking RetroDECK
    touch ~/retrodeck/.lock

    kdialog --title "RetroDECK" --msgbox "Initialization completed.\nplease put your roms in:\n\n$roms_folder\n\nand your bioses in\n\n~/retrodeck/bios\n\nThen start the program again.\nIf you wish to change the roms location, you may use the tool located the tools section of RetroDECK.\n\nIt's suggested to add RetroDECK to your Steam Library for a quick access."
else
    emulationstation --home /var/config/emulationstation
fi
