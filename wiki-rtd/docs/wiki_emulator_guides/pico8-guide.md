# Guide: PICO-8

<img src="../../wiki_images/logos//pico-8-logo.png">

WIP

## Where to put the games
PICO-8 games should be put under the `retrodeck/roms/pico8/` directory.

## ES-DE Guide

**This needs to be rewritten**

PICO-8 Fantasy Console is a game engine developed by Lexaloffle Games that you need to buy a license to use. Doing so will provide you with download links to releases for Linux, macOS and Windows. Make sure to use the 64-bit release as the 32-bit release reportedly has some technical issues. On macOS and Windows the installation is straightforward, but on Linux you need to place PICO-8 in a location recognized by ES-DE. See the Using manually downloaded emulators on Linux section of this guide for more details.
After the emulator has been installed you are ready to add some games. There are two ways to play games using PICO-8, either to add them to ES-DE as for any other system, or using the built-in Splore tool to explore and run games all through the PICO-8 user interface.
For the first approach you can download games from the PICO-8 forum and these are quite uniquely distributed as .png images. You just download these and place them inside the ~/ROMs/pico8 directory, for example:

- /ROMs/pico8/c_e_l_e_s_t_e-0.p8.png
- /ROMs/pico8/xzero-3.p8.png

After this you just launch them like any regular game. You can also scrape many of these games using ScreenScraper, but you will need to refine the game names in most instances since most have filenames that the scraper service won't recognize. It's therefore recommended to run the scraper in interactive mode for these games or to scrape them one by one from the metadata editor.
The second alternative for playing PICO-8 games is to run Splore to browse and launch games from inside the game engine user interface. To do this, first add a dummy game file to the ROMs/pico8 directory. It can be named anything but splore.png is recommended. The file content doesn't matter, it can even be an empty file. Following this, change to the alternative emulator PICO-8 Splore (Standalone) for this specific entry using the metadata editor. If you now launch the file, you will be brought straight to the Splore browser inside PICO-8.
This is what the complete setup could look like:

- /ROMs/pico8/c_e_l_e_s_t_e-0.p8.png
- /ROMs/pico8/splore.png
- /ROMs/pico8/xzero-3.p8.png
