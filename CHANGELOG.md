# Changelog

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
