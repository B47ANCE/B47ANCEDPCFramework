# Changelog

## [0.2.0-dev.1] - 2026-10-17

- Accept every verified vanilla PC orientation and other placed tiles declaring native `CustomName=Computer`, replacing the single-sprite restriction.
- Preserve loaded-object, power, reachability, sandbox and safehouse/app permission checks. Unrelated powered appliances and computer-like names are rejected.
- Compatible MINOR device-support expansion; registration API, saved bindings and network commands are unchanged. Native SP/dedicated NOT TESTED; G7/stable G8 BLOCKED.

## [0.1.0-dev.1] - 2026-10-17

- Initial standalone computer framework development: desktop, device validation, registered apps and reusable server drive bindings extracted from owned Quartermaster code.
- Native SP/dedicated NOT TESTED. G7 and stable G8 BLOCKED.
