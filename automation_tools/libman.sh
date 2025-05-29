#!/bin/bash

# LibMan 2.0
# This script deduplicates library files in the Flatpak build environment by replacing duplicates with symlinks.
# It prioritizes libraries in /lib, then /app/retrodeck/components/shared-libs, and finally other components.
# Usage: Run this script in the Flatpak build environment after all components have been copied.

# Dedupe libraries in /lib, /app/retrodeck/components/shared-libs, and /app/retrodeck/components by replacing duplicates with symlinks
# Priority: /lib > /app/retrodeck/components/shared-libs > other components

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

        if [[ -z "${file_hash_map[$hash]}" ]]; then
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