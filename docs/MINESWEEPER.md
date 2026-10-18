# Bundled Minesweeper

Project Version: 0.6.0-dev.1

Minesweeper is installed with PC Framework under app ID `b47pc.minesweeper`. Use a powered accessible PC, choose Minesweeper's desktop from the world context menu when several apps are installed, then select its application icon or Start entry. Opening the desktop does not start the app. No CD or Quartermaster is required. Existing app-specific desktops and CD programs remain available through their context-menu entries.

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

Each hosted app owns a fresh disposable board. Minimize/restore preserves it. App closure, switching to another app, power/access loss, disconnect or restarting the game discards it. No board, score or timer is written to game saves or shared with other players. There are no inventory effects, world changes, experience, boredom/stress changes or rewards. The client owns only this local puzzle/presentation; no shared gameplay authority or custom network protocol is introduced. Future shared scores/rewards require their own server-authoritative design.

Configuration assessment: the fixed beginner board is the bundled puzzle format, not a world-balance setting. Flag mode and window layout are temporary local controls. No shared behavior is configurable or added here; existing server `B47ANCEDPCFramework.Enabled` continues to govern PC availability. Larger boards, difficulty options, saved scores and additional games remain future app work.

Source is `client/B47ANCEDPCFramework/Apps/MinesweeperGame.lua` (pure board rules) and `Minesweeper.lua` (installed UI using the public PC app/UI/assets API). Startup registers it once. The independent Lua-only implementation uses no copied game code, sprites, OS artwork or third-party mod source. It is included in the production manifest and the user-requested framework development ZIP; examples remain excluded. This is a compatible MINOR addition with no public API or persistence-schema changes.

Validation commands: `python -B scripts/check_versions.py`; `python -B tests/run_tests.py`. The latter tests all 81 first-reveal positions, mine/count invariants, flood/flags, win/loss, correct/incorrect chords, invalid coordinates, installed launch, mouse-shaped/controller-mode callbacks, minimize/reset, font/size bounds and stale/power guards. Package only on explicit request with `python -B scripts/build.py`, then `python -B scripts/check_versions.py --release`; its receipt records commit, dirty state, exact file hashes, ZIP hash, CRC/member/content checks and runtime limits. These commands do not deploy or publish.

[TESTED OFFLINE] Native-shaped host tests are not native execution. [RUNTIME GATE] Native SP/dedicated NOT TESTED; project dedicated G7 and stable-release G8 remain BLOCKED. The puzzle has no shared gameplay to synchronize, but this does not waive the framework's stricter existing runtime gates or verify any consumer transport. Validate actual enabled-mod startup, powered-PC discovery, multi-app selection, pointer/controller play, minimize/resize, split-screen and power/logoff closure on disposable saves. Development packaging is distribution evidence only.
