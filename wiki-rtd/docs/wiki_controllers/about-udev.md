# About udev

udev is a device manager for the Linux kernel that gives the system access to various running hardware via device `.rules` files also known as `udev rules`.

udev rules are used to allow and manage the access to a specific devices, so without a proper udev rule some devices such as custom controller could not be used by RetroDECK nor by Steam or any other part of the system.

- Setting an udev rule needs administrator root access with sudo.
- The udev rule must be added when the RetroDECK or any other software that you want access to the device is not running.
- For SteamOS or other immutable systems udev rules might or might not persistent persit over SteamOS updates (we can't say for certain).

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

## Controller udev projects
**Valve's - Steam Devices**:
The Steam Devices package is usually installed when you install Steam on your system, it contains rules for the most common controllers. <br>
[steam-devices](https://github.com/ValveSoftware/steam-devices)

**Game Devices udev**
The following project is an effort to combine all game devices into one package but it is still early and several are missing.<br>
[game-devices-udev](https://codeberg.org/fabiscafe/game-devices-udev)

**Batocera udev**
The Batocera project has also combined a list of other controllers that might be missing from the two projects above.
[Batocera - Controllers])https://github.com/batocera-linux/batocera.linux/tree/master/package/batocera/controllers)
