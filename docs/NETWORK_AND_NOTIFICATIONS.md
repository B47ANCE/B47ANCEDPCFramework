# PC connections and notifications

Project Version: 0.11.0-dev.1

This compatible MINOR adds Connections API 1, Notification API 1 and a bundled
PC Network application. Existing desktop, CD program and media APIs remain 1.
Prepared for authorized MP testing distribution; see WORKSHOP_PUBLICATION.md for the exact uploaded commit and receipt.

## PC Network

Launch **PC Network** from a powered computer. **Network status** lists known
connected endpoints and refreshes every five seconds while the application is
open. Online means the exact placed PC is loaded, powered and inspectable by
this player. Offline / unavailable also covers permission denial; the screen
does not disclose which private condition failed. Failed refreshes clear stale
status rows. No unloaded inventory is treated as live.

In **Pairing / connections**, start pairing on the first computer and copy its
address. Visit another computer and enter that address to connect. A private
invitation belongs to the authenticated player who started it, expires after
the configured in-game interval, and supports multiple computers. Alternatively
make the first PC public to accept connections by address. Private mode stops
new public connections; it does not silently remove existing links. Select a
direct connection and Disconnect to remove its reciprocal link.

Pairing requires current configure permission at the PC being operated. Visiting
the first PC creates the private invitation; the player need not be beside both
PCs simultaneously. A still-valid invitation can pair a temporarily offline PC.
This never authorizes access to either PC's application data or inventory.

## Public interfaces

Client `require 'B47ANCEDPCFramework/API'` exposes:

- `PC.Connections.version == 1` and
  `PC.Connections.request(playerNum, computer, command, args, reply)`.
  Commands: `list`, `pair`, `public`, `connect`, `disconnect`. Changes require
  `args.revision` from the last result. `public` takes a boolean `public`;
  connect/disconnect take `peer` (the server-issued PC address).
- Replies have `status`. Successful replies include `id`, `revision`, `public`,
  `pairing`, sorted direct `peers` and the connected component `network`.
  Rows contain `id`, `online`; network rows also contain `direct`. An oversized
  historical component sets `truncated`; disconnect remains available.
- `PC.Notifications.version == 1`;
  `post(host,{id,title,message,severity,onOpen,silent})` returns a boolean.
  Use the actual application host (`ctx.host` for descriptor apps). Stable IDs
  update existing notices; `silent=true` prevents a repeated toast. Severity is
  `info`, `warning` or `error`. `onOpen` is an optional trusted local callback.
- `dismiss(host,id)`, `clear(host)` and `list(host)`. List returns defensive
  copies without callbacks. Open activates the originating app host, then calls
  its callback; the application owns restoring its content and stale guards.
  Descriptor apps should use `ctx.guard` and clear notices in `onClose`.

`PC.supports('pc-connections')` / `PC.supports('notifications')` and
`getAPIInfo()` report the additive capabilities. Notification IDs are at most
80 bytes, titles 128, messages 512; at most 16 notices per host / 32 per desktop.
The taskbar tray opens a paged panel; changed non-silent notices toast for eight
seconds. Close, power, actor or access loss removes invalid notifications.
Notifications are client-local presentation, not persistent gameplay records.
Applications must supply only information their server has authorized.

Server `require 'B47ANCEDPCFramework/Connections'` exposes
`members(actor,computer)` returning authorized online `{id,computer}` entries,
an error (or nil), and total known component size. Consumers must revalidate
their own data/media and permissions. `registerPolicy(name,fn)` adds a trusted
server predicate `(actor,computer,action)`; every registered predicate must allow
inspect/configure. A connection does not grant gameplay permission.

`DriveService.new(adapter)` additionally exposes `scanMedia(actor,computer)`
and `validateMedia(actor,computer,row)`. Scan returns a job with `step()` yielding
rows / `done`, or nil / `waiting` or an error. It examines actual accessible
adjacent storage incrementally, never mounts or moves a CD. Validation resolves
the exact physical item again through the consumer adapter. The consumer owns
application installation, snapshot schema and disclosure policy.

## Authority, persistence and bounds

Native `OnClientCommand` binds intent to the real sender; only the server changes
ModData `B47ANCEDPCConnections` schema 1. UUID markers identify exact placed PCs;
coordinates alone and display names do not identify endpoints. Reciprocal links,
public flags and expiring account-bound invitations persist. A replaced/moved
PC cannot inherit links merely by occupying the old tile. Unloaded PCs keep
their known offline identity; native object resolution controls online status.
Unknown/corrupt schemas are preserved and refused, never reset automatically.
Restart persistence uses native ModData; actual restart acceptance is pending.

Server sandbox: `ConnectionsEnabled` default true; `PairingHours` default 24,
range 1–168 in-game hours. Disabling preserves saved topology. Existing saves
start with no networks. No new user setting controls protocol limits or geometry.

Technical limits: 256 saved endpoints, 32 per connected component/direct-link
set. Oversized new links are rejected before topology mutation. RPC burst 4,
refill 2/second; client pending cap 32 and 15-second timeout. Media scans perform
64 operations per step, with caps of 4,096 items, 512 compartments, 1,024 objects
and 32 qualifying CDs. These bound work; they are not capacity/gameplay options.

## Evidence and acceptance

[VERIFIED source] Reuses existing Build 42.21.0 device, safehouse, native
ModData, authenticated command and exact-media interfaces. No custom Java or
external network sockets. Registration/callbacks are trusted mod code.

[TESTED OFFLINE — Windows, Python/Lupa Lua 5.1] `python -B tests/run_tests.py`
covers account/private/public pairing, stale revisions, expiry, persisted-service
reload, physical identity loss, offline exclusion, pre-mutation component cap,
future-schema refusal, actual incremental media scanning, status/pairing UI at
four font sizes, notification dedupe/caps/privacy/lifecycle and existing suites.
`python -B scripts/check_versions.py` checks current mirrors. Localization is
29-locale English fallback, not translated/native glyph acceptance.

[RUNTIME GATE] Native visual/controller, SP, two remote clients, delayed replies,
simultaneous network edits, unloaded buildings, privacy revocation, power loss,
disconnect/reconnect and dedicated restart NOT TESTED. G7 and stable G8 BLOCKED.
No game/server launch, packaging, deployment or publication accompanies this work.
