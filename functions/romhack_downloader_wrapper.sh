#!/bin/bash

romhack_downloader_wrapper() {
  # expand ~
  eval expanded_roms_folder="$roms_folder"
  
  python3 /app/libexec/romhack_downloader/main.py --roms-folder "$expanded_roms_folder" "$@"
}
