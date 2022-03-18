#!/bin/bash
ARG=${1//[\\]/}
./emulators/ryujinx/Ryujinx --fullscreen $ARG