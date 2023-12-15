---
date: 2023-11-23
---

**Please note that this was written for Lemmy/Reddit and copied over to the new RetroDECK Wiki**

Hello community!

We in the team thought we could give you a quick status update on how development is going.

If you don’t know what RetroDECK is or want more information check out the wiki.

# Status update 2023-11:

It is the end of November and we want to give you a status update on  how things are going with RetroDECK. First off development is going  steady, and we have a lot of features in the pipeline but also some IRL  things that slow us down a bit (work, new baby etc…). But let us talk  about what we are working on and answer some questions.

<!-- more -->

**Note:**

Most listed here are subject to change and is just an outline of what  we are working on right now. Not all of these features will be a part  of 0.8b and we are also working on even more stuff than what we are  showing in this post.

##

## Question: How do I move RetroDECK to a new device?

You can find a detailed step-for-step guide here for both Linux Desktop and Steam Deck:

[How to: Move RetroDECK](https://github.com/XargonWan/RetroDECK/wiki/How-to%3A-Move-RetroDECK-to-a-new-device)

**For a ultra-quick guide:**



* Just copy the \~/retrodeck folder to the new device to the location you want it.
* Install RetroDECK on the new device and point to it the new location of \~/retrodeck during first setup:
   * If you put it on the internal drive – choose that option
   * If you put it on the sd card – choose that option.
   * If you put it in a custom location – choose that option.
* Then proceed installation as normal.



# What are you working on?

## New Emulators/Systems

We will be trying to include all of these in the next big update 0.8b



* OpenBOR
* IkemenGO (M.U.G.E.N)
* Solarus
* MAME (Standalone)
* Ryujinx
* SCUMMVM (Standalone)
* Vita3K
* GZDoom (Standalone)

We have worked with several of the development teams of the emulators  to add various functions we could use and improve the emulators for  everyone regardless of whether you use RetroDECK or not. They have also  worked with us to help us integrate into RetroDECK better. We want to  give special thanks to the Vita3K Team and Ryujinx Team.

## New Feature: Yuzu (Custom)

Yuzu (Custom) is something we are working on for those that want to  use the Early Access version of Yuzu. So, you will get the ability to  run the EA .appimage version from inside RetroDECK in some fashion.

But the downside is that it will not fully hook into the RetroDECK  Framework, so you will need to configure things like input manually the  first time you run it.  But the goal is you can select it in the  alternative emulator selector in ES-DE and pick Yuzu (Custom) from the  list.

## New Feature: Steam Flatpak version support

We have gotten feedback that users want us to support the Steam  Flatpak version and are trying to make it happen. Examples of features  that need to work are the “Controller Profiles”, “Add RetroDECK to  Steam” and the “Add games to Steam” function. We are still not sure if  everything will work as intended in the Flatpak version of Steam.

If you for some reason have both normal Steam and flatpak Steam  installed on the same system. The none flatpak version will take  preference over the flatpak version (this is also how projects like  Lutris do things).

But running a flatpak within a flatpak is something the users will need to think about.If the users want RetroDECK and other flatpaks to run from Steam they  will need to open the permissions in the sandbox from either terminal or  Flatseal. This does open the sandbox more than the standard  configuration that Steam comes with as default.

## New Feature: SFTP

We are looking into letting users enabling SFTP transfers for easy transfers of files (roms, saves etc…).

## New Feature: Cloud Sync

We have done some work cloud sync both live sync and backup to various cloud services. But nothing to show just yet.

## New Feature: USB Transfer / Backups

Like SFPT, Cloud Sync above will be another way to export import files but via USB.

## Status update: External Controllers & Inputs



* PS3
* PS4
* PS5
* Xbox360
* Xbox One / S / X
* Switch Pro
* Steam Controller
* Generic

All standard type controllers supported by Steam Input will work with  the normal global hotkeys. We are also changing the layout so that you  have even more hotkeys.

If you want to try them right now, you can do that by going into the  following github issue and follow the instructions over there (they also  work on current stable, just extract the zipfile in the correct folder  and enjoy):

[Github Issue with Download](https://github.com/XargonWan/RetroDECK/issues/573)

## Status update: Multiuser mode

We are still working on it with all the complexity. The goal is to  support both Steam users from the Steam Deck and local RetroDECK users  for desktop users. It does “work” right now in our cooker builds, but it  still needs more time in the oven. There are a lot of variables to  account for before we feel ready to ship it to everyone.

## Status update: Adding RetroDECK games as Steam Entries

We are still working on it and have it working on our cooker builds.  But we are still trying to get it to work on the Steam Flatpak version.  There are also some other ideas we want to try to make it even better,  but more of them if we can make them happen in a later development  update.

## Status update: Configurator GODOT version

The work is ongoing and not something that will be part of 0.8b. We  have general plans for the GUI and internal versions we can play with.  But the goal stays the same replace the entire configurator with a nice  GODOT controller navigational interface and replace all the Zenity  windows with it.

## Status update: Mascot

After the last development update, we got connected with Tyson Tan  the artist behind both the KDE and Krita mascots. We are hopeful we can  work something out together.

# That is all for now!

Also there will be no December update post thanks to the upcoming holidays!

To everyone out there in our community, we want to wish you a festive holiday period and a Happy New Year.



**Want to contribute to RetroDECK?**

We are always looking for more people to help us with the project.

· Developers (help us improve RetroDECK and get updates out faster).

· Website developer (to help us improve our website).

· Video Editor (to help us with patch notes / hype videos on various platforms).



**Check out our:**

[Discord](https://discord.gg/Dz3szYsP8g)

[Github](https://github.com/XargonWan/RetroDECK)

[Wiki](https://github.com/XargonWan/RetroDECK/wiki)

[Donations](https://github.com/XargonWan/RetroDECK/wiki/Misc%3A-Donations-%26-Licenses)
