# Changelog

## [0.9.0-dev.4] - 2026-10-18

- PATCH-level branding checkpoint within the pending 0.9.0 iteration: replace the fallback Workshop thumbnail and in-game poster with the user-supplied PC artwork, plus a text-free computer icon crop. Preserve the supplied original and export provenance.
- Gameplay, public APIs, sandbox settings and save formats are unchanged. Artwork checks and package integrity are offline evidence; native SP/dedicated remain NOT TESTED, G7/stable G8 BLOCKED.

## [0.9.0-dev.3] - 2026-10-17

- PATCH-level publication metadata/tooling checkpoint within the pending 0.9.0 MINOR iteration. Prepare the explicitly authorized first public Workshop MP testing item, canonical player-facing prose, exact fallback thumbnail and guarded package-to-staging manifest.
- SteamCMD creation/upload succeeded for public item 3822042011; record canonical identity and exact source/package provenance.
- Runtime gameplay, public APIs, sandbox settings and save schemas are unchanged. Native SP/dedicated NOT TESTED; G7/stable G8 BLOCKED. Upload success must be recorded separately.

## [0.9.0-dev.2] - 2026-10-17

- PATCH-level visual refinement within the pending 0.9.0 MINOR iteration: original mine-and-flag pixel icon for Minesweeper on the shared desktop and taskbar.
- Expose the additive `minesweeper` drawing asset through Assets API 1, using existing palette roles and Lua geometry. No gameplay, networking, sandbox or schema changes.
- Check icon bounds at taskbar/desktop sizes and the installed app/catalog binding offline. Native SP/dedicated NOT TESTED; G7/stable G8 BLOCKED. No package/deploy/upload.

## [0.9.0-dev.1] - 2026-10-17

- Compatible MINOR expansion toward 0.9.0: one CRT desktop and Start menu for all available registered apps, retaining app-specific windows and media authority. Public API/schema versions remain unchanged.
- Restore the user-approved beige CRT, pixel icons, inset screen, taskbar and physical power control with original Lua geometry.
- Native SP/dedicated NOT TESTED; G7/stable G8 BLOCKED.

## [0.8.0-dev.1] - 2026-10-17

- Compatible MINOR expansion toward 0.8.0: allow PC use from occupied native furniture directly in front of the PC, including while resting. Existing direct adjacency and public API/schema versions remain unchanged.
- Validate native seating state/data, loaded furniture identity, PC facing, bounded body offset and both short barrier checks through shared Device; retain power, safehouse and app privacy authorization. No client seat claim, custom state packet or migration.
- Open without clearing queued rest or initiating walking from a seat; desktop and server operations revalidate loss of access. Add four-orientation and adversarial seat/server/UI regressions plus exact-build API evidence.
- Framework and paired Quartermaster/Rooms offline checks pass. Native SP/dedicated NOT TESTED; G7/stable G8 BLOCKED. No package/deploy/upload.

## [0.7.0-dev.1] - 2026-10-17

- Compatible MINOR gameplay addition toward 0.7.0: server-authoritative Minesweeper play and configurable boredom/unhappiness relief. Public app APIs remain unchanged.
- Move pure board rules to shared Lua; retain the require name and validate all game moves on server/SP authority. Redact hidden cells and correlate/cancel client replies.
- Default active-play benefits: remove 2 boredom and 1 unhappiness per 30 qualifying real seconds, with native clamping and owner stat synchronization. Add five localized server sandbox settings for enable/rates/interval/activity grace.
- Exclude idle windows, flag spam, resets and replayed requests; recheck PC power/access/reach, sequence, actor and session validity. No client stat setter or persisted reward record.
- Add authority/transport regressions, exact-build API evidence and gameplay documentation. Historical 0.6 package retained unchanged; no automatic repackaging/deployment.
- Native SP/dedicated NOT TESTED; gameplay G7/stable G8 BLOCKED.

## [0.6.0-dev.1] - 2026-10-17

- Compatible MINOR addition toward 0.6.0: bundle an installed, local Minesweeper PC app. Existing public APIs and binding/persistence schemas remain unchanged.
- Add original 9x9/10-mine board rules: safe first reveal, zero flood, capped flags, number chording, win/loss and reset.
- Use the public hosted UI API for flags/reveal mode, timer/status, font-aware tiles, controller focus and small-window fallback. Startup registers the app without launching it or requiring a CD.
- Add model/UI regressions, localized English fallback keys and exact-build input source evidence. Boards are disposable local state with no scores/rewards/save or world effects.
- Development package requested; native SP/dedicated NOT TESTED. G7/stable G8 BLOCKED.

## [0.5.0-dev.1] - 2026-10-17

- Compatible MINOR iteration toward 0.5.0: public CD-program registration and server authorization helpers. Legacy application/media API 1 and binding schema 1 remain supported.
- Add `registerCDProgram`, `cdProgramVersion`/`cd-programs` discovery, shared hosted lifecycle and one-shot launch guards with exact version/item/binding checks.
- Add server `CDPrograms` list/authorize/resolve over real DriveService bindings; private snapshots stay server-side. No burning, item moves, persisted format or transport changes.
- Add executable opt-in client/server examples, server/client/end-to-end offline regressions, English fallback status strings and full API/authority documentation.
- Native SP/dedicated NOT TESTED. G7/stable G8 BLOCKED.

## [0.4.0-dev.1] - 2026-10-17

- Compatible MINOR iteration from 0.3.0-dev.1 toward 0.4.0; public API versions and persistence schemas remain unchanged. Stable release remains gated.
- Begin the UI roadmap with public `tabView`, wrapping `toolbar` and font-sized `statusBar` components; additive UI API 1 capabilities retain legacy consumers.
- Extend the opt-in gallery with editor/about tabs, toolbar actions and status output; only local preview state is edited.
- Offline tests cover selection, page visibility/focus, disabled actions, descriptor isolation, invalid IDs and 14/24/32/42-font layouts at narrow/wide widths. Native SP/dedicated NOT TESTED; G7/stable G8 BLOCKED.

## [0.3.0-dev.1] - 2026-10-17

- Add public UI API 1 and drawing-assets API 1 for modular PC panels, hosted windows, controls, palette and scalable icons.
- Add descriptor-based installed apps and guarded UI callbacks without changing legacy application API 1, Quartermaster hooks, media commands or saved binding schemas.
- Supply an opt-in component gallery, consumer guide and feature roadmap that separates implemented UI from proposed gameplay integrations.
- Compatible MINOR SDK expansion. Source/offline evidence only; native SP/dedicated NOT TESTED, G7/stable G8 BLOCKED. No package/deployment/Workshop upload.

## [0.2.0-dev.1] - 2026-10-17

- Accept every verified vanilla PC orientation and other placed tiles declaring native `CustomName=Computer`, replacing the single-sprite restriction.
- Preserve loaded-object, power, reachability, sandbox and safehouse/app permission checks. Unrelated powered appliances and computer-like names are rejected.
- Compatible MINOR device-support expansion; registration API, saved bindings and network commands are unchanged. Native SP/dedicated NOT TESTED; G7/stable G8 BLOCKED.

## [0.1.0-dev.1] - 2026-10-17

- Initial standalone computer framework development: desktop, device validation, registered apps and reusable server drive bindings extracted from owned Quartermaster code.
- Native SP/dedicated NOT TESTED. G7 and stable G8 BLOCKED.
