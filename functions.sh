#!/bin/bash

# THIS IS A CENTRALIZED LOCATION FOR FUNCTIONS, WHICH CAN BE SOURCED WITHOUT RUNNING EXTRA CODE. EXISTING USE OF THESE FUNCTIONS CAN BE REFACTORED TO HERE.

# These functions are original to this file

#=================
# FUNCTION SECTION
#=================

browse() {
    # This function browses for a directory and returns the path chosen
    # USAGE: path_to_be_browsed_for=$(browse $action_text)

    path_selected=false

    while [ $path_selected == false ]
    do
        target="$(zenity --file-selection --title="Choose $1" --directory)"
        if [ $? == 0 ] #yes
        then
            zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
            --text="Directory $target chosen, is this correct?"
            if [ $? == 0 ]
            then
                path_selected=true
                echo $target
                break
            fi
        else
            zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
            --text="No directory selected. Do you want to return to the main menu?"
            if [ $? == 1 ]
            then
                configurator_welcome_dialog
            fi
        fi
    done
}

verify_space() {
    # Function used for verifying adequate space before moving directories around
    # USAGE: verify_space $source_dir $dest_dir
    # Function returns "true" if there is enough space, "false" if there is not

    source_size=$(du -sk /home/deck/retrodeck | awk '{print $1}')
    source_size=$((source_size+(source_size/10))) # Add 10% to source size for safety
    dest_avail=$(df -k --output=avail $2 | tail -1)

    if [[ $source_size -ge $dest_avail ]]; then
        echo "false"
    else
        echo "true"
    fi
}

move() {
    # Function to move a directory from one parent to another
    # USAGE: move $source_dir $dest_dir

    if [[ $(verify_space $1 $2) ]]; then
        (
            if [[ ! -d $2 ]]; then # Create destination directory if it doesn't already exist
                debug_dialog "mkdir -pv $2"
            fi
            debug_dialog "mv -v -t $2 $1"
        ) |
        zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close --width=800 --height=600 \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Configurator Utility - Move in Progress" \
        --text="Moving directory $1 to new location of $2, please wait."

    else
        zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --width=800 --height=600 \
        --title "RetroDECK Configurator Utility - Move Directories" \
        --text="The destination directory you have selected does not have enough free space for the files you are trying to move.\n\nPlease select a new destination or free up some space."

        configurator_move_dialog
    fi
}

set_setting() {
# Function for editing settings
# USAGE: set_setting $setting_file $setting_name $new_setting_value $system (needed as different systems use different config file syntax)
# NOTES: Citra, Yuzu and RPCS3 have special conditions, see comments below

case $4 in

    "retrodeck" )
        sed -i "s%$2=.*%$2=$3%" $1
        ;;

    "retroarch" )
        sed -i "s%$2 = \".*\"%$2 = \"$3\"%" $1
        ;;

    "dolphin" )
        sed -i "s%$2 = .*%$2 = $3%" $1
        ;;

    "duckstation" )
        sed -i "s%$2 = .*%$2 = $3%" $1
        ;;

    "pcsx2" )
        sed -i "s%$2 = .*%$2 = $3%" $1
        ;;

    "ppsspp" )
        sed -i "s%$2 = .*%$2 = $3%" $1
        ;;

    "rpcs3" ) # This does not currently work for settings with a $ in them
        sed -i "s%$2: .*%$2: $3%" $1
        ;;

    "yuzu" )
        yuzu_setting=$(sed -e 's%\\%\\\\%g' <<< "$2") # Acommodate backslashes in setting name
        sed -i "s%$yuzu_setting=.*%$yuzu_setting=$3%" $1
        ;;

    "citra" )
        citra_setting=$(sed -e 's%\\%\\\\%g' <<< "$2") # Acommodate backslashes in setting name
        sed -i "s%$citra_setting=.*%$citra_setting=$3%" $1
        ;;

    "melonds" )
        sed -i "s%$2=.*%$2=$3%" $1
        ;;

    "xemu" )
        sed -i "s%$2 = .*%$2 = $3%" $1
        ;;

    "emulationstation" )
        sed -i "s%$2\" \" value=\".*\"%$2\" \" value=\"$3\"" $1
        ;;

