#!/bin/bash
# todo create launch test commands ie mame -help, ruffle --version
# Log file
LOG_FILE="$HOME/check.log"
# Clear previous log
> "$LOG_FILE"
# Extract launch commands and CLI arguments using jq
mapfile -t commands < <(jq -r '.emulator | to_entries[] | [.value.launch, .value."cli-arg"] | @tsv' /app/retrodeck/config/retrodeck/reference_lists//features.json)
# Timeout duration in seconds
TIMEOUT=3
# Function to run command with timeout
run_and_check() {
    local cmd="$1"
    local cli_arg="${2:-}"
    local full_cmd="${cmd}${cli_arg:+ $cli_arg}"
    
    # Verify command exists
    if ! command -v "$cmd" &> /dev/null; then
        echo "✗ Command not found: $cmd (Exit Code: 127)" | tee -a "$LOG_FILE"
        return 127
    fi
    
    # Run command with timeout
    timeout -s TERM $TIMEOUT "$full_cmd"
    local exit_code=$?
    
    # Log the results
    echo "Command: $full_cmd, Exit Code: $exit_code" | tee -a "$LOG_FILE"
    
    case $exit_code in
    0)
        echo "✓ $full_cmd completed successfully" | tee -a "$LOG_FILE"
        ;;
    124)
        echo "✗ $full_cmd terminated after $TIMEOUT seconds" | tee -a "$LOG_FILE"
        ;;
    137)
        echo "✗ $full_cmd killed" | tee -a "$LOG_FILE"
        ;;
    *)
        echo "✗ $full_cmd failed" | tee -a "$LOG_FILE"
        ;;
    esac
    
    return $exit_code
}

# Execute commands
for entry in "${commands[@]}"; do
    # Split the TSV entry into command and CLI arg
    IFS=$'\t' read -r cmd cli_arg <<< "$entry"
    
    # Run the command with optional CLI argument
    run_and_check "$cmd" "$cli_arg"
done
