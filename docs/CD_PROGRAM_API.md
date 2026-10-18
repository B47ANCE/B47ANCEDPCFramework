# Public CD program API 1

Project Version: 0.9.0-dev.2

CD programs are trusted Lua supplied by installed mods. A physical CD identifies compatible program data; it never supplies executable Lua, paths to load, or operating-system code. Application, UI and drawing-assets API 1 remain compatible. Query `PC.supports('cd-programs')` and `PC.getAPIInfo().cdProgramVersion == 1` before using this additive contract.

## Client registration

```lua
local PC = require 'B47ANCEDPCFramework/API'
PC.registerCDProgram({
    id='yourmod.catalog', version='1.0.0',
    titleKey='UI_YourMod_Catalog', file='CATALOG.EXE',
    mediaTypes={'YourMod.CatalogCD'},
    drive=function(ctx,command,args,reply)
        -- Your authenticated transport adds ctx.computer coordinates and
        -- maps list/mount/eject to your existing server DriveService.
        YourClient.drive(ctx,command,args,reply)
    end,
    requestRun=function(ctx,request,reply)
        YourClient.requestRun(ctx,request,reply)
    end,
    create=function(ctx)
        local panel=ctx.window()
        PC.UI.label(panel,{x=12,y=12,textKey='UI_YourMod_Ready'})
        return panel
    end
})
```

`id`, `version`, `titleKey`, `file`, `mediaTypes`, `drive`, `requestRun` and `create` are required. IDs/versions are nonempty strings containing letters, digits, underscore, dot or hyphen, at most 80 characters. The independently versioned program `version` is matched exactly; it is not the framework version. `file` is a display-only EXE filename of at most 80 characters, without directory separators. `mediaTypes` is a nonempty list of distinct full item types, each at most 128 characters. Registration copies supported fields/type lists, rejects duplicate application IDs and creates a selectable app entry. Supply the CD item and translations in your own mod; the example item name above is a placeholder, not a framework item.

Optional callbacks `enabled(ctx)`, `canUse(ctx,near)` and `onClose(ctx,reason)` have the [installed-app semantics](UI_API.md). `onDenied(probe,status)` observes a rejected/malformed authorization response; a success response with mismatched program/version/media reports `incompatible`. Pure availability probes have player/computer/UI/assets fields but no hosted window or media. Registration/probing never reads a CD or starts a request. CD programs appear in the shared desktop/Start launcher as media-app entries. Selecting one opens its browser; load a compatible CD from adjacent authorized storage, then choose **Run application** or double-click its EXE. Mounting a CD does not run it.

`drive(probe,command,args,reply)` implements the existing [list/mount/eject protocol](API.md). Reply with server-approved media descriptors, not client inventory assertions. `requestRun(probe,request,reply)` runs only after explicit launch and sends:

```lua
{program='yourmod.catalog', media=exactItemID, drive=serverBindingID}
```

The consumer transport authenticates the native sender and independently resolves the PC. The server helper below produces the expected reply:

```lua
{status='ok', program={id='yourmod.catalog',version='1.0.0'},
 media={id=exactItemID,drive=serverBindingID,fullType='YourMod.CatalogCD'}}
```

Only a matching successful reply creates the hosted UI. Missing/mismatched fields, duplicate replies, actor replacement, closure, power/access loss, an observed disc/binding change, a replaced browser or a reply after 15 seconds cannot launch it. One request is pending per app host; expiry permits retry. This timeout is an internal stale-request safety limit, not game balance. Closing the browser does not cancel transport work; stale replies are ignored. Consumers remain responsible for bounded transport queues and cancellation. The desktop polls existing media bindings at its established bounded cadence while running/minimized and closes the app on observed media loss.

`create(ctx)` must construct one `ctx.window(options)` and return that panel or nil. It receives the usual hosted UI helpers plus copies of `ctx.program={id,version}` and `ctx.media={id,drive,fullType}`. `ctx.guard` also checks the current mounted media identity. It does not prove that a remote disc or its contents remain unchanged between polls. Use guards for presentation replies and server checks for gameplay. Private snapshot data is not delivered by launch authorization; obtain only authorized, sanitized views through your app's own read service.

## Server registry and validation

```lua
local CD = require 'B47ANCEDPCFramework/CDPrograms'
local programs = CD.new({drive=YourServerDriveService, programs={{
    id='yourmod.catalog', version='1.0.0',
    mediaTypes={'YourMod.CatalogCD'},
    accepts=function(ctx)
        -- ctx.snapshot came from your DriveService's genuine-item validator.
        return ctx.snapshot.program=='yourmod.catalog'
            and ctx.snapshot.programVersion=='1.0.0'
    end
}}})
-- In your authenticated server command handler:
-- local result = programs.authorize(nativeSender,resolvedComputer,args)
-- Send result only to that sender, using your existing request correlation.
```

