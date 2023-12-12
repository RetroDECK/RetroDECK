# Toys-to-life Controllers

Toys-to-life Controllers is a broad category that encompasses the vast majority of mostly first party controllers that are used to connect collectable toys figures that can via the controller interact with the game.

## LEGO Dimensions

### LEGO ToyPad

<img src="../../wiki_images/controllers/lego-toypad.png" width="250">

#### Installing the Toypad

This controller needs to set a system's udev rule, just execute this in the terminal:
```bash
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="0e6f", ATTRS{idProduct}=="0241", MODE="0666"' | sudo tee -a /etc/udev/rules.d/71-toypad.rules > /dev/null
sudo udevadm control --reload-rules
```

#### What emulator support the Toypad?
At the moment of writing the best way to play LEGO Dimensions with the LEGO Toypad is to use the PS3 version and the RPCS3 emulator.
Just connect the ToyPad to a USB port before starting the game.

**Special Notes on the Steam Deck**
The ToyPad must be connected to an alimented hub such as the a USB port of the Steam Dock. <br>
Directly connecting the ToyPad to the Steam Deck it's not working as the Steam Deck can not give the ToyPad enought power output.

## Skylanders

### Portal of Power

<img src="../../wiki_images/controllers/portal-of-power.png" width="250">

The Portal of Power is used for the Skylanders game Series.

#### How to configure
WIP


### Traptanium Portal

<img src="../../wiki_images/controllers/traptanium-portal.png" width="250">

The Traptanium Portal is used for the game Skylanders: Trap Team.

#### How to configure
WIP

## Disney Infinity

### The Disney Infinity Base

<img src="../../wiki_images/controllers/disney-infinity-base.png" width="250">

#### How to configure
WIP

