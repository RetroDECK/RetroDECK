#!/bin/bash

game_downloader_setup() {
  crc32_cmd="python3 /app/libexec/crc32.py"

  # "hacks" is the general name which includes ROM Hacks, Homebrew and Ports
  hacks_repo_url="https://raw.githubusercontent.com/Libretto7/best-romhacks/main"
  hacks_db_path="$HOME/.var/app/net.retrodeck.retrodeck/data/hacks_metadata.db"

  # set up hacks database
  sqlite3 $hacks_db_path < <(curl -sL "$hacks_repo_url"/db_setup.sql)

  declare -g hacks_db_cmd="sqlite3 $hacks_db_path"
}

collect_base_rom_crc32s() {
  # Register all crc32 checksums of potential base ROMs and their paths into the dictionary "base_roms"

  declare -gA base_roms

  for rom in ${roms_folder}/*/*; do
    if [[ "$(basename "$rom")" != "systeminfo.txt" ]]; then
      crc32="$($crc32_cmd "$rom")"
      base_roms["$crc32"]="$rom"
    fi
  done
}
  
build_patches_array() {
  # Set up array that contains the names of patches compatible with available base ROMs
  
  declare -ga compatible_romhack_patches=()
  
  for base_crc32 in "${!base_roms[@]}"; do

    current_base_compatible_patches="$($hacks_db_cmd "SELECT name FROM main WHERE base_crc32 = '""$base_crc32""'")"

    if [[ ! -z "$(printf "$current_base_compatible_patches")" ]]; then # if there are compatible patches for this base
      # Add available patches to array

      # TODO: Remove redundancy within this line. Puts the patches names separated by newlines into an array
      IFS='|' read -r -a array_of_compatible_patches <<< $(echo "$current_base_compatible_patches" | tr '\n' '|')

      for patch in "${array_of_compatible_patches[@]}"; do
        compatible_romhack_patches+=("$patch")
      done
    fi
  done
}

get_compatible_romhacks() {
  # Provide global array "compatible_romhack_patches" which contains names of available, compatible romhack patches

  game_downloader_setup
  collect_base_rom_crc32s
  build_patches_array
}
