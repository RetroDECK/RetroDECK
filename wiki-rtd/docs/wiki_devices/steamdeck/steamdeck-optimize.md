# What are some optimizations for the Steam Deck to make emulation even better?
These optimizations are entirely optional and but they can give you better performance on some more demanding emulators.

## Increase the VRAM to 4GB
This increases the VRAM to 4GB in the BIOS, this can give you improvements in certain emulators.

- Power off your Steam Deck completely
- Hold the `Power Button` and `Volume Up Button` until you hear a chime/beep and release the buttons.
- Click on `Setup Utility`
- Click on `Advanced`
- Change`UMA Frame buffer Size` to 4GB
- Save and Exit

## Setup a sudo password
This is a requirement for many optimizations and solutions, it also makes your Deck safer.
It enables you to run commands/applications heighten sudo privileges.

- Go to `Desktop Mode`
- Open `Konsole` or another `Terminal`
- Type `passwd`
- You will now set your new sudo password
- After you are done you can close the terminal

## Install CryoUtilities
This requires that you have set up a sudo password.

This will create a 16GB SWAP file that can improve the performance for some emulators. Note that it will take up that extra space on your Steam Deck.

- Go to `Desktop Mode`
- Open a web browser and go to the [CryoUtilities](https://github.com/CryoByte33/steam-deck-utilities) github page
- Click on releases
- Download the latewst `cryo_utilities` version and save to the Desktop or Home folder
- Double click on the file and it will begin the installation
- After installation is complete you will find a new desktop icon `CryoUtilities`
- Click on `CryoUtilities`
- Click on `Recommended Settings`
- It should now be done

## Install Decky Loader
Decky Loader is a [homebrew plugin store](https://beta.deckbrew.xyz/) for the Steam Deck.
This requires that you have set up a sudo password.

- Go to `Desktop Mode`
- Open `Konsole` or another `Terminal`
- Type `curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh`
- Decky Loader should now be installed and you can go back into `Game Mode`.
- To access Decky Loader you only need to press the `Menu Button - (•••)`

### Decky Loader: Install Power Tools
Power Tools allows you to tweak various performance settings of the Steam Deck.
What the best setting is differs per emulator or even per game.

In Game Mode:

- `Menu Button - (•••)`
-  Go into Decky Loader
-  From the Store install Power Tools
-  This will add a 🔌 icon to the `Menu Button - (•••)` where you can access Power Tools.

### Decky Loader:  AutoFlatpaks
AutoFlatpaks allows you to manage and update flatpaks like RetroDECK directly from Game Mode

- `Menu Button - (•••)`
-  Go into Decky Loader
-  From the Store install AutoFlatpaks
