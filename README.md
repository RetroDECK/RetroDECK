<p float="center">
    <img src="https://github.com/XargonWan/RetroDECK/blob/main/res/logo.png?raw=true" alt="RetroDECK logo" width="600"/>
</p>

# RetroDECK

**RetroDECK** brings an enviornment to catalog and play your retro games directly from SteamOS and it's tailored specifically for the **Steam Deck**.

It's inspired from embedded emulation systems like AmberELEC, EmuELEC, CoreELEC, Lakka, and Batocera.

Powered by [EmulationStation Desktop Edition](https://es-de.org), which uses RetroArch and other standalone emulators to allow you to import and play your favorite retro (and even not-so-retro) games in a tidy enviornment without flooding your Steam library.

Join our [Discord](https://discord.gg/Dz3szYsP8g)!
<p float="center">
<img src="https://github.com/XargonWan/RetroDECK/blob/main/res/screenshots/screen03.jpg?raw=true" alt="screenshot" width="300"/>
<img src="https://github.com/XargonWan/RetroDECK/blob/main/res/screenshots/screen04.jpg?raw=true" alt="screenshot" width="300"/><br/>
<img src="https://github.com/XargonWan/RetroDECK/blob/main/res/screenshots/screen01.png?raw=true" alt="screenshot" width="300"/>
<img src="https://github.com/XargonWan/RetroDECK/blob/main/res/screenshots/screen02.png?raw=true" alt="screenshot" width="300"/>
</p>
<br/>

## What does it means "tailored for the Steam Deck"?
Means that all the configurations are ready to go and tweaked to get the best graphics and perfomance on the Deck without having the hassle of choosing, installing and configuring tons of emulators: just put your games in the roms folder, provide your own bioses and start your games.

## Do I have to partition my disk to install it?
No partitioning or formatting is required. RetroDECK (differently from AmberELEC, Batocera and others) comes as a flatpak: just install it as any other application and launch it from your desktop or Steam library. You still retain the ability to return to SteamOS by pressing the Steam button or opening the Quick Access menu while using RetroDECK.

## Is it available on Windows?
No, RetroDECK doesn't support Windows, but the project is fully opensource so you can port it if you wish. As an alternative, [Retrobat](http://www.retrobat.ovh/) offers similar functionality (but may not be compatible with RetroDECK's rom paths).

## Can I help?
Of course, any help is appreciated, and not only byp rogramming, just check out our [Discord](https://discord.gg/Dz3szYsP8g)!
<br/><br/>
# Developer notes: build instructions

If you want to build the RetroDECK flatpak on your machine for developing or just testing purposes:
```
cd ~
git clone --recursive https://github.com/XargonWan/RetroDECK.git
cd RetroDECK
git submodule init
git submodule update
```

install `flatpak flatpak-builder p7zip-full` with your distro's package manager.

```flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y org.kde.Sdk//5.15-21.08 org.kde.Platform//5.15-21.08 io.qt.qtwebengine.BaseApp/x86_64/5.15-21.08 org.freedesktop.Sdk.Extension.llvm13
```

To build the stable release:
```
flatpak-builder --user --install --force-clean --repo=local ~/RetroDECK/retrodeck-main ~/RetroDECK/com.xargon.retrodeck.yml
flatpak build-bundle local ~/RetroDECK.flatpak com.xargon.retrodeck
```

Or alternatively, to build the cooker (experimental) release:
```
git checkout cooker
flatpak-builder --user --install --force-clean --repo=local ~/RetroDECK/retrodeck-cooker ~/RetroDECK/com.xargon.retrodeck.yml
flatpak build-bundle local ~/RetroDECK.flatpak com.xargon.retrodeck
```

Install RetroDECK:
```
flatpak install com.xargon.retrodeck
```

Run RetroDECK:
```
flatpak run com.xargon.retrodeck
```

Uninstall RetroDECK:
```
flatpak uninstall com.xargon.retrodeck
```
