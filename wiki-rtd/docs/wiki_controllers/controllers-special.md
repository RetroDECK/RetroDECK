# Special Controllers

Special Controllers is a broad category that encompasses the vast majority of third and first party controllers that don't fit anywhere else.
They might have been made for a single game.

# About udev rules
For these controllers to being recognized byt the system and so by RetroDECK is needed to set their own udev rule on SteamOS.

Udev rules are used to allow and manage the access to a specific third party usb device, so without a proper udev rule some devices such as the following ones could not be used by RetroDECK nor by the system.

Some notes on the udev rules:
- Setting an udev rule needs root access.
- The udev rule must be added when the emulator is not running, if it's running it must be restarted to acknowledge the change.
- The udev rules seems to be persistent even after a SteamOS update.

> **NOTE:** If running other Linux distributions the procedure might have some difference, please refer to a proper documentation or a web search. 

## LEGO Dimensions - LEGO ToyPad

<img src="../../wiki_images/devices/lego-toypad.jpg" width="350">

The LEGO Toypad is used for the game LEGO Dimensions for the following platforms:

- PlayStation 3
- PlayStation 4 (Not available on RetroDECK)
- Xbox One (Not available on RetroDECK)
- Xbox 360
- Wii U

### How to configure
At the moment of writing the best way to play this game it's its PS3 version as the WiiU version of the game is not fully supported by its emulator.

Just connect the ToyPad before starting the game.

> **NOTE:** the ToyPad must be connected to an alimented hub such as the Steam Dock. Directly connecting the ToyPad to the Steam Deck it's not working as the Steam Deck is not giving it enough power to turn it on constantly.

This controller needs to set a system's udev rule, just execute this in the terminal:
```bash
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="0e6f", ATTRS{idProduct}=="0241", MODE="0666"' | sudo tee -a /etc/udev/rules.d/71-toypad.rules > /dev/null
sudo udevadm control --reload-rules
```

## Skylanders - Portal of Power

<img src="../../wiki_images/devices/skylanders-portal.jpg" width="350">

The Skylanders Portal of Power is used for the Skylanders game Series.

### How to configure
The Skylanders Portal of Power should work very similar to the LEGO Dimensions ToyPad, however the udev rule might be different.
The RetroDECK Team don't own this game nor its hardware for a proper testing, please report back if you wish to test it.

## Official GameCube Controller Adapter for Wii U

<img src="../../wiki_images/devices/wiiu-gcpad-adapter.jpg" width="350">

WIP
