#!/bin/bash

# WARNING: run this script from the project root folder, not from here!!

# This script is used to inject framework, config files and components inside a RetroDECK Cooker installation
# To apply the injected config you have to reset the targeted component from the Configurator
# Please know what you're doing, if you need to undo this you need to completely uninstall and reinstall RetroDECK flatpak
# Please note that this may create a dirty situation where older files are still in place as the action is add and overwrite

flatpak_user_installation="$HOME/.local/share/flatpak/app/net.retrodeck.retrodeck/current/active/files"
flatpak_system_installation="/var/lib/flatpak/app/net.retrodeck.retrodeck/current/active/files"
force_user=false
force_system=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --force-user) force_user=true ;;
        --force-system) force_system=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Determine installation path
if [ "$force_user" = true ]; then
    echo "Forcing user mode installation."
    app="$flatpak_user_installation"
elif [ "$force_system" = true ]; then
    echo "Forcing system mode installation."
    app="$flatpak_system_installation"
elif [ -d "$flatpak_user_installation" ]; then
    echo "RetroDECK is installed in user mode, proceeding."
    app="$flatpak_user_installation"
elif [ -d "$flatpak_system_installation" ]; then
    echo "RetroDECK is installed in system mode, proceeding."
    app="$flatpak_system_installation"
else
    echo "RetroDECK installation not found, are you inside a flatpak? Quitting"
    exit 1
fi

# Copying files to the installation
sudo cp -vfr "res/binding_icons" "$app/retrodeck/binding_icons"
sudo cp -vfr "res/steam_grid" "$app/retrodeck" 
sudo cp -vfr "config/"** "$app/retrodeck/config/"
sudo cp -vfr "tools" "$app"
sudo cp -vfr "retrodeck.sh" "$app/bin/"
sudo cp -vfr "functions/"** "$app/libexec/"
rm -rf "$app/libexec/retrodeck.sh"
sudo cp -vfr "net.retrodeck.retrodeck.metainfo.xml" "$app/share/metainfo/net.retrodeck.retrodeck.metainfo.xml"
echo ""

echo "Components injection is possible, be sure that your components folder contains the desired components."
echo "If you want to update the components, run the 'manage_components.sh' script first and re-run this script."
echo ""
read -p "Do you want to inject RetroDECK Components? (Y/n): " inject_components

inject_components=${inject_components:-Y}
if [[ "$inject_components" =~ ^[Yy]$ ]]; then
    if [ -d "components" ]; then
        FLATPAK_DEST="$app"
        source "automation_tools/install_components.sh"
    else
        echo "No 'components' directory found to inject."
    fi
else
    echo "Skipping components injection."
fi
