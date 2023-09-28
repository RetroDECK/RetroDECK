# Where to put the games?
PS3 games comes either as a Blu-ray rip directory (folder) with a bunch of different files or a digital PSN title that needs to be installed (see guide on this page). 

PS3 games should be put under the `retrodeck/roms/ps3/` directory.

# How to: Install the PS3UPDAT.PUP firmware

There are two ways to install the firmware:

## Install PS3 firmware from RetroDECK Configurator

1. Open RPCS3 `RetroDECK Configurator` - `RetroDECK: Tools` - `Install: PS3 Firmware`.
2. Press `OK` and this will download the PS3 Firmware and open RPCS3.
3. You will get a prompt asking if you want to install the firmware from the /tmp/ folder, say `Yes`
4. Wait for the installation to finish
5. Exit RPCS3 from the GUI under `File -> Exit`

## Manual Download
1. Download the latest PS3 firmware `PS3UPDAT.PUP` from Sony [here](https://www.playstation.com/en-us/support/hardware/ps3/system-software/) 
2. Open RPCS3 `RetroDECK Configurator -> Open Emulator -> RPCS3`.
3. In the RPCS3 interface navigate to `File -> Install Firmware`.
4. In the file browser navigate and select the file `PS3UPDAT.PUP` file.
5. The firmware should now be installed.

# How to: Get games to show up inside the ES-DE interface
To get the games to show up you need to rename the directory to end with a `.ps3` file extension.

_Example:_

You have directory dump of the a game Blu-ray PlayStation 3 game called Hockey World, the directory is called `Hockey World`. 

To get the it to show up you need to rename and add `.ps3` in the end of the directory name.

The directory `Hockey World` becomes `Hockey World.ps3` and the game will show up.


# How to: Install DLC or patches on disc based games

**NOTE:** On the Steam Deck this could be easier to do in `Desktop Mode`. If you want to do it in `Game Mode` you need to press the `Steam` button and switch between windows using the window switcher. 

If you want to install some DLC or patch you can do that trough RPCS3 itself.

1. Open RPCS3 `RetroDECK Configurator -> Open Emulator -> RPCS3`.
2. In the RPCS3 interface navigate to `File -> Install Packages/Raps/Edats`.
3. In the file browser navigate and select the file you want to install.
4. The file will be installed inside the a new game directory on the RPCS3 hard drive under 
  `retrodeck/bios/rpcs3/dev_hdd0/game/GAMEID` where `GAMEID` is unique for each game [PS3GAMEID-List](https://www.gametdb.com/PS3/List).
5. The patches or dlc should now be installed and in the GAMEID directory. 
6. Move the content of the GAMEID directory into the games directory inside the `retrodeck/roms/ps3/GAMENAME.ps3` directory and overwrite & replace the files.
8. You can now remove the `retrodeck/bios/rpcs3/dev_hdd0/game/GAMEID` directory as the files have been moved.
9. The game can be launched inside the ES-DE interface with patches and DLC installed.

_Example:_

The game `Hockey World.ps3` inside the `retrodeck/roms/ps3/` has some DLC & and a patch you want to install. 

You follow the above guide and install the files.

The installation made a newly created directory called `BCA111111` under `retrodeck/bios/rpcs3/dev_hdd0/game/`.

You open up the directory `retrodeck/bios/rpcs3/dev_hdd0/game/BCA111111` and copy all of it's content and paste it into `retrodeck/roms/ps3/Hockey World.ps3` directory and replace/overwrite the files.

You can then remove the `BCA111111` directory in `retrodeck/bios/rpcs3/dev_hdd0/game/`

# How to: Install digital PSN titles

**NOTE:** On the Steam Deck this could be easier to do in `Desktop Mode`. If you want to do it in `Game Mode` you need to press the `Steam` button and switch between windows using the window switcher. 

If you want to install some PSN tiltes you can do that trough RPCS3 itself.

1. Open RPCS3 `RetroDECK Configurator -> Open Emulator -> RPCS3`.
2. In the RPCS3 interface navigate to `File -> Install Packages/Raps/Edats`.
3. In the file browser navigate and select the file you want to install.
4. The file will be installed inside the games directory on the RPCS3 hard drive under 
  `retrodeck/bios/rpcs3/dev_hdd0/game/GAMEID` where `GAMEID` is unique for each game [PS3GAMEID-List](https://www.gametdb.com/PS3/List).
5. Install any patches or DLC for the game by repeating step .2 and .3 for each file.
6. After the game is ready move the digital games directory from `retrodeck/bios/rpcs3/dev_hdd0/game/GAMEID` to `retrodeck/roms/ps3`
7. Rename the directory to the name of the game and add the .ps3 file extension to the end of the directory (see guide on top).
8. The game should now show up and be playable inside the ES-DE interface. 


_Example:_

You installed a file that contained the digital game Hockey World 2, it created a directory called `BCA123456` under `retrodeck/bios/rpcs3/dev_hdd0/game/`

After that you moved `BCA123456` from `retrodeck/bios/rpcs3/dev_hdd0/game/` to `retrodeck/roms/ps3`.
The directory `BCA123456` is renamed to `Hockey World 2.ps3`.