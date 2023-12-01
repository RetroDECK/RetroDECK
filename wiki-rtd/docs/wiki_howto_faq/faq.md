# FAQs: Frequently asked questions

What follows is questions and answers to a variety of topics.

<br>
## General Questions

### What is the scope of this project?
<details><summary>Click here to see the answer</summary>

Read the "Whats the long term vision and goals" on the Home page of this wiki.

</details>

### What is RetroDECK cooker?
<details><summary>Click here to see the answer</summary>

 Cooker is a bleeding edge snapshot of the current commits, the action of uploading code to GitHub is called commit.<br/>
As you can understand, the code may not be always reviewed and so the cooker it's unstable by its nature, it's just suggested to testers or developer to try bleeding edge function or to contribute.<br/>

More info on the pinned post in #💙-i-want-to-help on our [Discord Server](discord.gg/Dz3szYsP8g).
I don't support the cooker user side.

</details>

#### Why the name cooker? 🍲
<details><summary>Click here to see the answer</summary>

That's what cooking in the pot at this moment and not yet ready to be served (released).<br> This name was also used by Linux Mandrake and Mandriva for the bleeding edge channel.

</details>

### What emulators and software is included in RetroDECK?
<details><summary>Click here to see the answer</summary>

RetroDECK comes with:

* Emulationstation Desktop Edition - RetroDECK version
* The RetroDECK Framework
* The RetroDECK Configurator
* For emulators and other software check the RetroDECK: What's included? section of this wiki.

We plan to have support for all of the the different systems ES-DE support in the long term. But the goal is only to have the best emulator per system and not every emulator in existence.

</details>

### Does RetroDECK include any games?
<details><summary>Click here to see the answer</summary>
No games are included in RetroDECK currently.
</details>

### Will you include Open Source games in the future as default?
<details><summary>Click here to see the answer</summary>
We are looking into a ports downloader for a future update.
</details>

### Does RetroDECK include any Firmware or BIOS?
<details><summary>Click here to see the answer</summary>
RetroDECK only includes those BIOS and Firmware that are Open Source. All others can never be done for legal reasons.
</details>

#### Can you at least point me towards where I find none Open Source: Games, Firmeware or BIOS?
<details><summary>Click here to see the answer</summary>
For purchased titles we recommend that you use your own game backups and look into how to extract the Firmware or BIOS from your own consoles.
</details>

<br>

## Flatpak Questions

### Retrodeck is a flatpak, what is it?

<details><summary>Click here to see the answer</summary>

