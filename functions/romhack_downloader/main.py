# Copyright 2024 Libretto
# SPDX-License-Identifier: GPL-3.0-or-later

import argparse, os, pathlib, shutil, sqlite3

from scan_roms import scan_avail_base_roms
from download_patch import download_patch

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--fetch-compatible-hacks', action='store_const', const=True)
    parser.add_argument('-i', '--install')
    parser.add_argument('--roms-folder', required=True)
    parser.add_argument('--saves-folder', required=True)
    return parser.parse_args()


def reset_db(db):
    with open('/app/libexec/romhack_downloader/db_setup.sql', 'r') as file:
        db.executescript(file.read())


def construct_rhack_filename_no_ext(name, type, version):
    if type:
        return f"{name}[{type} v{version}]"
    else:
        return f"{name}[v{version}]"


def copy_rhack_save(name, type, version, already_installed_version, saves_folder):
    try:
        shutil.copy2(f"{saves_folder}/ROM Hacks/{construct_rhack_filename_no_ext(name, type, already_installed_version)}.srm",
                     f"{saves_folder}/ROM Hacks/{construct_rhack_filename_no_ext(name, type, version)}.srm")
    except FileNotFoundError:
        pass


def construct_rhack_path(roms_folder, system, rhack_name, base_path, rhack_version, rhack_type):
    rhack_dir = os.path.join(roms_folder, system, 'ROM Hacks')
    os.makedirs(rhack_dir, exist_ok=True)

    rhack_extension = pathlib.Path(base_path).suffix
    rhack_filename = f"{construct_rhack_filename_no_ext(rhack_name, rhack_type, rhack_version)}{rhack_extension}"

    rhack_path = os.path.join(rhack_dir, rhack_filename)
    print(f"Path of the ROM Hack: {rhack_path}")
    return rhack_path


def install_rhack(db, id, roms_folder, saves_folder):
    db.execute((
        "SELECT rhack.url, base.local_path, base.system, rhack.name, rhack.archive_path, rhack.version, rhack.type, rhack.installed_version "
        "FROM base JOIN rhack ON base.hash = rhack.base_hash "
        f"WHERE rhack.id = {id}"
    ))
    url, base_path, system, rhack_name, archive_path, rhack_version, rhack_type, rhack_already_installed_version = db.fetchone()

    # handle the case that the user has already installed a version of the hack
    if rhack_already_installed_version:
        if rhack_already_installed_version > rhack_version:
            raise NotImplementedError("User wants to downgrade a hack to an earlier version.")
        elif rhack_already_installed_version == rhack_version:
            return
        else:
            # hack will be upgraded
            copy_rhack_save(rhack_name, rhack_type, rhack_version, rhack_already_installed_version, saves_folder)

    rhack_path = construct_rhack_path(roms_folder, system, rhack_name, base_path, rhack_version, rhack_type)

    patch_path = download_patch(url, archive_path)
    try:
        os.system(f'flips --apply "{patch_path}" "{base_path}" "{rhack_path}"')
    except:
        exit(1)

    # cleanup
    os.system("rm -rf /tmp/patch_archive* /tmp/extract_patch")


def main():
    db_connection = sqlite3.connect('/var/data/romhacks.db')
    db = db_connection.cursor()

    args = parse_arguments()

    if args.fetch_compatible_hacks:
        reset_db(db)
        scan_avail_base_roms(db, args.roms_folder)

    if args.install: 
        install_rhack(db, args.install, args.roms_folder, args.saves_folder)
    
    db_connection.commit() # make db changes available to other connections
    db_connection.close()


main()
