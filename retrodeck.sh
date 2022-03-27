#!/bin/bash

# if we got the es_settings.xml means that it's a clean(-ish)/first run
if test -f "/app/retrodeck/es_settings.xml"; then
    mv -f /app/retrodeck/es_settings.xml ~/.emulationstation/es_settings.xml
fi

emulationstation