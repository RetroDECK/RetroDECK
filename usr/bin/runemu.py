#!/usr/bin/env python3

import datetime
import os
import shlex
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from time import perf_counter
from typing import TYPE_CHECKING, Optional

from setsettings import set_settings

# If we are on Steam Deck we want a prefix

# TODO: INSTALL_DIR + '/storage/.config/.OS_ARCH' was not working, dunno why, I'll check later
# DEVICE = "DECK" #for the moment this will do

INSTALL_DIR = os.path.expanduser('~/retrodeck')
with open(INSTALL_DIR + r'/storage/.config/.OS_ARCH', 'r') as file:
	DEVICE = file.read().rstrip()

#if DEVICE == "DECK" :
#    
#else:
#	INSTALL_DIR = ""

if TYPE_CHECKING:
	#These except Union are deprecated in 3.9 and should be replaced with collections.abc / builtin list type, but we have 3.8 for now
	from typing import List, Mapping, MutableMapping, Sequence, Union

LOGS_DIR = Path('/tmp/logs')
RA_TEMP_CONF = INSTALL_DIR + '/storage/.config/retroarch/retroarch.cfg'
RA_APPEND_CONF = '/tmp/raappend.cfg'
log_path = LOGS_DIR / 'exec.log'

def call_profile_func(function_name: str, *args: str) -> str:
	# if we are on Steam Deck
	if DEVICE == "DECK" :
		proc = subprocess.run(f'. {INSTALL_DIR}/export_func.sh', shell=True, stdout=subprocess.PIPE, check=True, text=True)
	else:
		#We are going to want to call some stuff from /etc/profile, they are defined in ../profile.d/99-distribution.conf
		#But on Steam Deck this is not needed as these stuff is called by another script as profile.d is just for embedded distros
		proc = subprocess.run(f'. /etc/profile && {shlex.quote(function_name)} {shlex.join(args)}', shell=True, stdout=subprocess.PIPE, check=True, text=True)
	return proc.stdout.strip('\n')

def get_es_setting(setting_type: str, setting_name: str) -> str:
	#from es_settings.cfg (XML)
	return call_profile_func('get_es_setting', setting_type, setting_name)

log_level = get_es_setting('string', 'LogLevel') #If set to default, would equal empty string

def jslisten_set(*exe_names: str):
	#exe_names are passed as one argument, intended for killall to use them later
	if DEVICE != "DECK" :
		call_profile_func('jslisten', 'set', shlex.join(exe_names))

def jslisten_stop():
	#call_profile_func('jslisten', 'stop')
	if DEVICE != "DECK" :
		subprocess.check_call(['systemctl', 'stop', 'jslisten'])

def get_elec_setting(setting_name, platform=None, rom=None):
	#From distribution.conf
	#Potentially this can be reimplemented in Python if that turns out to be a good idea
	return call_profile_func('get_ee_setting', setting_name, platform, rom)

def set_elec_setting(setting_name, value):
	call_profile_func('set_ee_setting', setting_name, value)

def check_bios(platform, core, emulator, game, log_path_):
	call_profile_func('ee_check_bios', platform, core, emulator, game, log_path_)

def log(text):
	with log_path.open('at', encoding='utf-8') as log_file:
		print(text, file=log_file)

def cleanup_and_quit(return_code):
	if log_level == 'debug':
		log(f'Cleaning up and exiting with return code {return_code}')

	if DEVICE != "DECK" :
		jslisten_stop()
	clear_screen()
	call_profile_func('normperf')
	call_profile_func('set_audio', 'default')
	sys.exit(return_code)

def clear_screen():
	if DEVICE != "DECK" :
		if log_level == 'debug':
			log('Clearing screen')
		with open('/dev/console', 'wb') as console:
			subprocess.run('clear', stdout=console, check=True)

