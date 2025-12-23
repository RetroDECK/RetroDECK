# RetroDECK Configurator

 **Note:** 
 
- The Configurator will undergo a full redesign into a controller-friendly **Godot-based application** in the long term.
- The interface shown here represents the current implementation and is **not the final design**.


---

## Overview

The **RetroDECK Configurator** is a comprehensive, multi-purpose utility integrated directly into RetroDECK.
It serves as the primary management interface, giving users access to both core functionality and advanced tooling within the **RetroDECK Framework**.

Key capabilities include:

- Managing numerous system-wide RetroDECK features and settings.
- Providing access to maintenance tools, data operations, and component-level controls.
- Acting as the bridge between the user interface and RetroDECK’s underlying framework and automation systems.

---

## How to Open the RetroDECK Configurator

The Configurator can be launched through multiple methods:

**1. From ES-DE (Recommended)**

Navigate to the main ES-DE menu and select **RetroDECK Configurator**.

**2. From the Desktop Environment**

Use the `RetroDECK Configurator.desktop` shortcut available in your applications menu.

**3. From the Command Line (CLI)**

Run RetroDECK with the `--configurator` flag:

```
flatpak run net.retrodeck.retrodeck --configurator
```

---

## RetroDECK Configurator - Main Menu

| **Choice**                 | **Action**                                                                 | **Comments**                       |
|----------------------------|-----------------------------------------------------------------------------|------------------------------------|
| **About RetroDECK 📖**     | View patch notes, credits, and other project information.                   |      |
| **Data Management 📂**     | Move, clean, empty or rebuild RetroDECK directories.                        |          |
| **Open Component**      | Manually launch and configure individual components.  | *Advanced Users Only*       |
| **Reset Components 🔄**    | Reset a specific component or restore all RetroDECK defaults.               |       |
| **Settings ⚙️**            | Adjust core RetroDECK: Presets, Visuals, Tweaks, and Logins.                |           |
| **Steam Tools 🕹️**        | Synchronize ES-DE ☀️ Favorites ☀️ or add RetroDECK to Steam.                |           |
| **Tools ☎️**               | Run various tools: BIOS Checker, File Compressor, optional features, etc.   |     |

---

## RetroDECK Configurator - About RetroDECK

| **Choice**                         | **Action**                                                           | **Comments** |
|------------------------------------|-----------------------------------------------------------------------|--------------|
| RetroDECK: Team Credits 🏆        | View contributor credits for RetroDECK.                              |              |
| RetroDECK: Version History 📖     | View the changelog and version history of RetroDECK.                 |              |

---

## RetroDECK Configurator -  Data Management

| **Choice**                                    | **Action**                                                                                           | **Comments** |
|-----------------------------------------------|-------------------------------------------------------------------------------------------------------|--------------|
| Backup RetroDECK 📦                           | Backup and compress RetroDECK userdata into a `.tar` file.                                           |              |
| Move: All of RetroDECK 🚚                     | Move the entire RetroDECK data folder (`retrodeck`) to a new location.                              |              |
| Move: BIOS folder 🚚                          | Move the BIOS folder to a new location.                                                               |              |
| Move: Cheats folder 🚚                        | Move the cheats folder to a new location.                                                             |              |
| Move: Downloaded Media folder 🚚              | Move the ES-DE downloaded_media folder to a new location.                                           |              |
| Move: Mods folder 🚚                          | Move the mods folder to a new location.                                                               |              |
| Move: ROMs folder 🚚                          | Move the ROMs folder to a new location.                                                               |              |
| Move: Saves folder 🚚                         | Move the saves folder to a new location.                                                              |              |
| Move: Screenshots folder 🚚                   | Move the screenshots folder to a new location.                                                        |              |
| Move: Shaders folder 🚚                       | Move the shaders folder to a new location.                                                            |              |
| Move: States folder 🚚                        | Move the states folder to a new location.                                                             |              |
| Move: Themes folder 🚚                        | Move the ES-DE themes folder to a new location.                                                       |              |
| Move: Texture Packs folder 🚚                 | Move the texture_packs folder to a new location.                                                    |              |
| ROMs Folder: Clean Empty Systems 🧹           | Remove empty system folders from the ROMs directory.                                                  |              |
| ROMs Folder: Rebuild Systems               | Recreate any missing system folders in the ROMs directory.                                           |              |

---

## RetroDECK Configurator - Open Component

The **Open Component** menu is intended for **advanced users** who wish to tweak or modify default RetroDECK settings for individual components.

