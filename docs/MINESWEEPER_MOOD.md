# Minesweeper mood benefits and authority

Project Version: 0.8.0-dev.1

Playing Minesweeper can reduce boredom and increase happiness. PZ represents the latter as **lower unhappiness**, so the server removes boredom/unhappiness through the existing enum stat API. Default benefits are **2 boredom points and 1 unhappiness point per 30 real seconds of qualifying play**, clamped by native stat bounds. No skill, item, stress, fatigue or other reward is added.

## What counts as playing

The server creates the 9×9 board and validates each reveal/flag intent. Only moves that newly uncover safe tiles advance activity. Between consecutive progress events, server elapsed time counts while the gap is at most the configured activity grace (default 30 seconds). A longer gap clears accumulated credit. The first progress event starts timing; simply opening a window, waiting, toggling flags, resetting or resending a move awards nothing. Revealing many cells at once still contributes only elapsed time, with at most one benefit per interval. Winning/losing has no extra reward. A final move can count if it uncovers safe tiles.

Benefits stop without further progress. Minimize/idle time alone provides none; the display timer is separate from server-validated activity credit. Network delay may reduce credit or break activity continuity; clients cannot claim elapsed time or catch-up rewards. The server validates legal moves, not human presence or a client's physical screen visibility. Automated legal intents remain bounded by the same time, progress, access and rate checks.

## Server sandbox configuration

All identifiers use page `B47ANCEDPCFramework` and have localized names/tooltips, including the existing English fallback policy in 29 locales. Numeric options are integers with step 1.

| Identifier | Default | Bounds | Meaning |
| --- | --- | --- | --- |
| `MinesweeperMoodEffects` | true | boolean | Enable mood benefits; disabling retains the playable server-owned puzzle. |
| `MinesweeperBoredomRelief` | 2 | 0–10 | Boredom removed per qualifying interval; zero disables this component. |
| `MinesweeperUnhappinessRelief` | 1 | 0–10 | Unhappiness removed per qualifying interval; zero disables this component. |
| `MinesweeperReliefInterval` | 30 | 10–300 seconds | Server-measured active play required per benefit. |
| `MinesweeperActivityTimeout` | 30 | 5–120 seconds | Maximum progress gap that counts; longer gaps clear activity credit. |

Existing `B47ANCEDPCFramework.Enabled` still gates the entire powered-PC host. Missing settings in existing saves use the defaults; invalid/non-integer/out-of-range numeric values fall back to their declared defaults rather than trusting client payloads. New server settings apply to subsequent intents. Disabling benefits clears credit on progress while disabled. Native existing-save option UI/persistence remains a runtime gate. There is no client preference or editable hidden gameplay table overriding these settings.

Technical limits remain internal: one ephemeral session per native actor, at most ten move responses per second, 81-cell snapshots, monotonically sequenced moves, bounded identifiers and 15-second client request expiry. The server expires idle sessions after five minutes and checks session validity at most once a second without world scans. These bound protocol/memory work; they are not reward multipliers.

## Ownership and trust boundaries

| State/boundary | Owner and validation |
| --- | --- |
| Board/mines, sequence, progress clock, accumulated credit and last benefit | Server/SP authority in `MinesweeperService`. No client board or win claim is accepted. |
| Client intents | Native sender supplied by `OnClientCommand`, plus server token, next sequence, reveal/flag and integer cell coordinates. PC is resolved on start; every move rechecks actual PC identity, same-floor reach, power, safehouse access, Enabled and actor life. Client actor IDs, rates and elapsed/reward fields are ignored. |
| Replies | Sent only to the native sender. Hidden cells expose no mine/count data until opened or the game ends. Client correlation/cancellation rejects duplicate, expired and closed-context replies. |
| Mood mutation | Server `Stats:remove(CharacterStat.BOREDOM/UNHAPPINESS, amount)`, using native clamp and changed results. No client stat setter. |
| MP synchronization | Existing `syncPlayerStats(actor, mask)` targets the actor's owner. Masks come from exposed `SyncPlayerStatsPacket.getBitMaskForStat`; no obsolete constant names, custom stat packet or custom Java dependency. Missing sync capability refuses mutation before changing either stat. |
| Persistence/restart | Board, token and activity credit are memory-only and are not resumed. Base-game stat persistence remains vanilla-owned; native save/rejoin behavior needs dedicated tests. No custom mood save table or migration is introduced. |

Duplicate sequence replies cannot replay a move or benefit and are rate-limited. Wrong sender/token, old sequence, invalid coordinates/action, expired session or changed PC fails closed. A new game replaces the sender's session and clears play credit; a stale stop token cannot close its replacement. A reward interval is claimed before native mutation so an error/retry cannot duplicate a partial effect. Errors propagate; they are not disguised as successful mutation. Restarts/reconnects begin fresh sessions and require new progress/time. Disconnect cleanup is bounded by weak actor keys and idle expiry; no idle tick grants benefits.

SP uses the same service directly. Multiplayer uses the `B47ANCEDPCMinesweeper` command namespace (`start`, `move`, `stop`) and targeted `result` responses. The client only renders validated snapshots and sends intents; there is no local reward fallback if the server does not respond. Use matching framework versions on peers. Existing application/UI/CD APIs and media persistence remain unchanged. The pure board module moves from client to shared under the same Lua require name; no game/save source tree is migrated.

## Evidence and remaining gates

[VERIFIED source/binding inspection] `MINESWEEPER_MOOD_API.json` fingerprints vanilla server stat calls, native player command dispatch, explicit Lua exposure of the mask helper, native clamp/serialization and owner-directed sync. Installed jar/loose stat files differ; the inspected mutation/serialization paths match, while the getter has an installed optimization. Source inspection does not establish effective runtime/classloader behavior. No installed game file was changed.

[TESTED OFFLINE, Windows/Python/Lupa Lua 5.1] `python -B scripts/check_versions.py`; `python -B tests/run_tests.py`. The suite tests server-only authority, redaction, genuine progress/time, settings/invalid values, forged sender/rates, replay/order, flags/reset/idle exclusion, power/disable/expiry, stale stop, stat bounds/sync invocation, missing-sync refusal, targeted request correlation, and duplicate/canceled/expired replies. Prior board/UI/CD/media tests remain. Native-shaped doubles do not prove stat replication or persistence.

[RUNTIME GATE] Native SP NOT TESTED; dedicated G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. Test real stat decrease and floor clamp, owner synchronization, two players/PCs, rapid/reordered/lost packets, close/minimize/AFK, movement/power/privacy loss, settings changes, disconnect/rejoin and dedicated restart/save persistence. No game/server launch, deployment, repackaging or publication is authorized by this implementation. The prior 0.6 development ZIP is preserved unchanged and does not contain this feature.

Seated access 0.8.0-dev.1 retains this authority/rate model. An occupied native seat directly in front can satisfy Device reach; the server derives it from the actor, not client payload. No rest/endurance setter is added. Validate concurrent native endurance recovery and server mood synchronization on real SP/dedicated sessions; current evidence is source/offline only. See SEATED_PC.md.
