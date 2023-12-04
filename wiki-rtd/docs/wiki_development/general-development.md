# Development General Notes

## Cooker
Cooker, differently from the main (stable) branch, is what it's boiling in the pot now: the bleeding edge of the software development.
Every time a commit or a PR is done, a GitHub action automatically compiles the snapshot with the latest changes and publish them on the [cooker repository](https://github.com/XargonWan/RetroDECK-cooker).
This can be publicly tested and if it's stable will be merged in the main branch creating a new release.

Useless to say that this channel is not suggested for the end user but it's developer / alpha tester oriented.
Expect major bugs and data loss: be warned.

## Build instructions

If you want to build the RetroDECK flatpak on your machine for developing or just testing purposes:

```
cd ~
git clone --recursive https://github.com/XargonWan/RetroDECK.git
cd RetroDECK
git submodule init
git submodule update
```

install `flatpak flatpak-builder p7zip-full` with your distro's package manager, then:

```
flatpak remote-add --if-not-exists Flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y org.kde.Sdk//5.15-21.08 org.kde.Platform//5.15-21.08 io.qt.qtwebengine.BaseApp/x86_64/5.15-21.08 org.freedesktop.Sdk.Extension.llvm13 org.freedesktop.Platform.ffmpeg-full/x86_64/21.08
```

To build the stable release:

```
flatpak-builder --user --install --install-deps-from=flathub --install-deps-from=flathub-beta --force-clean --repo=local ~/RetroDECK/retrodeck-main ~/RetroDECK/net.retrodeck.retrodeck.yml
flatpak build-bundle local ~/RetroDECK.flatpak net.retrodeck.retrodeck
```

Or alternatively, to build the cooker (experimental) release:

```
git checkout cooker
flatpak-builder --user --install --force-clean --repo=local ~/RetroDECK/retrodeck-cooker ~/RetroDECK/net.retrodeck.retrodeck.yml
flatpak build-bundle local ~/RetroDECK.flatpak net.retrodeck.retrodeck
```

## Debug Mode
It's possible to enter in a sort of debug mode, it's actually the flatpak shell.

Enter in the flatpak shell:

```
flatpak run --command=bash net.retrodeck.retrodeck
```

Launch ES-DE in debug mode:

```
emulationstation --debug --home /var/config/emulationstation
```

Launch an emulator in debug mode:

```
ls /app/bin
```
To get the list of the available binaries to launch, then just write the command, such as `yuzu` or `retroarch`

This is useful when for example a game is not starting and you want the output printed in the terminal.

## Manual installation instructions
This method is usually for the beta/cooker testers:
- Download the RetroDECK.flatpak from the [release page](https://github.com/XargonWan/RetroDECK/releases) or from the [cooker release page](https://github.com/XargonWan/RetroDECK-cooker/releases) (be sure to download the correct version, check the date as they're not ordered unfortunately).
- `cd` where the downloded file is located
- `flatpak install RetroDECK.flatpak` or whatever the filename is

If this doesn´t work:
- cd into your download location
- `flatpak install RetroDECK.flatpak`
- Run it from the start menu or, alternatively, from the terminal by typing `flatpak run net.retrodeck.retrodeck`
- Then the first setup will guide you in the first steps, **please read all the messages carefully** as the rom directory must not be edited in EmulationStation

### Updating instructions
- uninstall the previous version with `flatpak uninstall net.retrodeck.retrodeck`
- follow installation instructions
- [OPTIONAL] In case of issues it's suggested to remove `~/.var/app/net.retrodeck.retrodeck` and run `flatpak run net.retrodeck.retrodeck --reset`, but this will reset the application configs, please backup your data.
NOTE: this will not be needed after v`0.4.0b`.

## Managing RetroDECK flatpak file

Install RetroDECK from flatpak file:

```
flatpak install RetroDECK.flatpak
```

Run RetroDECK:

```
flatpak run net.retrodeck.retrodeck
```

Uninstall RetroDECK:

```
flatpak uninstall net.retrodeck.retrodeck
```

## Making your own ES-DE theme
Please check the following link link over ES-DE <br>
[Theme Development ](https://gitlab.com/es-de/emulationstation-de/-/blob/master/THEMES-DEV.md)

