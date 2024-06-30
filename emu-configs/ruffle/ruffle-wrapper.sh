source /app/libexec/global.sh

#Check if Steam Deck in Desktop Mode
if [[ $(check_desktop_mode) == "true" ]]; then
    /app/share/ruffle/ruffle --graphics vulkan --config /var/data/ruffle --save-directory $saves_folder/ruffle --fullscreen "$@"
else
    /app/share/ruffle/ruffle --graphics gl --config /var/data/ruffle --save-directory $saves_folder/ruffle --fullscreen "$@"
fi
