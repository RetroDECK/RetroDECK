# RetroDECK 0.7.1b

### Release Date: 2023-08-22

## Information:
- Steam Deck users update RetroDECK from `Discover` in Desktop Mode.
- Don't forget to reapply the latest controller layout: Go into the `Templates` tab and reapply the new profile ending with 0.7.1b (there is no need to reinstall the entire layout from the Configurator).
  

## Bugfixes & other changes: 
- Fixed an issue to make sure the RD controller layout file at update with each RD update.
- Fixed an issue with PPSSPP that made `L` and `R` incorrectly bound.
- Fixed an issue in the Configurator that prevented the Yuzu preset for swapping A/B X/Y from working.
- Fixed an notification issues on the latest SteamOS Beta releases. 
- Fixed an rsync permissions issue in the RetroDECK Framework.  
- Updated Yuzu presets to handle new config syntax in the RetroDECK Framework.
- Changed auto-update to notification only, until permissions error can be worked out. 
- Added some new pixelart icons by ItzSelenux (pixelitos-icon-theme)


## Updates
- All Emulators and ES-DE have been updated

## Steam Deck - Global Controller Layout:
We have done some  changes based on community feedback

**Layout Changes:**
- `Select` is now a hotkey trigger while pressing it down, `L4` and `R4` are still triggers as well. 
- The RetroArch combo of `Select`  + `Start` = `Quit` now works on many SA-Emulators.
- `Open Menu` is removed from `Select`.
- `R5`  = `A` button (this allows for great Wii controls on the right touchpad and pressing down the R5 for A).
- `L5` = `B` button.

**Global hotkey changes:**
- `Open Menu` is on `Y`.
- `Increase Emulation Speed`  is on `Dpad-UP`.
- `Decrease Emulation Speed` is on `Dpad-Down`.
- `Fullscreen OFF` command is removed (as emulators have migrated to toggle).

## Known issues
- The built in auto-updater is not working (we are working on it). Discover is ok.
- Some emulators don't have hotkey support or have bugs affecting their hotkeys.


# RetroDECK v0.7.0b - Amazing Aozora 

### Release Date: 2023-06-16

## Read First – Important Changes!  

* `PCSX2-SA` latest updates are not compatible with old save states. Please make sure you do an in-game save to your virtual memory card before upgrading.  

* The following emulators have changed the defaults and now run the stand-alone version: `Dolphin`, `Citra`, `PPSSPP`. <br>
If you have saves states or just want to go back to the RetroArch version, you can always switch back by pressing: `Other Settings` – `Alternative Emulators` and set them back to the core versions.  

* If you decide to install the new `RetroDECK Controller Layout` for the Steam Deck (highly recommended), it will wipe your custom configurations and emulator settings. That’s because all the configs needs to be updated and changed to be compatible. <br>
The choice is yours (you can always install it later via the Configurator if you change your mind). 


## New Emulators 

- Wii U powered by CEMU 

- We had hopes to add MAME standalone as well but we had to push it towards a future update because of various issues. That's why there is a MAME submenu in the new radial menus.

 

## New General Features  

### New - Steam Deck Controller Layout 

Please read up on: https://github.com/XargonWan/RetroDECK/wiki/Steam-Deck%3A-Hotkeys-and-controls 
- All hotkeys for all emulators have been unified where possible. 

This Steam Deck Controller Layout features both 

- Radial input menus on the left touchpad. 
- Button bound hotkeys you can access by either holding R4 or L4.  

**Installation of the layout:**

**From an upgrade:**

A upgrade from a older version to 0.7b you will get a prompt during the upgrade process that asks you if you want to install the layout. If you choose to do this (highly recommended), it will reset your emulators custom configurations if you had them. 

**For everyone (upgrade or fresh install):**

After installation need to manually enable the config as under (you also need to do this for a new RetroDECK install): <br>
`Controller Settings` -> `Controller Layouts` -> `Templates` `RetroDECK: Official Layout` with a version number. 

**NOTE:**

Not all Emulators has hotkey support; some have partial support, some has none and some has a majority implemented.

**Known issues:**

PPSSPP has an issue with flatpak hotkeys currently on their github so we have mapped ESC `HK + R3` ( press the `Escape` key from the radial menu) to `Open PPSSPP Menu`. In this way you can shutdown, save and access PPSSPP functions from there. 
As soon as the issue is solved we will remap everything to the correct hotkeys.

