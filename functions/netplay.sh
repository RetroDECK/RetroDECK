#!/bin/bash

# URL of the RetroArch lobby API
url="http://lobby.libretro.com/list"

# Fetch the list of netplay rooms in JSON format
response=$(curl -s "$url")

# Check if the response is empty or if there are errors
if [ -z "$response" ]; then
  zenity --error --text="Error connecting to the RetroArch Netplay server."
  exit 1
fi

# Parse the JSON response using jq
rooms=$(echo "$response" | jq -r '.[] | .fields | [.username, .game_name, .core_name, .has_password, .retroarch_version, .created] | @tsv')

# Initialize the results for the Zenity table
results=()

# Process each room
while IFS=$'\t' read -r username game_name core_name has_password retroarch_version created; do
  # Convert boolean to human-readable format
  if [ "$has_password" = "true" ]; then
    has_password="Yes"
  else
    has_password="No"
  fi
  
  # Add the extracted data to the results array
  results+=("$username" "$game_name" "$core_name" "$has_password" "$retroarch_version" "$created")
done <<< "$rooms"

# Check if results array is populated
if [ ${#results[@]} -eq 0 ]; then
  zenity --info --title="Netplay Results" --text="No valid rooms found."
  exit 0
fi

# Display the results using Zenity in a table
zenity --list \
  --title="Available Netplay Rooms" \
  --column="User" \
  --column="Game" \
  --column="Core" \
  --column="Password" \
  --column="Version" \
  --column="Created" \
  "${results[@]}"
