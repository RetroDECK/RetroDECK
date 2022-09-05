#!/bin/bash

racfg=""

zenity --question \
--no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
--title "RetroDECK" \
--text="Do you want to enable the rewind function in RetroArch cores?\n\nNOTE:\nThis may impact on performances expecially on the latest systems."

if [ $? == 0 ] #yes, enable
then
	sed -i 's%rewind_enable = .*%rewind_enable = "true"' $racfg
	zenity --info \
		--no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
		--title "RetroDECK" \
		--text="Rewind enabled\!\nYou can check on Libretro docs to see which cores supports this function."
else # no, disable
	sed -i 's%rewind_enable = .*%rewind_enable = "false"' $racfg
	zenity --info \
		--no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
		--title "RetroDECK" \
		--text="Rewind disabled."
fi
