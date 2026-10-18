# Validation

Project Version: 0.4.0-dev.1

[TESTED OFFLINE, Windows/Python/Lupa Lua 5.1] `python -B scripts/check_versions.py` and `python -B tests/run_tests.py` pass. Host dependency: `lupa==2.6`; it is not a game dependency. Native-shaped doubles prove only the listed offline behaviors.

- Independent framework-only world/device tests: all four stock PC orientations, Computer-tagged alternate tiles, rejection of unrelated powered appliances, loaded identity, power, safehouse fail-closed, sandbox disable, invalid descriptor/client requests, sender-bound/expired offers, permission denial, exact-media retention, persisted-store reload, lost CD, stale eject and future schema refusal.
- Framework-only desktop tests: no Quartermaster imports, no registered app, no auto-run, app registration/selection, duplicate registration, unknown/disabled app, incompatible media, late replies, hidden-tool controller focus and screen cleanup.
- Static checks: Lua 5.1 parse, case-correct framework requires, no Java/JAR/classes, exact source inventory, folder case collisions and 29-locale English fallback parity. Fallback parity is not translation quality or native glyph proof.
- Paired Quartermaster suite with real Rooms checkout: paper/CD transactions, forged/replayed requests, drive loss, settings, inventory conservation, scope permissions, requirement/freshness, UI geometry and existing unrelated regressions. Native fixture imports do not launch the game.

Exact paired command, run from Quartermaster's extraction checkout:

```powershell
python -B tests/run_tests.py --require-rooms --rooms <B47ANCEDRooms checkout> --pc-framework <B47ANCEDPCFramework checkout>
python -B scripts/check_deployment.py
python -B tests/test_deployment.py
```

[VERIFIED source] Existing API fixture receipt is Quartermaster `docs/LEDGER_NATIVE_EVIDENCE_2026-10-16.json` for game 42.21.0 / Steam build 25485521. Current native-file fingerprints used here are in `NATIVE_EVIDENCE.json`; prior receipts retain their exact versions. New extraction uses the already inspected native interfaces; this does not constitute native execution.

[RUNTIME GATE] Native SP NOT TESTED. Dedicated G7 BLOCKED / NOT TESTED. Stable-release G8 BLOCKED. Validate enable/load order, standalone context/desktop, Quartermaster app availability, writer/native timing, screen scaling/tooltips/controller, two clients on one drive, delayed/reordered replies, privacy changes, power loss, CD transfers, restart/rejoin and unchanged older persisted binding records on disposable save fixtures. No real save was changed. No game/server was launched, package built, local mod deployed or Workshop upload performed. No Workshop item is assigned to PC Framework.

Powered-PC expansion validation (0.2.0-dev.1): `python -B tests/run_tests.py` checks electricity on/off per orientation, alternate metadata, nil/missing properties, invalid labels, server safehouse denial, detached objects, distance/floor and sandbox disable. `python -B tests/check_native_computers.py --game <installed-game-root>` reads the installed native tile definitions, verifies all four facing records, and checks recognition against the production Lua helper. These are source/offline results, not native invocation. Source evidence and method observations are recorded in `POWERED_PC_API.json`; game 42.21.0 / installed Steam build 25485521, runtime NOT TESTED.

Public SDK 0.3.0-dev.1: the independent suite now includes `test_public_ui.lua` and an actual opt-in consumer loaded from `examples/ComponentGallery.lua`. It tests palette/metric isolation, built-in/custom icon scale/bounds, public native controls, explicit installed-app launch, resize/font bounds, visible/enabled focus rows, synchronous and stale callbacks, power/privacy/actor loss, failed construction and cleanup exceptions. Original legacy app/drive tests and the complete Quartermaster/Rooms regression suite pass against the new framework checkout. Example localization keys are checked against its separate English strings; it is not part of the production manifest. New API source observations are recorded in `UI_NATIVE_API.json` and the local unmanaged API audit library; this is source evidence, not runtime proof.

Commands: `python -B scripts/check_versions.py`; `python -B tests/run_tests.py`; the paired command above with `--pc-framework` pointing to this SDK checkout. Packaging, native SP and dedicated multiplayer were not run. Prior 0.1/0.2 native receipts remain historical and are not relabeled as new runtime evidence. Validate actual native font/focus/tooltip/layering, split-screen, app switching/error recovery and server-authorized media behavior before claiming dedicated G7 or stable G8 PASS.

Roadmap UI 0.4.0-dev.1: `python -B tests/run_tests.py` adds `test_composites.lua` and the updated real gallery. Offline checks cover tab visibility/selection/no-op notifications, retained page data, root focus exclusion for hidden pages, unchanged-paint focus retention, toolbar action isolation/disable, invalid descriptors without partial attachment, status sizing, and wrapping at widths 100/300/700 with fonts 14/24/32/42. These use the existing source-verified native panel/button/text APIs; no new engine APIs, gameplay state, network commands or sandbox values were introduced. UI API remains 1 with additive `tabs`, `toolbars`, `status-bars` capability flags. Native SP, keyboard/controller routing, split-screen and dedicated G7 remain NOT TESTED/BLOCKED; stable G8 remains BLOCKED.
