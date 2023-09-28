# Getting started 

This is a guide on how to get started with RetroDECK

# Step 0: Prerequisites

## What do I need?
You need to meet the following prerequisites before you start following this guide:

* You need to have a device to install RetroDECK on (we currently only support the Steam Deck).
* Read up on the FAQs pages: <br>
[Do you include any games, firmware or BIOS?](https://github.com/XargonWan/RetroDECK/wiki/FAQs:-Frequently-asked-questions#do-you-include-any-games-firmware-or-bios)<br>
[Where can I get them?](https://github.com/XargonWan/RetroDECK/wiki/FAQs:-Frequently-asked-questions#can-you-at-least-point-me-towards-where-i-can-get-them)<br>
[What does ~ mean?](https://github.com/XargonWan/RetroDECK/wiki/FAQs:-Frequently-asked-questions#i-see--refereed-in-documentation-and-examples-what-does-it-mean)
* Have related BIOS & Firmware ready
* Have backup rom files of the games you want to play ready

# Step 1: Installation & Configuration
Only install RetroDECK from the official channels via flathub! 

## Steam Deck - Installation<br>
Read and follow the:

* [Installation guide for the Steam Deck](https://github.com/XargonWan/RetroDECK/wiki/Steam-Deck:-Installation-and-updates)<br>

## Linux Desktop - Installation<br>

(more information later)


## Other SteamOS devices - Installation<br>

(more information later)

# Step 2: BIOS & Firmware

**NOTE:** On the Steam Deck this step needs to be done in Desktop Mode

## Information
Read up on [BIOS & Firmware](https://github.com/XargonWan/RetroDECK/wiki/BIOS-and-Firmware)

* The BIOS & Firmware files go into the `~/retrodeck/bios/` directory <br>


**Example:**<br>
You have a BIOS for the PSX called `exampleBIOSPSX.bin`, you just put that file into the `~/retrodeck/bios/` folder.

# Step 3: ROMs 

**NOTE:** On the Steam Deck this step needs to be done in Desktop Mode

## On ROMs

Rom files needs to be put in their corresponding system directory inside the `roms` folder.<br>
Note that the `roms` folder location can be different depending on where you choose to put it during the installation process. The following options are available during the installation:

### **Choice: Internal**<br>
If during the installation of RetroDECK you choose the Internal option for the roms folder:<br>
The roms folder is:`~/retrodeck/roms/` 

### **Choice: SDCard**<br>
If during the installation of RetroDECK you choose the SDCard option for the roms folder:<br>
The roms folder is: `<sdcard>/retrodeck/roms/`<br>

(Please note that the `<sdcard>` is an example and not called so inside your Linux/SteamOS system but rather your unique per SDCard ID number).<br>


## Let's get started on ROMs:

Read up on [Emulators: Folders & File extensions](https://github.com/XargonWan/RetroDECK/wiki/Emulators:-Folders-&-File-extensions) to see what folder each system has. 
* Put the corresponding roms inside the corresponding system folder

**Example:**<br>
You have an example NES game called `ExampleNESGame.nes` <br>
You have to put that game into the `/retrodeck/roms/nes` folder.

# Step 4: Playing the ROMs

## Steam Deck - Gamemode
Return to gamemode on the Steam Deck and start up RetroDECK. Now the systems you put rom files for should be shown and be able to be played. 

**Example:**<br>
The NES column should now be shown with our `ExampleNESGame.nes` from `Step 3`

# Step 5: Making the games "pretty" with videos, images and art.

Do the following:
1. Make an account on https://www.screenscraper.fr/
2. Read up on scraping on the [ES-DE Guide](https://github.com/XargonWan/RetroDECK/wiki/EmulationStation-DE:-User-Guide#scraping-and-editing-roms-metadata-images-etc)
3. Login to your screenscraper account inside RetroDECK and start scraping. 
4. Look at your nice pretty games.

Also read:
* [I got some weird error message about quota after scraping in a foreign language from screenscraper.fr](https://github.com/XargonWan/RetroDECK/wiki/FAQs:-Frequently-asked-questions#i-got-some-weird-error-message-about-quota-after-scraping-in-a-foreign-language-from-screenscraperfr)
* [My system storage ran out after scraping!](https://github.com/XargonWan/RetroDECK/wiki/FAQs:-Frequently-asked-questions#my-system-storage-ran-out-after-scraping) 

# Step 6: Themes 
RetroDECK comes with several themes built in for the ES-DE interface.

## How to switch between themes?
* On the Steam Deck: you can switch between them by pressing the `☰` button to open the menu and then navigate to `UI Settings > Theme Set` to select the theme you want to use. 

## How to add more themes?
[More information on themes and how to add more](https://github.com/XargonWan/RetroDECK/wiki/EmulationStation-DE:-Themes)
