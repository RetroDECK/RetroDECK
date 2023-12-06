# Guide: Vita3K

**Please note that the PSVita support is still experimental and it will be available starting from RetroDECK 0.8.0b**

<img src="../../wiki_images/logos/vita3k-logo.png" width="150">

---

### Vita3K Links:
[Vita3K Quickstart Guide](https://vita3k.org/quickstart.html)

[Vita3K Game Compatibility and ID List](https://vita3k.org/compatibility.html?lang=en)

[Vita3K Homebrew Compatibility and ID List](https://vita3k.org/compatibility-homebrew.html)

[Vita3K Wiki](https://github.com/Vita3K/Vita3K/wiki)

[Vita3K Github](https://github.com/Vita3K/Vita3K)

[Vita3K Webpage](https://vita3k.org/)

---

## Where to put the games?
Vita3K games should be put into the `retrodeck/roms/psvita/` directory.<br>
The supported formats are `pkg`, `zip`, `vpk`. <br>

## Does Vita3K require BIOS or Firmware?
Yes, it requires two firmwares.

- The Firmware: `PSVUPDAT.PUP`
- The Firmware Font Package: `PSP2UPDAT.PUP`

The firmware and font firmware can be downloaded and installed from the Configurator.

You can also install them manually:<br>
Download the firmwares from

- [Sony PSVita Firmware](https://www.playstation.com/en-us/support/hardware/psvita/system-software/)
- [Sony PSVita Firmware Font Package](https://dus01.psp2.update.playstation.net/update/psp2/image/2022_0209/sd_59dcf059d3328fb67be7e51f8aa33418/PSP2UPDAT.PUP?dest=usand)

Open Vita3K from the Configurator and press `File - Install Firmware` to install the downloaded firmware.

## Licence Files and Keys

Licence files `.bin` `.rif` or a licence keys called a `zRif` are required for many games.<br>
They need to be installed by pressing `File - Install Licence` then either `Select work.bin / rif` for the files or `Enter zRif` to input the key.

## How to: Get games to show up inside the ES-DE interface

**Example:** <br>
In this example we got a game we want to add: `WipEout 2048`

### Step 1: Install the Game
Open the Vita3K emulator via Configurator and press `File` and either `Install .pkg` or `Install .zip, .vpk` depending on what game file you have.

In our example `WipEout 2048` is a `.pkg` file so we chose the `Install .pkg` option and navigate to the file to install it.

#### Step 1b: Add Licences (not always needed)
During installation the Vita3K could call for a Licence File or Key. <br>
Either add the `.bin` or `.rif` files or input the `zRif` key in the prompt.
Check more above in the **Licence Files and Keys** section.

#### Step 1c: Install any DLCs or patches
Install the patches and DLC the same way as the game by repeating Step 1 to 1b for the filetype the patch/DLC is in `pkg`, `zip`, `vpk`.

### Step 2: Create the .psvita file
- Create an empty file in `retrodeck/roms/psvita/gamename.psvita`, please mind the `.psvita` extension.<br>
For example: `roms/psvita/WipEout 2048 (EU).psvita.`
- Edit the empty file adding the game `Title ID` (more below).
- The game should appear in the game list after RetroDECK is re-opened or reloaded from the Utilities.

## How to find a title ID
It can be found inside the Vita3K GUI in the Title ID column, or found via web search.
For example the game `WipEout 2048 (EU)` has an ID that is `PCSF00007`.
So simply add `PCSF00007` to the `WipEout 2048 (EU).psvita` file and the setup for this game is complete.
