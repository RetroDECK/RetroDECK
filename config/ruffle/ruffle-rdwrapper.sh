#!/bin/sh

source /app/libexec/global.sh

arg="$@"

log i "Ruffle is running: $arg"

create_dir "$saves_folder/ruffle"

static_invoke="--config /var/data/ruffle --save-directory $saves_folder/ruffle --fullscreen"

#Check if Steam Deck in Desktop Mode
if [[ $(check_desktop_mode) == "true" ]]; then
    log d "Running Ruffle in Desktop Mode"
    log d "ruffle --graphics vulkan $static_invoke $@"
    ruffle --graphics vulkan $static_invoke "$@"
else
    log d "Running Ruffle in Desktop Mode"
    log d "ruffle --graphics gl --no-gui $static_invoke $@"
    ruffle --graphics gl --no-gui $static_invoke "$@"
fi