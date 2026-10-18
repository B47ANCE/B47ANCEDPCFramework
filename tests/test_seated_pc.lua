-- Native-shaped seating/rest doubles; no game or animation execution.
local f=PC_FIXTURE;local actor,pc=f.actor,f.computer
local Device=require 'B47ANCEDPCFramework/Device'
local oldCell,oldManager,oldServer=getCell,SeatingManager,isServer
local oldSquare,oldSprite=actor.square,pc.getSprite
local oldSitting,oldSeat=actor.isSittingOnFurniture,actor.getSitOnFurnitureObject
local cells={};local seated=true;local occupied;local positions=1
local function square(x,y,z)
 local s={x=x,y=y,z=z or 0,objects={},blocked={}}
 function s:getX() return self.x end;function s:getY() return self.y end;function s:getZ() return self.z end
 function s:getObjects() return {size=function() return #s.objects end,get=function(_,i) return s.objects[i+1] end} end
 function s:canReachTo(other) return not self.blocked[other] end
 cells[x..':'..y..':'..s.z]=s;return s
end
local function chair(s)
 local o={square=s,index=0};s.objects={o}
 function o:getSquare() return self.square end;function o:getObjectIndex() return self.index end
 return o
end
getCell=function() return {getGridSquare=function(_,x,y,z)
 return cells[x..':'..y..':'..z] or oldCell():getGridSquare(x,y,z)
end} end
SeatingManager={getInstance=function() return {getTilePositionCount=function(_,seat) assert(seat==occupied);return positions end} end}
actor.isSittingOnFurniture=function() return seated end
actor.getSitOnFurnitureObject=function() return occupied end
local function place(x,y)
 cells={};local seatSquare=square(x,y);occupied=chair(seatSquare)
 actor.square=square(x*2,y*2);return seatSquare,actor.square
end
-- The actor is two tiles from the PC: ordinary adjacency cannot mask the new path.
for _,v in ipairs({{72,0,1},{73,1,0},{74,0,-1},{75,-1,0}}) do
 pc.getSprite=function() return {name='appliances_com_01_'..v[1]} end
 local seat,body=place(v[2],v[3])
 assert(Device.seatedReachable(actor,pc) and Device.computer(actor,pc,true),'front seat orientation '..v[1])
 seated=false;assert(not Device.computer(actor,pc,true),'seat object alone granted reach');seated=true
 body.blocked[seat]=true;assert(not Device.computer(actor,pc,true),'body-to-seat barrier bypass');body.blocked[seat]=nil
 seat.blocked[f.home]=true;assert(not Device.computer(actor,pc,true),'seat-to-PC barrier bypass');seat.blocked[f.home]=nil
 local loaded=seat.objects;seat.objects={};assert(not Device.computer(actor,pc,true),'removed seat accepted');seat.objects=loaded
 occupied.index=-1;assert(not Device.computer(actor,pc,true),'stale seat index accepted');occupied.index=0
 positions=0;assert(not Device.computer(actor,pc,true),'no native sitting positions accepted');positions=1
 actor.square=square(v[2]*3,v[3]*3);assert(not Device.computer(actor,pc,true),'distant stale seating accepted');actor.square=body
 seat.z=1;assert(not Device.computer(actor,pc,true),'seat on another floor accepted');seat.z=0
 body.z=1;assert(not Device.computer(actor,pc,true),'actor on another floor accepted');body.z=0
 f.home.power=false;assert(not Device.computer(actor,pc,true),'seated power bypass');f.home.power=true
 SandboxVars.B47ANCEDPCFramework.Enabled=false;assert(not Device.computer(actor,pc,true));SandboxVars.B47ANCEDPCFramework.Enabled=true
end
pc.getSprite=oldSprite
for _,v in ipairs({{1,0},{-1,0},{0,-1}}) do
 place(v[1],v[2]);assert(not Device.computer(actor,pc,true),'side/back seat granted extended reach')
end
place(0,1)
local actualSeat=occupied;occupied=nil;assert(not Device.computer(actor,pc,true),'missing furniture accepted');occupied=actualSeat
local manager=SeatingManager;SeatingManager=nil;assert(not Device.computer(actor,pc,true),'missing seating API failed open');SeatingManager=manager
local seatSquare=occupied.square
cells['0:1:0']=square(0,1);assert(not Device.computer(actor,pc,true),'unloaded furniture square accepted');cells['0:1:0']=seatSquare
local function metadata(facing)
 return {name='custom_pc',getProperties=function() return {
  has=function(_,k) return k=='CustomName' or k=='Facing' and facing~=nil end,
  get=function(_,k) if k=='CustomName' then return 'Computer' elseif k=='Facing' then return facing end end} end}
end
pc.getSprite=function() return metadata('S') end;assert(Device.computer(actor,pc,true),'Computer/Facing metadata rejected')
for _,facing in ipairs({'Unknown','s','SE'}) do
 pc.getSprite=function() return metadata(facing) end;assert(not Device.computer(actor,pc,true),'unknown facing granted extended reach')
end
pc.getSprite=function() return metadata(nil) end;assert(not Device.computer(actor,pc,true),'missing facing granted extended reach')
actor.square=f.home;assert(Device.computer(actor,pc,true),'ordinary adjacent access changed')
pc.getSprite=oldSprite;place(0,1)
-- Server authorization reads the actual actor's furniture, never a request's seat flag.
isServer=function() return true end
local oldSafe=SafeHouse
SafeHouse={isSafehouseAllowLoot=function() return false end,isSafehouseAllowInteract=function() return true end}
assert(not Device.computer(actor,pc,true),'seated safehouse bypass');SafeHouse=oldSafe
local service=require('B47ANCEDPCFramework/MinesweeperService').new()
local started=service.handle(actor,'start',{computer=f.server.position,seat={x=100,y=100}})
assert(started.status=='ok','server PC program rejected actual front-seat state')
seated=false
assert(service.handle(actor,'start',{computer=f.server.position,seated=true,seat={x=0,y=1}}).status=='unavailable','client seat claims granted server access')
seated=true;f.advance(150);started=service.handle(actor,'start',{computer=f.server.position});assert(started.status=='ok');isServer=oldServer
-- Opening a PC while the native rest action remains queued must not touch that queue.
local P=require 'B47ANCEDPCFramework/API';local Startup=require 'B47ANCEDPCFramework/Startup'
local oldQueue,oldWalk=ISTimedActionQueue.getTimedActionQueue,luautils
local resting={Type='ISRestAction'};local queue={queue={resting}}
ISTimedActionQueue.getTimedActionQueue=function() return queue end
local walks=0;luautils={walkAdj=function() walks=walks+1;return true end}
local entries={};local context={addOption=function(_,_,_,fn) entries[#entries+1]=fn end}
Startup.menu(0,context,{pc},false);assert(#entries>0);entries[1]()
local screen=assert(P.ComputerUI.active[0],'rest queue prevented immediate seated desktop')
screen:prerender();assert(P.ComputerUI.active[0]==screen,'seated desktop closed on access refresh')
assert(#queue.queue==1 and queue.queue[1]==resting and walks==0,'opening changed rest or initiated walking')
occupied.index=-1;screen:prerender();assert(not P.ComputerUI.active[0],'removed chair left desktop usable')
entries[1]();assert(not P.ComputerUI.active[0] and walks==0 and queue.queue[1]==resting,'invalid seated access walked away')
entries={};Startup.menu(0,context,{pc},false);assert(#entries==0,'unreachable seated PC exposed an unusable action')
occupied.index=0
-- Reach is revalidated before server moves, too.
seated=false;f.advance(150)
assert(service.handle(actor,'move',{token=started.token,seq=1,action='reveal',x=1,y=1}).status=='unavailable')
ISTimedActionQueue.getTimedActionQueue=oldQueue;luautils=oldWalk
getCell=oldCell;SeatingManager=oldManager;isServer=oldServer
actor.square=oldSquare;actor.isSittingOnFurniture=oldSitting;actor.getSitOnFurnitureObject=oldSeat;pc.getSprite=oldSprite
print('PASS OFFLINE seated PCs: four facings, native seat identity/pose, bounded offset, floors/barriers, power/safehouse/sandbox, server intent rejection, rest queue preservation and desktop revalidation')
