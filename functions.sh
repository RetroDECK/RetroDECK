#!/bin/bash

# THIS IS A CENTRALIZED LOCATION FOR FUNCTIONS, WHICH CAN BE SOURCED WITHOUT RUNNING EXTRA CODE. EXISTING USE OF THESE FUNCTIONS CAN BE REFACTORED TO HERE.

# These functions are original to this file

#=================
# FUNCTION SECTION
#=================

browse() {
  # This function browses for a directory and returns the path chosen
  # USAGE: path_to_be_browsed_for=$(browse $action_text)

  path_selected=false

  while [ $path_selected == false ]
  do
    target="$(zenity --file-selection --title="Choose $1" --directory)"
    if [ $? == 0 ] #yes
    then
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
      --text="Directory $target chosen, is this correct?"
      if [ $? == 0 ]
      then
        path_selected=true
        echo $target
        break
      fi
    else
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" \
      --text="No directory selected. Do you want to exit?"
      if [ $? == 0 ]
      then
        break
      fi
    fi
  done
}

verify_space() {
  # Function used for verifying adequate space before moving directories around
  # USAGE: verify_space $source_dir $dest_dir
  # Function returns "true" if there is enough space, "false" if there is not

  source_size=$(du -sk $1 | awk '{print $1}')
  source_size=$((source_size+(source_size/10))) # Add 10% to source size for safety
  dest_avail=$(df -k --output=avail $2 | tail -1)

  if [[ $source_size -ge $dest_avail ]]; then
    echo "false"
  else
    echo "true"
  fi
}

move() {
  # Function to move a directory from one parent to another
  # USAGE: move $source_dir $dest_dir

  if [[ ! -d "$2/$(basename $1)" ]]; then
    if [[ $(verify_space $1 $2) ]]; then
      (
        if [[ ! -d $2 ]]; then # Create destination directory if it doesn't already exist
          mkdir -pv $2
        fi
        mv -v -t $2 $1
      ) |
      zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Move in Progress" \
      --text="Moving directory $1 to new location of $2, please wait."
    else
      zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK Configurator Utility - Move Directories" \
      --text="The destination directory you have selected does not have enough free space for the files you are trying to move.\n\nPlease select a new destination or free up some space."

      configurator_move_dialog
    fi
  else
    zenity --icon-name=net.retrodeck.retrodeck --error --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK Configurator Utility - Move Directories" \
    --text="The destination directory you have selected already exists.\n\nPlease select a new destination."
  fi
}

set_setting_value() {
  # Function for editing settings
  # USAGE: set_setting_value $setting_file "$setting_name" "$new_setting_value" $system $section_name(optional)

  local setting_name_to_change=$(sed -e 's^\\^\\\\^g;s^`^\\`^g' <<< "$2")
  local setting_value_to_change=$(sed -e 's^\\^\\\\^g;s^`^\\`^g' <<< "$3")
  local current_section_name=$(sed -e 's/%/\\%/g' <<< "$5")

  case $4 in

    "retrodeck" | "citra" | "melonds" | "yuzu" )
      if [[ -z $current_section_name ]]; then
        sed -i 's^'"$setting_name_to_change"'=.*^'"$setting_name_to_change"'='"$setting_value_to_change"'^' $1
      else
        sed -i '\^\['"$current_section_name"'\]^,\^'"$setting_name_to_change"'.*^s^'"$setting_name_to_change"'=.*^'"$setting_name_to_change"'='"$setting_value_to_change"'^' $1
      fi
      ;;

    "retroarch" )
      if [[ -z $current_section_name ]]; then
        sed -i 's^'"$setting_name_to_change"' = \".*\"^'"$setting_name_to_change"' = \"'"$setting_value_to_change"'\"^' $1
      else
        sed -i '\^\['"$current_section_name"'\]^,\^'"$setting_name_to_change"'.*^s^'"$setting_name_to_change"' = \".*\"^'"$setting_name_to_change"' = \"'"$setting_value_to_change"'\"^' $1
      fi
      ;;

    "dolphin" | "duckstation" | "pcsx2" | "ppsspp" | "xemu" )
      if [[ -z $current_section_name ]]; then
        sed -i 's^'"$setting_name_to_change"' =.*^'"$setting_name_to_change"' = '"$setting_value_to_change"'^' $1
      else
        sed -i '\^\['"$current_section_name"'\]^,\^'"$setting_name_to_change"'.*^s^'"$setting_name_to_change"' =.*^'"$setting_name_to_change"' = '"$setting_value_to_change"'^' $1
      fi
      ;;

    "rpcs3" ) # This does not currently work for settings with a $ in them
      if [[ -z $current_section_name ]]; then
        sed -i 's^'"$setting_name_to_change"': .*^'"$setting_name_to_change"': '"$setting_value_to_change"'^' $1
      else
        sed -i '\^\['"$current_section_name"'\]^,\^'"$setting_name_to_change"'.*^s^'"$setting_name_to_change"': .*^'"$setting_name_to_change"': '"$setting_value_to_change"'^' $1
      fi
      ;;

    "emulationstation" )
      sed -i "s%$setting_name_to_change\" \" value=\".*\"%$setting_name_to_change\" \" value=\"$setting_value_to_change\"" $1
      ;;

  esac
}

get_setting_name() {
  # Function for getting the setting name from a full setting line from a config file
  # USAGE: get_setting_name "$current_setting_line" $system

  local current_setting_line="$1"

  case $2 in

  "emulationstation" )
    echo "$current_setting_line" | grep -o -P "(?<=name\=\").*(?=\" value)"
    ;;

  "rpcs3" )
    echo "$current_setting_line" | grep -o -P "^\s*?.*?(?=\s?:\s?)" | sed -e 's/^[ \t]*//;s^\\ ^ ^g'
    ;;

  * )
    echo "$current_setting_line" | grep -o -P "^\s*?.*?(?=\s?=\s?)" | sed -e 's/^[ \t]*//;s^\\ ^ ^g;s^\\$^^'
    ;;

  esac
}

