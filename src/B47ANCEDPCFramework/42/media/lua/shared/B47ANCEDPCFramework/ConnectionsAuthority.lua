local S=require 'B47ANCEDPCFramework/Connections'
local A={};local buckets=setmetatable({},{__mode='k'})
function A.handle(actor,command,args)
 if isClient() or not actor or actor:isDead() or type(args)~='table' or args.protocol~=1 then return {status='invalid'} end
 local time=getTimestampMs();local b=buckets[actor] or {at=time,tokens=4};buckets[actor]=b
 b.tokens=math.min(4,b.tokens+math.max(0,time-b.at)*.002);b.at=time
 if b.tokens<1 then return {status='busy'} end;b.tokens=b.tokens-1
 return S.handle(actor,command,args)
end
function A.command(module,command,actor,args)
 if module~='B47ANCEDPCConnections' or type(args)~='table' or type(args.request)~='string' or #args.request>80 then return end
 local r=A.handle(actor,command,args);r.request=args.request
 if isServer() then sendServerCommand(actor,module,'result',r) end
end
if not isClient() and Events and Events.OnClientCommand then Events.OnClientCommand.Add(A.command) end
return A
