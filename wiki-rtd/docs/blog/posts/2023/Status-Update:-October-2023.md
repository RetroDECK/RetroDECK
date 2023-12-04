---
date: 2023-10-13
---

**Please note that this was written for Lemmy/Reddit and copied over to the new RetroDECK Wiki**

Hello community!

We in the team thought we could give you a quick status update on how development is going.

# Status update 2023-10:

We hope that everyone is ready for a tiny spooky October status update.

<!-- more -->

## We begin with thanking all kind emulator developers.

We had some issues with certain emulators caused by the recent QT6 migration and the addition of new emulators (more on that next month).



We tried to contact those developers to request for help or a hint about their project and thankfully they were very collaborative towards us, in some cases making some code changes to accustom some specific RetroDECK needing and thanking us for our work.

It seems like that RetroDECK got a good reputation out there and we're really thankful for this, as one of our main efforts is trying to contribute more good will into the emulation community.



This is what makes the emulation community great when we all can work together. If you need something from us, feel free to ask.

Thank you all!



## What are you working on?



## Adding individual ROMS to Steam and launch them with RetroDECK

More development has been going on into this and how it will work in its first iteration is that the games you flag as your favorites can be added to Steam with a tool in the Configurator.

## External Controllers – Button Combo Hotkeys

We will ship various Steam Input templates that allows you to use the button bound hotkey combos to do various emulator functions like (Save State, Load State, Quit etc..) for a variety of controllers from 0.8b. All you will need to is plug in / connect your controller, go into Steam Controller setting and choose the RetroDECK template for your controller.

This will also work for the RetroDECK Linux Desktop users as long as you have added RetroDECK to Steam and launch it from there.

It will be the same button combos as the Steam Deck with \`Select\` as the trigger but with \*\*no radial menu system\*\*.



We will have templates for all the following:

* PS3
* PS4
* PS5
* Xbox 360
* Xbox One / S / X
* Switch Pro
* Steam Controller
* Generic (Stadia, 8bit, Xiaomi, USB-Clones, others etc..)



**Special notes on Generic:**

To access all the hotkeys, you must have a controller that has all the normal inputs (two joysticks with clickable L3 and R3, four button dpad, four face buttons, four shoulder buttons, start, and select).

But if you have start and select you can always quit the game (even with a tiny NES USB clone controller).



**Special notes on PS4, PS5:**

The full touchpad acts as a mouse for Wii input / computer systems.

Left touchpad click = left click

Right touchpad click = right click



**Special notes on the Steam Controller:**

The right touchpad acts as a mouse for Wii input / computer systems.

Right touchpad click = left click



## Turning the Configurator into a Godot application

We are working on turning the configurator into a Godot application. This will allow you to use all the functions with a controller in a Retro Inspired interface that is already working. The interface should be scalable for both TV’s, Monitors and Steam Deck Screen. We are also looking into changing toggle the font to OpenDyslexic so it can be easier to read for those who need it. This might not be done for 0.8b as it’s quite a big project (it will ready when it’s ready).

If you are working with UI/UX design and/or have experience with Godot and want to help on this, please contact us on discord.



## Rekku, the RetroDECK mascot.

Some parts of the team also really wanted a mascot so that will also be a part of the new Configurator. It’s a animated cyborg-cat-like-humanoid that guides you to the various functions in the Configurator. Right now, we only have AI generated concepts of the mascot for reference but if you are an artist and want to help us design the mascot, please contact us on discord.



**Mascot Q/A:**

Q: I get the Godot Configurator, but why a mascot?!

A: Why not?!



Q: Will we see Rekku in other things except the Configurator?

A: Maybe!



Q: I hate mascots with a burning passion, can I turn it off in the configurator?

A: You’re a meanie, but yes!


## That is all for this month!

A minor patch 0.7.3b will be out later with Emulator updates. But the main feature will be ES-DE 2.2, so we will release it when the ES-DE team are ready, and we can implement it asap.


