"""Sync RetroDECK favorites games with steam shortcuts"""
import binascii
import os
import re
import shlex
import shutil
import glob
import sys
import time
import hashlib

import xml.etree.ElementTree as ET

from resetsync import resetfun

command_list_default={
"3do": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/opera_libretro.so",
"amiga": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae_libretro.so",
"amiga1200": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae_libretro.so",
"amiga600": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae_libretro.so",
"amigacd32": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae_libretro.so",
"amstradcpc": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/cap32_libretro.so",
"arcade": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so",
"arduboy": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/arduous_libretro.so",
"astrocde": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so",
"atari2600": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/stella_libretro.so",
"atari5200": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/a5200_libretro.so",
"atari7800": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/prosystem_libretro.so",
"atari800": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/atari800_libretro.so",
"atarijaguar": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/virtualjaguar_libretro.so",
"atarijaguarcd": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/virtualjaguar_libretro.so",
"atarilynx": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/handy_libretro.so",
"atarist": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/hatari_libretro.so",
"atarixe": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/atari800_libretro.so",
"atomiswave": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/flycast_libretro.so",
"c64": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vice_x64sc_libretro.so",
"cavestory": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/nxengine_libretro.so",
"cdimono1": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/same_cdi_libretro.so",
"cdtv": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae_libretro.so",
"chailove": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/chailove_libretro.so",
"channelf": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/freechaf_libretro.so",
"colecovision": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so",
"cps": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so",
"cps1": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so",
"cps2": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so",
"cps3": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so",
"doom": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/prboom_libretro.so",
"dos": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/dosbox_pure_libretro.so",
"dreamcast": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/flycast_libretro.so",
"easyrpg": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/easyrpg_libretro.so",
"famicom": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mesen_libretro.so",
"fba": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbalpha2012_libretro.so",
"fbneo": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbneo_libretro.so",
"fds": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mesen_libretro.so",
"gameandwatch": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gw_libretro.so",
"gamegear": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so",
"gb": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gambatte_libretro.so",
"gba": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mgba_libretro.so",
"gbc": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gambatte_libretro.so",
"genesis": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so",
"gx4000": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/cap32_libretro.so",
"intellivision": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/freeintv_libretro.so",
"j2me": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/squirreljme_libretro.so",
"lcdgames": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gw_libretro.so",
"lutro": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/lutro_libretro.so",
"mame": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so",
"mastersystem": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so",
"megacd": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so",
"megacdjp": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so",
"megadrive": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so",
"megaduck": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/sameduck_libretro.so",
"mess": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mess2015_libretro.so",
"model2": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so",
"moto": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/theodore_libretro.so",
"msx": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so",
"msx1": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so",
"msx2": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so",
"msxturbor": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so",
"multivision": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gearsystem_libretro.so",
"n64": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mupen64plus_next_libretro.so",
"n64dd": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/parallel_n64_libretro.so",
"naomi": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/flycast_libretro.so",
"naomigd": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/flycast_libretro.so",
"nds": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/desmume_libretro.so",
"neogeo": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbneo_libretro.so",
"neogeocd": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/neocd_libretro.so",
"neogeocdjp": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/neocd_libretro.so",
"nes": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mesen_libretro.so",
"ngp": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_ngp_libretro.so",
"ngpc": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_ngp_libretro.so",
"odyssey2": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/o2em_libretro.so",
"palm": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mu_libretro.so",
"pc88": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/quasi88_libretro.so",
"pc98": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/np2kai_libretro.so",
"pcengine": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_libretro.so",
"pcenginecd": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_libretro.so",
"pcfx": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pcfx_libretro.so",
"pokemini": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/pokemini_libretro.so",
"psx": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/swanstation_libretro.so",
"quake": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/tyrquake_libretro.so",
"satellaview": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x_libretro.so",
"saturn": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_saturn_libretro.so",
"saturnjp": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_saturn_libretro.so",
"scummvm": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/scummvm_libretro.so",
"sega32x": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/picodrive_libretro.so",
"sega32xjp": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/picodrive_libretro.so",
"sega32xna": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/picodrive_libretro.so",
"segacd": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so",
"sfc": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x_libretro.so",
"sg-1000": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so",
"sgb": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mesen-s_libretro.so",
"snes": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x_libretro.so",
"snesna": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x_libretro.so",
"spectravideo": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so",
"sufami": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x_libretro.so",
"supergrafx": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_supergrafx_libretro.so",
"supervision": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/potator_libretro.so",
"tg16": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_libretro.so",
"tg-cd": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_libretro.so",
"tic80": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/tic80_libretro.so",
"to8": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/theodore_libretro.so",
"uzebox": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/uzem_libretro.so",
"vectrex": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vecx_libretro.so",
"vic20": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vice_xvic_libretro.so",
"videopac": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/o2em_libretro.so",
"virtualboy": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_vb_libretro.so",
"wasm4": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/wasm4_libretro.so",
"wonderswan": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_wswan_libretro.so",
"wonderswancolor": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_wswan_libretro.so",
"x1": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/x1_libretro.so",
"x68000": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/px68k_libretro.so",
"zx81": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/81_libretro.so",
"zxspectrum": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fuse_libretro.so",
"switch": "flatpak run --command=/var/data/ponzu/Yuzu/bin/yuzu net.retrodeck.retrodeck -f -g",
"n3ds": "flatpak run --command=/var/data/ponzu/Citra/bin/citra-qt net.retrodeck.retrodeck",
"ps2": "flatpak run --command=pcsx2-qt net.retrodeck.retrodeck -batch",
"wiiu": "flatpak run --command=Cemu-wrapper net.retrodeck.retrodeck -g",
"gc": "flatpak run --command=dolphin-emu-wrapper net.retrodeck.retrodeck -b -e",
"wii": "flatpak run --command=dolphin-emu-wrapper net.retrodeck.retrodeck -b -e",
"xbox": "flatpak run --command=xemu net.retrodeck.retrodeck -dvd_path",
"ps3": "flatpak run --command=pcsx3 net.retrodeck.retrodeck --no-gui",
"psp": "flatpak run --command=PPSSPPSDL net.retrodeck.retrodeck",
"pico8": "flatpak run --command=pico8 net.retrodeck.retrodeck -desktop_path ~/retrodeck/screenshots -root_path {GAMEDIR} -run"
}

