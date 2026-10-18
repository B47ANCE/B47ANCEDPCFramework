-- Server-only board/mood authority. Clients submit coordinates, never rewards.
local Device=require 'B47ANCEDPCFramework/Device'
local Game=require 'B47ANCEDPCFramework/Apps/MinesweeperGame'
local S={}
local function integer(n,a,b) return type(n)=='number' and n==n and n%1==0 and n>=a and n<=b end
local function token(s) return type(s)=='string' and #s>0 and #s<=80 and s:match('^[%w_.-]+$') end
function S.settings()
 local s=SandboxVars and SandboxVars.B47ANCEDPCFramework or {}
 local function number(key,default,min,max) local n=s[key];return integer(n,min,max) and n or default end
 return {enabled=s.MinesweeperMoodEffects~=false,boredom=number('MinesweeperBoredomRelief',2,0,10),
  unhappiness=number('MinesweeperUnhappinessRelief',1,0,10),interval=number('MinesweeperReliefInterval',30,10,300),
  activity=number('MinesweeperActivityTimeout',30,5,120)}
end
function S.apply(actor,boredom,unhappiness)
 if isClient() or not actor or actor:isDead() or not integer(boredom,0,10) or not integer(unhappiness,0,10) then return false end
 local stats=actor:getStats()
 if not stats or not stats.remove or not CharacterStat or not CharacterStat.BOREDOM or not CharacterStat.UNHAPPINESS then return false end
 local mask
 if isServer() then
  if not syncPlayerStats or not SyncPlayerStatsPacket or not SyncPlayerStatsPacket.getBitMaskForStat then return false end
  local b=SyncPlayerStatsPacket.getBitMaskForStat(CharacterStat.BOREDOM)
  local u=SyncPlayerStatsPacket.getBitMaskForStat(CharacterStat.UNHAPPINESS)
  if not integer(b,1,2147483647) or not integer(u,1,2147483647) or b==u then return false end
  mask=b+u
 end
 local b=stats:remove(CharacterStat.BOREDOM,boredom);local u=stats:remove(CharacterStat.UNHAPPINESS,unhappiness)
 if mask and (b or u) then syncPlayerStats(actor,mask) end
 return b==true or u==true
end
function S.new(adapter)
 local A=adapter or {};local sessions=setmetatable({},{__mode='k'});local limits=setmetatable({},{__mode='k'})
 local now=A.now or getTimestampMs;local uuid=A.uuid or getRandomUUID;local apply=A.apply or S.apply
 local function snapshot(s,relief)
  local g=s.game;local result={status='ok',token=s.token,seq=s.seq,state=g.state,flags=g.flags,revealed=g.revealed,cells={},relief=relief==true}
  for i,c in ipairs(g.cells) do result.cells[i]={open=c.open,flag=c.flag,count=c.open and c.count or 0,
   mine=(g.state=='lost' or g.state=='won') and c.mine or false,exploded=c.exploded==true} end
  return result
 end
 local service={}
 function service.handle(actor,command,args)
  if isClient() or not actor or actor:isDead() or type(args)~='table' then return {status='invalid'} end
  local s=sessions[actor];local time=now()
  if command=='stop' then if s and args.token==s.token then sessions[actor]=nil end;return {status='ok'} end
  if not Device.enabled() then sessions[actor]=nil;return {status='unavailable'} end
  if command~='start' and command~='move' then return {status='invalid'} end
  if command=='move' and (not s or args.token~=s.token or time-s.at>300000) then return {status='changed'} end
  local computer=command=='start' and Device.object(args.computer) or s.computer
  if not Device.computer(actor,computer,true) then sessions[actor]=nil;return {status='unavailable'} end
  if command=='move' then
   if not integer(args.seq,1,1000000) then return {status='invalid'} end
   if args.seq~=s.seq and args.seq~=s.seq+1 then return {status='changed'} end
   if (args.action~='reveal' and args.action~='flag') or not integer(args.x,1,9) or not integer(args.y,1,9) then return {status='invalid'} end
  end
  local limit=limits[actor] or {};limits[actor]=limit
  if limit.at and time-limit.at<100 then return {status='busy'} end;limit.at=time
  if command=='move' and args.seq==s.seq then return snapshot(s) end -- bounded duplicate response, no replay
  if command=='start' then
   local id=uuid();if not token(id) then return {status='unavailable'} end
   s={token=id,seq=0,game=Game.new(A.random),computer=computer,at=time,active=0};sessions[actor]=s
   return snapshot(s)
  end
  local before=s.game.revealed
  s.game[args.action](s.game,args.x,args.y);s.seq=args.seq;s.at=time
  local settings=S.settings();local relief=false
  if s.game.revealed>before then
   local gap=s.progress and time-s.progress
   if gap and gap>=0 and gap<=settings.activity*1000 then s.active=s.active+gap else s.active=0 end
   s.progress=time
   if settings.enabled and s.active>=settings.interval*1000 and (not limit.reward or time-limit.reward>=settings.interval*1000) then
    -- Claim the interval before mutation: failures/replays cannot double-apply.
    s.active=0;limit.reward=time;relief=apply(actor,settings.boredom,settings.unhappiness)==true
   elseif not settings.enabled then s.active=0 end
  end
  return snapshot(s,relief)
 end
 function service.tick()
  local time=now()
  for actor,s in pairs(sessions) do
   if time-s.at>300000 or not Device.computer(actor,s.computer,true) then sessions[actor]=nil end
  end
 end
 return service
end
local default
function S.default() if not default then default=S.new() end;return default end
return S
