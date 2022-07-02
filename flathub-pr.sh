#!/bin/bash

cd ~
rm -rf flathub
git clone --branch=RetroDECK --recursive https://github.com/XargonWan/flathub.git
cd ~/RetroDECK
git checkout main
git submodule init
git submodule update
# NOTE: the only linked submodules are: rd-submodules/retroarch
# these must be included in the exclusion list as they must be redownloaded
#sync -rav --progress --exclude={'res/screenshots/','shared-modules/','rd-submodules/retroarch','.git/','docs','retrodeck-flatpak/','retrodeck-flatpak-cooker/','.flatpak-builder/'} ~/RetroDECK/ ~/flathub/

sync -rav --progress { \
'overlays', \
'rd-submodules', \
'flathub.json', \
'LICENSE', \
'net.retrodeck.retrodeck.appdata.xml', \
'net.retrodeck.retrodeck.desktop', \
'net.retrodeck.retrodeck.yml', \
'README.md', \
} ~/flathub/

cd ~/flathub
git rm -r *
# NOTE: be careful to remove the REAL (linked) submodules only
rm -rf shared-modules
rm -rf rd-submodules/retroarch

# rebuilding submodules
git config -f .gitmodules --get-regexp '^submodule\..*\.path$' |
    while read path_key path
    do
        url_key=$(echo $path_key | sed 's/\.path/.url/');
        branch_key=$(echo $path_key | sed 's/\.path/.branch/');
        # If the url_key doesn't yet exist then backup up the existing
        # directory if necessary and add the submodule
        if [ ! $(git config --get "$url_key") ]; then
            if [ -d "$path" ] && [ ! $(git config --get "$url_key") ]; then
                mv "$path" "$path""_backup_""$(date +'%Y%m%d%H%M%S')";
            fi;
            url=$(git config -f .gitmodules --get "$url_key");
            # If a branch is specified then use that one, otherwise
            # default to master
            branch=$(git config -f .gitmodules --get "$branch_key");
            if [ ! "$branch" ]; then branch="master"; fi;
            git submodule add -f -b "$branch" "$url" "$path";
        fi;
    done;

# In case the submodule exists in .git/config but the url is out of date

git submodule sync;

# Now actually pull all the modules. I used to use this...
git submodule foreach --recursive 'git checkout $(git config -f $toplevel/.gitmodules submodule.$name.branch || echo master)';

git submodule update
git add *
git commit -m "Updating flathub"
git push origin RetroDECK