get_setting_value() {
# Function for getting the current value of a setting from a config file
# USAGE: get_setting_value $setting_file "$setting_name" $system $section (optional)

  local current_setting_name="$2"
  local current_section_name="$4"

  case $3 in

  "retrodeck" | "citra" | "melonds" | "yuzu" ) # For files with this syntax - setting_name=setting_value
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=^$current_setting_name=).*" $1)
    else
      sed -n '\^\['"$section_name"'\]^,\^'"$current_setting_name"'^{ \^\['"$section_name"'\]^! { \^'"$current_setting_name"'^ p } }' $1 | grep -o -P "(?<=^$current_setting_name=).*"
    fi
  ;;

  "retroarch" ) # For files with this syntax - setting_name = "setting_value"
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=^$current_setting_name = \").*(?=\")" $1)
    else
      sed -n '\^\['"$section_name"'\]^,\^'"$current_setting_name"'^{ \^\['"$section_name"'\]^! { \^'"$current_setting_name"'^ p } }' $1 | grep -o -P "(?<=^$current_setting_name = \").*(?=\")"
    fi
  ;;

  "dolphin" | "duckstation" | "pcsx2" | "ppsspp" | "xemu" ) # For files with this syntax - setting_name = setting_value
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=^$current_setting_name = ).*" $1)
    else
      sed -n '\^\['"$section_name"'\]^,\^'"$current_setting_name"'^{ \^\['"$section_name"'\]^! { \^'"$current_setting_name"'^ p } }' $1 | grep -o -P "(?<=^$current_setting_name = ).*"
    fi
  ;;

  "rpcs3" ) # For files with this syntax - setting_name: setting_value
    if [[ -z $current_section_name ]]; then
      echo $(grep -o -P "(?<=$current_setting_name: ).*" $1)
    else
      sed -n '\^\['"$section_name"'\]^,\^'"$current_setting_name"'^{ \^\['"$section_name"'\]^! { \^'"$current_setting_name"'^ p } }' $1 | grep -o -P "(?<=$current_setting_name: ).*"
    fi
  ;;

  "emulationstation" )
    echo $(grep -o -P "(?<=^$current_setting_name\" value=\").*(?=\")" $1)
  ;;

  esac
}

add_setting() {
  # This function will add a setting line to a file. This is useful for dynamically generated config files where a setting line may not exist until the setting is changed from the default.
  # USAGE: add_setting $setting_file $setting_line $system $section (optional)

  local current_setting_line=$(sed -e 's^\\^\\\\^g;s^`^\\`^g' <<< "$2")
  local current_section_name=$(sed -e 's/%/\\%/g' <<< "$4")

  case $3 in

  * )
    if [[ -z $current_section_name ]]; then
      sed -i '$ a '"$current_setting_line"'' $1
    else
      sed -i '/^\s*?\['"$current_section_name"'\]|\b'"$current_section"':$/a '"$current_setting_line"'' $1
    fi
    ;;

  esac
}

disable_setting() {
  # This function will add a '#' to the beginning of a defined setting line, disabling it.
  # USAGE: disable_setting $setting_file $setting_line $system $section (optional)

  local current_setting_line"$2"
  local current_section_name="$4"

  case $3 in

  * )
    if [[ -z $current_section_name ]]; then
      sed -i -E 's^(\s*?)'"$current_setting_line"'^\1#'"$current_setting_line"'^' $1
    else
      sed -i -E '\^\['"$current_section_name"'\]|\b'"$current_section"':$^,\^\s*?'"$current_setting_line"'^s^(\s*?)'"$current_setting_line"'^\1#'"$current_setting_line"'^' $1
    fi
  ;;

  esac
}

enable_setting() {
  # This function will remove a '#' to the beginning of a defined setting line, enabling it.
  # USAGE: enable_setting $setting_file $setting_line $system $section (optional)

  local current_setting_line"$2"
  local current_section_name="$4"

  case $3 in

  * )
    if [[ -z $current_section_name ]]; then
      sed -i -E 's^(\s*?)#'"$current_setting_line"'^\1'"$current_setting_line"'^' $1
    else
      sed -i -E '\^\['"$current_section_name"'\]|\b'"$current_section"':$^,\^\s*?#'"$current_setting_line"'^s^(\s*?)#'"$current_setting_line"'^\1'"$current_setting_line"'^' $1
    fi
  ;;

  esac
}

disable_file() {
  # This function adds the suffix ".disabled" to the end of a file to prevent it from being used entirely.
  # USAGE: disable_file $file_name
  # NOTE: $filename can be a defined variable from global.sh or must have the full path to the file

  mv $(realpath $1) $(realpath $1).disabled
}

enable_file() {
  # This function removes the suffix ".disabled" to the end of a file to allow it to be used.
  # USAGE: enable_file $file_name
  # NOTE: $filename can be a defined variable from global.sh or must have the full path to the file and should not have ".disabled" as a suffix

  mv $(realpath $1.disabled) $(realpath $(echo $1 | sed -e 's/\.disabled//'))
}

