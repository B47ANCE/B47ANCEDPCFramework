# First Workshop MP testing publication

## Transparent icon correction — 2026-10-18

SteamCMD updated existing item **3822042011** to **0.9.0-dev.5**, reported `Committing update...Success` and exited 0 using cached authentication. Public Steam API metadata independently confirms the item/title, App ID 108600, configured visibility 0, current version and MP testing label. The unauthenticated page reader could not access the item; unrestricted page availability is not newly verified.

- Uploaded source: `3be9dcb62e2b345e2ddb73351653ace9a6e402de`, public branch `feature/transparent-pc-icon`, included in stacked PR #9.
- ZIP SHA-256: `ffbcf39c74818b551ef70a257b84bc5b92f96200bc333b560c7654a8057a60d9`; 90 exact source/ZIP/staged runtime files.
- Transparent 64×64 RGBA icon SHA-256: `6b3a31de0c882a852d316eacd72fa9a4450d53d9b836e4359f419cf49c5c55e7`; alpha extrema 0/255, four zero-alpha corners and 1,272 fully transparent pixels. Light/teal background inspection is offline evidence.
- Approved thumbnail/poster SHA-256 remains `3cc31d939acc58a0de5dfccb0f8b58ffab7b5815aa4bdf6a0476a0e557d08d4e`; both 512×512.
- `python -B scripts/check_versions.py`, `python -B tests/run_tests.py`, `python -B scripts/build.py`, `python -B scripts/check_versions.py --release` and `python -B scripts/prepare_workshop.py` PASS OFFLINE. Clean source ancestry, exact-head push CI, VDF target/label/newlines, archive/member integrity, stage parity and art hashes passed before upload.
- Ignored receipt: `dist/workshop-0.9.0-dev.5-3be9dcb62e2b/transparent-icon-upload-result.json`, with adjacent release manifest and retained private upload log. Earlier packages/evidence remain preserved.

The new front-facing monitor/system-unit UI in **0.10.0-dev.1 / PR #9** is not included in this upload. This correction changes only the icon and version/publication metadata. Native SP/dedicated NOT TESTED; project G7/stable G8 BLOCKED. No local deployment or game/server launch. Steam desktop remains unchanged pending a separate affirmative restart reply.

## Approved artwork update — 2026-10-18

SteamCMD updated the existing item **3822042011** to **0.9.0-dev.4**, reported `Committing update...Success` and exited 0 using cached authentication. The item identity, title and configured public visibility were preserved. The owner-visible Workshop page shows the new supplied cover and current version; it also displays Steam's temporary automated-content-review notice. Upload success is confirmed; unrestricted public availability remains pending Steam's review at this observation.

- Uploaded source: `95404286775c58ecf58f3d2ee6a00a0fb7f1732e`, public branch `feature/custom-pc-branding`, PR #8 (stacked on #7).
- Package SHA-256: `ce52e6349c9c49a9eace2de0999e80316fbf4debf37b8b70a79f3ab94ad0c0f4`; 90 exact source/ZIP/staged runtime files.
- Workshop preview/poster SHA-256: `3cc31d939acc58a0de5dfccb0f8b58ffab7b5815aa4bdf6a0476a0e557d08d4e`; 512×512; Workshop preview 335,979 bytes. The 64×64 icon hash is in `assets/branding/exports.json`.
- Canonical cover and computer-icon sources, editor prompt and exact export provenance: `assets/branding/README.md`. Player-facing prose: `docs/WORKSHOP_DESCRIPTION.md`, `docs/WORKSHOP_CHANGELOG.md`; generated BBCode: `workshop/description.bbcode`.
- `python -B scripts/check_versions.py`, `python -B tests/run_tests.py`, `python -B scripts/build.py`, `python -B scripts/check_versions.py --release`, and `python -B scripts/prepare_workshop.py` PASS OFFLINE. Exact-head push/PR Ubuntu CI PASS. PNG structure/dimensions/hash and actual-size visual inspection PASS. Source originals are excluded from runtime packaging.
- Ignored receipt: `dist/workshop-0.9.0-dev.4-95404286775c/artwork-upload-result.json`; source/package/preview/VDF provenance is in the adjacent release manifest. Earlier packages and publication receipts remain unchanged in their original worktrees.

Only artwork and version/publication metadata changed. Gameplay, sandbox values, public APIs and save formats are unchanged. Native rendering/SP/dedicated NOT TESTED; project G7/stable G8 BLOCKED. No live deployment or game/server launch. Steam desktop was not restarted; the user must explicitly confirm a restart after this upload. This follow-up records evidence without changing uploaded runtime bytes.

## Initial publication — 2026-10-17

2026-10-17: SteamCMD created public item 3822042011 and reported Committing update...Success with exit 0 using existing cached authentication.

- Project version: 0.9.0-dev.3; Mod ID: B47ANCEDPCFramework; App ID: 108600.
- Canonical identity: WORKSHOP_ID.txt. Never create another item for this project.
- Uploaded source commit: 5a6ef83fd8ee23885bff82e28d9bd7e868538e55 (feature/workshop-publication; public PR #7).
- ZIP SHA-256: 629ae47b261384c10c762ee240e6dd5dae0faef790fc67aa546a55a501972698; 90 exact source/package/staged runtime files.
- Canonical description: docs/WORKSHOP_DESCRIPTION.md; changenote: docs/WORKSHOP_CHANGELOG.md; generated description: workshop/description.bbcode; original fallback preview: preview-client.png.
- Version, Lua-only/case/localization, full framework offline regressions, deterministic ZIP/member integrity, staged parity and exact-head Ubuntu CI PASS. Source used for upload was clean, pushed and verified.
- Ignored local receipt: dist/workshop-0.9.0-dev.3-5a6ef83fd8ee/creation-result.json and release-manifest.json. Initial creation VDF now contains the assigned ID; never resubmit a zero-ID descriptor.
- This follow-up records identity/documentation only; the uploaded runtime bytes and version are unchanged.

Public Steam API metadata independently confirms item 3822042011, title B47ANCED PC Framework, App ID 108600, visibility 0/public, version 0.9.0-dev.3 and the MP testing label. Quartermaster item 3807217050 now lists this item as a required dependency alongside Rooms; its loader requirement and player-facing links agree.

MP testing build - dedicated multiplayer NOT TESTED. Native SP/dedicated NOT TESTED; G7/stable G8 BLOCKED. Publication is distribution evidence only. No live deployment or game/server launch. Steam desktop was not restarted; a separate explicit confirmation is required after publication. Subscription/download and native runtime acceptance remain separate verification gates.
