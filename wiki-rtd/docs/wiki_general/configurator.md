# The RetroDECK Configurator

The `RetroDECK Configurator` is a unique multi-use toolbox that exists within RetroDECK to manage/configure/change/reset/edit many aspect of the application and built around the `RetroDECK Framework`.

The `RetroDECK Configurator` can be called:

* By the main menu inside the ES-DE interface (`START` > `RetroDECK Configurator``)
* From the `RetroDECK Configurator.desktop` desktop shortcut, available in your application menu.
* From CLI by calling `flatpak run net.retrodeck.retrodeck --configurator`

What follows are the commands you can use inside the Configurator (more commands will be added during development).

## Presets & Settings

In this menu you can set various presets.

### Global: Presets & Settings
In this menu you will find presets and settings that span over multiple emulators.

#### RetroAchivements: Login
Login to RetroAchievements in all supported emulators and cores.

#### RetroAchivements: Logut
Logut from RetroAchievements in all supported emulators and cores.

#### RetroAchivements: Hardcore Mode
Enables `Hardcore Mode` from RetroAchievements in all supported emulators and cores.

#### Widescreen: Enable/Disable
Enables or disable Widescreen in all supported emulators and cores.

#### Swap A/B and X/Y: Enable/Disable
Swaps `A/B` `X/Y` in all supported emulators and cores.

#### Ask to Exit prompt: Enable/Disable
Enables or disables ask to exit prompts in all supported emulators and cores.
Note: If you disable this, the emulators will directly exit.

### RetroArch: Presets & Settings
In this menu you will find presets and settings for RetroArch.

#### Borders: Enable/Disable

Enable / Disable borders across the RetroArch cores you choose.

#### Rewind: Enable/Disable

Enable / Disable rewind across all  of RetroArch (this may impact performance on some more demanding systems).

### Wii & Gamecube: Presets & Settings
In this menu you will find presets and settings for Dolphin and Primehack.

#### Dolphin Textures: Universal Dynamic Input
Enable / Disable Venomalias's Universal Dynamic Input Texture for Dolphin.

#### Primehack Textures: Universal Dynamic Input
Enable / Disable Venomalias's Universal Dynamic Input Texture for Primehack.

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

## RetroDECK: Tools

### Tool: Move files

This option lets you choose the installation path of the RetroDECK folder that handles ROMS,Saves, BIOS etc... to a new location.
You get the following three options.

`Internal Storage` - Moves the folder to the internal storage. <br>
`SD CARD` - Moves the folder to the SD CARD <br>
`Custom Location` - Choose where you want the RetroDECK folder to be.<br>

### Tool: Compress games
This option enables you to compress disc based game image files `.gdi` `.iso` `.bin` `.cue` to the less space demanding `.chd` format.
You can choose either a single game or many.

### Install: RetroDECK SD Controller Profile
This option installs the Steam Deck controller profile to RetroDECK it also resets all emulators configurations to input the correct bindings.

### Install: PS3 Firmware
This option downloads and installs the latest PS3 firmware. A the end of the download, RPCS3 will open requesting the user to install it. Just press OK.

### RetroDECK: Change update settings (cooker only)
This option lets you turn on or off automatic updates on launch.

## RetroDECK: Troubleshooting

### Backup: RetroDECK Userdata
Creates backups of the user data folders

### Check & Verify: Multi-file structure
Verifies to the structure of multi disc/file games that uses `.m3u` files.

### Check & Verify: BIOS
Shows a detailed BIOS list of missing and current BIOS.

### RetroDECK: Reset
The reset menu resets various features

#### Reset Specific Emulator
Opens up a menu where you can reset a specific emulator

#### Reset All Emulators
Resets all the emulators at once

#### Reset RetroDECK
Resets the entirety of RetroDECK.
> ⚠️ WARNING! BACK UP YOUR DATA BEFORE RUNNING THIS! ⚠️

## RetroDECK: About
This menu contains information about RetroDECK

### Version history
Displays the changelogs

### Credits
Displays the credits
