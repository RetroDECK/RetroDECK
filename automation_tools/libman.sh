#!/bin/bash

echo "Starting LibMan"

# Set default destination if FLATPAK_DEST is not set
if [ -z "$FLATPAK_DEST" ]; then
    FLATPAK_DEST="/app"
fi

# Check if source directory is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <source_directory>"
    exit 1
fi

# Define target directory
target_dir="${FLATPAK_DEST}/retrodeck/lib"

# Ensure the target directory exists
if ! mkdir -p "$target_dir"; then
    echo "Error: Failed to create target directory $target_dir"
    exit 0
fi

# Find and copy files
find "$1" -type f | while IFS= read -r file; do
    # Define destination file path
    dest_file="$target_dir/$(basename "$file")"
    
    # Skip if the destination file already exists
    if [ -e "$dest_file" ]; then
        echo "Skipped $file as $dest_file already exists"
        continue
    fi

    # Attempt to copy the file
    if cp "$file" "$dest_file"; then
        echo "Copied $file to $dest_file"
    else
        echo "Warning: Failed to copy $file. Skipping."
    fi
done

echo "Terminating LibMan"

