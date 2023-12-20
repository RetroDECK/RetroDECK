#!/bin/bash

flatpak install -y flathub org.flatpak.Builder

flatpak run --command=appstream-util org.flatpak.Builder validate -v net.retrodeck.retrodeck.appdata.xml