---
date: 2023-06-01
---

**Please note that this was written for Lemmy/Reddit and copied over to the new RetroDECK Wiki**

Hello community!

We in the team thought we could give you a quick status update on how development is going.

Github link if you don't know what the project is: [https://github.com/XargonWan/RetroDECK](https://github.com/XargonWan/RetroDECK)


# Status update 2023-06:

With 0.7b and summer just around the corner we in the team thought this month we should focus more on a mix of topics.

<!-- more -->

### Read First – Important Changes in 0.7b!



* `PCSX2-SA` latest updates are not compatible with old save states. Please make sure you do an in-game save to your virtual memory card before upgrading.
* The following emulators have changed as the defaults and now run the stand-alone version: `Dolphin`, `Citra`, `PPSSPP`.If you have saves states or just want to go back to the `RetroArch` versions, you can always switch back by pressing: `Other Settings` – `Alternative Emulators` in the main interface and set them there.
* If you decide to install the new `RetroDECK Controller Layout` for the Steam Deck, it will wipe your custom configurations and emulator settings. That’s because all the configs need to be updated and changed to be compatible. The choice is yours (you can always install it later via the Configurator if you change your mind).



# What are the upsides of RetroDECKs all-in-one approach?

Quite many actually!

* RetroDECK is updated via standard secure update channels where you update all your other software (we will have an internal updater added in RetroDECK in 0.7b, so users don’t even need to go to the Discover app to update if they don’t want to).
* It allows us to apply the RetroDECK Framework on the bundled software and apply custom made specific patches for emulators or ES-DE (more on that later).
* We can optimize the data to take as little space as we possibly could. Our whole application in 0.7b is around 3GB. Since we are using a single package, ~~we can avoid a lot (but not all) of the overlap that takes up space when installing multiple AppImages or Flatpacks.~~  (Flatpak does an even greater job of deduplicating data see [**TiZ\_EX1**](https://www.reddit.com/user/TiZ_EX1/) comment in this thread!).
* We can expose various hidden/hard to find emulation features and allow the users to customize various experiences directly inside the application itself without needing to go into the Steam Deck’s desktop environment.
* We are leveraging the power of compiling these emulators ourselves (where possible) to make a more complete unified experience a reality with custom patches.



**What are the downsides of this approach?**

* You are bound to the software we ship inside our application and cannot add more things. But we are always open to suggestions on what to add next, just tell us on Github or Discord.
   * *That said we are experimenting with allowing users to import certain emulators early access versions like Yuzu (but no solution in the short term).*
* Emulator updates need to be in point releases and not daily, since we can’t update emulators inside an existing flatpak. As we apply the RetroDECK Framework on top of the emulators, we sometimes need to do some tinkering before we can release a new version. But you can expect semi-frequent emulator-update point releases, historically we have been fast if we feel the need to get something out quickly. Major new updates that add features to the RetroDECK application itself will take more time.
   * *There has been some issues with Yuzu in the past, but we have redone our entire Yuzu pipeline for 0.7b s it should allow for faster updates.*



# What is RetroDECK's vision and design philosophy?

* Valve endorsed the use of flatpaks as their preferred and safe way to distribute software on SteamOS’s immutable system. Many other immutable systems like Fedora Silverblue/Kionite and standard Linux distributions have also endorsed flatpaks. We also share the vision that flatpaks are the future for the Linux desktop and Linux based devices.
* Everything must be accessible from inside the application itself where possible. Once you launch RetroDECK, you should have all the tools you need to play games and configure the application. For the Steam Deck that means minimizing switching to desktop mode.
* We need to build a foundation that pushes emulation forward and expose more of the niche hardcore features in an easier way.
* We shall not be so bound by design choices that others have made but make our own path.
* We should ship the emulators with optimized settings for Steam Deck (later other devices) but also allow the users full control to create their own configs and make it easy to do so.
* We should do our best to respect user-made config changes where possible, even during the updates. Any forced changes should always be explained and give the users a prompt to accept them.
* We believe in a transparent open community: Dialog , user feedback and testing development versions will never be locked behind paywalls or subscription tiers . This comes from deep rooted beliefs in open-source freedom. Subscriptions and donations will always only grant cosmetics like a unique discord color.
* We want to make the emulation available for everyone; from the casual to the power user. Keep it simple, everything in one application and download it like any other software. Only one thing to update.
* Prioritize security and keep everything contained as much as possible.



**How does this vision effect design?**

A good example is the new exposure of `mods` and `texture_packs` under the retrodeck folder.

Before it was quite hard for users to add mods and texture packs into the emulators. No work for any other solution (that we are aware off) has been done to make this very hardcore thing more easy to handle.

For the user it means no more looking into hidden folders of when and where to put the files. Our new approach also has received the blessing of famous texture packs and mod pack creators out there that were happy that someone lowered the barrier.

So if you found it hard before to add:

* A magnificent texture pack for Citra
* A spooky HD pack for the Mesen Core
* New 3D polygon racing models for Mupen64Plus-Next Core

Just look our wiki under mods/texture packs and look forward to 0.7b.

[https://github.com/XargonWan/RetroDECK/wiki](https://github.com/XargonWan/RetroDECK/wiki)



Another example is (as others have done) move `gamelists` to under the retrodeck folder. This is a safer way of doing it and it's easier for the users to take backups.



**What to expect in the future?**

You can expect most of the standard stuff like that you can except from an emulation solution in the future:



* Cloud-sync
* USB and FTP file transfer
* External controller management
* Lightgun support
* Most of the supported ES-DE emulators
* Automatic Updates from Gamemode on Launch (0.7b it can be disabled in the Configurator)
* And more...

# What is the RetroDECK Framework?

This is the feature we have been building on since the beginning and the true hidden core of RetroDECK that we are unveiling for the first time today. It’s the foundation we have built over many months of hard work and will keep expanding on in every upcoming update.

The RetroDECK framework is a complete system that applies and adds features, fixes, structure and functions to all applications/data shipped within RetroDECK.

This is also one of the reasons we needed to restructure save file folders in the past updates as well.



**What does the RetroDECK Framework allow you to do?**

It allows us to ship deeper choices, customization, apply settings globally, create custom patches or functions and expose hidden settings to the front.

But what truly excites us in the team is the more advanced big features that we have not seen anyone else do on SteamOS or other operative systems.



**Some light examples in 0.7b of the framework is:**

* Move everything everywhere.

**Note:**

Please be careful when moving data to exotic locations don't be like Mr.Angry:





* Log in/logout/hardcore mode for RetroAchivements hardcore mode for all supported emulators.
* Apply Borders, Shaders and Widescreen mode per emulator / core or globally.



**Note:**

RetroDECK will offer full user choice and not a blanket all or nothing. You could have widescreen on one core while the others have borders.

**What are some advanced big examples that you could do with the Framework?**

Here is one example:



Think about configurations for emulators. How most other solutions are handling changes or updates is just a blanket call all-or-nothing. Either you accept the changes and remove everything you have done or keep your changes without getting the updates.

What we are building with the framework is a system to inject point changes into configurations.



*So instead of doing the crude way others are doing:*

Force replace in `config.xml` old with new `config.xml` yes or no?



***What our goal is and what we are building:***

Be able to open a `config.xml` inject the changed values across all those configs.

If an emulator updates and adds more config options, we can just add them without losing the rest of the user data.

So we can compare changes between the new `config.xml` and the old, then inject the changes.

*But if a emulator totally change how their configuration works and makes a whole new system from scratch (it does not happen often or at all) even we will be out of luck.*

So we hope in the future to be able to save even more custom configs even with the emulator updates. We also hope to make configuring emulators easier... more on that in a future development update after the summer.



**Another big example:**

If you read the recent article, we in the RetroDECK team are happy to unveil the `RetroDECK: Multiuser Mode`. This is only the first one of the big features we have planned for future updates and stands as an example of the complicated features we can accomplish. There is even more crazy stuff in development for the future big releases then this, so consider this a taste of things to come. It will not be ready for 0.7b but can be enabled with CLI commands for testing.



See the following Q&A:

# RetroDECK: Multiuser Mode Q&A

First read here:

[https://github.com/XargonWan/RetroDECK/wiki/How-can-I-help-with-testing%3F](https://github.com/XargonWan/RetroDECK/wiki/How-can-I-help-with-testing%3F)

This is for testing only in 0.7b!



**What does Multiuser Mode mean?**

It creates a new directory structure `retrodeck/multi-user-data/<username>` and allows multiple users to use RetroDECK from one device.



**Wait... what.. how?! What about saves?! Configurations?! Custom settings?!**

They are all saved per user if you enable it. You, your sister, brother, child, husband, wife, dog, cat could all have their separate saves, states and custom emulator settings just for themselves when they select their own profile.



**Does it support the Steam Deck’s multiple users in Game Mode? Will RetroDECK hook those Steam Users into the enabled Multiuser system?**

Yes, that is the intent and should work, so you can log into your Steam Deck profile and have your RetroDECK saves/configs.



**What about a Linux Desktop PC that don't have Steam installed?**

We also support locally created “RetroDECK Users” so, for those Linux Desktop users in the future that don’t use Steam and just want RetroDECK on their device.



**What happens if I disable multiuser mode?**

You chose one profile as the primary user and the other data still exists under `retrodeck/multi-user-data/<username>`. No data is lost until you delete it manually.



**What happens if I re-enable multiuser mode?**

If you have had multiuser mode enabled and disable it, then re-enable it and have not deleted any `retrodeck/multi-user-data/` everything should work as it did before.



**Will there be an easy way transfer/export/import a user profile, like press a button and my can export to my profile (saves, configurations, with/without roms) to my friend's device on something like a USB or other media?**

Not for 0.7b but hopefully for the next major update 0.8b.



# Other things

**What does Amazing Aozora mean?**

Aozora is Japanese and means blue sky.

So, you could interpret the name as one team member:

*“Amazing blue skies... The first update that shows the exiting new horizon and the path we are heading towards.”*

Or as another:

*“Aozora is just a tiny Japanese banks name! This is clearly just an update to pay some of our dept to the community off! Stop with that horizon nonsense mumbo jumbo!”*



**What are some examples I can help out with with?**



**Artist/Creators:**

* Create new pixel art for the Radial menus.
* Create easter egg art for the new `easter egg system` for various holidays.
* Create menu art for a new Configurator.
* Create input art that can be shown when you start a game.
* Create input art guides for the wiki for the Steam Deck and later various controllers.
* Create patch note videos.
* Create instruction videos.
* Help us make RetroDECK better.



**Developers:**

* Help us put in new features.
* Help us make the configurator a godot application with full controller support.
* Help us get releases out faster.
* Help us make RetroDECK better.



**Testers:**

* Help us test cooker builds and submit bugs and feedback.
* Help us make RetroDECK better.



**Everyone:**

* Be kind and follow the rules.
* Spread the word of RetroDECK if you like it, if you don't like it or have suggestions put them on github into issues or discuss them on discord.
* Engage with the rest of the community.
* Help us make RetroDECK better.



**Summer Period**

As the summer period arrives there will be a holiday break on these kind of development posts until after the summer. Some parts of the team is also going on vacation, you can still except semi regular emulator updates and bug fixes as usual in 0.7.X releases (but no major 0.8b - Bonsai Banana version in the middle of the summer!).



**End Quote**

*We hope you are excited about these features and our vision as we are and we want to get 0.7b out to you as quickly as possible (hopefully next week).*

*We also wish everyone a happy and good summer!*

[Discord Server](https://discord.gg/Dz3szYsP8g)

[Patreon](https://patreon.com/RetroDECK)

*//The RetroDECK Team*
