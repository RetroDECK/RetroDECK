# Copyright 2024 Libretto
# SPDX-License-Identifier: GPL-3.0-or-later

import os, re, zlib

def crc32(file):
    prev = 0
    for each_line in open(file, 'rb'):
        prev = zlib.crc32(each_line, prev)
    return ("%X"%(prev & 0xFFFFFFFF)).lower()


def db_sanitize(input):
    return input.replace("'", "''")


def add_base_path_to_db(db, path, hash):
    db.execute(f"UPDATE base SET local_path = '{db_sanitize(path)}' WHERE hash = '{hash}'")


def add_installed_hack_version_to_db(db, name, type, installed_version):
    if type:
        db.execute(f"UPDATE rhack SET installed_version = '{installed_version}' WHERE name = '{db_sanitize(name)}' AND type = '{db_sanitize(type)}'")
    else:
        db.execute(f"UPDATE rhack SET installed_version = '{installed_version}' WHERE name = '{db_sanitize(name)}'")


def scan_and_add(db, root_search_path, avail_systems):
    for search_dir, avail_dirs, avail_files in os.walk(root_search_path):

        ### add base roms to db

        # only look at files that are in a valid console dir
        if os.path.basename(search_dir) in avail_systems:

            for base in avail_files:
                if base.endswith('.txt'): continue

                rom_path = os.path.join(search_dir, base)
                rom_hash = crc32(rom_path)
    
                add_base_path_to_db(db, rom_path, rom_hash)

        ### add already installed hacks to db

        if os.path.basename(search_dir) == "ROM Hacks":
            for rhack in avail_files:
                rhack_name = re.search("^.*\\[", rhack).group()[:-1]

                type_and_version = re.search("\\[.*\\]", rhack).group()[1:-1]
                version_start_index = re.search("v[0-9]+\\.[0-9]+.*", type_and_version).span()[0]

                rhack_version = type_and_version[version_start_index + 1:]

                rhack_type = type_and_version[:version_start_index]
                if rhack_type == "":
                    rhack_type = False
                else:
                    rhack_type = rhack_type[:-1]

                add_installed_hack_version_to_db(db, rhack_name, rhack_type, rhack_version)


# return a list of consoles for which patches are available
def get_avail_systems(db):
    db.execute("SELECT DISTINCT system FROM base")
    return [tuple[0] for tuple in db.fetchall()]


# "main" function of this module
def scan_avail_base_roms(db, search_path):
    scan_and_add(db, search_path, get_avail_systems(db))
