# About Udev rules

For these controllers to being recognized byt the system and so by RetroDECK is needed to set their own udev rule on SteamOS.

Udev rules are used to allow and manage the access to a specific third party usb device, so without a proper udev rule some devices such as the following ones could not be used by RetroDECK nor by the system.

Some notes on the udev rules:
- Setting an udev rule needs root access.
- The udev rule must be added when the emulator is not running, if it's running it must be restarted to acknowledge the change.
- The udev rules seems to be persistent even after a SteamOS update.

> **NOTE:** If running other Linux distributions the procedure might have some difference, please refer to a proper documentation or a web search.
