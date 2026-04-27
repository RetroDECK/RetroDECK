#!/bin/bash

# This library provides minimal function loading for scripts working outside of the application shell (such as ones called by /bin/bash <script> or exec) without the need to source global.sh
# All application variables are still available to all scripts as they are exported to the environment

source /app/libexec/cleanup.sh
source /app/libexec/logger.sh
source /app/libexec/zenity_processing.sh
