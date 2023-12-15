# The RetroDECK Configurator

**Please note that we are going to rebuild the configurator into a controller friendly GODOT application and that the current version is not the final design.**

<img src="../../wiki_images/graphics/configurator/configurator.png" width="500">

The `RetroDECK Configurator` is a unique multi-use utility that exists within RetroDECK to manage many aspect of the application and exposes functions from the `RetroDECK Framework` to the user.

The `RetroDECK Configurator` can be opened from:

- The main menu inside the ES-DE interface and choose `RetroDECK Configurator`.

<img src="../../wiki_images/graphics/configurator/configurator-esde.png" width="500">

* From the `RetroDECK Configurator.desktop` desktop shortcut, available in your application menu.

<img src="../../wiki_images/graphics/configurator/configurator-kde.png" width="500">

* From CLI by calling `flatpak run net.retrodeck.retrodeck --configurator`

What follows are the commands you can use inside the Configurator (more commands will be added during development).



## Presets & Settings
In this menu you can set various presets.

### Global: Presets & Settings
In this menu you will find presets and settings that span over multiple emulators.

<br>

#### RetroAchivements: Login
Login to RetroAchievements in all supported emulators and cores.

<br>

#### RetroAchivements: Logut
Logut from RetroAchievements in all supported emulators and cores.

<br>

#### RetroAchivements: Hardcore Mode
Enables `Hardcore Mode` from RetroAchievements in all supported emulators and cores.

<br>

#### Widescreen: Enable/Disable
Enables or disable Widescreen in all supported emulators and cores.

<br>

#### Swap A/B and X/Y: Enable/Disable
Swaps `A/B` `X/Y` in all supported emulators and cores.

<br>

#### Ask to Exit prompt: Enable/Disable
Enables or disables ask to exit prompts in all supported emulators and cores.
Note: If you disable this, the emulators will directly exit.

<br>


### RetroArch: Presets & Settings
In this menu you will find presets and settings for RetroArch.

<br>

#### Borders: Enable/Disable
Enable / Disable borders across the RetroArch cores you choose.

<br>

#### Rewind: Enable/Disable
Enable / Disable rewind across all  of RetroArch (this may impact performance on some more demanding systems).

<br>

### Wii & Gamecube: Presets & Settings
In this menu you will find presets and settings for Dolphin and Primehack.

<br>

#### Dolphin Textures: Universal Dynamic Input
Enable / Disable Venomalias's Universal Dynamic Input Texture for Dolphin.

<br>

#### Primehack Textures: Universal Dynamic Input
Enable / Disable Venomalias's Universal Dynamic Input Texture for Primehack.

<br>

## Open Emulator
Here you launch and configure each emulators settings, the option you choose will open that emulators GUI. For documentation on how to change the settings of each emulators settings please check the website of each emulator.

(Please note that most of the emulator interfaces where not designed with controller input in mind for handling the applications GUI, just the games. So you might need to use other inputs like the Steam Decks touchscreen or a mouse and key board to navigate properly).

From this entry you can run the emualtor itself such as:

- RetroArch
- Citra
- Dolphin
- Duckstation
- MelonDS
- PCSX2
- PPSSPP
- RPCS3
- XEMU
- Yuzu

<br>

## RetroDECK: Tools

### Tool: Move files
This option lets you choose the installation path of the RetroDECK folder that handles ROMS,Saves, BIOS etc... to a new location.
You get the following three options.

`Internal Storage` - Moves the folder to the internal storage. <br>
`SD CARD` - Moves the folder to the SD CARD <br>
`Custom Location` - Choose where you want the RetroDECK folder to be.<br>

<br>

### Tool: Compress games
This option enables you to compress disc based game image files `.gdi` `.iso` `.bin` `.cue` to the less space demanding `.chd` format.
You can choose either a single game or many.

<br>

### Install: RetroDECK SD Controller Profile
This option installs the Steam Deck controller profile to RetroDECK it also resets all emulators configurations to input the correct bindings.

<br>

### Install: PS3 Firmware
This option downloads and installs the latest PS3 firmware. A the end of the download, RPCS3 will open requesting the user to install it. Just press OK.

<br>

### RetroDECK: Change update settings (cooker only)
This option lets you turn on or off automatic updates on launch.

<br>

## RetroDECK: Troubleshooting
Various troubleshooting options.


### Backup: RetroDECK Userdata
Creates backups of the user data folders

<br>

### Check & Verify: Multi-file structure
Verifies to the structure of multi disc/file games that uses `.m3u` files.

<br>

### Check & Verify: BIOS
Shows a detailed BIOS list of missing and current BIOS.

<br>

### RetroDECK: Reset
The reset menu resets various features

<br>

#### Reset Specific Emulator
Opens up a menu where you can reset a specific emulator

<br>

#### Reset All Emulators
Resets all the emulators at once

<br>

#### Reset RetroDECK
Resets the entirety of RetroDECK.<br>
`⚠️ WARNING! BACK UP YOUR DATA BEFORE RUNNING THIS! ⚠️`

<br>

## RetroDECK: About
This menu contains information about RetroDECK

### Version history
Displays the changelogs

<br>

### Credits
Displays the credits
