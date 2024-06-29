#!/bin/bash

check_bios_files() {
  # This function validates all the BIOS files listed in the $bios_checklist and adds the results to an array called $bios_checked_list which can be used elsewhere
  # There is a "basic" and "expert" mode which outputs different levels of data
  # USAGE: check_bios_files "mode"
  
  if [[ -f "$godot_bios_files_checked" ]]; then
    rm -f "$godot_bios_files_checked" # Godot data transfer temp files
  fi
  touch "$godot_bios_files_checked"

  while IFS="^" read -r bios_file bios_subdir bios_hash bios_system bios_desc || [[ -n "$bios_file" ]];
    do
      if [[ ! $bios_file == "#"* ]] && [[ ! -z "$bios_file" ]]; then
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
      fi
  done < $bios_checklist
}

find_empty_rom_folders() {
  # This function will build an array of all the system subfolders in $roms_folder which are either empty or contain only systeminfo.txt for easy removal

  if [[ -f "$godot_empty_roms_folders" ]]; then
    rm -f "$godot_empty_roms_folders" # Godot data transfer temp files
  fi
  touch "$godot_empty_roms_folders"

  empty_rom_folders_list=()
  all_empty_folders=()
  all_helper_files=()

  while IFS='^' read -r file dest || [[ -n "$file" ]];
  do
    if [[ ! "$file" == "#"* ]] && [[ ! -z "$file" ]]; then
      all_helper_files=("${all_helper_files[@]}" "$file")
    fi
  done < "$helper_files_list"

  for system in $(find "$roms_folder" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
  do
    local dir="$roms_folder/$system"
    local files=$(ls -A1 "$dir")
    local count=$(ls -A "$dir" | wc -l)

    if [[ $count -eq 0 ]]; then
        # Directory is empty
        empty_rom_folders_list=("${empty_rom_folders_list[@]}" "false" "$(realpath $dir)")
        all_empty_folders=("${all_empty_folders[@]}" "$(realpath $dir)")
        echo "$(realpath $dir)" >> "$godot_empty_roms_folders" # Godot data transfer temp file
    elif [[ $count -eq 1 ]] && [[ "$(basename "${files[0]}")" == "systeminfo.txt" ]]; then
        # Directory contains only systeminfo.txt
        empty_rom_folders_list=("${empty_rom_folders_list[@]}" "false" "$(realpath $dir)")
        all_empty_folders=("${all_empty_folders[@]}" "$(realpath $dir)")
        echo "$(realpath $dir)" >> "$godot_empty_roms_folders" # Godot data transfer temp file
    elif [[ $count -eq 2 ]] && [[ "$files" =~ "systeminfo.txt" ]]; then
      # Directory contains 2 files, one of which is "systeminfo.txt"
      for helper_file in ${all_helper_files[@]} # Compare helper file list to dir file list
      do
        if [[ "$files" =~ "$helper_file" ]]; then
          contains_helper_file="true" # Helper file was found
          break
        fi
      done
      if [[ "$contains_helper_file" == "true" ]]; then
        # Directory contains only systeminfo.txt and a helper file
        empty_rom_folders_list=("${empty_rom_folders_list[@]}" "false" "$(realpath $dir)")
        all_empty_folders=("${all_empty_folders[@]}" "$(realpath $dir)")
        echo "$(realpath $dir)" >> "$godot_empty_roms_folders" # Godot data transfer temp file
      fi
    fi
  done
}
