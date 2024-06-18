#!/bin/bash

# Mapping of country codes to flag emojis
declare -A country_flags=(
  ["af"]="🇦🇫"
  ["ax"]="🇦🇽"
  ["al"]="🇦🇱"
  ["dz"]="🇩🇿"
  ["as"]="🇦🇸"
  ["ad"]="🇦🇩"
  ["ao"]="🇦🇴"
  ["ai"]="🇦🇮"
  ["aq"]="🇦🇶"
  ["ag"]="🇦🇬"
  ["ar"]="🇦🇷"
  ["am"]="🇦🇲"
  ["aw"]="🇦🇼"
  ["au"]="🇦🇺"
  ["at"]="🇦🇹"
  ["az"]="🇦🇿"
  ["bs"]="🇧🇸"
  ["bh"]="🇧🇭"
  ["bd"]="🇧🇩"
  ["bb"]="🇧🇧"
  ["by"]="🇧🇾"
  ["be"]="🇧🇪"
  ["bz"]="🇧🇿"
  ["bj"]="🇧🇯"
  ["bm"]="🇧🇲"
  ["bt"]="🇧🇹"
  ["bo"]="🇧🇴"
  ["bq"]="🇧🇶"
  ["ba"]="🇧🇦"
  ["bw"]="🇧🇼"
  ["bv"]="🇧🇻"
  ["br"]="🇧🇷"
  ["io"]="🇮🇴"
  ["bn"]="🇧🇳"
  ["bg"]="🇧🇬"
  ["bf"]="🇧🇫"
  ["bi"]="🇧🇮"
  ["kh"]="🇰🇭"
  ["cm"]="🇨🇲"
  ["ca"]="🇨🇦"
  ["cv"]="🇨🇻"
  ["ky"]="🇰🇾"
  ["cf"]="🇨🇫"
  ["td"]="🇹🇩"
  ["cl"]="🇨🇱"
  ["cn"]="🇨🇳"
  ["cx"]="🇨🇽"
  ["cc"]="🇨🇨"
  ["co"]="🇨🇴"
  ["km"]="🇰🇲"
  ["cd"]="🇨🇩"
  ["cg"]="🇨🇬"
  ["ck"]="🇨🇰"
  ["cr"]="🇨🇷"
  ["ci"]="🇨🇮"
  ["hr"]="🇭🇷"
  ["cu"]="🇨🇺"
  ["cw"]="🇨🇼"
  ["cy"]="🇨🇾"
  ["cz"]="🇨🇿"
  ["dk"]="🇩🇰"
  ["dj"]="🇩🇯"
  ["dm"]="🇩🇲"
  ["do"]="🇩🇴"
  ["ec"]="🇪🇨"
  ["eg"]="🇪🇬"
  ["sv"]="🇸🇻"
  ["gq"]="🇬🇶"
  ["er"]="🇪🇷"
  ["ee"]="🇪🇪"
  ["et"]="🇪🇹"
  ["fk"]="🇫🇰"
  ["fo"]="🇫🇴"
  ["fj"]="🇫🇯"
  ["fi"]="🇫🇮"
  ["fr"]="🇫🇷"
  ["gf"]="🇬🇫"
  ["pf"]="🇵🇫"
  ["tf"]="🇹🇫"
  ["ga"]="🇬🇦"
  ["gm"]="🇬🇲"
  ["ge"]="🇬🇪"
  ["de"]="🇩🇪"
  ["gh"]="🇬🇭"
  ["gi"]="🇬🇮"
  ["gr"]="🇬🇷"
  ["gl"]="🇬🇱"
  ["gd"]="🇬🇩"
  ["gp"]="🇬🇵"
  ["gu"]="🇬🇺"
  ["gt"]="🇬🇹"
  ["gg"]="🇬🇬"
  ["gn"]="🇬🇳"
  ["gw"]="🇬🇼"
  ["gy"]="🇬🇾"
  ["ht"]="🇭🇹"
  ["hm"]="🇭🇲"
  ["va"]="🇻🇦"
  ["hn"]="🇭🇳"
  ["hk"]="🇭🇰"
  ["hu"]="🇭🇺"
  ["is"]="🇮🇸"
  ["in"]="🇮🇳"
  ["id"]="🇮🇩"
  ["ir"]="🇮🇷"
  ["iq"]="🇮🇶"
  ["ie"]="🇮🇪"
  ["im"]="🇮🇲"
  ["il"]="🇮🇱"
  ["it"]="🇮🇹"
  ["jm"]="🇯🇲"
  ["jp"]="🇯🇵"
  ["je"]="🇯🇪"
  ["jo"]="🇯🇴"
  ["kz"]="🇰🇿"
  ["ke"]="🇰🇪"
  ["ki"]="🇰🇮"
  ["kp"]="🇰🇵"
  ["kr"]="🇰🇷"
  ["kw"]="🇰🇼"
  ["kg"]="🇰🇬"
  ["la"]="🇱🇦"
  ["lv"]="🇱🇻"
  ["lb"]="🇱🇧"
  ["ls"]="🇱🇸"
  ["lr"]="🇱🇷"
  ["ly"]="🇱🇾"
  ["li"]="🇱🇮"
  ["lt"]="🇱🇹"
  ["lu"]="🇱🇺"
  ["mo"]="🇲🇴"
  ["mg"]="🇲🇬"
  ["mw"]="🇲🇼"
  ["my"]="🇲🇾"
  ["mv"]="🇲🇻"
  ["ml"]="🇲🇱"
  ["mt"]="🇲🇹"
  ["mh"]="🇲🇭"
  ["mq"]="🇲🇶"
  ["mr"]="🇲🇷"
  ["mu"]="🇲🇺"
  ["yt"]="🇾🇹"
  ["mx"]="🇲🇽"
  ["fm"]="🇫🇲"
  ["md"]="🇲🇩"
  ["mc"]="🇲🇨"
  ["mn"]="🇲🇳"
  ["me"]="🇲🇪"
  ["ms"]="🇲🇸"
  ["ma"]="🇲🇦"
  ["mz"]="🇲🇿"
  ["mm"]="🇲🇲"
  ["na"]="🇳🇦"
  ["nr"]="🇳🇷"
  ["np"]="🇳🇵"
  ["nl"]="🇳🇱"
  ["nc"]="🇳🇨"
  ["nz"]="🇳🇿"
  ["ni"]="🇳🇮"
  ["ne"]="🇳🇪"
  ["ng"]="🇳🇬"
  ["nu"]="🇳🇺"
  ["nf"]="🇳🇫"
  ["mk"]="🇲🇰"
  ["mp"]="🇲🇵"
  ["no"]="🇳🇴"
  ["om"]="🇴🇲"
  ["pk"]="🇵🇰"
  ["pw"]="🇵🇼"
  ["ps"]="🇵🇸"
  ["pa"]="🇵🇦"
  ["pg"]="🇵🇬"
  ["py"]="🇵🇾"
  ["pe"]="🇵🇪"
  ["ph"]="🇵🇭"
  ["pn"]="🇵🇳"
  ["pl"]="🇵🇱"
  ["pt"]="🇵🇹"
  ["pr"]="🇵🇷"
  ["qa"]="🇶🇦"
  ["re"]="🇷🇪"
  ["ro"]="🇷🇴"
  ["ru"]="🇷🇺"
  ["rw"]="🇷🇼"
  ["bl"]="🇧🇱"
  ["sh"]="🇸🇭"
  ["kn"]="🇰🇳"
  ["lc"]="🇱🇨"
  ["mf"]="🇲🇫"
  ["pm"]="🇵🇲"
  ["vc"]="🇻🇨"
  ["ws"]="🇼🇸"
  ["sm"]="🇸🇲"
  ["st"]="🇸🇹"
  ["sa"]="🇸🇦"
  ["sn"]="🇸🇳"
  ["rs"]="🇷🇸"
  ["sc"]="🇸🇨"
  ["sl"]="🇸🇱"
  ["sg"]="🇸🇬"
  ["sx"]="🇸🇽"
  ["sk"]="🇸🇰"
  ["si"]="🇸🇮"
  ["sb"]="🇸🇧"
  ["so"]="🇸🇴"
  ["za"]="🇿🇦"
  ["gs"]="🇬🇸"
  ["ss"]="🇸🇸"
  ["es"]="🇪🇸"
  ["lk"]="🇱🇰"
  ["sd"]="🇸🇩"
  ["sr"]="🇸🇷"
  ["sj"]="🇸🇯"
  ["se"]="🇸🇪"
  ["ch"]="🇨🇭"
  ["sy"]="🇸🇾"
  ["tw"]="🇹🇼"
  ["tj"]="🇹🇯"
  ["tz"]="🇹🇿"
  ["th"]="🇹🇭"
  ["tl"]="🇹🇱"
  ["tg"]="🇹🇬"
  ["tk"]="🇹🇰"
  ["to"]="🇹🇴"
  ["tt"]="🇹🇹"
  ["tn"]="🇹🇳"
  ["tr"]="🇹🇷"
  ["tm"]="🇹🇲"
  ["tc"]="🇹🇨"
  ["tv"]="🇹🇻"
  ["ug"]="🇺🇬"
  ["ua"]="🇺🇦"
  ["ae"]="🇦🇪"
  ["gb"]="🇬🇧"
  ["um"]="🇺🇲"
  ["us"]="🇺🇸"
  ["uy"]="🇺🇾"
  ["uz"]="🇺🇿"
  ["vu"]="🇻🇺"
  ["ve"]="🇻🇪"
  ["vn"]="🇻🇳"
  ["vg"]="🇻🇬"
  ["vi"]="🇻🇮"
  ["wf"]="🇼🇫"
  ["eh"]="🇪🇭"
  ["ye"]="🇾🇪"
  ["zm"]="🇿🇲"
  ["zw"]="🇿🇼"
)


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
  rooms=$(echo "$response" | jq -r '.[] | .fields | [.country, .username, .game_name, .core_name, .has_password, .retroarch_version, .created, .game_crc, .ip, .port] | @tsv')

  # Initialize the results for the Zenity table
  results=()
  room_details=()

  # Process each room
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
  done <<< "$rooms"

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

