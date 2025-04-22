#!/bin/bash

rd_zenity() {
  # This function replaces the standard 'zenity' command and filters out annoying GTK errors on Steam Deck
  export CONFIGURATOR_GUI="zenity"

  # env GDK_SCALE=1.5 \
  #     GDK_DPI_SCALE=1.5 \
  zenity 2> >(grep -v 'Gtk' >&2) "$@"

  local status=${PIPESTATUS[0]}  # Capture the exit code of 'zenity'

  unset CONFIGURATOR_GUI
  
  return "$status"
}
