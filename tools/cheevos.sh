#!/bin/bash

racfg="/var/config/retroarch/retroarch.cfg"

login=$(zenity --forms --title="RetroAchievements Login" \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
	--text="Enter your RetroAchievements Account details.\n\nBe aware that this tool cannot verify your login details.\nFor registration and more info visit\nhttps://retroachievements.org/\n" \
	--separator="=SEP=" \
	--add-entry="Username" \
	--add-password="Password")

arrIN=(${login//=SEP=/ })
user=${arrIN[0]}
pass=${arrIN[1]}

sed -i "s%cheevos_enable =.*%cheevos_enable = \"true\"" $racfg
sed -i "s%cheevos_username =.*%cheevos_username = \"$user\"" $racfg
sed -i "s%cheevos_password =.*%cheevos_password = \"$pass\"" $racfg
