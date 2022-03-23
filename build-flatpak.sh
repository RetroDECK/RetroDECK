#!/bin/bash

INSTALL_DIR=$PWD
PREVIOUS_DIR=$PWD

echo "Welcome to the RetroDECK flatpak builder."
echo "This script is helping the flatpak building in $INSTALL_DIR."

read -n 1 -r -s -p $'Press enter to continue...\n'
echo "Building RetroDECK, please stand by."

# Installing 351elec-emulationstation
cd $INSTALL_DIR
git clone --recursive https://github.com/351ELEC/351elec-emulationstation emulationstation
# TODO: one day I will have to fork this emustation...
# applying patches
cp $INSTALL_DIR/patches/Splash.h $INSTALL_DIR/emulationstation/es-core/src/Splash.h
cp $INSTALL_DIR/patches/GuiMenu.cpp $INSTALL_DIR/emulationstation/es-app/src/guis/GuiMenu.cpp
# pathes applied
cd emulationstation
sudo pacman -S base-devel cmake freeimage sdl2_mixer sdl2 rapidjson boost
cmake -DENABLE_EMUELEC=1 -DGLES2=0 -DDISABLE_KODI=1 -DENABLE_FILEMANAGER=0 -DCEC=0 -DRG552=1
make -j$(nproc)

cd $INSTALL_DIR
flatpak-builder retrodeck-flatpak com.xargon.retrodeck.yml --force-clean

# Useful commands:
# flatpak-builder --user --install --force-clean retrodeck-flatpak com.xargon.retrodeck.yml
# flatpak run com.xargon.retrodeck
#
# flatpak --user remote-add --no-gpg-verify xargon-dev repo
# flatpak --user install xargon-dev com.xargon.retrodeck

echo "Building terminated, you can install retrodeck by typing `flatpak run com.xargon.retrodeck`."

cd $PREVIOUS_DIR
