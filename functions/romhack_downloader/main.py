# Copyright 2024 Libretto
# SPDX-License-Identifier: GPL-3.0-or-later

import argparse, os, pathlib, sqlite3

from scan_roms import scan_avail_base_roms
from download_patch import download_patch

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--fetch-compatible-hacks', action='store_const', const=True)
    parser.add_argument('-i', '--install')
    parser.add_argument('-r', '--roms-folder', required=True)
    return parser.parse_args()


def reset_db(db):
    with open('/app/libexec/romhack_downloader/db_setup.sql', 'r') as file:
        db.executescript(file.read())


def construct_rhack_path(roms_folder, system, rhack_name, base_path, rhack_version, rhack_type):
    rhack_dir = os.path.join(roms_folder, system, 'ROM Hacks')
    os.makedirs(rhack_dir, exist_ok=True)

    rhack_extension = pathlib.Path(base_path).suffix
    if rhack_type:
        rhack_filename = f"{rhack_name}[{rhack_type} v{rhack_version}]{rhack_extension}"
    else:
        rhack_filename = f"{rhack_name}[v{rhack_version}]{rhack_extension}"

    rhack_path = os.path.join(rhack_dir, rhack_filename)
    print(f"Path of the ROM Hack: {rhack_path}")
    return rhack_path


def install_rhack(db, id, roms_folder):
    db.execute((
        "SELECT rhack.url, base.local_path, base.system, rhack.name, rhack.archive_path, rhack.version, rhack.type "
        "FROM base JOIN rhack ON base.hash = rhack.base_hash "
        f"WHERE rhack.id = {id}"
    ))
    url, base_path, system, rhack_name, archive_path, rhack_version, rhack_type = db.fetchone()

    rhack_path = construct_rhack_path(roms_folder, system, rhack_name, base_path, rhack_version, rhack_type)

    patch_path = download_patch(url, archive_path)
    if patch_path: os.system(f'flips --apply "{patch_path}" "{base_path}" "{rhack_path}"')

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
        install_rhack(db, args.install, args.roms_folder)
    
    db_connection.commit() # make db changes available to other connections
    db_connection.close()


main()
