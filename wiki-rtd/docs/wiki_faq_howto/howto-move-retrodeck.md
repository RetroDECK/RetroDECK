# How do I move RetroDECK to a new device?



### Prerequisites: Before you move
- Make sure you are running the latest version of RetroDECK on the old device and have started it at least once.
- If your device has a battery like a Steam Deck or Laptop, make sure it has enough charge to complete the file transfer. We recommend you are plugged in while doing this to prevent data loss.

**NOTE:**

If you old device is broken but you still have access to the data you can skip this step.


# Quickguides:

## Ultra Quickguide:
1. Just copy the `~/retrodeck` folder to the new device to the location you want it.
2. Install RetroDECK on the new device and point to it the new location of `~/retrodeck` during first setup.
3. Proceed installation as normal.

## Quickguide - Steam Deck:
1. Put the Steam Deck into Desktop Mode `Steam button` > `Power` > `Switch to Desktop`.
2. Back up existing the RetroDECK `~/retrodeck` folder .
3. On the new Steam Deck install RetroDECK on your [from the Discover store](#step-2-install-from-discover).
4. Do not launch RetroDECK on your new device until you have copied over the backed up folders.
5. Copy over the backup folder to the same location (or new) on the new device.
6. Launch RetroDECK on the new device and point towards the `~/retrodeck` location during installation. So if you have moved the `~/retrodeck` to the SD card of the new Steam Deck choose the SD card option during initial install, if you have moved it to the internal storage (home/) choose that option or third chose the custom option.

After that you can keep following following the installation guide [[Steam Deck: Installation and updates]] if you are unsure on progress the installation.

## Quickguide - Linux Desktop:
1. Back up existing the RetroDECK `~/retrodeck` folder .
2. On the new PC install RetroDECK from flathub via your application manager.
3. Do not launch RetroDECK on your new device until you have copied over the backed up folders.
4. Copy over the backup folder to the same location (or new) on the new device.
5. Launch RetroDECK on the new device and point towards the `~/retrodeck` location during installation.

After that you can keep following following the installation guide [[Linux Desktop: Installation and updates]] if you are unsure on progress the installation.

# Information on moving RetroDECK:

RetroDECK contains mainly two folders:

`~/retrodeck`<br>
This is the important folder, that contains all the user content like roms/bios/saves/screenshots/scraped data etc...
The location of the folder is where you have chosen to install it like `/home/retrodeck` `sd-card` `external drive` `other`.

`~/.var/app/net.retrodeck.retrodeck`<br>
This is the location of the core flatpak, emulator files and configurations.


## Two ways to move RetroDECK:

What follows is a short comparison on the two ways to move RetroDECK.


### Move just `~/retrodeck` (recommended)

**Downsides:**
* You will lose all your custom emulator settings inside the emulators (like graphic settings or other tweaks), everything else stays intact.
* You will need to go through the initial setup again and point to the moved retrodeck folder.

**Upsides:**
* You will get the benefits of a fresh install with all your content intact (saves, games, scraped data etc..).
* You minimize the risks of any file conflicts.

### Move `~/.var/app/net.retrodeck.retrodeck` and `~/retrodeck`

**Downsides:**
* Need to reinstall things from configurator like controller profiles.
* Need to make sure you are on the same version before you update.
* If there are any version conflicts within `~/.var/app/net.retrodeck.retrodeck` things could break.

**Upsides:**
* No first install, just move and play.
* All custom emulator settings you have made are moved.


# How to: move from a old Steam Deck to a new Steam Deck?

**Note:**

Depending on how comfortable you are using the Steam Deck controller to navigate the desktop environment, this may be easier to do with a connected mouse and keyboard.

## Recommended way: Only move `~/retrodeck`

### Step 1: Back up your existing files
You will need to backup the the main `~/retrodeck` folder.

- First put the Steam Deck into Desktop Mode `Steam button` > `Power` > `Switch to Desktop`.
- Main `~/retrodeck` folder
    - Open the Dolphin File Manager (the folder icon in the taskbar).
    - Navigate to where you installed `~/retrodeck` (this folder should contain sub-folders such as `bios`, `roms`, and `saves`).
    - Copy the whole folder `~/retrodeck` to a device used for transfer such as a thumb drive, microSD Card, NAS, SFTP and get the files to the new Steam Deck. Or use a transfer software like warpinator to send the folder to the new Steam Deck via network.


### Step 2: Install RetroDECK on your new Steam Deck
- Follow steps 1 and 2 of the installation guide over at: [[Steam Deck: Installation and updates]] but stop after Step 2 and do not open RetroDECK yet!

### Step 3: Restore your backed up files
- Copy over the `~/retrodeck` to the new device via any of the chosen methods from step 1.
- Launch RetroDECK on the new device and point towards the `~/retrodeck` location during installation. So if you have moved the `~/retrodeck` to the SD card of the new Steam Deck choose the SD card option during initial install, if you have moved it to the internal storage choose that option or third chose the custom option.
- Keep following the [[Steam Deck: Installation and updates]] as normal.


## Other way: Move `.var/ files` and `~/retrodeck`

This is not recommended, but if you know what you are doing you could try this way.

### Step 1: Back up your existing files
You will need to backup two directories: the main `~/retrodeck` folders and a hidden `~/.var/app/net.retrodeck.retrodeck` folder.

- First put the Steam Deck into Desktop Mode `Steam button` > `Power` > `Switch to Desktop`.
- Main `retrodeck` folder
    - Open the Dolphin File Manager (the folder icon in the taskbar).
    - Navigate to where you installed `~/retrodeck` (this folder should contain sub-folders such as `bios`, `roms`, and `saves`).
    - Copy the whole folder `~/retrodeck` to a device used for transfer such as a thumb drive, microSD Card, NAS, SFTP and get the files to the new Steam Deck. Or use a transfer software like warpinator to send the folder to the new Steam Deck via network.
    - Put the copy in the same location as the old Steam Deck.

- Hidden `net.retrodeck.retrodeck` folder
    - Return to `home`
    - Find the "hamburger" menu button (three horizontal lines in the top-right). Open the menu and select `Show Hidden Files`. If on a keyboard, you can type `Ctrl+H`.
    - Navigate to `home/.var/app/net.retrodeck.retrodeck/` and copy the whole folder it to device used for transfer such as a thumb drive, microSD Card, NAS, SFTP and get the files to the new Steam Deck. Or use a transfer software like warpinator to send the folder to the new Steam Deck via network.

### Step 2: Install RetroDECK on your new Steam Deck
- Follow steps 1 and 2 of the installation guide over at: [[Steam Deck: Installation and updates]] but stop after Step 2 and do not open RetroDECK yet!

### Step 3: Restore your backed up files
- Move the copy of `~/retrodeck` to the same location as the old Steam Deck.
- Move the copy of `~/.var/app/net.retrodeck.retrodeck` to `~/.var/app/net.retrodeck.retrodeck` on the new device.
- In both cases, you can safely overwrite all existing files.
- You can now just launch RetroDECK if all have gone well directly from gamemode, without needing to do the initial setup.
- Don't forget to install the official controller profile in the configurator!
