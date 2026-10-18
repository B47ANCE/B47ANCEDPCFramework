-- Independent disposable world fixture: no Quartermaster source is loaded.
SandboxVars={B47ANCEDPCFramework={Enabled=true}}
local client=false;isClient=function() return client end;isServer=function() return false end
local now=0;getTimestampMs=function() return now end
local serial=0;getRandomUUID=function() serial=serial+1;return 'uuid-'..serial end
local function list(t) return {size=function() return #t end,get=function(_,n) return t[n+1] end} end
local squares={};local function square(x,y)
 local s={x=x,y=y,objects={},power=true}
 function s:getX() return self.x end;function s:getY() return self.y end;function s:getZ() return 0 end
 function s:getObjects() return list(self.objects) end;function s:haveElectricity() return self.power end
 function s:hasGridPower() return false end;function s:getRoom() return {} end
 function s:canReachTo() return true end
 squares[x..':'..y]=s;return s
end
local home=square(0,0);local adjacent=square(1,0)
local function object(s)
 local o={square=s,md={},containers={}};s.objects[#s.objects+1]=o
 function o:getSquare() return self.square end;function o:getObjectIndex() return 0 end
 function o:getSprite() return {name='appliances_com_01_72'} end
 function o:getModData() return self.md end;function o:transmitModData() end
 function o:getContainerCount() return #self.containers end
 function o:getContainerByIndex(i) return self.containers[i+1] end
 return o
end
local computer=object(home);local storage=object(adjacent)
getCell=function() return {getGridSquare=function(_,x,y,z) if z==0 then return squares[x..':'..y] end end} end
instanceof=function() return false end
local actor={square=home};function actor:getCurrentSquare() return self.square end;function actor:isDead() return false end
function actor:getPlayerNum() return 0 end;function actor:setHaloNote() end
local Device=require 'B47ANCEDPCFramework/Device'
assert(Device.computer(actor,computer,true))
computer.getSprite=function() return {name='unsupported'} end;assert(not Device.computer(actor,computer,true))
computer.getSprite=function() return {name='appliances_com_01_72'} end
home.power=false;assert(not Device.computer(actor,computer,true));home.power=true
assert(not Device.object({x=0,y=0,z=0,index=0/0}));assert(not Device.object({x=0,y=0,z=0,index=1}))
SandboxVars.B47ANCEDPCFramework.Enabled=false;assert(not Device.computer(actor,computer,true));SandboxVars.B47ANCEDPCFramework.Enabled=true
client=true;assert(not Device.computer(actor,computer,true),'missing multiplayer permissions failed open')
SafeHouse={isSafehouseAllowLoot=function() return true end,isSafehouseAllowInteract=function() return true end}
assert(Device.computer(actor,computer,true));client=false
local roots={};ModData={getOrCreate=function(k) roots[k]=roots[k] or {};return roots[k] end}
local cd={id=41,name='Fixture media',kind='Fixture.Media'};local snapshot={complete=true}
local container={items={cd}};storage.containers={container};cd.container=container
function container:getItems() return list(self.items) end
function container:getItemWithID(id) for _,i in ipairs(self.items) do if i.id==id then return i end end end
function cd:getID() return self.id end;function cd:getDisplayName() return self.name end
function cd:getFullType() return self.kind end;function cd:getContainer() return self.container end
local allowed=true;local enabled=true
local config={store='FixturePCBindings',computerKey='FixtureDrive',storageKey='FixtureStorage',
 media={object=Device.object,computer=Device.computer,disc='Fixture.Media'},
 enabled=function() return enabled end,valid=function(t) return t and t.container~=nil end,
 can=function() return allowed end,target=function(o,ci) return {obj=o,container=o:getContainerByIndex(ci),ci=ci} end,
 snapshot=function(i) if i==cd then return snapshot end end,grants=function() return {} end,
 building=function() return 'fixture-building' end,commands={list='list',mount='mount',eject='eject'},
 status={disabled='disabled',power='power',denied='denied',changed='changed',occupied='occupied'}}
local Service=require 'B47ANCEDPCFramework/DriveService';local D=Service.new(config)
local position={x=0,y=0,z=0,index=0}
local function call(cmd,extra,a)
 extra=extra or {};extra.computer=position;return D.handle(a or actor,cmd,extra)
end
assert(D.handle(actor,'list',false).status=='invalid')
client=true;assert(call('list').status=='invalid');client=false
local offer=call('list');assert(offer.status=='ok' and #offer.choices==1)
local token=offer.choices[1].token
local other=setmetatable({},{__index=actor});assert(call('mount',{token=token},other).status=='changed')
now=31000;assert(call('mount',{token=token}).status=='changed')
offer=call('list');token=offer.choices[1].token
allowed=false;assert(call('mount',{token=token}).status=='denied');allowed=true
assert(call('mount',{token=token}).status=='ok');assert(#container.items==1 and cd.container==container,'mount moved media')
assert(D.protected(cd));local id=computer.md.FixtureDrive
local rebuilt=Service.new(config);assert(rebuilt.read(actor,id,computer)==cd,'restart lost binding')
assert(rebuilt.provider(actor,id)==cd)
allowed=false;assert(not rebuilt.read(actor,id,computer));allowed=true
home.power=false;assert(not rebuilt.provider(actor,id));home.power=true
container.items={};assert(not rebuilt.read(actor,id,computer));container.items={cd}
assert(call('eject',{drive='stale'}).status=='changed')
assert(call('eject',{drive=id}).status=='ok' and #container.items==1)
roots.FixturePCBindings.schema=99;assert(call('list').status=='schema' and D.protected(cd),'future schema did not fail closed')
roots.FixturePCBindings.schema=1
enabled=false;assert(call('list').status=='disabled');enabled=true
PC_FIXTURE={actor=actor,computer=computer,home=home,advance=function(n) now=now+n end}
PC_FIXTURE.server={drive=D,media=cd,container=container,snapshot=snapshot,position=position,
 permission=function(value) allowed=value end,client=function(value) client=value end,
 rebuild=function() return Service.new(config) end}
print('PASS OFFLINE independent device and server drive: power, bounds, safehouse, malformed/client refusal, sender/TTL, permissions, persistence, media loss, stale eject, future schema and no item moves')
