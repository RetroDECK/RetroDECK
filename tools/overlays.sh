#!/bin/bash

border="$(zenity --list \
--title "RetroDECK" \
--window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
--text="Select the borders type" \
--hide-header \
--column=Border \
"None" \
"Light" \
"Dark")"

if [ $border == "None" ]
then
    return
elif [ $border == "Light" ]
then
    return
elif [ $border == "Dark" ]
then
    return
fi

shader="$(zenity --list \
--title "RetroDECK" \
--window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
--text="Select the shader type" \
--hide-header \
--column=Border \
"None" \
"Retro")"

if [ $shader == "None" ]
then
    return
elif [ $shader == "Retro" ]
then
    return
fi