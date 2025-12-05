#!/bin/bash

configurator_check_multifile_game_structure_dialog() {
  local folder_games=($(find "$roms_path" -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3"))
  if [[ ${#folder_games[@]} -gt 1 ]]; then
    echo "$(find "$roms_path" -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3")" > "$logs_path"/multi_file_games_"$(date +"%Y_%m_%d_%I_%M_%p").log"
    rd_zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator - 🛑 Warning: Verify Multi-file Structure - Errors Found 🛑" \
    --text="These games have an invalid folder structure:\n\n$(find "$roms_path" -maxdepth 2 -mindepth 2 -type d ! -name "*.m3u" ! -name "*.ps3")\n\n🛑 Warning! 🛑\n\nIncorrect folder structure can cause games to fail to launch or save files to be in the wrong location.\n\nSee the <span foreground='$purple'><b>RetroDECK Wiki</b></span> for details.\n\nYou can find this list of games under <span foreground='purple'>/retrodeck/logs</span>."
  else
    configurator_generic_dialog "RetroDECK Configurator - 💚 Verify Multi-file Structure: All good! 💚" "No incorrect multi-file game folder structures were found."
  fi
}
