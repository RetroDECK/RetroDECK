# Supported extensions
In order to check which file extensions are supported check the page [Emulators: Folders & File extensions](https://github.com/XargonWan/RetroDECK/wiki/Emulators:-Folders-&-File-extensions)

## Special ROMs formats
Some emulators are working only with specific rips, here is what I gather.

**XEMU**: you must use iso files called xiso (the extensions are usually `.xiso.iso` or `.iso` only)<br/>

**NDS**: needs a decrypted dump<br/>

**3DS**: needs a decrypted dump<br/>

**PS3**: are folders that need to be with the `.ps3` file extension in the end. <br/>
Example: `Gran Turismo 5.ps3`

# RetroAchievements
Until we don't implement a proper menu, the RetroAchievements must be enabled from RetroArch:<br/>
`Tools` -> `Start RetroArch` -> `Settings` -> `Achievements`<br/>
Here you have to insert your username and password that you used to register to [RetroAchievements](https://retroachievements.org), then [save your RetroArch config](https://github.com/XargonWan/RetroDECK/wiki/FAQs---Frequently-asked-questions#i-configured-retroarch-but-the-configuration-was-not-saved).<br/><br/>
**NOTE:** not all the games are supported; your game [hash](https://docs.retroachievements.org/FAQ/#what-is-an-ra-hash) must be checked on [RetroAchievements website](https://retroachievements.org).

# Multidisk/file games: Directory interpreted as files
You can put all the game files inside a sub-folder in order to keep you game list clean, these folder will be seen as the game itself from RetroDECK and not as an actual folder, more info [here](https://gitlab.com/es-de/emulationstation-de/-/blob/master/USERGUIDE.md#directories-interpreted-as-files) on the official ES-DE Documentation. The folder needs to have the corresponding .m3u file and the folder needs to be renamed to the exact filename of the .m3u 

Example on how a structure could be:
```
─── Dragon Fantasy VII.m3u
    ├── Dragon Fantasy VII - Disk1.chd
    ├── Dragon Fantasy VII - Disk2.chd
    ├── Dragon Fantasy VII - Disk3.chd
    └── Dragon Fantasy VII.m3u
```
In this case the folder will be viewed as a single game and it will launch `Dragon Fantasy VII.m3u` so you can easly swap the disks from RetroArch menu.

## How do I create a Multidisk Directory? 

Let's use the Dragon Fantasy VII example as written above.

### Step 1: Make a .m3u sub-folder
Make a new sub-folder inside the PSX roms directory where you move and store the Dragon Fantasy VII files with a .m3u file extension in the end. 
The name of the folder will be Dragon Fantasy VII.m3u and the full file path will be:

`~/retrodeck/roms/psx/Dragon Fantasy VII.m3u`


### Step 2: Make a .m3u file inside the folder.m3u
Following the example above, make an empty file inside the Dragon Fantasy VII.m3u folder called the exact same thing as the folder name in this case: `Dragon Fantasy VII.m3u`. Now the full file path to the newly created .m3u file should be like this:

`~/retrodeck/roms/psx/Dragon Fantasy VII.m3u/Dragon Fantasy VII.m3u`

### Step 3: Populate the .m3u file 

Open the `Dragon Fantasy VII.m3u` file with an text editor and write the filenames of all files contained in the folder, one per line.
When you are done, the structure  of the file should look something like this:  

`Dragon Fantasy VII - Disk1.chd`<br>
`Dragon Fantasy VII - Disk2.chd`<br>
`Dragon Fantasy VII - Disk3.chd`

Note this also works with other files types like `.bin` `.iso` `.cue` `.bin` etc.. You just need to make sure that all the files in the folders are written inside the .m3u file.

### Step 4: Launch RetroDECK
The ES-DE interface that RetroDECK uses should now pick up on the game as one file and you can change disks inside RetroArch.

# Emulators compatibility lists
Here is a collection of games that were tested on Steam Deck, not on RetroDECK specifically.
If you find some inconsistences please report them on our `#support` channel on Discord.
* [Xemu](https://xemu.app/#compatibility)
* [Citra](https://citra-emu.org/game/)
* [Dolphin](https://dolphin-emu.org/compat/?nocr=true)
* [Yuzu](https://yuzu-emu.org/game/)
* [PCSX2](https://pcsx2.net/compat/)
* [RPCS3](https://docs.google.com/spreadsheets/d/1EzTcNoKiBaMS4orZrGEOKwMpFOZEFKVSOZjLRJqzEkA/)

# Scraping

[Check out FAQ on Scraping on the wiki](https://github.com/XargonWan/RetroDECK/wiki/FAQs%3A-Frequently-asked-questions#scraping-questions) 

## Quick tips
* Register an account on https://www.screenscraper.fr/ (support them on Patreon for faster downloads, more scrapes per day and priority scraping).
* Login to your Screenscraper.fr account inside of the ES-DE interface in RetroDECK
* Choose what content you want to scrape (remember that each content you choose could take up several mb of data per game).
* Do an initial scrape of all the games you want to scrape. 
* If some games are missed do a more narrow scraping by enabling `Scraper -> Other Settings -> Interactive Mode -> On`& Scraper -> `Other Settings -> Auto-Accept Single Game Matches -> On` and choose to scrape by games missing metadata. This will allow you to select each game from a list and also tweak the searches of the missing games. In some cases you need to remove certain aspects of the name like if a rom comes both with a Japanese name and English name, you could try to remove one of the names to find a better result.
