#!/bin/bash

zenity --title "RetroDECK" --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --text="Doing some changes in the emulator's configuration may create serious issues,\nplease continue only if you know what you're doing.\n\nDo you want to continue?"
if [ $? == 1 ] #no
then
    exit 0
fi

emulator="$(zenity --list \
--width=600 \
--height=350 \
--title "RetroDECK" \
--window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
--text="Which emulator do you want to configure?" \
--hide-header \
--column=emulator \
"RetroArch" \
"Citra" \
"Dolphin" \
"Duckstation" \
"MelonDS" \
"PCSX2-QT" \
"PCSX2-Legacy" \
"PPSSPP" \
"RPCS3" \
"XEMU" \
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
elif [ $emulator == "Duckstation" ]
then
    duckstation-qt
elif [ $emulator == "MelonDS" ]
then
    melonDS
elif [ $emulator == "PCSX2-Legacy" ]
then
    pcsx2
elif [ $emulator == "PCSX2-QT" ]
then
    pcsx2-qt
elif [ $emulator == "PPSSPP" ]
then
    PPSSPPSDL
elif [ $emulator == "RPCS3" ]
then
    rpcs3
elif [ $emulator == "Yuzu" ]
then
    yuzu
elif [ $emulator == "XEMU" ]
then
    xemu
fi