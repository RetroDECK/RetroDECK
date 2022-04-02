#!/bin/bash

INSTALL_DIR=$PWD
PREVIOUS_DIR=$PWD

echo "Welcome to the RetroDECK flatpak builder."
echo "This script is helping the flatpak building in $INSTALL_DIR."

read -n 1 -r -s -p $'Press enter to continue...\n'
echo "Building RetroDECK, please stand by."

if command -v apt >/dev/null; then
  sudo apt install flatpak flatpak-builder
elif command -v yum >/dev/null; then
  sudo yum install flatpak flatpak-builder # not sure about this
else
  sudo pacman -S flatpak flatpak-builder
fi

flatpak install org.kde.Sdk//5.15-21.08 org.kde.Platform//5.15-21.08

cd $INSTALL_DIR

# External flatpaks import
# To update change branch and update the manifest.
# Some json must be converted with this: https://codebeautify.org/json-to-yaml

# RetroArch
# https://github.com/flathub/org.libretro.RetroArch/blob/master/org.libretro.RetroArch.json
git clone --recursive --branch update-v1.10.2 https://github.com/flathub/org.libretro.RetroArch.git
# removing not needed and potentially dangerous files
#rm -rf org.libretro.RetroArch/shared-modules
#rm -f org.libretro.RetroArch/retroarch.cfg
#rm -f org.libretro.RetroArch/README.md
#rm -f org.libretro.RetroArch/org.libretro.RetroArch.json
#rm -f org.libretro.RetroArch/COPYING
#rm -rf org.libretro.RetroArch/.*
ln -s org.libretro.RetroArch/* $INSTALL_DIR/

# Yuzu
# https://github.com/flathub/org.yuzu_emu.yuzu/blob/master/org.yuzu_emu.yuzu.json
#git clone --recursive https://github.com/flathub/org.yuzu_emu.yuzu
#rm -rf org.yuzu_emu.yuzu/shared-modules
#rm -rf org.yuzu_emu.yuzu/.*
#ln -s org.yuzu_emu.yuzu/* $INSTALL_DIR/


cd $INSTALL_DIR
flatpak-builder retrodeck-flatpak com.xargon.retrodeck.yml --force-clean

# Useful commands:
# flatpak-builder --user --install --force-clean retrodeck-flatpak com.xargon.retrodeck.yml
# flatpak run com.xargon.retrodeck
#
# flatpak --user remote-add --no-gpg-verify xargon-dev repo
# flatpak --user install xargon-dev com.xargon.retrodeck
#
# flatpak run --command=/bin/bash com.xargon.retrodeck

# Cleaning up
#rm -rf org.libretro.RetroArch
#rm -rf org.yuzu_emu.yuzu

# removing orphaned symlinks
find -L . -name . -o -type d -prune -o -type l -exec rm {} +

echo "Building terminated, you can install retrodeck by typing: flatpak run com.xargon.retrodeck"

cd $PREVIOUS_DIR