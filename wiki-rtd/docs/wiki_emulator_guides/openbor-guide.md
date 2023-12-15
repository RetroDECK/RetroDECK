# Guide: OpenBOR

<img src="../../wiki_images/logos//openbor-logo.svg" width="150">

WIP

## Where to put the games
OpenBOR games should be put under the `retrodeck/roms/openbor/` directory.

## ES-DE Guide

**This needs to be rewritten**

The Open Beats of Rage (OpenBOR) game engine is available on Windows and Linux. Unfortunately the macOS ports seems to have been abandoned.
These games are often but not always distributed together with the game engine as specific engine versions may be required for some games. The setup is slightly different between Windows and Linux so they are described separately here.

On Linux you need to supply your own game engine binary as few (if any) games are distributed with the Linux release of OpenBOR. <br>
Download the .7z archive from the [OpenBOR Github](https://github.com/DCurrent/openbor) repository.

The file you want is `OpenBOR<Versionnumber>.AppImage` which is located inside the LINUX/OpenBOR folder. If you need an older engine for some specific game, then you may need to download an earlier release instead.

Copy this file to the game directory and make it executable using the command chmod +x `OpenBOR<Versionnumber>.AppImage`

Using the same game example as for the Windows instructions above, the directory structure should look like the following:

```
/ROMs/openbor/D&D - K&D - The Endless Quest LNS/
/ROMs/openbor/D&D - K&D - The Endless Quest LNS/Logs/
/ROMs/openbor/D&D - K&D - The Endless Quest LNS/Paks/
/ROMs/openbor/D&D - K&D - The Endless Quest LNS/Saves/
/ROMs/openbor/D&D - K&D - The Endless Quest LNS/ScreenShots/
/ROMs/openbor/D&D - K&D - The Endless Quest LNS/OpenBOR_3.0_6391.AppImage
/ROMs/openbor/D&D - K&D - The Endless Quest LNS/OpenBOR.exe
```

You can delete the OpenBOR.exe file since you don't need it, and it's recommended to rename the `OpenBOR<Versionnumber>.AppImage` file to the name of the game, such as:

`~/ROMs/openbor/D&D - K&D - The Endless Quest LNS/The Endless Quest.AppImage`

Starting ES-DE and launching the game should now work fine, but a further improvement is to use the directories interpreted as files functionality to display the game as a single entry instead of a directory. To accomplish this, simply rename the game directory to the same name as the .AppImage file, such as:

`~/ROMs/openbor/The Endless Quest.AppImage/The Endless Quest.AppImage`

Doing this will make the game show up as if it was a single file inside ES-DE and it can be included in automatic collections, custom collections and so on.
