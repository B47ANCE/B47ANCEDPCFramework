local C={version=1};local pending={}
function C.result(module,command,args)
 if module~='B47ANCEDPCConnections' or command~='result' or type(args)~='table' then return end
 local p=pending[args.request];if not p then return end;pending[args.request]=nil
 if getSpecificPlayer(p.num)==p.actor and getTimestampMs()-p.at<=15000 then p.reply(args) end
end
function C.request(num,computer,command,args,reply)
 local actor=getSpecificPlayer(num);local sq=computer and computer:getSquare()
 if not actor or not sq then reply({status='unavailable'});return end
 local data={protocol=1,computer={x=sq:getX(),y=sq:getY(),z=sq:getZ(),index=computer:getObjectIndex()}}
 for _,key in ipairs({'peer','public','revision'}) do data[key]=args and args[key] end
 if not isClient() then reply(require('B47ANCEDPCFramework/ConnectionsAuthority').handle(actor,command,data));return end
 local count=0;for _ in pairs(pending) do count=count+1 end;if count>=32 then reply({status='busy'});return end
 local token=getRandomUUID();data.request=token;pending[token]={num=num,actor=actor,reply=reply,at=getTimestampMs()}
 sendClientCommand(actor,'B47ANCEDPCConnections',command,data)
end
function C.tick()
 for token,p in pairs(pending) do
  if getSpecificPlayer(p.num)~=p.actor then pending[token]=nil
  elseif getTimestampMs()-p.at>15000 then pending[token]=nil;p.reply({status='timeout'}) end
 end
end
if Events then
 if Events.OnServerCommand then Events.OnServerCommand.Add(C.result) end
 if Events.OnTick then Events.OnTick.Add(C.tick) end
end
return C