alt_command_list={
"PUAE": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae_libretro.so",
"Caprice32": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/cap32_libretro.so",
"MAME - CURRENT": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so",
"Stella": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/stella_libretro.so",
"a5200": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/a5200_libretro.so",
"Atari800": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/atari800_libretro.so",
"Handy": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/handy_libretro.so",
"VICE x64sc Accurate": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vice_x64sc_libretro.so",
"SAME CDi": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/same_cdi_libretro.so",
"blueMSX": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so",
"MAME - CURRENT": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so",
"PrBoom": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/prboom_libretro.so",
"DOSBox-Pure": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/dosbox_pure_libretro.so",
"Mesen": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mesen_libretro.so",
"Genesis Plus GX": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so",
"Gamebatte": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gambatte_libretro.so",
"mGBA": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mgba_libretro.so",
"ParaLLEI N64": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/parallel_n64_libretro.so",
"DeSmuME": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/desmume_libretro.so",
"NeoCD": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/neocd_libretro.so",
"Beetle NeoPop": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_ngp_libretro.so",
"Neko Project II Kai": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/np2kai_libretro.so",
"Beetle PCE": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_libretro.so",
"Swanstation": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/swanstation_libretro.so",
"TyrQuake": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/tyrquake_libretro.so",
"Beetle Saturn": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_saturn_libretro.so",
"Snes 9x - Current": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x_libretro.so",
"Beetle SuperGrafx": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_supergrafx_libretro.so",
"Yuzu (Standalone)": "flatpak run --command=yuzu net.retrodeck.retrodeck -f -g",
"Citra (Standalone)": "flatpak run --command=citra net.retrodeck.retrodeck",
"PCSX2 (Standalone)": "flatpak run --command=pcsx2-qt net.retrodeck.retrodeck -batch",
"Dolphin (Standalone)": "flatpak run --command=dolphin-emu-wrapper net.retrodeck.retrodeck -b -e",
"RPCS3 Directory (Standalone)": "flatpak run --command=pcsx3 net.retrodeck.retrodeck --no-gui",
"PPSSPP (Standalone)": "flatpak run --command=PPSSPPSDL net.retrodeck.retrodeck",
"PICO-8 (Standalone)": "flatpak run --command=pico8 net.retrodeck.retrodeck -desktop_path ~/retrodeck/screenshots -root_path {GAMEDIR} -run",
"PUAE 2021": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae2021_libretro.so",
"CrocoDS": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/crocods_libretro.so",
"CPCemu (Standalone)": "NYI", #NYI
"MAME 2010": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame2010_libretro.so",
"MAME 2003-Plus": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame2003_plus_libretro.so",
"MAME 2000": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame2000_libretro.so",
"MAME (Standalone)": "NYI", #NYI
"FinalBurn Neo": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbneo_libretro.so",
"FinalBurn Neo (Standalone)": "NYI", #NYI
"FB Alpha 2012": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbalpha2012_libretro.so",
"Flycast": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/flycast_libretro.so",
"Flycast (Standalone)": "NYI", #NYI
"Kronos": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/kronos_libretro.so",
"Supermodel (Standalone)": "NYI", #NYI
"Supermodel [Fullscreen] (Standalone)": "NYI", #NYI
"Shortcut or script": "TODO: I have to catch how it works", #TODO
"Atari800 (Standalone)": "NYI", #NYI
"Stella 2014": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/stella2014_libretro.so",
"Atari800": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/atari800_libretro.so",
"Beetle Lynx": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_lynx_libretro.so",
"VICE x64 Fast": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vice_x64_libretro.so",
"VICE x64 SuperCPU": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vice_xscpu64_libretro.so",
"VICE x128": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vice_x128_libretro.so",
"Frodo": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/frodo_libretro.so",
"CDi 2015": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/cdi2015_libretro.so",
"Gearcoleco": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gearcoleco_libretro.so",
"FB Alpha 2012 CPS-1": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbalpha2012_cps1_libretro.so",
"FB Alpha 2012 CPS-2": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbalpha2012_cps2_libretro.so",
"FB Alpha 2012 CPS-3": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbalpha2012_cps3_libretro.so",
"Boom 3": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/boom3_libretro.so",
"Boom 3 xp": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/boom3_libretro_xp.so",
"DOSBox-Core": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/dosbox_core_libretro.so",
"DOSBox-SVN": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/dosbox_svn_libretro.so",
"Keep ES-DE running": "TODO: I have to catch how it works", #TODO
"AppImage (Suspend ES-DE)": "TODO: I have to catch how it works", #TODO
"AppImage (Keep ES-DE running)": "TODO: I have to catch how it works", #TODO
"Nestopia UE": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/nestopia_libretro.so",
"FCEUmm": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fceumm_libretro.so",
"QuickNES": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/quicknes_libretro.so",
"Genesis Plus GX Wide": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_wide_libretro.so",
"Gearsystem": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gearsystem_libretro.so",
"SMS Plus GX": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/smsplus_libretro.so",
"SameBoy": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/sameboy_libretro.so",
"Gearboy": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gearboy_libretro.so",
"TGB Dual": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/tgbdual_libretro.so",
"Mesen-S": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mesen-s_libretro.so",
"VBA-M": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vbam_libretro.so",
"bsnes": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bsnes_libretro.so",
"mGBA": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mgba_libretro.so",
"VBA Next": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vba_next_libretro.so",
"gpSP": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gpsp_libretro.so",
"Dolphin": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/dolphin_libretro.so",
"PrimeHack (Standalone)": "flatpak run --command=primehack-wrapper net.retrodeck.retrodeck -b -e",
"PicoDrive": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/picodrive_libretro.so",
"BlastEm": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/blastem_libretro.so",
"CrocoDS": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/crocods_libretro.so",
"fMSX": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fmsx_libretro.so",
"Citra": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/citra_libretro.so",
"Citra 2018": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/citra2018_libretro.so",
"Mupen64Plus-Next": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mupen64plus_next_libretro.so",
"DeSmuME 2015": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/desmume2015_libretro.so",
"melonDS": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/melonds_libretro.so",
"melonDS (Standalone)": "flatpak run --command=melonDS net.retrodeck.retrodeck",
"FinalBurn Neo neogeocd": "flatpak run --command=retroarch net.retrodeck.retrodeck --subsystem neocd -L /var/config/retroarch/cores/fbneo_libretro.so",
"RACE": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/race_libretro.so",
"Neko Project II": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/nekop2_libretro.so",
"Beetle PCE FAST": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_fast_libretro.so",
"PICO-8 Splore (Standalone)": "flatpak run --command=pico8 net.retrodeck.retrodeck -desktop_path ~/retrodeck/screenshots -root_path {GAMEDIR} -splore",
"AppImage": "TODO: I have to catch how it works", #TODO
"LRPS2": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/pcsx2_libretro.so",
"PCSX2": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/pcsx2_libretro.so",
"RPCS3 Shortcut (Standalone)": "TODO: I have to catch how it works", #TODO
"PPSSPP": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/ppsspp_libretro.so",
"Beetle PSX": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_psx_libretro.so",
"Beetle PSX HW": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_psx_hw_libretro.so",
"PCSX ReARMed": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/pcsx_rearmed_libretro.so",
"DuckStation (Standalone)": "flatpak run --command=duckstation-qt net.retrodeck.retrodeck -batch",
"vitaQuake 2": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vitaquake2_libretro.so",
"vitaQuake 2 [Rogue]": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vitaquake2-rogue_libretro.so",
"vitaQuake 2 [Xatrix]": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vitaquake2-xatrix_libretro.so",
"vitaQuake 2 [Zaero]": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vitaquake2-zaero_libretro.so",
"vitaQuake 3": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vitaquake3_libretro.so",
"YabaSanshiro": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/yabasanshiro_libretro.so",
"Yabause": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/yabause_libretro.so",
"Snes9x 2010": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x2010_libretro.so",
"bsnes-hd": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bsnes_hd_beta_libretro.so",
"bsnes-mercury Accuracy": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bsnes_mercury_accuracy_libretro.so",
"Beetle Supafaust": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_supafaust_libretro.so",
"Beetle PCE": "flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_libretro.so"
}

