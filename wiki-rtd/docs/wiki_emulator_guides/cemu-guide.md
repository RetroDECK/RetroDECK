# Guide: CEMU

<img src="../../wiki_images/logos/cemu-logo.png" width="150">

WIP

## Where to put the games
WiiU games should be put under the `retrodeck/roms/wiiu/` directory.

## ES-DE Guide

**This needs to be rewritten**

The .wua archive format is the preferred method to use for Wii U games, but the method of using unpacked games is also documented here for reference.
.wud and .wux files are supported as well, but these two formats are not discussed here as the .wua format is clearly the way to go in the future.

Method 1, using .wua files
Start Cemu and install the game, any updates as well as optional DLCs to the Cemu NAND. After the installation is completed, open the Title Manager from the Tools menu, select your game, right click and select Convert to compressed Wii U archive (.wua) and select your wiiu system directory as the target. You can modify the file name if you want to, or keep it at its default value. Press the Save button and the game will be automatically packaged as a .wua file.
Following this just start ES-DE and the game should be shown as a single entry that can be launched using Cemu.

Method 2, unpacked games
Only the setup on Windows is covered here, but it's the same principle in Linux and macOS.
Using this unpacked approach, the content of each game is divided into the three directories code, content and meta.
The first step is to prepare the target directory in the wiiu system directory, for this example we'll go for the game Super Mario 3D World. So simply create a directory with this name inside the wiiu folder. It should look something like the following:

- C:\Users\myusername\ROMs\wiiu\Super Mario 3D World\

The next step is done inside the Cemu user interface. You should install the game, any updates as well as optional DLCs to the Cemu NAND. After the installation is completed, right click on the game and choose Game directory. An Explorer window should now open showing the content of the game. Here's the game directory for our example:

- C:\Games\cemu\mlc01\usr\title\00050000\10145d00\code
Go up one level and copy the code, content and meta directories and paste them into the C:\Users\myusername\ROMs\wiiu\Super Mario 3D World\ directory. It should now look something like the following:

- C:\Users\myusername\ROMs\wiiu\Super Mario 3D World\code
- C:\Users\myusername\ROMs\wiiu\Super Mario 3D World\content
- C:\Users\myusername\ROMs\wiiu\Super Mario 3D World\meta

Starting ES-DE should now show the Super Mario 3D World entry for the Wii U system. The actual game file with the extension .rpx is stored inside the code directory, and does not normally match the name of the game. For this example it's named RedCarpet.rpx. When scraping the .rpx file you therefore need to refine the search and manually enter the game name. ES-DE fully supports scraping of directories, so you can scrape the Super Mario 3D World folder as well.
