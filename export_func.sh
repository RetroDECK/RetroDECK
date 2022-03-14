#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2020-present Fewtarius

# This content was taken from 99-distribution.conf and made as a shell script for steam deck
# TODO: remove absolute paths and put the variables INSTALL_DIR

export PATH="$PATH:/usr/local/bin:/usr/bin:/storage/bin"

export SDL_GAMECONTROLLERCONFIG_FILE="~/retrodeck/storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt"

EE_DIR="~/retrodeck/storage/.config/distribution"
EE_CONF="${EE_DIR}/configs/distribution.conf"
ES_CONF="~/retrodeck/storage/.emulationstation/es_settings.cfg"
EE_DEVICE=$(cat ~/retrodeck/storage/.config/.OS_ARCH)
JSLISTENCONF="~/retrodeck/storage/.config/distribution/configs/jslisten.cfg"

get_ee_setting() {
# Argument $1 is the setting name, EmuELEC settings alway start with ee_ e.g. ee_novideo
# Usage: get_ee_setting setting [platform] [rom]
# Only the setting argument is required
# Priority is: GAME, PLATFORM, GLOBAL, EE_SETTING if at any point one returns 0 it means its dissabled, if it returns empty it will continue onto the next one.

SETTING="${1}"
PLATFORM="${2}"
ROM="${3}"

#ROM
ROM=$(echo [\"${ROM}\"] | sed -e 's|\[|\\\[|g' | sed -e 's|\]|\\\]|g' | sed -e 's|(|\\\(|g' | sed -e 's|)|\\\)|g')
PAT="^${PLATFORM}${ROM}[.-]${SETTING}=(.*)"
	EES=$(cat "${EE_CONF}" | grep -oE "${PAT}")
	EES="${EES##*=}"

if [ -z "${EES}" ]; then
#PLATFORM
PAT="^${PLATFORM}[.-]${SETTING}=(.*)"
	EES=$(cat "${EE_CONF}" | grep -oE "${PAT}")
	EES="${EES##*=}"
fi

if [ -z "${EES}" ]; then
#GLOBAL
PAT="^global[.-]${SETTING}=(.*)"
	EES=$(cat "${EE_CONF}" | grep -oE "${PAT}")
	EES="${EES##*=}"
fi

if [ -z "${EES}" ]; then
#EE_SETTINGS
PAT="^${SETTING}=(.*)"
	EES=$(cat "${EE_CONF}" | grep -oE "${PAT}")
	EES="${EES##*=}"
fi

echo "${EES}"
}

set_ee_setting() {
# argument $1 is the setting name e.g. nes.integerscale. $2 is the value, e.g "1"
	sed -i "/$1=/d" "${EE_CONF}"
	[ $2 == "disable" ] && echo "#${1}=" >> "${EE_CONF}" || echo "${1}=${2}" >> "${EE_CONF}"
}

get_es_setting() {
	echo $(sed -n "s|\s*<${1} name=\"${2}\" value=\"\(.*\)\" />|\1|p" ${ES_CONF})
}


normperf() {
  # A foo function as in steam deck is not needed, however sometime it's called and I am lazy to edit everything, sorry -Xargon
  return
}

maxperf() {
  # A foo function as in steam deck is not needed, however sometime it's called and I am lazy to edit everything, sorry -Xargon
  return
}


ee_check_bios() {

PLATFORM="${1}"
CORE="${2}"
EMULATOR="${3}"
ROMNAME="${4}"
LOG="${5}"

if [[ -z "$LOG" ]]; then
	LOG="/tmp/logs/exec.log"
	cat /etc/motd > "$LOG"
fi

MISSINGBIOS="$(batocera-systems --strictfilter ${PLATFORM})"
if [ "$?" == "2" ]; then

# formating so it looks nice :)
PLATFORMNAME="${MISSINGBIOS##*>}"  # read from -P onwards
PLATFORMNAME="${PLATFORMNAME%%MISSING*}"  # until a space is found
PLATFORMNAME=$(echo $PLATFORMNAME | sed -e 's/\\n//g')

if [[ -f "${LOG}" ]]; then
echo "${CORE} ${EMULATOR} ${ROMNAME}" >> $LOG
echo "${PLATFORMNAME} missing BIOS - Could not find all BIOS: " >> $LOG
echo "please make sure you copied the files into the corresponding folder " >> $LOG
echo "${MISSINGBIOS}" >> $LOG
fi
	MISSINGBIOS=$(echo "$MISSINGBIOS" | sed -e 's/$/\\n/g')

	/usr/bin/error.sh "${PLATFORMNAME} missing BIOS" "Could not find all BIOS/files in /storage/roms, the game may not work:\n\n ${MISSINGBIOS}\n\nPlease make sure you copied the files into the corresponding folder."
	error_process="$!"
	pkill -P $error_process
fi
}

message_stream () {
  local MESSAGE=$1
  local DELAY=$2
  local LOADBUFFER=0
  local ANSI=0
  for (( i=0; i<${#MESSAGE}; i++ ))
  do
    CHAR="${MESSAGE:$i:1}"
    # Is this an escape character?
    if [ "${CHAR}" == "\\" ]
    then
      LOADBUFFER=1
      BUFFER="$BUFFER${CHAR}"
      continue
    fi

    # Is this ANSI? (\e[*[a-Z])
    if [ "${BUFFER}" == "\e[" ] && [ "${LOADBUFFER}" -eq 1 ]
    then
        ANSI=1
        BUFFER="$BUFFER${CHAR}"
        continue
    fi

    if [ "${LOADBUFFER}" -eq 1 ] && [ "${ANSI}" -eq 1 ]
    then
      # If it isn't ANSI it's a control char like \n
      if [[ "${CHAR}" =~ [a-Z] ]]
      then
        echo -ne "${BUFFER}${CHAR}" >/dev/console
        unset BUFFER
        LOADBUFFER=0
        ANSI=0
      fi
    else
      # otherwise it's text
      echo -ne "${BUFFER}${CHAR}" >/dev/console
      unset BUFFER
      LOADBUFFER=0
      ANSI=0
    fi
    sleep ${DELAY}
  done
}

spinny_cursor() {
  message_stream "$1" 0
  for (( c=0; c<=$2; c++ ))
  do
    echo -ne '\e[2D' '-' > /dev/console
    sleep .01
    echo -ne '\e[2D' '\\' > /dev/console
    sleep .01
    echo -ne '\e[2D' '|' > /dev/console
    sleep .01
    echo -ne '\e[2D' '/' > /dev/console
    sleep .01
  done
  echo -ne '\e[80D\e[K' > /dev/console
}

jslisten() {
    # A foo function as in steam deck is not needed, however sometime it's called and I am lazy to edit everything, sorry -Xargon
    return
}


# 351EDECK specific code

export -f get_ee_setting
export -f set_ee_setting
export -f get_es_setting
export -f maxperf
export -f normperf
export -f ee_check_bios
export -f message_stream
export -f spinny_cursor
#export -f jslisten
#export -f init_port
