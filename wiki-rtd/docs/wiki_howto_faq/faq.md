# FAQs: Frequently asked questions

What follows is questions and answers to a variety of topics.


## General Questions

### What does the "b" stand for in the versioning number?
It stands for Beta.

<br>

### What is RetroDECK cooker?
 Cooker is a bleeding edge snapshot of the current commits, the action of uploading code to GitHub is called commit.
 As you can understand, the code may not be always reviewed and so the cooker it's unstable by its nature,  it's just suggested to testers or developer to try bleeding edge function or to contribute.

 More info on the pinned post in #💙-i-want-to-help on our [Discord Server](discord.gg/Dz3szYsP8g).
 We don't support the cooker on user side.

#### Why the name cooker? 🍲
 That's what cooking in the pot at this moment and not yet ready to be served (released). This name was also used by Linux Mandrake and Mandriva for the bleeding edge channel.

<br>

### What emulators and software is included in RetroDECK?
Check `General Information 📰` - `RetroDECK: What's included?`

<br>

### Does RetroDECK include any games?
No games are included in RetroDECK.

<br>

### Will you include Open Source games in the future?
We are looking into a ports downloader for a future update.

<br>

### Does RetroDECK include any Firmware or BIOS?
RetroDECK only includes those BIOS and Firmware that are Open Source. All others can never be done for legal reasons.

#### Can you at least point me towards where I find none Open Source: Games, Firmeware or BIOS?
For purchased titles we recommend that you use your own game backups and look into how to extract the Firmware or BIOS from your own consoles.

<br>


## RetroDECK Usage Questions

### Do I have to partition or format my disk/sdcard to install RetroDECK?
 No, partitioning or formatting is not needed at all. RetroDECK (differently from AmberELEC, Batocera and others) comes as a flatpak. Just install it as any other application and launch it from your desktop and/or Steam library.

<br>

### Where is RetroDECK installed?

There are two primary folders:

`~/retrodeck`

- The location of this folder is where you set it during installation.
- This cointains all of the userdata that the users put into RetroDECK like: ROMs, Mods, Texturepacks, Downloaded Content, Themes etc.
- The folder is not deleted during a uninstallation of RetroDECK and must be manually deleted, as all the users valuble files are there.

`~/.var/app/net.retrodeck.retrodeck/`

- This is the main flatpak folder, under the hidden `./var/app/` folder you need to show hidden folders and files to see it.
- This cointains all of the emulators, emulationstation and other settings that make RetroDECK work.
- During uninstallation this folder is removed.

### Can I move the ROMs folder to another place?
 Yes, you can do so inside the configurator and the `Move RetroDECK` option.

<br>

### Is there a way to reset RetroDECK?
 Yes, you can reset various parts of the software using the RetroDECK configurator under the option reset.

 Or you can use CLI arguments in the terminal.

 Resets the whole RetroDECK at factory defaults:
 ```bash
 flatpak run net.retrodeck.retrodeck --reset-all
 ```
 Resets RetroArch configs at factory defaults:
 ```bash
 flatpak run net.retrodeck.retrodeck --reset-ra
 ```
 Resets all the standalone emulators configs at factory defaults:
 ```bash
 flatpak run net.retrodeck.retrodeck --reset-sa
 ```

 <br>

### How do I uninstall RetroDECK?
 **On the Steam Deck:**

Put the Steam Deck into Desktop Mode `Steam button`  `Power`  `Switch to Desktop`

* Go into Discover
* Press the `Installed` tab and find RetroDECK
* Press the `Uninstall` button
* Manually backup then remove the `~\retrodeck` folder. Warning! Make a backup your data roms/bios/saves etc if you want to save them else they will be gone.

<br>

### Does uninstalling RetroDECK remove my roms, bios and saves?
No, as long as you don't manually don't delete the `~\retrodeck` folder and it's content your data is safe. You could uninstall RetroDECK and install it again and keep going.

<br>

