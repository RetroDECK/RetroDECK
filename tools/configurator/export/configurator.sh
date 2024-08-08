#!/bin/sh
echo -ne '\033c\033]0;RetroDECK Configurator\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/configurator.x86_64" "$@"
