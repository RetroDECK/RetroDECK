#!/bin/bash

# Be aware that this script deletes the source directory after copying the files. It is intended to be used only by the flatpak builder.


# List of user-defined libraries to exclude
excluded_libraries=("libselinux.so.1")

# Define target directory
target_dir="${FLATPAK_DEST}/lib"


echo "Worry not, LibMan is here!"

# Set default destination if FLATPAK_DEST is not set
if [ -z "$FLATPAK_DEST" ]; then
    export FLATPAK_DEST="/app"
fi

# Check if source directory is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <source_directory>"
    exit 0
fi

# Ensure the target directory exists
if ! mkdir -p "$target_dir"; then
    echo "Error: Failed to create target directory $target_dir"
    exit 0
fi

# Function to check if a file is in the excluded libraries list
is_excluded() {
    local file="$1"
    for excluded in "${excluded_libraries[@]}"; do
        if [[ "$excluded" == "$file" ]]; then
            return 0
        fi
    done
    return 1
}

# Find and copy files
copied_files=()
failed_files=()

for file in $(find "$1" -type f -name "*.so*"); do
    # Define destination file path
    dest_file="$target_dir/$(basename "$file")"
    
    # Skip if the destination file already exists
    if [ -e "$dest_file" ]; then
        echo "Skipped $file as $dest_file already exists"
        continue
    fi

    # Skip if the file is in the list of excluded libraries
    if is_excluded "$(basename "$file")"; then
        reason="library is in the exclusion list"
        echo "Skipped $file as it is $reason"
        failed_files+=("$file, $reason")
        continue
    fi
    # Attempt to copy the file
    if install -D "$file" "$dest_file" 2>error_log; then
        echo "Copied $file to $dest_file"
        copied_files+=("$file")
    else
        error_message=$(<error_log)
        echo "Warning: Failed to copy $file. Skipping. Error: $error_message"
        failed_files+=("$file, $error_message")
    fi
done

# Output the lists of copied and failed files
if [ ${#copied_files[@]} -ne 0 ]; then
    echo "Imported libraries:"
    for file in "${copied_files[@]}"; do
        echo "$file"
    done
fi

# Output failed files only if the list is not empty
if [ ${#failed_files[@]} -ne 0 ]; then
    echo "Failed library files:"
    for file in "${failed_files[@]}"; do
        echo "$file"
    done
fi

echo "LibMan is flying away"
