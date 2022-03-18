#!/bin/bash

INSTALL_DIR=~/retrodeck
CORES_LINK=https://buildbot.libretro.com/stable/1.10.1/linux/x86_64/RetroArch_cores.7z
PREVIOUS_DIR=$PWD

echo "Welcome to the RetroDECK installer."
echo "RetroDECK will be installed in $INSTALL_DIR."

# TODO-MAYBE: give the option to change the installation directory?

echo "WARNING: RetroDECK will replace your retroarch.cfg, the former one will be renamed moved in ~/.config/retroarch/retroarch.cfg.bak."
echo "Whenever a choice is prompted just accept it to continue (yes/enter), root password will be asked."
# but maybe it will not affect the original retroarch, let's see
# maybe --root option of pacman may be useful to install my own copy of retroarch without messing the one already installed
read -n 1 -r -s -p $'Press enter to continue...\n'
echo "Installing RetroDECK in $INSTALL_DIR, please stand by."

cd $INSTALL_DIR

# TODO: download everything from retrodeck github
# git clone --recursive https://github.com/XargonWan/RetroDECK retrodeck

# Initalizing rom folders
if [ test ! -d "$INSTALL_DIR/storage/roms/" ]; then
    mkdir -p $INSTALL_DIR/storage/roms/
fi
if [ test ! -d "$INSTALL_DIR/roms" ]; then
    ln -s $INSTALL_DIR/storage/roms $INSTALL_DIR/roms
