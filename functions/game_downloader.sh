#!/bin/bash

hacks_db_setup() {
  crc32_cmd="python3 /app/libexec/crc32.py"

  # "hacks" is the general name which includes ROM Hacks, Homebrew and Ports
  hacks_repo_url="https://raw.githubusercontent.com/Libretto7/best-romhacks/main"
  hacks_db_path="$HOME/.var/app/net.retrodeck.retrodeck/data/hacks_metadata.db"

  # set up hacks database
  rm $hacks_db_path
  sqlite3 $hacks_db_path < <(curl -sL "$hacks_repo_url"/db_setup.sql)
  sqlite3 $hacks_db_path < <(echo "ALTER TABLE bases ADD COLUMN local_path;")

  declare -g hacks_db_cmd="sqlite3 $hacks_db_path"
}

check_romhacks_compatibility() {
  # Register all crc32 checksums of potential base ROMs and their paths into the dictionary "base_roms"

  for rom_path in ${roms_folder}/*/*; do
    if [[ "$(basename "$rom_path")" != "systeminfo.txt" ]]; then

      crc32="$($crc32_cmd "$rom_path")"
      sanitized_path="$(echo "$rom_path" | sed -e "s/'/''/g")"

      $hacks_db_cmd < <(echo "UPDATE bases SET local_path = '""$sanitized_path""' WHERE crc32 = '""$crc32""'")
    fi
  done
}