def list_archive(path: Path) -> 'List[str]':
	#7z path needs to be given explicitly, otherwise it won't find 7z.so
	sevenzip_proc = subprocess.run(['/usr/bin/7z', 'l', '-slt', path], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
	if sevenzip_proc.returncode != 0:
		raise OSError(sevenzip_proc.stderr.strip())
	#Ignore the first Path = line which is the archive itself
	return [line[len('Path = '):] for line in sevenzip_proc.stdout.splitlines() if line.startswith('Path = ')][1:]

def extract_archive(path: Path) -> Path:
	#Assume there is only one file, otherwise things get weird
	inner_filename = list_archive(path)[0]
	#Since save files etc may be placed in the ROM folder, we should extract there so everything still works transparently, which also helps with overrides and such
	subprocess.check_call(['/usr/bin/7z', 'e', f'-o{str(path.parent)}', path, inner_filename], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
	return path.parent.joinpath(inner_filename)

@dataclass(frozen=True)
class StandaloneEmulator():
	jskill_name: str
	args: 'Sequence[str]'
	should_extract: bool = False

standalone_emulators: 'MutableMapping[str, StandaloneEmulator]' = {
	'AMIBERRY': StandaloneEmulator('amiberry', ['/usr/bin/amiberry.start', '<path>']),
	'AdvanceMame': StandaloneEmulator('advmame', ['/usr/bin/advmame.sh', '<path>']),
	'HATARISA': StandaloneEmulator('hatari', ['/usr/bin/hatari.start', '<path>']),
	'hypseus_singe': StandaloneEmulator('hypseus', ['/usr/bin/hypseus.sh', '<path>']),
	'OPENBOR': StandaloneEmulator('openbor', ['/usr/bin/openbor.sh', '<path>']),
	'PPSSPPSDL': StandaloneEmulator('PPSSPPSDL', ['/usr/bin/ppsspp.sh', '<path>']),
	'SCUMMVMSA': StandaloneEmulator('scummvm', ['/usr/bin/scummvm.start', 'sa', '<path>']),
	'drastic': StandaloneEmulator('drastic', ['/usr/bin/drastic.sh', '<path>']),
	'ecwolf': StandaloneEmulator('ecwolf', ['/usr/bin/ecwolf.sh', '<path>']),
	'gzdoom': StandaloneEmulator('gzdoom', ['/usr/bin/gzdoom.sh', '<path>']),
	'lzdoom': StandaloneEmulator('lzdoom', ['/usr/bin/lzdoom.sh', '<path>']),
	'mpv': StandaloneEmulator('mpv', ['/usr/bin/mpv_video.sh', '<path>']),
	'pico8': StandaloneEmulator('pico8_dyn', ['/usr/bin/pico-8.sh', '<path>']),
	'piemu': StandaloneEmulator('piemu', ['/usr/bin/bash', '-l', '/usr/bin/piemu.sh', '<path>']),
	'raze': StandaloneEmulator('raze', ['/usr/bin/raze.sh', '<path>']),
	'solarus': StandaloneEmulator('solarus-run', ['/usr/bin/solarus.sh', '<path>']),
}

def _load_customized_standalone_emulators():
	try:
		with open(INSTALL_DIR + '/storage/.config/standalone_emulators', 'rt', encoding='utf-8') as f:
			for line in f:
				if ': ' not in line or line.startswith('#'):
					continue
				name, rest = line.rstrip().split(': ', 1)
				args = rest.split(' ')
				kill_name = name
				should_extract = False
				#If name of exe to kill was not listed, assume it is the same as the emulator name
				if not args[0].startswith('/'):
					kill_name = args[0]
					args = args[1:]
					if args[-1] == 'should_extract':
						args = args[:-1]
						should_extract = True
				standalone_emulators[name] = StandaloneEmulator(kill_name, args, should_extract)
	except (FileNotFoundError, ValueError):
		pass

_load_customized_standalone_emulators()

class EmuRunner():
	def __init__(self, rom: Optional[Path], platform: Optional[str], emulator: Optional[str], core: Optional[str], args: 'Mapping[str, str]') -> None:
		self.rom = rom
		self.platform = platform
		self.emulator = emulator
		self.core = core
		self.args = args
		self.temp_files: 'List[Path]' = [] #Files that we extracted from archives, etc. to clean up later
		self.environment = os.environ.copy()

	def download_things_if_needed(self) -> None:
		if self.core == 'freej2me':
			#freej2me needs the JDK to be downloaded on the first run
			subprocess.run(INSTALL_DIR + '/usr/bin/freej2me.sh', check=True)
			self.environment['JAVA_HOME']=INSTALL_DIR + '/storage/jdk'
			self.environment['PATH'] = INSTALL_DIR + '/storage/jdk/bin:' + os.environ['PATH']
		elif self.core == 'easyrpg':
			# easyrpg needs runtime files to be downloaded on the first run
			subprocess.run(INSTALL_DIR + '/usr/bin/easyrpg.sh', check=True)

	def toggle_max_performance(self) -> None:
		if get_elec_setting('maxperf', self.platform, self.rom.name if self.rom else None) == '1':
			if log_level == 'debug':
				log('Enabling max performance as requested')
			call_profile_func('maxperf')
		else:
			call_profile_func('normperf')

	def set_settings(self) -> str:
		rom_name = str(self.rom) if self.rom else ''
		core = self.core if self.core else ''
		platform = self.platform if self.platform else ''
		return set_settings(rom_name, core, platform, controllers=self.args.get('controllers', ''), autosave=self.args.get('autosave', ''), snapshot=self.args.get('state_slot', ''))

	def get_standalone_emulator_command(self) -> 'Sequence[Union[str, Path]]':
		if not self.emulator:
			raise ValueError('runemu.py was called improperly, tried to launch a standard emulator with no emulator')
		if log_level != 'minimal':
			log('Running a standalone emulator:')
			log(f'platform: {self.platform}')
			log(f'emulator: {self.emulator}')
		#Core is not actually relevant (other than Mupen64Plus which is in another function)

		emu = standalone_emulators[self.emulator]
		path = self.rom
		if self.rom and emu.should_extract and self.rom.suffix in {'.zip', '.7z', '.gz', '.bz2'}:
			path = extract_archive(self.rom)
			self.temp_files.append(path)

		command = [arg for arg in (path if arg == '<path>' else arg for arg in emu.args) if arg]

		jslisten_set(emu.jskill_name)
		return command

	def get_retroarch_command(self, shader_arg: str) -> 'Sequence[Union[str, Path]]':
		if log_level != 'minimal':
			log('Running a libretro core via RetroArch')
			log(f'platform: {self.platform}')
			log(f'core: {self.core}')
		retroarch_binary = 'retroarch'
		if self.core in {'pcsx_rearmed', 'parallel_n64'}:
			retroarch_binary = 'retroarch32'
			self.environment['LD_LIBRARY_PATH'] = '/usr/lib32'
		
		rom_path: 'Optional[Union[str, Path]]' = self.rom

		if self.rom:
			if self.platform == 'doom' and self.rom.suffix == '.doom':
				subprocess.run(['dos2unix', self.rom], check=True) #Hmmmmm but do we need that
				with self.rom.open('rt', encoding='utf-8') as doomfile:
					for line in doomfile:
						key, _, value = line.partition('=')
						if key == 'IWAD':
							rom_path = value
							break
			if self.core == 'scummvm' and self.rom.suffix == '.scummvm':
				#ScummVM libretro core actually only works with .scummvm files that just have the game ID with no path specified, which isn't how they are generated by the scummvm scanner script
				#But if you give it any other path to a file, it will autodetect a game inside that file's parent directory, even if the file doesn't actually exist
				#This would otherwise be what /usr/bin/scummvm.start tries to do when its first arg is "libretro", by cd'ing into that game directory
				path = Path(self.rom.read_text(encoding='utf-8').split('"')[1])
				rom_path = path / 'game'

		jslisten_set(retroarch_binary)
		command: 'List[Union[str, Path]]' = [os.path.join('/usr/bin/', retroarch_binary), '-L', Path('/tmp/cores/', f'{self.core}_libretro.so')]
		
		if log_level != 'minimal':
			command.append('--verbose')

		if 'host' in self.args or 'connect' in self.args:
			netplay_nick = get_elec_setting('netplay.nickname')
			if not netplay_nick:
				netplay_nick = '351ELEC'
			if 'connect' in self.args:
				set_elec_setting('netplay.client.port', self.args['port'])
				set_elec_setting('netplay.client.ip', self.args['connect']) #We should now have parsed that properly so it's just a hostname/IP address, no --port argument
				command += ['--connect', self.args['connect'] + '|' + self.args['port']]
			if 'host' in self.args:
				command += ['--host', self.args['host']]
				
			command += ['--nick', netplay_nick]

		if self.core == 'fbneo' and self.platform == 'neocd':
			command += ['--subsystem', self.platform]
		if shader_arg:
			#Returned from setsettings, this is of the form "--shader-set /tmp/shaders/blahblahblah", apparently actually needed even if video_shader is set in RA_APPEND_CONF
			command += shlex.split(shader_arg)
		command += ['--config', RA_TEMP_CONF, '--appendconfig', RA_APPEND_CONF]
		if rom_path:
			command.append(rom_path)
		
		return command

	def get_retrorun_command(self) -> 'Sequence[Union[str, Path]]':
		if not self.rom:
			raise ValueError('runemu.py was called improperly, tried to launch retrorun with no game')
		if not self.platform:
			raise ValueError('runemu.py was called improperly, tried to launch retrorun with no platform')
		if not self.core:
			raise ValueError('runemu.py was called improperly, tried to launch retrorun with no platform')

		core_path = Path('/tmp/cores/', f'{self.core}_libretro.so')
		if log_level != 'minimal':
			log('Running a libretro core via retrorun')
			log(f'platform: {self.platform}')
			log(f'core: {self.core}')
		jslisten_set('retrorun', 'retrorun32')

		path = self.rom
		if self.rom.suffix in {'.zip', '.7z', '.gz', '.bz2'} and self.platform not in {'arcade', 'naomi', 'atomiswave', 'fbneo', 'mame'}:
			path = extract_archive(self.rom)
			self.temp_files.append(path)
			
		return [INSTALL_DIR + '/usr/bin/retrorun.sh', core_path, path, self.platform]

	def get_mupen64plus_standalone_command(self) -> 'Sequence[Union[str, Path]]':
		if not self.rom:
			raise ValueError('runemu.py was called improperly, tried to launch Mupen64Plus standalone with no video plugin')
		if not self.core:
			raise ValueError('runemu.py was called improperly, tried to launch Mupen64Plus standalone with no video plugin')
		if log_level != 'minimal':
			log(f'Running Mupen64Plus standalone with {self.core} video plugin')
		jslisten_set('mupen64plus')
		path = self.rom
		if self.rom.suffix in {'.zip', '.7z', '.gz', '.bz2'}:
			path = extract_archive(self.rom)
			self.temp_files.append(path)
			
		return [INSTALL_DIR + '/usr/bin/m64p.sh', self.core, path]

	def get_command(self, shader_arg: str='') -> 'Sequence[Union[str, Path]]':			
		is_libretro_port = self.core and not self.emulator
		#If true this was called from the inside of a port .sh that runs a libretro port (e.g. 2048, tyrQuake, etc), it makes no sense otherwise

		if self.rom and (self.rom.suffix == '.sh' or self.platform == 'tools'):
			#If the ROM is a shell script then just execute it (tools, ports, Pico-8 splore, ScummVM scanner, etc)
			return ['/usr/bin/bash', '-l', self.rom]
		elif self.emulator == 'retroarch' or is_libretro_port:
			return self.get_retroarch_command(shader_arg)
		elif self.emulator == 'retrorun':
			return self.get_retrorun_command()
		elif self.emulator == 'mupen64plussa':
			return self.get_mupen64plus_standalone_command()
		else:
			return self.get_standalone_emulator_command()

	def run(self, command: 'Sequence[Union[str, Path]]') -> None:
		clear_screen()
		if log_level != 'minimal':
			log(f'Executing game: {self.rom}')
			log(f'Executing {command}')
		with log_path.open('at', encoding='utf-8') as log_file:
			subprocess.run(command, stdout=log_file, stderr=subprocess.STDOUT, check=True, text=True, env=self.environment)

	def cleanup_temp_files(self) -> None:
		for temp_file in self.temp_files:
			temp_file.unlink(missing_ok=True)

def main():
	time_started = perf_counter()

	i = 0
	args: dict[str, str] = {}
	while i < len(sys.argv)-1:
		if sys.argv[i].startswith('--'):
			args[sys.argv[i][2:]] = sys.argv[i + 1]
			i += 1
			continue
		if sys.argv[i].startswith('-'):
			args[sys.argv[i][1:]] = sys.argv[i + 1]
			i += 1
			continue
		i += 1

	rom = Path(args['rom']) if 'rom' in args else None
	platform = args.get('platform')
	core = args.get('core')
	emulator = args.get('emulator')
		
	log_path.unlink(missing_ok=True)
	LOGS_DIR.mkdir(parents=True, exist_ok=True)
	log_path.touch()
	
	log(f'Emulation run log: Started at {datetime.datetime.now()}')
	log(f'Args: {args}')

	runner = EmuRunner(rom, platform, emulator, core, args)

	runner.download_things_if_needed()
	runner.toggle_max_performance()

	#Disable netplay by default
	set_elec_setting('netplay.client.ip', 'disable')
	set_elec_setting('netplay.client.port', 'disable')

	jslisten_stop()

	shader_arg = runner.set_settings()
	command = runner.get_command(shader_arg)
	if log_level != 'minimal':
		log(f'Took {perf_counter() - time_started} seconds to start up')
	clear_screen()

	try:
		runner.run(command)
		exit_code = 0
	except subprocess.CalledProcessError as cpe:
		log(f'Process exited improperly with return code {cpe.returncode}')
		exit_code = 1
		requires_bios = {'atari5200', 'atari800', 'atari7800', 'atarilynx', 'colecovision', 'amiga', 'amigacd32', 'o2em', 'intellivision', 'pcengine', 'pcenginecd', 'pcfx', 'fds', 'segacd', 'saturn', 'dreamcast', 'naomi', 'atomiswave', 'x68000', 'neogeo', 'neogeocd', 'msx', 'msx2', 'sc-3000'}
		if platform in requires_bios:
			if platform == 'msx2':
				platform_to_check = 'msx2'
			elif platform == 'pcenginecd':
				platform_to_check = 'pcengine'
			elif platform == 'amigacd32':
				platform_to_check = 'amiga'
			else:
				platform_to_check = platform
			check_bios(platform_to_check, core, emulator, rom, log_path)
	finally:
		runner.cleanup_temp_files()
		cleanup_and_quit(exit_code)
	

if __name__ == '__main__':
	main()