generate_patch() {
  # generate_patch $original_file $modified_file $patch_file $system

  rm $3 # Remove old patch file (maybe change this to create a backup instead?)

  while read -r current_setting_line; # Look for changes from the original file to the modified one
  do

    printf -v escaped_setting_line '%q' "$current_setting_line" # Take care of special characters before they mess with future commands

    if [[ (! -z $current_setting_line) && (! $current_setting_line == "#!/bin/bash") && (! $current_setting_line == "[]") ]]; then # Ignore empty lines, empty arrays or Bash start lines
      if [[ ! -z $(grep -o -P "^\[.+?\]$" <<< "$current_setting_line") || ! -z $(grep -o -P "^\b.+?:$" <<< "$current_setting_line") ]]; then # Capture section header lines
        if [[ $current_setting_line =~ ^\[.+\] ]]; then # If normal section line
          action="section"
          current_section=$(sed 's^[][]^^g' <<< $current_setting_line) # Remove brackets from section name
        elif [[ ! -z $(grep -o -P "^\b.+?:$" <<< "$current_setting_line") ]]; then # If RPCS3 section name
          action="section"
          current_section=$(sed 's^:$^^' <<< $current_setting_line) # Remove colon from section name
        fi
      elif [[ (! -z $current_section) ]]; then # If line is in a section...
        if [[ ! -z $(grep -o -P "^\s*?#.*?$" <<< "$current_setting_line") ]]; then # Check for disabled lines
          if [[ -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\s*?'"$(sed -E 's/^[ \t]*//;' <<< "$escaped_setting_line")"'^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\s*?'"$(sed -E 's/^[ \t]*//' <<< "$escaped_setting_line")"'^ p } }' $2) ]]; then # If disabled line is not disabled in new file...
          action="disable_setting"
          echo $action"^"$current_section"^"$(sed -n -E 's^\s*?#(.*?)$^\1^p' <<< $(sed -E 's/^[ \t]*//' <<< "$current_setting_line")) >> $3
          fi
        elif [[ ! -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\s*?#'"$(sed -E 's/^[ \t]*//' <<< "$escaped_setting_line")"'^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\s*?#'"$(sed -E 's/^[ \t]*//;' <<< "$escaped_setting_line")"'^ p } }' $2) ]]; then # Check if line is disabled in new file
          action="enable_setting"
          echo $action"^"$current_section"^"$current_setting_line >> $3
        else # Look for setting value differences
          current_setting_name=$(get_setting_name "$escaped_setting_line" $4)
          if [[ (-z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\b'"$current_setting_name"'.*^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\b'"$(sed -E 's/^[ \t]*//;' <<< "$escaped_setting_line")"'$^ p } }' $2)) ]]; then # If the same setting line is not found in the same section of the modified file...
            if [[ ! -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\b'"$current_setting_name"'^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\b'"$current_setting_name"'^ p } }' $2) ]]; then # But the setting exists in that section, only with a different value...
              new_setting_value=$(get_setting_value $2 "$current_setting_name" $4 $current_section)
              action="change"
              echo $action"^"$current_section"^"$(sed -e 's%\\\\%\\%g' <<< "$current_setting_name")"^"$new_setting_value"^"$4 >> $3
            fi
          fi
        fi
      elif [[ (-z $current_section) ]]; then # If line is not in a section...
        if [[ ! -z $(grep -o -P "^\s*?#.*?$" <<< "$current_setting_line") ]]; then # Check for disabled lines
          if [[ -z $(grep -o -P "^\s*?$current_setting_line$" $2) ]]; then # If disabled line is not disabled in new file...
            action="disable_setting"
            echo $action"^"$current_section"^"$(sed -n -E 's^\s*?#(.*?)$^\1^p' <<< "$current_setting_line") >> $3
          fi
        elif [[ ! -z $(sed -n -E '\^\s*?#'"$(sed -E 's/^[ \t]*//' <<< "$escaped_setting_line")"'$^p' $2) ]]; then # Check if line is disabled in new file
            action="enable_setting"
            echo $action"^"$current_section"^"$current_setting_line >> $3
        else # Look for setting value differences
          if [[ (-z $(sed -n -E '\^\s*?\b'"$(sed -E 's/^[ \t]*//' <<< "$escaped_setting_line")"'$^p' $2)) ]]; then # If the same setting line is not found in the modified file...
            current_setting_name=$(get_setting_name "$escaped_setting_line" "$4")
            if [[ ! -z $(sed -n -E '\^\s*?\b'"$current_setting_name"'\s*?[:=]^p' $2) ]]; then # But the setting exists, only with a different value...
              new_setting_value=$(get_setting_value $2 "$current_setting_name" $4)
              action="change"
              echo $action"^"$current_section"^"$(sed -e 's%\\\\%\\%g' <<< "$current_setting_name")"^"$new_setting_value"^"$4 >> $3
            fi
          fi
        fi
      fi
    fi
  done < $1

    # Reset the variables for reuse
    action=""
    current_section=""
    current_setting_name=""
    current_setting_value=""

  while read -r current_setting_line; # Look for new lines (from dynamically generated config files) in modified file compared to original
  do

    printf -v escaped_setting_line '%q' "$current_setting_line" # Take care of special characters before they mess with future commands

    if [[ (! -z $current_setting_line) && (! $current_setting_line == "#!/bin/bash") && (! $current_setting_line == "[]") ]]; then # Ignore empty lines, empty arrays or Bash start lines
      if [[ ! -z $(grep -o -P "^\[.+?\]$" <<< "$current_setting_line") || ! -z $(grep -o -P "^\b.+?:$" <<< "$current_setting_line") ]]; then # Capture section header lines
      if [[ $current_setting_line =~ ^\[.+\] ]]; then # If normal section line
        action="section"
        current_section=$(sed 's^[][]^^g' <<< $current_setting_line) # Remove brackets from section name
        echo "Section found:" "$current_section""."
      elif [[ ! -z $(grep -o -P "^\b.+?:$" <<< "$current_setting_line") ]]; then # If RPCS3 section name
        action="section"
        current_section=$(sed 's^:$^^' <<< $current_setting_line) # Remove colon from section name
        echo "Section found:" "$current_section""."
      fi
      elif [[ (! -z $current_section) ]]; then
        current_setting_name=$(get_setting_name "$escaped_setting_line" "$4")
        if [[ -z $(sed -n -E '\^\['"$current_section"'\]|\b'"$current_section"':$^,\^\b'"$current_setting_name"'.*^{ \^\['"$current_section"'\]|\b'"$current_section"':$^! { \^\b'"$current_setting_name"'^p } }' $1 ) ]]; then # If setting name is not found in this section of the original file...
          action="add_setting"
          echo $action"^"$current_section"^"$current_setting_line"^^"$4 >> $3
        fi
      elif [[ (-z $current_section) ]]; then
        current_setting_name=$(get_setting_name "$escaped_setting_line" "$4")
        if [[ -z $(sed -n -E '\^\s*?\b'"$current_setting_name"'\s*?[:=]^p' $1) ]]; then # If setting name is not found in the original file...
          action="add_setting"
          echo $action"^"$current_section"^"$current_setting_line"^^"$4 >> $3
        fi
      fi
    fi
  done < $2
}

deploy_patch() {

# This function will take an "original" file and a patch file and generate a ready to use modified file
# USAGE: deploy_patch $original_file $patch_file $output_file

cp -fv $1 $3 # Create a copy of the original file to be patched

while IFS="^" read -r action current_section setting_name setting_value system_name
do

    case $action in

	"disable_file" )
        disable_file $setting_name
	;;

	"enable_file" )
        enable_file $setting_name
	;;

	"add_setting" )
        add_setting $3 "$setting_name" $system_name $current_section
	;;

	"disable_setting" )
        disable_setting $3 "$setting_name" $system_name $current_section
	;;

	"enable_setting" )
        enable_setting $3 "$setting_name" $system_name $current_section
	;;

	"change" )
        set_setting_value $3 "$setting_name" "$setting_value" $system_name $current_section
    ;;

	* )
	echo "Config file malformed"
	;;

    esac
done < $2
}

