#!/bin/bash

check_bios_files() {
  # This function validates all the BIOS files listed in the $bios_checklist and adds the results to an array called $bios_checked_list which can be used elsewhere
  # There is a "basic" and "expert" mode which outputs different levels of data
  # USAGE: check_bios_files "mode"
  
  if [[ -f "$godot_bios_files_checked" ]]; then
    rm -f "$godot_bios_files_checked" # Godot data transfer temp files
  fi
  touch "$godot_bios_files_checked"

  while IFS="^" read -r bios_file bios_subdir bios_hash bios_system bios_desc
    do
      bios_file_found="No"
      bios_hash_matched="No"
      if [[ -f "$bios_folder/$bios_subdir$bios_file" ]]; then
        bios_file_found="Yes"
        if [[ $bios_hash == "Unknown" ]]; then
          bios_hash_matched="Unknown"
        elif [[ $(md5sum "$bios_folder/$bios_subdir$bios_file" | awk '{ print $1 }') == "$bios_hash" ]]; then
          bios_hash_matched="Yes"
        fi
      fi
      if [[ "$1" == "basic" ]]; then
        bios_checked_list=("${bios_checked_list[@]}" "$bios_file" "$bios_system" "$bios_file_found" "$bios_hash_matched" "$bios_desc")
        echo "$bios_file"^"$bios_system"^"$bios_file_found"^"$bios_hash_matched"^"$bios_desc" >> "$godot_bios_files_checked" # Godot data transfer temp file
      else
        bios_checked_list=("${bios_checked_list[@]}" "$bios_file" "$bios_system" "$bios_file_found" "$bios_hash_matched" "$bios_desc" "$bios_subdir" "$bios_hash")
        echo "$bios_file"^"$bios_system"^"$bios_file_found"^"$bios_hash_matched"^"$bios_desc"^"$bios_subdir"^"$bios_hash" >> "$godot_bios_files_checked" # Godot data transfer temp file
      fi
  done < $bios_checklist
}
