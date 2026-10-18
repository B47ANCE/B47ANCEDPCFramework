# B47ANCED PC Framework

Standalone Lua-only computer framework for Project Zomboid Build 42.21.

Development version: 0.5.0-dev.1. Source only; native SP and dedicated multiplayer NOT TESTED. G7 and stable G8 BLOCKED.

Use any powered placed PC (all four vanilla desktop orientations, plus other tiles tagged `CustomName=Computer`) to open an original Windows '93 desktop. The framework supplies the computer screen, drive browser, taskbar, Start menu, application hosting, keyboard/controller handling and reusable server drive bindings. It runs without Quartermaster and shows an empty desktop when no application is installed. No arbitrary executable code, filesystem access or external OS assets are loaded.

Other mods register trusted Lua apps. Quartermaster supplies `QUARTERMASTER.EXE` and its CD Writer through this interface; its ledger contents, permissions, inventory conversion and network authority stay in Quartermaster. Opening the screen or mounting a CD never automatically runs an app. Multiple registered apps can be selected from the computer context menu.

Enable `B47ANCEDPCFramework` on the server and every client alongside dependent apps. This repository has no assigned Workshop item; Workshop installation is not yet available. Quartermaster is not a dependency of this framework.

`B47ANCEDPCFramework.Enabled` is the server sandbox switch (default true). Disabling it closes screens and refuses device validation without deleting app records. App-specific gameplay settings remain with their apps. Computer identity, adjacency, scan bounds and polling limits are implementation constraints, not user-adjustable gameplay values.

## Public mod API and modular UI assets

Import `B47ANCEDPCFramework/API`, `B47ANCEDPCFramework/UI` or `B47ANCEDPCFramework/Assets` from your own client mod. Public UI API 1 supplies PC panels, hosted windows, buttons, icon buttons, text entries, dropdowns, lists, labels, tabs, wrapping toolbars, status bars, layout/focus and safe window lifecycle helpers. Assets API 1 supplies palette copies, bevels and seven scalable original icons, plus namespaced custom drawing registrations. `registerApp` provides installed apps without a CD; the existing factory/media API 1 remains compatible with Quartermaster.

`registerCDProgram` adds physical-CD programs with explicit EXE launch, version/media matching and the same hosted UI guards. Server `CDPrograms.new` lists, authorizes and resolves programs through a genuine-item DriveService. See the [CD program API, authority contract and examples](docs/CD_PROGRAM_API.md). The API supplies no CD burning or client-owned gameplay authority.

See the [consumer guide and complete public API](docs/UI_API.md), [opt-in Component Gallery](examples/ComponentGallery.lua), and [feature/functionality brainstorm](docs/ROADMAP.md). The gallery is excluded from production and must be enabled by a consumer mod. The roadmap marks multiwindow, shared notes/mail, dashboards, repairs and surveillance as proposals or research; they are not current gameplay features.

## Development

Authoritative source: `src/B47ANCEDPCFramework`. Root `VERSION` is canonical. `scripts/production-files.json` inventories shipped files. `dist/current/` is generated packaging output; it is ignored and has not been built. The framework includes no custom Java/JAR/native runtime dependency. Python and Lupa are host-only test tools.

```powershell
python -m pip install -r requirements-dev.txt
python -B scripts/check_versions.py
python -B tests/run_tests.py
```

See [application API and authority contract](docs/API.md), [source provenance and persistence](docs/ARCHITECTURE.md), [validation and runtime gates](docs/TESTING.md), and [version policy](docs/VERSION_POLICY.md). Use `python -B scripts/build.py` only when packaging is requested. It does not deploy or upload.

Mod ID: `B47ANCEDPCFramework`. Created by B47ANCE. Original owned code extracted from [Quartermaster](https://github.com/B47ANCE/B47ANCEDQuartermaster), with an isolated framework UI namespace and exact team fallback artwork. No Workshop ID has been invented.
