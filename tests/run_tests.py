"""Offline Lua 5.1/static tests. Does not launch, package, deploy or publish."""
from pathlib import Path
import json,re
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'src/B47ANCEDPCFramework'
LUA=SOURCE/'42/media/lua'
def runtime():
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.globals().package.path=';'.join((str(LUA/'client/?.lua').replace('\\','/'),str(LUA/'shared/?.lua').replace('\\','/'),lua.globals().package.path))
    lua.globals().EXAMPLE_ROOT=(ROOT/'examples').as_posix()
    return lua
lua=runtime()
for path in LUA.rglob('*.lua'):
    code=path.read_text(encoding='utf-8')
    lua.execute('assert(loadstring(...))',code)
    assert 'B47ANCEDQuartermaster' not in code,path
    for name in re.findall(r"require\s*\(?\s*['\"]([^'\"]+)",code):
        if name.startswith('B47ANCEDPC'):
            assert any((LUA/side/(name+'.lua')).is_file() for side in ('client','shared','server')),(path,name)
for name in ('test_minesweeper.lua','test_core.lua','test_minesweeper_mood.lua','test_minesweeper_network.lua','test_cd_programs_server.lua','test_devices.lua','test_desktop.lua','test_seated_pc.lua','test_public_ui.lua','test_composites.lua','test_example.lua','test_cd_programs_client.lua','test_cd_program_example.lua','test_minesweeper_ui.lua','test_unified_desktop.lua','test_full_pc_frame.lua','test_connections.lua','test_network_ui.lua','test_notifications.lua'):
    lua.execute((ROOT/'tests'/name).read_text(encoding='utf-8'))
english=json.loads((LUA/'shared/Translate/EN/UI.json').read_text(encoding='utf-8'))
example_text='\n'.join(p.read_text(encoding='utf-8') for p in (ROOT/'examples').glob('*.lua'))
example_keys=json.loads((ROOT/'examples/Translate/EN/UI.json').read_text(encoding='utf-8'))
assert set(re.findall(r"['\"](UI_PC(?:Gallery|CD)_[^'\"]+)['\"]",example_text))==set(example_keys)
assert not re.search(r'Quartermaster|Supply Ledger|Supply Sheet',json.dumps(english),re.I),'application text leaked into framework translations'
for path in (LUA/'client/B47ANCEDPCFramework').rglob('*.lua'):
    code=path.read_text(encoding='utf-8')
    for key in re.findall(r"['\"](UI_B47PC_[^'\"]+)['\"]",code):
        if key.endswith('_'): continue  # dynamic prefixes are checked at their call sites below
        assert key in english,(path,key)
    for key in re.findall(r"tr\('([^']+)'",code):
        assert 'UI_B47PC_'+('Mines_' if path.name=='Minesweeper.lua' else '')+key in english,(path,key)
for state in ('ready','playing','won','lost','Pending','Unavailable','Busy','Relief'):
    assert 'UI_B47PC_Mines_'+state in english
for locale in (LUA/'shared/Translate').iterdir():
    assert json.loads((locale/'UI.json').read_text(encoding='utf-8'))==english
    assert json.loads((locale/'Sandbox.json').read_text())==json.loads((LUA/'shared/Translate/EN/Sandbox.json').read_text())
info=(SOURCE/'42/mod.info').read_text()
assert 'id=B47ANCEDPCFramework\n' in info and '\nrequire=' not in info
actual=sorted(p.relative_to(SOURCE).as_posix() for p in SOURCE.rglob('*') if p.is_file())
assert actual==json.loads((ROOT/'scripts/production-files.json').read_text()),'source inventory mismatch'
assert len(actual)==len({p.casefold() for p in actual}),'source filename case collision'
assert all(not p.startswith('/') and '..' not in Path(p).parts for p in actual)
assert not any(p.suffix.lower() in ('.jar','.java','.class') for p in SOURCE.rglob('*'))
for side in ('common','42'):
    for directory in ('AnimSets','actiongroups'):
        assert (SOURCE/side/'media'/directory).is_dir()
print('PASS OFFLINE Lua 5.1 syntax, case-correct requires, standalone metadata, Lua-only source, runtime directories and 29-locale English fallback parity')
