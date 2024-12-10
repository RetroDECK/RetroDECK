#!/bin/bash
# todo create launch test commands ie mame -help, ruffle --version


# Log file
LOG_FILE="$HOME/check.log"

# Clear previous log
> "$LOG_FILE"

# Extract launch commands using jq
commands=($(jq -r '.emulator | to_entries[] | .value.launch' /app/retrodeck/config/retrodeck/reference_lists/features.json))

# Timeout duration in seconds
TIMEOUT=5

# Function to run command with timeout
run_and_check() {
    local cmd="flatpak run net.retrodeck.retrodeck $1"
    
    # Verify command exists
    if ! command -v "$cmd" &> /dev/null; then
        echo "✗ Command not found: $cmd (Exit Code: 127)" | tee -a "$LOG_FILE"
        return 127
    fi

    # Run command with timeout
    timeout -s TERM $TIMEOUT "$cmd"
    local exit_code=$?

    # Log the results
    echo "Command: $cmd, Exit Code: $exit_code" | tee -a "$LOG_FILE"

    case $exit_code in
        0)
            echo "✓ $cmd completed successfully" | tee -a "$LOG_FILE"
            ;;
        124)
            echo "✗ $cmd terminated after $TIMEOUT seconds" | tee -a "$LOG_FILE"
            ;;
        137)
            echo "✗ $cmd killed" | tee -a "$LOG_FILE"
            ;;
        *)
            echo "✗ $cmd failed" | tee -a "$LOG_FILE"
            ;;
    esac

    return $exit_code
}

# Execute commands
for cmd in "${commands[@]}"; do
    run_and_check "$cmd"
done