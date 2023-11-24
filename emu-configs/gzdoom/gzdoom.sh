#!/bin/bash

LOG_FILE="$rdhome/.logs/gzdoom.log"

# List of IWAD files
IWAD_FILES=("DOOM1.WAD" "DOOM.WAD" "DOOM2.WAD" "DOOM2F.WAD" "DOOM64.WAD" "TNT.WAD"
            "PLUTONIA.WAD" "HERETIC1.WAD" "HERETIC.WAD" "HEXEN.WAD" "HEXDD.WAD"
            "STRIFE0.WAD" "STRIFE1.WAD" "VOICES.WAD" "CHEX.WAD"
            "CHEX3.WAD" "HACX.WAD" "freedoom1.wad" "freedoom2.wad" "freedm.wad" # unlicenced iwads
            "doom_complete.pk3"                                                 # this includes them all
            )

# Convert file name to uppercase for case-insensitive comparison
provided_file=$(echo "$1" | tr '[:lower:]' '[:upper:]')

if [[ " ${IWAD_FILES[@]} " =~ " $provided_file " ]]; then
    gzdoom +fluid_patchset /app/share/sounds/sf2/gzdoom.sf2 -config /var/config/gzdoom/gzdoom.ini -iwad "$1" >> "$LOG_FILE" 2>&1
else
    gzdoom +fluid_patchset /app/share/sounds/sf2/gzdoom.sf2 -config /var/config/gzdoom/gzdoom.ini -file "$1" >> "$LOG_FILE" 2>&1
fi