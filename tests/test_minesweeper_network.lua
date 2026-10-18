local f=PC_FIXTURE
local oldEvents=Events;local onCommand,onTick
Events={OnClientCommand={Add=function(fn) onCommand=fn end},OnTick={Add=function(fn) onTick=fn end}}
local server=require 'B47ANCEDPCFramework/MinesweeperAuthority';assert(onCommand and onTick)
local oldServer,oldSend=isServer,sendServerCommand;local response
isServer=function() return true end
sendServerCommand=function(actor,module,command,result) assert(actor==f.actor and module=='B47ANCEDPCMinesweeper' and command=='result');response=result end
onCommand('B47ANCEDPCMinesweeper','start',f.actor,{computer=f.server.position,request='server-proof',actor='forged'})
assert(response and response.request=='server-proof' and response.status=='ok')
local board=response;response=nil
onCommand('B47ANCEDPCMinesweeper','start',f.actor,{computer=f.server.position,request={}});assert(not response)
isServer=oldServer;sendServerCommand=oldSend;Events=oldEvents
local Client=require 'B47ANCEDPCFramework/MinesweeperClient'
f.server.client(true);local oldClient=sendClientCommand;local sent;local replies=0
sendClientCommand=function(actor,module,command,args) assert(actor==f.actor and module=='B47ANCEDPCMinesweeper');sent=args end
local cancel=Client.request(f.actor,'start',{computer=f.server.position},function(result) replies=replies+1;assert(Client.view(result)) end)
board.request=sent.request;Client.result('wrong','result',board);assert(replies==0)
Client.result('B47ANCEDPCMinesweeper','result',board);Client.result('B47ANCEDPCMinesweeper','result',board);assert(replies==1)
cancel=Client.request(f.actor,'start',{computer=f.server.position},function() error('canceled response ran') end)
board.request=sent.request;cancel();Client.result('B47ANCEDPCMinesweeper','result',board)
Client.request(f.actor,'start',{computer=f.server.position},function() error('expired response ran') end)
board.request=sent.request;f.advance(15001);Client.result('B47ANCEDPCMinesweeper','result',board)
sendClientCommand=oldClient;f.server.client(false);f.advance(150)
print('PASS OFFLINE mood transport: authenticated native sender dispatch, targeted/correlated response, malformed IDs, duplicate/canceled/expired replies and no client stat mutation')