conf_write() {
  # writes the variables in the retrodeck config file

  echo "DEBUG: printing the config file content before writing it:"
  cat "$rd_conf"
  echo ""

  echo "Writing the config file: $rd_conf"

  # TODO: this can be optimized with a while and a list of variables to check
  if [ ! -z "$version" ] #if the variable is not null then I update it
  then
    sed -i "s%version=.*%version=$version%" "$rd_conf"
  fi

  if [ ! -z "$rdhome" ]
  then
    sed -i "s%rdhome=.*%rdhome=$rdhome%" "$rd_conf"
  fi

  if [ ! -z "$roms_folder" ]
  then
    sed -i "s%roms_folder=.*%roms_folder=$roms_folder%" "$rd_conf"
  fi

  if [ ! -z "$saves_folder" ]
  then
    sed -i "s%saves_folder=.*%saves_folder=$saves_folder%" "$rd_conf"
  fi

  if [ ! -z "$states_folder" ]
  then
    sed -i "s%states_folder=.*%states_folder=$states_folder%" "$rd_conf"
  fi

  if [ ! -z "$bios_folder" ]
  then
    sed -i "s%bios_folder=.*%bios_folder=$bios_folder%" "$rd_conf"
  fi

  if [ ! -z "$media_folder" ]
  then
    sed -i "s%media_folder=.*%media_folder=$media_folder%" "$rd_conf"
  fi

  if [ ! -z "$themes_folder" ]
  then
    sed -i "s%themes_folder=.*%themes_folder=$themes_folder%" "$rd_conf"
  fi

  if [ ! -z "$sdcard" ]
  then
    sed -i "s%sdcard=.*%sdcard=$sdcard%" "$rd_conf"
  fi
  echo "DEBUG: New contents:"
  cat "$rd_conf"
  echo ""
}

