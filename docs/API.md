# Application API 1

Project Version: 0.11.0-dev.1

Current addition: [Connections and Notification APIs 1](NETWORK_AND_NOTIFICATIONS.md). Existing authority and historical evidence below remain distinct.
The public SDK now also exposes **UI API 1** and **drawing-assets API 1** through `require 'B47ANCEDPCFramework/UI'`, `require 'B47ANCEDPCFramework/Assets'`, `PC.UI` and `PC.Assets`. Use descriptor-based `PC.registerApp` for installed, non-media apps. See the [public UI contract, controls, assets, lifecycle and working example](UI_API.md). The factory/media API below remains supported unchanged. [Feature ideas and implementation status](ROADMAP.md).

For descriptor-based physical-CD programs, use `PC.registerCDProgram` with authenticated drive/run callbacks and a server `CDPrograms` registry. See [CD program API 1](CD_PROGRAM_API.md) for exact request/reply types, server resolve checks, stale reply guards and opt-in examples. This additive API retains all legacy hooks below.

The trusted local Lua registration interface is client presentation, not a network RPC or authorization capability. Declare `B47ANCEDPCFramework` in the app mod's `mod.info` `require` list. Never bundle framework runtime files into an app.

```lua
local PC=require 'B47ANCEDPCFramework/API'
PC.registerApplication('example',function(playerNum,computer)
 return {
  file='EXAMPLE.EXE',
  canRun=function(media) return media:getFullType()=='Example.Media' end,
  drive=function(command,args,reply)
   -- list/mount/eject: send intent through your authenticated server service.
   -- Add computer coordinates; reply only with server-approved media proxies.
  end,
  read=function(media,host)
   -- Ask the server to validate/read the actual media, then host:showApp(panel,title).
  end
 }
end,'Example')
-- Explicitly select an app. Omit id to open the unified desktop without running an app.
PC.open(playerNum,computer,'example')
```

Factories return nil when the app is disabled and must have no gameplay side effects: availability checks may invoke them before opening a screen. IDs are stable, unique, at most 80 characters; duplicate registration is rejected. `applications()` returns sorted IDs; `availableApplications(playerNum,computer)` filters enabled/authorized apps; `applicationTitle(id)` returns its presentation title. `apiVersion` is 1 and is independent of the project version. Every available app is listed on the shared desktop and Start menu; the world menu supplies one computer action.

Optional hooks: `enabled()` (default framework switch), `canUse(actor,computer,near)` (additional app privacy), `busy()`, `close()` (cancel this user's app work), `text(key,...)` (domain status translations), `writer(host,hooks)` and `toolTitle` (one hosted app tool). `inventory`, `burn` and other domain callbacks may be consumed by that tool, never by the desktop. Core powered-device/safehouse validation always applies in addition to app callbacks. One native CRT root owns independent app host sessions. Switching apps retains their panels and media state; a tool/writer has a separate task. Foreground `ComputerUI.active` identity does not mean another host is closed; use `ComputerUI.isLive(host)` or a guarded context. Optional `launcherTitle` supplies an already-localized short launcher caption. `host.root` is the native widget; API-1 host geometry/input methods delegate to it. Native keyboard Escape and controller B return/minimize/close through the existing desktop flow.

Drive replies: `{status='ok',choices={{id=<native item ID>,name=<sanitized label>,fullType=<type>,token=<sender-bound offer>}},mounted=<same descriptor plus drive ID>,slot=<binding ID>,occupied=<boolean>}`. `mount` submits only an offer token; `eject` submits the current binding ID. UI proxies never move items or authorize reads. Missing providers show an empty drive. `canRun` must explicitly accept the media type; only Run/EXE double-click calls `read`. On media change, eject, power loss, app disable, actor replacement/death or screen close, the screen discards the app UI. App server services must independently revalidate every operation, including replies arriving after UI close.

## Server drive engine

`require('B47ANCEDPCFramework/DriveService').new(adapter)` creates an isolated binding service. It exposes `handle(actor,command,args)`, `read`, `provider`, `occupied`, `busy`, `protected` and `candidates`. It refuses clients and invalid/dead actors. Call `handle` only after your transport authenticates the sender; never accept an actor ID from client payloads.

Adapter fields: `store`, `computerKey`, `storageKey`; `media={object,computer,disc}`; `enabled()`, `valid(target,actor)`, `can(actor,target,action)`, `target(object,compartment,actor)`, `snapshot(item)`, `grants()`, `building(computer)`; `commands={list,mount,eject}` and `status={disabled,power,denied,changed,occupied}`. All are trusted server code. Supply app-safe physical-target validation, private-room permissions and genuine media-to-snapshot binding. `snapshot` must return nil for forged metadata. The `computer` callback must include Device validation and any app-specific permissions. The engine owns no application snapshots, inventory conversions or generic client command handler.

The server re-resolves world objects, storage markers, exact native media and app snapshots; mount/eject require configure access. Discovery offers are sender/computer-bound and expire after 30 seconds. Real media remain in adjacent storage. Binding schema 1 persists under the supplied store and object keys; supply stable unique namespaces. Unknown/future/corrupt data fail closed and are not reset. Loaded-record indexing supports building/range providers; all usage revalidates current power, permissions and media. Technical caps remain internal: 256 bindings/store; 32 offers; bounded adjacent-world scans; one outstanding UI poll per two seconds. These are safety limits rather than game balance options.

Applications retain ownership of join/reconnect handshakes, peer compatibility, authoritative gameplay transactions and persistence migrations. Services are isolated per adapter namespace; they do not provide global hardware locking between unrelated apps. Consumers that mutate media used by another app must coordinate those services explicitly. The framework supplies no client-owned shared state. A binding service must not be treated as dedicated MP proof until tested with the application's actual server transport.

## Supported computers

`require('B47ANCEDPCFramework/Device').isComputerSprite(sprite)` recognizes the four installed vanilla desktop orientations or exact sprite `CustomName=Computer` metadata. `Device.computer(actor,object,near)` additionally enforces loaded world-object identity, the server Enabled setting, current electricity, safehouse access and optional same-floor adjacent or validated front-seat reachability. This recognition automatically applies to Quartermaster's server adapter; no client-selected sprite identifier authorizes an operation. App privacy callbacks remain additional requirements. Computer-like translated labels, arbitrary sprite-name substrings and inventory items are not identity evidence.

Client Startup now registers bundled `b47pc.minesweeper` via public `registerApp`. It is a CD-free puzzle. Its server-owned board and bounded mood service are documented in MINESWEEPER_MOOD.md; public app API versions remain unchanged. Opening a PC still does not auto-launch an app; select its icon/Start entry. Select it alongside other apps on the unified desktop or Start menu. See [Minesweeper](MINESWEEPER.md).

Seated access in 0.8.0-dev.1 uses the authenticated actor's native furniture state and the same shared `Device.computer` validation. `Device.isSeated(actor)` reports native furniture sitting; `Device.seatedReachable(actor,object)` checks only the extra physical front-seat path. Neither helper grants PC or app permission. Keep complete Device and app checks on every authoritative operation. Stock S/E/N/W facings and exact custom `Facing` metadata are supported. No request-supplied seat flag or position is trusted. See [seated access, rest behavior and acceptance gates](SEATED_PC.md).

The 0.9.0-dev.1 desktop/lifecycle additions retain app/UI/assets/CD API 1 and authoritative media schemas. See [complete common-launcher, provider selection, teardown and compatibility contract](UNIFIED_DESKTOP.md). Client session facades are presentation objects and never server grants.