esac
}

get_setting() {
# Function for getting the current value of a setting from a config file
# USAGE: get_setting $setting_file $setting_name $system (needed as different systems use different config file syntax)

case $3 in

    "retrodeck" )
        echo $(grep "$2" $1 | grep -o -P "(?<=$2=).*")
        ;;

    "retroarch" )
        echo $(grep "$2" $1 | grep -o -P "(?<=$2 = \").*(?=\")")
        ;;

    "dolphin" ) # Use quotes when passing setting_name, as this config file contains special characters
        echo $(grep "$2" $1 | grep -o -P "(?<=$2 = ).*")
        ;;

    "duckstation" )
        echo $(grep "$2" $1 | grep -o -P "(?<=$2 = ).*")
        ;;

    "pcsx2" )
        echo $(grep "$2" $1 | grep -o -P "(?<=$2 = ).*")
        ;;

    "ppsspp" ) # Use quotes when passing setting_name, as this config file contains spaces
        echo $(grep "$2" $1 | grep -o -P "(?<=$2 = ).*")
        ;;

    "rpcs3" ) # Use quotes when passing setting_name, as this config file contains special characters and spaces
        echo $(grep "$2" $1 | grep -o -P "(?<=$2: ).*")
        ;;

    "yuzu" ) # Use quotes when passing setting_name, as this config file contains special characters
        yuzu_setting=$(sed -e 's%\\%\\\\%g' <<< "$2") # Accomodate for backslashes in setting names
        echo $(grep "$yuzu_setting" $1 | grep -o -P "(?<=$yuzu_setting=).*")
        ;;

    "citra" ) # Use quotes when passing setting_name, as this config file contains special characters
        citra_setting=$(sed -e 's%\\%\\\\%g' <<< "$2") # Accomodate for backslashes in setting names
        echo $(grep "$citra_setting" $1 | grep -o -P "(?<=$citra_setting=).*")
        ;;

    "melonds" )
        echo $(grep "$2" $1 | grep -o -P "(?<=$2=).*")
        ;;

    "xemu" )
        echo $(grep "$2" $1 | grep -o -P "(?<=$2 = ).*")
        ;;

    "emulationstation" )
        echo $(grep "$2" $1 | grep -o -P "(?<=$2\" value=\").*(?=\")")
        ;;

esac
}