`CD.new({drive,programs})` copies each program definition. IDs are unique within that service. Each requires identity/version/media types and a pure `accepts(serverContext)` callback returning exactly true only for genuine supported program data and any extra app privacy rules. Optional `enabled(serverContext)` must return exactly true when supplied; meaningful gameplay toggles belong in authoritative server sandbox settings. Do not inspect client-submitted snapshots or allow a display name alone to establish program identity.

| Method | Behavior |
| --- | --- |
| `service.list(actor,computer,bindingID)` | Revalidates the actual mounted CD; returns `{status='ok',programs={{id,version},...}}` sorted by ID, filtered by type, enable and acceptance callbacks. No payload or native object is serialized. |
| `service.authorize(actor,computer,request)` | Revalidates exact requested item ID, binding, PC, power/access, media type and program acceptance, then returns the sanitized launch reply above. |
| `service.resolve(actor,computer,request)` | Same checks, returning a **server-only** context `{player,computer,item,snapshot,drive,program={id,version}}`, or `nil,status`. Call immediately before each gameplay read/action and apply additional action-specific authorization. Never serialize this context. |

All methods refuse client-side execution. `actor` must come from authenticated transport, never payload player IDs. PC validation is repeated by the framework; DriveService re-resolves the physical item, adjacent storage, exact binding and adapter privacy/snapshot. The program callback applies additional data/access constraints. Failure statuses are `invalid` (malformed/client/dead sender), `unavailable` (PC/program denied or incompatible), and `changed` (binding/media no longer valid). Do not expose more detailed private records to unauthorized users. Errors in trusted callbacks propagate; they are not silently converted to successful reads.

`CD.describe(definition)` returns validated identity/version/type-list copies. `CD.acceptsType(description,fullType)` checks the declared type list; it is a presentation compatibility test, not server authorization. `CD.version` is 1. The server registry may accept several programs on the same app-owned data disc; current desktop selection is still one registered program per selected app. A generic multi-file CD browser/installer is future work.

## Ownership and limits

| State/boundary | Owner and checks |
| --- | --- |
| Registered code, EXE display name, local UI and pending reply ticket | Trusted client mod; never executed from CD bytes. One-shot ticket, exact reply match and hosted lifecycle checks. |
| Physical media, storage, binding, snapshot and access | Existing authenticated server DriveService/consumer adapter; no moves or inventory conversion introduced. |
| Program compatibility | Server registry plus pure accepted-media predicate; client type matching cannot authorize anything. |
| Read/write/gameplay operations | Owning mod's authenticated server service. Resolve again, enforce action permissions, exact items, quotas/timing and duplicate-request handling. Authorization replies are UI descriptions, never reusable gameplay grants. |
| Persistence/reconnect/restart | Existing DriveService binding schema 1 and app-owned snapshot schema; no new persisted framework record. Register definitions on server startup and clients, then rediscover/re-authorize after reconnect. Outstanding UI requests are local and are not restored. |

This API does not burn, clone, install, trade or consume CDs. Writing needs an app-owned server action with real item validation, bounded costs/time, cancellation/refunds, synchronization, persistence and sandbox settings. Existing Quartermaster writer hooks remain supported. This avoids inventing universal writable metadata, trusting client modData, or duplicating inventory authority. Services retain their existing namespace isolation; cross-app hardware locking still requires explicit coordination.

[Opt-in client example](../examples/CDProgram.lua) and [server example](../examples/CDProgramServer.lua) accept the owning mod's DriveService, item types and transports. They are excluded from production. The independent offline suite executes both examples against the actual binding service and disposable fixture items; no game is launched.

[TESTED OFFLINE] Registration, native-shaped UI, real service list/mount/authorize, forged/mismatched replies, exact item/type/version checks, power/access loss, timeout/duplicate handling, media-loss closure, persisted-binding reload and no item movement. [RUNTIME GATE] Native SP and dedicated multiplayer NOT TESTED; G7 and stable G8 BLOCKED. Validate two-client contention, request correlation/delay, real item notifications, reconnect/rejoin, storage unload/reload, restart and controller/input with each actual consumer transport before claiming runtime correctness.

In 0.9.0-dev.1 media-app sessions coexist with installed apps on one CRT desktop. A common CD-ROM browser exposes an explicit provider selector when necessary; provider offers/bindings and pending run authorizations remain isolated. Switching apps preserves a live context; closing/replacing its browser still rejects a late launch. No cross-provider authority or global hardware locking is added. See UNIFIED_DESKTOP.md.
