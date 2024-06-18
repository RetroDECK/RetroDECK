#!/bin/bash

populate_table() {
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
  rooms=$(echo "$response" | jq -r '.[] | .fields | [.username, .game_name, .core_name, .has_password, .retroarch_version, .created, .game_crc, .ip, .port] | @tsv')

  # Initialize the results for the Zenity table
  results=()
  room_details=()

  # Process each room
  while IFS=$'\t' read -r username game_name core_name has_password retroarch_version created game_crc ip port; do
    # Convert boolean to human-readable format
    if [ "$has_password" = "true" ]; then
      has_password="Yes"
    else
      has_password="No"
    fi

    # Add the extracted data to the results array
    results+=("$username" "$game_name" "$core_name" "$has_password" "$retroarch_version" "$created")
    room_details+=("$username,$game_name,$core_name,$has_password,$retroarch_version,$created,$game_crc,$ip,$port")
  done <<< "$rooms"

  # Check if results array is populated
  if [ ${#results[@]} -eq 0 ]; then
    zenity --info --title="Netplay Results" --text="No valid rooms found."
    exit 0
  fi

  # Display the results using Zenity in a table and get the selected row
  selected=$(zenity --list \
    --title="Available Netplay Rooms" \
    --column="User" \
    --column="Game" \
    --column="Core" \
    --column="Password" \
    --column="Version" \
    --column="Created" \
    "${results[@]}" \
    --print-column=ALL)

  echo "$selected"
}

start_game() {
  selected="$1"
  room_details=("${@:2}")

  # Check if the user selected a row
  if [ -z "$selected" ]; then
    exit 0
  fi

  # Extract the details of the selected room
  selected_username=$(echo "$selected" | awk -F'|' '{print $1}')
  selected_game_name=$(echo "$selected" | awk -F'|' '{print $2}')
  selected_core_name=$(echo "$selected" | awk -F'|' '{print $3}')
  selected_has_password=$(echo "$selected" | awk -F'|' '{print $4}')
  selected_version=$(echo "$selected" | awk -F'|' '{print $5}')
  selected_created=$(echo "$selected" | awk -F'|' '{print $6}')

  # Find the matching room details
  for room in "${room_details[@]}"; do
    IFS=',' read -r username game_name core_name has_password retroarch_version created game_crc ip port <<< "$room"
    if [ "$username" = "$selected_username" ] && [ "$game_name" = "$selected_game_name" ] && [ "$core_name" = "$selected_core_name" ] && [ "$has_password" = "$selected_has_password" ] && [ "$retroarch_version" = "$selected_version" ] && [ "$created" = "$selected_created" ]; then
      selected_game_crc="$game_crc"
      selected_ip="$ip"
      selected_port="$port"
      break
    fi
  done

  # Find the game ROM by name and then verify CRC
  found_rom=""
  candidates=($(find "$roms_folder" -type f -iname "*$(echo "$selected_game_name" | sed 's/[^a-zA-Z0-9]//g')*"))

  for rom in "${candidates[@]}"; do
    # Check the CRC of the ROM
    rom_crc=$(crc32 "$rom")
    if [ "$rom_crc" = "$selected_game_crc" ]; then
      found_rom="$rom"
      break
    fi
  done

  # Check if the ROM was found
  if [ -z "$found_rom" ]; then
    zenity --error --text="Game ROM not found or CRC mismatch."
    exit 1
  fi

  # Warn the user if the CRC is different
  if [ "$rom_crc" != "$selected_game_crc" ]; then
    zenity --warning --text="CRC mismatch! The game may not work correctly."
  fi

  # Launch RetroArch with the selected game and netplay room details
  retroarch -L "/path/to/cores/${selected_core_name}.so" "$found_rom" --connect "$selected_ip:$selected_port"
}

# Call the function to populate the table
selected_room=$(populate_table)

# Call the function to start the game
start_game "$selected_room" "${room_details[@]}"
