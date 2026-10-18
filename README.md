# B47ANCED PC Framework

Standalone Lua-only computer framework for Project Zomboid Build 42.21.

Development version: 0.2.0-dev.1. Source only; native SP and dedicated multiplayer NOT TESTED. G7 and stable G8 BLOCKED.

Use any powered placed PC (all four vanilla desktop orientations, plus other tiles tagged `CustomName=Computer`) to open an original Windows '93 desktop. The framework supplies the computer screen, drive browser, taskbar, Start menu, application hosting, keyboard/controller handling and reusable server drive bindings. It runs without Quartermaster and shows an empty desktop when no application is installed. No arbitrary executable code, filesystem access or external OS assets are loaded.

Other mods register trusted Lua apps. Quartermaster supplies `QUARTERMASTER.EXE` and its CD Writer through this interface; its ledger contents, permissions, inventory conversion and network authority stay in Quartermaster. Opening the screen or mounting a CD never automatically runs an app. Multiple registered apps can be selected from the computer context menu.

Enable `B47ANCEDPCFramework` on the server and every client alongside dependent apps. This repository has no assigned Workshop item; Workshop installation is not yet available. Quartermaster is not a dependency of this framework.

`B47ANCEDPCFramework.Enabled` is the server sandbox switch (default true). Disabling it closes screens and refuses device validation without deleting app records. App-specific gameplay settings remain with their apps. Computer identity, adjacency, scan bounds and polling limits are implementation constraints, not user-adjustable gameplay values.

## Development

Authoritative source: `src/B47ANCEDPCFramework`. Root `VERSION` is canonical. `scripts/production-files.json` inventories shipped files. `dist/current/` is generated packaging output; it is ignored and has not been built. The framework includes no custom Java/JAR/native runtime dependency. Python and Lupa are host-only test tools.

```powershell
python -m pip install -r requirements-dev.txt
python -B scripts/check_versions.py
python -B tests/run_tests.py
```

See [application API and authority contract](docs/API.md), [source provenance and persistence](docs/ARCHITECTURE.md), [validation and runtime gates](docs/TESTING.md), and [version policy](docs/VERSION_POLICY.md). Use `python -B scripts/build.py` only when packaging is requested. It does not deploy or upload.

Mod ID: `B47ANCEDPCFramework`. Created by B47ANCE. Original owned code extracted from [Quartermaster](https://github.com/B47ANCE/B47ANCEDQuartermaster), with an isolated framework UI namespace and exact team fallback artwork. No Workshop ID has been invented.