exit_file="/tmp/retrodeck_steam_sync_exit"
rdhome=""
roms_folder=""

def create_shortcut_new_new(games):
    old_games=os.listdir(rdhome+"/.sync/").copy()

    for game in games:
        try:
            i=old_games.index(game[0])
            old_games[i]=0
        except ValueError:
            print(game[0]+" is a new game!")

        path=rdhome+"/.sync/"+game[0]+".sh"
        print("Go to path: "+path)

        fl=open(path,"w")
        fl.write("#!/bin/bash\n\n")
        fl.write('if test "$(whereis flatpak)" = "flatpak:"\n')
        fl.write("then\n")
        fl.write("flatpak-spawn --host "+game[1]+"\n")
        fl.write("else\n")
        fl.write(game[1]+"\n")
        fl.write("fi\n")
        fl.close()

        st=os.stat(path)
        os.chmod(path, st.st_mode | 0o0111)

    print("Start removing")
    print(old_games)
    for game in old_games:
        if game:
            os.remove(rdhome+"/.sync/"+game)

    os.system("/app/bin/zypak-wrapper /app/srm/steam-rom-manager add")

def addToSteam(systems):
    games=[]
    for system in systems:
        print("Start parsing system: {}".format(system))

        f=open(rdhome+"/ES-DE/gamelists/"+system+"/gamelist.xml","r")
        f.readline()
        parser=ET.XMLParser()
        parser.feed(b'<root>')
        parser.feed(f.read())
        parser.feed(b'</root>')
        root=parser.close()
        f.close()

        globalAltEmu=""
        for subroot in root:
            if subroot.tag=="alternativeEmulator":
                for alt in subroot:
                    globalAltEmu=alt.text
            else:
                for game in subroot:
                    path=""
                    name=""
                    favorite=""
                    altemulator=globalAltEmu
                    for tag in game:
                        if tag.tag=="path":
                            path=tag.text
                        elif tag.tag=="name":
                            name=tag.text
                        elif tag.tag=="favorite":
                            favorite=tag.text
                        elif tag.tag=="altemulator":
                            altemulator=tag.text

                    if favorite=="true" and altemulator=="":
                        print("Find favorite game: {}".format(name))
                        games.append([name,command_list_default[system]+" '"+roms_folder+"/"+system+path[1:]+"'"])
                    elif favorite=="true":
                        print("Find favorite game with alternative emulator: {}, {}".format(name,altemulator))
                        if ("neogeocd" in system) and altemulator=="FinalBurn Neo":
                            games.append([name,alt_command_list[altemulator+" neogeocd"]+" '"+roms_folder+"/"+system+path[1:]+"'"])
                            print(alt_command_list[altemulator+" neogeocd"]+" '"+roms_folder+"/"+system+path[1:]+"'")
                        elif system=="pico8" and altemulator=="PICO-8 Splore (Standalone)":
                            games.append([name,alt_command_list[altemulator]])
                            print(alt_command_list[altemulator])
                        else:
                            games.append([name,alt_command_list[altemulator]+" '"+roms_folder+"/"+system+path[1:]+"'"])
                            print(alt_command_list[altemulator]+" '"+roms_folder+"/"+system+path[1:]+"'")
    create_shortcut_new_new(games)

