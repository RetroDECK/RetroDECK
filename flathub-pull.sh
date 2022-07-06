#!/bin/bash

mkdir backup
mv net.retrodeck.retrodeck.yml backup
mv net.retrodeck.retrodeck.appdata.xml backup
wget https://raw.githubusercontent.com/flathub/net.retrodeck.retrodeck/master/net.retrodeck.retrodeck.yml
wget https://raw.githubusercontent.com/flathub/net.retrodeck.retrodeck/master/net.retrodeck.retrodeck.appdata.xml
git add net.retrodeck.retrodeck.yml
git add net.retrodeck.retrodeck.appdata.xml
git commit -m "Pulled from flathub"