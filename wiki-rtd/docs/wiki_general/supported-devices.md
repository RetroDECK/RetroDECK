# What devices/systems does RetroDECK currently support?

RetroDECK currently supports two systems:

- Steam Deck itself
- Other SteamOS devices
- The Linux Desktop

## Steam Deck LCD/OLED
Supported from the beginning. RetroDECK is tailored to the Steam Deck.

## Other SteamOS devices
Hence there are no any other devices that are coming with SteamOS at the moment of writing, it's in the plan of Valve to distribute this OS and make it available to the hardware manifacturers and users.
We plan to fully support the OS itself, about the single hardware it will be decided on a case by case basis on what level of support we can offer.

## Linux Desktop
It is working, but the user experience might not be that great it as we want it to be just yet.
You will also need to manually configure the input to match your desktop and might need to tweak more settings. If you want to try it make sure that your distribution has flatpak support (else you will need to install it).

## Q&A Supported Systems

### Will you support Windows or Windows based devices like the ROG Ally?
No, RetroDECK doesn't support Windows currently and there are no plans to do so.
As an alternative you could try [RetroBat](https://www.retrobat.ovh) that offers similar functionality in a Windows environment.
How ever if you install a Linux distribution on your device instead you can try out RetroDECK.

### Will you support ARM devices like iOS or MacOS?
ARM devices are not supported currently. ES-DE does support the ARM emulators but it is a very different landscape.
It would be a major undertaking but maybe one day in the far off future it could be possible. But it would need to be a different experience as the emulators, other underlying systems would not be the same and would need to be rewritten.

### Will you support Android?
We believe that is not really possible to bundle and preconfigure external emulators on Android unfortunately.

### Will you support other distribution methods usch as Snap or AppImage?
It's not in our roadmap yet as now the entire buildsystem is based on the flatpak-build that builds the software via flatpak manifest.
In the past we evaluated to migrate to **Buildstream** (or similar) to build in multiple output format, but the team is not large enough to migrate and maintain other distribution methods, so we prefer to focus our effort on Flatpak only.
If someone wishes to take charge of this we are open to discuss it.

