#!/bin/bash

zenity \
--icon-name=net.retrodeck.retrodeck \
--question \
--no-wrap \
--window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
--title "RetroDECK" \
--ok-label "Yes" \
--cancel-label "No" \
--text="This tool is will clean the MixImages in order to beautify the theme.\nDo you want to delete them?"

if [ $? == 0 ] #yes - Internal
then
    find ~/retrodeck/.downloaded_media -name miximages -type d -print0|xargs -0 rm -rfv --
fi

zenity \
--icon-name=net.retrodeck.retrodeck \
--info \
--no-wrap \
--window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
--title "RetroDECK" \
--text="Miximages successfully cleaned, please restart RetroDECK to reload the games list."