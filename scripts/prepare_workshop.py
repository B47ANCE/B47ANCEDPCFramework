"""Stage an already validated package; never logs in, uploads or restarts Steam."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
LABEL = 'MP testing build - dedicated multiplayer NOT TESTED'


def prepare(create_public=False):
    version = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
    item_path = ROOT / 'WORKSHOP_ID.txt'
    if create_public:
        assert not item_path.exists(), 'Item already assigned; never create another'
        item = '0'
    else:
        item = item_path.read_text(encoding='utf-8').strip()
        assert item.isdigit() and 7 <= len(item) <= 20 and item != '0'
    archive = ROOT / 'dist/current' / f'B47ANCEDPCFramework-{version}.zip'
    receipt = json.loads(archive.with_name(archive.name + '.provenance.json').read_text(encoding='utf-8'))
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    assert receipt['source_commit'] == head and not receipt['dirty']
    assert not subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT).strip()
    assert receipt['sha256'] == hashlib.sha256(archive.read_bytes()).hexdigest()
    description = (ROOT / 'workshop/description.bbcode').read_text(encoding='utf-8').strip()
    note = (ROOT / 'docs/WORKSHOP_CHANGELOG.md').read_text(encoding='utf-8').strip()
    assert LABEL in description and LABEL in note and '\\n' not in description + note
    assert len(description.encode('utf-8')) <= 8000 and f'Version {version}' in note
    stage = ROOT / 'dist' / f'workshop-{version}-{head[:12]}'
    assert not stage.exists(), 'Preserve previous staging and submission evidence'
    mods = stage / 'Contents/mods'
    mods.mkdir(parents=True)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        names = z.namelist()
        assert len(names) == len(set(names)) == len({n.casefold() for n in names})
        for name in names:
            path = Path(name)
            assert not path.is_absolute() and '..' not in path.parts and path.parts[0] == 'B47ANCEDPCFramework'
            data = z.read(name)
            assert hashlib.sha256(data).hexdigest() == receipt['files'][name]
            assert data == (ROOT / 'src' / path).read_bytes()
            target = mods / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    preview = stage / 'preview.png'
    preview.write_bytes((ROOT / 'preview-client.png').read_bytes())
    fields = dict(appid='108600', publishedfileid=item, contentfolder=str(stage / 'Contents'),
                  previewfile=str(preview), title='B47ANCED PC Framework', description=description, changenote=note)
    if create_public:
        fields['visibility'] = '0'
    def escape(value):
        return value.replace('\\', '\\\\').replace('"', '\\"').replace('\r\n', '\n').replace('\r', '\n')
    vdf = stage / 'submission.vdf'
    vdf.write_text('"workshopitem"\n{\n' + ''.join(f'    "{key}" "{escape(value)}"\n' for key, value in fields.items()) + '}\n', encoding='utf-8-sig')
    manifest = dict(receipt, appid=108600, mod_id='B47ANCEDPCFramework', workshop_id=item,
                    creation_requested=create_public, target_game='42.21.0 / Steam build 25485521',
                    vdf_sha256=hashlib.sha256(vdf.read_bytes()).hexdigest(),
                    preview_sha256=hashlib.sha256(preview.read_bytes()).hexdigest(), upload='NOT PERFORMED')
    (stage / 'release-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(vdf)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--create-public', action='store_true', help='Only with explicit user approval for the first public item')
    prepare(parser.parse_args().create_public)
