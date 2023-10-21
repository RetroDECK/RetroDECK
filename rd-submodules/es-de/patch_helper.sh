#!/bin/bash

mkdir /tmp

branch="2de8282f6a5feaf86424b1175154c5fc2585f70a"
git clone "https://gitlab.com/es-de/emulationstation-de.git" /tmp/emulationstation-de

pushd .
cd /tmp/emulationstation-de
git checkout $branch
popd

mkdir patches-tmp

cp /tmp/emulationstation-de/es-app/src/guis/GuiMenu.cpp         ./patches-tmp
cp /tmp/emulationstation-de/es-app/src/guis/GuiMenu.h           ./patches-tmp
cp /tmp/emulationstation-de/es-app/src/views/ViewController.cpp ./patches-tmp
cp /tmp/emulationstation-de/es-core/src/Window.cpp              ./patches-tmp

read -p "Please edit the files in \"patches-tmp\" and press enter to continue."

diff -au1r /tmp/emulationstation-de/es-app/src/guis/GuiMenu.cpp         ./patches-tmp/GuiMenu.cpp           > GuiMenu.cpp.patch
diff -au1r /tmp/emulationstation-de/es-app/src/guis/GuiMenu.h           ./patches-tmp/GuiMenu.h             > GuiMenu.h.patch 
diff -au1r /tmp/emulationstation-de/es-app/src/views/ViewController.cpp ./patches-tmp/ViewController.cpp    > ViewController.cpp.patch            
diff -au1r /tmp/emulationstation-de/es-core/src/Window.cpp              ./patches-tmp/Window.cpp            > Window.cpp.patch

#rm -rf patches-tmp