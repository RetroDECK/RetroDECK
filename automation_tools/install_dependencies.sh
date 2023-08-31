#!/bin/bash
sudo apt install -y flatpak flatpak-builder p7zip-full xmlstarlet bzip2 curl
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo