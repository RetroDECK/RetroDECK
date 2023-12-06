# Guide: ScummVM

Create a **.scummvm** file in each game directory and launch that.

The **.scummvm** file must be named using the correct **Game Short Name** and it must also contain this short name as a single string/word. You can find the complete list of supported ScummVM games with their corresponding short names [here](https:/www.scummvm.org/compatibility).<br><br>
An example setup could look like the following:

```
retrodeck/roms/scummvm/Beneath a Steel Sky/sky.scummvm
retrodeck/roms/scummvm/Flight of the Amazon Queen/queen.scummvm
```
<br>
To clarify, the **sky.scummvm** file should contain just the single word sky and likewise the **queen.scummvm** file should only contain the word queen instead of **queen:queen** or **sky:sky**.
In order to avoid having to display each game as a directory inside the game list (that needs to be entered each time you want to launch a game).
<br><br>
You can optionally interpret each game directory as a file. Make sure to read the Directories interpreted as files section here to understand how this functionality works, but essentially the following would be the setup required for our example:

```
retrodeck/roms/scummvm/sky.scummvm/sky.scummvm
retrodeck/roms/scummvm/queen.scummvm/queen.scummvm
```
<br>
In this case the two entries sky and queen will show up inside the game list and these will be handled like any other game files and can be part of automatic and custom collections for instance.
<br><br>

---

**NOTE:** This guide is taken from [the official ES-DE Documentation](https://gitlab.com/es-de/emulationstation-de/-/blob/master/USERGUIDE.md#scummvm) please check it for more information.
