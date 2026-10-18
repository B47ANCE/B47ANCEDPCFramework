# Public PC UI and drawing assets

Project Version: 0.9.0-dev.3

Application API **1**, UI API **1**, drawing-assets API **1**. This is a client presentation SDK for trusted Lua mods. Consumers enable `B47ANCEDPCFramework` as a loader dependency and import it; they do not vendor the framework source or copy its global UI objects. No separate Java, texture generator or external OS runtime is required.

```lua
local PC = require 'B47ANCEDPCFramework/API'
local UI = require 'B47ANCEDPCFramework/UI'       -- also PC.UI
local Assets = require 'B47ANCEDPCFramework/Assets' -- also PC.Assets
local versions = PC.getAPIInfo()
assert(versions.uiVersion == 1 and PC.supports('hosted-windows'))

PC.registerApp({
    id = 'yourmod.status',
    titleKey = 'UI_YourMod_StatusTitle',
    icon = 'document',
    create = function(ctx)
        local panel = ctx.window({onResize=function(view,width,height)
            UI.place(view.message,12,12,width-24,UI.metrics().font+4)
            UI.place(view.refresh,12,height-UI.metrics().button-12,width-24,UI.metrics().button)
        end})
        panel.message = UI.label(panel,{textKey='UI_YourMod_Ready'})
        panel.refresh = UI.button(panel,{
            textKey='UI_YourMod_Refresh',
            onClick=ctx.guard(function()
                panel.message:setTextKey('UI_YourMod_Ready')
            end)
        })
        UI.focus(panel,{{panel.refresh}})
        return panel
    end
})
```

Supply your own localized keys and translate files. Registration creates an app entry, not a running app. The user explicitly selects its desktop/Start-menu icon. `PC.open(playerNum,computer)` opens the unified desktop. Passing an ID creates/focuses that app's host session without launching it. Installed apps need no CD; unrelated apps and valid media providers remain visible in the shared launcher. Existing factory/media apps continue to use `registerApplication`, authenticated drive offers and explicit EXE launch unchanged.

## App descriptor and context

`registerApp({id,titleKey,icon,create,enabled,canUse,onClose})` is additive to application API 1. `id`, `titleKey` and `create` are required. IDs use letters/digits/underscore/dot/hyphen, at most 80 characters; use your mod's namespace. Icons default to `application`. Register each ID once. The supported descriptor fields are copied at registration, so later descriptor edits do not silently change the app.

`enabled(context)` and `canUse(context,near)` are optional availability/privacy filters. They must be pure and may run while building context menus; availability probes have no host/window helpers. The framework still requires a loaded, powered, accessible PC and safehouse permission. A filter cannot override those checks. `create(context)` runs only on explicit launch and receives the hosted lifecycle helpers. It must construct exactly one `ctx.window(options)` and return that panel or nil. Use native nested panels inside it. Different apps and legacy tools retain independent taskbar windows in one CRT root; multiple SDK windows within one app and arbitrary drag/snap are not implemented.

The context contains `playerNum`, the current native `player`, `computer`, `host`, `ui`, and `assets`. `ctx.window(options)` connects window cleanup to `onClose(context,reason)`. `ctx.isActive()` checks current window, actor, PC, power, framework/app enable state and access. `ctx.guard(callback)` returns a function that ignores stale calls after closure, actor replacement or access/power loss. Synchronous callbacks after `ctx.window()` are accepted. Guards do not authenticate server requests or cancel an app's background work; implement cancellation in `onClose` and validate gameplay on the server. Closing a panel invalidates its context even if the desktop stays open. Minimize, switching apps and restore preserve a live context. `ctx.isActive()` checks session lifetime and authorization, not foreground focus. Each session retains independent mounted media and pending work. A host is a facade over `host.root`, the native widget.

Builder errors close any constructed SDK panel before propagating the error. Cleanup callbacks run once; framework cleanup completes before a cleanup error propagates. Errors are not turned into success results or hidden. Public UI metadata and callbacks are trusted local mod code, never code loaded from a physical disc or arbitrary file.

`getAPIInfo()` returns a fresh table with `frameworkVersion`, `applicationVersion`, `uiVersion`, `assetsVersion`, `cdProgramVersion`, and a fresh `features` map. `supports(name)` supports `installed-apps`, `ui-controls`, `hosted-windows`, `drawing-assets`, `custom-icons`, `media-adapters`, `tabs`, `toolbars`, `status-bars`, `cd-programs`, `unified-desktop`, `retained-app-windows`, and `crt-frame`. Feature/version compatibility does not imply native or multiplayer validation.