### How can I move RetroDECK do a different device like Steam Deck OLED or a new Linux PC?
 Yes, check over at [[How to: Move RetroDECK to a new device](../wiki_howto_faq/retrodeck-move.md)

<br>

### Where can I find the logfiles?
 In `~/retrodeck/logs/retrodeck.log`

<br>

### Can I add a single game to my Steam Library or with Steam Rom Manager?
We are working on this feature. Meanwhile you can achieve this manually.
Example of a launch script to launch to launch a Wii game called Baloon World:

 ```
 flatpak run --command=dolphin-emu-wrapper net.retrodeck.retrodeck -e "/run/media/mmcblk0p1/retrodeck/roms/wii/Baloon World.rvz" -b
 ```

<br>

### After installing RetroDECK manually, Discover is not opening or giving me some errors?
 This bug is appearing only when installing RetroDECK manually and not from Discover. The discover release is suggested for all the users.
However you can run this to fix it: `flatpak remote-delete retrodeck-origin`

<br>



## Feature Requests & Bug Reports

### How to report bugs?

Check `Bugs & Issues 🐜` - `Reporting bugs and issues`

<br>

### Will you implement X/Y/Z emulator?
 Our goal is to implement and configure a selection of the best emulators for each system. If your favorite system is not integrated you can request its integration by opening an issue on this github page.

<br>

### Will you implement none emulator software inside of RetroDECK like Batocera?
 We do have plans for a ports downloader / manager in the future.

<br>

### I have a good idea on a new feature, how do I suggest it?
 Check if the request already exists in the issue list on github, if not you can make a new issue and suggest it.
 If you want to discuss before submitting feel free to post your ideas in our discord community.

<br>



## Updating RetroDECK

<br>



### How do I update RetroDECK?
Updates to RetroDECK is handled automatically via your software manager when there is a new version released.

Or if you want to update from the terminal you can type:
`flatpak update`

<br>

### How do I update a specific emulator in RetroDECK?
You can't in a easy way do that without breaking several things. RetroDECK builds many emulators and add RetroDECK specific features on top of them and makes it into one application. That said we are looking into a custom emulator installation for those that have payed early access versions like Yuzu (that installation will still beore limited then the one we ship with RetroDECK and might have less features then normal Yuzu in term of hotkey support and other things).

<br>

### Do you only ship stable versions of the emulators or nightly versions?
RetroDECK ship the version that is the best for running the games on a case by case basis.

For example: many bleeding edge emulators like Yuzu or RPCS3 it's nightly we ship, but for things like RetroArch it is stable releases.
Even if it is a nightly version we want to make sure that the version we ship is works.

<br>

### When does the next version of RetroDECK come out?
When it's ready.

#### When does the version after the upcoming version come out?
After the upcoming version.

#### When does the version 1.0 of RetroDECK come out?
In the future.

<br>



## Documentation & Wiki

### What is sudo?
The command stands for "superuser do" and in the windows world it is called "run as administrator".
Su in "sudo" refers to the "superuser" or in the windows called the "administrator".

<br>

### Whats the meaning of the ~ character mean in documentation and examples?
The tilde character ~  is the a short way of saying the logged in users home directory in the UNIX world.
 So for example the Steam Deck
```~ = /home/deck```
Read more on [Wikipedia](https://en.wikipedia.org/wiki/Home_directory)

<br>

### Whats the meaning of the SA acronym in documentation and examples?
SA means Standalone and the emulator is not inside RetroArch/LibRetro but a separate program launched within RetroDECK.

<br>

### Whats the meaning of the CLI acronym in documentation and examples?
CLI stands for command-line interface and is often refereed commands you can run in the the Linux Terminal

<br>

## About Other Emulation Solutions

<br>

### Are you related to EmuDeck?
No, the two projects are not related.

<br>

#### So what's the difference between RetroDECK and EmuDeck?
Apart of that from the user point of view EmuDeck and RetroDECK may sound similar but technically they're completely different.

EmuDeck is a shell script that you run in the Steam Decks desktop mode that downloads and configures all the separate emulators & plugins for you from various sources using a built in electron based gui.

RetroDECK is an all-in-one application contained in a sandboxed environment called "flatpak", that is downloaded from Discover (Flathub). This is Valves and other Linux desktops recommended way of distributing applications on the Steam Deck and Linux desktop in a safe way. It grantees for example even if Valve makes major changes to the file system in a SteamOS update, RetroDECK and it’s configurations will not be touched and will be safe.

RetroDECK only writes in these two folders: `~/retrodeck` for roms/configurations/bios etc.. And an hidden flatpak folder located in `~/.var/net.retrodeck.retrodeck`.

As everything is contained within those two folders it will not have conflict if you decide to install an emulator from another source like Yuzu or RetroArch with your RetroDECK setup. Even if you uninstall RetroDECK all your roms/bios/saves/etc.. are safe until you remove the `~/retrodeck` folder. So if you for some reason don't like the application after playing for a while you can easily move out your important files after an uninstall (or you can just reinstall RetroDECK again and start where you left off).

This approach of everything is in a all-in-one package will also allow RetroDECK to do tighter integrations with each bundled emulator in the future and expose all those settings when you are inside RetroDECK, so you do not need to go into Steam Decks desktop mode to do changes and tweaks. All things should be, in the long term, inside the application itself and you can already see a part of that inside the RetroDECK Configurator in the Tools menu.

<br>

#### Can I install RetroDECK if I have EmuDeck already?
Yes, as RetroDECK is completely standalone.

<br>

#### Why create RetroDECK when EmuDeck and other solutions exists?
 RetroDECK is older then EmuDeck, EmuDeck was created later.

<br>

### Are you related anyway to Batocera?
 No, but RetroDECK had some dialog before the project started with some of the Batocera crew if there where any plans to start a Batocera non-OS application (there where no plans at that moment and their focus is to make the best retro gaming operative system). RetroDECK and Batocera also have good dialog together with representatives of each projects inside the internal development channels.

<br>

### Batocera or EmuDeck or RetroDECK I still don't get it?
 - Batocera is a retro emulation operative system that you need to boot into separately (like from an SDCard) or replace your current OS.  For the Steam Deck you lose access to the SteamOS features and your emulation gaming is separate from your SteamOS gamemode gaming. That said; Batocera has many years of development time, is a great mature OS with a lot of features.

 - EmuDeck is a shell script that you download and run. The script downloads & configures all the separate emulators & plugins for you from various sources for various operative systems.

 - RetroDECK is an all-in-one application that already provides everything you need without to many extra steps for the user.It is on Flathub and thus allows the users to update the application via standard safe operative system update methods.
You can see RetroDECK as the in between of EmuDeck and Batocera. We hope that one day we can offer a complete Batocera-like experience right inside your operative system.

<br>

### What is your relationship with EmulationStation Desktop Edition (ES-DE)?
 S-DE and RetroDECK are separate projects, but we collaborate to give the best possible user experience.
We have a unique partnership where inside the ES-DE code is a section just for RetroDECK specific features. 
[Read more on ES-DE FAQs](https://gitlab.com/es-de/emulationstation-de/-/blob/master/FAQ.md#what-is-the-relationship-between-es-de-and-retrodeck)

<br>


## Flatpak Questions

### Retrodeck is a flatpak, what is it?
 [Flaptak](https://docs.flatpak.org/en/latest/introduction.html) is like sandboxed application, with its own read only filesystem that is different from your computer's filesystem. That's why flatpak is safer than installing something directly in your filesystem as everything it needs is contained within the flatpak.


#### How is a flatpak made?
 A flatpak is generated from a manifest file. A software called  flatpak-builder reads the  manifest, then starts downloading dependencies and starts building the software. After the build process is done it generates the software in a .flatpak file. This file can then be hosted on Flathub or distributed on the web.


#### How does the RetroDECK flatpak manifest look like?
 You can find out manifest here:  https://github.com/XargonWan/RetroDECK/blob/main/net.retrodeck.retrodeck.yml

<br>


## Emulation & Games

### Why are games call ROMs?
 ROM stands for "Read Only Memory" and was a common method to store games.
The games where later dumped from their ROM chips into digitalized files that can be played with an emulator.
Read more on [wikipedia](https://en.wikipedia.org/wiki/Read-only_memory)

<br>

### How can I set another default emulator?
 The ES-DE interface allows you to change emulators for systems that has many different emulators.  In the main menu go to `Other Settings` - `Alternative Emulators` to set other defaults.

<br>

### Game X/Y/Z is not working or showing black screen
- Some emulators needs BIOS and/or firmware files, first you can check if you got the `How-to's 💬` - `How to: Manage BIOS and Firmware`.<br/
- You could have bad backups compare them on a database site for example [no-intro](https://datomatic.no-intro.org/index.php?page=search&s=64) or even [RetroAchievements](https://retroachievements.org) if your game is supported.<br/
- Moreover please mind that some emulator require very specific roms `How-to's 💬` - `How to: Manage your Games`

<br>

### PS2 games are not working or buggy in the RetroArch Core.
 It's a known issue with if you are using the libretro core but you can use the the standalone pcsx2 emulator to solve this issue.
 Be sure to check that the bios files are in the correct folder. Read more on the `How-to's 💬` - `How to: Manage BIOS and Firmware`

<br>

### I configured RetroArch but the configuration was not saved.
 Configuring RetroArch can be dangerous for an inexperienced user, so RetroDECK is set to don't save the RetroArch configuration upon exiting.<br/
 The configuration must be saved willingly by going to: `Main Menu` -  `Configuration File` - `Save Current Configuration`.<br/
 If you find some better configurations however, you may contribute by sharing it on the `💙-i-want-to-help` channel on our [Discord Server](discord.gg/Dz3szYsP8g) that may be included in the next version.

<br>

### Will you support Lightguns (Sinden, Gun4IR, Samco etc...)?
 The long term answer is yes, but there are several issues that need to be addressed from various dependencies that are beyond the scope of what RetroDECK can do by it self. We are talking to several projects and hope to have those issues addressed in the future. Right now the best way to use lightgun hardware is to use Batocera as they have developed native support in their OS.

<br>

## Emulation on the Steam Deck

<br>

### Can I launch RetroDECK from inside of the Steam Decks gamemode?
 Yes, RetroDECK currently only supports Steam Deck's gamemode as it relies on Steam Controller configs.
 To add it into Steam please check the second step of `Steam Deck 🕹️` - `Steam Deck - Installation and Updates`.

<br>

### XBOX games are slow on the Steam Deck
 Unfortunately on thanks to missing optimizations focusing on the Steam Deck and the hardware is limited in scope makes performance not great. Like most emulators they will get improvements over time and we will follow the XBOX emulators progress with great interest.

<br>

### The games are stuck at 30FPS on the Steam Deck!
 Press the [...] button on the Steam Deck, go into the Power menu and see if the Framerate Limit is set to 30FPS and set it to 60FPS or off.

<br>

### Fast forwarding is slow on the Steam Deck!
 Same as above: Check the Power menu Framerate Limit.

<br>

### Some emulators run slow when I got my Steam Deck docked to a 4k, 8k or above resolution monitor.
 The Steam Deck does not have the power to play all the games in those high resolutions with a stable framerate. What you could do is go into desktop mode while docked and lower the resolution of the display to 1080p or 720p then return to gamemode.

<br>



## Emulationstation-DE: Themes

### How can I add more themes?
 ES-DE comes with a built in Theme Downloader `UI Settings  Theme Downloader`. But you can also add themes manually in the: `~/retrodeck/themes` folder.

<br>

### How do you switch between themes inside of RetroDECK?
 You can switch between them by open the menu and then navigate to `UI Settings  Theme Set` to select the theme you want to use.

<br>

### "Why does the theme I am using not work?" or "Why does the layout look broken?" (black screen with blue text)?
 * Please make sure you are specifically using a theme that is compatible with [ES-DE](https://www.es-de.org).

 * If you are trying to use a theme that was built for Batocera it will likely not be compatible.

 * ES-DE uses a unique theme engine so themes are not directly portable from Batocera.

 * Please see ES-DE's EmulationStation-DE Guide 📘 for more details.

 <br>

### Why does the theme layout look squished?
 * The Steam Deck has a screen aspect ratio of `16:10` and most themes that you will find are built for an aspect ratio of `16:9`.  Depending on the theme's design this may cause the layout to appear squished when using it on the Steam Deck's display.

 * All of the included themes are built for 16:10 aspect ratio so you should not see this issue with any of them; however if you are downloading a theme from another source there is a chance this can occur for you.

 * There are 2 ways to fix this if it does occur: (1) see if a specific version was built for `16:10` aspect ratio and use that instead or (2) edit the theme to make it compatible with that aspect ratio.

<br>



## Emulationstation-DE: Scraping

### Can I manually add custom game images/videos/media for games that I can not scrape?
 Yes, check the file structure over at Emulationstation DE's user guide on gitlab.
[Manually copying game media files](https://gitlab.com/es-de/emulationstation-de/-/blob/master/USERGUIDE.md#manually-copying-game-media-files)

<br>

### Where is my scraped data?
 In: `~/retrodeck/downloaded_media` folder.

<br>

### I got some weird error message about quota after scraping!
The error message mentions something about quota. You have a quota limit on how much you can scrape each day from [Screenscraper.fr ](https://www.screenscraper.fr/) where each item you scrape counts as 1 quota of the daily total.
You can pay them to get a bit more daily quota and show your support or just wait 24 hours.

<br>

### The Scraper said: The Server or Service is down?
The service is down, check [Screenscraper]](https://www.screenscraper.fr/) when they get back up.

<br>

### Can I only scrape one game or can I narrow down the scraping method?
Yes, check the [[EmulationStation DE: User Guide]] for more details.

<br>

### Can I move the downloaded_media folder?
 You can move it with the the move RetroDECK option inside the configurator.

<br>

### Can I copy the downloaded_media folder to another device?
 Yes, just copy it into the other device RetroDECK folder.

<br>

### The scraping is very slow...
[Screenscraper]](https://www.screenscraper.fr/) offers different types of donations that can increase your speed with extra threads.

<br>

### My systems storage ran out after scraping...
 You can clean out images and videos that takes a lot of space under: `~/retrodeck/downloaded_media`.

#### But I still want them...
 The only way to still keep them is either delete something else from the storage or buy more storage.

<br>
