# SORRY, I WILL CLEAN UP THIS
# -Xargon

# This script provides a logging function 'log' that can be sourced in other scripts.
# It logs messages to both the terminal and a specified logfile, allowing different log levels.
# The log function takes three parameters: log level, log message, and optionally the logfile. If no logfile is specified, it writes to retrodeck/logs/retrodeck.log

# Type of log messages:
# log d - debug message: maybe in the future we can decide to hide them in main builds or if an option is toggled
# log i - normal informational message
# log w - waring: something is not expected but it's not a big deal
# log e - error: something broke

# Example usage:
# log w "foo" -> logs a warning with message foo in the default log file retrodeck/logs/retrodeck.log
# log e "bar" -> logs an error with message bar in the default log file retrodeck/logs/retrodeck.log
# log i "par" rekku.log -> logs an information with message in the specified log file inside the logs folder retrodeck/logs/rekku.log

# This function is merging the temporary log file into the actual one
# tmplog_merger() {

#     log d "Starting log merger function"
#     create_dir "$rd_logs_folder"

#     # Check if /tmp/rdlogs/retrodeck.log exists
#     if [ -e "/tmp/rdlogs/retrodeck.log" ] && [ -e "$rd_logs_folder/retrodeck.log" ]; then

#         # Sort both temporary and existing log files by timestamp
#         #sort -k1,1n -k2,2M -k3,3n -k4,4n -k5,5n "/tmp/rdlogs/retrodeck.log" "$rd_logs_folder/retrodeck.log" > "$rd_logs_folder/merged_logs.tmp"

#         # Move the merged logs to replace the original log file
#         #mv "$rd_logs_folder/merged_logs.tmp" "$rd_logs_folder/retrodeck.log"

#         mv "/tmp/rdlogs/retrodeck.log" "$rd_logs_folder/retrodeck.log"

#         # Remove the temporary folder
#         rm -rf "/tmp/rdlogs"
#     fi

#     local ESDE_source_logs="/var/config/ES-DE/logs"
#     # Check if the source file exists
#     if [ -e "$ESDE_source_logs" ]; then
#         # Create the symlink in the logs folder
#         ln -sf "$ESDE_source_logs" "$rd_logs_folder/ES-DE"
#         log i "ES-DE log folder linked to \"$rd_logs_folder/ES-DE\""
#     fi

# }

log() {

    # exec > >(tee "$logs_folder/retrodeck.log") 2>&1 # this is broken, creates strange artifacts and corrupts the log file

    local level="$1"
    local message="$2"
    local timestamp="$(date +[%Y-%m-%d\ %H:%M:%S.%3N])"
    local colorize_terminal

    # Use specified logfile or default to retrodeck.log
    local logfile
    if [ -n "$3" ]; then
        logfile="$3"
    else
        if [ -z $rd_logs_folder ]; then
            # echo "Logger: case 1, rd_logs_folder not found, rd_logs_folder=$rd_logs_folder" # TODO: Debug, delete me
            rd_logs_folder="/tmp/rdlogs"
            create_dir "$rd_logs_folder"
        fi
        if [ ! -z $rdhome ]; then
            # echo "Logger: case 2, rdhome is found, rdhome=$rdhome" # TODO: Debug, delete me
            rd_logs_folder="$(get_setting_value "$rd_conf" "logs_folder" "retrodeck" "paths")"
            mkdir -p "$rd_logs_folder"
            # echo "Logger: case 2, rdhome is found, rd_logs_folder=$rd_logs_folder" # TODO: Debug, delete me
            logfile="$rd_logs_folder/retrodeck.log"
            touch "$logfile"
            local ESDE_source_logs="/var/config/ES-DE/logs"
            # Check if the source file exists
            if [ -e "$ESDE_source_logs" ] && [ ! -d "$rd_logs_folder/ES-DE" ]; then
                # Create the symlink in the logs folder
                # echo "Logger: case 2, symlinking \"$ESDE_source_logs\" in \"$rd_logs_folder/ES-DE\"" # TODO: Debug, delete me
                ln -sf "$ESDE_source_logs" "$rd_logs_folder/ES-DE"
                ln -sf "$HOME/.var/app/net.retrodeck.retrodeck/config/ES-DE/logs" "$rd_logs_folder/ES-DE-outflatpak" # TODO: think a smarter way
            fi
        else
            # echo "Logger: case 3" # TODO: Debug, delete me
            logfile="/tmp/rdlogs/retrodeck.log"
            echo "$timestamp [WARN] retrodeck folder not found, temporary writing logs in \"$logfile\""
        fi

        if [ -z $rdhome ] && [ -d "/tmp/rdlogs" ]; then
            # echo "Logger: case 4, rdhome is found, rdhome=$rdhome, and /tmp/rdlogs is found as well" # TODO: Debug, delete me
            # echo "Logger: case 4, creating the acutal log dir in $rd_logs_folder" # TODO: Debug, delete me
            mkdir -p "$rd_logs_folder"
            # echo "Logger: case 4, moving \"/tmp/rdlogs/retrodeck.log\" in \"$rd_logs_folder/retrodeck.log\"" # TODO: Debug, delete me
            mv "/tmp/rdlogs/retrodeck.log" "$rd_logs_folder/retrodeck.log"
            rm -rf "/tmp/rdlogs"
            # echo "Logger: deleting /tmp/rdlogs" # TODO: Debug, delete me
        fi
    fi

    # Check if the shell is sh (not bash or zsh) to avoid colorization
    if [ "${SHELL##*/}" = "sh" ]; then
        colorize_terminal=false
    else
        colorize_terminal=true
    fi

    case "$level" in
        w) 
            if [ "$colorize_terminal" = true ]; then
                # Warning (yellow) for terminal
                colored_message="\e[33m[WARN] $message\e[0m"
            else
                # Warning (no color for sh) for terminal
                colored_message="$timestamp [WARN] $message"
            fi
            # Write to log file without colorization
            log_message="$timestamp [WARN] $message"
            ;;
        e) 
            if [ "$colorize_terminal" = true ]; then
                # Error (red) for terminal
                colored_message="\e[31m[ERROR] $message\e[0m"
            else
                # Error (no color for sh) for terminal
                colored_message="$timestamp [ERROR] $message"
            fi
            # Write to log file without colorization
            log_message="$timestamp [ERROR] $message"
            ;;
        i) 
            # Write to log file without colorization for info message
            log_message="$timestamp [INFO] $message"
            colored_message=$log_message
            ;;
        d) 
            if [ "$colorize_terminal" = true ]; then
                # Debug (green) for terminal
                colored_message="\e[32m[DEBUG] $message\e[0m"
            else
                # Debug (no color for sh) for terminal
                colored_message="$timestamp [DEBUG] $message"
            fi
            # Write to log file without colorization
            log_message="$timestamp [DEBUG] $message"
            ;;
        *) 
            # Default (no color for other shells) for terminal
            colored_message="$timestamp $message"
            # Write to log file without colorization
            log_message="$timestamp $message"
            ;;
    esac

    # Display the message in the terminal
    echo -e "$colored_message"

    # Write the log message to the log file
    if [ ! -f "$logfile" ]; then
        echo "$timestamp [WARN] Log file not found in \"$logfile\", creating it"
        touch "$logfile"
    fi
    echo "$log_message" >> "$logfile"

}
