#!/bin/bash

# EDITABLES:
#rd_branch="main"
rd_branch="cooker"
#gits_folder=~/gits
gits_folder="/home/public-folder/gits" # without last /

# NON-EDITABLES
branch="$rd_branch-"$(date +%d%m%y.%H%M)

cd $gits_folder
rm -rf flathub
git clone --recursive https://github.com/flathub/net.retrodeck.retrodeck.git flathub
cd $gits_folder/RetroDECK
git checkout $rd_branch
git submodule init
git submodule update
# NOTE: the only linked submodules are: rd-submodules/retroarch
# these must be included in the exclusion list as they must be redownloaded
#sync -rav --progress --exclude={'res/screenshots/','shared-modules/','rd-submodules/retroarch','.git/','docs','retrodeck-flatpak/','retrodeck-flatpak-cooker/','.flatpak-builder/'} ~/RetroDECK/ ~/flathub/

cd $gits_folder/flathub
git checkout -b $branch
git rm -rf *
git clean -fxd # restroing git index

# Copying only a few files as the others are cloned by git in retrodeck.sh
cd $gits_folder/RetroDECK
cp -rf \
'rd-submodules' \
'flathub.json' \
'LICENSE' \
'net.retrodeck.retrodeck.appdata.xml' \
'net.retrodeck.retrodeck.desktop' \
'net.retrodeck.retrodeck.yml' \
'README.md' \
$gits_folder/flathub/
cd $gits_folder/flathub

# #rebuilding submodules
# git config -f .gitmodules --get-regexp '^submodule\..*\.path$' |
#     while read path_key path
#     do
#         url_key=$(echo $path_key | sed 's/\.path/.url/');
#         branch_key=$(echo $path_key | sed 's/\.path/.branch/');
#         # If the url_key doesn't yet exist then backup up the existing
#         # directory if necessary and add the submodule
#         if [ ! $(git config --get "$url_key") ]; then
#             if [ -d "$path" ] && [ ! $(git config --get "$url_key") ]; then
#                 mv "$path" "$path""_backup_""$(date +'%Y%m%d%H%M%S')";
#             fi;
#             url=$(git config -f .gitmodules --get "$url_key");
#             # If a branch is specified then use that one, otherwise
#             # default to master
#             branch=$(git config -f .gitmodules --get "$branch_key");
#             if [ ! "$branch" ]; then branch="master"; fi;
#             git submodule add -f -b "$branch" "$url" "$path";
#         fi;
#     done;

# # In case the submodule exists in .git/config but the url is out of date
# git submodule sync

# # Now actually pull all the modules. I used to use this...
# git submodule foreach --recursive 'git checkout $(git config -f $toplevel/.gitmodules submodule.$name.branch || echo master)';

rm -rf .git/modules/*
# Adding the real submodules, please update this every time a submodule is added
git rm -rf shared-modules
git submodule add https://github.com/flathub/shared-modules.git shared-modules

git rm -rf rd-submodules/retroarch
git submodule add https://github.com/flathub/org.libretro.RetroArch.git rd-submodules/retroarch

# unbinds all submodules
git submodule deinit -f .
# checkout again
git submodule update --init --recursive
git add *
git commit -m "Updated flathub/net.retrodeck.retrodeck from RetroDECK/$rd_branch"
git push origin $branch