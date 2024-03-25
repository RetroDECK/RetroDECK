#!/bin/bash

source /app/libexec/global.sh

log i "Starting Ryujinx wrapper"
command="$1"
manage_ryujinx_keys
Ryujinx.sh $command # do not put comma here or it breaks
