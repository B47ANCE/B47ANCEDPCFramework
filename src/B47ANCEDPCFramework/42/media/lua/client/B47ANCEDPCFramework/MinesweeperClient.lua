-- Presentation transport only. No client stat setters or reward amounts.
local C={};local pending={};local module='B47ANCEDPCMinesweeper'
function C.view(result)
 local states={ready=true,playing=true,won=true,lost=true}
 if type(result)~='table' or result.status~='ok' or not states[result.state] or type(result.cells)~='table' or #result.cells~=81
  or type(result.token)~='string' or #result.token<1 or #result.token>80 or type(result.seq)~='number' or result.seq%1~=0 or result.seq<0
  or type(result.flags)~='number' or result.flags%1~=0 or result.flags<0 or result.flags>10 then return end
 local cells={}
 for i,row in ipairs(result.cells) do
  if type(row)~='table' or type(row.count)~='number' or row.count%1~=0 or row.count<0 or row.count>8 then return end
  cells[i]={open=row.open==true,flag=row.flag==true,mine=row.mine==true,exploded=row.exploded==true,count=row.count}
 end
 return {width=9,height=9,mines=10,state=result.state,flags=result.flags,cells=cells,
  cell=function(self,x,y) return self.cells[(y-1)*9+x] end}
end
function C.result(name,command,args)
 if name~=module or command~='result' or type(args)~='table' then return end
 local p=pending[args.request];if not p then return end;pending[args.request]=nil
 if getTimestampMs()-p.at<=15000 then p.reply(args) end
end
if Events and Events.OnServerCommand then Events.OnServerCommand.Add(C.result) end
function C.request(actor,command,args,reply)
 if not isClient() then
  reply(require('B47ANCEDPCFramework/MinesweeperService').default().handle(actor,command,args));return function() end
 end
 for id,p in pairs(pending) do if getTimestampMs()-p.at>15000 then pending[id]=nil end end
 local id=getRandomUUID();args.request=id;pending[id]={at=getTimestampMs(),reply=reply}
 local ok,err=pcall(sendClientCommand,actor,module,command,args)
 if not ok then pending[id]=nil;error(err) end
 return function() pending[id]=nil end
end
function C.stop(actor,token)
 if not token then return end
 if isClient() then sendClientCommand(actor,module,'stop',{token=token,request=getRandomUUID()})
 else require('B47ANCEDPCFramework/MinesweeperService').default().handle(actor,'stop',{token=token}) end
end
return C
