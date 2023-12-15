# What are the various folders and filepaths in RetroDECK?

RetroDECK is a Flatpak a sandboxed bundle of different applications and configurations. One part of the files are none writable while others are.

## ~/retrodeck
It's the home folder of RetroDECK itself, it contains:

- `bios`, the bios folder, the actual `retroarch/system` folder is poiting here `~/.var/app/net.retrodeck.retrodeck/config/emulationstation/.emulationstation/downloaded_media` is pointing here
- `.downloaded_media`, this is where you scraped data is saved (images, videos, logos..),
- `.lock`, this file tells RetroDECK that the settings are done and to not reset them, if this file is missing it will trigger a first boot showing the setup. Here is written the software version that is compared to the actual version to check if an update is needed.
- `.logs`, logs folder
- `roms`, if internal is chosen the roms folder is here, otherwise it's in `<sdcard>/retrodeck/roms`
- `saves`, emulators saves file location
- `screenshots`, emulators screenshots location
- `states`, emulators save states location
- `gamelists`, RetroDECK's gamelist location
- `texture_packs`, emulators texture packs location
- `mods`, emulators mods location
- `.themes`, additional themes folder, `~/.var/app/net.retrodeck.retrodeck/config/emulationstation/.emulationstation/themes` is poiting here

## ~/.var/app/net.retrodeck.retrodeck
This folder is the only flatpak folder that is editable user side, it's mapped as `/var` in the flatpak itself, from now on we will use the flatpak paths unless differently specified.

### config/

- `config`, contains all the various software configs such as RetroDECK, retroarch folder and standalones emulator configs
    - `retroarch`, the retroarch folder (see below)
    - `emulationstation`, emulationstation home folder (see below)
    - `retrodeck`, to not be confued with `~/retrodeck/`, this folder contains the retrodeck configs, see below.
    -  various standalone emulators config folders such as `yuzu`, `pcsx2`, `melonDS`, `dolphin-emu` and so on.

### config/retroarch

- `system`, retroarch bios (system) folder, this points to `~/retrodeck/bios`
- `core`, retroarch cores folder, this is populated by `/app/share/libretro/cores` at the first startup (or with `--reset`, `--reset-ra`)
- `retroarch.cfg`, the retroarch config, the original one is located in `/app/retrodeck/emu-configs/retroarch.cfg`, and similarly to above it's generated at the first startup

### config/emulationstation

- `ROMs`, this is linked to the roms folder in `~/retroeck/roms`or `<sdcard>/roms`
- `.emulationstation`, ES-DE main folder
    - `custom_systems`, where the customs systems are kept (example the tools file), check the official ES-DE docs for more info.
    - `downloaded_media`, this points to `~/retrodeck/.downloaded_media`
    - `themes`, this points to `~/retrodeck/.themes`
    - `es_log.txt`, ES-DE log file
    - `es_settings.xml`, ES-DE settings file

### config/retrodeck

- `tools`
- `version`, this file carries the RetroDECK version number and it ś generated during the flatpak build.

### data/
Some emulators, like yuzu, needs this path, here for example is even symlinked the yuzu keys and firmware folder.

### emu-configs/defaults/retrodeck/controller_configs
Where the Steam Input .vdf files are located

### /var/lib/flatpak/app/net.retrodeck.retrodeck/current/active/files/
Non-flatpak path: this folders contain file such as the .desktop, icons, etc.

This is mapped as the `/app` folder in flatpak, this folder is inside the read only file system and so all this tree is immutable (actually can be edited by root for develop purposes).<br>
FYI: you can edit the with KWrite, it justs ask you for the root password when saving.

### /var/lib/flatpak/app/net.retrodeck.retrodeck/current/active/files/share/emulationstation/resources/systems/unix/
This contains `es_find_rules.xml` and `es_systems.xml`

### /app/bin
All the binary files, like `retrodeck.sh`, the main program (wrapper).
All these programs can be launched in developer mode just invoking them in the terminal.

### /app/retrodeck
This folder contains the default configuration that is restored with the various `--reset` commands.

- `emu-configs`
- `steam`
- `tools`
- `es_settings.xml`
- `tools-gamelist.xml`









