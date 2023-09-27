#!/bin/bash

# This is building the bundle RetroDECK.flatpak after the download and build steps are done

flatpak build-bundle ${GITHUB_WORKSPACE}/local RetroDECK-cooker.flatpak net.retrodeck.retrodeck