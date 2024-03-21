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


# this is a one off otherwise it would be logging every time this function is called

# if retrodeck folder variable is not yet initialized
if [ -z "${rdhome}" ]; then
    tmp_logs_folder="/tmp/rdlogs"
    logs_folder="$tmp_logs_folder"
    create_dir "$logs_folder"
# if the log folder is not existing
elif [ ! -d "$rd_logs_folder" ]; then
    
    rd_logs_folder="$rdhome/logs"
    create_dir "$rd_logs_folder"
elif [ ! -z "${rdhome}" ] && [ -d "$tmp_logs_folder" ]; then
    cp -f "$tmp_logs_folder/retrodeck.log" "$logs_folder/retrodeck.log"
    rm -rf "$tmp_logs_folder"
fi

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
        logfile="$rd_logs_folder/retrodeck.log"
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

# This function is merging the temporary log file into the actual one
tmplog_merger() {

    create_dir "$rd_logs_folder"

    # Check if /tmp/retrodeck.log exists
    if [ -e "/tmp/retrodeck.log" ] && [ -e "$rd_logs_folder/retrodeck.log" ]; then

        # Sort both temporary and existing log files by timestamp
        sort -k1,1n -k2,2M -k3,3n -k4,4n -k5,5n "/tmp/retrodeck.log" "$rd_logs_folder/retrodeck.log" > "$rd_logs_folder/merged_logs.tmp"

        # Move the merged logs to replace the original log file
        mv "$rd_logs_folder/merged_logs.tmp" "$rd_logs_folder/retrodeck.log"

        # Remove the temporary file
        rm "/tmp/retrodeck.log"
    fi

    local ESDE_source_logs="/var/config/ES-DE/logs"
    # Check if the source file exists
    if [ -e "$ESDE_source_logs" ]; then
        # Create the symlink in the logs folder
        ln -sf "$ESDE_source_logs" "$rd_logs_folder/ES-DE"
        log i "ES-DE log folder linked to \"$rd_logs_folder/ES-DE\""
    fi

}
