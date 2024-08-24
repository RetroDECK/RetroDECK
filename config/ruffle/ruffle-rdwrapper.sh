#!/bin/sh

source /app/libexec/global.sh

create_dir "$saves_folder/ruffle"

static_invoke="--config /var/data/ruffle \ 
               --save-directory "$saves_folder/ruffle" \
               --fullscreen"

#Check if Steam Deck in Desktop Mode
if [[ $(check_desktop_mode) == "true" ]]; then
    ruffle --graphics vulkan $static_invoke "$@"
else
    ruffle --graphics gl --no-gui $static_invoke "$@"
fi