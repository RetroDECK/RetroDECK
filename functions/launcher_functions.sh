#!/bin/bash

# This library provides minimal function loading for scripts working outside of the application shell (such as ones called by /bin/bash <script> or exec) without the need to source global.sh
# All application variables are still available to all scripts as they are exported to the environment

source /app/libexec/cleanup.sh
source /app/libexec/logger.sh
source /app/libexec/zenity_processing.sh

# Shared helpers used by both the main shell and the launchers.
source /app/libexec/system_detection.sh

# BIOS status scanning + the pre-launch BIOS check hook.
source /app/libexec/api_data_processing.sh
source /app/libexec/configurator_functions.sh
source /app/libexec/bios_launch_check.sh

_launching_component="$(basename "$(dirname "$(readlink -f "${BASH_SOURCE[1]}")")")"
rd_pre_launch_bios_check "$_launching_component" "$@"
