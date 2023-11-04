#!/bin/bash

mkdir /tmp

branch="00a226062fff37209d98e0ab048ac89af50ecacc"
git clone "https://gitlab.com/es-de/emulationstation-de.git" /tmp/emulationstation-de

pushd .
cd /tmp/emulationstation-de
git checkout $branch
popd

mkdir patches-tmp

cp /tmp/emulationstation-de/es-app/src/guis/GuiMenu.cpp             ./patches-tmp
cp /tmp/emulationstation-de/es-app/src/guis/GuiMenu.h               ./patches-tmp
cp /tmp/emulationstation-de/es-app/src/views/ViewController.cpp     ./patches-tmp
cp /tmp/emulationstation-de/es-core/src/Window.cpp                  ./patches-tmp
cp /tmp/emulationstation-de/es-app/src/guis/GuiThemeDownloader.cpp  ./patches-tmp

read -p "Please edit the files in \"patches-tmp\" and press enter to continue."

diff -au1r /tmp/emulationstation-de/es-app/src/guis/GuiMenu.cpp             ./patches-tmp/GuiMenu.cpp               > GuiMenu.cpp.patch
diff -au1r /tmp/emulationstation-de/es-app/src/guis/GuiMenu.h               ./patches-tmp/GuiMenu.h                 > GuiMenu.h.patch 
diff -au1r /tmp/emulationstation-de/es-app/src/views/ViewController.cpp     ./patches-tmp/ViewController.cpp        > ViewController.cpp.patch            
diff -au1r /tmp/emulationstation-de/es-core/src/Window.cpp                  ./patches-tmp/Window.cpp                > Window.cpp.patch
diff -au1r /tmp/emulationstation-de/es-app/src/guis/GuiThemeDownloader.cpp  ./patches-tmp/GuiThemeDownloader.cpp    > GuiThemeDownloader.cpp.patch

rm -rf patches-tmp

echo "Done, now please remeber to edit the headers of the patch files with the correct paths."