fi
mkdir -p $INSTALL_DIR/roms/bios
mkdir -p $INSTALL_DIR/roms/3do
mkdir -p $INSTALL_DIR/roms/amiga
mkdir -p $INSTALL_DIR/roms/amigacd32
mkdir -p $INSTALL_DIR/roms/amstradcpc
mkdir -p $INSTALL_DIR/roms/arcade
mkdir -p $INSTALL_DIR/roms/atari2600
mkdir -p $INSTALL_DIR/roms/atari5200
mkdir -p $INSTALL_DIR/roms/atari7800
mkdir -p $INSTALL_DIR/roms/atarist
mkdir -p $INSTALL_DIR/roms/atari800
mkdir -p $INSTALL_DIR/roms/atomiswave
mkdir -p $INSTALL_DIR/roms/channelf
mkdir -p $INSTALL_DIR/roms/colecovision
mkdir -p $INSTALL_DIR/roms/c64
mkdir -p $INSTALL_DIR/roms/c128
mkdir -p $INSTALL_DIR/roms/vic20
mkdir -p $INSTALL_DIR/roms/laserdisc
mkdir -p $INSTALL_DIR/roms/dreamcast
mkdir -p $INSTALL_DIR/roms/easyrpg
mkdir -p $INSTALL_DIR/roms/famicom
mkdir -p $INSTALL_DIR/roms/fbn
mkdir -p $INSTALL_DIR/roms/gb
mkdir -p $INSTALL_DIR/roms/gbh
mkdir -p $INSTALL_DIR/roms/gameandwatch
mkdir -p $INSTALL_DIR/roms/gba
mkdir -p $INSTALL_DIR/roms/fds
mkdir -p $INSTALL_DIR/roms/c16
mkdir -p $INSTALL_DIR/roms/ggh
mkdir -p $INSTALL_DIR/roms/gbah
mkdir -p $INSTALL_DIR/roms/intellivision
mkdir -p $INSTALL_DIR/roms/gbch
mkdir -p $INSTALL_DIR/roms/atarilynx
mkdir -p $INSTALL_DIR/roms/mame
mkdir -p $INSTALL_DIR/roms/dos
mkdir -p $INSTALL_DIR/roms/snesmsu1
mkdir -p $INSTALL_DIR/roms/msx
mkdir -p $INSTALL_DIR/roms/msx2
mkdir -p $INSTALL_DIR/roms/naomi
mkdir -p $INSTALL_DIR/roms/neogeo
mkdir -p $INSTALL_DIR/roms/ngp
mkdir -p $INSTALL_DIR/roms/nds
mkdir -p $INSTALL_DIR/roms/n64
mkdir -p $INSTALL_DIR/roms/nes
mkdir -p $INSTALL_DIR/roms/nesh
mkdir -p $INSTALL_DIR/roms/ngpc
mkdir -p $INSTALL_DIR/roms/neocd
mkdir -p $INSTALL_DIR/roms/pc-9800
mkdir -p $INSTALL_DIR/roms/pcengine
mkdir -p $INSTALL_DIR/roms/pcenginecd
mkdir -p $INSTALL_DIR/roms/pcfx
mkdir -p $INSTALL_DIR/roms/openbor
mkdir -p $INSTALL_DIR/roms/piece
mkdir -p $INSTALL_DIR/roms/odyssey2
mkdir -p $INSTALL_DIR/roms/psp
mkdir -p $INSTALL_DIR/roms/pspminis
mkdir -p $INSTALL_DIR/roms/pokemini
mkdir -p $INSTALL_DIR/roms/homebrew
mkdir -p $INSTALL_DIR/roms/ports
mkdir -p $INSTALL_DIR/roms/sc-3000
mkdir -p $INSTALL_DIR/roms/scummvm
mkdir -p $INSTALL_DIR/roms/psx
mkdir -p $INSTALL_DIR/roms/segacd
mkdir -p $INSTALL_DIR/roms/sega32x
mkdir -p $INSTALL_DIR/roms/genesis
mkdir -p $INSTALL_DIR/roms/genh
mkdir -p $INSTALL_DIR/roms/mastersystem
mkdir -p $INSTALL_DIR/roms/megadrive
mkdir -p $INSTALL_DIR/roms/megaduck
mkdir -p $INSTALL_DIR/roms/saturn
mkdir -p $INSTALL_DIR/roms/sg-1000
mkdir -p $INSTALL_DIR/roms/x1
mkdir -p $INSTALL_DIR/roms/zxspectrum
mkdir -p $INSTALL_DIR/roms/zx81
mkdir -p $INSTALL_DIR/roms/pc-8800
mkdir -p $INSTALL_DIR/roms/snes
mkdir -p $INSTALL_DIR/roms/supergrafx
mkdir -p $INSTALL_DIR/roms/pico-8
mkdir -p $INSTALL_DIR/roms/megacd
mkdir -p $INSTALL_DIR/roms/snesh
mkdir -p $INSTALL_DIR/roms/satellaview
mkdir -p $INSTALL_DIR/roms/sfc
mkdir -p $INSTALL_DIR/roms/sufami
mkdir -p $INSTALL_DIR/roms/tic-80
mkdir -p $INSTALL_DIR/roms/tg16
mkdir -p $INSTALL_DIR/roms/solarus
mkdir -p $INSTALL_DIR/roms/vectrex
mkdir -p $INSTALL_DIR/roms/gbc
mkdir -p $INSTALL_DIR/roms/videopac
mkdir -p $INSTALL_DIR/roms/virtualboy
mkdir -p $INSTALL_DIR/roms/wonderswan
mkdir -p $INSTALL_DIR/roms/wonderswancolor
mkdir -p $INSTALL_DIR/roms/ecwolf
mkdir -p $INSTALL_DIR/roms/x68000
mkdir -p $INSTALL_DIR/roms/build
mkdir -p $INSTALL_DIR/roms/tools
mkdir -p $INSTALL_DIR/roms/imageviewer
mkdir -p $INSTALL_DIR/roms/gamegear
mkdir -p $INSTALL_DIR/roms/tg16cd
mkdir -p $INSTALL_DIR/roms/j2me
mkdir -p $INSTALL_DIR/roms/uzebox
mkdir -p $INSTALL_DIR/roms/supervision
mkdir -p $INSTALL_DIR/roms/doom
mkdir -p $INSTALL_DIR/roms/switch

# Initializing directories
mkdir -p $INSTALL_DIR/storage/.config/
mkdir -p $INSTALL_DIR/usr/
mkdir -p $INSTALL_DIR/emulators
ln -s $INSTALL_DIR/emulationstation ~/.emulationstation


