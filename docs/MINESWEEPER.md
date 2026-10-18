# Bundled Minesweeper

Project Version: 0.9.0-dev.1

Minesweeper is installed with PC Framework under app ID `b47pc.minesweeper`. Use a powered accessible PC and select Minesweeper from the shared desktop or Start menu. Opening the desktop does not start the app. No CD or Quartermaster is required. Other installed apps and CD programs remain available on that same desktop and taskbar.

The original Lua game provides a 9×9 board with 10 mines. The first reveal and its immediate neighbors are safe; zero regions reveal connected safe tiles. The board is not guaranteed to be solvable without guessing. Reveal every safe tile to win; hitting a mine ends the game. Flags are limited to 10 and protect a tile from reveal. Wrong flags can cause a loss when chording.

| Control | Action |
| --- | --- |
| Select a covered tile | Reveal it, or toggle its flag while **Mode: Flag** is active. |
| Right-click a tile | Toggle its flag directly. |
| Select an opened number | Chord: if the adjacent flag count matches the number, reveal remaining neighbors. Incorrect flags can expose a mine. |
| Mode button | Switch Reveal/Flag, including for controller play. |
| New game | Discard the current board, flags and timer. |
| Escape/controller B | Close the hosted app using the framework's existing input flow. |

The counter shows unplaced flags and elapsed seconds since the first reveal. Time continues while minimized and stops on win/loss. `F` marks flags, `*` marks mines after a loss, and `X` marks an incorrect flag; number/symbol differences work independently of color. The app reserves font-sized controls and a status bar. If tiles cannot fit legibly, it hides the board and shows a resize/font hint, preserving its local state. Native controller routing, right-click dispatch, glyphs and layout remain runtime gates; see `MINESWEEPER_INPUT_API.json` for exact-build source observations.

The server now owns each disposable board and validates reveal/flag moves. Active progress can reduce boredom and unhappiness (increasing happiness): defaults are 2 boredom and 1 unhappiness point per 30 qualifying real seconds. Idle windows, flag spam, resets and replayed requests provide no benefit. There are no shared scores, items or experience rewards. See the [complete mood configuration and authority contract](MINESWEEPER_MOOD.md).

Minimize/restore preserves the current board, but idle time alone does not earn benefits. Close, invalid power/access or server session expiry discards it. Switching apps now retains the current board/window; idle time still earns no benefits. Boards/activity credit are not saved or resumed after reconnect/restart. Base-game mood stats remain vanilla-owned and are synchronized by the server. The display timer is separate from reward eligibility. Client inputs never write mood values or claim rewards.

Source is `shared/B47ANCEDPCFramework/Apps/MinesweeperGame.lua` (pure board rules) and `Minesweeper.lua` (installed UI using the public PC app/UI/assets API). Startup registers it once. The independent Lua-only implementation uses no copied game code, sprites, OS artwork or third-party mod source. It is included in the production manifest; examples remain excluded. The historical 0.6 development ZIP remains unchanged and does not contain the new mood feature. This is a compatible MINOR addition with no public API or persistence-schema changes.

Validation commands: `python -B scripts/check_versions.py`; `python -B tests/run_tests.py`. The latter tests all 81 first-reveal positions, mine/count invariants, flood/flags, win/loss, correct/incorrect chords, invalid coordinates, installed launch, mouse-shaped/controller-mode callbacks, minimize/reset, font/size bounds and stale/power guards. Package only on explicit request with `python -B scripts/build.py`, then `python -B scripts/check_versions.py --release`; its receipt records commit, dirty state, exact file hashes, ZIP hash, CRC/member/content checks and runtime limits. These commands do not deploy or publish.

[TESTED OFFLINE] Native-shaped host tests are not native execution. [RUNTIME GATE] Native SP/dedicated NOT TESTED; project dedicated G7 and stable-release G8 remain BLOCKED. Mood effects are gameplay and require dedicated validation; offline tests cannot prove owner stat synchronization or persistence. Validate actual enabled-mod startup, powered-PC discovery, multi-app selection, pointer/controller play, minimize/resize, split-screen and power/logoff closure on disposable saves. Development packaging is distribution evidence only.

In 0.8.0-dev.1 the common PC access check also supports occupied native furniture directly in front of the PC, including during native rest. Opening/playing does not clear the rest queue or stand the player up. Server board/mood authorization still revalidates actual seated reach, power and permissions. See SEATED_PC.md; simultaneous native endurance recovery and mood relief remain SP/dedicated acceptance gates.
