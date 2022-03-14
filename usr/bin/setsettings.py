#!/usr/bin/env python3

# SPDX-License-Identifier: GPL-2.0-or-later
#
# setsettings.py:
# Copyright (C) 2021-present konsumschaf
# Copyright (C) 2021-present konsumlamm
#
# based on setsettings.sh:
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2020-present Fewtarius


# Convert ES settings from distribution.conf to RetroArch configuration in raappend.conf.

from argparse import ArgumentParser
from configparser import ConfigParser
from dataclasses import dataclass
from glob import iglob
import os
import random
import re
import shutil

# If we are on Steam Deck we want a prefix
DEVICE = "DECK"
# TODO: put a real check on the .OS_ARCH file, or maybe not as we are obviously running on Deck
INSTALL_DIR = os.path.expanduser("~/retrodeck")

# if DEVICE == "DECK" :
#	
#else:
#	INSTALL_DIR = ""

# Files and Folder
ra_conf = INSTALL_DIR + "/storage/.config/retroarch/retroarch.cfg"
ra_source_conf = INSTALL_DIR + "/usr/config/retroarch/retroarch.cfg"
ra_core_conf = INSTALL_DIR + "/storage/.config/retroarch/retroarch-core-options.cfg"
ra_append_conf = "/tmp/raappend.cfg"
os_arch_conf = INSTALL_DIR + "/storage/.config/.OS_ARCH"
snapshots = INSTALL_DIR + "/storage/roms/savestates"

# Logging
class Logger:
    dir = "/tmp/logs"
    file = "exec.log"
    script_basename = os.path.basename(__file__)

    def __init__(self):
        if not os.path.isdir(self.dir):
            os.makedirs(self.dir)
        self.file_handle = open(f'{self.dir}/{self.file}',"a+")

    def log(self, text: str) -> None:
        self.file_handle.write(f'{self.script_basename}: {text}\n')

    def __del__(self):
        self.file_handle.close()


# No Sections in distribution.conf, we have to fake our own
class MyConfigParser(ConfigParser):
    def read(self, filename: str) -> None:
        text = open(filename, encoding="utf_8").read()
        self.read_string("[351elec]\n" + text, filename)

@dataclass
class Config:
    rom_name: str
    platform: str

    distribution_conf = INSTALL_DIR + "/storage/.config/distribution/configs/distribution.conf"

    def __post_init__(self):
        # Read the distribution.conf to a dictionary
        config_parser = MyConfigParser(strict=False)
        config_parser.read(self.distribution_conf)
        self.config = config_parser['351elec']

    def get_setting(self, setting: str) -> str:
        """Get the settings from distribution.conf"""

        pat_rom = f'{self.platform}["{self.rom_name}"].{setting}'
        pat_platform = f'{self.platform}.{setting}'
        pat_global = f'global.{setting}'

        if pat_rom in self.config:
            value = self.config[pat_rom]
        elif pat_platform in self.config:
            value = self.config[pat_platform]
        elif pat_global in self.config:
            value = self.config[pat_global]
        else:
            value = ""

        if value == "0":
            value = ""
        return value

    def get_bool_string(self, setting: str) -> str:
        """For readability a function that returns "true" and "false" directly."""

        if self.get_setting(setting):
            return "true"
        else:
            return "false"

# Delete lines from a config file
def delete_lines(file_path: str, lines: tuple) -> None:
    with open(file_path, "r") as input:
        tmp_file = f'/tmp/{os.path.basename(file_path)}.tmp'
        with open(tmp_file, "w") as output:
            for line in input:
                write_this_line = True
                for item in lines:
                    if line.strip().startswith(item):
                        write_this_line = False
                        break
                if write_this_line:
                    output.write(line)
    # replace file with original name
    shutil.move(tmp_file, file_path)

# Append dictionary to the end of a file
def write_file(file_path: str, dictionary: dict, separator: str = ' = ', quote_sign: str = '"') -> None:
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    with open(file_path, "a") as file:
        for (key, value) in dictionary.items():
            file.write(f'{key}{separator}{quote_sign}{value}{quote_sign}\n')

