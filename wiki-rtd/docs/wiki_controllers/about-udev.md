# About udev

udev is a device manager for the Linux kernel that gives the system access to various running hardware via device `.rules` files also known as `udev rules`.

## Important directories

`/lib/udev/rules.d/`<br>

This directory contains the default `.rules file` shipped by your system. They should generally not be edited.

`/etc/udev/rules.d/` or `/run/udev/rules.d` (depending on the system) <br>

This directory contains custom `.rules file` additions to those shipped in `/lib/udev/rules.d/` and the administrator can add more rules into this directory.

If a  `.rules file` exist for the same device under `/lib/udev/rules.d/` and `/etc/udev/rules.d/` the `/etc` version will always take preset over the `lib` version.

## Example of a .rules file

The content of a Merlin UTMS modem .rules file.
```
ATTRS{prod_id2}=="Merlin UMTS Modem", ATTRS{prod_id1}=="Novatel Wireless", SYMLINK+="MerlinUMTS"
```

A .rules file can also contain more the one devices example multiple 8Bitdo controllers:
```
# 8Bitdo F30 P1
SUBSYSTEM=="input", ATTRS{name}=="8Bitdo FC30 GamePad", ENV{ID_INPUT_JOYSTICK}="1", TAG+="uaccess"

# 8Bitdo F30 P2
SUBSYSTEM=="input", ATTRS{name}=="8Bitdo FC30 II", ENV{ID_INPUT_JOYSTICK}="1", TAG+="uaccess"
```

## Adding Controllers
For these controllers to being recognized but the system and so by RetroDECK is needed to set their own udev rule on SteamOS.

Udev rules are used to allow and manage the access to a specific third party usb device, so without a proper udev rule some devices such as the following ones could not be used by RetroDECK nor by the system.

Some notes on the udev rules:
- Setting an udev rule needs root access.
- The udev rule must be added when the emulator is not running, if it's running it must be restarted to acknowledge the change.
- The udev rules seems to be persistent even after a SteamOS update.

> **NOTE:** If running other Linux distributions the procedure might have some difference, please refer to a proper documentation or a web search.
