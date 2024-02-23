#!/bin/bash

hacks_db_setup() {
  crc32_cmd="python3 /app/libexec/crc32.py"

  # "hacks" is the general name which includes ROM Hacks, Homebrew and Ports
  hacks_db_path="$HOME/.var/app/net.retrodeck.retrodeck/data/hacks_metadata.db"

  # Set up hacks database
  declare -g hacks_db_cmd="sqlite3 $hacks_db_path"
  $hacks_db_cmd < <(curl -sL "https://raw.githubusercontent.com/Libretto7/best-romhacks/main/db_setup.sql")
  $hacks_db_cmd "ALTER TABLE bases ADD COLUMN local_path;"
}

db_sanitize() {
  echo "$(echo "$1" | sed -e "s/'/''/g")"
}

check_romhacks_compatibility() {
  # Add paths of locally available base roms to db

  for rom_path in ${roms_folder}/*/*; do
    if [[ "$(basename "$rom_path")" != "systeminfo.txt" ]]; then

      crc32="$($crc32_cmd "$rom_path")"

      $hacks_db_cmd < <(echo "UPDATE bases SET local_path = '""$(db_sanitize "$rom_path")""' WHERE crc32 = '""$crc32""'")
    fi
  done
}

install_romhack() {
  # $1: name of romhack

  hack_name="$1"
  infos=$($hacks_db_cmd "SELECT bases.system,bases.name,bases.local_path \
                         FROM bases JOIN rhacks ON bases.crc32 = rhacks.base_crc32 \
                         WHERE rhacks.name = '""$(db_sanitize "$1")""'")

  IFS='|' read -r system base_name base_local_path <<< $infos

  # Download patchfile
  wget -q "https://github.com/Libretto7/best-romhacks/raw/main/rhacks/$system/$base_name/$hack_name/patch.tar.xz" \
       -O "/tmp/patch.tar.xz"

  # Extract patchfile
  patchfile_name=$(tar -xvf "/tmp/patch.tar.xz" --directory="$roms_folder/$system")

  # Create the hack  
  base_name="$(basename "$base_local_path")"
  ext="$(echo "${base_name##*.}")"
  flips --apply "$roms_folder/$system/$patchfile_name" "$base_local_path" "$roms_folder/$system/$hack_name.$ext" >/dev/null

  # Cleanup
  rm "$roms_folder/$system/$patchfile_name"
}
