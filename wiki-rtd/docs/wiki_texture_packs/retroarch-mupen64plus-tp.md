# Texture Packs: RetroArch - N64 - Mupen64Plus-Next

The `texture_packs/RetroArch-Mupen64Plus/` represents `/retroarch/system/Mupen64plus/` folder.

**Note:** <br>
Some texture packs could made for a specific version or region of the game. Make sure you have the right rom and textures for it.

## Enable Texture Packs in the Mupen64Plus-Next core for certain games

From the `RetroArch Quick Menu`

* Go to `Core Options` -> `GLideN64` ->

`Use High-Res Textures` set to `On`<br>

`Cache Textures` set to `On`<br>

`Use High-Res Full Alpha Channel` set to `On`<br>

`Use Hi-Res Storage` set to `On`<br>

Then save the current configuration for that game under `Core Options` -> `Manage Core Options` -> `Save Game Options`

**Optional:**

`Use High-Res Texture Cache Compression` set to `On` - compresses uncompressed HD Textures into .hts files.




## How do I add texture packs that can be used by the Mupen64Plus-Next Core?

**NOTE:** On the Steam Deck this could be easier to do in `Desktop Mode`.

* All texture packs go into the `texture_packs//RetroArch-Mupen64Plus/hires_texture/` or `texture_packs/RetroArch-Mupen64Plus/cache/` folder.
* The texture pack have to be extracted from .zip or other compressed format into a folder.

## Compressed textures in .hts files
Compressed textures that are stored in `.hts` files goes into the `texture_packs/RetroArch-Mupen64Plus/cache/` folder.

## Uncompressed textures in loose folders or files
Uncompressed textures that are stored in in loose folders or files  goes into the `texture_packs/RetroArch-Mupen64Plus/hires_texture/` folder.

