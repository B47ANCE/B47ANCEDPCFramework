"""Read installed tile metadata and check recognition without loading the game."""
import argparse,hashlib,json,re
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--game',type=Path,required=True);args=p.parse_args()
path=args.game/'media/newtiledefinitions.tiles.txt'
text=path.read_text(encoding='utf-8-sig')
computers={}
for match in re.finditer(r'// ([A-Za-z0-9_]+)\s*\n\s*tile\s*\{(.*?)^\s*\}',text,re.M|re.S):
    fields=dict(re.findall(r'^[ \t]*(\w+)[ \t]*=[ \t]*([^\n]*)$',match[2],re.M))
    if fields.get('CustomName','').strip()=='Computer':
        computers[match[1]]=fields.get('Facing','').strip()
assert computers==dict(zip(('appliances_com_01_'+str(n) for n in range(72,76)),('S','E','N','W'))),computers
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().package.path=str(ROOT/'src/B47ANCEDPCFramework/42/media/lua/shared/?.lua').replace('\\','/')+';'+lua.globals().package.path
recognizes=lua.eval("require('B47ANCEDPCFramework/Device').isComputerSprite")
for name in computers:assert recognizes(lua.table_from({'name':name})),name
print('PASS OFFLINE installed computer definitions: '+json.dumps(computers,sort_keys=True))
print('Native tile evidence SHA-256: '+hashlib.sha256(path.read_bytes()).hexdigest()+'; no game execution')
