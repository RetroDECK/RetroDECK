# Adding RetroDECK to Steam
What follows are two ways to add RetroDECK to Steam and what settings you need to enable after you added it. If you have the Flatpak Version of Steam installed you need to do some extra steps for everything to work.

## Add with BoilR (Recommended)

If you don't have [BoilR](https://flathub.org/apps/io.github.philipk.boilr) you can just install it from Flathub.
BoilR will add RetroDECK to Steam (flatpak or standard versions), it will also add the Steam Grid art.

First make sure that you have fully closed Steam then do the following:

1. Open BoilR
2. Make sure RetroDECK is marked in the `Import Games` Section
3. Go to `Settings`
4. Check `Download Images`
5. Put in your `Authentication Key` from `SteamGridDB` (if you don't have one press the link in BoilR and get one).
6. Check if you want animated images or other types of images.
7. Go back to `Import Games`.
8. Press the `Import Button`.
9. When the import is done you can close BoilR and Open Steam.
10. The RetroDECK entry should now be there

## Add manually

1. Open Steam
2. Inside Steam go to the tab Games press `Add non Steam game to My library` and you should be able to see all installed applications select `RetroDECK` to add it into your library.
3. Go to SteamGridDB and manually download all the art.
4. Follow the guides on SteamGridDB on how to set up each art piece correctly.

## Steam - Flatpak version extras

If you have the [Steam Flatpak](https://flathub.org/apps/com.valvesoftware.Steam) version installed some extra steps apply.

### Prerequisites

To make a flatpak launch other flatpaks it needs a special permission called `org.freedesktop.Flatpak`.
Take note that this opens up the Flatpak more then normal, as flatpaks are not allowed to run many system commands from the sandbox. You can add the permission from the software Flatseal or directly from the terminal.

**With Flatseal (Recommended):**

If you don't have [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal) you can just install it from Flathub

1. Open Flatseal
2. Click on Steam
3. Scroll down to the section called `Session Bus`
4. Press the `+` sign
5. Paste in `org.freedesktop.Flatpak`
6. Launch Steam

**From Terminal:**

Copy the following into the terminal:

`flatpak --user override --talk-name=org.freedesktop.Flatpak com.valvesoftware.Steam`

### Add RetroDECK to Steam

Add RetroDECK to Steam with BoilR or manually by following the guides above.

**Special notes on the manual install:**

Steam won't find the application directlyy and you will need to manually browse to the desktop file to add it in:

`/var/lib/flatpak/app/net.retrodeck.retrodeck/current/active/export/share/applications/`

### Configuring RetroDECK in Steam Flatpak

After RetroDECK is added to Steam, right click on the RetroDECK entry and change the shortcut values to:

**Target:**

`/usr/bin/flatpak-spawn`

**Launch options:**

`--host flatpak run --branch=stable --arch=x86_64 net.retrodeck.retrodeck`

This should now be enough for you to launch RetroDECK.
