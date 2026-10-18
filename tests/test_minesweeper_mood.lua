local S=require 'B47ANCEDPCFramework/MinesweeperService'
local Game=require 'B47ANCEDPCFramework/Apps/MinesweeperGame'
local f=PC_FIXTURE;local time=0;local awards={};local serial=0
local function random() local seed=3;return function(a,b) seed=(seed*73+19)%997;return a+seed%(b-a+1) end end
local service=S.new({now=function() return time end,uuid=function() serial=serial+1;return 'mood-'..serial end,random=random(),
 apply=function(actor,b,u) assert(actor==f.actor);awards[#awards+1]={b,u};return true end})
local function start()
 time=time+150;return service.handle(f.actor,'start',{computer=f.server.position})
end
local result=start();assert(result.status=='ok' and result.seq==0)
local token=result.token;local seq=0;local mirror=Game.new(random())
for _,c in ipairs(result.cells) do assert(not c.mine and c.count==0,'hidden mines leaked') end
local function move(x,y,action,elapsed)
 time=time+(elapsed or 150);seq=seq+1
 local args={token=token,seq=seq,x=x,y=y,action=action or 'reveal',boredom=999,unhappiness=999,player='forged'}
 local r=service.handle(f.actor,'move',args)
 mirror[action or 'reveal'](mirror,x,y);return r,args
end
local function progress(elapsed)
 for y=1,9 do for x=1,9 do local c=mirror:cell(x,y)
  if not c.open and not c.mine and not c.flag and c.count>0 then return move(x,y,'reveal',elapsed) end
 end end;error('fixture exhausted progress')
end
result=move(1,1);assert(#awards==0 and result.state=='playing')
progress(10000);progress(10000);local args
result,args=progress(10000);assert(result.relief and #awards==1 and awards[1][1]==2 and awards[1][2]==1)
result=service.handle(f.actor,'move',args);assert(not result.relief and #awards==1,'replayed move awarded twice')
time=time+150;result=service.handle(f.actor,'move',args);assert(result.status=='ok' and not result.relief and #awards==1)
local other=setmetatable({},{__index=f.actor});assert(service.handle(other,'move',args).status=='changed','foreign sender used session')
assert(service.handle(f.actor,'move',{token=token,seq=seq+2,x=1,y=1,action='reveal'}).status=='changed')
assert(service.handle(f.actor,'move',{token=token,seq=0/0,x=1,y=1,action='reveal'}).status=='invalid')
-- Flag toggles are legal game actions but cannot accumulate benefit time.
local flagged
for y=1,9 do for x=1,9 do if not flagged and not mirror:cell(x,y).open then flagged={x,y} end end end
for n=1,6 do move(flagged[1],flagged[2],'flag',1000) end
assert(#awards==1);progress(60000);assert(#awards==1,'idle window accrued a benefit')
SandboxVars.B47ANCEDPCFramework.MinesweeperMoodEffects=false
progress(10000);progress(10000);progress(10000);assert(#awards==1,'disabled effects mutated mood')
SandboxVars.B47ANCEDPCFramework.MinesweeperMoodEffects=nil
f.home.power=false;assert(progress(10000).status=='unavailable');f.home.power=true
assert(service.handle(f.actor,'move',{token=token,seq=seq+1,x=1,y=1,action='reveal'}).status=='changed')
result=start();assert(#awards==1 and not result.relief,'reset granted benefit')
local replacement=result.token
service.handle(f.actor,'stop',{token=token})
time=time+150;assert(service.handle(f.actor,'move',{token=replacement,seq=1,x=1,y=1,action='flag'}).status=='ok','stale stop cleared replacement')
service.handle(f.actor,'stop',{token=replacement})
assert(service.handle(f.actor,'move',{token=replacement,seq=2,x=1,y=1,action='reveal'}).status=='changed')
result=start();time=time+300001;service.tick()
assert(service.handle(f.actor,'move',{token=result.token,seq=1,x=1,y=1,action='reveal'}).status=='changed')
f.server.client(true);assert(service.handle(f.actor,'start',{computer=f.server.position}).status=='invalid' and not S.apply(f.actor,2,1));f.server.client(false)
SandboxVars.B47ANCEDPCFramework.MinesweeperBoredomRelief=999
SandboxVars.B47ANCEDPCFramework.MinesweeperUnhappinessRelief=0/0
assert(S.settings().boredom==2 and S.settings().unhappiness==1)
SandboxVars.B47ANCEDPCFramework.MinesweeperBoredomRelief=nil;SandboxVars.B47ANCEDPCFramework.MinesweeperUnhappinessRelief=nil
-- Native-shaped contract: enum stat removal clamps via the native API, followed
-- by server-to-owner vanilla stat synchronization. No custom client setters.
local oldServer,oldStats,oldSync,oldEnums,oldPacket=isServer,f.actor.getStats,syncPlayerStats,CharacterStat,SyncPlayerStatsPacket
local values={boredom=1,unhappiness=.5};local synced
CharacterStat={BOREDOM='boredom',UNHAPPINESS='unhappiness'}
f.actor.getStats=function() return {remove=function(_,kind,amount) local old=values[kind];values[kind]=math.max(0,old-amount);return old~=values[kind] end} end
SyncPlayerStatsPacket={getBitMaskForStat=function(kind) return kind=='boredom' and 1 or 131072 end}
syncPlayerStats=function(actor,mask) assert(actor==f.actor);synced=mask end;isServer=function() return true end
assert(S.apply(f.actor,2,1) and values.boredom==0 and values.unhappiness==0 and synced==131073)
syncPlayerStats=nil;values.boredom=5;assert(not S.apply(f.actor,2,1) and values.boredom==5,'missing sync partially mutated stats')
isServer=oldServer;f.actor.getStats=oldStats;syncPlayerStats=oldSync;CharacterStat=oldEnums;SyncPlayerStatsPacket=oldPacket
print('PASS OFFLINE mood authority: server board, redacted snapshots, sequenced intent, real progress/time, defaults, forged rates/senders, replay, idle/flags/reset, disable/power/expiry and native-shaped stat sync')
