# Using a PC from a seat

Project Version: 0.10.0-dev.1

Use native Rest on furniture directly in front of a powered PC, then use the PC's normal context action. The desktop and its installed/CD apps can open while that rest action is queued. The framework does not clear timed actions, stand the player up, change endurance, or set native rest/seating flags. If a seated player cannot reach the PC, the context action does not initiate walking. Ordinary adjacent access is unchanged.

The additional reach path requires all of the following:

- The actual actor reports native furniture seating and an occupied world object with native seating positions. Ground sitting and a remembered bed alone do not qualify.
- The exact occupied furniture is still loaded in its square/object slot, on the PC's floor, one cardinal tile directly in front of the PC. Stock PC tiles 72/73/74/75 face S/E/N/W; other `CustomName=Computer` tiles must have an exact `Facing` of N/S/E/W. Unknown orientations and side/back seats grant no additional reach.
- The actor's current square is at most one tile from the occupied furniture. This accommodates native seating animation offsets without permitting arbitrary distant use.
- Native `canReachTo` accepts both short segments: actor to furniture and furniture to PC. Walls, closed barriers and floor differences cannot be bypassed by the new path.

The complete `Device.computer(actor,object,true)` check still requires a loaded genuine PC, electricity, framework Enabled and multiplayer safehouse permissions. Application privacy remains additional. `Device.reachable` supplies physical reach only; `Device.isSeated` and `Device.seatedReachable` are helpers, not authorization grants. Consumers must retain the complete device/application checks.

[VERIFIED source] The same shared helper runs on client and server. Native `ISRestAction` records the furniture on both sides, and native sitting-state processing maintains the sitting flag. Server commands resolve the authenticated actor's actual seating state; a client's seat coordinates, rest flag or UI state cannot grant access. Minesweeper, DriveService/CD adapters and Quartermaster's existing Device wrapper inherit this rule. Each command and ongoing desktop lifecycle revalidates access. Removing a chair, moving away, losing power or losing permissions removes access. The implementation adds no custom seat packet, stored record or migration; reconnect/restoration follows native seating and is rechecked, not remembered as a framework grant.

Native rest can finish its timed action while furniture sitting and passive endurance recovery continue. The framework therefore does not require an active `ISRestAction` or a persistent resting flag. Seat position/identity and bounded barrier checks are physical access invariants, not adjustable gameplay rates. No sandbox option is added; existing authoritative Enabled and app gameplay options still apply. Minesweeper's server-owned boredom/unhappiness effects are unchanged; endurance remains native-owned.

[TESTED OFFLINE, Windows/Lupa Lua 5.1] `python -B tests/run_tests.py` includes `test_seated_pc.lua`: four orientations, alternate metadata, invalid/stale/removed furniture, no seating data, unloaded squares, floors, body/seat barriers, distance, power/safehouse/Enabled refusal, forged client seat claims, server program revalidation, a queued rest-action double, immediate desktop opening, no walking, and closing after chair removal. `python -B tests/check_native_computers.py --game <installed-game-root>` verifies installed stock facing metadata. See `SEATED_PC_API.json` for source fingerprints against 42.21.0 / Steam build 25485521.

[RUNTIME GATE] Native SP and dedicated multiplayer NOT TESTED. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. On disposable saves, test real rest animation/queue behavior in all four orientations, single/multitile seats and custom tagged PCs; verify walls/doors, power/privacy loss, chair removal, standing/walking, split-screen/controller focus, Minesweeper mood relief together with native endurance recovery, Quartermaster/CD operations, two clients, delayed commands, reconnect and server restart. Source inspection and doubles do not prove native seat offsets, state replication or uninterrupted recovery. No game/server launch, packaging, deployment or publication was performed.
