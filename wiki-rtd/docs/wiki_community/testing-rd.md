# Testing RetroDECK

There are two ways help us to test features in RetroDECK.<br>
The first one is our bleeding edge `RetroDECK Cooker` channel.<br>
The second one is the `Experimental Features` inside the stable version inside the `Developer Options Menu`.

## Can I help you with testing?
Yes, do follow the instructions on this page and tell in Discord channel `i-want-to-help` that you are interested in testing out `RetroDECK Cooker`  builds or want to give feedback on `Experimental Features`.
You will get some instructions from one of the mods and be promoted to a `BetaTester` role.


## Before you begin!

### Backup before testing! 🛑
These builds and features can make you loose all data including `ROMS`, `BIOS` and `Scraped Data` etc..<br>
We **recommend** that you don't run any experimental features or cooker builds on your main gaming machine.

### Expect bugs and issues! 🛑
These builds and experimental features can contain several bugs and be unstable.

## How do I take a backup?

Backup your `/retrodeck/` and it's content and `/.var/app/net.retrodeck.retrodeck/`.
You could copy the entire folders to a secure location or for a quick test you could just rename both of the folders into something else.
Then RetroDECK will think it's a fresh install.

Example of renaming:<br>
`OLDnet.retrodeck.retrodeck/`<br>
`OLDretrodeck/`


## What is RetroDECK Cooker?
[RetroDECK Cooker](https://github.com/XargonWan/RetroDECK-cooker) are the bleeding edge development builds of [RetroDECK](https://github.com/XargonWan/RetroDECK). These builds are only for development and testing purposes.

### How do I install cooker builds?
You can download the latest `.flatpak` releases from the above link and install them via CLI or from the desktop.

**NOTE:**
* You need to have set up a sudo password if you want to test on a Steam Deck.
* If you have `RetroDECK` the stable release on your system `RetroDECK-Cooker` will be installed separately since it is a different branch. We do not recommend running cooker on a system where you have a running `RetroDECK` stable.

#### Desktop

You should just be able to double click on the .`flatpak` file and what ever application manager/installer (like Discover) you have installed should be able to install it. If that does not work use the CLI method.

#### CLI

Run the following command from where you have downloaded the `.flatpak` file. <br>
`flatpak install RetroDECK.flatpak`


## How do I uninstall RetroDECK Cooker?

### Desktop
Just go into your application manager/installer (like Discover), find RetroDECK and press uninstall.


### CLI

Run the following command: <br>
`flatpak remove RetroDECK`


### Why does the cooker release have strange names?
The names are randomly generated to make it easy to see what build you are running.

## What are RetroDECK experimental features?
Experimental features are a showcase of what proof-of-concepts we are trying out or working on that you can try out even on stable releases and we would like feedback on them. All these features are just conceptual and we hope them release ready in an later major update or scrap them if the don't work out.
Standard backup procedures apply as written above.

### How do I enable them?

From CLI run:

`flatpak run net.retrodeck.retrodeck uuddlrlrstart`

The `Developer Options Menu` should show up inside the Configurator.

