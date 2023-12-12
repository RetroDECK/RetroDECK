#!/bin/bash

# WARNING: DANGEROUS! Don't use this script lightly

git submodule deinit --all
rm rd-submodules/retroarch
git rm -rf --cached rd-submodules/retroarch
rm -rf .git/modules/rd-submodules/retroarch
rm rd-submodules/ryujinx
git rm -rf --cached rd-submodules/ryujinx
rm -rf .git/modules/rd-submodules/ryujinx
rm -rf rd-submodules/shared-modules
git rm -rf --cached rd-submodules/shared-modules
rm -rf .git/modules/rd-submodules/shared-modules

git submodule init
git submodule add https://github.com/flathub/shared-modules.git rd-submodules/shared-modules
git submodule add https://github.com/flathub/org.libretro.RetroArch rd-submodules/retroarch
git submodule add https://github.com/flathub/org.ryujinx.Ryujinx rd-submodules/ryujinx

git submodule update --remote --merge --recursive