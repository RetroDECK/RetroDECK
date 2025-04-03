#!/bin/bash
# This script runs entirely inside the Flatpak sandbox for net.retrodeck.retrodeck

# Flatpak App ID
FLATPAK_APP_ID="net.retrodeck.retrodeck"

# Log file inside the Flatpak sandbox
LOG_FILE="$HOME/retrodeck-post-build-check.log"

# Clear previous log
> "$LOG_FILE"

# Ensure global.sh is sourced inside the Flatpak sandbox
GLOBAL_SH_PATH="/app/libexec/global.sh"

# Check if the global.sh script exists
if ! flatpak run --command=ls "$FLATPAK_APP_ID" "$GLOBAL_SH_PATH" &> /dev/null; then
    echo "✗ global.sh not found at $GLOBAL_SH_PATH" | tee -a "$LOG_FILE"
    exit 1
else
    echo "✓ global.sh found at $GLOBAL_SH_PATH" | tee -a "$LOG_FILE"
fi

# Source global.sh to load the `features` variable
echo "Sourcing $GLOBAL_SH_PATH to load features" | tee -a "$LOG_FILE"
features=$(flatpak run --command=bash "$FLATPAK_APP_ID" -c "source $GLOBAL_SH_PATH && echo \$features")

# Ensure `features` variable is set
if [ -z "$features" ]; then
    echo "✗ Failed to load features from $GLOBAL_SH_PATH" | tee -a "$LOG_FILE"
    exit 1
fi

# Extract launch commands using jq
echo "Extracting launch commands from $features" | tee -a "$LOG_FILE"
commands=($(flatpak run --command=jq "$FLATPAK_APP_ID" -r '.emulator | to_entries[] | .value.launch' "$features"))
echo "Extracted launch commands: ${commands[@]}" | tee -a "$LOG_FILE"

# Timeout duration in seconds
TIMEOUT=3

# Function to run command with timeout
run_and_check() {
    local cmd="$1"

    echo "Validating command: \"$cmd\"" | tee -a "$LOG_FILE"
    
    # Verify command exists within the Flatpak sandbox
    if ! flatpak run --command=which "$FLATPAK_APP_ID" "$cmd" &> /dev/null; then
        echo "✗ Command not found: $cmd (Exit Code: 127)" | tee -a "$LOG_FILE"
        return 127
    fi

    # Run command with timeout inside the sandbox
    flatpak run --command=timeout "$FLATPAK_APP_ID" -s TERM $TIMEOUT "$cmd" &> /dev/null &
    local pid=$!
    sleep $TIMEOUT

    # Ensure the process is terminated
    if kill -0 $pid 2>/dev/null; then
        #echo "✗ $cmd did not terminate, killing process" | tee -a "$LOG_FILE"
        kill -9 $pid
    fi

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
            echo "✗ $cmd killed after timeout" | tee -a "$LOG_FILE"
            ;;
        *)
            echo "✗ $cmd failed" | tee -a "$LOG_FILE"
            ;;
    esac

    return $exit_code
}

# Execute commands inside the Flatpak sandbox
for cmd in "${commands[@]}"; do
    run_and_check "$cmd"
done

echo "$LOG_FILE"

grep "✗" "$LOG_FILE"