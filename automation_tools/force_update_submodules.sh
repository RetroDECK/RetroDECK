#!/bin/bash

# WARNING: DANGEROUS! Don't use this script lightly

git submodule deinit --all
rm rd-submodules/retroarch
git rm -rf --cached rd-submodules/retroarch
rm -rf .git/modules/rd-submodules/retroarch
rm -rf shared-modules
git rm -rf --cached shared-modules
rm -rf .git/modules/shared-modules

git submodule init
git submodule add https://github.com/flathub/shared-modules.git
git submodule add https://github.com/flathub/org.libretro.RetroArch rd-submodules/retroarch

git submodule update --remote --merge --recursive