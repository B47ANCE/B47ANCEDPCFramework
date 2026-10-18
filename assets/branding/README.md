# Approved PC Framework artwork

On 2026-10-18 B47ANCE supplied the full PC Framework cover and explicitly requested its use for the Workshop thumbnail and in-game poster, a computer-only icon crop, and an update to the existing Workshop item 3822042011. This supersedes fallback art for these three roles independently.

- `pc-framework-original.png`: the supplied 1254×1254 PNG, retained byte-for-byte (SHA-256 `4cf4e0ed4947d5f69812de681b5a1fb1a942b2dbef36e14997bfbe91752ae641`).
- `pc-framework-computer-crop.png`: text-free computer derivative produced with the built-in image editor from that supplied cover, retaining the beige CRT/system unit, teal desktop, dark background and pixel-art style. Keyboard/mouse and heading are excluded for small-size legibility. It is an image-edited derivative, not claimed to be a pixel-identical rectangular cutout.
- `exports.json`: exact source/output hashes, dimensions, Pillow version and export filter.

Reproduce mechanical exports with `python -B scripts/build_branding.py` using the recorded Pillow version. This is a host authoring dependency only. The full cover composition becomes the 512×512 `preview-client.png` and `42/poster.png`; the computer derivative becomes the 64×64 `42/icon.png`. The PNG exports contain no creative changes beyond source selection and size conversion. Original sources remain outside runtime packaging. No sandbox options or gameplay behavior are involved.

Image edit prompt: “Produce only a square, text-free computer icon crop from the supplied lower illustration. Preserve the beige pixel-art CRT monitor, teal desktop, horizontal computer case, proportions, age texture, lighting, dark background and three-quarter view. Make the monitor and case dominate with a small margin; omit the keyboard, mouse and heading. Do not redesign or introduce objects, logos or text. Frame for eventual 64×64 export.” Built-in mode was used; no CLI/API-key workflow.

Validation: visually inspect the cover and actual 64px icon, verify PNG structure/dimensions/hashes and package/stage parity. Those checks are offline evidence. Native UI rendering remains NOT TESTED. The artwork-only difference has no gameplay authority effect; project gameplay dedicated G7 and stable G8 remain BLOCKED.
