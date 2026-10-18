"""Export approved branding sources at UI sizes. Host tool only; never uploads."""
from pathlib import Path
import argparse
import hashlib
import json
from PIL import Image, __version__ as pillow_version

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/branding'
OUTPUTS = (
    ('pc-framework-original.png', 'preview-client.png', 512),
    ('pc-framework-original.png', 'src/B47ANCEDPCFramework/42/poster.png', 512),
    ('pc-framework-computer-transparent.png', 'src/B47ANCEDPCFramework/42/icon.png', 64),
)


def export(icon_only=False):
    previous = json.loads((ASSETS / 'exports.json').read_text(encoding='utf-8')) if icon_only else None
    result = {'schema': 1, 'pillow_version': pillow_version, 'resampling': 'LANCZOS',
              'provenance': 'Full cover supplied by B47ANCE; computer-only icon derivative made with the built-in image editor. No external-mod/OS artwork.',
              'sources': {}, 'outputs': {}}
    for source, destination, size in OUTPUTS:
        path = ASSETS / source
        result['sources'][source] = hashlib.sha256(path.read_bytes()).hexdigest()
        with Image.open(path) as image:
            assert image.width == image.height and image.format == 'PNG'
            if not icon_only or size == 64:
                image.convert('RGBA').resize((size, size), Image.Resampling.LANCZOS).save(ROOT / destination, optimize=True)
            else:
                assert hashlib.sha256((ROOT / destination).read_bytes()).hexdigest() == previous['outputs'][destination]['sha256']
        with Image.open(ROOT / destination) as image:
            image.verify()
        result['outputs'][destination] = {'dimensions': [size, size],
                                           'sha256': hashlib.sha256((ROOT / destination).read_bytes()).hexdigest()}
        if size == 64:
            with Image.open(ROOT / destination) as icon:
                assert icon.mode == 'RGBA' and icon.getchannel('A').getextrema() == (0, 255)
                assert all(icon.getpixel(p)[3] == 0 for p in ((0, 0), (63, 0), (0, 63), (63, 63)))
                result['outputs'][destination]['alpha_extrema'] = [0, 255]
                result['outputs'][destination]['transparent_pixels'] = icon.getchannel('A').histogram()[0]
    assert (ROOT / 'preview-client.png').stat().st_size < 1_000_000
    (ASSETS / 'exports.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('Branding export PASS: full-composition 512px thumbnail/poster; true-alpha 64px computer icon')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--icon-only', action='store_true', help='Preserve thumbnail/poster bytes while exporting the transparent icon')
    export(parser.parse_args().icon_only)
