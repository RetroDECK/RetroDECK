# Getting started

This is a guide on how to get started with RetroDECK

## Step 0: Prerequisites

### What do I need?
You need to meet the following prerequisites before you start following this guide:

* You need to have a device to install RetroDECK on.
* Have related BIOS & Firmware ready
* Have game backups of various formats ready that you want to play

## Step 1: Installation & Configuration
Only install RetroDECK from the official channels via flathub!

### Steam Deck - Installation<br>
Read and follow the following guide

[Steam Deck - Installation and Updates](../wiki_devices/steamdeck/steamdeck-start.md)

### Linux Desktop - Installation<br>
Read and follow the:

[Linux Desktop - Installation and Updates](../wiki_devices/linux_desktop/linux-install.md)


### Other SteamOS / Linux gaming devices - Installation<br>

(more information later)

## Step 2: BIOS & Firmware

**NOTE:** On the Steam Deck this step needs to be done in Desktop Mode

### Information
Read up on [Manage your BIOS/Firmware](../wiki_howto_faq/bios-firmware.md)

* The BIOS & Firmware files go into the `~/retrodeck/bios/` directory <br>


**Example:**<br>
You have a BIOS for the PSX called `exampleBIOSPSX.bin`, you just put that file into the `~/retrodeck/bios/` folder.

## Step 3: ROMs

**NOTE:** On the Steam Deck this step needs to be done in Desktop Mode

### On ROMs

Rom files needs to be put in their corresponding system directory inside the `roms` folder.<br>
Note that the `roms` folder location can be different depending on where you choose to put it during the installation process. The following options are available during the installation:

#### **Choice: Internal**<br>
If during the installation of RetroDECK you choose the Internal option for the roms folder:<br>
The roms folder is:`~/retrodeck/roms/`

#### **Choice: SDCard**<br>
If during the installation of RetroDECK you choose the SDCard option for the roms folder:<br>
The roms folder is: `<sdcard>/retrodeck/roms/`<br>

(Please note that the `<sdcard>` is an example and not called so inside your Linux/SteamOS system but rather your unique per SDCard ID number).<br>

#### **Choice: Custom**<br>
If during the installation of RetroDECK you choose the Custom option for the roms folder:<br>
The roms folder where ever you choose.


### Let's get started on ROMs:

Read up on [ES-DE Folders and Files](../wiki_emulationStation_de/esde-folders-files.md) to see what folder each system has or read the readme file in each systems folder under `~/retrodeck/roms/`

* Put the corresponding roms inside the corresponding system folder

**Example:**<br>
You have an example NES game called `ExampleNESGame.nes` <br>
You have to put that game into the `/retrodeck/roms/nes` folder.

## Step 4: Playing the Games

### Steam Deck - Gamemode
Return to gamemode on the Steam Deck and start up RetroDECK. Now the systems you put rom files for should be shown and be able to be played.

**Example:**<br>
The NES column should now be shown with our `ExampleNESGame.nes` from `Step 3`

### Linux Desktop
Start up RetroDECK from Steam. Now the systems you put rom files for should be shown and be able to be played.

**Example:**<br>
The NES column should now be shown with our `ExampleNESGame.nes` from `Step 3`

## Step 5: Making the games "pretty" with videos, images and art.

Do the following:

1. Make an account on [Screenscraper](https://www.screenscraper.fr/)
2. Read up on scraping and the various settings that exist for it in the [ES-DE User Guide](../wiki_emulationStation_de/esde-guide.md)
3. Login to your screenscraper account inside RetroDECK.
4. Setup the scraping how you want it.
5. Start scraping.
6. Look at your nice pretty games.

## Step 6: EmulationStation-DE Themes
You can download more themes for ES-DE's frontend with the built in theme downloader you can find it in:

`UI Settings > Theme Downloader`

Switch between them and in:

`UI Settings > Theme Set`

