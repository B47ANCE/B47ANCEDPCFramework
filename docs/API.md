# Application API 1

Project Version: 0.2.0-dev.1

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
-- Explicitly select an app. Omit id to use the first available app or empty desktop.
PC.open(playerNum,computer,'example')
```

Factories return nil when the app is disabled and must have no gameplay side effects: availability checks may invoke them before opening a screen. IDs are stable, unique, at most 80 characters; duplicate registration is rejected. `applications()` returns sorted IDs; `availableApplications(playerNum,computer)` filters enabled/authorized apps; `applicationTitle(id)` returns its presentation title. `apiVersion` is 1 and is independent of the project version. Multiple available apps are selectable through the native context menu.

Optional hooks: `enabled()` (default framework switch), `canUse(actor,computer,near)` (additional app privacy), `busy()`, `close()` (cancel this user's app work), `text(key,...)` (domain status translations), `writer(host,hooks)` and `toolTitle` (one hosted app tool). `inventory`, `burn` and other domain callbacks may be consumed by that tool, never by the desktop. Core powered-device/safehouse validation always applies in addition to app callbacks. Screen singleton identity includes app ID; switching apps closes the old app. Native keyboard Escape and controller B return/minimize/close through the existing desktop flow.

Drive replies: `{status='ok',choices={{id=<native item ID>,name=<sanitized label>,fullType=<type>,token=<sender-bound offer>}},mounted=<same descriptor plus drive ID>,slot=<binding ID>,occupied=<boolean>}`. `mount` submits only an offer token; `eject` submits the current binding ID. UI proxies never move items or authorize reads. Missing providers show an empty drive. `canRun` must explicitly accept the media type; only Run/EXE double-click calls `read`. On media change, eject, power loss, app disable, actor replacement/death or screen close, the screen discards the app UI. App server services must independently revalidate every operation, including replies arriving after UI close.

## Server drive engine

`require('B47ANCEDPCFramework/DriveService').new(adapter)` creates an isolated binding service. It exposes `handle(actor,command,args)`, `read`, `provider`, `occupied`, `busy`, `protected` and `candidates`. It refuses clients and invalid/dead actors. Call `handle` only after your transport authenticates the sender; never accept an actor ID from client payloads.

Adapter fields: `store`, `computerKey`, `storageKey`; `media={object,computer,disc}`; `enabled()`, `valid(target,actor)`, `can(actor,target,action)`, `target(object,compartment,actor)`, `snapshot(item)`, `grants()`, `building(computer)`; `commands={list,mount,eject}` and `status={disabled,power,denied,changed,occupied}`. All are trusted server code. Supply app-safe physical-target validation, private-room permissions and genuine media-to-snapshot binding. `snapshot` must return nil for forged metadata. The `computer` callback must include Device validation and any app-specific permissions. The engine owns no application snapshots, inventory conversions or generic client command handler.

The server re-resolves world objects, storage markers, exact native media and app snapshots; mount/eject require configure access. Discovery offers are sender/computer-bound and expire after 30 seconds. Real media remain in adjacent storage. Binding schema 1 persists under the supplied store and object keys; supply stable unique namespaces. Unknown/future/corrupt data fail closed and are not reset. Loaded-record indexing supports building/range providers; all usage revalidates current power, permissions and media. Technical caps remain internal: 256 bindings/store; 32 offers; bounded adjacent-world scans; one outstanding UI poll per two seconds. These are safety limits rather than game balance options.

Applications retain ownership of join/reconnect handshakes, peer compatibility, authoritative gameplay transactions and persistence migrations. Services are isolated per adapter namespace; they do not provide global hardware locking between unrelated apps. Consumers that mutate media used by another app must coordinate those services explicitly. The framework supplies no client-owned shared state. A binding service must not be treated as dedicated MP proof until tested with the application's actual server transport.

## Supported computers

`require('B47ANCEDPCFramework/Device').isComputerSprite(sprite)` recognizes the four installed vanilla desktop orientations or exact sprite `CustomName=Computer` metadata. `Device.computer(actor,object,near)` additionally enforces loaded world-object identity, the server Enabled setting, current electricity, safehouse access and optional same-floor adjacent reachability. This recognition automatically applies to Quartermaster's server adapter; no client-selected sprite identifier authorizes an operation. App privacy callbacks remain additional requirements. Computer-like translated labels, arbitrary sprite-name substrings and inventory items are not identity evidence.
