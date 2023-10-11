# General information 

[I see SA refereed in documentation about emulators what does it mean?](https://github.com/XargonWan/RetroDECK/wiki/FAQs%3A-Frequently-asked-questions#i-see-sa-refereed-in-documentation-about-emulators-what-does-it-mean)
## Different controller layouts in games

### Xbox layout - Steam Deck 
The Steam Deck uses the Xbox button layout as it's physical buttons.

**Steam Deck/Xbox button layout:**<br>

| Button Placement  | Button |
| :---              | :---:  |
| Top               |  `Y`   |
| Left              |  `X`   |
| Right             |  `B`   |
| Bottom            |  `A`   |

### Nintendo Layout
Nintendo systems uses the Nintendo layout in game where both the Y-X and A-B buttons have switched places with each other from the Steam Decks physical button layout. You can enable a mode that switches the Y-X and A-B buttons for supported Emulators inside the `RetroDECK Configurator`. 

<br>

**Nintendo - button layout:**<br>
| Button Placement  | Button |
| :---              | :---:  |
| Top               |  `X`   |
| Left              |  `Y`   |
| Right             |  `A`   |
| Bottom            |  `B`   |


**Example:**<br>
So if you are emulating a Nintendo game that calls for the button A to be pressed it corresponds to the right button on the Steam Deck so button B.


### Sony PlayStation Layout
The Sony PlayStation uses it's icon glyphs to represent it's buttons.

**Sony PlayStation - button layout:**<br>
| Button Placement  | Button      |
| :---              | :---:       |
| Top               |  `Triangle` |
| Left              |  `Square`   |
| Right             |  `Circle`   |
| Bottom            |  `X`    |

**Example:**<br>
So if you are emulating a PlayStation game that calls for the button Triangle to be pressed it corresponds to the top button on the Steam Deck so button Y.

**Regional differences:**

Depending on the region of your Playstation game, the buttons `Circle` and `X` switches the meaning for confirm and cancel (they are still at the same physical location). But it is good to keep in mind if you are used to exiting out of menus with a certain button and wondering why it works in some games while others not.

**Example:**

In the EU/US `X` is confirm while in Japan `X` is cancel.

# Steam Deck Controller Guide - A Visual Introduction
If you are looking for a general guide on how to use the Steam Deck controls beyond RetroDECK please check this steam community guide:<br>
[Steam Deck Controller Guide - A Visual Introduction](https://steamcommunity.com/sharedfiles/filedetails/?id=2804823261)



# RetroDECK Official Controller Layout: Hotkeys:

### Current version of the layout
0.7.1b that is written on this wiki

## Information
Be sure to have the `RetroDECK: Official Controller Layout` activated from the `Templates`. 
- Add the Official Layout under `Controller Settings` -> `Controller Layouts` -> `Templates` in the Steam Deck called `RetroDECK: Official Layout` with a version number and apply 

Read more on  <br>[[Steam Deck: Installation and updates]]

## Everything is customizable
You are free to rebind the keys as you see fit in the RetroDECK: Official Layout profile and make your own to better suit your needs. <br>
But if you rebind the keys inside RetroDECK there can be a risk that an upcoming update will revert your changes if the emulators made changes to the keybindings for the hotkeys. <br>
Also note that if you break your controller profile with your tinkering please revert the RetroDECK's official profile. 

## 🚧 Please READ: 🚧

**Not all Emulators has hotkey support; some have partial support, some has none and some has a majority implemented**

The plan is to map as much as we can into the RetroDECK Hotkey System below. We are also patching in Emulator Hotkeys with the `RetroDECK Framework` (if possible) to be compatible with the system. If a emulators later versions adds better hotkey support we plan to map it towards the same functions bellow for a unified experience across as many emulators as possible.  

### Known issues
* `PPSSPP` has a bug in with multi-input hotkeys in their flatpak version, so we did a workaround and bound ESC is Open Menu. This allows you to access all of the emulator features and can quit.
* `RPCS3` hotkeys/shortcuts do not work and they are a new experimental feature. To exit you have to shut down RPCS3 from the `Switch Window` inside the Steam Deck interface. 
* `CEMU` has almost no hotkey support.
* `XEMU` has no hotkey support.
*  `Citra` is the only dual-screen emulator that allows a hotkey for changing the screen layout, others: `MelonDS`, `RetroArch`, `Cemu` has no hotkey for it.

## Global Hotkeys: Button Combos

### The hotkey button 
The `HK` or `hotkey button` on the Steam Deck is `L4` or `R4` or `Select` depending on what is closest for the button combo you are trying to press, all trigger the same functions.

**Example:**

You want to do the command `Pause / Resume`. <br>
You press and hold either `L4` or `R4` or `Select` and press `A` to trigger the command.

### Button combo list
The global hotkeys are activated by pressing the hotkey button and holding it while pressing the corresponding other button input.
What follows is a list of hotkeys: 

`Command` Shows what the hotkey does. <br>
`Button / Combination` Shows the input you need to make to trigger the command. <br>
`Keyboard Command` Shows what is being sent to the emulator. <br>
`Emulator Support` Shows what emulators support the command. <br>
`Comment` Just extra comments. <br>



| Command                 | Button / Combination| Keyboard Command      | Emulator Support     |    Comment |  
| :---                    | :---:               | :---:                 |       :---:          |  :---:     |      
| Pause / Resume          |   `HK + A`          |   `CTRL + P`          | `RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `MelonDS` `PCSX2`  `Yuzu`             |            |     
| Take Screenshot         |   `HK + B`          |   `CTRL + X`          | `RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `PCSX2`   `Yuzu`           |            | 
| Fullscreen Toggle      |   `HK + X`          |   `CTRL + ENTER`      | `Citra` `Dolphin/Primehack` `Duckstation` `MelonDS` `PCSX2`  `Yuzu`             |            | 
| Previous State Slot     |  `HK + D-Pad Left`  |   `CTRL + J`          | `RetroArch` `Dolphin/Primehack` `Duckstation` `PCSX2`|                    |            |          
| Next State Slot         |  `HK + D-Pad Right` |   `CTRL + K`          | `RetroArch` `Dolphin/Primehack` `Duckstation` `PCSX2`|   
| Increase Emulation Speed     |  `HK + D-Pad Up`  |   `CTRL + 1`          | `Citra` `Dolphin/Primehack` `Duckstation` `PCSX2`|                    |            |          
| Decrease Emulation Speed         |  `HK + D-Pad Down` |   `CTRL + 2`          | `Citra` `Dolphin/Primehack` `Duckstation` `PCSX2`|                       |            | 
| Load State              |  `HK + L1`          |   `CTRL + A`          | `RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `PCSX2`                          |            | 
| Save State              |  `HK + R1`          |   `CTRL + S`          | `RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `PCSX2`                        |            | 
| Rewind                  |  `HK + L2`          |   `CTRL + -`          | `RetroArch` `Duckstation`                     |            | 
| Fast forward            |  `HK + R2`          |   `CTRL + +`          |  `RetroArch` `Duckstation` `MelonDS` `PCSX2`                                  |            | 
| Swap Screens         |  `HK + L3`          |   `CTRL + TAB`        |     `Citra` `MelonDS`  `Cemu`           |            | 
| Open Menu               |  `HK + Y`         |   `CTRL + M`          | `RetroArch` `Duckstation` `PCSX2`  `Yuzu`                        |            | 
| Exit Emulator           |  `HK + Start`       |   `CTRL + Q`          |`RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `PCSX2`   `Yuzu`                                   |            | 
| Escape                  |  `HK + R3`          |   `ESC`               |     `PPSSPP`                 |            | 




### RetroArch: Additional Hotkeys

These hotkeys also work for RetroArch and are built in.

| Command                 | Button / Combination     | Emulator Support     |    Comment |
| :---                    | :---:                    |       :---:          |  :---:     | 
| Open Menu               |  `L3 + R3`               |      `RetroArch`     |            | 

### Arcade Systems: Additional Hotkeys

This hotkey work for RetroArch, MAME, FBNEO and other arcade systems.

| Command                 | Button / Combination     | Emulator Support     |    Comment |
| :---                    | :---:                    |       :---:          |  :---:     |  
| Insert Credit           |  `Select`                |     `RetroArch`      |            | 


# Steam Deck - Radial Menu System

What follows is a breakdown of the Radial System that you access on the `Left Touchpad`. 

### Is there a quick way to go back to the top of the radial menu system? 
Yes, just press  on the `HK` trigger buttons: `L4` or `R4` or `Select` 

## Radial Menu System
`Radial Button` Shows what the hotkey does. <br>
`Keyboard Command` Shows what is being sent to the emulator.<br> 
`Emulator Support` Shows what emulators support the command. <br>
`Comment` Just extra comments. <br>

**NOTE:**

Like everything in RetroDECK we plan to make revisions and updates of the menus. We hope with time be able to add more emulators and even better art. 

## Main Menu
The `Main Menu` gives you access to all the menus bellow. 

## Quick
The `Quick Menu` or `Quick Access Menu` Menu is the most populated menu. It features "best of" options from other menus.

| Radial Button           | Keyboard Command     |  Emulator Support     |    Comment |
| :---                    | :---:                |       :---:          |  :---:     |    
| Exit Emulator           |   `Ctrl + Q`         | `RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `PCSX2`   `Yuzu`                     |            | 
| Open Menu               |   `Ctrl + M`         |  `RetroArch` `Duckstation` `PCSX2`  `Yuzu`                       |            | 
| Swap Screens            |   `Ctrl + Tab`       |  `Citra` `MelonDS`  `Cemu`                     |            | 
| Take Screenshot         |   `Ctrl + X`         | `RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `PCSX2`   `Yuzu`           |            | 
| Save State              |   `Ctrl + S`         |`RetroArch` `Dolphin/Primehack` `Duckstation` `PCSX2`                      |            | 
| Load State              |   `Ctrl + A`         | `RetroArch` `Dolphin/Primehack` `Duckstation` `PCSX2`                     |            | 
| Pause / Resume          |   `Ctrl + P`         | `RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `MelonDS` `PCSX2`   `Yuzu`             |             | 
| Fullscreen Toggle       |   `Ctrl + Enter`     |`Citra` `Dolphin/Primehack` `Duckstation` `MelonDS` `PCSX2`   `Yuzu`                      |            | 
| Restart / Reset         |   `CTRL + R`         |`RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `MelonDS` `PCSX2`  `Yuzu`                                   |            |
| Escape                  |   `ESC`              |       `PPSSPP`              |            |

## State
The `State Menu` is the menu where you handle anything to do with saving and loading states. 


| Radial Button           | Keyboard Command     | Emulator Support     |    Comment |  
| :---                    | :---:                |       :---:          |  :---:     |      
| Previous State          |   `Ctrl + J`         |`RetroArch` `Dolphin/Primehack` `Duckstation` `PCSX2`                      |            | 
| Next State              |   `Ctrl + K`         |`RetroArch` `Dolphin/Primehack` `Duckstation` `PCSX2`                      |            | 
| Save State              |   `Ctrl + S`         |`RetroArch` `Dolphin/Primehack` `Duckstation` `PCSX2`                      |            | 
| Load State              |   `Ctrl + A`         | `RetroArch` `Dolphin/Primehack` `Duckstation` `PCSX2`                     |            | 
| Undo Load State         |   `Ctrl + 8`         | `Dolphin/Primehack`                    |            | 
| Undo Save State         |   `Ctrl + 9`         |  `Dolphin/Primehack` `Duckstation`                   |            | 


## Speed / Frames
The `Speed / Frames Menu` is where you find anything related to: emulation speed, frame limits, fast forwarding and rewinding. 

| Radial Button           | Keyboard Command     |  Emulator Support     |    Comment |   
| :---                    | :---:                |       :---:           |  :---:     |  
| Fastforward             |   `Ctrl + +`         | `RetroArch` `Duckstation` `MelonDS` `PCSX2`                       |            | 
| Rewind                  |   `CTRL + -`         |  `RetroArch` `Duckstation`                     |            |
| Increase Emulation Speed|   `CTRL + 1`         | `Citra` `Dolphin/Primehack` `Duckstation`  `PCSX2`                       |            |
| Decrease Emulation Speed|   `CTRL + 2`         |`Citra` `Dolphin/Primehack` `Duckstation`  `PCSX2`                        |            |
| Reset Emulation Speed   |   `CTRL + 3`         | `Duckstation`                      |            |
| Disable Emulation Speed Limit  |   `CTRL + 0`  |`Dolphin/Primehack`                       |            |
| Frame limit On/Off     |   `CTRL + Z`          | `PCSX2`  `Yuzu`                       |            |


## Display / Graphics
The `Display / Graphics Menu` is where you find anything related to: up-scaling/resolution scaling, widescreen or change aspect ratio, fullscreen, swap or change dual screen layout. 

| Radial Button                    | Keyboard Command |  Emulator Support     |    Comment |
| :---                             | :---:            |       :---:           |  :---:     |
| Fullscreen Toggle                |   `Ctrl + Enter` | `Citra` `Dolphin/Primehack` `Duckstation` `MelonDS` `PCSX2`   `Yuzu`                      |            |
| Increase Resolution / Upscale    |   `Ctrl + U`     |  `Dolphin/Primehack` `Duckstation` `PCSX2`    |            |
| Decrease Resolution / Upscale    |   `Ctrl + Y`     | `Dolphin/Primehack` `Duckstation` `PCSX2`     |            |
| Change Widescreen / Aspect Ratio |   `Ctrl + W`     |  `Dolphin/Primehack` `Duckstation` `PCSX2`    |            |
| Swap Screens                     |   `Ctrl + Tab`   |`Citra` `MelonDS`  `Cemu`                        |    |
| Change Dual Screens Layout       |   `Ctrl + L`     |   `Citra`|                    |        |

## General 
The `General Menu` or `General Emulation Menu` is where you find various global generic emulation hotkeys: Quit/Exit, Restart, Take Screenshot, Change CD, Pause, Turbo Input, Cheats and Video Recording.

| Radial Button           | Keyboard Command     |  Emulator Support     |    Comment |   
| :---                    | :---:                |       :---:           |  :---:     |    
| Exit Emulator           |   `Ctrl + Q`         | `RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `PCSX2` `Yuzu`                      |            | 
| Open Menu               |   `Ctrl + M`         | `RetroArch` `Duckstation` `PCSX2`  `Yuzu`                         |            | 
| Take Screenshot         |   `Ctrl + X`         | `RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `MelonDS` `PCSX2`  `Yuzu`             |            | 
| Restart / Reset         |   `CTRL + R`         |`RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `MelonDS` `PCSX2`  `Yuzu`                                                          |            |
| Change Disc / Next Disc |   `CTRL + D`         | `RetroArch` `Dolphin/Primehack` `Duckstation`                      |            |
| Cheats On/Off           |   `CTRL + C`         | `RetroArch` `Duckstation`                     |            |
| Pause / Resume          |   `Ctrl + P`         | `RetroArch` `Citra` `Dolphin/Primehack` `Duckstation` `MelonDS` `PCSX2`  `Yuzu`             |            | 
| Turbo On/Off            |   `Ctrl + T`         | `Duckstation`                       |            | 
| Video Recording On/Off  |   `Ctrl + V`         |`RetroArch` `Dolphin/Primehack`  `PCSX2`                       |            | 

## Steam Deck
The `Steam Deck Menu` is where you find Steam Deck specific functions and general computer hotkeys: Steam Screenshot, Show Steam Deck Keyboard, Escape, Alt + F4, Tab, Enter and F1. Some of these could also be useful inside the various PC emulation emulators. 


| Radial Button           | Keyboard Command     |  Emulator Support     |    Comment |   
| :---                    | :---:                |       :---:           |  :---:     |     
| Escape                  |   `ESC`              |     `PPSSPP`          |            | 
| Tab                     |   `Tab`              |                       |            | 
| Alt + F4                |   `Alt + F4`         |                       |            | 
| F1                      |   `F1`               |                       |            | 
| Enter                   |   `Enter`            |                       |            | 
| Take Steam Screenshot   |   `none`             |                       |            | 
| Show Steam Deck Keyboard|   `none`             |                       |            | 


## Specific

The `Specific Menu` or `Specific Emulator Hotkeys Menu` opens up several system/emulator specific sub-menus. Here you will find hotkeys not so commonly used but could be good to have easy access to:

### Switch
The `Switch Menu` here you find hotkeys related to Switch emulation: Change GPU Accuracy, Change Docked/Undocked Mode, Add/Remove Amiibo

| Radial Button           | Keyboard Command     |  Emulator Support     |    Comment |    
| :---                    | :---:                |       :---:           |  :---:     |     
| Change GPU Accuracy     |   `Alt + G`          |   `Yuzu`              |            | 
| Load / Remove Amiibo    |   `Alt + M`          |   `Yuzu`              |            | 
| Docked / Undocked Mode  |   `Alt + D`          |   `Yuzu`              |            | 

### MAME
The `MAME Menu` here find hotkeys related to the MAME standalone emulator: Servicemode and buttons 1-4, Insert None Bills (not credits that is Select) and tilt.

**MAME SUPPORT IS NOT IN YET WILL BE IN A LATER UPDATE**

| Radial Button           | Keyboard Command     |  Emulator Support     |    Comment |   
| :---                    | :---:                |       :---:           |  :---:     |     
| Service Mode            |   `Alt + 0`          |   `MAME`              |            | 
| Service Button 1        |   `Alt + 1`          |   `MAME`              |             | 
| Service Button 2        |   `Alt + 2`          |   `MAME`                    |            | 
| Service Button 3        |   `Alt + 3`          |   `MAME`                    |            | 
| Service Button 4        |   `Alt + 4`          |    `MAME`                   |            | 
| Insert Bill / Note      |   `Alt + 5`          |    `MAME`                  |            | 
| Tilt                    |   `Alt + 6`          |     `MAME`                  |            | 

### RetroArch
The `RetroArch Menu` here you find hotkeys related to the RetroArch emulator: RetroArch Cheat Mangement, AI Service and Netplay Host.


| Radial Button           | Keyboard Command     |  Emulator Support     |    Comment |   
| :---                    | :---:                |       :---:           |  :---:     |     
| Next Cheat              |   `Ctrl + G`         | `RetroArch`                      |            | 
| Previous Cheat          |   `Ctrl + F`         | `RetroArch`                      |            | 
| Cheats On/Off           |   `Ctrl + C`         | `RetroArch`                      |            | 
| AI Service On/Off       |   `Ctrl + I`         | `RetroArch`                      |            | 
| Netplay Host On/Off     |   `Ctrl + H`         |  `RetroArch`                     |            | 

### Gamecube / Wii
The `Gamecube / Wii Menu` here you find hotkeys related to the Dolphin standalone emulator: Golf Mode, Freelook Mode On/Off/Reset, Wii Sync Button and Wii Mote Sideways / Upright. 


| Radial Button           | Keyboard Command     |  Emulator Support     |    Comment |   
| :---                    | :---:                |       :---:           |  :---:     |     
| Golf Mode On/Off        |   `Alt + H`          |  `Dolphin/Primehack`                     |            | 
| Freelook Mode On/Off    |   `Alt + F`          |`Dolphin/Primehack`                       |            | 
| Freelook Mode Reset     |   `Alt + R`          | `Dolphin/Primehack`                      |            | 
| Wii Sync Button         |   `Alt + W`          | `Dolphin/Primehack`                      |            | 
| Wiimote Upright         |   `Alt + Z`          | `Dolphin/Primehack`                      |            | 
| Wiimote Sideways        |   `Alt + X`          | `Dolphin/Primehack`                      |            | 


### NDS 
The `NDS Menu` here you find hotkeys related to the MelonDS standalone emulator: Send Close/Open Lid, Send Play Microphone and Sunlight + / -.


| Radial Button           | Keyboard Command     | Emulator Support     |    Comment |  
| :---                    | :---:                |      :---:           |  :---:     |
| Sunlight +              |   `Alt + +`          |`MelonDS`                      |            | 
| Sunlight -              |   `Alt + -`          | `MelonDS`                     |            | 
| Play Microphone         |   `Alt + P`          |`MelonDS`                      |            | 
| Close/Open Lid          |   `Alt + L`          | `MelonDS`                       |            | 

### 3DS 
The `3DS Menu` here you find hotkeys related to the Citra standalone emulator: Load and Remove Amiibo

| Radial Button           | Keyboard Command     | Emulator Support     |    Comment |     
| :---                    | :---:                |      :---:           |  :---:     |    
| Load Amiibo             |   `Alt + M`          |`Citra`               |            | 
| Remove Amiibo           |   `Alt + N`          |`Citra`               |            | 