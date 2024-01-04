#!/bin/bash

# This script provides a logging function 'log' that can be sourced in other scripts.
# It logs messages to both the terminal and a specified logfile, allowing different log levels.
# The log function takes three parameters: log level, log message, and optionally the logfile. If no logfile is specified, it writes to retrodeck/logs/retrodeck.log

# Example usage:
# log w "foo" -> logs a warning with message foo in the default log file retrodeck/logs/retrodeck.log
# log e "bar" -> logs an error with message bar in the default log file retrodeck/logs/retrodeck.log
# log i "par" rekku.log -> logs an information with message in the specified log file inside the logs folder retrodeck/logs/rekku.log

log() {
    local level="$1"
    local message="$2"
    local timestamp="$(date +[%Y-%m-%d\ %H:%M:%S])"
    local logfile="${3:-$logs_folder/retrodeck.log}" # Use specified logfile or default to retrodeck.log

    case "$level" in
        w) 
            # Warning (yellow) for terminal, no color for log file
            colored_message="\e[33m[WARN]\e[0m $message"
            echo "$timestamp $colored_message" | tee -a >(sed $'s,\e\\[[0-9;]*[a-zA-Z],,g' >> "$logfile")
            ;;
        e) 
            # Error (red) for terminal, no color for log file
            colored_message="\e[31m[ERROR]\e[0m $message"
            echo "$timestamp $colored_message" | tee -a >(sed $'s,\e\\[[0-9;]*[a-zA-Z],,g' >> "$logfile")
            ;;
        i) 
            # Info (green) for terminal, no color for log file
            colored_message="\e[32m[INFO]\e[0m $message"
            echo "$timestamp $colored_message" | tee -a >(sed $'s,\e\\[[0-9;]*[a-zA-Z],,g' >> "$logfile")
            ;;
        d) 
            # Debug (green) for both terminal, no color for log file
            colored_message="\e[32m[DEBUG]\e[0m $message"
            echo "$timestamp $colored_message" | tee -a >(sed $'s,\e\\[[0-9;]*[a-zA-Z],,g' >> "$logfile")
            ;;
        *) 
            # Default (no color)
            echo "$timestamp $message" | tee -a "$logfile"
            ;;
    esac
}