## UI controls

All factories initialize, instantiate, style and attach the native widget to the supplied parent. Common options are `x`, `y`, `width`, `height`, and `tooltipKey`. Label/button captions use `textKey`, or `text` for already-localized dynamic content. Bounds are local UI pixels. Every widget is a native ISUI widget, so app-specific native behavior remains available without wrapping gameplay state.

| Function | Options and behavior |
| --- | --- |
| `UI.panel(parent,options)` | Native joypad panel with a PC background; `color` is a palette token, default `grey`. |
| `UI.window(host,options)` | Embedded single app window; `titleKey`/`title`, `onResize(panel,width,height)`, `onUpdate(panel)`, `onClose(reason)`. Descriptor apps use `ctx.window` so their lifecycle is bound correctly. |
| `UI.label(parent,options)` | Clipped single-line caption, optional `textColor` palette token. `setText(value)` sets dynamic text; `setTextKey(key)` restores localization. |
| `UI.button(parent,options)` | Beveled control, native input/controller handling, `onClick(button)`. |
| `UI.iconButton(parent,options)` | Desktop-style scalable icon plus clipped caption; `icon` is a registered asset ID, default `application`; `textColor` defaults to `white`. |
| `UI.textEntry(parent,options)` | Editable native text entry with initial `value`; native glyphs are dark on the light input surface. |
| `UI.combo(parent,options)` | `options={{textKey=...,value=...},...}` and `onChange(value,combo)`; values are local UI data. |
| `UI.list(parent,options)` | Native scrolling list with readable selected/unselected rows; optional `rowHeight`. Use native `addItem(displayText,payload)`, selection and callbacks. |
| `UI.tabView(parent,options)` | `tabs={{id,textKey/text,tooltipKey},...}`, optional `selected` and `onChange(id,page,previousID)`. `page(id)` returns a native nested panel; `selectedID()` reads selection; `select(id)` returns false for unknown IDs and true otherwise. Initial selection and repeated selection do not notify. |
| `UI.toolbar(parent,options)` | `actions={{id,textKey/text,tooltipKey,enabled,onClick},...}`. `onClick(button,id)` runs for enabled actions. `button(id)` exposes the native control for later enable changes. Captions wrap into button rows. |
| `UI.statusBar(parent,options)` | Recessed caption with `textKey`/`text`, optional `textColor`; `setText(value)` and `setTextKey(key)` update its local message. |
| `UI.style(widget,kind)` | Apply PC colors to an existing native widget; `input` also sets native entry glyph colors; `list` sets selection colors. Does not instantiate or attach it. |
| `UI.place(widget,x,y,width,height)` | Explicit bounds using the existing native anchoring discipline. |
| `UI.focus(panel,rows)` | Rebuild controller focus rows; hidden/disabled controls are omitted. Rebuild after app visibility/enable changes. |
| `UI.metrics()` | A fresh copy of current native font-derived dimensions. Mutating it does not change other apps. |

Composite IDs must be unique nonempty strings within that control. Invalid tab lists, duplicate IDs or an unknown initial tab fail before attachment. Descriptor fields are copied at construction; callbacks and payloads remain trusted local Lua. Tabs preserve their page widgets and values when switching, and show only the selected page. Selection does not grant app access or authorize a gameplay operation.

`UI.place` immediately lays out SDK composites. They also reflow on changed native dimensions/font height during prerender; unchanged painting preserves controller selection. Toolbars own their height (`contentHeight`), and status bars use `UI.metrics().font+12`; reserve that space when positioning siblings. Tab headers wrap and expose `headerHeight`; give the tab view at least `headerHeight+5` pixels plus the application's required body height. Keep page contents within `page(id)` bounds in the hosted window's resize callback; the component does not scroll or lay out arbitrary consumer children.

Toolbar `focusRows()` exposes its action rows. Tabs provide `setPageFocus(id,rows)` and `focusRows()` combining current header rows and the selected page's rows. Feed those rows into `UI.focus` on the hosted window after resize, page selection, or enable/visibility changes. For nested toolbar actions include the toolbar's rows in that page's focus rows. `UI.focus` filters hidden/disabled controls; it does not infer hidden ancestors from arbitrary consumer widgets. Rebuild after a toolbar action is enabled/disabled. The gallery demonstrates root focus rebuilding on tab selection. Low-height layouts, native focus routing and clipping still need in-game acceptance.

