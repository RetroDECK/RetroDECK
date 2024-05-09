# Copyright 2024 Libretto
# SPDX-License-Identifier: GPL-3.0-or-later

import os, zlib


def crc32(file):
    prev = 0
    for each_line in open(file, 'rb'):
        prev = zlib.crc32(each_line, prev)
    return ("%X"%(prev & 0xFFFFFFFF)).lower()


def add_base_path_to_db(db, path, hash):
    sanitized_path = path.replace("'", "''")
    db.execute(f"UPDATE base SET local_path = '{sanitized_path}' WHERE hash = '{hash}'")


def scan_and_add(db, root_search_path, avail_systems):
    for search_dir, avail_dirs, avail_files in os.walk(root_search_path):

        # only look at consoles that appear in our patch db 
        if os.path.basename(search_dir) in avail_systems:

            for file in avail_files:
                if file.endswith('.txt'): continue

                rom_path = os.path.join(search_dir, file)
                rom_hash = crc32(rom_path)
    
                add_base_path_to_db(db, rom_path, rom_hash)


# return a list of consoles for which patches are available
def get_avail_systems(db):
    db.execute("SELECT DISTINCT system FROM base")
    return [tuple[0] for tuple in db.fetchall()]


# "main" function of this module
def scan_avail_base_roms(db, search_path):
    scan_and_add(db, search_path, get_avail_systems(db))
