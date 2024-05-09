#!/bin/bash

romhack_downloader_wrapper() {
  # turn ~ into path
  eval expanded_roms_folder="$roms_folder"
  
  cd /app/libexec/romhack_downloader
  python3 main.py --roms-folder "$expanded_roms_folder" "$@"
}
