#!/bin/bash

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
mkdir -p "$target_dir"

# Find and copy files
find "$1" -type f -exec sh -c '
    target_dir="$1"
    shift
    for file in "$@"; do
        dest_file="$target_dir/$(basename "$file")"
        if [ ! -e "$dest_file" ]; then
            if cp "$file" "$dest_file"; then
                echo "Copied $file to $dest_file"
            else
                echo "Failed to copy $file to $dest_file"
            fi
        else
            echo "Skipped $file as $dest_file already exists"
        fi
    done
' sh "$target_dir" {} +