⚠️ **Warning:** Making manual changes to a component's configuration may create serious issues. Some settings may be overwritten during RetroDECK updates or when using presets.

⚠️ **Warning:** If a component undergoes major changes to its configuration system in future updates, your manual modifications may be **overwritten**.

The RetroDECK team encourages experimentation, but if anything goes wrong, use the built-in **reset tools** inside the RetroDECK Configurator.

---

## RetroDECK Configurator - Reset Components

The **Reset Components** menu allows users to restore **specific components**, multiple components, or the **entire RetroDECK system** to their default settings.

⚠️ **Warning:** Using this feature will overwrite any custom configurations or changes made to the selected components. Use with caution, especially if you have modified system or component settings manually.

---

## RetroDECK Configurator  -  Settings Menu

| **Choice**                                | **Action**                                                                                                      | **Comments** |
|-------------------------------------------|------------------------------------------------------------------------------------------------------------------|--------------|
| Ask-To-Exit ❓                             | Enable or disable: Show a confirmation pop-up when exiting a game (for certain components).                     |              |
| Borders 🖼️                                | Enable or disable: Borders in supported components.                                                              |              |
| PortMaster in ES-DE 🧭                    | Enable or disable: PortMaster entry in ES-DE.                                                                    |              |
| Quick Resume ⚡                           | Enable or disable: Automatic save/load of game states in supported components.                                   |              |
| RetroAchievements 🏆                      | Logging in/out of RetroAchievements in supported components.                                                     |              |
| RetroAchievements: Hardcore Mode 💀       | Enable or disable: Hardcore mode for RetroAchievements (no cheats, rewind, or save states).                      |              |
| RetroDECK Folder Iconset 🎨              | Enable or disable: RetroDECK folder iconset.                                                                     |              |
| Rewind ⏪                                 | Enable or disable: Rewind functionality in supported components.                                                 |              |
| Savestate Auto Load ⏱️                    | Enable or disable: Automatic load of the last saved state in supported components.                               |              |
| Savestate on Exit 💾                      | Enable or disable: Automatic save on exit in supported components.                                               |              |
| Swap A/B and X/Y Buttons 🟧              | Enable or disable: Swapped A/B and X/Y button layout in supported components.                                   |              |
| Universal Dynamic Input Textures 🎮       | Enable or disable: Universal Dynamic Input Textures in supported components.                                     |              |
| Widescreen 🖥️                             | Enable or disable: Widescreen mode in supported components.                                                      |              |

---

## RetroDECK Configurator - Steam Tools Menu

| **Choice**                                 | **Action**                                                                                                                           | **Comments** |
|--------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|--------------|
| **Add RetroDECK to Steam ➕**               | Integrate RetroDECK itself into your Steam library and enable Steam Input support.                                                    |              |
| **Automatic Steam Synchronization 🔄**      | Enable or disable automatic synchronization of all marked 🌟 Favorites 🌟 from ES-DE to your Steam library.                           |              |
| **Manual Steam Synchronization 🖱️**        | Manually synchronize all marked 🌟 Favorites 🌟 from ES-DE to your Steam library.                                                      |              |
| **Remove Synchronized Favorites 🗑️**        | Completely remove all previously synchronized 🌟 Favorites 🌟 from your Steam library.                                                 |              |


---

## RetroDECK Configurator - Tools Menu 

| **Choice**                             | **Action**                                                                                     | **Comments** |
|----------------------------------------|-------------------------------------------------------------------------------------------------|--------------|
| **BIOS Checker 🔍**                    | Checks BIOS and firmware availability and displays key details.                                 |              |
| **Change Logging Level 📒**            | Adjust RetroDECK logging level for debugging purposes.                                          |              |
| **Games Compressor 📦**                | Compresses games into various formats for supported systems.                                    |              |
| **Install: RPCS3 Firmware 🧱**         | Download and install PlayStation 3 firmware for the RPCS3 emulator.                             |              |
| **Install: Steam Controller Templates 🎮** | Installs RetroDECK controller templates to Steam.                                              |              |
| **Install: Vita3K Firmware 🧱**        | Download and install PlayStation Vita firmware for the Vita3K emulator.                         |              |
| **M3U Multi-File Validator 🔎**        | Validates the structure of multi-file or multi-disc games.                                      |              |
| **Repair RetroDECK Paths**          | Fix RetroDECK folder paths for missing or misconfigured directories.                             |              |
| **Update Notification**             | Enable or disable notifications for new RetroDECK versions.                                     |              |

---


