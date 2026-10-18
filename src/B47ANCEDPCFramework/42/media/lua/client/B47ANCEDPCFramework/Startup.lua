local P=require 'B47ANCEDPCFramework/API'
local Device=require 'B47ANCEDPCFramework/Device'
local pending={}
require 'TimedActions/ISTimedActionQueue'
require 'TimedActions/WalkToTimedAction'
local function open(num,obj,id)
 local actor=getSpecificPlayer(num);if not actor then return end
 if Device.computer(actor,obj,true) then return P.open(num,obj,id) end
 if not Device.computer(actor,obj,false) or #ISTimedActionQueue.getTimedActionQueue(actor).queue>0 then return end
 if luautils.walkAdj(actor,obj:getSquare()) then pending[num]={actor=actor,object=obj,application=id,at=getTimestampMs()} end
end
local function menu(num,context,objects,test)
 if test then return end
 local actor=getSpecificPlayer(num);if not actor then return end
 for n=1,math.min(#objects,64) do local obj=objects[n]
  if Device.computer(actor,obj,false) then
   context:addOption(getText('UI_B47PC_ComputerUse'),nil,function() open(num,obj) end)
   local ids=P.availableApplications(num,obj)
   if #ids>1 then for _,id in ipairs(ids) do
    local app=id
    context:addOption(getText('UI_B47PC_ComputerOpenApplication',P.applicationTitle(app)),nil,function() open(num,obj,app) end)
   end end
   break
  end
 end
end
local function tick()
 for num,p in pairs(pending) do
  if getSpecificPlayer(num)~=p.actor or p.actor:isDead() or getTimestampMs()-p.at>120000 or not Device.enabled() then pending[num]=nil
  elseif #ISTimedActionQueue.getTimedActionQueue(p.actor).queue==0 then pending[num]=nil;if Device.computer(p.actor,p.object,true) then P.open(num,p.object,p.application) end end
 end
end
if Events then Events.OnFillWorldObjectContextMenu.Add(menu);Events.OnTick.Add(tick) end
return {menu=menu,tick=tick}