# Generate the config out of the distribution.conf
def set_settings(rom_name: str, core: str, platform: str, controllers: str, autosave: str, snapshot: str) -> str:
    logger = Logger()
    shader_path = ''

    #
    # Do some checks and clean up first
    #

    # Log current call:
    logger.log(f'ROM: {rom_name}')
    logger.log(f'Platform: {platform}')
    logger.log(f'Core: {core}')
    logger.log(f'Controllers: {controllers}')
    logger.log(f'Autosave: {autosave}')
    logger.log(f'Snapshot: {snapshot}')

    # We only need the ROM, but we get the fullpath
    rom_name = os.path.basename(rom_name)
    # Delete any existing raappend.cfg first
    if os.path.isfile(ra_append_conf):
        os.remove(ra_append_conf)
    # Restore retroarch.cfg if it is missing or empty
    if not os.path.isfile(ra_conf) or os.stat(ra_conf).st_size == 0:
        shutil.copy(ra_source_conf,ra_conf)

    # Get the Device Name
    with open(os_arch_conf, encoding="utf-8") as f:
        device_name = f.readline().strip()
    logger.log(f'Device: {device_name}')

    # Is the CORE 32 or 64bit?
    if core in {'pcsx_rearmed', 'parallel_n64'}:
        bits='32bit'
    else:
        bits='64bit'
    logger.log(f'core is {bits}')

    # Dictionary for the raappend.cfg
    ra_append_dict = {}

    # Create config from distribution.conf
    config = Config(rom_name, platform)

    #
    # Global configuration directly in retroarch.cfg
    #

    # RA menu rgui, ozone, glui or xmb (fallback if everthing else fails)
    # if empty (auto in ES) do nothing to enable configuration in RA
    if menu_driver := config.get_setting('retroarch.menu_driver'):
        ra_dict = {}
        # delete setting only if we set new ones
    	# therefore configuring in RA is still possible
        delete_lines(ra_conf, ('menu_driver', 'menu_linear_filter'))
        if menu_driver == 'rgui':
            ra_dict['menu_driver'] = 'rgui'
            ra_dict['menu_linear_filter'] = 'true'
        elif menu_driver == 'ozone':
            ra_dict['menu_driver'] = 'ozone'
        elif menu_driver == 'glui':
            ra_dict['menu_driver'] = 'glui'
        else:
       		# play it save and set xmb if nothing else matches
            ra_dict['menu_driver'] = 'xmb'
        write_file(ra_conf, ra_dict)

    #
    # Convert the settings from distribution.conf to raappend.cfg
    #

    # FPS
    ra_append_dict['fps_show'] = config.get_bool_string("showFPS")

    # Retroachievements / Cheevos
    retro_achievements = {
        'arcade', 'atari2600', 'atari7800', 'atarilynx', 'colecovision',
        'famicom', 'fbn', 'fds', 'gamegear', 'gb', 'gba', 'gbah', 'gbc', 'gbch',
        'gbh', 'genesis', 'genh', 'ggh', 'intellivision', 'mastersystem',
        'megacd', 'megadrive', 'megadrive-japan', 'msx', 'msx2', 'n64',
        'neogeo', 'neogeocd', 'nes', 'nesh', 'ngp', 'ngpc', 'odyssey2',
        'pcengine', 'pcenginecd', 'pcfx', 'pokemini', 'psp', 'psx', 'sega32x',
        'segacd', 'sfc', 'sg-1000', 'snes', 'snesh', 'snesmsu1', 'supergrafx',
        'supervision', 'tg16', 'tg16cd', 'vectrex', 'virtualboy', 'wonderswan',
        'wonderswancolor',
    }
    if platform in retro_achievements:
        if config.get_setting("retroachievements"):
            ra_append_dict['cheevos_enable'] = "true"
            ra_append_dict['cheevos_username'] = config.get_setting("retroachievements.username")
            ra_append_dict['cheevos_password'] = config.get_setting("retroachievements.password")
            ra_append_dict['cheevos_hardcore_mode_enable'] = config.get_bool_string("retroachievements.hardcore")
            value = config.get_setting("retroachievements.leaderboards")
            if value == "enabled":
                ra_append_dict['cheevos_leaderboards_enable'] = "true"
            elif value == "trackers only":
                ra_append_dict['cheevos_leaderboards_enable'] = "trackers"
            elif value == "notifications only":
                ra_append_dict['cheevos_leaderboards_enable'] = "notifications"
            else:
                ra_append_dict['cheevos_leaderboards_enable'] = "false"
            ra_append_dict['cheevos_verbose_enable'] = config.get_bool_string("retroachievements.verbose")
            ra_append_dict['cheevos_auto_screenshot'] = config.get_bool_string("retroachievements.screenshot")
            ra_append_dict['cheevos_richpresence_enable'] = config.get_bool_string("retroachievements.richpresence")
            ra_append_dict['cheevos_challenge_indicators'] = config.get_bool_string("retroachievements.challengeindicators")
            ra_append_dict['cheevos_test_unofficial'] = config.get_bool_string("retroachievements.testunofficial")
            ra_append_dict['cheevos_badges_enable'] = config.get_bool_string("retroachievements.badges")
            ra_append_dict['cheevos_start_active'] = config.get_bool_string("retroachievements.active")
            ra_append_dict['cheevos_unlock_sound_enable'] = config.get_bool_string("retroachievements.soundenable")
        else:
            ra_append_dict['cheevos_enable'] = "false"
            ra_append_dict['cheevos_username'] = ""
            ra_append_dict['cheevos_password'] = ""
            ra_append_dict['cheevos_hardcore_mode_enable'] = "false"
            ra_append_dict['cheevos_leaderboards_enable'] = "false"
            ra_append_dict['cheevos_verbose_enable'] = "false"
            ra_append_dict['cheevos_test_unofficial'] = "false"
            ra_append_dict['cheevos_unlock_sound_enable'] = "false"
            ra_append_dict['cheevos_auto_screenshot'] = "false"
            ra_append_dict['cheevos_badges_enable'] = "false"
            ra_append_dict['cheevos_start_active'] = "false"
            ra_append_dict['cheevos_richpresence_enable'] = "false"
            ra_append_dict['cheevos_challenge_indicators'] = "false"

    # Netplay
    if config.get_setting("netplay"):
        ra_append_dict['netplay'] = "true"
        # Not needed any more?
        ## Disable Cheevos Hardcore Mode to allow savestates
        #if 'cheevos_hardcore_mode_enable' in ra_append_dict:
        #    ra_append_dict['cheevos_hardcore_mode_enable'] = "false"
        # Host or Client
        value = config.get_setting('netplay.mode')
        if value == 'host':
            ra_append_dict['netplay_mode'] = "false"
            ra_append_dict['netplay_client_swap_input'] = "false"
            ra_append_dict['netplay_ip_port'] = config.get_setting('netplay.port')
        elif value == 'client':
            ra_append_dict['netplay_mode'] = "true"
            ra_append_dict['netplay_ip_address'] = config.get_setting('netplay.client.ip')
            ra_append_dict['netplay_ip_port'] = config.get_setting('netplay.client.port')
            ra_append_dict['netplay_client_swap_input'] = "true"
        # Relay
        if value := config.get_setting('netplay.relay'):
            ra_append_dict['netplay_use_mitm_server'] = "true"
            ra_append_dict['netplay_mitm_server'] = value
        else:
            ra_append_dict['netplay_use_mitm_server'] = "false"
        ra_append_dict['netplay_delay_frames'] = config.get_setting('netplay.frames')
        ra_append_dict['netplay_nickname'] = config.get_setting('netplay.nickname')
        # spectator mode
        ra_append_dict['netplay_spectator_mode_enable'] = config.get_bool_string("netplay.spectator")
        ra_append_dict['netplay_public_announce'] = config.get_bool_string("netplay_public_announce")
    else:
        ra_append_dict['netplay'] = "false"

    # AI Translation Service
    if config.get_setting('ai_service_enabled'):
        ra_append_dict['ai_service_enable'] = "true"
        LangCodes = {
            "false": "0", "En": "1", "Fr": "3", "Pt": "49", "De": "5",
            "El": "30", "Es": "2", "Cs": "8", "Da": "9", "Hr": "11", "Hu": "35",
            "It": "4", "Ja": "6", "Ko": "12", "Nl": "7", "Nn": "46", "Po": "48",
            "Ro": "50", "Ru": "51", "Sv": "10", "Tr": "59", "Zh": "13",
        }
        ai_lang = config.get_setting('ai_target_lang')
        if ai_lang in LangCodes:
            ra_append_dict['ai_service_target_lang'] = f'{LangCodes[ai_lang]}'
        else:
            # use English as default
            ra_append_dict['ai_service_target_lang'] = "1"
        if ai_url := config.get_setting('ai_service_url'):
            ra_append_dict['ai_service_url'] = f'{ai_url}&mode=Fast&output=png&target_lang={ai_lang}'
        else:
            ra_append_dict['ai_service_url'] = f'http://ztranslate.net/service?api_key=BATOCERA&mode=Fast&output=png&target_lang={ai_lang}'
    else:
        ra_append_dict['ai_service_enable'] = "false"

    #
    # Global/System/Game specific settings
    #

    # Ratio
    # default to 22 (core provided) if case anything goes wrong
    ra_append_dict['aspect_ratio_index'] = "22"
    if ratio := config.get_setting('ratio'):
        index_rations = {
            '4/3': '0', '16/9': '1', '16/10': '2', '16/15': '3', '21/9': '4',
            '1/1': '5', '2/1': '6', '3/2': '7', '3/4': '8', '4/1': '9',
            '9/16': '10', '5/4': '11', '6/5': '12', '7/9': '13', '8/3': '14',
            '8/7': '15', '19/12': '16', '19/14': '17', '30/17': '18',
            '32/9': '19', 'config': '20', 'squarepixel': '21', 'core': '22',
            'custom': '23', 'full' : '24',
        }
        if ratio in index_rations:
            ra_append_dict['aspect_ratio_index'] = index_rations[ratio]

    # Bilinear filtering
    ra_append_dict['video_smooth'] = config.get_bool_string("smooth")

    # Video Integer Scale
    ra_append_dict['video_scale_integer'] = config.get_bool_string("integerscale")

    # Video Integer Scale Overscale
    ra_append_dict['video_scale_integer_overscale'] = config.get_bool_string("integerscaleoverscale")

    # RGA Scaling / CTX Scaling
    ra_append_dict['video_ctx_scaling'] = config.get_bool_string("rgascale")

    # Shaderset
    if shaderset := config.get_setting('shaderset'):
        ra_append_dict['video_shader_enable'] = "true"
        ra_append_dict['video_shader'] = shaderset
        # We need to print the shader folder for runemu.sh to use it
        shader_path = f'--set-shader /tmp/shaders/{shaderset}'
    else:
        ra_append_dict['video_shader_enable'] = "false"
        ra_append_dict['video_shader'] = ""

    # Filters
    # Set correct path for video- and audio-filters depending on 32/64bit
    ra_append_dict['audio_filter_dir'] = f'/usr/share/retroarch/filters/{bits}/audio'
    ra_append_dict['video_filter_dir'] = f'/usr/share/retroarch/filters/{bits}/video'
    # Filterset
    if filterset := config.get_setting('filterset'):
        # Filter do not work with RGA/CTX enabled
        ra_append_dict['video_ctx_scaling'] = "false"
        ra_append_dict['video_filter'] = f'/usr/share/retroarch/filters/{bits}/video/{filterset}'
    else:
        ra_append_dict['video_filter'] = ""

    # Rewind
    no_rewind = {'sega32x', 'psx', 'zxspectrum', 'odyssey2', 'mame', 'n64', 'dreamcast', 'atomiswave', 'naomi', 'neogeocd', 'saturn', 'psp', 'pspminis'}
    if config.get_setting('rewind') and platform not in no_rewind:
        ra_append_dict['rewind_enable'] = "true"
    else:
        ra_append_dict['rewind_enable'] = "false"

    # Saves
    # Incrementalsavestates
    if config.get_setting('incrementalsavestates'):
        ra_append_dict['savestate_auto_index'] = "true"
        ra_append_dict['savestate_max_keep'] = "0"
    else:
        ra_append_dict['savestate_auto_index'] = "false"
        ra_append_dict['savestate_max_keep'] = "50"
    # Autosave
    if config.get_setting('autosave'):
        ra_append_dict['savestate_auto_save'] = "true"
        ra_append_dict['savestate_auto_load'] = "true"
    else:
        ra_append_dict['savestate_auto_save'] = "false"
        ra_append_dict['savestate_auto_load'] = "false"
    # Snapshots
    ra_append_dict['savestate_directory'] = f'{snapshots}/{platform}'
    if snapshot:
        if autosave == "1":
            ra_append_dict['savestate_auto_load'] = "true"
            ra_append_dict['savestate_auto_save'] = "true"
        else:
            ra_append_dict['savestate_auto_load'] = "false"
            ra_append_dict['savestate_auto_save'] = "false"
        ra_append_dict['state_slot'] = f'{snapshot}'

    # Runahead
    # Runahead 1st Instance
    no_run_ahead = {'psp', 'sega32x', 'n64', 'dreamcast', 'atomiswave', 'naomi', 'neogeocd', 'saturn'}
    if (runahead := config.get_setting('runahead')) and platform not in no_run_ahead:
        ra_append_dict['run_ahead_enabled'] = "true"
        ra_append_dict['run_ahead_frames'] = runahead
    else:
        ra_append_dict['run_ahead_enabled'] = "false"
        ra_append_dict['run_ahead_frames'] = "1"
    # Runahead 2nd Instance
    if config.get_setting('secondinstance') and platform not in no_run_ahead:
        ra_append_dict['run_ahead_secondary_instance'] = "true"
    else:
        ra_append_dict['run_ahead_secondary_instance'] = "false"

    # Auto Frame Relay
    ra_append_dict['video_frame_delay_auto'] = config.get_bool_string("video_frame_delay_auto")

    # maxperf / CPU Governor
    if config.get_setting('maxperf'):
        ra_append_dict['cpu_scaling_mode'] = '2'
    else:
        ra_append_dict['cpu_scaling_mode'] = '4'

    #
    # Settings for special cores
    #

    ## atari800 core needs other settings when emulation atari5200
    if core == 'atari800':
        logger.log('Atari 800 section')
        retrocore_dict = {}
        atari800_dict = {}
        atari_dict = {}
        atari_conf = INSTALL_DIR + '/storage/.config/distribution/configs/atari800.cfg'
        atari800_conf = INSTALL_DIR + '/storage/.config/retroarch/config/Atari800/Atari800.opt'
        delete_lines(ra_core_conf, ('atari800_system =',))
        delete_lines(atari_conf, ('RAM_SIZE', 'STEREO_POKEY', 'BUILTIN_BASIC'))
        if os.path.isfile(atari800_conf):
            delete_lines(atari800_conf, ('atari800_system',))
        if platform == 'atari5200':
            retrocore_dict['atari800_system'] = '5200'
            atari800_dict['atari800_system'] = '5200'
            atari_dict['RAM_SIZE'] = '16'
            atari_dict['STEREO_POKEY'] = '0'
            atari_dict['BUILTIN_BASIC'] = '0'
        else:
            retrocore_dict['atari800_system'] = '800XL (64K)'
            atari800_dict['atari800_system'] = '800XL (64K)'
            atari_dict['RAM_SIZE'] = '64'
            atari_dict['STEREO_POKEY'] = '1'
            atari_dict['BUILTIN_BASIC'] = '1'
        write_file(ra_core_conf, retrocore_dict)
        # The format of the atari800.cfg is different
        # ('key=value' instead of 'key = "value"')
        write_file(atari_conf, atari_dict, separator='=', quote_sign='')
        write_file(atari800_conf, atari800_dict)

    # Gambatte
    if core == 'gambatte':
        logger.log('Gambatte section')
        gambatte_dict = {}
        gambatte_conf = INSTALL_DIR + "/storage/.config/retroarch/config/Gambatte/Gambatte.opt"

        if os.path.isfile(gambatte_conf):
            delete_lines(gambatte_conf, ('gambatte_gb_colorization', 'gambatte_gb_internal_palette'))
        else:
            gambatte_dict['gambatte_gbc_color_correction'] = 'disabled'

        colorization = config.get_setting('renderer.colorization')
        logger.log(f'gambatte colorization: {colorization}')
        if not colorization or colorization == 'auto':
            gambatte_dict['gambatte_gb_colorization'] = 'disabled'
        elif colorization == 'Best Guess':
            gambatte_dict['gambatte_gb_colorization'] = 'auto'
        elif colorization == 'GBC' or colorization == 'SGB':
            gambatte_dict['gambatte_gb_colorization'] = colorization
        else:
            gambatte_dict['gambatte_gb_colorization'] = 'internal'
            gambatte_dict['gambatte_gb_internal_palette'] = colorization

        write_file(gambatte_conf, gambatte_dict)

    #
    # Controllers
    #
    # We set up the controller index
    if controllers:
        for player in range(1,6):
            logger.log(f'Controller section {player}')
            if pindex := re.search(fr'p{player}index\s+([0-9]+)', controllers):
                ra_append_dict['input_player{player}_joypad_index'] = pindex.group(1)
            # Setting controller type for different cores
            if platform == "atari5200":
                ra_append_dict['input_libretro_device_p{player}'] = '513'

    #
    # Bezels / Decorations
    #
    # List of possible Bezel Folders
    bezel_dir = ('/tmp/overlays/bezels', INSTALL_DIR + '/storage/roms/bezels')
    # Define the resolutions of the different systems (0:x 1:y 2:width 3:height) as seen in Scaling -> Aspect Ration -> Custom
    # Devices (width x hight)
    #   RG351P/M = 480x320
    #   RG351V/MP = 640x480
    #   RG552 = 1920x1152
    #   DECK = 1280x800
    # Consoles (width x hight)
    #   GB/GBC/GG = 160x144
    #   supervision = 160x160
    #   Pokemini = 96x64
    #   ngp/ngpc = 160x152
    #   wonderswan/wonderswancolor = 224×144
    if device_name == "RG351P":
        system_viewport = {
            'standard': (1, 1, 479, 319),          # max-1
            'gb': (80, 16, 320, 288),              # x2
            'gbh': (80, 16, 320, 288),             # x2
            'gbc': (80, 16, 320, 288),             # x2
            'gbch': (80, 16, 320, 288),            # x2
            'supervision': (80, 0, 320, 320),      # x2
            'gamegear': (80, 16, 320, 288),        # x2
            'ggh': (80, 16, 320, 288),             # x2
            'pokemini': (96, 64, 288, 192),        # x3
            'ngp': (80, 8, 320, 304),              # x2
            'ngpc': (80, 8, 320, 304),             # x2
            'wonderswan': (16, 16, 448, 288),      # x2
            'wonderswancolor': (16, 16, 448, 288), # x2
        }
    elif device_name == "RG351V" or device_name == "RG351MP":
        system_viewport = {
            'standard': (1, 1, 639, 479),          # max-1
            'gb': (80, 24, 480, 432),              # x3
            'gbh': (80, 24, 480, 432),             # x3
            'gbc': (80, 24, 480, 432),             # x3
            'gbch': (80, 24, 480, 432),            # x3
            'supervision': (80, 0, 480, 480),      # x3
            'gamegear': (80, 24, 480, 432),        # x3
            'ggh': (80, 24, 480, 432),             # x3
            'pokemini': (128, 112, 384, 256),      # x4
            'ngp': (80, 12, 480, 456),             # x3
            'ngpc': (80, 12, 480, 456),            # x3
            'wonderswan': (96, 96, 448, 288),      # x2
            'wonderswancolor': (96, 96, 448, 288), # x2
        }
    elif device_name == "RG552":
        system_viewport = {
            'standard': (1, 1, 1919, 1151),         # max-1
            'gb': (320, 0, 1280, 1152),             # x8
            'gbh': (320, 0, 1280, 1152),            # x8
            'gbc': (320, 0, 1280, 1152),            # x8
            'gbch': (320, 0, 1280, 1152),           # x8
            'supervision': (400, 16, 1120, 1120),   # x7
            'gamegear': (320, 0, 1280, 1152),       # x8
            'ggh': (320, 0, 1280, 1152),            # x8
            'pokemini': (384, 192, 1152, 768),      # x12
            'ngp': (400, 44, 1120, 1064),           # x7
            'ngpc': (400, 44, 1120, 1064),          # x7
            'wonderswan': (64, 0, 1792, 1152),      # x8
            'wonderswancolor': (64, 0, 1792, 1152), # x8
        }
    elif device_name == "DECK":
        #just copied from 552, I have to edit this
        system_viewport = {
            'standard': (1, 1, 1279, 799),         # max-1
            'gb': (320, 0, 1280, 1152),             # x8
            'gbh': (320, 0, 1280, 1152),            # x8
            'gbc': (320, 0, 1280, 1152),            # x8
            'gbch': (320, 0, 1280, 1152),           # x8
            'supervision': (400, 16, 1120, 1120),   # x7
            'gamegear': (320, 0, 1280, 1152),       # x8
            'ggh': (320, 0, 1280, 1152),            # x8
            'pokemini': (384, 192, 1152, 768),      # x12
            'ngp': (400, 44, 1120, 1064),           # x7
            'ngpc': (400, 44, 1120, 1064),          # x7
            'wonderswan': (64, 0, 1792, 1152),      # x8
            'wonderswancolor': (64, 0, 1792, 1152), # x8
        }

    bezel_cfg = None

    if (bezel := config.get_setting('bezel')) and platform in system_viewport:
        logger.log(f'bezel: {bezel} platform: {platform} rom: {rom_name}')
        tmp_bezel = "/tmp/351elec-bezel.cfg"
        game_cfg = ''
        # set path
        path = ''
        for searchpath in bezel_dir:
            if os.path.isdir(f'{searchpath}/{bezel}'):
                path = f'{searchpath}/{bezel}'

        bezel_system = config.get_setting('bezel.system.override')
        if not bezel_system or bezel_system == "AUTO":
            bezel_system = platform

        bezel_system_png = f'{path}/systems/{bezel_system}.png'
        logger.log(f'Bezel system png: {bezel_system_png}')

        game_bezel_override = config.get_setting('bezel.game.override')
        logger.log(f'Game bezel override: {game_bezel_override}')
        if not game_bezel_override or game_bezel_override == "AUTO":
            logger.log('No game specific override found.  Looking for games')
            # is there a $ROMNAME.cfg?
            # exactly the same / just the name / default
            # Random bezels have to match $ROMNAME./d+.cfg
            romdir = f'{path}/systems/{bezel_system}/games'
            full_name = os.path.splitext(rom_name)[0]
            short_name = full_name.split(' (')[0]
            if os.path.isdir(romdir):
                with os.scandir(romdir) as it:
                    full_list = [entry.name for entry in it if entry.is_file() and entry.name.endswith('.cfg')]
                for romname in (full_name, short_name , 'default'):
                    logger.log(f'Looking at: {romdir}/{romname}')
                    file_list = [file for file in full_list if re.fullmatch(fr'{re.escape(romname)}\.[0-9]+\.cfg', file)]
                    if len(file_list) > 0:
                        game_cfg = f'{romdir}/{random.choice(file_list)}'
                        logger.log(f'Using random config: {game_cfg}')
                        break
                    elif os.path.isfile(f'{romdir}/{romname}.cfg'):
                        game_cfg = f'{romdir}/{romname}.cfg'
                        logger.log(f'Using ROM config: {game_cfg}')
                        break
        else:
            game_cfg = f'{path}/systems/{bezel_system}/games/{game_bezel_override}.cfg'

        if os.path.isfile(game_cfg):
            logger.log(f'game config file exists: {game_cfg}')
            with open(game_cfg) as f:
                contents = f.read().strip()
            bezel_system_png = f'{path}/systems/{bezel_system}/games/{contents}'
        logger.log(f'bezel png: {bezel_system_png}')
        if os.path.isfile(bezel_system_png):
            tmp_bezel_dict = {}
            tmp_bezel_dict['overlays'] = '1'
            tmp_bezel_dict['overlay0_full_screen'] = 'true'
            tmp_bezel_dict['overlay0_normalized'] = 'true'
            tmp_bezel_dict['overlay0_overlay'] = bezel_system_png
            overlays_dir = f'{path}/systems/{bezel_system}/overlays/'
            count = 0
            if os.path.isdir(overlays_dir):
                for overlay_png in iglob(f'{overlays_dir}/*.png'):
                    overlay_name = os.path.splitext(os.path.basename(overlay_png))[0]
                    overlay_setting = config.get_setting(f'bezel.overlay.{overlay_name}')
                    if not overlay_setting:
                        continue
                    logger.log(f'Adding overlay. name: {overlay_name} overlay setting: {overlay_setting}')
                    tmp_bezel_dict[f'overlay0_desc{count}_overlay'] = overlay_png
                    tmp_bezel_dict[f'overlay0_desc{count}'] = 'nul,0.5,0.5,rect,0.5,0.5'
                    count += 1
            tmp_bezel_dict['overlay0_descs'] = count
            if os.path.isfile(tmp_bezel):
                os.remove(tmp_bezel)
            write_file(tmp_bezel, tmp_bezel_dict)
            bezel_cfg = tmp_bezel

    if bezel_cfg is not None:
        logger.log('using bezel')
        # configure bezel
        ra_append_dict['input_overlay_enable'] = 'true'
        ra_append_dict['input_overlay'] = bezel_cfg
        ra_append_dict['input_overlay_hide_in_menu'] = 'true'
        ra_append_dict['input_overlay_opacity'] = '1.000000'
        ra_append_dict['input_overlay_show_inputs'] = '2'
        ra_append_dict['video_scale_integer'] = 'false'
        ra_append_dict['aspect_ratio_index'] = '23'
        # configure custom scaling
        # needs some grouping to reflect the hack systems as well (i. e. gb=gb, gbh, gbc and gbch)
        ra_append_dict['custom_viewport_x'] = system_viewport[platform][0]
        ra_append_dict['custom_viewport_y'] = system_viewport[platform][1]
        ra_append_dict['custom_viewport_width'] = system_viewport[platform][2]
        ra_append_dict['custom_viewport_height'] = system_viewport[platform][3]
    else:
        logger.log('not using bezel')
        # disable decorations
        ra_append_dict['input_overlay_enable'] = 'false'
        # set standard resolution for custom scaling
        ra_append_dict['custom_viewport_x'] = system_viewport['standard'][0]
        ra_append_dict['custom_viewport_y'] = system_viewport['standard'][1]
        ra_append_dict['custom_viewport_width'] = system_viewport['standard'][2]
        ra_append_dict['custom_viewport_height'] = system_viewport['standard'][3]

    # DECK specific options TODO: integrate better in the code
    # TODO: not working
    #ra_append_dict['video_windowed_fullscreen'] = "true"

    # Write the raappend.cfg
    logger.log('Write raappend.cfg')
    write_file(ra_append_conf, ra_append_dict)

    logger.log('done ...')
    return shader_path

# Main (if we are run as a script and not as a module)
if __name__ == '__main__':
    # Arguments
    parser = ArgumentParser(description="Convert ES settings from distribution.conf to RetroArch configuration in raappend.conf.")
    parser.add_argument("--core", help="core", required=True)
    parser.add_argument("--platform", help="platform", required=True)
    parser.add_argument("--rom", help="ROM file name", required=True)
    parser.add_argument("--controllers", help="controller config", default="-p1index 0")
    parser.add_argument("--autosave", help="autosave", default="0")
    parser.add_argument("--snapshot", help="snapshot", default="")
    args = parser.parse_args()
    shader_path = set_settings(rom_name=args.rom, core=args.core, platform=args.platform, controllers=args.controllers, autosave=args.autosave, snapshot=args.snapshot)
    if shader_path:
        print(shader_path)
