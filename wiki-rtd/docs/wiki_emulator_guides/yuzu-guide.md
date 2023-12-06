# Guide: Yuzu - Switch

<img src="../../wiki_images/logos//yuzu-logo.svg" width="150">

---

### Yuzu Links:
[Yuzu Quickstart Guide](https://yuzu-emu.org/help/quickstart/)

[Yuzu Wiki](https://yuzu-emu.org/wiki/)

[Yuzu Github](https://github.com/yuzu-emu/yuzu)

[Yuzu Webpage](https://yuzu-emu.org/)

---

## Where to put the games?
Switch games should be put into the `retrodeck/roms/switch/` directory.<br>
The games can come in many different formats: `XCI` `NSP` `NCA` `NSO` `NRO`.

## Does Yuzu require BIOS or Firmware?
Yes, `prod.keys` `title.keys` and `nca` files.

### Where do I put the BIOS and firmware files?
Yuzu needs the key files `prod.keys`, `title.keys` and the firmware files in the following directories:

**Yuzu keys:** `~/retrodeck/bios/switch/keys`

**Yuzu firmware:** `~/retrodeck/bios/switch/registered`

The directory tree should look like this example:
```
~/retrodeck/bios/switch
├── keys
│   ├── prod.keys
│   └── title.keys
└── registered
    ├── 02259fd41066eddbc64e0fdd217d9d2f.nca
    ├── 02582a2cd46cc226ce72c8a52504cd97.nca
    ├── 02b1dd519a6df4de1b11871851d328a1.nca
    ├── other 217 files...
    └── fd0d23003ea5602c24ac4e41101c16fd.nca
```

You can find a complete guide in the Yuzu Wiki (link above) on how to extract the BIOS from your Switch.

## How do I install DLC and Updates?

**Requirements:** Patch or DLC files <br>

**NOTE:** On the Steam Deck this could be easier to do in `Desktop Mode`.

1. Extract any patch or dlc files from compressed `.zip` or any other format to the true files.
2. Open up Yuzu inside `RetroDECK Configurator` by pressing `Open Emulator` - `Yuzu`.
3. Press `File` - `Install Files to NAND`
4. Find a DLC or Patch file from the file browser and press `Open`
5. This will install the DLC or Patch file into the games NAND folder inside of Yuzu.
6. Repeat step 2 to 3 for every file you need to install.
7. Quit Yuzu
8. Start up RetroDECK and select the game you want to play. <br>

## How do I add shader caches?

**Requirements:** Shader cache files <br>

**NOTE:** On the Steam Deck this could be easier to do in `Desktop Mode`.

1. Extract any shader cache files from compressed `.zip` or any other format to folders.
2. Open up Yuzu inside `RetroDECK Configurator` by pressing `Open Emulator` - `Yuzu`.
3. Right click on the game you want to add mods into.
4. Click on `Open Transferable Pipeline Cache`.
5. Paste the files inside that directory.
6. Start up RetroDECK and select the game. <br>

## How do I add mods?
Check: `Mod Guides ⚙️` - `Mods: Yuzu - Switch`

