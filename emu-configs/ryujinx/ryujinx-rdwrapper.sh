#!/bin/bash

source /app/libexec/global.sh

log i "Ryujinx RetroDECK wrapper: starting"
command="$1"
manage_ryujinx_keys
log d "Ryujinx RetroDECK wrapper: launching \"Ryujinx.sh $command\""
Ryujinx.sh "$command"