start_game() {
  selected="$1"
  room_details=("${@:2}")

  # Check if the user selected a row
  if [ -z "$selected" ]; then
    exit 0
  fi

  # Extract the details of the selected room
  selected_flag=$(echo "$selected" | awk -F'|' '{print $1}')
  selected_username=$(echo "$selected" | awk -F'|' '{print $2}')
  selected_game_name=$(echo "$selected" | awk -F'|' '{print $3}')
  selected_core_name=$(echo "$selected" | awk -F'|' '{print $4}')
  selected_has_password=$(echo "$selected" | awk -F'|' '{print $5}')
  selected_version=$(echo "$selected" | awk -F'|' '{print $6}')
  raw_dates=$(echo "$selected" | awk -F'|' '{print $7}')
  # Convert ISO 8601 format to human-readable format
  selected_created=$(date -d "$raw_dates" +"%Y-%m-%d %H:%M:%S")


  # Find the matching room details
  for room in "${room_details[@]}"; do
    IFS=',' read -r country username game_name core_name has_password retroarch_version created game_crc ip port <<< "$room"
    flag="${country_flags[$country]}"
    if [ "$flag" = "$selected_flag" ] && [ "$username" = "$selected_username" ] && [ "$game_name" = "$selected_game_name" ] && [ "$core_name" = "$selected_core_name" ] && [ "$has_password" = "$selected_has_password" ] && [ "$retroarch_version" = "$selected_version" ] && [ "$created" = "$selected_created" ]; then
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

  # If the room has a password, ask for it
  if [ "$selected_has_password" = "Yes" ]; then
    password=$(zenity --entry --title="Password Required" --text="Enter the password for the netplay room:")
    if [ -z "$password" ]; then
      zenity --error --text="Password required to join the room."
      exit 1
    fi
    # Launch RetroArch with the selected game and netplay room details, including password
    retroarch -L "/app/share/libretro/cores/${selected_core_name}.so" "$found_rom" --connect "$selected_ip:$selected_port" --password "$password"
  else
    # Launch RetroArch without password
    retroarch -L "/app/share/libretro/cores/${selected_core_name}.so" "$found_rom" --connect "$selected_ip:$selected_port"
  fi
}

# Call the function to populate the table
selected_room=$(populate_table)

# Call the function to start the game
start_game "$selected_room" "${room_details[@]}"