def start_config():
    global rdhome
    global roms_folder
    global command_list_default
    global alt_command_list

    print("Open RetroDECK config file: {}".format(os.path.expanduser("~/.var/app/net.retrodeck.retrodeck/config/retrodeck/retrodeck.cfg")))

    fl=open(os.path.expanduser("~/.var/app/net.retrodeck.retrodeck/config/retrodeck/retrodeck.cfg"),"r")
    lines=fl.readlines()
    for line in lines:
        if "rdhome" in line:
            rdhome=line[7:-1]
        elif "roms_folder" in line:
            roms_folder=line[12:-1]
    fl.close()

    command_list_default["pico8"]=command_list_default["pico8"].replace("{GAMEDIR}",roms_folder+"/pico8")
    alt_command_list["PICO-8 Splore (Standalone)"]=alt_command_list["PICO-8 Splore (Standalone)"].replace("{GAMEDIR}",roms_folder+"/pico8")

    srm_path=os.path.expanduser("~/.var/app/net.retrodeck.retrodeck/config/steam-rom-manager/userData/userConfigurations.json")
    if not os.path.isfile(srm_path):
        print("Steam Rom Manager configuration not initialized! Initializing now.")
        resetfun(rdhome)

if __name__=="__main__":
    start_config()
    addToSteam(os.listdir(rdhome+"/ES-DE/gamelists/"))
    print("Finished!")
