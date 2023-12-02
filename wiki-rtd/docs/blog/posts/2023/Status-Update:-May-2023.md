---
date: 2023-05-03
---

**Please note that this was written for Lemmy/Reddit and copied over to the new RetroDECK Wiki**

Hello community!

We in the team thought we could give you a quick status update on how development is going.

**NOTE: This is still work in progress**

# Status update 2023-05:

*Controls for everything everywhere all at once.*

As a continuation of last months post, some parts of the team have been working on hotkeys and controls (in fact since October 2022 [GitHub: Issue 194](https://github.com/XargonWan/RetroDECK/issues/194)).

<!-- more -->

*This is only one part of the 0.7b update.*



**We set out the following goals for the project for a new Steam Deck layout profile:**



* The layout needs to be scalable and adapt for new emulators in the future without adding too much clutter.
* The layout needs to be scalable when a emulator updates and supports new hotkeys.
* The layout should when possible have the ability to hook as many hotkeys into the same input that represents the same function across all emulators.
* The layout need to be unified and support players dynamic playstyles to hop between emulators and games in one gaming session. A player could start RetroDECK: Play a little Switch then quit Yuzu, go directly to PPSSPP and play some PSP then end up in RetroArch to play SNES before the session is over.



**That boiled down into the following points to work on:**



* Check every hotkey that exists in every emulator and how they work.
* Check if some hotkeys are hardbound (none rebind-able) and see if those can be worked into the over all structure of all other emulators.
* Check what rules the hotkeys of each emulator have to bind them (single button only, only keyboard inputs, only gamepad inputs etc..).
* From the result above: Decide and prioritize what hotkeys are so important they need a physical button combo. What hotkeys are "semi-important / good to have" and can live in a radial menu. Decide what not hotkeys not to bind at all.



**Results so far:**

*NOTE: Not all functions are supported in all emulators, but they will be added in as soon as they do support them.*



**Physical button combo input**

* The standard RetroArch = Start + Select to Quit and L3 + R3 for Open Menu is still there for RetroArch.
* The L4 and R4 buttons changes the layout when hold down and allows button combinations with those buttons, example: "L4 or R4 + R1" = Save State and "L4 or R4 + L1" = Load State. It allows for quick access to the following functions with just button presses:
   * Save state
   * Load state
   * Exit/Quit Emulator
   * Fullscreen On/Off
   * Fullscreen Off - (NOTE: Some emulators don't have toggle and have a separated on / off hotkeys)
   * Fast forward
   * Rewind
   * Pause/Resume
   * Open Menu
   * Select Previous State Slot
   * Select Next State Slot
   * Capture Screenshot
   * Swap Dual-Screens  /  Toggle pad screen (DS, 3DS, WiiU)
   * Escape key - (Useful for some Emulators)
   * Freelook mode movement for Dolphin on the sticks (NOTE: as long as L4 or R4 is hold down and Freelook mode is activated).



**Radial Menu System**

The radial menu system that is on the left touchpad gives you access to 70+ hotkeys (including the button bound from above) for various functions while gaming. All functions are labeled (even tho the labels) are not in the picture.



The Main Menu is your way into the radial system and it's sub-menus bellow:



The State Menu gives you access to everything to do with states

* Save State
* Load State
* Select Previous State Slot
* Select Next State Slot
* Undo Save State
* Undo Load State





The Speed Menu gives you access to everything to do with Speed / Frame rate manipulation

* Fast forward
* Rewind
* Increase Emulation Speed
* Decrease Emulation Speed
* Reset Emulation Speed
* Disable Emulation Speed Limit
* Toggle Frame Limit





The General Menu gives you access to general emulator functions

* Toggle Cheats
* Exit/Quit Emulator
* Open Menu
* Capture Screenshot
* Toggle Turbo
* Pause/Resume
* Toggle Video Capture / Recording





The Display / Graphics Menu gives you access to everything about: screen layout, upscaling, widescreen etc..

* Increase Reslution Scale / Increase Upscale Multiplier
* Decrease Reslution Scale / Decrease Upscale Multiplier
* Widescreen / Cycle Aspect Ratio
* Fullscreen On/Off
* Fullscreen Off
* Swap Dual-Screens (3DS, DS, WiiU)
* Change Dual-Screenlayout  (3DS)





The Steam Deck Menu gives you access to certain steam deck functions and certain keyboard inputs (that could work in emulators that don't have good hotkey support).

* Show Keyboard
* Steam Deck Screenshot
* Steam Deck Zoom
* Escape
* ALT + F4
* Tab



The Emulator Specific Menu opens up a new menu system where you can access emulator specific functions (I can't show them all in this post!)

* Switch Menu - Gives a radial that supports: Docked / Undocked, Change GPU Accuracy, Amiibo
* Mame Menu - Gives a radial that supports: Service menu and keys, insert bills and other none credits.
* Wii/GC (Dolphin) Menu - Gives a radial that supports: Golf Mode, Freelook Mode, Wii Sync Button, Freelook Reset, WiiMote mode: Upright / Sideways
* DS Menu - Gives a radial that supports: Send Close / Open Lid, Send Microphone Input, Boktai + and - sunlight.
* 3DS Menu - Gives a radial that supports: Amiibos
* RetroArch Menu - Gives a radial that supports: Cheats manipulation, AI Service, Netplay Host



The Quick Access Menu gives you a "best of" hotkeys from the other menus.

* Save / Load
* Fullscreen On / Offf
* Fullscreen Off
* Swap Dual-Screens (3DS, DS, WiiU)
* Change Dual-Screenlayout  (3DS)
* Escape
* Quit
* Open Menu
* Pause
* Screenshot



That is all for today!

If you are an pixelartist, a video editor or a developer that want to help us with the project please contact us on discord.



**What else?**

There are a lot of other things in the pipeline as well for v0.7b. But we shall save those for a future update (when we have something to share and we don't want to spoil everything).

If you want to help with out with the project or just chat join the discord.



[Discord Server](https://discord.gg/Dz3szYsP8g)

[Patreon](https://patreon.com/RetroDECK)



//The RetroDECK team
