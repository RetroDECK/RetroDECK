# Guide: IkemenGO / M.U.G.E.N

<img src="../../wiki_images/logos/ikemen-go-logo.png" width="150">


WIP

## Where to put the games
`IkemenGO` `Ikemen` and `M.U.G.E.N` games should be put under the `retrodeck/roms/mugen/` directory.

## ES-DE Guide

**This needs to be rewritten**

Ikemen GO and M.U.G.E.N Game Engine
M.U.G.E.N games can be played using the  game engine which is being actively developed and is available on Linux, macOS and Windows. The original M.U.G.E.N engine which only exists for Windows has not had any updates in years and is therefore considered obsolete and won't be covered here. But it's still possible to use it on Windows via the same approach described for Ikemen GO so if you really want to use it, then you can.
Basic setup

These games are shipped as self-contained units with the game engine binary included in the game directory structure. On Windows .lnk files are used to launch the games and on Linux and macOS files or symlinks with the .mugen extension are required.

For this example we'll go with the game Ultimate Sonic Mugen.
On Windows, go into the game directory, right click on the Ikemen_GO.exe file, select Create Shortcut followed by Create Desktop Shortcut. This will create a file with the .lnk extension. Rename the file to Ultimate Sonic Mugen.lnk and try to run this file to make sure that the game starts and runs correctly. Note that this setup is not portable, if you move your game files somewhere else you will need to manually update your shortcuts as these contain absolute paths.

On Linux and macOS, go into the game directory and rename the Ikemen_GO_Linux or Ikemen_GO_MacOS binary to the name of the game and add the .mugen extension to the filename, for example Ultimate Sonic Mugen.mugen. Try to run this file to make sure that the game starts and runs correctly.

Starting ES-DE and launching the game should now work fine, but a further improvement is to use the directories interpreted as files functionality to display the game as a single entry instead of a directory. To accomplish this, simply rename the game directory to the same name as the game file, which for this example would be Ultimate Sonic Mugen.lnk or Ultimate Sonic Mugen.mugen depending on which operating system you use.

The setup should now look something like the following:

```
~/ROMs/mugen/Ultimate Sonic Mugen.mugen/
~/ROMs/mugen/Ultimate Sonic Mugen.mugen/chars/
~/ROMs/mugen/Ultimate Sonic Mugen.mugen/data/
~/ROMs/mugen/Ultimate Sonic Mugen.mugen/external/
~/ROMs/mugen/Ultimate Sonic Mugen.mugen/font/
~/ROMs/mugen/Ultimate Sonic Mugen.mugen/sound/
~/ROMs/mugen/Ultimate Sonic Mugen.mugen/stages/
~/ROMs/mugen/Ultimate Sonic Mugen.mugen/Ultimate Sonic Mugen.mugen
```

Configuring M.U.G.E.N games for use with Ikemen GO
This section is only included to provide some general understanding on how to convert M.U.G.E.N games to run with Ikemen GO, it's in no way a complete tutorial and the steps needed are likely slightly different for each game. Refer to the Ikemen GO support forums and documentation for more thorough information.
We'll use the game Ultimate Sonic Mugen for this example.

Download Ikemen GO from [Ikemen GO Github](https://github.com/ikemen-engine/Ikemen-GO/releases) the package you want is Ikemen_GO_v0.98.2.zip or similar, depending on which version you're downloading. Unpack the file to a suitable location.

Download the game Ultimate Sonic Mugen and unpack it to a suitable location.
Create a new game directory, for example `~/ROMs/mugen/Ultimate Sonic Mugen`.
Copy the following directories from the downloaded game directory to the empty game directory you just created:

```
chars
data
font
sound
stages
```

If you're using an operating system with a case-sensitive file system like Linux, then you also need to rename every file inside the data directory to lowercase characters. This includes also the file extensions.
Copy the following directories from the Ikemen GO directory to the game directory:

```
data
external
font
The game binary, either Ikemen_GO.exe, Ikemen_GO_Linux or Ikemen_GO_MacOS
```

Do NOT overwrite any files when copying over the data and font directories, or the game will not work correctly.