yuzu_init() {
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
    dir_prep "$rdhome/.logs/yuzu" "/var/data/yuzu/log"
    mkdir -pv /var/config/yuzu/
    cp -fvr $emuconfigs/yuzu/* /var/config/yuzu/
    sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/yuzu/qt-config.ini
    dir_prep "$rdhome/screenshots" "/var/data/yuzu/screenshots"
}

dolphin_init() {
  echo "----------------------"
    echo "Initializing DOLPHIN"
    echo "----------------------"
    mkdir -pv /var/config/dolphin-emu/
    cp -fvr "$emuconfigs/dolphin/"* /var/config/dolphin-emu/
    sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/dolphin-emu/Dolphin.ini
    dir_prep "$rdhome/saves/gc/dolphin/EUR" "/var/data/dolphin-emu/GC/EUR"
    dir_prep "$rdhome/saves/gc/dolphin/USA" "/var/data/dolphin-emu/GC/USA"
    dir_prep "$rdhome/saves/gc/dolphin/JAP" "/var/data/dolphin-emu/GC/JAP"
    dir_prep "$rdhome/screenshots" "/var/data/dolphin-emu/ScreenShots"
    dir_prep "$rdhome/states" "/var/data/dolphin-emu/StateSaves"
    dir_prep "$rdhome/saves/wii/dolphin" "/var/data/dolphin-emu/Wii/"
}

pcsx2_init() {
  echo "----------------------"
    echo "Initializing PCSX2"
    echo "----------------------"
    mkdir -pv "/var/config/PCSX2/inis"
    mkdir -pv "$rdhome/saves/ps2/pcsx2/memcards"
    mkdir -pv "$rdhome/states/ps2/pcsx2"
    cp -fvr $emuconfigs/PCSX2/* /var/config/PCSX2/inis/
    sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/PCSX2/inis/PCSX2_ui.ini
    sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/PCSX2/inis/PCSX2.ini
}

melonds_init() {
  echo "----------------------"
    echo "Initializing MELONDS"
    echo "----------------------"
    mkdir -pv /var/config/melonDS/
    mkdir -pv "$rdhome/saves/nds/melonds"
    mkdir -pv "$rdhome/states/nds/melonds"
    dir_prep "$rdhome/bios" "/var/config/melonDS/bios"
    cp -fvr $emuconfigs/melonDS.ini /var/config/melonDS/
    # Replace ~/retrodeck with $rdhome as ~ cannot be understood by MelonDS
    sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/melonDS/melonDS.ini
}

citra_init() {
  echo "------------------------"
    echo "Initializing CITRA"
    echo "------------------------"
    mkdir -pv /var/config/citra-emu/
    mkdir -pv "$rdhome/saves/n3ds/citra/nand/"
    mkdir -pv "$rdhome/saves/n3ds/citra/sdmc/"
    dir_prep "$rdhome/.logs/citra" "/var/data/citra-emu/log"
    cp -fv $emuconfigs/citra-qt-config.ini /var/config/citra-emu/qt-config.ini
    sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/citra-emu/qt-config.ini
    #TODO: do the same with roms folders after new variables is pushed (check even the others qt-emu)
    #But actually everything is always symlinked to retrodeck/roms so it might be not needed
    #sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/citra-emu/qt-config.ini
}

rpcs3_init() {
  echo "------------------------"
    echo "Initializing RPCS3"
    echo "------------------------"
    mkdir -pv /var/config/rpcs3/
    cp -fvr $emuconfigs/rpcs3/* /var/config/rpcs3/
    sed -i 's#/home/deck/retrodeck#'$rdhome'#g' /var/config/rpcs3/vfs.yml
}

xemu_init() {
  echo "------------------------"
    echo "Initializing XEMU"
    echo "------------------------"
    mkdir -pv $rdhome/saves/xbox/xemu/
    cp -fv $emuconfigs/xemu.toml /var/data/xemu/xemu.toml
    sed -i 's#/home/deck/retrodeck#'$rdhome'#g' /var/data/xemu/xemu.toml
    # Preparing HD dummy Image if the image is not found
    if [ ! -f $rdhome/bios/xbox_hdd.qcow2 ]
    then
      wget "https://github.com/mborgerson/xemu-hdd-image/releases/latest/download/xbox_hdd.qcow2.zip" -P $rdhome/bios/
      unzip $rdhome/bios/xbox_hdd.qcow2.zip $rdhome/bios/
      rm -rfv $rdhome/bios/xbox_hdd.qcow2.zip
    fi
}

ppssppsdl_init() {
  echo "------------------------"
    echo "Initializing PPSSPPSDL"
    echo "------------------------"
    mkdir -p /var/config/ppsspp/PSP/SYSTEM/
    cp -fv $emuconfigs/ppssppsdl/* /var/config/ppsspp/PSP/SYSTEM/
    sed -i 's#/home/deck/retrodeck#'$rdhome'#g' /var/config/ppsspp/PSP/SYSTEM/ppsspp.ini
}

duckstation_init() {
  echo "------------------------"
    echo "Initializing DUCKSTATION"
    echo "------------------------"
    mkdir -p /var/config/duckstation/
    cp -fv $emuconfigs/duckstation/* /var/config/duckstation
    sed -i 's#/home/deck/retrodeck/bios#'$rdhome/bios'#g' /var/config/ppsspp/PSP/SYSTEM/settings.ini
}

standalones_init() {
    # This script is configuring the standalone emulators with the default files present in emuconfigs folder

    echo "----------------------"
    echo "Initializing standalone emulators"
    echo "----------------------"

    yuzu_init
    citra_init
    dolphin_init
    melonds_init
    pcsx2_init
    ppssppsdl_init
    rpcs3_init
    xemu_init
    duckstation_init
}

#=========================
# REUSABLE DIALOGS SECTION
#=========================

debug_dialog() {
    # This function is for displaying commands run by the Configurator without actually running them
    # USAGE: debug_dialog "command"

    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --width=800 --height=600 \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility - Debug Dialog" \
    --text="$1"
}

configurator_process_complete_dialog() {
    # This dialog shows when a process is complete.
    # USAGE: configurator_process_complete_dialog "process text"
    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Quit" --extra-button="OK" --width=800 --height=600 \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility - Process Complete" \
    --text="The process of $1 is now complete.\n\nYou may need to quit and restart RetroDECK for your changes to take effect\n\nClick OK to return to the Main Menu or Quit to return to RetroDECK."

    if [ ! $? == 0 ] # OK button clicked
    then
        configurator_welcome_dialog
    fi
}

configurator_generic_dialog() {
    # This dialog is for showing temporary messages before another process happens.
    # USAGE: configurator_generid_dialog "info text"
    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --width=800 --height=600 \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility" \
    --text="$1"
}

configurator_destination_choice_dialog() {
    # This dialog is for making things easy for new uers to move files to common locations. Gives the options for "Internal", "SD Card" and "Custom" locations.
    # USAGE: $(configurator_destination_choice_dialog "folder being moved" "action text")
    # This function returns one of the values: "Back" "Internal Storage" "SD Card" "Custom Location"
    choice=$(zenity --title "RetroDECK Configurator Utility - Moving $1 folder" --info --no-wrap --ok-label="Back" --extra-button="Internal Storage" --extra-button="SD Card" --extra-button="Custom Location" --width=800 --height=600 \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --text="$2")

    echo $choice
}


#=========================
# LEGACY FUNCTIONS SECTION
#=========================

# These functions were pulled from retrodeck.sh or global.sh and should be consolidated eventually

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
    cp -rfv /app/retrodeck/tools/* /var/config/retrodeck/tools/
    mkdir -pv /var/config/emulationstation/.emulationstation/custom_systems/tools/
    rm -rfv /var/config/retrodeck/tools/gamelist.xml
    cp -fv /app/retrodeck/tools-gamelist.xml /var/config/retrodeck/tools/gamelist.xml
}

ra_init() {
    dir_prep "$rdhome/bios" "/var/config/retroarch/system"
    dir_prep "$rdhome/.logs/retroarch" "/var/config/retroarch/logs"
    mkdir -pv /var/config/retroarch/cores/
    cp /app/share/libretro/cores/* /var/config/retroarch/cores/
    cp -fv $emuconfigs/retroarch.cfg /var/config/retroarch/
    cp -fv $emuconfigs/retroarch-core-options.cfg /var/config/retroarch/
    #rm -rf $rdhome/bios/bios # in some situations a double bios symlink is created
    sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/retroarch/retroarch.cfg

    # PPSSPP
    echo "--------------------------------"
    echo "Initializing PPSSPP_LIBRETRO"
    echo "--------------------------------"
    if [ -d $rdhome/bios/PPSSPP/flash0/font ]
    then
      mv -fv $rdhome/bios/PPSSPP/flash0/font $rdhome/bios/PPSSPP/flash0/font.bak
    fi
    mkdir -p $rdhome/bios/PPSSPP
    #if [ ! -f "$rdhome/bios/PPSSPP/ppge_atlas.zim" ]
    #then
      wget "https://github.com/hrydgard/ppsspp/archive/refs/heads/master.zip" -P $rdhome/bios/PPSSPP
      unzip "$rdhome/bios/PPSSPP/master.zip" -d $rdhome/bios/PPSSPP/
      mv "$rdhome/bios/PPSSPP/ppsspp-master/assets/"* "$rdhome/bios/PPSSPP/"
      rm -rfv "$rdhome/bios/PPSSPP/master.zip"
      rm -rfv "$rdhome/bios/PPSSPP/ppsspp-master"
    #fi
    if [ -d $rdhome/bios/PPSSPP/flash0/font.bak ]
    then
      mv -fv $rdhome/bios/PPSSPP/flash0/font.bak $rdhome/bios/PPSSPP/flash0/font
    fi


    # MSX / SVI / ColecoVision / SG-1000
    echo "-----------------------------------------------------------"
    echo "Initializing MSX / SVI / ColecoVision / SG-1000 LIBRETRO"
    echo "-----------------------------------------------------------"
    wget "http://bluemsx.msxblue.com/rel_download/blueMSXv282full.zip" -P $rdhome/bios/MSX
    unzip "$rdhome/bios/MSX/blueMSXv282full.zip" $rdhome/bios/MSX
    mv -rfv $rdhome/bios/MSX/Databases $rdhome/bios/Databases
    mv -rfv $rdhome/bios/MSX/Machines $rdhome/bios/Machines
    rm -rfv $rdhome/bios/MSX

}

create_lock() {
    # creating RetroDECK's lock file and writing the version in the config file
    version=$hard_version
    touch "$lockfile"
    conf_write
}

post_update() {
    # post update script
    echo "Executing post-update script"

    # Finding existing ROMs folder
    if [ -d "$default_sd/retrodeck" ]
    then
      # ROMs on SD card
      roms_folder="$default_sd/retrodeck/roms"
    else
      # ROMs on Internal
      roms_folder="$HOME/retrodeck/roms"
    fi
    echo "ROMs folder found at $roms_folder"

    # Unhiding downloaded media from the previous versions
    if [ -d "$rdhome/.downloaded_media" ]
    then
      mv -fv "$rdhome/.downloaded_media" "$media_folder"
    fi

    # Unhiding themes folder from the previous versions
    if [ -d "$rdhome/.themes" ]
    then
      mv -fv "$rdhome/.themes" "$themes_folder"
    fi

    # Doing the dir prep as we don't know from which version we came
    dir_prep "$media_folder" "/var/config/emulationstation/.emulationstation/downloaded_media"
    dir_prep "$themes_folder" "/var/config/emulationstation/.emulationstation/themes"
    mkdir -pv $rdhome/.logs #this was added later, maybe safe to remove in a few versions


    # Resetting es_settings, now we need it but in the future I should think a better solution, maybe with sed
    cp -fv /app/retrodeck/es_settings.xml /var/config/emulationstation/.emulationstation/es_settings.xml


    # 0.4 -> 0.5
    # Perform save and state migration if needed

    # Moving PCSX2 Saves
    mv -fv /var/config/PCSX2/sstates/* $rdhome/states/ps2/pcsx2
    mv -fv /var/config/PCSX2/memcards/* $rdhome/saves/ps2/memcards

    versionwheresaveschanged="0.4.5b" # Hardcoded break point between unsorted and sorted saves

    if [[ $(sed -e "s/\.//g" <<< $hard_version) > $(sed -e "s/\.//g" <<< $versionwheresaveschanged) ]] && [[ ! $(sed -e "s/\.//g" <<< $hard_version) == $(sed -e "s/\.//g" <<< $version) ]]; then # Check if user is upgrading from the version where save organization was changed. Try not to reuse this, it things 0.4.5b is newer than 0.4.5
        migration_logfile=$rdhome/.logs/savemove_"$(date +"%Y_%m_%d_%I_%M_%p").log"
        save_backup_file=$rdhome/savebackup_"$(date +"%Y_%m_%d_%I_%M_%p").zip"
        state_backup_file=$rdhome/statesbackup_"$(date +"%Y_%m_%d_%I_%M_%p").zip"

        zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
            --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
            --title "RetroDECK" \
            --text="You are updating to a version of RetroDECK where save file locations have changed!\n\nYour existing files will be backed up for safety and then sorted automatically.\n\nIf a file cannot be sorted automatically it will remain where it is for manual sorting.\n\nPLEASE BE PATIENT! This process can take several minutes if you have a large ROM library."

        allgames=($(find "$roms_folder" -maxdepth 2 -mindepth 2 ! -name "systeminfo.txt" ! -name "systems.txt" ! -name "gc" ! -name "n3ds" ! -name "nds" ! -name "wii" ! -name "xbox" ! -name "*^*" | sed -e "s/ /\^/g")) # Build an array of all games and multi-disc-game-containing folders, adding whitespace placeholder

        allsaves=($(find "$saves_folder" -mindepth 1 -maxdepth 1 -name "*.*" ! -name "gc" ! -name "n3ds" ! -name "nds" ! -name "wii" ! -name "xbox"  | sed -e "s/ /\^/g")) # Build an array of all save files, ignoring standalone emulator sub-folders, adding whitespace placeholder

        allstates=($(find "$states_folder" -mindepth 1 -maxdepth 1 -name "*.*" ! -name "gc" ! -name "n3ds" ! -name "nds" ! -name "wii" ! -name "xbox"  | sed -e "s/ /\^/g")) # Build an array of all state files, ignoring standalone emulator sub-folders, adding whitespace placeholder

        totalsaves=${#allsaves[@]}
        totalstates=${#allstates[@]}
        filesleft=
        current_dest_folder=
        gamestoskip=

        tar -C $rdhome -czf $save_backup_file saves # Backup save directory for safety
        echo "Saves backed up to" $save_backup_file >> $migration_logfile
        tar -C $rdhome -czf $state_backup_file states # Backup state directory for safety
        echo "States backed up to" $state_backup_file >> $migration_logfile

        (
        movefile() { # Take matching save and rom files and sort save into appropriate system folder
            echo "# $filesleft $currentlybeingmoved remaining..." # These lines update the Zenity progress bar
            progress=$(( 100 - (( 100 / "$totalfiles" ) * "$filesleft" )))
            echo $progress
            filesleft=$((filesleft-1))
            if [[ ! " ${gamestoskip[*]} " =~ " ${1} " ]]; then # If the current game name exists multiple times in array ie. /roms/snes/Mortal Kombat 3.zip and /roms/genesis/Mortal Kombat 3.zip, skip and alert user to sort manually
                game=$(sed -e "s/\^/ /g" <<< "$1") # Remove whitespace placeholder
                gamebasename=$(basename "$game" | sed -e 's/\..*//') # Extract pure file name ie. /roms/snes/game1.zip becomes game1
                systemdir="$(basename "$(dirname "$1")")" # Extract parent directory identifying system ROM belongs to
                matches=($(find "$roms_folder" -maxdepth 2 -mindepth 2 -name "$gamebasename"".*" | sed -e 's/ /^/g' | sed -e 's/\..*//')) # Search for multiple instances of pure game name, adding to skip list if found
                if [[ ${#matches[@]} -gt 1 ]]; then
                    echo "ERROR: Multiple ROMS found with name:" $gamebasename "Please sort saves and states for these ROMS manually" >> $migration_logfile
                    gamestoskip+=("$1")
                    return
                fi
                echo "INFO: Examining ROM file:" "$game" >> $migration_logfile
                echo "INFO: System detected as" $systemdir >> $migration_logfile
                sosfile=$(sed -e "s/\^/ /g" <<< "$2") # Remove whitespace placeholder from s-ave o-r s-tate file
                sospurebasename="$(basename "$sosfile")" # Extract pure file name ie. /saves/game1.sav becomes game1
                echo "INFO: Current save or state being examined for match:" $sosfile >> $migration_logfile
                echo "INFO: Matching save or state" $sosfile "and game" $game "found." >> $migration_logfile
                echo "INFO: Moving save or state to" $current_dest_folder"/"$systemdir"/"$sosbasename >> $migration_logfile
                if [[ ! -d $current_dest_folder"/"$systemdir ]]; then # If system directory doesn't exist for save yet, create it
                    echo "WARNING: Creating missing system directory" $current_dest_folder"/"$systemdir
                    mkdir $current_dest_folder/$systemdir
                fi
                mv "$sosfile" -t $current_dest_folder/$systemdir # Move save to appropriate system directory
                return
            else
                echo "WARNING: Game with name" "$(basename "$1" | sed -e "s/\^/ /g")" "already found. Skipping to next game..." >> $migration_logfile # Inform user of game being skipped due to duplicate ROM names
            fi
        }

        find "$roms_folder" -mindepth 2 -maxdepth 2 -name "*\^*" -exec echo "ERROR: Game named" {} "found, please move save manually" \; >> $migration_logfile # Warn user if any of their files have the whitespace replacement character used by the script

        totalfiles=$totalsaves #set variables for save file migration
        filesleft=$totalsaves
        currentlybeingmoved="saves"
        current_dest_folder=$saves_folder

        for i in "${allsaves[@]}"; do # For each save file, compare to every ROM file name looking for a match
            found=
            currentsave=($(basename "$i" | sed -e 's/\..*//')) # Extract pure file name ie. /saves/game1.sav becomes game1
            for j in "${allgames[@]}"; do
                currentgame=($(basename "$j" | sed -e 's/\..*//')) # Extract pure file name ie. /roms/snes/game1.zip becomes game1
                [[ $currentgame == $currentsave ]] && { found=1; break; } # If names match move to next stage, otherwise skip
            done
            [[ -n $found ]] && movefile $j $i || echo "ERROR: No ROM match found for save file" $i | sed -e 's/\^/ /g' >> $migration_logfile # If a match is found, run movefile() otherwise warn user of stranded save file
        done

        totalfiles=$totalstates #set variables for state file migration
        filesleft=$totalstates
        currentlybeingmoved="states"
        current_dest_folder=$states_folder

        for i in "${allstates[@]}"; do # For each state file, compare to every ROM file name looking for a match
            found=
            currentstate=($(basename "$i" | sed -e 's/\..*//')) # Extract pure file name ie. /states/game1.sav becomes game1
            for j in "${allgames[@]}"; do
                currentgame=($(basename "$j" | sed -e 's/\..*//')) # Extract pure file name ie. /roms/snes/game1.zip becomes game1
                [[ $currentgame == $currentstate ]] && { found=1; break; } # If names match move to next stage, otherwise skip
            done
            [[ -n $found ]] && movefile $j $i || echo "ERROR: No ROM match found for state file" $i | sed -e 's/\^/ /g' >> $migration_logfile # If a match is found, run movefile() otherwise warn user of stranded state file
        done

        ) |
        zenity --progress \
        --icon-name=net.retrodeck.retrodeck \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title="Processing Files" \
        --text="# files remaining..." \
        --percentage=0 \
        --no-cancel \
        --auto-close

        if [[ $(cat $migration_logfile | grep "ERROR" | wc -l) -eq 0 ]]; then
          zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK" \
          --text="The migration process has sorted all of your files automatically.\n\nEverything should be working normally, if you experience any issues please check the RetroDECK wiki or contact us directly on the Discord."

        else
          cat $migration_logfile | grep "ERROR" > "$rdhome/manual_sort_needed.log"
          zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
          --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
          --title "RetroDECK" \
          --text="The migration process was unable to sort $(cat $migration_logfile | grep "ERROR" | wc -l) files automatically.\n\nThese files will need to be moved manually to their new locations, find more detail on the RetroDECK wiki.\n\nA log of the files that need manual sorting can be found at $rdhome/manual_sort_needed.log"
        fi

    else
      echo "Version" $version "is after the save and state organization was changed, no need to sort again"
    fi

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

browse(){
  # Function for browsing the sd card
  path_selected=false
      while [ $path_selected == false ]
      do
        sdcard="$(zenity --file-selection --title="Choose retrodeck folder location" --directory)"
        echo "Path choosed: $sdcard, answer=$?"
        zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" \
        --cancel-label="No" \
        --ok-label "Yes" \
        --text="Your rom folder will be:\n\n$sdcard/retrodeck/roms\n\nis that ok?"
        if [ $? == 0 ] #yes
        then
          path_selected == true
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
}

finit() {
    # Force/First init, depending on the situation

    echo "Executing finit"

    # Internal or SD Card?
    choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" \
    --ok-label "Cancel" \
    --extra-button "Internal" \
    --extra-button "SD Card" \
    --text="Welcome to the first configuration of RetroDECK.\nThe setup will be quick but please READ CAREFULLY each message in order to avoid misconfigurations.\n\nWhere do you want your roms folder to be located?" )
    echo "Choice is $choice"

    case $choice in

    "" ) # Cancel or X button quits
      echo "Now quitting"
      kill $$
    ;;

    "Internal" ) # Internal
      echo "Internal selected"
      roms_folder="$rdhome/roms"
    ;;

    "SD Card" )
      echo "SD Card selected"
      if [ ! -d "$sdcard" ] # SD Card path is not existing
      then
        echo "Error: SD card not found"
        zenity --question --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK" --cancel-label="Cancel" \
        --ok-label "Browse" \
        --text="SD Card was not find in the default location.\nPlease choose the SD Card root.\nA retrodeck/roms folder will be created starting from the directory that you selected."
        browse # Calling the browse function
      else
        roms_folder="$sdcard/retrodeck/roms"    # sdcard variable is correct as its given by browse function
        echo "ROMs folder = $roms_folder"
      fi
    ;;

    #"Advanced" ) # Browse + not found fallback
    #  echo "Advanced"
    #  advanced
    #;;

    esac

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

    zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK" \
    --text="Installation completed.\nPlease put your roms in:\n\n$roms_folder\n\nand your bioses in\n\n$rdhome/bios\n\nThen start the program again.\nIf you wish to change the roms location, you may use the tool located the tools section of RetroDECK.\n\nIMPORTANT NOTES:\n- RetroDECK must be manually added and launched from your Steam Library in order to work correctly.\n- It's recommended to use the 'RetroDECK Offical Controller Config' from Steam (under community layouts).\n- It's suggested to use BoilR to automatically add the SteamGridDB images to Steam (this will be automated soon).\nhttps://github.com/PhilipK/BoilR"
    # TODO: Replace the stuff above with BoilR code when ready
}

