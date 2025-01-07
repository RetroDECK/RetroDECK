#!/bin/bash

# Be aware that this script is deleting the source directory after copying the files and it's intended to be used only by flatpak builder

echo "Worry not, LibMan is here!"

# Set default destination if FLATPAK_DEST is not set
if [ -z "$FLATPAK_DEST" ]; then
    FLATPAK_DEST="/app"
fi

# Check if source directory is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <source_directory>"
    exit 0
fi

# Define target directory
target_dir="${FLATPAK_DEST}/retrodeck/lib"

# Ensure the target directory exists
if ! mkdir -p "$target_dir"; then
    echo "Error: Failed to create target directory $target_dir"
    exit 0
fi

# List all libraries in LD_LIBRARY_PATH and store them in an array
libraries=()
IFS=: read -ra dirs <<< "$LD_LIBRARY_PATH"
for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        while IFS= read -r lib; do
            libraries+=("$lib")
        done < <(find "$dir" -type f -name "*.so")
    fi
done

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

    # Skip if the file is already in the list of libraries
    if [[ " ${libraries[*]} " == *" $file "* ]]; then
        echo "Skipped $file as it is already present in the system"
        failed_files+=("$file, already present in the system")
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

echo "LibMan is flying away"

# Output the lists of copied and failed files
echo "Copied files:"
for file in "${copied_files[@]}"; do
    echo "$file"
done

# Output failed files only if the list is not empty
if [ ${#failed_files[@]} -ne 0 ]; then
    echo "Failed files:"
    for file in "${failed_files[@]}"; do
        echo "$file"
    done
fi
