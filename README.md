# B47ANCE'd PC Framework

Standalone Lua-only computer framework for Project Zomboid Build 42.21.

Development version: 0.11.0-dev.2. Development build; native SP and dedicated multiplayer NOT TESTED. G7 and stable G8 BLOCKED.

Use any powered placed PC (all four vanilla desktop orientations, plus other tiles tagged `CustomName=Computer`) to open an original Windows '93 desktop. The framework supplies the computer screen, drive browser, taskbar, Start menu, application hosting, keyboard/controller handling and reusable server drive bindings. It runs without Quartermaster and includes Minesweeper as an installed app. No arbitrary executable code, filesystem access or external OS assets are loaded.

You can also use a PC while resting in native furniture directly in front of it. The framework keeps the seat/rest action intact and checks the occupied seat, facing and barriers on both peers. [Seated access rules and runtime limits](docs/SEATED_PC.md).

Other mods register trusted Lua apps. Quartermaster supplies `QUARTERMASTER.EXE` and its CD Writer through this interface; its ledger contents, permissions, inventory conversion and network authority stay in Quartermaster. Opening the screen or mounting a CD never automatically runs an app. All available apps now share one desktop and Start menu. Their windows remain on the same taskbar when switching apps. The shell uses the approved beige B47 / CRT 93 design, original pixel icons and physical logoff control. [Shared desktop, CD providers and lifecycle](docs/UNIFIED_DESKTOP.md).

