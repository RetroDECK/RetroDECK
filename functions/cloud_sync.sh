#!/bin/bash

#TODO: 
# - remove hard code
# - add multi-user support
# - save remote name somewhere (and maybe make customisable remote name)
# - optional: back up to mutliple remotes (by replacing $rdhome with a different remote)
# - add exclusion options (to have multiple playthroughs for different devices)


#--backup-dir requires v1.66
#Options for resync-mode (also requires v1.66): 
#    - path1 (local files always win), 
#    - path2 (remote files always win), 
#    - newer (newer files always win), 
#    - older (older files always win), 
#    - larger (larger files always win), 
#    - smaller (smaller files always win)

set_cloud() { # 1=cloud-provider 2=resync-mode 3=username 4=password 5=host/URL 6=port
    #TODO: only trigger this log when browser authentication needed
    log i "Configurator: Opening browser and authenticating"
    case $1 in
        box)
            rclone --fast-list --ignore-checksum config create RetroDECK box
            ;;
        dropbox)
            rclone --fast-list --ignore-checksum config create RetroDECK dropbox
            ;;
        drive)
            rclone --fast-list --ignore-checksum config create RetroDECK drive scope=drive
            ;;
        onedrive)
            rclone --fast-list --ignore-checksum config create RetroDECK onedrive drive_type=personal access_scopes=Files.ReadWrite,offline_access
            ;;
        #TODO for ftp, smb, webdav: check how passwords are stored, is it secure?
        ftp)
            rclone --fast-list --ignore-checksum config create RetroDECK ftp host=$5 port=$6 username=$3 password=$4
            ;;
        smb)
            rclone --fast-list --ignore-checksum config create RetroDECK smb host=$5 port=$6 username=$3 password=$4
            ;;
        fastmail | nextcloud | owncloud | sharepoint | sharepoint-ntlm | rclone | other)
            # TODO: add filtering to allow both base URL and webdav URL to be added (nextcloud-instance.com and nextcloud-instance.com/remote.php/dav/files/USERNAME/ would both be valid inputs)
            rclone --fast-list --ignore-checksum config create RetroDECK webdav url=$5 username=$3 password=$4 provider=$1
            ;;
        *)
            exit
            ;;
    esac
    rclone mkdir RetroDECK:/RetroDECK
    rclone mkdir RetroDECK:/RetroDECK_backup
    touch $rdhome/RCLONE_TEST
    mkdir $rdhome/../retrodeck_backup
    #TODO: discuss which other directories are eligable for syncing, and add them to the include flag (or user choice). 
    rclone --copy-links --check-first bisync --resync --resync-mode $2 $rdhome RetroDECK:/RetroDECK --include "{saves,screenshots}/**" --backup-dir1 ~/retrodeck_backup --backup-dir2 RetroDECK:/RetroDECK_backup
}

unset_cloud() {
    rclone config delete RetroDECK
}


#Theoretically, you only need to push to the cloud after quitting a game, and pull just before starting. The bisync option has some nice extra options, however, so the preferable workflow needs to be discussed.

sync_cloud() { #1=resolver type (none, newer, older, larger, smaller, path1, path2)
    # --max-delete PERCENT: Safety check on maximum percentage of deleted files allowed. If exceeded, the bisync run will abort. (default: 50%)?
    rclone --copy-links --check-first bisync --recover --no-slow-hash --check-access --conflict-resolve $1 $rdhome RetroDECK:/RetroDECK --include "{saves,screenshots}/**" --backup-dir1 ~/retrodeck_backup --backup-dir2 RetroDECK:/RetroDECK_backup
}

# --update: Skip files that are newer on the destination?
push_cloud() {
    rclone --copy-links --check-first sync --check-first $rdhome RetroDECK:/RetroDECK --include "{saves,screenshots}/**" --backup-dir RetroDECK:/RetroDECK_backup
}

pull_cloud() {
    rclone --copy-links --check-first sync --check-first RetroDECK:/RetroDECK $rdhome --include "{saves,screenshots}/**" --backup-dir ~/retrodeck_backup
}