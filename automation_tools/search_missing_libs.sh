#!/bin/bash

# Search for missing libraries
missing_libs=$(flatpak run --command=sh net.retrodeck.retrodeck -c \
"find /app/bin -type f -exec ldd {} + 2>/dev/null | grep 'not found' | awk '{print \$2}' | tr -d ':' | xargs -n 1 basename | sort | uniq | tr '\n' ' '")

# If there is any missing library, it will be printed, and the step will fail
if [ -n "$missing_libs" ]; then
    echo "The following libraries are missing:"
    echo "$missing_libs"
    exit 1
else
    echo "TEST OK: No missing libraries are found"
fi
