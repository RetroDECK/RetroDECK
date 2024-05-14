#!/bin/bash

romhack_downloader_wrapper() {
  python3 /app/libexec/romhack_downloader/main.py --roms-folder "$roms_folder" --saves-folder "$saves_folder" "$@"
}
