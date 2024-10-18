# The RetroDECK Configurator

**Please note that we are going to rebuild the Configurator into a controller friendly GODOT application and that the current version is not the final design.**

<img src="../../wiki_images/graphics/configurator/configurator.png" width="500">

The `RetroDECK Configurator` is a unique multi-use utility that exists within RetroDECK to manage many aspects of the application and exposes functions from the `RetroDECK Framework` to the user.

The `RetroDECK Configurator` can be opened from:

- The main menu inside the ES-DE interface and choose `RetroDECK Configurator`.

<img src="../../wiki_images/graphics/configurator/configurator-esde.png" width="500">

* From the `RetroDECK Configurator.desktop` desktop shortcut, available in your application menu.

<img src="../../wiki_images/graphics/configurator/configurator-kde.png" width="500">

* From CLI by calling `flatpak run net.retrodeck.retrodeck --configurator`

What follows are the commands you can use inside the Configurator (more commands will be added during development).

## Presets & Settings
In this menu you can set various presets.

#### Widescreen: Enable/Disable
Enables or disables Widescreen in all supported emulators and cores.

#### Ask to Exit prompt: Enable/Disable
Enables or disables ask to exit prompts in all supported emulators and cores.
Note: If you disable this, the emulators will directly exit.

### Global: Presets & Settings
In this menu you will find presets and settings that span over multiple emulators.

#### RetroAchivements: Login
Login to RetroAchievements in all supported emulators and cores.

#### RetroAchivements: Logut
Logut from RetroAchievements in all supported emulators and cores.

#### RetroAchivements: Hardcore Mode
Enables `Hardcore Mode` from RetroAchievements in all supported emulators and cores.

#### Swap A/B and X/Y: Enable/Disable
Swaps `A/B` `X/Y` in supported emulators and cores.

#### Quick Resume: Enable/Disable
Enables `Quick Resume` aka  `Auto Save` + `Auto Load` on exit in supported emulators and cores.

### RetroArch: Presets & Settings
In this menu you will find presets and settings for RetroArch.

#### Borders: Enable/Disable
Enable / Disable borders across the RetroArch cores you choose.

#### Rewind: Enable/Disable
Enable / Disable rewind across all of RetroArch (this may impact performance on some more demanding systems).

### Wii & Gamecube: Presets & Settings
In this menu you will find presets and settings for Dolphin and Primehack.



#### Dolphin Textures: Universal Dynamic Input
Enable / Disable Venomalias's Universal Dynamic Input Texture for Dolphin.



#### Primehack Textures: Universal Dynamic Input
Enable / Disable Venomalias's Universal Dynamic Input Texture for Primehack.



## Open Emulator

Here you launch and configure each emulator's settings, the option you choose will open that emulators GUI. For documentation on how to change the settings of each emulator's settings please check the website of each emulator.

(Please note that most of the emulator interfaces where not designed with controller input in mind for handling the applications GUI, just the games. You might need to use other inputs like the Steam Decks touchscreen or a mouse and keyboard to navigate properly).


## RetroDECK: Tools


### Tool: Remove empty ROM folders

This tool removes all the roms folders under retrodeck/roms/ that are empty to only leave those that are populated with content.

### Tool: Rebuild all ROM folders

This tool rebuilds rom folders you have accidentally removed or used the `Remove empty ROM folders` tool.

### Tool: Move files
This option lets you choose the installation path of the RetroDECK folder that handles ROMS, Saves, BIOS, etc... to a new location.
You get the following three options.

`Internal Storage` - Moves the folder to the internal storage.
`SD CARD` - Moves the folder to the SD CARD
`Custom Location` - Choose where you want the RetroDECK folder to be.



### Tool: Compress games
This option enables you to compress disc-based game image files `.gdi` `.iso` `.bin` `.cue` to the less space demanding `.chd` format.
You can choose either a single game or many.



### Install: RetroDECK SD Controller Profile
This option installs the Steam controller profiles that RetroDECK into Steam.


### Install: PS3 Firmware
This option downloads and installs the latest PS3 firmware. At the end of the download, RPCS3 will open requesting the user to install it (just press OK).



### RetroDECK: Change update settings (cooker only)
This option lets you turn on or off automatic updates on launch.



## RetroDECK: Troubleshooting
Various troubleshooting options.


### Backup: RetroDECK Userdata
Creates backups of the user data folders



### Check & Verify: Multi-file structure
Verifies the structure of multi disc/file games that uses `.m3u` files.



### Check & Verify: BIOS
Shows a detailed BIOS list of missing and current BIOS.



### RetroDECK: Reset
The reset menu resets various features



#### Reset Specific Emulator
Opens a menu where you can reset a specific emulator


#### Reset All Emulators
Resets all the emulators at once



#### Reset RetroDECK
Resets the entirety of RetroDECK.
`⚠️ WARNING! BACK UP YOUR DATA BEFORE RUNNING THIS! ⚠️`



## RetroDECK: About
This menu contains information about RetroDECK

### Version history
Displays the changelogs



### Credits
Displays the credits