### New -  RetroDECK system folders 

Handling modpacks and texture packs has never been easier! You can read more on the wiki! 

https://github.com/XargonWan/RetroDECK/wiki 

**New folder: Mods**

`retrodeck/mods/` Inside you will find easy to access mod folders for the following systems: Citra ,Dolphin, Primehack, Yuzu 
     

**New folder: Texture Packs** 

`retrodeck/texture_packs/` inside you will find easy to access texture pack folders for the following systems: Citra, Dolphin, Duckstation, PCSX2, PPSSPP, Primehack, RetroArch-Mesen, RetroArch-Mupen64Plus 
     

**New folder: Gamelists**

`retrodeck/gamelists` gamelists are now moved into  by default for ease of access and added security.  


## New - System features 

- The Configurator has a new home inside the ES-DE main menu and thus the tools menu has been removed.  
- The Configurator also has a .deskop icon for ease of access for both Steam Deck desktop mode and Linux Desktop users. 
- Added RetroDECK auto updates on launch, this can be disabled from the Configurator this works in Game Mode for the Steam Deck.  
     
## New RetroDECK Configurator features: 

- The Configurator has a new structure, with more menus and options.  
- The compression tool has been updated to allow for even more formats such as .zip in addition to the standard disc-based formats for certain systems.  
- The compression tool has been updated to have an even stronger verification before a compression job starts.  
- Added a global preset to swap A/B and X/Y in all supported emulators (aka N layout). 
- Added a global preset to enable/disable Widescreen in all supported emulators, globally or per core/emulator. 
- Added a global preset to enable/disable Ask-to-Exit prompts in all supported emulators. 
- Added a preset to enable/disable Pegasus and NyNy77 Borders for RetroArch, globally or per core. 
- Added an option to install Venomalia's Universial Dynamic Input Textures for Dolphin https://github.com/Venomalia/UniversalDynamicInput 
- Added an RetroDECK: About section  
- Added an option to install the RetroDECK Steam Deck controller profile 
- Added an “RetroDECK: Auto Updates” function that enables or disables auto updates on RetroDECK launch.  
- Added a Semi-automated RPCS3 firmware installer. 
- The Move Folder tool has been greatly expanded 
  - You can now move the entire folder or different folders as you choose. (WARNING! Please do not try to move the data to more exotic locations). 
- The basic BIOS checker has been removed.  
- The BIOS checker has been updated to look for over 120+ BIOS. 
- RetroAchivements Login: Now logs into all supported emulators/cores at once. 
- RetroAchivements Logout: Now logs out of all supported emulators/cores at once. 
- Added RetroAchivements: Hardcore Mode, that lets you toggle hardcore mode for supported emulators/cores with a logged in RetroAchivements account. 

## Updates 

- Updated ES-DE to the latest version. 
- Updated RetroArch and the cores to latest versions. 
- Updated all standalone emulators and to their latest versions. 


## Bugfixes & other changes: 

- Dolphin/Primehack Wii Mote controls have been redesigned for the Steam Deck to allow both for touch input or right radial as pointer and `R2` emulates the Wii Remote Shake needed for certain games. 
- Updated the RPCS3 to run better and with a better configuration. Read more on the wiki on how to install DLC and patches. 
- RPCS3 and Duckstations save files where in the wrong directory. They have been moved to fit the overall inside the RetroDECK Framework. If you have any issues, contact us on discord or add them on github.  
- We made a unique PICO-8 wrapper that makes it runs better in a flatpak environment. 
- Fixed an avcodec issue that caused some roms for certain emulators to break.  
- Changed the ES-DE progress bar color 
- Changed how Yuzu builds are handled and should allow for better Yuzu updates.  
- Added a low space warning on launch.  
- Various backend improvements and fixes. 
- Added the foss Capsimg BIOS for the Amiga RetroArch core. 
- Implemented ES-DE's experimental theme downloader. For fresh new installs we only now ship one theme: ArtBookNext (as all other themes can be downloaded from the interface). 

## Experimental features: 
You can enable the RetroDECK: Multi-user system and other things from CLI for testing purposes.  
Read more here on how to help us with testing: 

https://github.com/XargonWan/RetroDECK/wiki/How-can-I-help-with-testing%3F  

There is also a Q&A on the latest blog post: 

https://www.reddit.com/r/RetroDeck/comments/13x8dva/retrodeck_status_update_202306/ 

# RetroDECK v0.6.6b

