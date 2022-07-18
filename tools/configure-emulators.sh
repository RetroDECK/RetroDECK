#!/bin/bash

zenity --title "RetroDECK" --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --text="Doing some changes in the emulator's configuration may create serious issues,\nplease continue only if you know what you're doing.\n\nDo you want to continue?"
if [ $? == 1 ] #no
then
    exit 0
fi

emulator="$(zenity --list \
--title "RetroDECK" \
--window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
--text="Which emulator do you want to configure?" \
--hide-header \
--column=emulator \
"RetroArch" \
"Citra" \
"Dolphin" \
"MelonDS" \
"PCSX2" \
"PPSSPP" \
"RPCS3" \
"Yuzu")"

if [ $emulator == "RetroArch" ]
then
    retroarch
elif [ $emulator == "Citra" ]
then
    citra-qt
elif [ $emulator == "Dolphin" ]
then
    dolphin-emu
elif [ $emulator == "MelonDS" ]
then
    melonDS
elif [ $emulator == "PCSX2" ]
then
    pcsx2
elif [ $emulator == "PPSSPP" ]
then
    PPSSPPSDL
elif [ $emulator == "RPCS3" ]
then
    rpcs3
elif [ $emulator == "Yuzu" ]
then
    yuzu
fi