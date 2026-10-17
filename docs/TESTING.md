# Validation

Project Version: 0.1.0-dev.1

[TESTED OFFLINE, Windows/Python/Lupa Lua 5.1] `python -B scripts/check_versions.py` and `python -B tests/run_tests.py` pass. Host dependency: `lupa==2.6`; it is not a game dependency. Native-shaped doubles prove only the listed offline behaviors.

- Independent framework-only world/device tests: stock sprite, loaded identity, power, safehouse fail-closed, sandbox disable, invalid descriptor/client requests, sender-bound/expired offers, permission denial, exact-media retention, persisted-store reload, lost CD, stale eject and future schema refusal.
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