# Defining architecture
rm -f $INSTALL_DIR/storage/.config/.OS_ARCH
touch $INSTALL_DIR/storage/.config/.OS_ARCH
echo "DECK" >> $INSTALL_DIR/storage/.config/.OS_ARCH

# Installing RetroArch
sudo pacman -S retroarch
# Setting up RetroArch
mkdir -p ~/.config/retroarch/
mv ~/.config/retroarch/retroarch.cfg ~/.config/retroarch/retroarch.cfg.bak
mv $INSTALL_DIR/retroarch.cfg ~/.config/retroarch/
# TODO: download controller config

# Installing libretro cores
cd $INSTALL_DIR/emulators

if test -f "$INSTALL_DIR/emulators/RetroArch_cores.7z"; then
    read -p "The RetroArch cores seems to be already downloaded, do you want to re-download them? [Y/n]: " -n 1 -r
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        break
    else
        rm -rf RetroArch*
        wget $CORES_LINK
    fi
fi

7z x RetroArch_cores.7z
mv $INSTALL_DIR/emulators/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/cores $INSTALL_DIR/emulators/

# TODO: Installing standalone emulators

# Switch - Yuzu
flatpak install flathub org.yuzu_emu.yuzu

# Switch - Ryujinx
flatpak install flathub org.ryujinx.Ryujinx

# PS3 - RPCS3
# DOS - dosbox-pure is included?
# PSVITA - vita3k

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
cp $INSTALL_DIR/es_systems.cfg $INSTALL_DIR/emulationstation/
cp $INSTALL_DIR/es_settings.cfg $INSTALL_DIR/emulationstation/
cp $INSTALL_DIR/es_input.cfg $INSTALL_DIR/emulationstation/

# Installing default theme
mkdir -p $INSTALL_DIR/emulationstation/themes
cd $INSTALL_DIR/emulationstation/themes
git clone --recursive https://github.com/anthonycaccese/es-theme-art-book-next


# Downloading needed files
# TODO 351elec-es-packages  batocera-config  batocera-scraper  batocera-settings  runemu.py  setsettings.py

# Creating desktop element
rm -f ~/Desktop/RetroDECK.desktop
touch ~/Desktop/RetroDECK.desktop
cat << EOF >> ~/Desktop/RetroDECK.desktop
[Desktop Entry]
Comment=An enbedded emulation system.
Exec=$INSTALL_DIR/retrodeck.sh
GenericName=RetroDECK
Icon=$INSTALL_DIR/res/icon128.png
MimeType=
Name=RetroDECK
Path=$INSTALL_DIR/
StartupNotify=true
Terminal=false
TerminalOptions=
Type=Application
X-DBUS-ServiceName=
X-DBUS-StartupType=
X-KDE-SubstituteUID=false
X-KDE-Username=
EOF

# Creating start script
rm -rf $INSTALL_DIR/retrodeck.sh
touch $INSTALL_DIR/retrodeck.sh
cat << EOF >> $INSTALL_DIR/retrodeck.sh
#!/bin/bash

$INSTALL_DIR/export_func.sh

mkdir -p /tmp/logs

if [ test -d "/tmp/cores" ]; then break
else
    ln -s $INSTALL_DIR/emulators/cores /tmp/cores
fi

$INSTALL_DIR/emulationstation/emulationstation
EOF

chmod 777 $INSTALL_DIR/retrodeck.sh
chmod 777 $INSTALL_DIR/export_func.sh

# Cleaning up
# TODO: these removal must be made when I am sure this files are safe on github
#rm -rf $INSTALL_DIR/emulators/RetroArch-Linux-x86_64
#rm -rf $INSTALL_DIR/emulators/RetroArch_cores.7z
#rm -rf $INSTALL_DIR/emulators/ryujinx-1.1.76-linux_x64.tar.gz
#rm $INSTALL_DIR/es_systems.cfg
#rm $INSTALL_DIR/es_settings.cfg
#rm $INSTALL_DIR/es_input.cfg
#rm -rf $INSTALL_DIR/patches

echo "Installation terminated, you can run RetroDECK from the desktop link or add it on your Steam Library."
# TODO: maybe I can add it to the steam library directly, I think I have to close steam and  design a banner

cd $PREVIOUS_DIR
