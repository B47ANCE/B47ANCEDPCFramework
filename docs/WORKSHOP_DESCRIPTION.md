# B47ANCED PC Framework

## Overview
A shared Windows '93 computer desktop for Project Zomboid, with a beige CRT frame, teal desktop, Start menu and taskbar. Installed apps appear together and keep their windows when switching. Quartermaster adds its own ledger and CD Writer apps; this framework also runs on its own.

MP testing build - dedicated multiplayer NOT TESTED
Development version 0.9.0-dev.4. Offline regression checks pass; native single-player and dedicated multiplayer acceptance remain pending. Back up saves and use matching versions on server and clients.

## Features
- Use powered vanilla PCs in all four orientations and placed tiles carrying native Computer metadata. Power and access checks remain active.
- Use a PC from occupied native furniture directly in front of it, including while resting. Native animation and simultaneous rest behavior still need in-game testing.
- Play bundled Minesweeper without a CD: 9 by 9 board, 10 mines, safe first reveal, flags, chording, timer and New game. Includes an original mine-and-flag desktop/taskbar icon.
- Qualifying active Minesweeper play reduces boredom and unhappiness through server-validated actions. Idle windows, flag spam and resets earn no benefit.
- Let other Lua mods register installed apps and physical-CD programs, with explicit program launch and server-authorized media access.
- Public UI, drawing-assets and CD-program APIs provide reusable panels, buttons, tabs, lists, status bars, scalable pixel icons and hosted-window lifecycle helpers. The example gallery is for developers and is not installed as a gameplay app.

## Compatibility & Requirements
Project Zomboid Build 42.21.0. Mod ID: B47ANCEDPCFramework. Enable on the server and every client. Does not require Quartermaster. Apps can declare their own dependencies and access rules. No custom Java or external runtime mod dependencies.

## Configuration
Server sandbox options enable the framework and Minesweeper mood benefits. Defaults remove 2 boredom and 1 unhappiness per 30 qualifying real seconds. Relief amounts, interval and activity timeout are server options. Each app owns its own gameplay and permissions.

## Source Code & Development
GitHub: https://github.com/B47ANCE/B47ANCEDPCFramework
Public API and examples are documented in the repository. This development upload provides test distribution; it is not a stable-release or multiplayer-verification claim.

## Known Issues
Native rendering, controller focus, split screen, seated/resting behavior, multiplayer mood synchronization, multi-client media changes and reconnect/restart acceptance are NOT TESTED. Dedicated G7 and stable G8 remain BLOCKED. One content window per app; arbitrary window dragging/snapping is not implemented. CDs contain registered program descriptors, not arbitrary executable Lua loaded from media.

## Credits & Permissions
Developed by B47ANCE'd Workshop. Original Lua implementation and pixel UI geometry; extracted owned computer/UI code from B47ANCE'd Quartermaster. PC Framework cover artwork supplied by B47ANCE; the small icon is derived from that artwork. No external-mod code or OS icon sheets are included.