### Release Date: 2023-04-26

### Information: 
This patch is a quick hotfix for ES-DE.


## Bug fixes and other changes:
- ES-DE had the wrong buildflag and pushed the update notification.
- Reverted to the Swanstation Core for RetroArch

# RetroDECK v0.6.5b

### Release Date: 2023-04-07

### Information: 
Just a quick hotfix for Yuzu (since some games where not working in 0.6.4b).
So we had to roll back to the latest working version.
Newer versions will be shipped with v0.7b

## Bug fixes and other changes:
- Rolled back to latest working Yuzu as some games had issues with the latest update.
- Slightly improved Yuzu performance by tweaking GPU options
- Fixed an issue where the default theme was not loaded 
- Removed unavailable emulators entries

# RetroDECK v0.6.4b

### Release Date: 2023-04-04

## New features - General:
- Updated to ES-DE 2.0
- Added the NSO Menu Interpreted theme
- Updated all included themes
- Updated the Emulators/RetroArch + cores

## Bug fixes and other changes:

- Fixed an audio issue in the Primehack configuration
- Various backend fixes

# RetroDECK v0.6.3b 

### Release Date: 2023-03-24

## New features - General:
- Added support support for multiple file compression via CLI.

## RetroDECK Configurator:
- Added support support for multiple file compression in the Configurator.
- Added safety y/n prompts to the reset functions. 
- Fixed some missing layout changes.
- Renamed "Reset All" to "Reset RetroDECK".
- Moved the configurator into the RO partition for futher enhancements.

## Bug fixes and other changes:
- Fixed a bug in the compression tool with certain filenames with spaces.
- Fixed a bug where some folders were recursively symlinked.
- Fixed a bug where some emulator configs were not correctly deployed. 
- Fixed a manifest bug that caused a conflict between Dolphin and Primehack in certain scenarios.
- Fixed the Configurator BIOS tool looking in the wrong location (Thanks sofauxboho for the report!)
- Implemented new configurations for Yuzu and Citra thanks to the  big config file changes in the latest emulator updates in both emulators.
- Removed some leftover files from Legacy PCSX2.
- Removed the legacy "Reset Tools" command from Configurator and CLI.

# RetroDECK v0.6.2b 

### Release Date: 2023-03-15

## New features - General:
- Persistent configurations when updating RetroDECK <br> (This means your custom configurations should be saved across future versions. We also laid groundwork for dynamic persistent configurations, more on that in a future update. This is the reason why it has taken quite long to fix this). 
- Added Primehack controller profiles for both Xbox and Nintendo button layouts
- Added a warning when running RetroDECK in desktop mode that not all control inputs will work properly. It also comes with a "Never show again" button.
- Added CLI for CHD compression (chdman) of single games
- Reworked CLI commands and added safety "y/n" confirmations for the reset arguments.

## New features - RetroDECK Configurator:
- The RetroDECK Configurator "toolbox" has a new structure for more easy access to various tools
- The power user prompt has a "Never show again" button
- Added tool to do CHD compression (chdman) of single games (multi-game batch compression coming in a future update)
- Added tool to check for common BIOS files
- Added tool to check for common multi-file game structure issues

## Bug fixes and other changes:
- Fixed Primehack initial configuration as it was broken (will automatically reset the emulator just this once)
- Fixed Duckstation initial configuration as it was broken (will require user-performed reset just this once)
- Fixed Pico-8 initial configuration as it was broken. 
- Fixed Pico-8 dual bios folders. The program files `pico8_dyn`,`pico8.dat` and `pico8` have to be manually moved to the correct location`~/retrodeck/bios/pico-8/`. The old `~/retrodeck/bios/pico8/` is renamed `~/retrodeck/bios/pico8_olddata/` to avoid confusion on where to put files. After the files have moved the `pico8_olddata `folder can be deleted. 
- Fixed a bug that made the Dolphin RetroArch core not working properly (the standalone version of Dolphin always worked and is the default)
- Various backend fixes

## Updates:
- Updated all Emulators, RetroArch and libreretro cores. <br> (PLEASE NOTE! ES-DE was not updated to version 2.0, this will be done in the next major version of RetroDECK as we need more time to work on the new theme format). 

# RetroDECK v0.6.1b

### Release Date: 2023-02-21
 
## New features:
* Added CLI option to run Configurator directly
* Added "--configure" option to RetroDECK CLI

## Updates: 
* Yuzu updated to mainline-1301        

