# Copyright 2024 Libretto
# SPDX-License-Identifier: GPL-3.0-or-later

import os, pathlib, requests
from pyunpack import Archive
from urllib.parse import urlparse


# return absolute path of patch
def get_patch_from_archive(archive_path, location_in_archive):
    os.system("rm -rf /tmp/extract_patch")
    extract_dir = "/tmp/extract_patch"
    os.makedirs(extract_dir, exist_ok=True)

    Archive(archive_path).extractall(extract_dir)
    return os.path.join(extract_dir, location_in_archive)


def directly_download(url):
    file_extension = ''.join(pathlib.Path(url).suffixes)
    archive_path = f"/tmp/patch_archive{file_extension}"

    request = requests.get(url)
    with open(archive_path, 'wb') as file:
        file.write(request.content)
    return archive_path


# "main" function of this module
def download_patch(url, location_in_archive):
    match urlparse(url).netloc: # domain
        case _: # direct download possible
            archive_path = directly_download(url)
            return get_patch_from_archive(archive_path, location_in_archive)
