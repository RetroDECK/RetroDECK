# Special Controllers

Special Controllers is a broad category that encompasses the vast majority of third and first party controllers that don't fit anywhere else.
They might have been made for a single game.

## LEGO Dimensions - LEGO ToyPad

<img src="../../wiki_images/controllers/lego-toypad.jpg" width="250">

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

<img src="../../wiki_images/controllers/skylanders-portal.jpg" width="250">

The Skylanders Portal of Power is used for the Skylanders game Series.

### How to configure
The Skylanders Portal of Power should work very similarly to the LEGO Dimensions ToyPad, however the udev rule might be different.
The RetroDECK Team don't own this game nor its hardware for a proper testing, please report back if you wish to test it.

## DK Bongos

<img src="../../wiki_images/controllers/dk-bongos.jpg" width="250">

WIP
