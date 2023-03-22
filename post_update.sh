#!/bin/bash

post_update() {

  # post update script
  echo "Executing post-update script"

  local prev_version=$(sed -e 's/[\.a-z]//g' <<< $version)

  if [[ $prev_version -le "050" ]]; then # If updating from prior to save sorting change at 0.5.0b

    # Finding existing ROMs folder
    if [ -d "$default_sd/retrodeck" ]
    then
      # ROMs on SD card
      roms_folder="$default_sd/retrodeck/roms"
      if [[ ! -L $rdhome && ! -L $rdhome/roms ]]; then # Add a roms folder symlink back to ~/retrodeck if missing, to fix things like PS2 autosaves until user migrates whole ~retrodeck directory
        ln -s $roms_folder $rdhome/roms
      fi
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

    # Moving Citra saves from legacy location to 0.5.0b structure

    mv -fv $rdhome/saves/Citra/* $rdhome/saves/n3ds/citra
    rmdir $rdhome/saves/Citra # Old folder cleanup

    versionwheresaveschanged="0.4.5b" # Hardcoded break point between unsorted and sorted saves

    if [[ $(sed -e "s/\.//g" <<< $hard_version) > $(sed -e "s/\.//g" <<< $versionwheresaveschanged) ]] && [[ ! $(sed -e "s/\.//g" <<< $version) > $(sed -e "s/\.//g" <<< $versionwheresaveschanged) ]]; then # Check if user is upgrading from the version where save organization was changed. Try not to reuse this, it things 0.4.5b is newer than 0.4.5
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
  fi

  # Everything within the following ( <code> ) will happen behind the Zenity dialog. The save migration was a long process so it has its own individual dialogs.

  (
  if [[ $prev_version -le "062" ]]; then
    # In version 0.6.2b, the following changes were made that required config file updates/reset:
    # - Primehack preconfiguration completely redone. "Stop emulation" hotkey set to Start+Select, Xbox and Nintendo keymap profiles were created, Xbox set as default.
    # - Duckstation save and state locations were dir_prep'd to the rdhome/save and /state folders, which was not previously done. Much safer now!
    # - Fix PICO-8 folder structure. ROM and save folders are now sane and binary files will go into ~/retrodeck/bios/pico-8/

    rm -rf /var/config/primehack # Purge old Primehack config files. Saves are safe as they are linked into /var/data/primehack.
    primehack_init

    dir_prep "$rdhome/saves/duckstation" "/var/data/duckstation/memcards"
    dir_prep "$rdhome/states/duckstation" "/var/data/duckstation/savestates"

    mv "$bios_folder/pico8" "$bios_folder/pico8_olddata" # Move legacy (and incorrect / non-functional ) PICO-8 location for future cleanup / less confusion
    dir_prep "$bios_folder/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed
    dir_prep "$roms_folder/pico8" "$bios_folder/pico-8/carts" # Symlink default game location to RD roms for cleanliness (this location is overridden anyway by the --root_path launch argument anyway)
    dir_prep "$bios_folder/pico-8/cdata" "$saves_folder/pico-8" # PICO-8 saves folder
  fi
  if [[ $prev_version -le "063" ]]; then
    # In version 0.6.2b, the following changes were made that required config file updates/reset:
    # - Put Dolphin and Primehack save states in different folders inside $rd_home/states
    # - Fix symlink to hard-coded PICO-8 config folder (dir_prep doesn't like ~)
    # - Overwrite Citra and Yuzu configs, as controller mapping was broken due to emulator updates.
    
    dir_prep "$rdhome/states/dolphin" "/var/data/dolphin-emu/StateSaves"
    dir_prep "$rdhome/states/primehack" "/var/data/primehack/StateSaves"

    rm -rf "$HOME/~/" # Remove old incorrect location from 0.6.2b
    rm -f "$HOME/.lexaloffle/pico-8" # Remove old symlink to prevent recursion
    dir_prep "$bios_folder/pico-8" "$HOME/.lexaloffle/pico-8" # Store binary and config files together. The .lexaloffle directory is a hard-coded location for the PICO-8 config file, cannot be changed

    cp -fv $emuconfigs/citra/qt-config.ini /var/config/citra-emu/qt-config.ini
    sed -i 's#RETRODECKHOMEDIR#'$rdhome'#g' /var/config/citra-emu/qt-config.ini
    cp -fvr $emuconfigs/yuzu/* /var/config/yuzu/
    sed -i 's#RETRODECKHOMEDIR#'$rdhome'#g' /var/config/yuzu/qt-config.ini

    # Remove unneeded tools folder, as location has changed to RO space
    rm -rfv /var/config/retrodeck/tools/
  fi

  # The following commands are run every time.

  update_rd_conf
  ) |
  zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Finishing Upgrade" \
  --text="RetroDECK is finishing the upgrade process, please wait."
  source $rd_conf # Load new config file variables
  create_lock
}