#!/bin/bash
# This scritp is installing the required dependencies to correctly run the pipeline and buold the flatpak

sudo apt install -y flatpak flatpak-builder p7zip-full xmlstarlet bzip2 curl
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo