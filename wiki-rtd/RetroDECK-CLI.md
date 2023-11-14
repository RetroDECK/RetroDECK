# How do I run RetroDECK CLI commands?

Open a Linux terminal on your desktop (on the Steam Deck you need to be in desktop mode). Depending on what terminal application you have installed the naming of the application can be different.<br>

In Linux distributions that uses KDE desktop environment as well as the Steam Deck; the default application is called _Konsole_.
<br>
The default command to run retrodeck options and arguments is:

`flatpak run [FLATPAK-RUN-OPTION] net.retrodeck.retrodeck [ARGUMENTS]`

Where `[FLATPAK-RUN-OPTION]` is replaced by a flatpak run option (if there is one) and `[ARGUMENTS]` is replaced by arguments. 

**Example:**

This syntax runs the `--reset-all` argument that resets the application to default settings.

`flatpak run net.retrodeck-retrodeck --reset-all`

Where the argument `--reset-all` replaced `[ARGUMENTS]` and `[FLATPAK-RUN-OPTION]`was not needed to it was removed.

# CLI argument list

`-h` or `--help` - Prints all the available arguments.

`-v` or `--version` - Prints the installed RetroDECK version

`--info-msg` - Prints all the folder paths and various config information.
 
`--configurator` - Starts the RetroDECK configurator

`--compress` - Compresses a specific file to .chd format. It supports .cue .iso and .gdi formats. You need to add the filepath to the file for it to work.

`--reset-emulator` - Opens a new input where you can input an argument to reset a specific emulator or all emulators to the default settings. Inside the prompt you can type one of the following options to reset it;

`all-emulators`
`retroarch`
`citra`
`dolphin`
`duckstation` 
`melonds` 
`pcsx2` 
`ppsspp` 
`primehack` 
`rpcs3` 
`xemu`
`yuzu` 

`--reset-retrodeck` - Resets the entirety of RetroDECK to default settings! 
<br>
⚠️ WARNING! BACK UP YOUR DATA BEFORE RUNNING THIS ARGUMENT! ⚠️

# General flatpak commands

If you want to check RetroDECK's flathub page [click here](https://flathub.org/apps/details/net.retrodeck.retrodeck)<br>
Here follows some general flatpak commands that could be useful: <br>


## Install RetroDECK from CLI

If you want to install RetroDECK from CLI type:<br>
`flatpak install flathub net.retrodeck.retrodeck`

NOTE! This will work on the Steam Deck out of the box.<br>
But on the Linux desktop you need to check your distribution if it ships with both Flatpak and Flathub integration installed, if not you may need to install it. Check your distributions or flathubs documentation on how to install it on your desktop.

## Update all flatpaks from CLI

If you want to update all installed flatpaks from CLI type:<br>
`flatpak update`

Then answer `y` on the input prompt. 

## Update only RetroDECK from CLI

If you just want to update RetroDECK type: <br>

`flatpak update net.retrodeck.retrodeck`

Then answer `y` on the input prompt. 