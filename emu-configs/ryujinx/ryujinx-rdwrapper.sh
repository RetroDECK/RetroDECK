#!/bin/bash

source /app/libexec/functions.sh
source /app/libexec/logger.sh

command="$1"
manage_ryujinx_keys
Ryujinx.sh $command # do not put comma here or it breaks
