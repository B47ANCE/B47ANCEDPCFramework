"""Explicit reproducible packaging entry point. Never deploys or publishes."""
from pathlib import Path
import hashlib,json,subprocess,sys,zipfile
ROOT=Path(__file__).resolve().parents[1]
subprocess.run([sys.executable,'-B',str(ROOT/'scripts/check_versions.py')],check=True)
subprocess.run([sys.executable,'-B',str(ROOT/'tests/run_tests.py')],check=True)
source=ROOT/'src/B47ANCEDPCFramework'
version=(ROOT/'VERSION').read_text().strip()
out=ROOT/'dist/current';out.mkdir(parents=True,exist_ok=True)
archive=out/f'B47ANCEDPCFramework-{version}.zip'
if archive.exists():
    raise SystemExit('Current artifact already exists; preserve its provenance and review before replacing it.')
expected={}
for name in json.loads((ROOT/'scripts/production-files.json').read_text()):
    assert not Path(name).is_absolute() and '..' not in Path(name).parts
    expected['B47ANCEDPCFramework/'+name]=(source/name).read_bytes()
assert len(expected)==len({n.casefold() for n in expected})
with zipfile.ZipFile(archive,'x',zipfile.ZIP_DEFLATED) as z:
    for name,data in sorted(expected.items()):
        info=zipfile.ZipInfo(name,date_time=(1980,1,1,0,0,0))
        info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16
        z.writestr(info,data)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert len(z.namelist())==len(set(z.namelist())) and set(z.namelist())==set(expected)
    assert all(z.read(n)==data for n,data in expected.items())
receipt={'version':version,'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
         'dirty':bool(subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True).strip()),
         'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'files':{n:hashlib.sha256(d).hexdigest() for n,d in expected.items()},
         'native_sp':'NOT TESTED','dedicated_g7':'BLOCKED / NOT TESTED','stable_g8':'BLOCKED'}
(out/(archive.name+'.provenance.json')).write_text(json.dumps(receipt,indent=2)+'\n')
subprocess.run([sys.executable,'-B',str(ROOT/'scripts/check_versions.py'),'--release'],check=True)
print('PACKAGED',archive.name,receipt['sha256'],'native SP/dedicated NOT TESTED')
