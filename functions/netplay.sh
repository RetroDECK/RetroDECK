#!/bin/bash

source functions/flags.sh # TODO: set it in the real folder for flatpak enviro

populate_table() {
  # URL of the RetroArch lobby API
  retroarch_url="http://lobby.libretro.com/list"
  
  # Fetch the list of netplay rooms in JSON format
  retroarch_response=$(curl -s "$retroarch_url")
  
  # Fetch Pretendo netplay rooms (Example URL)
  pretendo_url="https://pretendo.network/api/rooms"
  pretendo_response=$(curl -s "$pretendo_url")
  
  # Fetch PCSX2 netplay rooms (Example URL)
  pcsx2_url="https://pcsx2.netplay.api/rooms"
  pcsx2_response=$(curl -s "$pcsx2_url")
  
  # Fetch RPCS3 netplay rooms (Example URL)
  rpcs3_url="https://rpcn.rpc3.net/v1/rooms"
  rpcs3_response=$(curl -s "$rpcs3_url")
  
  # Fetch Dolphin netplay rooms (Example URL)
  dolphin_url="https://dolphin-emu.org/netplay/rooms"
  dolphin_response=$(curl -s "$dolphin_url")
  
  # Check if the responses are empty or if there are errors
  if [ -z "$retroarch_response" ]; then
    log e "Error connecting to the RetroArch Netplay server."
  fi
  if [ -z "$pretendo_response" ]; then
    log e "Error connecting to the Pretendo Netplay server."
  fi
  if [ -z "$pcsx2_response" ]; then
    log e "Error connecting to the PCSX2 Netplay server."
  fi
  if [ -z "$rpcs3_response" ]; then
    log e "Error connecting to the RPCS3 Netplay server."
  fi
  if [ -z "$dolphin_response" ]; then
    log e "Error connecting to the Dolphin Netplay server."
  fi
  
  # Parse the JSON responses using jq
  retroarch_rooms=$(echo "$retroarch_response" | jq -r '.[] | .fields | [.country, .username, .game_name, .core_name, .has_password, .retroarch_version, .created, .game_crc, .ip, .port] | @tsv')
  pretendo_rooms=$(echo "$pretendo_response" | jq -r '.rooms[] | [.game, .host, .status] | @tsv')
  pcsx2_rooms=$(echo "$pcsx2_response" | jq -r '.rooms[] | [.game, .host, .status] | @tsv')
  rpcs3_rooms=$(echo "$rpcs3_response" | jq -r '.rooms[] | [.game, .host, .status] | @tsv')
  dolphin_rooms=$(echo "$dolphin_response" | jq -r '.rooms[] | [.game, .host, .status] | @tsv')
  
  # Initialize the results for the Zenity table
  results=()
  room_details=()
  
  # Process each room from RetroArch
  while IFS=$'\t' read -r country username game_name core_name has_password retroarch_version created game_crc ip port; do
    # Convert boolean to human-readable format
    if [ "$has_password" = "true" ]; then
      has_password="Yes"
    else
      has_password="No"
    fi
    
    # Get the flag emoji for the country
    flag="${country_flags[$country]}"
    
    # Add the extracted data to the results array
    results+=("$flag" "$username" "$game_name" "$core_name" "$has_password" "$retroarch_version" "$created")
    room_details+=("$country,$username,$game_name,$core_name,$has_password,$retroarch_version,$created,$game_crc,$ip,$port")
  done <<< "$retroarch_rooms"
  
  # Process each room from Pretendo
  while IFS=$'\t' read -r game host status; do
    results+=("Pretendo" "$host" "$game" "Pretendo" "$status" "N/A" "N/A")
    room_details+=("Pretendo,$host,$game,Pretendo,$status,N/A,N/A,N/A,N/A,N/A")
  done <<< "$pretendo_rooms"
  
  # Process each room from PCSX2
  while IFS=$'\t' read -r game host status; do
    results+=("PCSX2" "$host" "$game" "PCSX2" "$status" "N/A" "N/A")
    room_details+=("PCSX2,$host,$game,PCSX2,$status,N/A,N/A,N/A,N/A,N/A")
  done <<< "$pcsx2_rooms"
  
  # Process each room from RPCS3
  while IFS=$'\t' read -r game host status; do
    results+=("RPCS3" "$host" "$game" "RPCS3" "$status" "N/A" "N/A")
    room_details+=("RPCS3,$host,$game,RPCS3,$status,N/A,N/A,N/A,N/A,N/A")
  done <<< "$rpcs3_rooms"
  
  # Process each room from Dolphin
  while IFS=$'\t' read -r game host status; do
    results+=("Dolphin" "$host" "$game" "Dolphin" "$status" "N/A" "N/A")
    room_details+=("Dolphin,$host,$game,Dolphin,$status,N/A,N/A,N/A,N/A,N/A")
  done <<< "$dolphin_rooms"
  
  # Check if results array is populated
  if [ ${#results[@]} -eq 0 ]; then
    zenity --info --title="Netplay Results" --text="No valid rooms found."
    exit 0
  fi
  
  # Display the results using Zenity in a table and get the selected row
  selected=$(zenity --list --width="1280" --height="800" \
    --title="Available Netplay Rooms" \
    --column="Loc" \
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

# Call the function to populate the table
selected_room=$(populate_table)

# Parse the selected room details
IFS=',' read -r selected_country selected_username selected_game_name selected_core_name selected_has_password selected_version selected_created selected_game_crc selected_ip selected_port <<< "$selected_room"

# Implement the logic for launching the selected emulator with the selected game and netplay room details
start_game() {
  # Get the details of the selected room
  room_details=("$@")
  
  selected_game_crc=""
  selected_ip=""
  selected_port=""
  
  for detail in "${room_details[@]}"; do
    IFS=',' read -r country username game_name core_name has_password version created game_crc ip port <<< "$detail"
    
    if [ "$country" = "$selected_country" ] && [ "$username" = "$selected_username" ] && [ "$game_name" = "$selected_game_name" ] && [ "$core_name" = "$selected_core_name" ] && [ "$has_password" = "$selected_has_password" ] && [ "$version" = "$selected_version" ] && [ "$created" = "$selected_created" ]; then
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
  
  # Launch the appropriate emulator with the selected game and netplay room details
  case "$selected_core_name" in
    "RetroArch")
      if [ "$selected_has_password" = "Yes" ]; then
        password=$(zenity --entry --title="Password Required" --text="Enter the password for the netplay room:")
        if [ -z "$password" ]; then
          zenity --error --text="Password required to join the room."
          exit 1
        fi
        retroarch -L "/app/share/libretro/cores/${selected_core_name}.so" "$found_rom" --connect "$selected_ip:$selected_port" --password "$password"
      else
        retroarch -L "/app/share/libretro/cores/${selected_core_name}.so" "$found_rom" --connect "$selected_ip:$selected_port"
      fi
      ;;
    "Pretendo")
      # Pretendo-specific launch command (example, replace with actual)
      pretendoclient --connect "$selected_ip:$selected_port" --game "$found_rom"
      ;;
    "PCSX2")
      # PCSX2-specific launch command (example, replace with actual)
      pcsx2 --netplay --host "$selected_ip" --port "$selected_port" "$found_rom"
      ;;
    "RPCS3")
      # RPCS3-specific launch command (example, replace with actual)
      rpcs3 --netplay --host "$selected_ip" --port "$selected_port" "$found_rom"
      ;;
    "Dolphin")
      # Dolphin-specific launch command (example, replace with actual)
      dolphin-emu --netplay --host "$selected_ip" --port "$selected_port" "$found_rom"
      ;;
    *)
      zenity --error --text="Unsupported core: $selected_core_name"
      exit 1
      ;;
  esac
}

# Call the function to start the game
start_game "$selected_room" "${room_details[@]}"
