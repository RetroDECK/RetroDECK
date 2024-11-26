#!/bin/bash

config="/app/retrodeck/config"  
features=$config/retrodeck/reference_lists/features.json

jq . $features > $features.tmp && mv -f $features.tmp $features