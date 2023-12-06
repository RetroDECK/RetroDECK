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
The `zRIF` format is also used during installation.<br>

## Does Vita3K require BIOS or Firmware?
Yes, the firmware can be installed from the Configurator or during first setup of RetroDECK.

You can also install it manually:<br>
Download the firmware from [Sony PSVita Software](https://www.playstation.com/en-us/support/hardware/psvita/system-software/) and open Vita3K from the Configurator and press `File - Install Firmware` to install the downloaded firmware.

## How to: Get games to show up inside the ES-DE interface

**Example:** <br>
In this example we got a game we want to add: `WipEout 2048`


- Install a game opening the Vita3K emulator via Configurator, the supported formats are `pkg`, `zip`, `vpk`.
- Upon installation the `zRIF` may be asked, it's different for each game, you can find it via web search by searching for example `WipEout 2048 (EU) zRIF`.
- Install DLCs and patches in the same way.
- Create an empty file in `retrodeck/roms/psvita/gamename.psvita`, please mind the `.psvita` extension.<br>
For example: `roms/psvita/WipEout 2048 (EU).psvita.`
- Edit the empty file adding the game `Title ID` (more below).
- The game should appear in the game list after RetroDECK is re-opened or reloaded from the Utilities.

## How to find a title ID
It can be found inside the Vita3K GUI in the Title ID column, or found via web search.
For example the game `WipEout 2048 (EU)` has an ID that is `PCSF00007`.
So simply add `PCSF00007` to the `WipEout 2048 (EU).psvita` file and the setup for this game is complete.
