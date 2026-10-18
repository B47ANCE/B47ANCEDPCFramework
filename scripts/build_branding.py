"""Export approved branding sources at UI sizes. Host tool only; never uploads."""
from pathlib import Path
import hashlib
import json
from PIL import Image, __version__ as pillow_version

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/branding'
OUTPUTS = (
    ('pc-framework-original.png', 'preview-client.png', 512),
    ('pc-framework-original.png', 'src/B47ANCEDPCFramework/42/poster.png', 512),
    ('pc-framework-computer-crop.png', 'src/B47ANCEDPCFramework/42/icon.png', 64),
)


def export():
    result = {'schema': 1, 'pillow_version': pillow_version, 'resampling': 'LANCZOS',
              'provenance': 'Full cover supplied by B47ANCE; computer-only icon derivative made with the built-in image editor. No external-mod/OS artwork.',
              'sources': {}, 'outputs': {}}
    for source, destination, size in OUTPUTS:
        path = ASSETS / source
        result['sources'][source] = hashlib.sha256(path.read_bytes()).hexdigest()
        with Image.open(path) as image:
            assert image.width == image.height and image.format == 'PNG'
            image.convert('RGBA').resize((size, size), Image.Resampling.LANCZOS).save(ROOT / destination, optimize=True)
        with Image.open(ROOT / destination) as image:
            image.verify()
        result['outputs'][destination] = {'dimensions': [size, size],
                                           'sha256': hashlib.sha256((ROOT / destination).read_bytes()).hexdigest()}
    assert (ROOT / 'preview-client.png').stat().st_size < 1_000_000
    (ASSETS / 'exports.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('Branding export PASS: full-composition 512px thumbnail/poster; text-free 64px computer icon')


if __name__ == '__main__':
    export()