dir_prep() {
  # This script is creating a symlink preserving old folder contents and moving them in the new one

  # Call me with:
  # dir prep "real dir" "symlink location"
  real="$1"
  symlink="$2"

  echo -e "\n[DIR PREP]\nMoving $symlink in $real" #DEBUG

  # if the dest dir exists we want to backup it
  if [ -d "$symlink" ];
  then
    echo "$symlink found" #DEBUG
    mv -f "$symlink" "$symlink.old"
  fi

  # if the real dir doesn't exist we create it
  if [ ! -d "$real" ];
  then
    echo "$real not found, creating it" #DEBUG
    mkdir -pv "$real"
  fi

  # creating the symlink
  echo "linking $real in $symlink" #DEBUG
  mkdir -pv "$(dirname "$symlink")" # creating the full path except the last folder
  ln -svf "$real" "$symlink"

  # moving everything from the old folder to the new one, delete the old one
  if [ -d "$symlink.old" ];
  then
    echo "Moving the data from $symlink.old to $real" #DEBUG
    mv -f "$symlink".old/* $real
    echo "Removing $symlink.old" #DEBUG
    rm -rf "$symlink.old"
  fi

  echo -e "$symlink is now $real\n"
}

yuzu_init() {
  echo "----------------------"
  echo "Initializing YUZU"
  echo "----------------------"
  # removing dead symlinks as they were present in a past version
  if [ -d $rdhome/bios/switch ]; then
    find $rdhome/bios/switch -xtype l -exec rm {} \;
  fi
  # initializing the keys folder
  dir_prep "$rdhome/bios/switch/keys" "/var/data/yuzu/keys"
  # initializing the firmware folder
  dir_prep "$rdhome/bios/switch/registered" "/var/data/yuzu/nand/system/Contents/registered"
  # initializing the save folders
  dir_prep "$rdhome/saves/switch/yuzu/nand" "/var/data/yuzu/nand"
  dir_prep "$rdhome/saves/switch/yuzu/sdmc" "/var/data/yuzu/sdmc"
  # configuring Yuzu
  dir_prep "$rdhome/.logs/yuzu" "/var/data/yuzu/log"
  mkdir -pv /var/config/yuzu/
  cp -fvr $emuconfigs/yuzu/* /var/config/yuzu/
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/yuzu/qt-config.ini
  dir_prep "$rdhome/screenshots" "/var/data/yuzu/screenshots"
}

dolphin_init() {
  echo "----------------------"
  echo "Initializing DOLPHIN"
  echo "----------------------"
  mkdir -pv /var/config/dolphin-emu/
  cp -fvr "$emuconfigs/dolphin/"* /var/config/dolphin-emu/
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/dolphin-emu/Dolphin.ini
  dir_prep "$rdhome/saves/gc/dolphin/EUR" "/var/data/dolphin-emu/GC/EUR"
  dir_prep "$rdhome/saves/gc/dolphin/USA" "/var/data/dolphin-emu/GC/USA"
  dir_prep "$rdhome/saves/gc/dolphin/JAP" "/var/data/dolphin-emu/GC/JAP"
  dir_prep "$rdhome/screenshots" "/var/data/dolphin-emu/ScreenShots"
  dir_prep "$rdhome/states" "/var/data/dolphin-emu/StateSaves"
  mkdir -pv /var/data/dolphin-emu/Wii/
  dir_prep "$rdhome/saves/wii/dolphin" "/var/data/dolphin-emu/Wii"
}

primehack_init() {
  echo "----------------------"
  echo "Initializing Primehack"
  echo "----------------------"
  mkdir -pv /var/config/primehack/
  cp -fvr "$emuconfigs/primehack/"* /var/config/primehack/
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/primehack/Dolphin.ini
  dir_prep "$rdhome/saves/gc/primehack/EUR" "/var/data/primehack/GC/EUR"
  dir_prep "$rdhome/saves/gc/primehack/USA" "/var/data/primehack/GC/USA"
  dir_prep "$rdhome/saves/gc/primehack/JAP" "/var/data/primehack/GC/JAP"
  dir_prep "$rdhome/screenshots" "/var/data/primehack/ScreenShots"
  dir_prep "$rdhome/states" "/var/data/primehack/StateSaves"
  mkdir -pv /var/data/primehack/Wii/
  dir_prep "$rdhome/saves/wii/primehack" "/var/data/primehack/Wii"
}

pcsx2_init() {
  echo "----------------------"
  echo "Initializing PCSX2"
  echo "----------------------"
  mkdir -pv "/var/config/PCSX2/inis"
  mkdir -pv "$rdhome/saves/ps2/pcsx2/memcards"
  mkdir -pv "$rdhome/states/ps2/pcsx2"
  cp -fvr $emuconfigs/PCSX2/* /var/config/PCSX2/inis/
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/PCSX2/inis/PCSX2_ui.ini
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/PCSX2/inis/PCSX2.ini
  #dir_prep "$rdhome/states/ps2/pcsx2" "/var/config/PCSX2/sstates"
  #dir_prep "$rdhome/screenshots" "/var/config/PCSX2/snaps"
  #dir_prep "$rdhome/.logs" "/var/config/PCSX2/logs"
  #dir_prep "$rdhome/bios" "$rdhome/bios/pcsx2"
}

melonds_init() {
  echo "----------------------"
  echo "Initializing MELONDS"
  echo "----------------------"
  mkdir -pv /var/config/melonDS/
  mkdir -pv "$rdhome/saves/nds/melonds"
  mkdir -pv "$rdhome/states/nds/melonds"
  dir_prep "$rdhome/bios" "/var/config/melonDS/bios"
  cp -fvr $emuconfigs/melonDS.ini /var/config/melonDS/
  # Replace ~/retrodeck with $rdhome as ~ cannot be understood by MelonDS
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/melonDS/melonDS.ini
}

citra_init() {
  echo "------------------------"
  echo "Initializing CITRA"
  echo "------------------------"
  mkdir -pv /var/config/citra-emu/
  mkdir -pv "$rdhome/saves/n3ds/citra/nand/"
  mkdir -pv "$rdhome/saves/n3ds/citra/sdmc/"
  dir_prep "$rdhome/bios/citra/sysdata" "/var/data/citra-emu/sysdata"
  dir_prep "$rdhome/.logs/citra" "/var/data/citra-emu/log"
  cp -fv $emuconfigs/citra-qt-config.ini /var/config/citra-emu/qt-config.ini
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/citra-emu/qt-config.ini
  #TODO: do the same with roms folders after new variables is pushed (check even the others qt-emu)
  #But actually everything is always symlinked to retrodeck/roms so it might be not needed
  #sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/citra-emu/qt-config.ini
}

rpcs3_init() {
  echo "------------------------"
  echo "Initializing RPCS3"
  echo "------------------------"
  mkdir -pv /var/config/rpcs3/
  cp -fvr $emuconfigs/rpcs3/* /var/config/rpcs3/
  sed -i 's#/home/deck/retrodeck#'$rdhome'#g' /var/config/rpcs3/vfs.yml
}

xemu_init() {
  echo "------------------------"
  echo "Initializing XEMU"
  echo "------------------------"
  mkdir -pv $rdhome/saves/xbox/xemu/
  mkdir -pv /var/data/xemu/
  cp -fv $emuconfigs/xemu.toml /var/data/xemu/xemu.toml
  sed -i 's#/home/deck/retrodeck#'$rdhome'#g' /var/data/xemu/xemu.toml
  # Preparing HD dummy Image if the image is not found
  if [ ! -f $rdhome/bios/xbox_hdd.qcow2 ]
  then
    wget "https://github.com/mborgerson/xemu-hdd-image/releases/latest/download/xbox_hdd.qcow2.zip" -P $rdhome/bios/
    unzip -q $rdhome/bios/xbox_hdd.qcow2.zip -d $rdhome/bios/
    rm -rfv $rdhome/bios/xbox_hdd.qcow2.zip
  fi
}

ppssppsdl_init() {
  echo "------------------------"
  echo "Initializing PPSSPPSDL"
  echo "------------------------"
  mkdir -p /var/config/ppsspp/PSP/SYSTEM/
  cp -fv $emuconfigs/ppssppsdl/* /var/config/ppsspp/PSP/SYSTEM/
  sed -i 's#/home/deck/retrodeck#'$rdhome'#g' /var/config/ppsspp/PSP/SYSTEM/ppsspp.ini
}

duckstation_init() {
  echo "------------------------"
  echo "Initializing DUCKSTATION"
  echo "------------------------"
  mkdir -p /var/config/duckstation/
  cp -fv $emuconfigs/duckstation/* /var/config/duckstation
  sed -i 's#/home/deck/retrodeck/bios#'$rdhome/bios'#g' /var/config/duckstation/settings.ini
}

ryujinx_init() {
  echo "------------------------"
  echo "Initializing RYUJINX"
  echo "------------------------"
  mkdir -p /var/config/Ryujinx/system
  cp -fv $emuconfigs/ryujinx/* /var/config/Ryujinx
  sed -i 's#/home/deck/retrodeck#'$rdhome'#g' /var/config/Ryujinx/Config.json
  dir_prep "$rdhome/bios/switch/keys" "/var/config/Ryujinx/system"
}

standalones_init() {
  # This script is configuring the standalone emulators with the default files present in emuconfigs folder

  echo "------------------------------------"
  echo "Initializing standalone emulators"
  echo "------------------------------------"
  citra_init
  dolphin_init
  duckstation_init
  melonds_init
  pcsx2_init
  ppssppsdl_init
  primehack_init
  rpcs3_init
  ryujinx_init
  xemu_init
  yuzu_init
}

emulators_post_move() {
  # This script will redo the symlinks for all emulators after moving the $rdhome location without resetting other options
  # FUTURE WORK: The sed commands here should be replaced with set_setting_value and dir_prep should be replaced with changing paths in config files directly where possible

  # ES section
  dir_prep $roms_folder "/var/config/emulationstation/ROMs"

  # RA section
  dir_prep "$rdhome/bios" "/var/config/retroarch/system"
  dir_prep "$rdhome/.logs/retroarch" "/var/config/retroarch/logs"
  dir_prep "$rdhome/shaders/retroarch" "/var/config/retroarch/shaders"

  # Yuzu section
  dir_prep "$rdhome/bios/switch/keys" "/var/data/yuzu/keys"
  dir_prep "$rdhome/bios/switch/registered" "/var/data/yuzu/nand/system/Contents/registered"
  dir_prep "$rdhome/saves/switch/yuzu/nand" "/var/data/yuzu/nand"
  dir_prep "$rdhome/saves/switch/yuzu/sdmc" "/var/data/yuzu/sdmc"
  dir_prep "$rdhome/.logs/yuzu" "/var/data/yuzu/log"
  dir_prep "$rdhome/screenshots" "/var/data/yuzu/screenshots"
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/yuzu/qt-config.ini

  # Dolphin section
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/dolphin-emu/Dolphin.ini
  dir_prep "$rdhome/saves/gc/dolphin/EUR" "/var/data/dolphin-emu/GC/EUR"
  dir_prep "$rdhome/saves/gc/dolphin/USA" "/var/data/dolphin-emu/GC/USA"
  dir_prep "$rdhome/saves/gc/dolphin/JAP" "/var/data/dolphin-emu/GC/JAP"
  dir_prep "$rdhome/screenshots" "/var/data/dolphin-emu/ScreenShots"
  dir_prep "$rdhome/states" "/var/data/dolphin-emu/StateSaves"
  dir_prep "$rdhome/saves/wii/dolphin" "/var/data/dolphin-emu/Wii/"

  # Primehack section
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/primehack/Dolphin.ini
  dir_prep "$rdhome/saves/gc/primehack/EUR" "/var/data/primehack/GC/EUR"
  dir_prep "$rdhome/saves/gc/primehack/USA" "/var/data/primehack/GC/USA"
  dir_prep "$rdhome/saves/gc/primehack/JAP" "/var/data/primehack/GC/JAP"
  dir_prep "$rdhome/screenshots" "/var/data/primehack/ScreenShots"
  dir_prep "$rdhome/states" "/var/data/primehack/StateSaves"
  dir_prep "$rdhome/saves/wii/primehack" "/var/data/primehack/Wii/"

  # PCSX2 section
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/PCSX2/inis/PCSX2_ui.ini
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/PCSX2/inis/PCSX2.ini

  # MelonDS section
  dir_prep "$rdhome/bios" "/var/config/melonDS/bios"
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/melonDS/melonDS.ini

  # Citra section
  dir_prep "$rdhome/bios/citra/sysdata" "/var/data/citra-emu/sysdata"
  dir_prep "$rdhome/.logs/citra" "/var/data/citra-emu/log"
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/citra-emu/qt-config.ini

  # RPCS3 section
  sed -i 's#/home/deck/retrodeck#'$rdhome'#g' /var/config/rpcs3/vfs.yml

  # XEMU section
  sed -i 's#/home/deck/retrodeck#'$rdhome'#g' /var/data/xemu/xemu.toml

  # PPSSPP Standalone section
  sed -i 's#/home/deck/retrodeck#'$rdhome'#g' /var/config/ppsspp/PSP/SYSTEM/ppsspp.ini

  # Duckstation section
  sed -i 's#/home/deck/retrodeck/bios#'$rdhome/bios'#g' /var/config/duckstation/settings.ini

  # Ryujinx section
  sed -i 's#/home/deck/retrodeck#'$rdhome'#g' /var/config/Ryujinx/Config.json
  dir_prep "$rdhome/bios/switch/keys" "/var/config/Ryujinx/system"
}

#=========================
# REUSABLE DIALOGS SECTION
#=========================

debug_dialog() {
  # This function is for displaying commands run by the Configurator without actually running them
  # USAGE: debug_dialog "command"

  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - Debug Dialog" \
  --text="$1"
}

configurator_process_complete_dialog() {
  # This dialog shows when a process is complete.
  # USAGE: configurator_process_complete_dialog "process text"
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Quit" --extra-button="OK" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility - Process Complete" \
  --text="The process of $1 is now complete.\n\nYou may need to quit and restart RetroDECK for your changes to take effect\n\nClick OK to return to the Main Menu or Quit to return to RetroDECK."

  if [ ! $? == 0 ] # OK button clicked
  then
      configurator_welcome_dialog
  fi
}

configurator_generic_dialog() {
  # This dialog is for showing temporary messages before another process happens.
  # USAGE: configurator_generid_dialog "info text"
  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Configurator Utility" \
  --text="$1"
}

configurator_destination_choice_dialog() {
  # This dialog is for making things easy for new users to move files to common locations. Gives the options for "Internal", "SD Card" and "Custom" locations.
  # USAGE: $(configurator_destination_choice_dialog "folder being moved" "action text")
  # This function returns one of the values: "Back" "Internal Storage" "SD Card" "Custom Location"
  choice=$(zenity --title "RetroDECK Configurator Utility - Moving $1 folder" --info --no-wrap --ok-label="Back" --extra-button="Internal Storage" --extra-button="SD Card" --extra-button="Custom Location" \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --text="$2")

  echo $choice
}

#=========================
# LEGACY FUNCTIONS SECTION
#=========================

# These functions were pulled from retrodeck.sh or global.sh and should be consolidated eventually

tools_init() {
  rm -rfv /var/config/retrodeck/tools/
  mkdir -pv /var/config/retrodeck/tools/
  cp -rfv /app/retrodeck/tools/* /var/config/retrodeck/tools/
  mkdir -pv /var/config/emulationstation/.emulationstation/custom_systems/tools/
  rm -rfv /var/config/retrodeck/tools/gamelist.xml
  cp -fv /app/retrodeck/tools-gamelist.xml /var/config/retrodeck/tools/gamelist.xml
}

ra_init() {
  dir_prep "$rdhome/bios" "/var/config/retroarch/system"
  dir_prep "$rdhome/.logs/retroarch" "/var/config/retroarch/logs"
  mkdir -pv /var/config/retroarch/shaders/
  cp -rfv /app/share/libretro/shaders /var/config/retroarch/
  dir_prep "$rdhome/shaders/retroarch" "/var/config/retroarch/shaders"
  mkdir -pv /var/config/retroarch/cores/
  cp -f /app/share/libretro/cores/* /var/config/retroarch/cores/
  cp -fv $emuconfigs/retroarch/retroarch.cfg /var/config/retroarch/
  cp -fv $emuconfigs/retroarch/retroarch-core-options.cfg /var/config/retroarch/
  cp -rfv $emuconfigs/retroarch/core-overrides/* /var/config/retroarch/config
  #rm -rf $rdhome/bios/bios # in some situations a double bios symlink is created
  sed -i 's#~/retrodeck#'$rdhome'#g' /var/config/retroarch/retroarch.cfg

  # PPSSPP
  echo "--------------------------------"
  echo "Initializing PPSSPP_LIBRETRO"
  echo "--------------------------------"
  if [ -d $rdhome/bios/PPSSPP/flash0/font ]
  then
    mv -fv $rdhome/bios/PPSSPP/flash0/font $rdhome/bios/PPSSPP/flash0/font.bak
  fi
  mkdir -p $rdhome/bios/PPSSPP
  #if [ ! -f "$rdhome/bios/PPSSPP/ppge_atlas.zim" ]
  #then
    wget "https://github.com/hrydgard/ppsspp/archive/refs/heads/master.zip" -P $rdhome/bios/PPSSPP
    unzip -q "$rdhome/bios/PPSSPP/master.zip" -d $rdhome/bios/PPSSPP/
    mv -f "$rdhome/bios/PPSSPP/ppsspp-master/assets/"* "$rdhome/bios/PPSSPP/"
    rm -rfv "$rdhome/bios/PPSSPP/master.zip"
    rm -rfv "$rdhome/bios/PPSSPP/ppsspp-master"
  #fi
  if [ -d $rdhome/bios/PPSSPP/flash0/font.bak ]
  then
    mv -fv $rdhome/bios/PPSSPP/flash0/font.bak $rdhome/bios/PPSSPP/flash0/font
  fi

  # MSX / SVI / ColecoVision / SG-1000
  echo "-----------------------------------------------------------"
  echo "Initializing MSX / SVI / ColecoVision / SG-1000 LIBRETRO"
  echo "-----------------------------------------------------------"
  wget "http://bluemsx.msxblue.com/rel_download/blueMSXv282full.zip" -P $rdhome/bios/MSX
  unzip -q "$rdhome/bios/MSX/blueMSXv282full.zip" -d $rdhome/bios/MSX
  mv -f $rdhome/bios/MSX/Databases $rdhome/bios/Databases
  mv -f $rdhome/bios/MSX/Machines $rdhome/bios/Machines
  rm -rfv $rdhome/bios/MSX
}

create_lock() {
  # creating RetroDECK's lock file and writing the version in the config file
  version=$hard_version
  touch "$lockfile"
  conf_write
}

start_retrodeck() {
  # normal startup
  echo "Starting RetroDECK v$version"
  emulationstation --home /var/config/emulationstation
}

finit_browse() {
# Function for choosing data directory location during first/forced init
path_selected=false
while [ $path_selected == false ]
do
  sdcard="$(zenity --file-selection --title="Choose RetroDECK data directory location" --directory)"
  if [[ $? == 0 ]]; then
    if [[ -w $sdcard ]]; then
      zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" \
      --cancel-label="No" \
      --ok-label "Yes" \
      --text="Your RetroDECK data folder will be:\n\n$sdcard/retrodeck\n\nis that ok?"
      if [ $? == 0 ] #yes
      then
        path_selected=true
        echo "$sdcard/retrodeck"
        break
      else
        zenity --question --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --cancel-label="No" --ok-label "Yes" --text="Do you want to quit?"
        if [ $? == 0 ] # yes, quit
        then
          exit 2
        fi
      fi
    fi
  else
    zenity --error --no-wrap \
    --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
    --title "RetroDECK" \
    --ok-label "Quit" \
    --text="No location was selected. Please run RetroDECK again to retry."
    exit 2
  fi
done
}

finit() {
# Force/First init, depending on the situation

  echo "Executing finit"

  # Internal or SD Card?
  choice=$(configurator_destination_choice_dialog "RetroDECK data" "Welcome to the first configuration of RetroDECK.\nThe setup will be quick but please READ CAREFULLY each message in order to avoid misconfigurations.\n\nWhere do you want your RetroDECK data folder to be located?\n\nThis folder will contain all ROMs, BIOSs and scraped data." )
  echo "Choice is $choice"

  case $choice in

  "" ) # Cancel or X button quits
    echo "Now quitting"
    exit 2
  ;;

  "Internal Storage" ) # Internal
    echo "Internal selected"
    rdhome="$HOME/retrodeck"
    roms_folder="$rdhome/roms"
    saves_folder="$rdhome/saves"
    states_folder="$rdhome/states"
    bios_folder="$rdhome/bios"
    media_folder="$rdhome/downloaded_media"
    themes_folder="$rdhome/themes"
    if [[ -L $rdhome ]]; then #Remove old symlink from existing install, if it exists
      unlink $rdhome
    fi
  ;;

  "SD Card" )
    echo "SD Card selected"
    if [ ! -d "$sdcard" ] # SD Card path is not existing
    then
      echo "Error: SD card not found"
      zenity --error --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK" \
      --ok-label "Browse" \
      --text="SD Card was not find in the default location.\nPlease choose the SD Card root.\nA retrodeck folder will be created starting from the directory that you selected."
      rdhome=$(finit_browse) # Calling the browse function
      if [[ -z $rdhome ]]; then # If user hit the cancel button
        exit 2
      fi
      roms_folder="$rdhome/roms"
      saves_folder="$rdhome/saves"
      states_folder="$rdhome/states"
      bios_folder="$rdhome/bios"
      media_folder="$rdhome/downloaded_media"
      themes_folder="$rdhome/themes"
    elif [ ! -w "$sdcard" ] #SD card found but not writable
      then
        echo "Error: SD card found but not writable"
        zenity --error --no-wrap \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK" \
        --ok-label "Quit" \
        --text="SD card was found but is not writable\nThis can happen with cards formatted on PC.\nPlease format the SD card through the Steam Deck's Game Mode and run RetroDECK again."
        echo "Now quitting"
        exit 2
    else
      rdhome="$sdcard/retrodeck"
      roms_folder="$rdhome/roms"
      saves_folder="$rdhome/saves"
      states_folder="$rdhome/states"
      bios_folder="$rdhome/bios"
      media_folder="$rdhome/downloaded_media"
      themes_folder="$rdhome/themes"
    fi
  ;;

  "Custom Location" )
      echo "Custom Location selected"
      zenity --info --no-wrap \
      --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
      --title "RetroDECK" \
      --ok-label "Browse" \
      --text="Please choose the root folder for the RetroDECK data.\nA retrodeck folder will be created starting from the directory that you selected."
      rdhome=$(finit_browse) # Calling the browse function
      if [[ -z $rdhome ]]; then # If user hit the cancel button
        exit 2
      fi
      roms_folder="$rdhome/roms"
      saves_folder="$rdhome/saves"
      states_folder="$rdhome/states"
      bios_folder="$rdhome/bios"
      media_folder="$rdhome/downloaded_media"
      themes_folder="$rdhome/themes"
    ;;

  esac

  if [[ ! "$rdhome" == "$HOME/retrodeck" && ! -L $HOME/retrodeck ]]; then # If data stored on SD card, create /home/deck/retrodeck symlink to keep things working until configs can get modified
    echo "Symlinking retrodeck directory to home directory"
    dir_prep "$rdhome" "$HOME/retrodeck"
  fi

  mkdir -pv $roms_folder

  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --text="RetroDECK will now install the needed files.\nPlease wait up to one minute,\nanother message will notify when the process will be finished.\n\nPress OK to continue."

  # Recreating the folder
  rm -rfv /var/config/emulationstation/
  rm -rfv /var/config/retrodeck/tools/
  mkdir -pv /var/config/emulationstation/

  # Initializing ES-DE
  # TODO: after the next update of ES-DE this will not be needed - let's test it
  emulationstation --home /var/config/emulationstation --create-system-dirs

  mkdir -pv /var/config/retrodeck/tools/

  #zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" --title "RetroDECK" --text="RetroDECK will now install the needed files.\nPlease wait up to one minute,\nanother message will notify when the process will be finished.\n\nPress OK to continue."

  # Initializing ROMs folder - Original in retrodeck home (or SD Card)
  dir_prep $roms_folder "/var/config/emulationstation/ROMs"

  mkdir -pv $saves_folder
  mkdir -pv $states_folder
  mkdir -pv $rdhome/screenshots
  mkdir -pv $rdhome/bios/pico8
  mkdir -pv $rdhome/.logs

  # XMLSTARLET HERE
  cp -fv /app/retrodeck/es_settings.xml /var/config/emulationstation/.emulationstation/es_settings.xml

  # ES-DE preparing themes and scraped folders
  dir_prep "$media_folder" "/var/config/emulationstation/.emulationstation/downloaded_media"
  dir_prep "$themes_folder" "/var/config/emulationstation/.emulationstation/themes"

  # PICO-8
  dir_prep "$roms_folder/pico8" "$rdhome/bios/pico8/bbs/carts" #this is the folder where pico-8 is saving the carts

  (
  ra_init
  standalones_init
  tools_init
  ) |
  zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK Finishing Initialization" \
  --text="RetroDECK is finishing the initial setup process, please wait."

  create_lock

  zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap \
  --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
  --title "RetroDECK" \
  --text="Installation completed.\nPlease put your roms in:\n\n$roms_folder\n\nand your bioses in\n\n$bios_folder\n\nThen start the program again.\nIf you wish to change the roms location, you may use the tool located the tools section of RetroDECK.\n\nIMPORTANT NOTES:\n- RetroDECK must be manually added and launched from your Steam Library in order to work correctly.\n- It's recommended to use the 'RetroDECK Offical Controller Config' from Steam (under community layouts).\n- It's suggested to use BoilR to automatically add the SteamGridDB images to Steam (this will be automated soon).\nhttps://github.com/PhilipK/BoilR"
  # TODO: Replace the stuff above with BoilR code when ready
}