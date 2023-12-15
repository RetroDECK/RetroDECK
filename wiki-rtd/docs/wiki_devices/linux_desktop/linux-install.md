# How do I install RetroDECK on the Linux Desktop?

<img src="../../../wiki_images/logos/linux-tux-logo.svg" width="150">

## Prerequisites

1. You need to have flatpak support installed on your Linux desktop. <br>
Follow the official flatpak guides on how to install it for your distribution:<br>
[Flatpak Setup Guide](https://flatpak.org/setup/)

2. We recommend that you have the `steam-devices` and/or `game-devices-udev` package installed as it comes with udev rules for many different controllers. You will have to check your distribution on how to install it.

3. We currently recommend that you add and launch RetroDECK from Steam so you can utilize the Steam Input feature to change various aspects of the external controllers. We will be looking into other alternative solutions later for those that don't want to use Steam.

## From the Desktop GUI

- Go into your flatpak supported software manager in your desktop environment, this is different depending on what desktop you use. Example: for GNOME is often `GNOME Software` and for KDE it is `KDE Discover`.
- Search for RetroDECK and press install.

## From the terminal

- Run the following command `flatpak install Flathub net.retrodeck.retrodeck`


## First Run - Quick Start

1. Start RetroDECK for the first time
2. Choose where RetroDECK should create the `roms` folders `Internal`, `SDCard` or `Custom`.
3. Put the BIOS inside `~/retrodeck/bios/` for more information read
4. Put the ROMS inside `~/retrodeck/roms/` folder.<

5. Add RetroDECK to Steam [How-to - Add RetroDECK to Steam](../../wiki_howto_faq/add-to-steam.md)
6. Make sure you have enabled controller support in Steam [How-to - Enable Controllers in Steam ](../../wiki_howto_faq/enable-controllers-steam.md)
7. Connect your controller to your Desktop.
8. Launch RetroDECK from Steam and enjoy

## Updates

Updates to RetroDECK is handled automatically via your software manager when there is a new version released.

Or if you want to update from the terminal you can type: <br>
`flatpak update`
