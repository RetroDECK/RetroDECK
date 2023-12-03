# Known issues
What follows is a list of knows issues.
For a list of reported bugs please check here on github: [RetroDECK issues](https://github.com/XargonWan/RetroDECK/issues/)

## Big issues
- `RetroArch: ScummVM` Does not work. RetroArch forgot or removed the ScummVM core on the 16.00 release on their build server. This has been reported to LibreRetro by the RetroDECK team on 18-11-23.

## Minor issues
- `PPSSPP` Retroachievements is in the latest version, you can login / logout / enable hardcore mode normally from the emulators interface. It is right now not configurable in the Configurator (as it works a bit different the other emulators), we hope to have a solution for it at a later date.
- `RetroArch: Gambatte` Quitting the core with the `Quit` radial function makes the core swap the palette while playing GB.
- `RetroArch` Borders are in some few cases disappearing in the latest RetroArch version. A possible workaround is to reset RetroArch from the Configurator.

## Hotkey and Controller Issues

**Not all Emulators has hotkey support; some have partial support, some has none and some has a majority implemented**

The plan is to map as much as we can into the RetroDECK Hotkey System below. We are also patching in Emulator Hotkeys with the `RetroDECK Framework` (if possible) to be compatible with the system. If a emulators later versions adds better hotkey support we plan to map it towards the same functions bellow for a unified experience across as many emulators as possible.

### Emulator Issues
* `PPSSPP` has a bug in with multi-input hotkeys in their flatpak version, so we did a workaround and bound ESC is Open Menu. This allows you to access all of the emulator features and can quit.
* `RPCS3` hotkeys/shortcuts do not work and they are a new experimental feature. To exit you have to shut down RPCS3 from the `Switch Window` inside the Steam Deck interface.
* `CEMU` has almost no hotkey support.
* `XEMU` has no hotkey support.
*  `Citra` is the only dual-screen emulator that allows a hotkey for changing the screen layout, others: `MelonDS`, `RetroArch`, `Cemu` has no hotkey for it.

# Missing Features
We are working on implementing all of these features over the big releases. Some will take longer time then others and we will also add more things to this list when needed.

**Missing features:**

* Cloud sync
* USB transfer
* STFP
* Better External controller support.
* Better gyro support.
* Dynamic external display resolution support for borders and viewports.
* All Systems supported by ES-DE so there at least is one emulator per system.
* A rebuilt Configurator that is a Godot application that support controller navigation.
* A rebuilt First Run installer in Godot.
* Better art: Mascot, Easter Eggs, Logos.
* A profile system and multi-user system.



