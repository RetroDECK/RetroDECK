#!/bin/bash
# Compare the retroarch core configurations made by EmuDeck with those by RetroDECK
# Set KEEP_EMUDECK_CONFIGS env variable to keep the EmuDeck configs in the "emudeck_ra_configs" directory

[[ $# != 2 ]] && echo "Usage: cmp_emudeck [EmuDeck Repo Path] [RetroArch Core]
Example: cmp_emudeck ~/EmuDeck melonds" && exit 1

emudeck_ra_path="$1/functions/EmuScripts/emuDeckRetroArch.sh"
retrodeck_ra_path="$(dirname "$0")/../emu-configs/retroarch/retroarch-core-options.cfg"
core="$2"

# Sanity checks
if [ ! -f "$emudeck_ra_path" ]; then 
  echo "Error: There is something wrong with the EmuDeck path"
  exit 1
fi
if [[ -z $(grep $core $retrodeck_ra_path) ]]; then
  echo "Error: The core could not be found"
  exit 1
fi

# Setup
[[ -d "emudeck_ra_configs" ]] || mkdir emudeck_ra_configs
echo -n "" > emudeck_ra_configs/"$core".cfg

# Get EmuDeck values of core options
grep RetroArch_setOverride $emudeck_ra_path | grep $core | while read -r line ; do
  option=$(echo "$line" | cut -d' ' -f5 | tr -d "'")
  value=$(echo "$line" | sed 's/^[^"]*"/"/' | tr -d "'")
  echo "$option = $value" >> emudeck_ra_configs/"$core".cfg
done

sort -o "emudeck_ra_configs/$core.cfg"{,}

diff -y --suppress-common-lines <(grep $core $retrodeck_ra_path) \
                                emudeck_ra_configs/$core.cfg

# Cleanup
[[ -z "${KEEP_EMUDECK_CONFIGS}" ]] && rm -rf emudeck_ra_configs
