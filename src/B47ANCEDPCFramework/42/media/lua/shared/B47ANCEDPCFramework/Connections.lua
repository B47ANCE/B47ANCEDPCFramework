local function empty(t) for _ in pairs(t) do return false end;return true end
-- Server-owned physical-PC topology. Connections never grant inventory access.
local Device=require 'B47ANCEDPCFramework/Device'
local N={version=1,policies={}};local checked=setmetatable({},{__mode='k'})
local function int(n,lo,hi) return type(n)=='number' and n==n and n%1==0 and n>=lo and n<=hi end
local function id(v) return type(v)=='string' and #v>0 and #v<=80 and not v:find('%c') end
function N.enabled() return Device.enabled() and (not SandboxVars or not SandboxVars.B47ANCEDPCFramework or SandboxVars.B47ANCEDPCFramework.ConnectionsEnabled~=false) end
function N.registerPolicy(name,fn) assert(id(name) and type(fn)=='function' and not N.policies[name],'invalid PC connection policy');N.policies[name]=fn end
local function allowed(actor,obj,action,near)
 if not N.enabled() or not Device.computer(actor,obj,near) then return false end
 for _,fn in pairs(N.policies) do if fn(actor,obj,action)~=true then return false end end
 return true
end
local function root()
 if isClient() then return end
 local r=ModData.getOrCreate('B47ANCEDPCConnections')
 if empty(r) then r.schema=1;r.revision=0;r.nodes={} end
 if type(r)~='table' or r.schema~=1 or not int(r.revision,0,9007199254740000) or type(r.nodes)~='table' then return end
 if not checked[r] then
  local count=0
  for key,v in pairs(r.nodes) do
   if not id(key) or type(v)~='table' or type(v.links)~='table' or type(v.public)~='boolean' or not int(v.x,-10000000,10000000) or not int(v.y,-10000000,10000000) or not int(v.z,-32,31) then return end
   local links=0;for peer,flag in pairs(v.links) do if not id(peer) or flag~=true then return end;links=links+1 end
   if links>32 or v.pair~=nil and (type(v.pair)~='table' or (type(v.pair.owner)~='string' or #v.pair.owner<1 or #v.pair.owner>256 or v.pair.owner:find('%c')) or type(v.pair.untilHour)~='number' or v.pair.untilHour~=v.pair.untilHour or v.pair.untilHour<0 or v.pair.untilHour==math.huge) then return end
   count=count+1;if count>256 then return end
  end
  checked[r]=true
 end
 return r
end
local function account(actor) return isServer() and actor:getUsername() or 'local:'..actor:getPlayerNum() end
local function now() return getGameTime():getWorldAgeHours() end
local function resolve(key,row)
 local sq=getCell():getGridSquare(row.x,row.y,row.z);local objects=sq and sq:getObjects()
 if not objects or objects:size()>512 then return end
 for n=0,objects:size()-1 do local obj=objects:get(n)
  if Device.isComputerSprite(obj:getSprite()) and obj:getModData().B47PCNetworkID==key then return obj end
 end
end
local function node(r,obj,create)
 local key=obj:getModData().B47PCNetworkID;local s=obj:getSquare()
 if id(key) and r.nodes[key] then local row=r.nodes[key];if resolve(key,row)==obj then return key,row end;if not create then return end end
 if not create then return end
 if not s or not int(s:getX(),-10000000,10000000) or not int(s:getY(),-10000000,10000000) or not int(s:getZ(),-32,31) then return end
 local count=0;for _ in pairs(r.nodes) do count=count+1 end;if count>=256 then return end
 key=getRandomUUID();if not id(key) or r.nodes[key] then return end
 local row={x=s:getX(),y=s:getY(),z=s:getZ(),public=false,links={}}
 r.nodes[key]=row;obj:getModData().B47PCNetworkID=key;obj:transmitModData();r.revision=r.revision+1
 return key,row
end
function N.members(actor,computer)
 if isClient() or not allowed(actor,computer,'inspect',true) then return nil,'unavailable' end
 local r=root();if not r then return nil,'schema' end
 local key,row=node(r,computer,false);if not row then return {{computer=computer}},nil,1 end
 local out,queue,seen={}, {key}, {[key]=true};local index=1
 while queue[index] do
  local current=queue[index];local v=r.nodes[current];index=index+1
  if v then
   local object=resolve(current,v)
   if object and allowed(actor,object,'inspect',false) then
    out[#out+1]={id=current,computer=object}
   end
    local peers={};for peer in pairs(v.links) do peers[#peers+1]=peer end;table.sort(peers)
    for _,peer in ipairs(peers) do
     if not seen[peer] and r.nodes[peer] and r.nodes[peer].links[current] then
      if #queue>=32 then return nil,'tooLarge' end;seen[peer]=true;queue[#queue+1]=peer
     end
    end
  end
 end
 return out,nil,#queue
end
function N.handle(actor,command,args)
 if isClient() or not actor or actor:isDead() or type(args)~='table' then return {status='invalid'} end
 local hour=now();if type(hour)~='number' or hour~=hour or hour<0 or hour==math.huge then return {status='unavailable'} end
 local computer=Device.object(args.computer)
 if not allowed(actor,computer,command=='list' and 'inspect' or 'configure',true) then return {status='unavailable'} end
 local r=root();if not r then return {status='schema'} end
 local key,row=node(r,computer,true);if not row then return {status='tooLarge'} end
 if command~='list' then
  if args.revision~=r.revision then return {status='conflict'} end
  if command=='pair' then
   local value=SandboxVars and SandboxVars.B47ANCEDPCFramework and SandboxVars.B47ANCEDPCFramework.PairingHours
   row.pair={owner=account(actor),untilHour=now()+(int(value,1,168) and value or 24)}
  elseif command=='public' and type(args.public)=='boolean' then row.public=args.public
  elseif command=='connect' and id(args.peer) and args.peer~=key then
   local target=r.nodes[args.peer]
   if not target or not target.public and not (target.pair and target.pair.owner==account(actor) and now()<=target.pair.untilHour) then return {status='denied'} end
   local queue,seen={key,args.peer},{[key]=true,[args.peer]=true};local i=1
   while queue[i] do
    local address=queue[i];i=i+1;local current=r.nodes[address]
    for peer in pairs(current.links) do
     if r.nodes[peer] and r.nodes[peer].links[address] and not seen[peer] then
      if #queue>=32 then return {status='tooLarge'} end;seen[peer]=true;queue[#queue+1]=peer
     end
    end
   end
   -- An offline invited PC may be paired from its recorded invitation. It cannot
   -- contribute live data until its exact physical object is revalidated.
   row.links[args.peer]=true;target.links[key]=true
  elseif command=='disconnect' and id(args.peer) then
   row.links[args.peer]=nil;if r.nodes[args.peer] then r.nodes[args.peer].links[key]=nil end
  else return {status='invalid'} end
  r.revision=r.revision+1
 end
 local peers={};for peer in pairs(row.links) do
  local other=r.nodes[peer];local object=other and resolve(peer,other)
  peers[#peers+1]={id=peer,online=object~=nil and allowed(actor,object,'inspect',false) or false}
 end;table.sort(peers,function(a,b) return a.id<b.id end)
 local network,queue,seen={}, {key}, {[key]=true};local index=1;local truncated=false
 while queue[index] do
  local address=queue[index];index=index+1;local current=r.nodes[address]
  if current then
   local object=resolve(address,current);network[#network+1]={id=address,online=object~=nil and allowed(actor,object,'inspect',false) or false,direct=row.links[address]==true}
   local links={};for peer in pairs(current.links) do links[#links+1]=peer end;table.sort(links)
   for _,peer in ipairs(links) do if not seen[peer] and r.nodes[peer] and r.nodes[peer].links[address] then
    if #queue>=32 then truncated=true else seen[peer]=true;queue[#queue+1]=peer end
   end end
  end
 end
 table.sort(network,function(a,b) return a.id<b.id end)
 return {network=network,truncated=truncated,status='ok',id=key,revision=r.revision,public=row.public,pairing=row.pair~=nil and row.pair.owner==account(actor) and now()<=row.pair.untilHour or false,peers=peers}
end
return N
