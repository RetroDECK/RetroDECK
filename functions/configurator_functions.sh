#!/bin/bash


find_empty_rom_folders() {
  # This function will build an array of all the system subfolders in $roms_folder which are either empty or contain only systeminfo.txt for easy removal

  if [[ -f "$godot_empty_roms_folders" ]]; then
    rm -f "$godot_empty_roms_folders" # Godot data transfer temp files
  fi
  touch "$godot_empty_roms_folders"

  empty_rom_folders_list=()
  all_empty_folders=()

  # Extract helper file names using jq and populate the all_helper_files array
  all_helper_files=($(jq -r '.helper_files | to_entries | .[] | .value.filename' "$features"))

  for system in $(find "$roms_folder" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
  do
    local dir="$roms_folder/$system"
    local files=$(ls -A1 "$dir")
    local count=$(ls -A "$dir" | wc -l)

    if [[ $count -eq 0 ]]; then
        # Directory is empty
        empty_rom_folders_list=("${empty_rom_folders_list[@]}" "false" "$(realpath "$dir")")
        all_empty_folders=("${all_empty_folders[@]}" "$(realpath "$dir")")
        echo "$(realpath "$dir")" >> "$godot_empty_roms_folders" # Godot data transfer temp file
    elif [[ $count -eq 1 ]] && [[ "$(basename "${files[0]}")" == "systeminfo.txt" ]]; then
        # Directory contains only systeminfo.txt
        empty_rom_folders_list=("${empty_rom_folders_list[@]}" "false" "$(realpath "$dir")")
        all_empty_folders=("${all_empty_folders[@]}" "$(realpath "$dir")")
        echo "$(realpath "$dir")" >> "$godot_empty_roms_folders" # Godot data transfer temp file
    elif [[ $count -eq 2 ]] && [[ "$files" =~ "systeminfo.txt" ]]; then
      contains_helper_file="false"
      for helper_file in "${all_helper_files[@]}" # Compare helper file list to dir file list
      do
        if [[ "$files" =~ "$helper_file" ]]; then
          contains_helper_file="true" # Helper file was found
          break
        fi
      done
      if [[ "$contains_helper_file" == "true" ]]; then
        # Directory contains only systeminfo.txt and a helper file
        empty_rom_folders_list=("${empty_rom_folders_list[@]}" "false" "$(realpath "$dir")")
        all_empty_folders=("${all_empty_folders[@]}" "$(realpath "$dir")")
        echo "$(realpath "$dir")" >> "$godot_empty_roms_folders" # Godot data transfer temp file
      fi
    fi
  done
}

configurator_check_multifile_game_structure() {
  local folder_games=($(find "$roms_folder" -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3"))
  if [[ ${#folder_games[@]} -gt 1 ]]; then
    echo "$(find "$roms_folder" -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3")" > "$rd_home_logs_path"/multi_file_games_"$(date +"%Y_%m_%d_%I_%M_%p").log"
    rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - Verify Multi-file Structure" \
    --text="The following games have an incorrect folder structure:\n\n$(find "$roms_folder" -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3")\n\nIncorrect folder structure can cause games to fail to launch or save files to be in the wrong location.\n\nPlease check the RetroDECK Wiki for more details.\n\nYou can find this list of games under <span foreground='purple'>/retrodeck/logs</span>."
  else
    configurator_generic_dialog "RetroDECK Configurator - Verify Multi-file Structure" "No incorrect multi-file game folder structures found."
  fi
}
