#!/bin/bash

# Associative arrays for command lists
# TODO: make them dynamic by readin es_config and features.json
declare -A command_list_default=(
["3do"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/opera_libretro.so"
["amiga"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae_libretro.so"
["amiga1200"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae_libretro.so"
["amiga600"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae_libretro.so"
["amigacd32"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae_libretro.so"
["amstradcpc"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/cap32_libretro.so"
["arcade"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so"
["arduboy"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/arduous_libretro.so"
["astrocde"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so"
["atari2600"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/stella_libretro.so"
["atari5200"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/a5200_libretro.so"
["atari7800"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/prosystem_libretro.so"
["atari800"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/atari800_libretro.so"
["atarijaguar"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/virtualjaguar_libretro.so"
["atarijaguarcd"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/virtualjaguar_libretro.so"
["atarilynx"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/handy_libretro.so"
["atarist"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/hatari_libretro.so"
["atarixe"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/atari800_libretro.so"
["atomiswave"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/flycast_libretro.so"
["c64"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vice_x64sc_libretro.so"
["cavestory"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/nxengine_libretro.so"
["cdimono1"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/same_cdi_libretro.so"
["cdtv"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae_libretro.so"
["chailove"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/chailove_libretro.so"
["channelf"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/freechaf_libretro.so"
["colecovision"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so"
["cps"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so"
["cps1"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so"
["cps2"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so"
["cps3"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so"
["doom"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/prboom_libretro.so"
["dos"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/dosbox_pure_libretro.so"
["dreamcast"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/flycast_libretro.so"
["easyrpg"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/easyrpg_libretro.so"
["famicom"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mesen_libretro.so"
["flash"]="TODO: I have to catch how it works", #TOD
["fba"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbalpha2012_libretro.so"
["fbneo"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbneo_libretro.so"
["fds"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mesen_libretro.so"
["gameandwatch"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gw_libretro.so"
["gamegear"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so"
["gb"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gambatte_libretro.so"
["gba"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mgba_libretro.so"
["gbc"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gambatte_libretro.so"
["genesis"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so"
["gx4000"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/cap32_libretro.so"
["intellivision"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/freeintv_libretro.so"
["j2me"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/squirreljme_libretro.so"
["lcdgames"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gw_libretro.so"
["lutro"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/lutro_libretro.so"
["mame"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so"
["mastersystem"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so"
["megacd"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so"
["megacdjp"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so"
["megadrive"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so"
["megaduck"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/sameduck_libretro.so"
["mess"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mess2015_libretro.so"
["model2"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so"
["moto"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/theodore_libretro.so"
["msx"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so"
["msx1"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so"
["msx2"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so"
["msxturbor"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so"
["multivision"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gearsystem_libretro.so"
["n64"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mupen64plus_next_libretro.so"
["n64dd"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/parallel_n64_libretro.so"
["naomi"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/flycast_libretro.so"
["naomigd"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/flycast_libretro.so"
["nds"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/desmume_libretro.so"
["neogeo"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbneo_libretro.so"
["neogeocd"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/neocd_libretro.so"
["neogeocdjp"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/neocd_libretro.so"
["nes"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mesen_libretro.so"
["ngp"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_ngp_libretro.so"
["ngpc"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_ngp_libretro.so"
["odyssey2"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/o2em_libretro.so"
["palm"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mu_libretro.so"
["pc88"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/quasi88_libretro.so"
["pc98"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/np2kai_libretro.so"
["pcengine"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_libretro.so"
["pcenginecd"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_libretro.so"
["pcfx"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pcfx_libretro.so"
["pokemini"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/pokemini_libretro.so"
["psx"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/swanstation_libretro.so"
["quake"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/tyrquake_libretro.so"
["satellaview"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x_libretro.so"
["saturn"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_saturn_libretro.so"
["saturnjp"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_saturn_libretro.so"
["scummvm"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/scummvm_libretro.so"
["sega32x"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/picodrive_libretro.so"
["sega32xjp"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/picodrive_libretro.so"
["sega32xna"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/picodrive_libretro.so"
["segacd"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so"
["sfc"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x_libretro.so"
["sg-1000"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so"
["sgb"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mesen-s_libretro.so"
["snes"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x_libretro.so"
["snesna"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x_libretro.so"
["spectravideo"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so"
["sufami"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x_libretro.so"
["supergrafx"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_supergrafx_libretro.so"
["supervision"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/potator_libretro.so"
["tg16"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_libretro.so"
["tg-cd"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_libretro.so"
["tic80"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/tic80_libretro.so"
["to8"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/theodore_libretro.so"
["uzebox"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/uzem_libretro.so"
["vectrex"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vecx_libretro.so"
["vic20"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vice_xvic_libretro.so"
["videopac"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/o2em_libretro.so"
["virtualboy"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_vb_libretro.so"
["wasm4"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/wasm4_libretro.so"
["wonderswan"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_wswan_libretro.so"
["wonderswancolor"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_wswan_libretro.so"
["x1"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/x1_libretro.so"
["x68000"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/px68k_libretro.so"
["zx81"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/81_libretro.so"
["zxspectrum"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fuse_libretro.so"
["switch"]="flatpak run --command=/var/data/ponzu/Yuzu/bin/yuzu net.retrodeck.retrodeck -f -g"
["n3ds"]="flatpak run --command=/var/data/ponzu/Citra/bin/citra-qt net.retrodeck.retrodeck"
["ps2"]="flatpak run --command=pcsx2-qt net.retrodeck.retrodeck -batch"
["wiiu"]="flatpak run --command=Cemu-wrapper net.retrodeck.retrodeck -g"
["gc"]="flatpak run --command=dolphin-emu-wrapper net.retrodeck.retrodeck -b -e"
["wii"]="flatpak run --command=dolphin-emu-wrapper net.retrodeck.retrodeck -b -e"
["xbox"]="flatpak run --command=xemu net.retrodeck.retrodeck -dvd_path"
["ps3"]="flatpak run --command=pcsx3 net.retrodeck.retrodeck --no-gui"
["psp"]="flatpak run --command=PPSSPPSDL net.retrodeck.retrodeck"
["pico8"]="flatpak run --command=pico8 net.retrodeck.retrodeck -desktop_path ~/retrodeck/screenshots -root_path {GAMEDIR} -run"
)

declare -A alt_command_list=(
["PUAE"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae_libretro.so"
["Caprice32"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/cap32_libretro.so"
["MAME - CURRENT"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so"
["Stella"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/stella_libretro.so"
["a5200"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/a5200_libretro.so"
["Atari800"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/atari800_libretro.so"
["Handy"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/handy_libretro.so"
["VICE x64sc Accurate"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vice_x64sc_libretro.so"
["SAME CDi"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/same_cdi_libretro.so"
["blueMSX"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bluemsx_libretro.so"
["MAME - CURRENT"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame_libretro.so"
["PrBoom"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/prboom_libretro.so"
["DOSBox-Pure"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/dosbox_pure_libretro.so"
["Mesen"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mesen_libretro.so"
["Genesis Plus GX"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_libretro.so"
["Gamebatte"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gambatte_libretro.so"
["mGBA"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mgba_libretro.so"
["ParaLLEI N64"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/parallel_n64_libretro.so"
["DeSmuME"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/desmume_libretro.so"
["NeoCD"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/neocd_libretro.so"
["Beetle NeoPop"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_ngp_libretro.so"
["Neko Project II Kai"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/np2kai_libretro.so"
["Beetle PCE"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_libretro.so"
["Swanstation"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/swanstation_libretro.so"
["TyrQuake"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/tyrquake_libretro.so"
["Beetle Saturn"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_saturn_libretro.so"
["Snes 9x - Current"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x_libretro.so"
["Beetle SuperGrafx"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_supergrafx_libretro.so"
["Yuzu (Standalone)"]="flatpak run --command=yuzu net.retrodeck.retrodeck -f -g"
["Citra (Standalone)"]="flatpak run --command=citra net.retrodeck.retrodeck"
["PCSX2 (Standalone)"]="flatpak run --command=pcsx2-qt net.retrodeck.retrodeck -batch"
["Dolphin (Standalone)"]="flatpak run --command=dolphin-emu-wrapper net.retrodeck.retrodeck -b -e"
["RPCS3 Directory (Standalone)"]="flatpak run --command=pcsx3 net.retrodeck.retrodeck --no-gui"
["PPSSPP (Standalone)"]="flatpak run --command=PPSSPPSDL net.retrodeck.retrodeck"
["PICO-8 (Standalone)"]="flatpak run --command=pico8 net.retrodeck.retrodeck -desktop_path ~/retrodeck/screenshots -root_path {GAMEDIR} -run"
["PUAE 2021"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/puae2021_libretro.so"
["CrocoDS"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/crocods_libretro.so"
["CPCemu (Standalone)"]= "NYI", #NYI
["MAME 2010"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame2010_libretro.so"
["MAME 2003-Plus"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame2003_plus_libretro.so"
["MAME 2000"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mame2000_libretro.so"
["MAME (Standalone)"]= "NYI", #NYI
["FinalBurn Neo"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbneo_libretro.so"
["FinalBurn Neo (Standalone)"]= "NYI", #NYI
["FB Alpha 2012"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbalpha2012_libretro.so"
["Flycast"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/flycast_libretro.so"
["Flycast (Standalone)"]= "NYI", #NYI
["Kronos"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/kronos_libretro.so"
["Supermodel (Standalone)"]= "NYI", #NYI
["Supermodel [Fullscreen] (Standalone)"]= "NYI", #NYI
["Shortcut or script"]= "TODO: I have to catch how it works", #TODO
["Atari800 (Standalone)"]= "NYI", #NYI
["Stella 2014"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/stella2014_libretro.so"
["Atari800"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/atari800_libretro.so"
["Beetle Lynx"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_lynx_libretro.so"
["VICE x64 Fast"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vice_x64_libretro.so"
["VICE x64 SuperCPU"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vice_xscpu64_libretro.so"
["VICE x128"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vice_x128_libretro.so"
["Frodo"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/frodo_libretro.so"
["CDi 2015"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/cdi2015_libretro.so"
["Gearcoleco"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gearcoleco_libretro.so"
["FB Alpha 2012 CPS-1"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbalpha2012_cps1_libretro.so"
["FB Alpha 2012 CPS-2"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbalpha2012_cps2_libretro.so"
["FB Alpha 2012 CPS-3"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fbalpha2012_cps3_libretro.so"
["Boom 3"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/boom3_libretro.so"
["Boom 3 xp"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/boom3_libretro_xp.so"
["DOSBox-Core"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/dosbox_core_libretro.so"
["DOSBox-SVN"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/dosbox_svn_libretro.so"
["Keep ES-DE running"]= "TODO: I have to catch how it works", #TODO
["AppImage (Suspend ES-DE)"]= "TODO: I have to catch how it works", #TODO
["AppImage (Keep ES-DE running)"]= "TODO: I have to catch how it works", #TODO
["Nestopia UE"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/nestopia_libretro.so"
["FCEUmm"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fceumm_libretro.so"
["QuickNES"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/quicknes_libretro.so"
["Genesis Plus GX Wide"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/genesis_plus_gx_wide_libretro.so"
["Gearsystem"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gearsystem_libretro.so"
["SMS Plus GX"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/smsplus_libretro.so"
["SameBoy"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/sameboy_libretro.so"
["Gearboy"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gearboy_libretro.so"
["TGB Dual"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/tgbdual_libretro.so"
["Mesen-S"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mesen-s_libretro.so"
["VBA-M"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vbam_libretro.so"
["bsnes"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bsnes_libretro.so"
["mGBA"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mgba_libretro.so"
["VBA Next"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vba_next_libretro.so"
["gpSP"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/gpsp_libretro.so"
["Dolphin"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/dolphin_libretro.so"
["PrimeHack (Standalone)"]="flatpak run --command=primehack-wrapper net.retrodeck.retrodeck -b -e"
["PicoDrive"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/picodrive_libretro.so"
["BlastEm"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/blastem_libretro.so"
["CrocoDS"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/crocods_libretro.so"
["fMSX"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/fmsx_libretro.so"
["Citra"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/citra_libretro.so"
["Citra 2018"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/citra2018_libretro.so"
["Mupen64Plus-Next"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mupen64plus_next_libretro.so"
["DeSmuME 2015"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/desmume2015_libretro.so"
["melonDS"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/melonds_libretro.so"
["melonDS (Standalone)"]="flatpak run --command=melonDS net.retrodeck.retrodeck"
["FinalBurn Neo neogeocd"]="flatpak run --command=retroarch net.retrodeck.retrodeck --subsystem neocd -L /var/config/retroarch/cores/fbneo_libretro.so"
["RACE"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/race_libretro.so"
["Neko Project II"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/nekop2_libretro.so"
["Beetle PCE FAST"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_fast_libretro.so"
["PICO-8 Splore (Standalone)"]="flatpak run --command=pico8 net.retrodeck.retrodeck -desktop_path ~/retrodeck/screenshots -root_path {GAMEDIR} -splore"
["AppImage"]= "TODO: I have to catch how it works", #TODO
["LRPS2"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/pcsx2_libretro.so"
["PCSX2"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/pcsx2_libretro.so"
["RPCS3 Shortcut (Standalone)"]= "TODO: I have to catch how it works", #TODO
["PPSSPP"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/ppsspp_libretro.so"
["Beetle PSX"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_psx_libretro.so"
["Beetle PSX HW"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_psx_hw_libretro.so"
["PCSX ReARMed"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/pcsx_rearmed_libretro.so"
["DuckStation (Standalone)"]="flatpak run --command=duckstation-qt net.retrodeck.retrodeck -batch"
["vitaQuake 2"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vitaquake2_libretro.so"
["vitaQuake 2 [Rogue]"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vitaquake2-rogue_libretro.so"
["vitaQuake 2 [Xatrix]"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vitaquake2-xatrix_libretro.so"
["vitaQuake 2 [Zaero]"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vitaquake2-zaero_libretro.so"
["vitaQuake 3"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/vitaquake3_libretro.so"
["YabaSanshiro"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/yabasanshiro_libretro.so"
["Yabause"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/yabause_libretro.so"
["Snes9x 2010"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/snes9x2010_libretro.so"
["bsnes-hd"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bsnes_hd_beta_libretro.so"
["bsnes-mercury Accuracy"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/bsnes_mercury_accuracy_libretro.so"
["Beetle Supafaust"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_supafaust_libretro.so"
["Beetle PCE"]="flatpak run --command=retroarch net.retrodeck.retrodeck -L /var/config/retroarch/cores/mednafen_pce_libretro.so"
)

# Add games to Steam function
addToSteam() {
    log "i" "Starting Steam Sync"

    local srm_path="/var/config/steam-rom-manager/userData/userConfigurations.json"
    if [ ! -f "$srm_path" ]; then
        log "e" "Steam ROM Manager configuration not initialized! Initializing now."
        # TODO: do a prepare_component here
        resetfun "$rdhome"
    fi

    # Build the systems array from space-separated systems
    local systems_string=$(jq -r '.system | keys[]' "$features" | paste -sd' ')
    IFS=' ' read -r -a systems <<< "$systems_string"

    local games=()

    for system in "${systems[@]}"; do

        local gamelist="$rdhome/ES-DE/gamelists/$system/gamelist.xml"

        if [ -f "$gamelist" ]; then

        # Extract all <game> elements that are marked as favorite="true"
        game_blocks=$(xmllint --recover --xpath '//game[favorite="true"]' "$gamelist" 2>/dev/null)
        log d "Extracted favorite game blocks:\n\n$game_blocks\n\n"

        # Split the game_blocks into an array, where each element is a full <game> block
        IFS=$'\n' read -r -d '' -a game_array <<< "$(echo "$game_blocks" | xmllint --recover --format - | sed -n '/<game>/,/<\/game>/p' | tr '\n' ' ')"

        # Iterate over each full <game> block in the array
        for game_block in "${game_array[@]}"; do
          log "d" "Processing game block:\n$game_block"

          # Extract the game's name and path from the full game block
          local name=$(echo "$game_block" | xmllint --xpath 'string(//game/name)' - 2>/dev/null)
          local path=$(echo "$game_block" | xmllint --xpath 'string(//game/path)' - 2>/dev/null | sed 's|^\./||') # removing the ./

          log "d" "Game name: $name"
          log "d" "Game path: $path"

          # Ensure the extracted name and path are valid
          if [ -n "$name" ] && [ -n "$path" ]; then
              # Check for an alternative emulator if it exists
              local emulator=$(echo "$game_block" | xmllint --xpath 'string(//game/altemulator)' - 2>/dev/null)
              if [ -z "$emulator" ]; then
                  games+=("$name ${command_list_default[$system]} '$roms_folder/$system/$path'")
              else
                  games+=("$name ${alt_command_list[$emulator]} '$roms_folder/$system/$path'")
              fi
              log "d" "Steam Sync: found favorite game: $name"
          else
              log "w" "Steam Sync: failed to find valid name or path for favorite game"
          fi

          # Sanitize the game name for the filename: replace special characters with underscores
          local sanitized_name=$(echo "$name" | sed -e 's/^A-Za-z0-9._-/ /g')
          local sanitized_name=$(echo "$sanitized_name" | sed -e 's/:/-/g')
          local sanitized_name=$(echo "$sanitized_name" | sed -e 's/   / - /g')
          local sanitized_name=$(echo "$sanitized_name" | sed -e 's/  / /g')
          log d "File Path: $path"
          log d "Game Name: $name"

          # If the filename is too long, shorten it
          if [ ${#sanitized_name} -gt 100 ]; then
              sanitized_name=$(echo "$sanitized_name" | cut -c 1-100)
          fi

          log d "Sanitized Name: $sanitized_name" 

          #TODO: FIXME, this part is wrong, I need to fix it

          local launcher="$rdhome/.sync/${sanitized_name}.sh"
          log d "Creating shortcut at path: $launcher"

          if [[ -v command_list_default[$system] ]]; then
            command="${command_list_default[$system]}"
          else
            log e "$system is not included in the commands array."
            continue
          fi

          # Populate the .sync script with the correct command
          echo -e '#!/bin/bash\n' > "$launcher"
          echo "$command \"$path\"" >> "$launcher"

          chmod +x "$launcher"
        done
    fi
  done

  log i "Steam Sync: completed"
}