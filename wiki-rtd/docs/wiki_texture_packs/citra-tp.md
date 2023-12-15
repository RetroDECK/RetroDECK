# Texture Packs: Citra - 3DS
The `~/retrodeck/texture_packs/citra/` represents the `/load/textures` folder in Citra.

**Note:** <br>
Some texture packs could made for a specific version or region of a game. Make sure you have the right game and textures for it.

**Note:**<br>
`TITLEID` is different for every game.

## Enable Custom Textures
* Open up Citra inside `RetroDECK Configurator` by pressing `Open Emulator` - `Citra`.
* Press `Emulation` -> `Configure` -> `Graphics` -> `Use Custom Textures` and set it to `On`.


## How do I add texture packs?

**Requirements:** Texture pack files <br>

**NOTE:** On the Steam Deck this could be easier to do in `Desktop Mode`.


There are two ways of adding texture packs into Citra


### From Citra
1. Extract any texture files from compressed `.zip` or any other format to folders.
2. Open up Citra inside `RetroDECK Configurator` by pressing `Open Emulator` - `Citra`.
3. Right click on the game you want to add textures into.
4. Click on `Open Custom Textures Location`.
5. Paste the texture folders inside that directory, each folder is stored by the `TITLLEID` of the game.
6. Quit Citra

### From the texture folder directly

1. Extract any texture pack files from compressed `.zip` or any other format into folders.
2. Go into `~/retrodeck/texture_packs/citra/`. The folders are all named by `TITLEID`.
3. Move textures into the right `~/retrodeck/texture_packs/citra/<TITLEID>` folder.

Example:

* You have a `.zip` file for a game that contains the `/load/textures/0000001000` folders.
* All you need to do is take the TITLEID folder: `0000001000` and put it into `~/retrodeck/texture_packs/citra/`
* So the end result looks like: `~/retrodeck/texture_packs/citra/0000001000`
