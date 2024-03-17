#!/bin/bash

# WARNING: run this script from the project root folder, not from here!!

# This script is used to inject framework and config files inside a RetroDECK cooker installation
# To apply the injected config you have to reset the targeted component from the Configurator
# Please know what you're doing, if you need to undo this you need to completely uninstall and reinstall RetroDECK flatpak
# Please not that this may create a dirty situation where older files are still in place as the action is add and overwrite

flatpak_user_installation="$HOME/.local/share/flatpak/app/net.retrodeck.retrodeck/current/active/files"
flatpak_system_installation="/var/lib/flatpak/app/net.retrodeck.retrodeck/current/active/files"

if [ -d "$flatpak_user_installation" ]; then
    echo "RetroDECK is installed in user mode, proceeding."
    app="$flatpak_user_installation"
elif [ -d "$flatpak_system_installation" ]; then
    echo "RetroDECK is installed in system mode, proceeding."
    app="$flatpak_system_installation"
else
    echo "RetroDECK installation not found, quitting"
    exit 1
fi

sudo cp -vfr "retrodeck.sh" "$app/bin/"
sudo cp -vfr "functions/"** "$app/libexec/"
sudo cp -vfr "tools" "$app"
sudo cp -vfr "emu-configs/"** "$app/retrodeck/emu-configs/"
sudo cp -vfr "res/binding_icons" "$app/retrodeck/binding_icons" 