[Flaptak](https://docs.flatpak.org/en/latest/introduction.html) is like sandboxed application, with its own read only filesystem that is different from your computer's filesystem. That's why flatpak is safer than installing something directly in your filesystem as everything it needs is contained within the flatpak.
</details>

#### How is a flatpak made?
<details><summary>Click here to see the answer</summary>
A flatpak is generated from a manifest file. A software called  flatpak-builder reads the  manifest, then starts downloading dependencies and starts building the software. After the build process is done it generates the software in a .flatpak file. This file can then be hosted on Flathub or distributed on the web.
</details>

#### How does the RetroDECK flatpak manifest look like?
<details><summary>Click here to see the answer</summary>
You can find out manifest here:  https://github.com/XargonWan/RetroDECK/blob/main/net.retrodeck.retrodeck.yml
</details>


<br>

<!--  -->

## Using RetroDECK


### Do I have to partition or format my disk/sdcard to install RetroDECK?

<details><summary>Click here to see the answer</summary>

No, partitioning or formatting is not needed at all. RetroDECK (differently from AmberELEC, Batocera and others) comes as a flatpak. Just install it as any other application and launch it from your desktop and/or Steam library.
</details>


### Can I move the ROMs folder to another place?
<details><summary>Click here to see the answer</summary>

Yes, you can do so inside the configurator and the `Move RetroDECK` option.

</details>

### Is there a way to reset RetroDECK?
<details><summary>Click here to see the answer</summary>

Yes, you can reset various parts of the software using the RetroDECK configurator under the option reset<br/>

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
</details>


### How do I uninstall RetroDECK?
<details><summary>Click here to see the answer</summary>

**On the Steam Deck:**<br>

Put the Steam Deck into Desktop Mode `Steam button` > `Power` > `Switch to Desktop`<br>

* Go into Discover
* Press the `Installed` tab and find RetroDECK
* Press the `Uninstall` button
* Manually backup then remove the ~\RetroDECK folder. Warning! Make a backup your data roms/bios/saves etc if you want to save them else they will be gone.

</details>


### Does uninstalling RetroDECK remove my roms, bios and saves?
<details><summary>Click here to see the answer</summary>
No, as long as you don't manually don't delete the ~\RetroDECK folder and it's content your data is safe. You could uninstall RetroDECK and install it again and keep going.

</details>

### How can I move RetroDECK do a different device like Steam Deck OLED or a new Linux PC?
<details><summary>Click here to see the answer</summary>

Yes, check over at [[How to: Move RetroDECK to a new device]]

</details>

### Where can I find the logfiles?
<details><summary>Click here to see the answer</summary>
> In `~/retrodeck/logs/retrodeck.log`

</details>

### Can I add a single game to my Steam Library or with Steam Rom Manager?
<details><summary>Click here to see the answer</summary>

Not yet but might be in the future, it is technical possible but quite complicated and needs to be done via launch script. We hope we can simplify this in the future via an API call or inside the Configurator.
Example of a launch script to launch to launch a Wii game called Baloon World:

`flatpak run --command=dolphin-emu-wrapper net.retrodeck.retrodeck -e "/run/media/mmcblk0p1/retrodeck/roms/wii/Baloon World.rvz" -b `

</details>

### If I installed RetroDECK from outside of discover, do I need to uninstall the application to update?
<details><summary>Click here to see the answer</summary>
If you previously installed from outside of Discover, you can find the instructions here to

[install from discover](https://github.com/XargonWan/RetroDECK/wiki/Steam-Deck:-Installation-and-updates)

or here

[to install .flatpak file](https://github.com/XargonWan/RetroDECK/wiki/Developer-notes#managing-retrodeck-flatpak-file).</details>

### After installing RetroDECK manually, Discover is not opening or giving me some errors?
<details><summary>Click here to see the answer</summary>

This bug is appearing only when installing RetroDECK manually and not from Discover. The discover release is suggested for all the users.
However you can run this to fix it: `flatpak remote-delete retrodeck-origin`

</details>

<br>

## Feature Requests& & Bug Reports

### Will you implement X/Y/Z emulator?
<details><summary>Click here to see the answer</summary>

Our goal is to implement and configure a selection of the best emulators for each system. If your favorite system is not integrated you can request its integration by opening an issue on this github page.

</details>

### Will you implement none emulator software inside of RetroDECK like Batocera?
<details><summary>Click here to see the answer</summary>
We do have plans for a ports downloader / manager in the future.
</details>

### I have a good idea on a new feature, how do I suggest it?
<details><summary>Click here to see the answer</summary>
Check if the request already exists in the issue list on github, if not you can make a new issue and suggest it.
If you want to discuss before submitting feel free to post your ideas in our discord community.
</details>

<br>
## Updating RetroDECK

### What does the "b" stand for in the versioning number?
<details><summary>Click here to see the answer</summary>
It stands for Beta.
</details>

### How do I update RetroDECK?
<details><summary>Click here to see the answer</summary>
Updates to RetroDECK is handled automatically via your software manager when there is a new version released.

Or if you want to update from the terminal you can type: <br>
`flatpak update`
</details>


### How do I update a specific emulator in RetroDECK?
<details><summary>Click here to see the answer</summary>
You can't in a easy way do that without breaking several things. RetroDECK builds many emulators and add RetroDECK specific features on top of them and makes it into one application. That said we are looking into a custom emulator installation for those that have payed early access versions like Yuzu (that installation will still be more limited then the one we ship with RetroDECK and might have less features then normal Yuzu in term of hotkey support and other things).
</details>

### Do you only ship stable versions of the emulators or nightly versions?
<details><summary>Click here to see the answer</summary>
RetroDECK ship the version that is the best for running the games on a case by case basis.

For example: many bleeding edge emulators like Yuzu or RPCS3 it's nightly we ship, but for things like RetroArch it is stable releases. <br>
Even if it is a nightly version we want to make sure that the version we ship is works.
</details>

### When does the next version of RetroDECK come out?
<details><summary>Click here to see the answer</summary>
When it's ready.

</details>

#### When does the version after the upcoming version come out?
<details><summary>Click here to see the answer</summary>

After the upcoming version.</details>

#### When does the version 1.0 of RetroDECK come out?
<details><summary>Click here to see the answer</summary>

In the future.

</details>


<br>
## Documentation & Wiki

### What is sudo?
<details><summary>Click here to see the answer</summary>
The command stands for "superuser do" and in the windows world it is called "run as administrator".
Su in "sudo" refers to the "superuser" or in the windows called the "administrator".

</details>

### Whats the meaning of the ~ character mean in documentation and examples?
<details><summary>Click here to see the answer</summary>

The tilde character ~  is the a short way of saying the logged in users home directory in the UNIX world.<br>

So for example the Steam Deck<br>

`~ = /home/deck`<br>

Read more on [Wikipedia](https://en.wikipedia.org/wiki/Home_directory)</details>

### Whats the meaning of the SA acronym in documentation and examples?
<details><summary>Click here to see the answer</summary>

SA means Standalone and the emulator is not inside RetroArch/LibRetro but a separate program launched within RetroDECK. </details>

### Whats the meaning of the CLI acronym in documentation and examples?
<details><summary>Click here to see the answer</summary>
CLI stands for command-line interface and is often refereed commands you can run in the the Linux Terminal </details>

<br>
## About Other Emulation Solutions

### Are you related to EmuDeck?
<details><summary>Click here to see the answer</summary>

No, the two projects are not related.

</details>

#### So what's the difference between RetroDECK and EmuDeck?
<details><summary>Click here to see the answer</summary>

Apart of that from the user point of view EmuDeck and RetroDECK may sound similar but technically they're completely different.

EmuDeck is a shell script that you run in the Steam Decks desktop mode that downloads and configures all the separate emulators & plugins for you from various sources using a built in electron based gui.

RetroDECK is an all-in-one application contained in a sandboxed environment called "flatpak", that is downloaded from Discover (Flathub). This is Valves and other Linux desktops recommended way of distributing applications on the Steam Deck and Linux desktop in a safe way. It grantees for example even if Valve makes major changes to the file system in a SteamOS update, RetroDECK and it’s configurations will not be touched and will be safe.

RetroDECK only writes in these two folders: `~/retrodeck` for roms/configurations/bios etc.. And an hidden flatpak folder located in `~/.var/net.retrodeck.retrodeck`.

As everything is contained within those two folders it will not have conflict if you decide to install an emulator from another source like Yuzu or RetroArch with your RetroDECK setup. Even if you uninstall RetroDECK all your roms/bios/saves/etc.. are safe until you remove the `~/retrodeck` folder. So if you for some reason don't like the application after playing for a while you can easily move out your important files after an uninstall (or you can just reinstall RetroDECK again and start where you left off).

This approach of everything is in a all-in-one package will also allow RetroDECK to do tighter integrations with each bundled emulator in the future and expose all those settings when you are inside RetroDECK, so you do not need to go into Steam Decks desktop mode to do changes and tweaks. All things should be, in the long term, inside the application itself and you can already see a part of that inside the RetroDECK Configurator in the Tools menu.

</details>

#### Can I install RetroDECK if I have EmuDeck already?
<details><summary>Click here to see the answer</summary>

Yes, as RetroDECK is completely standalone.

 </details>


#### Why create RetroDECK when EmuDeck and other solutions exists?
<details><summary>Click here to see the answer</summary>

RetroDECK is older then EmuDeck, EmuDeck was created later.

 </details>

### Are you related anyway to Batocera?
<details><summary>Click here to see the answer</summary>
No, but RetroDECK had some dialog before the project started with some of the Batocera crew if there where any plans to start a Batocera non-OS application (there where no plans at that moment and their focus is to make the best retro gaming operative system). RetroDECK and Batocera also have good dialog together with representatives of each projects inside the internal development channels.

</details>


### Batocera or EmuDeck or RetroDECK I still don't get it?
<details><summary>Click here to see the answer</summary>

- Batocera is a retro emulation operative system that you need to boot into separately (like from an SDCard) or replace your current OS. <br> For the Steam Deck you lose access to the SteamOS features and your emulation gaming is separate from your SteamOS gamemode gaming. That said; Batocera has many years of development time, is a great mature OS with a lot of features.

- EmuDeck is a shell script that you download and run. The script downloads & configures all the separate emulators & plugins for you from various sources for various operative systems.

- RetroDECK is an all-in-one application that already provides everything you need without to many extra steps for the user.It is on Flathub and thus allows the users to update the application via standard safe operative system update methods.
You can see RetroDECK as the in between of EmuDeck and Batocera. We hope that one day we can offer a complete Batocera-like experience right inside your operative system.

</details>

### What is your relationship with EmulationStation Desktop Edition (ES-DE)?<br>
<details><summary>Click here to see the answer</summary>

ES-DE and RetroDECK are separate projects, but we collaborate to give the best possible user experience.<br>
We have a unique partnership where inside the ES-DE code is a section just for RetroDECK specific features. <br>
[Read more on ES-DE FAQs](https://gitlab.com/es-de/emulationstation-de/-/blob/master/FAQ.md#what-is-the-relationship-between-es-de-and-retrodeck)

 </details>

<br>

## Emulation & Games

### Why are games call ROMs?
<details><summary>Click here to see the answer</summary>

ROM stands for "Read Only Memory" and was a common method to store games.<br>
The games where later dumped from their ROM chips into digitalized files that can be played with an emulator.<br>
Read more on [wikipedia](https://en.wikipedia.org/wiki/Read-only_memory)

</details>


### How can I set another default emulator?

<details><summary>Click here to see the answer</summary>

The ES-DE interface allows you to change emulators for systems that has many different emulators.  In the main menu go to `Other Settings` - `Alternative Emulators` to set other defaults.
</details>


### Game X/Y/Z is not working or showing black screen
<details><summary>Click here to see the answer</summary>

Some emulators needs BIOS and/or firmware files, first you can check if you got the [needed ones](https://github.com/XargonWan/RetroDECK/wiki/BIOS-&-Firmware).<br/>

Then you can check if your got a bad dump by comparing your hash with the ones of the official lists on the internet, such as [no-intro](https://datomatic.no-intro.org/index.php?page=search&s=64) or even [RetroAchievements](https://retroachievements.org) if your game is supported.<br/>
Moreover please mind that some emulator require very specific roms, please [read here](https://github.com/XargonWan/RetroDECK/wiki/How-to:-Manage-your-games#special-roms-formats).
If it still not working you are welcome to ask for support on our [Discord Server](discord.gg/Dz3szYsP8g).

</details>

### PS2 games are not working or buggy in the RetroArch Core.
<details><summary>Click here to see the answer</summary>

It's a known issue with if you are using the libretro core but you can use the the standalone pcsx2 emulator to solve this issue.<br>
Be sure to check that the bios files are in the correct folder. Read more on the [Emulators: BIOS and Firmware](https://github.com/XargonWan/RetroDECK/wiki/Emulators%3A-BIOS-and-Firmware)#  page on this wiki.

</details>

### I configured RetroArch but the configuration was not saved.
<details><summary>Click here to see the answer</summary>

Configuring RetroArch can be dangerous for an inexperienced user, so RetroDECK is set to don't save the RetroArch configuration upon exiting.<br/>
The configuration must be saved willingly by going to: `Main Menu` ->  `Configuration File` -> `Save Current Configuration`.<br/>
If you find some better configurations however, you may contribute by sharing it on the #💙-i-want-to-help channel on our [Discord Server](discord.gg/Dz3szYsP8g) that may be included in the next version.

</details>

### Will you support Lightguns (Sinden, Gun4IR, Samco etc...)?
<details><summary>Click here to see the answer</summary>

The long term answer is yes, but there are several issues that need to be addressed from various dependencies that are beyond the scope of what RetroDECK can do by it self. We are talking to several projects and hope to have those issues addressed in the future. Right now the best way to use lightgun hardware is to use Batocera as they have developed native support in their OS.

</details>

<br>

## Emulation on the Steam Deck

### Can I launch RetroDECK from inside of the Steam Decks gamemode?
<details><summary>Click here to see the answer</summary>
Yes, RetroDECK currently only supports Steam Deck's gamemode as it relies on Steam Controller configs. <br>
To add it into Steam please check the second step of [[Steam Deck: Installation and updates]].

</details>

### XBOX games are slow on the Steam Deck
<details><summary>Click here to see the answer</summary>

Unfortunately on thanks to missing optimizations focusing on the Steam Deck and the hardware is limited in scope makes performance not great. Like most emulators they will get improvements over time and we will follow the XBOX emulators progress with great interest.

</details>

### The games are stuck at 30FPS on the Steam Deck!
<details><summary>Click here to see the answer</summary>

Press the [...] button on the Steam Deck, go into the Power menu and see if the Framerate Limit is set to 30FPS and set it to 60FPS or off.

</details>

### Fast forwarding is slow on the Steam Deck!
<details><summary>Click here to see the answer</summary>

Same as above: Check the Power menu Framerate Limit.

</details>

### Some emulators run slow when I got my Steam Deck docked to a 4k, 8k or above resolution monitor.
<details><summary>Click here to see the answer</summary>

The Steam Deck does not have the power to play all the games in those high resolutions with a stable framerate. What you could do is go into desktop mode while docked and lower the resolution of the display to 1080p or 720p then return to gamemode.

</details>

<br>

## Emulationstation-DE: Themes

### How can I add more themes?
<details><summary>Click here to see the answer</summary>
ES-DE comes with a built in Theme Downloader. But you can also add themes manually in the: ~/retrodeck/themes folder.

</details>

### How do you switch between themes inside of RetroDECK?
<details><summary>Click here to see the answer</summary>

You can switch between them by open the menu and then navigate to `UI Settings > Theme Set` to select the theme you want to use.

</details>

### "Why does the theme I am using not work?" or "Why does the layout look broken?" (black screen with blue text)?
<details><summary>Click here to see the answer</summary>

* Please make sure you are specifically using a theme that is compatible with [ES-DE](https://www.es-de.org). <br>

* If you are trying to use a theme that was built for Batocera it will likely not be compatible.<br>

* ES-DE uses a unique theme engine so themes are not directly portable from Batocera. <br>

* Please see ES-DE's [User Guide](https://gitlab.com/es-de/emulationstation-de/-/blob/master/USERGUIDE.md#themes) for more details.

</details>


### Why does the theme layout look squished?
<details><summary>Click here to see the answer</summary>

* The Steam Deck has a screen aspect ratio of `16:10` and most themes that you will find are built for an aspect ratio of `16:9`.  Depending on the theme's design this may cause the layout to appear squished when using it on the Steam Deck's display. <br>

* All of the included themes are built for 16:10 aspect ratio so you should not see this issue with any of them; however if you are downloading a theme from another source there is a chance this can occur for you. <br>

* There are 2 ways to fix this if it does occur: (1) see if a specific version was built for `16:10` aspect ratio and use that instead or (2) edit the theme to make it compatible with that aspect ratio.

</details>

<br>

## Emulationstation-DE: Scraping

### Can I manually add custom game images/videos/media for games that I can not scrape?
<details><summary>Click here to see the answer</summary>
Yes, check the file structure over at Emulationstation DE's user guide on gitlab.<br>

### [Manually copying game media files](https://gitlab.com/es-de/emulationstation-de/-/blob/master/USERGUIDE.md#manually-copying-game-media-files)

</details>

### Where is my scraped data?
<details><summary>Click here to see the answer</summary>
In: ~/retrodeck/downloaded_media folder.
</details>


### I got some weird error message about quota after scraping!
<details><summary>Click here to see the answer</summary>

The error message mentions something about quota. You have a quota limit on how much you can scrape each day from [Screenscraper.fr ](https://www.screenscraper.fr/) where each item you scrape counts as 1 quota of the daily total.<br>
You can pay them to get a bit more daily quota and show your support or just wait 24 hours.<br>
</details>

### The Scraper said: The Server or Service is down?
<details><summary>Click here to see the answer</summary>

The service is down, check https://www.screenscraper.fr/ when they get back up.

</details>

### Can I only scrape one game or can I narrow down the scraping method?
<details><summary>Click here to see the answer</summary>
Yes, check the [[EmulationStation DE: User Guide]] for more details.
</details>

### Can I move the downloaded_media folder?
<details><summary>Click here to see the answer</summary>

You can move it with the the move RetroDECK option inside the configurator.
</details>

### Can I copy the downloaded_media folder to another device?
<details><summary>Click here to see the answer</summary>

Yes, just copy it into the other device RetroDECK folder.
</details>

### The scraping is very slow...
<details><summary>Click here to see the answer</summary>

https://www.screenscraper.fr/ offers different types of donations that can increase your speed with extra threads.

</details>

### My systems storage ran out after scraping...
<details><summary>Click here to see the answer</summary>

You can clean out images and videos that takes a lot of space under: <br>
~/retrodeck/downloaded_media

</details>

#### But I still want them...
<details><summary>Click here to see the answer</summary>

The only way to still keep them is either delete something else from the storage or buy more storage.
</details>


