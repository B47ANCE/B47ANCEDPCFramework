# Validation

Project Version: 0.3.0-dev.1

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

## CRT/taskbar checkpoint — 0.3.0-dev.1

[TESTED OFFLINE] Framework suite additionally verifies application permission revocation immediately before Run (without waiting for render), alongside standalone behavior and existing server/media fixtures. Paired Quartermaster 0.19.0-dev.2 tests execute the actual framework desktop: independent drive/writer/ledger tasks, MRU/minimize/restore, Show Desktop, per-panel close, retained query/page/choices, hidden input/tooltip cleanup, media replacement/eject/loss, fresh resume reads, delayed replies, power/cancel behavior and containment at font heights 14/24/32/42. The same suite covers paper clipboard bounds, portrait defaults and ruling phase after scroll.

Preview rendering uses actual source with synthetic ledger data and host-font/native-widget approximations. It is not a PZ screenshot or performance measurement. No native SP or dedicated execution occurred; G6/G7 NOT TESTED and stable G8 BLOCKED. [Paired report](https://github.com/B47ANCE/B47ANCEDQuartermaster/blob/fix/clipboard-ui/docs/CLIPBOARD_UI_FIX.md).
