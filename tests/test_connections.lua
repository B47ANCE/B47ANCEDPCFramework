-- Production topology/authority, native-shaped PCs; no game/network claim.
local N=require 'B47ANCEDPCFramework/Connections';local f=PC_FIXTURE
local actor=f.actor;local a=f.computer;local b=getCell():getGridSquare(1,0,0):getObjects():get(0)
local saved=actor.square;local oldTime=getGameTime;local age=100
getGameTime=function() return {getWorldAgeHours=function() return age end} end
local function position(o) local s=o:getSquare();return {x=s:getX(),y=s:getY(),z=s:getZ(),index=o:getObjectIndex()} end
local function call(o,command,args,who)
 local r=args or {};r.computer=position(o)
 return N.handle(who or actor,command,r)
end
actor.square=a:getSquare();local first=call(a,'list');assert(first.status=='ok' and #first.network==1)
assert(call(a,'pair',{revision=first.revision-1}).status=='conflict')
first=call(a,'pair',{revision=first.revision});assert(first.pairing and not first.public)
actor.square=b:getSquare();local second=call(b,'list');assert(second.status=='ok')
local stranger={getCurrentSquare=function() return b:getSquare() end,getPlayerNum=function() return 1 end,isDead=function() return false end}
assert(call(b,'connect',{revision=second.revision,peer=first.id},stranger).status=='denied','private invitation crossed accounts')
local connected=call(b,'connect',{revision=second.revision,peer=first.id});assert(connected.status=='ok' and #connected.network==2)
local members,why,total=N.members(actor,b);assert(#members==2 and total==2 and not why)
local home=a:getSquare();home.power=false
local offline=call(b,'list');local down=0;for _,row in ipairs(offline.network) do if not row.online then down=down+1 end end
assert(down==1 and #N.members(actor,b)==1,'offline PC contributed an online endpoint')
home.power=true
-- Reinitialization retains server records and exact physical markers.
package.loaded['B47ANCEDPCFramework/Connections']=nil;local rebuilt=require 'B47ANCEDPCFramework/Connections'
assert(#rebuilt.members(actor,b)==2)
local disconnected=call(b,'disconnect',{revision=offline.revision,peer=first.id});assert(disconnected.status=='ok' and #disconnected.network==1)
age=200;assert(call(b,'connect',{revision=disconnected.revision,peer=first.id}).status=='denied','expired invitation was reused')
actor.square=a:getSquare();first=call(a,'list');first=call(a,'public',{revision=first.revision,public=true});assert(first.public)
actor.square=b:getSquare();second=call(b,'list');connected=call(b,'connect',{revision=second.revision,peer=first.id},stranger);assert(connected.status=='ok','public endpoint required private invitation')
actor.square=a:getSquare();assert(call(b,'pair',{revision=connected.revision}).status=='ok') -- adjacent PC remains physically reachable
local oldMarker=a:getModData().B47PCNetworkID;a:getModData().B47PCNetworkID='removed'
assert(#N.members(actor,b)==1,'replacement physical identity inherited a connection');a:getModData().B47PCNetworkID=oldMarker
local root=ModData.getOrCreate('B47ANCEDPCConnections');root.schema=99;assert(call(a,'list').status=='schema' and root.schema==99);root.schema=1
SandboxVars.B47ANCEDPCFramework.ConnectionsEnabled=false;assert(call(a,'list').status=='unavailable');SandboxVars.B47ANCEDPCFramework.ConnectionsEnabled=true
local snapshots=#f.server.container.items
-- Reject an oversized merged component before writing either reciprocal edge.
local savedNodes,savedRevision=root.nodes,root.revision
local ka,kb=a:getModData().B47PCNetworkID,b:getModData().B47PCNetworkID
root.nodes={[ka]={x=0,y=0,z=0,public=true,links={}},[kb]={x=1,y=0,z=0,public=true,links={}}}
local previous=ka
for i=1,30 do local key='bounded-'..i;root.nodes[key]={x=100+i,y=0,z=0,public=false,links={[previous]=true}};root.nodes[previous].links[key]=true;previous=key end
root.nodes.extra={x=200,y=0,z=0,public=false,links={[kb]=true}};root.nodes[kb].links.extra=true
local revision=root.revision
assert(call(b,'connect',{revision=revision,peer=ka}).status=='tooLarge')
assert(root.revision==revision and not root.nodes[ka].links[kb] and not root.nodes[kb].links[ka],'rejected link mutated persistent topology')
root.nodes,root.revision=savedNodes,savedRevision
local scan=assert(f.server.drive.scanMedia(actor,a));local rows,status
for _=1,100 do rows,status=scan.step();if status~='waiting' then break end end
assert(status=='done' and #rows==1 and f.server.drive.validateMedia(actor,a,rows[1])==f.server.snapshot)
f.server.permission(false);assert(not f.server.drive.validateMedia(actor,a,rows[1]));f.server.permission(true)
assert(#f.server.container.items==snapshots,'read-only media scan moved items')
actor.square=saved;getGameTime=oldTime
print('PASS OFFLINE PC connections: visited private pairing, public opt-in, wrong account/expired invitation/stale revisions, persistence, physical identity, offline status and unavailable exclusion, disabled/future schema and read-only media scan')
