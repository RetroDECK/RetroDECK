#!/bin/bash

source /app/libexec/global.sh

#Check if Steam Deck in Desktop Mode
if [[ $(check_desktop_mode) == "true" ]]; then
    ruffle --graphics vulkan --config /var/data/ruffle --save-directory $saves_folder/ruffle --fullscreen "$@"
else
    ruffle --graphics gl --config /var/data/ruffle --save-directory $saves_folder/ruffle --fullscreen "$@"
fi
