#!/bin/bash

# LibMan 2.0
# This script:
# 1. Ensures standard versioned symlinks (like libX.so.MAJOR.MINOR and libX.so.MAJOR) exist for fully versioned libraries.
# 2. Deduplicates library files in the Flatpak build environment by replacing duplicates with symlinks.
# Priority: /lib > /app/retrodeck/components/shared-libs > other components.

set -euo pipefail

echo "=== Creating standard versioned symlinks ==="

# Create standard symlinks for fully versioned .so files (e.g., libQt6Core.so.6.8.3)
find "${FLATPAK_DEST}" -type f -name '*.so.*.*' | while read -r fullver_file; do
    dir=$(dirname "$fullver_file")
    base=$(basename "$fullver_file")
    
    # Extract base name and version components
    if [[ $base =~ ^(lib.+\.so)\.([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        base_name="${BASH_REMATCH[1]}"
        major="${BASH_REMATCH[2]}"
        minor="${BASH_REMATCH[3]}"
        patch="${BASH_REMATCH[4]}"
        
        # Create .MAJOR.MINOR symlink
        minor_symlink="${dir}/${base_name}.${major}.${minor}"
        if [[ ! -e "$minor_symlink" ]]; then
            echo "Creating symlink: $minor_symlink -> $base"
            ln -s "$base" "$minor_symlink"
        fi
        
        # Create .MAJOR symlink
        major_symlink="${dir}/${base_name}.${major}"
        if [[ ! -e "$major_symlink" ]]; then
            echo "Creating symlink: $major_symlink -> $base"
            ln -s "$base" "$major_symlink"
        fi
    fi
done

echo "=== Starting deduplication ==="

# Collect all relevant library files with null-delimited safety
mapfile -d '' all_files < <(
    find "${FLATPAK_DEST}/lib" -type f -name '*.so*' -print0 2>/dev/null
    find "${FLATPAK_DEST}/retrodeck/components/shared-libs" -type f -name '*.so*' -print0 2>/dev/null
    find "${FLATPAK_DEST}/retrodeck/components" -type f -name '*.so*' -not -path "${FLATPAK_DEST}/retrodeck/components/shared-libs/*" -print0 2>/dev/null
)

# Group library files by basename
declare -A files_by_name

for file in "${all_files[@]}"; do
    filename=$(basename "$file")
    files_by_name["$filename"]+="$file"$'\n'
done

# Create hash map to track strongest (priority) file per content hash
declare -A file_hash_map

# Compare only same-named files
for filename in "${!files_by_name[@]}"; do
    # Read file list line by line
    IFS=$'\n' read -d '' -r -a same_named_files < <(printf '%s\0' "${files_by_name[$filename]}")

    for file in "${same_named_files[@]}"; do
        [ -f "$file" ] || continue

        # Compute hash
        hash=$(sha256sum "$file" | awk '{print $1}')

        if [[ ! -v file_hash_map[$hash] ]]; then
            file_hash_map[$hash]="$file"
        else
            strongest="${file_hash_map[$hash]}"
            if [[ "$file" != "$strongest" ]] && cmp -s "$file" "$strongest"; then
                echo "Deduping: $file is a duplicate of $strongest"
                rm -f "$file"
                ln -s "$(realpath --relative-to="$(dirname "$file")" "$strongest")" "$file"
            fi
        fi
    done
done

echo "=== Done! ==="