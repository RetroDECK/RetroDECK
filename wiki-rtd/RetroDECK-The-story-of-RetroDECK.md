# How RetroDECK was born? 
Let's take a step back.

RetroDECK was born on March 4th 2022 in Kyoto, Japan, with the name of [351EDECK](https://imgur.com/a/tGC9ZGO) because I am also one of the founding members of 351ELEC, now [AmberELEC](https://amberelec.org/).
What I wanted to do was to "port" 351ELEC to the Steam Deck, but instead of doing a custom firmware to flash, doing it as an application that could be launched from Steam.
Eventually, after talking to the other team members, we decided that we didn't want to support another platform such as Steam Deck, so I decided to continue the project on my own, renaming it to RetroDECK.

Back then I had many options on how to create 351EDECK, such as a bash script, appimage and flatpak.
In the beginning I opted for a simple shell script, in fact RetroDECK/351EDECK v0.1a existed as a mere shell script.
However I had bad feedbacks from the community because someone was feeling unsafe to give my script the root privileges so evaluating the Steam Deck use case I felt like it was not the right direction to take, the people was not feeling comfortable to give the sudo to a random script downloaded from the internet, so they asked to packetize it in some way.

Valve suggests the flatpak technology to port the applications on Steam Deck so, I decided to follow their guidelines, and I created the RetroDECK that you know today, starting from a Manjaro virtual machine as a development environment because I didn't have a Steam Deck yet.

-Xargon