conf_write() {
  # writes the variables in the retrodeck config file

  echo "DEBUG: printing the config file content before writing it:"
  cat "$rd_conf"
  echo ""

  echo "Writing the config file: $rd_conf"

  # TODO: this can be optimized with a while and a list of variables to check
  if [ ! -z "$version" ] #if the variable is not null then I update it
  then
    sed -i "s%version=.*%version=$version%" "$rd_conf"
  fi

  if [ ! -z "$rdhome" ]
  then
    sed -i "s%rdhome=.*%rdhome=$rdhome%" "$rd_conf"
  fi

  if [ ! -z "$roms_folder" ]
  then
    sed -i "s%roms_folder=.*%roms_folder=$roms_folder%" "$rd_conf"
  fi

  if [ ! -z "$saves_folder" ]
  then
    sed -i "s%saves_folder=.*%saves_folder=$saves_folder%" "$rd_conf"
  fi

  if [ ! -z "$states_folder" ]
  then
    sed -i "s%states_folder=.*%states_folder=$states_folder%" "$rd_conf"
  fi

  if [ ! -z "$bios_folder" ]
  then
    sed -i "s%bios_folder=.*%bios_folder=$bios_folder%" "$rd_conf"
  fi

  if [ ! -z "$media_folder" ]
  then
    sed -i "s%media_folder=.*%media_folder=$media_folder%" "$rd_conf"
  fi

  if [ ! -z "$themes_folder" ]
  then
    sed -i "s%themes_folder=.*%themes_folder=$themes_folder%" "$rd_conf"
  fi

  if [ ! -z "$sdcard" ]
  then
    sed -i "s%sdcard=.*%sdcard=$sdcard%" "$rd_conf"
  fi
  echo "DEBUG: New contents:"
  cat "$rd_conf"
  echo ""

}