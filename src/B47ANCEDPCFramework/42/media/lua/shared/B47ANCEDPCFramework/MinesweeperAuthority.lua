if isClient() then return {} end
local service=require('B47ANCEDPCFramework/MinesweeperService').default()
local module='B47ANCEDPCMinesweeper';local last=0
local function command(name,action,actor,args)
 if name~=module or type(args)~='table' then return end
 local request=args.request
 if type(request)~='string' or #request<1 or #request>80 or not request:match('^[%w_.-]+$') then return end
 local result=service.handle(actor,action,args)
 if action=='stop' then return end
 result.request=request
 if isServer() then sendServerCommand(actor,module,'result',result) end
end
if Events then
 if Events.OnClientCommand then Events.OnClientCommand.Add(command) end
 if Events.OnTick then Events.OnTick.Add(function()
  local time=getTimestampMs();if time-last>=1000 then last=time;service.tick() end
 end) end
end
return {command=command}
