#!/bin/bash

lockfile="/var/config/retrodeck/.lock"      # where the lockfile is located
version="$(cat /app/retrodeck/version)"    # version info taken from the version file
rdhome="$HOME/retrodeck"                   # the retrodeck home, aka ~/retrodecck
emuconfigs="/app/retrodeck/emu-configs"    # folder with all the default emulator configs
sdcard="/run/media/mmcblk0p1"              # Steam Deck SD default path

# We moved the lockfile in /var/config/retrodeck in order to solve issue #53 - Remove in a few versions
if [ -f "$HOME/retrodeck/.lock" ]
then
  mv "$HOME/retrodeck/.lock" $lockfile
fi

# Functions area

dir_prep() {
    # This script is creating a symlink preserving old folder contents and moving them in the new one
    
    # Call me with:
    # dir prep "real dir" "symlink location"
    real="$1"
    symlink="$2"

    echo -e "\n[DIR PREP]\nMoving $symlink in $real" #DEBUG

    # if the dest dir exists we want to backup it
    if [ -d "$symlink" ];
    then
      echo "$symlink found" #DEBUG
      mv -fv "$symlink" "$symlink.old"
    fi

    # if the real dir doesn't exist we create it
    if [ ! -d "$real" ];
    then
      echo "$real not found, creating it" #DEBUG
      mkdir -pv "$real"
    fi
    
    # creating the symlink
    echo "linking $real in $symlink" #DEBUG
    mkdir -pv "$(dirname "$symlink")" # creating the full path except the last folder
    ln -sv "$real" "$symlink"

    # moving everything from the old folder to the new one, delete the old one
    if [ -d "$symlink.old" ];
    then
      echo "Moving the data from $symlink.old to $real" #DEBUG
      mv -fv "$symlink".old/* $real
      echo "Removing $symlink.old" #DEBUG
      rm -rf "$symlink.old"
    fi

    echo -e "$symlink is now $real\n"
}

tools_init() {
    rm -rfv /var/config/retrodeck/tools/
    mkdir -pv /var/config/retrodeck/tools/
    cp -r /app/retrodeck/tools/* /var/config/retrodeck/tools/
    mkdir -pv /var/config/emulationstation/.emulationstation/custom_systems/tools/
    cp /app/retrodeck/tools-gamelist.xml /var/config/retrodeck/tools/gamelist.xml
}

standalones_init() {
    # This script is configuring the standalone emulators with the default files present in emuconfigs folder
    
    echo "----------------------"
    echo "Initializing standalone emulators"
    echo "----------------------"

    # Yuzu
    echo "----------------------"
    echo "Initializing YUZU"
    echo "----------------------"
    # removing dead symlinks as they were present in a past version
    if [ -d $rdhome/bios/switch ]; then
      find $rdhome/bios/switch -xtype l -exec rm {} \;
    fi
    # initializing the keys folder
    dir_prep "$rdhome/bios/switch/keys" "/var/data/yuzu/keys"
    # initializing the firmware folder
    dir_prep "$rdhome/bios/switch/registered" "/var/data/yuzu/nand/system/Contents/registered"
    # configuring Yuzu
    mkdir -pv /var/config/yuzu/
    cp -fvr $emuconfigs/yuzu/* /var/config/yuzu/
    sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/yuzu/qt-config.ini
    dir_prep "$rdhome/screenshots" "/var/data/yuzu/screenshots"

    # Dolphin
    echo "----------------------"
    echo "Initializing DOLPHIN"
    echo "----------------------"
    mkdir -pv /var/config/dolphin-emu/
    cp -fvr "$emuconfigs/dolphin/"* /var/config/dolphin-emu/
    dir_prep "$rdhome/saves" "/var/data/dolphin-emu/GBA/Saves"
    dir_prep "$rdhome/saves" "/var/data/dolphin-emu/Wii"

    # pcsx2
    echo "----------------------"
    echo "Initializing PCSX2"
    echo "----------------------"
    mkdir -pv /var/config/PCSX2/inis/
    cp -fvr $emuconfigs/PCSX2_ui.ini /var/config/PCSX2/inis/
    sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/PCSX2/inis/PCSX2_ui.ini
    cp -fvr $emuconfigs/GS.ini /var/config/PCSX2/inis/
    cp -fvr $emuconfigs/PCSX2_vm.ini /var/config/PCSX2/inis/
    dir_prep "$rdhome/states" "/var/config/PCSX2/sstates"
    dir_prep "$rdhome/screenshots" "/var/config/PCSX2/snaps"
    dir_prep "$rdhome/.logs" "/var/config/PCSX2/logs"
    dir_prep "$rdhome/bios" "$rdhome/bios/pcsx2/bios"

    # MelonDS
    echo "----------------------"
    echo "Initializing MELONDS"
    echo "----------------------"
    mkdir -pv /var/config/melonDS/
    dir_prep "$rdhome/bios" "/var/config/melonDS/bios"
    cp -fvr $emuconfigs/melonDS.ini /var/config/melonDS/
    # Replace ~/retrodeck with $rdhome as ~ cannot be understood by MelonDS
    sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/melonDS/melonDS.ini

    # CITRA
    echo "----------------------"
    echo "Initializing CITRA"
    echo "----------------------"
    mkdir -pv /var/config/citra-emu/
    cp -fv $emuconfigs/citra-qt-config.ini /var/config/citra-emu/qt-config.ini
    sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/citra-emu/qt-config.ini
    #TODO: do the same with roms folders after new variables is pushed (check even the others qt-emu)
    #But actually everything is always symlinked to retrodeck/roms so it might be not needed
    #sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/citra-emu/qt-config.ini

    # RPCS3
    echo "----------------------"
    echo "Initializing RPCS3"
    echo "----------------------"
    mkdir -pv /var/config/rpcs3/
    cp -fvr $emuconfigs/config.yml /var/config/rpcs3/

    # PICO-8
    # Moved PICO-8 stuff in the finit as only it knows here roms folders is

}

ra_init() {
    dir_prep "$rdhome/bios" "/var/config/retroarch/system"
    mkdir -pv /var/config/retroarch/cores/
    cp /app/share/libretro/cores/* /var/config/retroarch/cores/
    cp -f $emuconfigs/retroarch.cfg /var/config/retroarch/
    cp -f $emuconfigs/retroarch-core-options.cfg /var/config/retroarch/
    #rm -rf $rdhome/bios/bios # in some situations a double bios symlink is created
    sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/retroarch/retroarch.cfg
}

create_lock() {
    # creating RetroDECK's lock file and writing the version number in it
    echo "$version" > "$lockfile"
}

post_update() {
    # post update script
    echo "Executing post-update script"

    # Unhiding downloaded media from the previous versions
    if [ -d "$rdhome/.downloaded_media" ]
    then
      mv -fv "$rdhome/.downloaded_media" "$rdhome/downloaded_media"
    fi

    # Unhiding themes folder from the previous versions
    if [ -d "$rdhome/.themes" ]
    then
      mv -fv "$rdhome/.themes" "$rdhome/themes"
    fi

    # Doing the dir prep as we don't know from which version we came - Remove in a few versions
    dir_prep "$rdhome/downloaded_media" "/var/config/emulationstation/.emulationstation/downloaded_media"
    dir_prep "$rdhome/themes" "/var/config/emulationstation/.emulationstation/themes"
    mkdir -pv $rdhome/.logs #this was added later, maybe safe to remove in a few versions

    # Resetting es_systems, now we need it but in the future I should think a better solution, maybe with sed
    cp -fv /app/retrodeck/es_settings.xml /var/config/emulationstation/.emulationstation/es_settings.xml

    ra_init
    standalones_init
    tools_init

    create_lock
}

start_retrodeck() {
    # normal startup
    echo "Starting RetroDECK v$version"
    emulationstation --home /var/config/emulationstation
}

finit() {
    # Force/First init, depending on the situation

    echo "Executing finit"

    # Internal or SD Card?
    zenity --icon-name=net.retrodeck.retrodeck --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --ok-label "Internal" --cancel-label "SD Card" --text="Welcome to the first configuration of RetroDECK.\nThe setup will be quick but please READ CAREFULLY each message in order to avoid misconfigurations.\n\nWhere do you want your roms folder to be located?"
    if [ $? == 0 ] #yes - Internal
    then
        roms_folder="$rdhome/roms"
    else #no - SD Card
        if [ -d "$sdcard" ];
        then
            roms_folder="$sdcard/retrodeck/roms"
        else
            sdselected=false
            zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="Cancel" --ok-label "Browse" --text="SD Card was not find in the default location.\nPlease choose the SD Card root.\nA retrodeck/roms folder will be created starting from the directory that you selected."
            if [ $? == 1 ] #cancel
            then
              exit 0
            fi
            while [ $sdselected == false ]
            do
              sdcard="$(zenity --file-selection --title="Choose SD Card root" --directory)"
              echo "DEBUG: sdcard=$sdcard, answer=$?"
              zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" --text="Your rom folder will be:\n\n$sdcard/retrodeck/roms\n\nis that ok?"
              if [ $? == 0 ] #yes
              then
                sdselected == true
                roms_folder="$sdcard/retrodeck/roms"
                break
              else
                zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" --text="Do you want to quit?"
                if [ $? == 0 ] # yes, quit
                then
                  exit 0
                fi
              fi
            done
        fi
    fi

    mkdir -pv $roms_folder

    # TODO: after the next update of ES-DE this will not be needed
    #zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --text="EmulationStation will now initialize the system.\nPlease DON'T EDIT THE ROMS LOCATION, just select:\n\nCREATE DIRECTORIES\nYES\nOK\nQUIT\n\nRetroDECK will manage the rest."
    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --text="RetroDECK will now install the needed files.\nPlease wait up to one minute,\nanother message will notify when the process will be finished.\n\nPress OK to continue."

    # Recreating the folder
    rm -rfv /var/config/emulationstation/
    rm -rfv /var/config/retrodeck/tools/
    mkdir -pv /var/config/emulationstation/
    
    # Initializing ES-DE
    # TODO: after the next update of ES-DE this will not be needed - let's test it
    emulationstation --home /var/config/emulationstation --create-system-dirs

    mkdir -pv /var/config/retrodeck/tools/

    #zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --text="RetroDECK will now install the needed files.\nPlease wait up to one minute,\nanother message will notify when the process will be finished.\n\nPress OK to continue."

    # Initializing ROMs folder - Original in retrodeck home (or SD Card)
    dir_prep $roms_folder "/var/config/emulationstation/ROMs"

    mkdir -pv $rdhome/saves
    mkdir -pv $rdhome/states
    mkdir -pv $rdhome/screenshots
    mkdir -pv $rdhome/bios/pico8
    mkdir -pv $rdhome/.logs

    # XMLSTARLET HERE
    cp -fv /app/retrodeck/es_settings.xml /var/config/emulationstation/.emulationstation/es_settings.xml

    # ES-DE preparing themes and scraped folders
    dir_prep "$rdhome/downloaded_media" "/var/config/emulationstation/.emulationstation/downloaded_media"
    dir_prep "$rdhome/themes" "/var/config/emulationstation/.emulationstation/themes"

    # PICO-8
    dir_prep "$roms_folder/pico8" "$rdhome/bios/pico8/bbs/carts" #this is the folder where pico-8 is saving the carts

    ra_init
    standalones_init
    tools_init
    create_lock

    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --text="Initialization completed.\nplease put your roms in:\n\n$roms_folder\n\nand your bioses in\n\n$rdhome/bios\n\nThen start the program again.\nIf you wish to change the roms location, you may use the tool located the tools section of RetroDECK.\n\nIMPORTANT NOTE:\nRetroDECK must be manually added and launched from your Steam Library in order to work correctly.\nMoreover is suggested to use BoilR to automatically add the SteamGridDB images to Steam (this will be automated soon).\nhttps://github.com/PhilipK/BoilR"
    # TODO: Replace the stuff above with BoilR code when ready
}

# Arguments section

for i in "$@"; do
  case $i in
    -h*|--help*)
      echo "RetroDECK v""$(cat /var/config/retrodeck/version)"
      echo "
      Usage:
flatpak run [FLATPAK-RUN-OPTION] net.retrodeck-retrodeck [ARGUMENTS]

Arguments:
    -h, --help        Print this help
    -v, --version     Print RetroDECK version
    --reset           Starts the initial RetroDECK installer (backup your data first!)
    --reset-ra        Resets RetroArch's config to the default values
    --reset-sa        Reset standalone emulator configs to the default values
    --reset-tools     Recreate the tools section

For flatpak run specific options please run: flatpak run -h

https://retrodeck.net
"
      exit
      ;;
    --version*|-v*)
      cat /var/config/retrodeck/version
      exit
      ;;
    --reset-ra*)
      ra_init
      shift # past argument with no value
      ;;
    --reset-sa*)
      standalones_init
      shift # past argument with no value
      ;;
    --reset-tools*)
      tools_init
      shift # past argument with no value
      ;;
    --reset*)
      rm -f "$lockfile"
      shift # past argument with no value
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

# UPDATE TRIGGERED
# if lockfile exists but the version doesn't match
if [ -f "$lockfile" ] && [ "$(cat "$lockfile")" != "$version" ]; 
then
    echo "Lockfile version is "$(cat "$lockfile")" but the actual version is $version"
    post_update
    start_retrodeck
    exit 0
fi

# LOCKFILE REMOVED
# if the lock file doesn't exist at all means that it's a fresh install or a triggered reset
if [ ! -f "$lockfile" ];
then
  echo "Lockfile not found"
  finit
	exit 0
fi

# Normal Startup
start_retrodeck