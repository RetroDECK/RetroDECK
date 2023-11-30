# How do I install RetroDECK on the Linux Desktop?

## Prerequisites

1. You need to have flatpak support installed on your Linux desktop. <br>
Follow the official flatpak guides on how to install it for your distribution:<br>
https://flatpak.org/setup/

2. We recommend that you have the `steam-devices` and/or `game-devices-udev` package installed as it comes with udev rules for many different controllers. You will have to check your distribution on how to install it.

3. We currently recommend that you add and launch RetroDECK from Steam so you can utilize the Steam Input feature to change various aspects of the external controllers. We will be looking into other alternative solutions later for those that don't want to use Steam.

# Installation

## From the Desktop GUI

- Go into your flatpak supported software manager in your desktop environment, this is different depending on what desktop you use. Example: for GNOME is often `GNOME Software` and for KDE it is `KDE Discover`.
- Search for RetroDECK and press install.

## From the terminal

- Run the following command `flatpak install flathub net.retrodeck.retrodeck`


# First Run - Quick Start

- Start RetroDECK for the first time
- Choose where RetroDECK should create the `roms` folders `Internal`, `SDCard` or `Custom`.
- Put the BIOS inside `~/retrodeck/bios/` for more information read: [[Emulators: BIOS and Firmware]]
- Put the ROMS inside `~/retrodeck/roms/` folder.
- Add RetroDECK to Steam with  `Add non Steam game to My library` or with the software BoilR (Recommended).
You can follow a more in depth guide here: [[Linux Desktop: Add RetroDECK to Steam]].
- In Steam go to the `Settings` tab to go into the `Steam Settings`, press `Controller`, enable all Steam Inputs.  You can follow a more in depth guide here: [[Linux Desktop: Enable Controllers in Steam]]
- Connect your controller to your Desktop.
- Launch RetroDECK from Steam and enjoy

### Other quick tips:
- Read up on the [[EmulationStation DE: User Guide]]
- Check out other recommended software [[Linux Desktop: Software recommendations]]

# Updates

Updates to RetroDECK is handled automatically via your software manager when there is a new version released.

Or if you want to update from the terminal you can type: <br>
`flatpak update`
