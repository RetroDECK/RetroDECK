#!/bin/bash

# Be aware that this script deletes the source directory after copying the files. It is intended to be used only by the flatpak builder.

# List of user-defined libraries to exclude
excluded_libraries=()

# General libraries
excluded_libraries=("libselinux.so.1" "libwayland-egl.so.1" "libwayland-cursor.so.0" "libxkbcommon.so.0")
# Qt libraries
excluded_libraries+=("libQt6Multimedia.so.6" "libQt6Core.so.6" "libQt6DBus.so.6" "libQt6Gui.so.6" "libQt6OpenGL.so.6" "libQt6Svg.so.6" "libQt6WaylandClient.so.6" "libQt6WaylandEglClientHwIntegration.so.6" "libQt6Widgets.so.6" "libQt6XcbQpa.so.6")
# SDL libraries
excluded_libraries+=("libSDL2_net-2.0.so.0.200.0" "libSDL2_mixer-2.0.so.0.600.3" "libSDL2-2.0.so.0" "libSDL2_mixer-2.0.so.0" "libSDL2_image-2.0.so.0" "libSDL2-2.0.so.0.2800.5" "libSDL2_ttf-2.0.so.0" "libSDL2_net-2.0.so.0" "libSDL2_image-2.0.so.0.600.3" "libSDL2_ttf-2.0.so.0.2200.0")
# FFMPEG libraries
excluded_libraries+=("libavcodec.so" "libavformat.so" "libavutil.so" "libavfilter.so" "libavdevice" "libswresample.so" "libswscale.so")

# Add libraries from /lib/x86_64-linux-gnu/ to the excluded list
for lib in /lib/x86_64-linux-gnu/*.so*; do
    excluded_libraries+=("$(basename "$lib")")
done

# Add libraries from /lib to the excluded list
for lib in /lib/*.so*; do
    excluded_libraries+=("$(basename "$lib")")
done

# Add libraries from /lib64 to the excluded list
for lib in /lib64/*.so*; do
    excluded_libraries+=("$(basename "$lib")")
done

echo "Worry not, LibMan is here!"

# Set default destination if FLATPAK_DEST is not set
if [ -z "$FLATPAK_DEST" ]; then
    export FLATPAK_DEST="/app"
fi

# Check if source directory is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <source_directory> [destination_directory]"
    exit 0
fi

# Use the second argument as the destination directory if provided
if [ -n "$2" ]; then
    target_dir="$2"
else
    target_dir="${FLATPAK_DEST}/lib"
fi

# Define debug directory
debug_dir="${target_dir}/debug"

# Ensure the target directory exists
if ! mkdir -p "$target_dir"; then
    echo "Error: Failed to create target directory $target_dir"
    exit 0
fi

# Ensure the debug directory exists
if ! mkdir -p "$debug_dir"; then
    echo "Error: Failed to create debug directory $debug_dir"
    exit 0
fi

# Function to check if a file is in the excluded libraries list
is_excluded() {
    local file="$1"
    for excluded in "${excluded_libraries[@]}"; do
        if [[ "$file" == $excluded ]]; then # NOTE excluded is not quoted to allow for wildcard matching
            return 0
        fi
    done
    return 1
}

# Find and copy files
copied_files=()
failed_files=()

# First, copy all regular files
for file in $(find "$1" -type f -name "*.so*" ! -type l); do
    # Check if the file is in the debug folder
    if [[ "$file" == *"/debug/"* ]]; then
        dest_file="$debug_dir/$(basename "$file")"
    else
        dest_file="$target_dir/$(basename "$file")"
    fi

    # Skip if the file is in the list of excluded libraries
    if is_excluded "$(basename "$file")"; then
        reason="library is in the exclusion list"
        echo "Skipped $file as it is $reason"
        failed_files+=("$file, $reason")
        continue
    fi
    
    # Skip if the destination file already exists
    if [ -e "$dest_file" ]; then
        echo "Skipped $file as $dest_file already exists"
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

# Then, copy all symlinks
for file in $(find "$1" -type l -name "*.so*"); do
    # Check if the file is in the debug folder
    if [[ "$file" == *"/debug/"* ]]; then
        dest_file="$debug_dir/$(basename "$file")"
    else
        dest_file="$target_dir/$(basename "$file")"
    fi

    # Get the target of the symlink
    symlink_target=$(readlink "$file")
    # Define the destination for the symlink target
    if [[ "$symlink_target" == *"/debug/"* ]]; then
        dest_symlink_target="$debug_dir/$(basename "$symlink_target")"
    else
        dest_symlink_target="$target_dir/$(basename "$symlink_target")"
    fi
    
    # Copy the symlink target if it doesn't already exist
    if [ ! -e "$dest_symlink_target" ]; then
        if install -D "$symlink_target" "$dest_symlink_target" 2>error_log; then
            echo "Copied symlink target $symlink_target to $dest_symlink_target"
            copied_files+=("$symlink_target")
        else
            error_message=$(<error_log)
            echo "Warning: Failed to copy symlink target $symlink_target. Skipping. Error: $error_message"
            failed_files+=("$symlink_target, $error_message")
            continue
        fi
    fi

    # Create the symlink in the target directory
    if ln -s "$dest_symlink_target" "$dest_file" 2>error_log; then
        echo "Created symlink $dest_file -> $dest_symlink_target"
        copied_files+=("$file")
    else
        error_message=$(<error_log)
        echo "Warning: Failed to create symlink $dest_file. Skipping. Error: $error_message"
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

# Remove excluded libraries from the target directory
for excluded in "${excluded_libraries[@]}"; do
    if [ -e "$target_dir/$excluded" ]; then
        rm -f "$target_dir/$excluded"
        echo "Deleted excluded library $target_dir/$excluded"
    fi
done

echo "LibMan is flying away"