Enable `B47ANCEDPCFramework` on the server and every client alongside dependent apps. The [public Workshop MP testing build](https://steamcommunity.com/sharedfiles/filedetails/?id=3822042011) is item 3822042011; WORKSHOP_ID.txt is the canonical identity. SteamCMD upload succeeded; native SP/dedicated remain NOT TESTED. Quartermaster is not a dependency of this framework.

`B47ANCEDPCFramework.Enabled` is the server sandbox switch (default true). Disabling it closes screens and refuses device validation without deleting app records. App-specific gameplay settings remain with their apps. Computer identity, adjacent/seated reach, scan bounds and polling limits are implementation constraints, not user-adjustable gameplay values.

## Network status and notifications

Open **PC Network** to see online/offline status across connected computers. Start pairing on one PC, then visit another and enter its address; repeat for multiple computers, or opt into public pairing. Private invitations expire and belong to the player who started them. Links persist but never grant inventory access or turn unloaded PCs into live devices. Power and current access determine online status.

Apps can use **Notification API 1** for taskbar notices, deduplicated updates and guarded Open actions. **Connections API 1** supplies sender-validated persistent pairing and authorized online members. Reusable read-only media scans let apps inspect real local CDs without moving them. Quartermaster uses these APIs for low-stock alerts and its multi-building Base Ledger. [API, settings, privacy and validation](docs/NETWORK_AND_NOTIFICATIONS.md).

This source version is the authorized MP testing candidate. Native SP/dedicated acceptance is pending; upload and runtime evidence remain separate. See the publication record for the exact distributed commit.

## Bundled Minesweeper

Use a powered PC and launch Minesweeper from the shared desktop or Start menu. The installed 9×9/10-mine game needs no CD. It includes a safe first reveal, flood reveal, flags, number chording, win/loss, a timer and New game. Mouse right-click and the Reveal/Flag mode provide flagging. Each player has a disposable server-owned board. Validated active play reduces boredom and unhappiness (greater happiness), with server sandbox controls. Defaults are 2 boredom and 1 unhappiness point per 30 active seconds; idle/reset/flag spam earns nothing. No shared scores or item rewards. [Controls, lifecycle and validation](docs/MINESWEEPER.md).

## Public mod API and modular UI assets

Import `B47ANCEDPCFramework/API`, `B47ANCEDPCFramework/UI` or `B47ANCEDPCFramework/Assets` from your own client mod. Public UI API 1 supplies PC panels, hosted windows, buttons, icon buttons, text entries, dropdowns, lists, labels, tabs, wrapping toolbars, status bars, layout/focus and safe window lifecycle helpers. Assets API 1 supplies palette copies, bevels and eight scalable original icons, plus namespaced custom drawing registrations. `registerApp` provides installed apps without a CD; the existing factory/media API 1 remains compatible with Quartermaster.

`registerCDProgram` adds physical-CD programs with explicit EXE launch, version/media matching and the same hosted UI guards. Server `CDPrograms.new` lists, authorizes and resolves programs through a genuine-item DriveService. See the [CD program API, authority contract and examples](docs/CD_PROGRAM_API.md). The API supplies no CD burning or client-owned gameplay authority.

See the [consumer guide and complete public API](docs/UI_API.md), [opt-in Component Gallery](examples/ComponentGallery.lua), and [feature/functionality brainstorm](docs/ROADMAP.md). The gallery is excluded from production and must be enabled by a consumer mod. Retained app/tool windows are implemented; arbitrary window drag/snap, shared notes/mail, dashboards, repairs and surveillance remain proposals or research.

## Development

Authoritative source: `src/B47ANCEDPCFramework`. Root `VERSION` is canonical. `scripts/production-files.json` inventories shipped files. `dist/current/` is generated packaging output; it is ignored and built only on explicit request. The framework includes no custom Java/JAR/native runtime dependency. Python and Lupa are host-only test tools.

```powershell
python -m pip install -r requirements-dev.txt
python -B scripts/check_versions.py
python -B tests/run_tests.py
```

See [application API and authority contract](docs/API.md), [source provenance and persistence](docs/ARCHITECTURE.md), [validation and runtime gates](docs/TESTING.md), and [version policy](docs/VERSION_POLICY.md). Use `python -B scripts/build.py` only when packaging is requested. It does not deploy or upload.

Mod ID: `B47ANCEDPCFramework`. Created by B47ANCE. Original owned code extracted from [Quartermaster](https://github.com/B47ANCE/B47ANCEDQuartermaster), with an isolated framework UI namespace and exact team fallback artwork. No Workshop ID has been invented.

Publication preparation: canonical Workshop prose is in docs/WORKSHOP_DESCRIPTION.md and docs/WORKSHOP_CHANGELOG.md. The current approved PC Framework cover is exported to preview-client.png; original source and export provenance are retained in assets/branding. After scripts/build.py, scripts/prepare_workshop.py stages exact package bytes and writes a source/package/VDF manifest without uploading or restarting Steam. First-item creation requires the explicit --create-public flag and refuses an existing WORKSHOP_ID.txt. Later submissions preserve existing visibility.

Artwork checkpoint 0.9.0-dev.4 uses the user-supplied B47ANCE'd PC Framework illustration for the Workshop preview and in-game poster, with a computer-only small icon. Editable source, export settings and hashes are in assets/branding; artwork replaces the earlier fallback independently for all three approved roles. No gameplay behavior changes.

The 0.9.0-dev.4 artwork upload succeeded. Steam displayed a temporary automated-content-review notice at verification; the configured visibility remains public. See docs/WORKSHOP_PUBLICATION.md for exact source/package hashes and the observed availability limit. Native runtime acceptance remains NOT TESTED.

Icon correction 0.9.0-dev.5 removes the small computer icon's exterior backdrop into genuine PNG transparency. The approved 512px thumbnail/poster remain byte-identical. The original opaque crop and current transparent derivative are retained separately in assets/branding, with icon-only export, alpha/corner checks and exact hashes. No gameplay or API changes.

Full PC UI 0.10.0-dev.1 shows a straight-on 2D PC: CRT and horizontal system unit, with no keyboard or mouse artwork. Apps run inside the 4:3 monitor; uniform resizing preserves hardware proportions and the case power button keeps its existing logoff action. Client presentation only; APIs, server commands, sandbox behavior and saves stay unchanged. Includes the true-alpha small icon. PR #9 is merged and this version was explicitly published to item 3822042011 as an MP testing build. See docs/WORKSHOP_PUBLICATION.md for source/package hashes and validation limits; native SP/dedicated remain NOT TESTED.