## Fixes & adjustments:
* Adjusted Configuration window sizes
* Temporarily removed Ryjuinx as it was broken and had too many issues (will be added back in a future patch). 
* Removed deprecated emulators from Configurator (eg. Legacy PCSX2)
* Made improvements to file-moving code
* Fixed Primehack preconfiguration and Configurator entry
* Fixed a bug where the hidden files were not moved during the directory preparation
* Fixed a bug where the symlinks were recursively placed inside the prepeared paths
* Fixed issue with missing symlink after RetroDECK base directory was moved somewhere else
* Fixed Duckstation preconfiguration

# RetroDECK v0.6.0b

### Release Date: 2022-12-27

## New Emulators
* Primehack
* Ryjuinx (Disabled in 0.6.2b)  

## New Features
* Merged all tools into single Configurator
* The Configurator can now move the whole retrodeck folder eslewhere (not just the ROMs one)
* The Configurator can now reset a single emulator, all RetroArch or all Standaloned configs (so there is no need to di it via CLI anymore
* The first install is now asking where to place the whole retrodeck folder instead of requesting the location of the ROMs folder only.

## RetroArch
* Updated RetroArch to version [v1.14.0](https://www.libretro.com/index.php/retroarch-1-14-0-release/)
* Updated Cores
* Updated Cheat_db

## Updated standalone emulators
These emulators are updated to the latest version available on 31/10/2022.
* Updated PPSSPP
* Updated Yuzu
* Updated Citra
* Updated PCSX2-QT
* Updated Dolphin 
* Updated Xemu 
* Updated RPCS3 
* Updated Duckstation

## Fixes
* PCSX2-QT is now looking for saves in the correct directory `~/retrodeck/saves/ps2/memcards` and not in `~/retrodeck/saves/ps2/pcsx2/memcards`

# RetroDECK v0.5.3b

### Release Date: 2022-10-28

## Bug fixes in v0.5.3b

* Fixed inaccessible RetroArch shaders folder
* Fixed PSP saving issue when using RetroArch core
* Fixed ROM visibility for Dolphin when running standalone, which should address ability to use AR/Gecko codes
* Changed default RPCS3 launch method to fix games not starting properly
* Fixed PCSX2 (legacy) autosave loading issue
* (Hopefully) Fixed RetroAchievements login on PCSX2-QT

## Changes in 0.5.3b
* Made Citra standalone the default 3DS emulator

## Additions in 0.5.3b
* Added Citra SA sysdata folder to RetroDECK BIOS folder
* Added Yuzu save folders to RetroDECK saves folder
* A progress window during emulator initialization where it can look like RetroDECK has crashed

# RetroDECK v0.5.2b

### Release Date: 2022-10-14

## Bug fixes in 0.5.2b

* Fixed a bug where the Citra save folder was duplicated
* Fixed a bug where scraped videos would not be played correctly for certain systems
* Fixed the Rewind Tool

# RetroDECK v0.5.1b

### Release Date: 2022-10-13

## Bug fixes in 0.5.1b

* Fixed an issue with Yuzu not being compiled correctly in 0.5.0b

# RetroDECK v0.5.0b 

### Release Date: 2022-10-12

## Important: New save folder structure and migration in 0.5.0b

### General information


[I see ~ refereed in documentation and examples, what does it mean?](https://github.com/XargonWan/RetroDECK/wiki/FAQs:-Frequently-asked-questions#i-see--refereed-in-documentation-and-examples-what-does-it-mean)

**Saves = game saves and save states**<br>
The word "saves" is used to reference both save files and save state files in this wiki article. Both files are treated in the same manner, the only difference is that saves are located at. 

**PLEASE BE PATIENT:** <br>
The migration of the saves only needs to be done once. <br>
Depending on how large roms library you have, this migration can take several minutes.<br>
If you have an extremely large roms library (+5.000 roms) this process can take over an hour. 

### Why are you changing the save folder structure?

In the long run, it is about the safety of your saves and we feel it's better to tackle this now during the beta period then later. 

By default, RetroArch (which handles emulation of most older systems) puts all your saves together in one folder. <br>
This is normally not an issue, but what you if you want to play the same game but different versions of it across multiple systems? <br>
RetroArch has no way of telling the difference between a save for `Mortal Kombat 3` on the Sega Genesis and on the Super Nintendo when the saves are all bundled together. RetroDECK is moving to a save storage structure where every save file is in a per system sub-folder inside of the `~/retrodeck/saves/` for game saves or `~/retrodeck/states/` for save states.

### How saves are stored in RetroDECK pre 0.5.0b:

_Example: Structure of the `~/retrodeck/saves/` folder_
    
    ~/retrodeck/saves/Final Fantasy 3.save

    ~/retrodeck/saves/Sonic the Hedgehog.save

_Example: Structure of the `~/retrodeck/states/` folder_
    
    ~/retrodeck/saves/Final Fantasy VI.savestate

    ~/retrodeck/saves/Sonic the Hedgehog 2.savestate


### How saves are stored in RetroDECK post 0.5.0b:

_Example: Structure of the `~/retrodeck/saves/` folder and with new sub-folders_

    ~/retrodeck/saves/nes/Super Mario Bros. 3.save

    ~/retrodeck/saves/genesis/Sonic the Hedgehog.save

_Example: Structure of the `~/retrodeck/states/` folder_
    
    ~/retrodeck/states/snes/Final Fantasy VI.savestate

    ~/retrodeck/states/genesis/Sonic the Hedgehog 2.savestate

Since RetroArch will be looking for your saves in new locations, RetroDECK will do its best to sort your saves into the new structure automatically, so you likely won't need to do anything except enjoy knowing your saves are safer than ever.

### How will it work?

* The fist time you run RetroDECK after upgrading from a previews version to 0.5.0b a new dialog prompt will appear letting you that the migration process will start after pressing `OK`.

* The migration process matches up all of your saves with all of your ROMs. 

* Once a match is found, the save is moved to where the sub-folder it needs to be in. 

* At the end of the process RetroDECK will let you know if any saves could not be sorted automatically.

* **NOTE:** Only saves created by RetroArch need to be sorted, standalone emulators such as Yuzu and Citra already use their own folder structure and don't need to go through this process.

* **NOTE:** If a match can't be found (for instance if you have a save for Mortal Kombat 3 and have both the SNES and Genesis editions in your ROM library) the save will be left alone and will need to be sorted manually, since only you will know for sure what system you were playing that game on. 

### Where will my saves be moved to? 

The saves will still be in the `~/retrodeck/saves` folder, but will also be moved into a new folder that matches what system the associated game is on.

 _Example: Game save - The Legend of Zelda on the NES_<br>

`~/retrodeck/saves/The Legend of Zelda.save`

 will be moved to

 `~/retrodeck/saves/nes/The Legend of Zelda.save`

 _Example 2: Save state - Super Mario Bros 3 on the NES_<br>

`~/retrodeck/states/Super Mario Bros 3.savestate`

 will be moved to

 `~/retrodeck/states/nes/Super Mario Bros 3.savestate`

### Why could not all saves be moved automatically? 

If you have a large ROM library, it is likely you will have multiple versions of the same game across multiple systems.

RetroArch creates save files that have the same name as the original ROM file. If there are multiple ROM files with the same name as a save, there is no way to tell which system the save belongs to.

In the interest of ultimate safety for your saves, we only sort files we can be sure of. It is unfortunate that some saves may need to be sorted manually for some users, but this is a one time process that will keep your saves safer in the long run.

### How do I move them manually? 

The saves can be moved like any other file, using the Dolphin file manager included in the Steam Deck desktop mode to the corresponding sub-folder inside `/retrodeck/saves/(system sub-folder)`. 

### Where can I find saves that could not be moved?

If you see a message after the migration process saying some of your saves could not be sorted automatically, they will be found where they have always been, in `~/retrodeck/saves` or `~/retrodeck/states`. 

In the `~/retrodeck` folder there will also be a file called `manual_sort_needed.log` listing every save that could not be sorted automatically with a reason it was not moved. In order to be used again, these files will need to be moved into the folder matching the name of the system that the game the save belongs to runs on.

For example, this save file could not be sorted automatically, because there are multiple ROMs in the library with the same name.

**Example: Game saves** <br
A game save from Mortal Kombat 3: `saves/Mortal Kombat 3.save`

Two roms with the same name exist, one for the SNES and one for the Genesis/Megadrive:

    ~/retrodeck/roms/genesis/Mortal Kombat 3.rom

    ~/retrodeck/roms/snes/Mortal Kombat 3.rom

If you have playing on the SNES, the save will need to be moved to:

`/retrodeck/saves/snes/Mortal Kombat 3.save`

If you have been playing on the Genesis/Megadrive, the save will need to be moved to:

`/retrodeck/saves/genesis/Mortal Kombat 3.save`

**Example 2: Save states** <br
A save state from Street Fighter 2: `states/Street Fighter 2.savestate`

Two roms with the same name exist, one for the SNES and one for the Genesis/Megadrive:

    ~/retrodeck/roms/genesis/Street Fighter 2.rom

    ~/retrodeck/roms/snes/Street Fighter 2.rom

If you have playing on the SNES, the save will need to be moved to:

`/retrodeck/states/snes/Street Fighter 2.savestate`

If you have been playing on the Genesis/Megadrive, the save will need to be moved to:

`/retrodeck/states/genesis/Street Fighter 2.savestate`


## Major features in 0.5.0b

* New save sub-folders structure.  
* Implemented the first steps towards a universal Emulator Configuration Tool in the TOOLS menu.
* Ability to log into your RetroAchievements account under the TOOLS menu.
* Added several free assets/fonts for RetroArch, PPSSPP, XEMU and BlueMSX
* Added a new DEFAULT Emulator for the PS2: PCSX2-QT (the former PCSX2 default emulator is now called "PCSX2 (Legacy)").
* Changed the DEFAULT Emulator for the PSX: Swanstation (Libretro) Core
* Added a new Standalone Emulator for the PSX: Duckstation.
* Enhanced the XEMU (XBOX) experience 
* New logo made by Pixelguin
* Two new themes added, made by RetroDECKs [anthonycaccese](https://github.com/anthonycaccese):
>
* New theme 1: [Alekfull-NX-Light](https://github.com/anthonycaccese/alekfull-nx-retropie/tree/retro-deck-esde-1.x-light) for ES-DE <br(Based on the original Alekfull-NX for Batrocera made by [Fagnerpc](https://github.com/fagnerpc)).
![rd-theme-AlekfullNXLight-GamelistView](https://user-images.githubusercontent.com/1454947/193457762-4d997ca3-d77c-4993-81bb-0c1a78f240a1.jpeg) 
![rd-theme-AlekfullNXLight-SystemView](https://user-images.githubusercontent.com/1454947/193457765-e56875cd-a34d-4675-8267-56d04d4d1c32.jpeg)
* New theme 2: [Retrofix-Revisited](https://github.com/anthonycaccese/retrofix-revisited-retropie) for ES-DE <br(Based on the original Retrofix theme for Batrocera made by [20GotoTen](https://github.com/20GotoTen)). <br>
![rd-theme-RetrofixRevisited-GamelistView](https://user-images.githubusercontent.com/1454947/193457594-b803546b-36eb-4e71-9eca-bfee1d81ba36.jpeg) 
![rd-theme-RetrofixRevisited-SystemView](https://user-images.githubusercontent.com/1454947/193457596-05dc4316-9f2a-41ae-aa27-9609c680ec5a.jpeg) 

## Updates & minor additions in 0.5.0b

* New variables system: now some variables such as game folder location are saved in /var/config/retrodeck/retrodeck.cfg.
* Rewritten build and publication workflows
* Updated ES-DE from 1.2.4 to 1.2.6 <br>(Please note that not all the supported emulators in ES-DE are included in RetroDECK at this moment)<br>
For the full ES-DE patch notes follow these links:<br>
[1.2.5 Patch Notes](https://gitlab.com/es-de/emulationstation-de/-/blob/master/CHANGELOG.md#version-125)<br>
[1.2.6 Patch Notes](https://gitlab.com/es-de/emulationstation-de/-/blob/master/CHANGELOG.md#version-126)
* Updated RetroArch, updated all cores and added new cores from 1.10.2 to 1.11.1<br>
[1.10.3 Patch Notes](https://www.libretro.com/index.php/retroarch-1-10-3-release/)<br>
[1.11.1 Patch Notes](https://www.libretro.com/index.php/retroarch-1-11-0-release/)<br>
* Updated all the standalone emulators to their latest releases
* Updated all included themes to their latest version.

## Bug fixes in 0.5.0b

* Removed the unavailable emulators from the ES-DE interface to avoid confusion.
* Solved an issue where Dolphin (Standalone) was not saving in the intended directories.
* Various smaller bug fixes, for a more detailed list check the [issues list](https://github.com/XargonWan/RetroDECK/issues?q=is%3Aissue+milestone%3A0.5.0b+)