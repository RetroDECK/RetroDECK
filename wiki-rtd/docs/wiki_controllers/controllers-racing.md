# Racing Controllers

Racing Controllers is a broad category that encompasses the vast majority of third and first party controllers that has everything to do with racing games.

Some of them might lack Linux drivers or udev rules entirely with others there is a community effort to make them work under Linux.<br>
A few of them also require Windows only software to configure various inputs and buttons.<br>

If you own a Racing Controller the best solution is just to try it on Linux via the Steam Deck Dock or a Linux PC and see if it works as expected.

If you have a Flight Controller that did not work on Linux but have found a way to make it work:<br>
- Contribute udev rules to the [game-devices-udev codeberg](https://codeberg.org/fabiscafe/game-devices-udev)
- Contribute to the Oversteer project
- (Optional) Inform the RetroDECK team on how you got it working on discord.

**Oversteer**
The Oversteer Project is trying to manage support multiple Steering Wheels on Linux. It is still in the early stages of development. <br>

```
Oversteer manages steering wheels on Linux using the features provided by the loaded modules. It doesn't provide hardware support, you'll still need a driver module that enables the hardware on Linux.
Most wheels will work but won't have FFB without specific drivers that support that feature.

[OverSteer](https://github.com/berarma/oversteer)
```

## Steering Wheels, Pedals and Gear Shifters

<img src="../../wiki_images/controllers/racing-kit.png" width="250">

Steering Wheels, Pedals and Gear Shifters all of them needs seperate driver modules and udev rules to work.
If it does work on Linux and it supports xinput, there is no reason why it should not work on RetroDECK.
