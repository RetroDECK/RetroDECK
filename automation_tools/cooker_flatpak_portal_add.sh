#!/bin/bash

# COOKER ONLY
# This script is adding the update portal (permission) to the ooker flatpak.
# This is ran by the cooker pipeline.

sed -i '/finish-args:/a \ \ - --talk-name=org.freedesktop.Flatpak' net.retrodeck.retrodeck.yml