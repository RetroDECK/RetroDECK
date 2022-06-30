#!/bin/bash

zenity --title "RetroDECK" --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --text="Doing some changes in the emulator's configuration may create serious issues,\nplease continue only if you know what you're doing.\n\nDo you want to continue?"
if [ $? == 1 ] #no
then
    exit 0
fi

border="$(zenity --list \
--title "RetroDECK" \
--window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
--text="Which emulator do you want to configure?" \
--hide-header \
--column=Border \
"RetroArch" \
"Citra" \
"Dolphin" \
"MelonDS" \
"PCSX2" \
"PPSSPP" \
"RPCS3" \
"Yuzu")"

if [ $border == "RetroArch" ]
then
    retroarch
elif [ $border == "Citra" ]
then
    citra-qt
elif [ $border == "Dolphin" ]
then
    dolphin-emu
elif [ $border == "MelonDS" ]
then
    melonDS
elif [ $border == "PCSX2" ]
then
    pcsx2
elif [ $border == "PPSSPP" ]
then
    PPSSPPSDL
elif [ $border == "RPCS3" ]
then
    rpcs3
elif [ $border == "Yuzu" ]
then
    yuzu
fi