Window resize callbacks run on changed content dimensions or body-font height. `onUpdate` runs once per host prerender, including while minimized; it is for bounded local presentation work. Do not use it for world scans, gameplay mutations or per-frame network requests. Escape/controller B close the SDK panel and restore host focus. The host handles taskbar, minimize/restore, actor/permission/power loss and desktop shutdown. Native screen/input acceptance remains a runtime gate.

The SDK deliberately does not introduce game-balance settings. Coordinates, icon dimensions, font metrics and callback lifecycle are implementation constraints. Existing server `Enabled` remains authoritative for PC availability; gameplay apps must declare their meaningful shared options as server sandbox settings. Native widget data, text and app preferences cannot own shared gameplay.

## Drawing assets

`Assets.palette()` returns fresh color tables; `Assets.color(name)` returns one copy. Tokens: `case`, `grey`, `light`, `shadow`, `black`, `white`, `blue`, `teal`, `muted`. Changing a returned table does not reskin other apps or the desktop. Global theme replacement is not part of API 1.

`Assets.icons()` returns a sorted fresh list. Built-in IDs: **computer, disc, writer, application, folder, document, settings, minesweeper**. `hasIcon(id)` checks availability. `drawIcon(widget,id,x,y,size)` draws original Lua geometry at the requested square size (default 40). Unknown IDs, invalid sizes or out-of-bounds geometry fail explicitly. There are no copied OS icon sheets or generated bitmap dependencies.

```lua
Assets.registerIcon('yourmod.alert',function(rect)
    rect(2,2,36,36,'blue')
    rect(17,8,6,17,'light')
    rect(17,29,6,5,'light')
end)
```

Custom icon callbacks draw rectangles in a normalized 40×40 space using palette tokens. The renderer validates finite positive geometry inside that space and scales it for the caller. Use namespaced IDs; existing IDs cannot be replaced by a different callback. This is a trusted Lua drawing extension, not a mechanism to load executable files or media-provided code.

Low-level components: `Assets.panel(widget,x,y,width,height,colorToken)`, `bevel(widget,x,y,width,height,pressed)`, and `text(widget,caption,x,y,width,colorToken)`. Text is single-line, clipped, plain native text. Legacy `ComputerUI` helpers are retained for existing consumers; new apps should import these public modules rather than depending on desktop implementation details.

## Example and acceptance

[Component Gallery](../examples/ComponentGallery.lua) and its [English strings](../examples/Translate/EN/UI.json) are opt-in consumer source, excluded from the production package. Put the script and translations in your own mod's native client/Translate paths and declare the framework dependency. The gallery changes only disposable local rows; it is not a persistent notes or inventory system.

[TESTED OFFLINE] Independent consumer tests cover public imports, palette/metric isolation, built-in/custom icons at several sizes, native constructors/callback shape, controls, focus, resize/font layout, explicit launch, synchronous/stale replies, permission/power loss, and builder/cleanup errors. The legacy Quartermaster regression suite is exercised against the new SDK. [RUNTIME GATE] Native pixels, keyboard/controller focus, split-screen behavior and dedicated multiplayer remain NOT TESTED; G7/stable G8 remain BLOCKED. No consumer publication or deployment is implied by this API.

CD-backed descriptors reuse the same context/window implementation as installed apps. [CD program API 1](CD_PROGRAM_API.md) adds `ctx.program`/`ctx.media` identity copies only after server authorization, and guards also check mounted-media identity. Use `registerCDProgram` for this flow; `registerApp` stays the installed/non-media entry point.

The shipped [Minesweeper app](MINESWEEPER.md) is a production consumer of `registerApp`, hosted contexts and public UI/assets. It registers at client startup and is included in the framework ZIP, unlike the opt-in Component Gallery/CD examples. Its disposable board and mood effects are now server-owned; the UI submits intent through the bundled app transport. See [mood authority](MINESWEEPER_MOOD.md).

The approved CRT shell and refreshed original pixel icons in 0.9.0-dev.1 use Lua rectangles/text only; the seven icon IDs and nine public palette roles are unchanged. See UNIFIED_DESKTOP.md for app-only retirement, cleanup error handling, bounded provider/catalog polling and native acceptance gates.

In 0.9.0-dev.2 the additive `minesweeper` asset depicts an original miniature minefield with an exposed mine, count and blue flag. The bundled app uses it on the shared desktop and taskbar. Its editable source is `Assets.lua`; it uses existing palette roles and rectangle rendering without bitmap dependencies. Assets API remains 1. Offline geometry checks cover 16, 20, 40, 56 and 80 pixels; native pixels remain a runtime gate.
