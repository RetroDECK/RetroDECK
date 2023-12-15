# Guide: RPCS3 - Playstation 3

<img src="../../wiki_images/logos/rpcs3-logo.png" width="150">

---

### RPCS3 Links:

[RPCS3 Quickstart Guide](https://rpcs3.net/quickstart)

[RPCS3 Wiki](https://wiki.rpcs3.net/index.php?title=Main_Page)

[RPCS3 Github](https://github.com/RPCS3/rpcs3)

[RPCS3 Webpage](https://rpcs3.net/)

---

## Where to put the games?
PS3 games comes either as a Blu-ray rip directory (folder) with a bunch of different files or a digital PSN title that needs to be installed (see guide on this page).

PS3 games should be put under the `retrodeck/roms/ps3/` directory.

## Does RPCS3 require BIOS or Firmware?
Yes, the `PS3UPDAT.PUP` firmware

### How to: Install the PS3UPDAT.PUP firmware

There are two ways to install the firmware:

#### Install PS3 firmware from RetroDECK Configurator

1. Open RPCS3 `RetroDECK Configurator` - `RetroDECK: Tools` - `Install: PS3 Firmware`.
2. Press `OK` and this will download the PS3 Firmware and open RPCS3.
3. You will get a prompt asking if you want to install the firmware from the /tmp/ folder, say `Yes`
4. Wait for the installation to finish
5. Exit RPCS3 from the GUI under `File -> Exit`

#### Manual Download
1. Download the latest PS3 firmware `PS3UPDAT.PUP` from Sony [here](https://www.playstation.com/en-us/support/hardware/ps3/system-software/)
2. Open RPCS3 `RetroDECK Configurator -> Open Emulator -> RPCS3`.
3. In the RPCS3 interface navigate to `File -> Install Firmware`.
4. In the file browser navigate and select the file `PS3UPDAT.PUP` file.
5. The firmware should now be installed.

## How to: Get games to show up inside the ES-DE interface

There are two methods of adding the games

Read more here:<br>
https://gitlab.com/es-de/emulationstation-de/-/blob/master/USERGUIDE.md#sony-playstation-3

### Method 1: Game shortcuts .desktop files (recommended)

This method can be used for all types rips/dumps both directories and .iso files.

1. Open RPCS3 via the Configurator
2. Click File -> Add Game -> Browse to game you want to add.
3. The game will now show up in the RPCS3 game list.
4. Rightclick on that list.
5. This will create a shortcut to the game on your Desktop.
6. Move that shortcut into the roms/ps3 folder.

### Method 2: Directories as .ps3 files
This method can only be used directory type game dumps.
To get the games to show up you need to rename the directory to end with a `.ps3` file extension.

_Example:_

You have directory dump of the a game Blu-ray PlayStation 3 game called Hockey World, the directory is called `Hockey World`.

To get the it to show up you need to rename and add `.ps3` in the end of the directory name.

The directory `Hockey World` becomes `Hockey World.ps3` and the game will show up.


## How to: Install DLC or patches on disc based games

**NOTE:** On the Steam Deck this could be easier to do in `Desktop Mode`. If you want to do it in `Game Mode` you need to press the `Steam` button and switch between windows using the window switcher.

If you want to install some DLC or patch you can do that trough RPCS3 itself.

1. Open RPCS3 `RetroDECK Configurator -> Open Emulator -> RPCS3`.
2. In the RPCS3 interface navigate to `File -> Install Packages/Raps/Edats`.
3. In the file browser navigate and select the file you want to install.
4. The game can be launched via RetroDECK with patches and DLC already installed.

### (OPTIONAL) How to include the DLC or PATCH in the main game files

Some users may want to include their DLC or PATCH files inside the game folder for achiving purposes, or just to don't have to keep these contents spread in the RPCS3 filesystem.
It's fully optional but to do so the steps are:

1. The files will be installed inside the a new game directory on the RPCS3 hard drive under
  `retrodeck/bios/rpcs3/dev_hdd0/game/GAMEID` where `GAMEID` is unique for each game [PS3GAMEID-List](https://www.gametdb.com/PS3/List).
2. The patches or dlc should now be installed inside the `GAMEID` directory.
3. Move the content of the GAMEID directory into the games directory inside the `retrodeck/roms/ps3/GAMENAME.ps3` directory and overwrite & replace the files.
4. You can now remove the `retrodeck/bios/rpcs3/dev_hdd0/game/GAMEID` directory as the files have been moved.

Example:

- The game `Hockey World.ps3` inside the `retrodeck/roms/ps3/` has some DLC & and a patch you want to install.
- You follow the above guide and install the files.
- The installation made a newly created directory called `BCA111111` under `retrodeck/bios/rpcs3/dev_hdd0/game/`.
- You open up the directory `retrodeck/bios/rpcs3/dev_hdd0/game/BCA111111` and copy all of it's content and paste it into `retrodeck/roms/ps3/Hockey World.ps3` directory and replace/overwrite the files.
- You can then remove the `BCA111111` directory in `retrodeck/bios/rpcs3/dev_hdd0/game/`

## How to: Install digital PSN titles

The procedure is almost identical as the procedure above.
**NOTE:** On the Steam Deck this could be easier to do in `Desktop Mode`. If you want to do it in `Game Mode` you need to press the `Steam` button and switch between windows using the window switcher.

If you want to install some PSN tiltes you can do that trough RPCS3 itself.

1. Open RPCS3 `RetroDECK Configurator -> Open Emulator -> RPCS3`.
2. In the RPCS3 interface navigate to `File -> Install Packages/Raps/Edats`.
3. In the file browser navigate and select the file you want to install.
4. The file will be installed inside the games directory on the RPCS3 hard drive under
  `retrodeck/bios/rpcs3/dev_hdd0/game/GAMEID` where `GAMEID` is unique for each game [PS3GAMEID-List](https://www.gametdb.com/PS3/List).
5. Install any patches or DLC for the game by repeating step .2 and .3 for each file.
6. The game should now show up and be playable inside the ES-DE interface.

### (OPTIONAL) Move the digital contents into a .ps3 folder
Similarly on how written above with the DLC and PATCHES the user can decide to move the digital games outside the RPCS3 filesystem, in order to do so:

1. After the game is ready move the digital games directory from `retrodeck/bios/rpcs3/dev_hdd0/game/GAMEID` to `retrodeck/roms/ps3`
2. Rename the directory to the name of the game and add the .ps3 file extension to the end of the directory (see guide above).


**Example:**

- You installed a file that contained the digital game Hockey World 2, it created a directory called `BCA123456` under `retrodeck/bios/rpcs3/dev_hdd0/game/`
- After that you moved `BCA123456` from `retrodeck/bios/rpcs3/dev_hdd0/game/` to `retrodeck/roms/ps3`.
The directory `BCA123456` is renamed to `Hockey World 2.ps3`.
