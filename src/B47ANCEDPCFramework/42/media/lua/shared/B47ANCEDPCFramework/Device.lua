require 'B47ANCEDPCFramework/Identity'
local M={}
-- Verified vanilla orientations; metadata also supports other computer tiles.
local nativeComputers={appliances_com_01_72=true,appliances_com_01_73=true,appliances_com_01_74=true,appliances_com_01_75=true}
local nativeFacing={appliances_com_01_72='S',appliances_com_01_73='E',appliances_com_01_74='N',appliances_com_01_75='W'}
local front={N={0,-1},S={0,1},E={1,0},W={-1,0}}
function M.isComputerSprite(sprite)
 if not sprite then return false end
 if nativeComputers[sprite.name] then return true end
 local props=sprite.getProperties and sprite:getProperties()
 return props~=nil and props:has('CustomName') and props:get('CustomName')=='Computer' or false
end
function M.enabled() return not SandboxVars or not SandboxVars.B47ANCEDPCFramework or SandboxVars.B47ANCEDPCFramework.Enabled~=false end
function M.isSeated(actor)
 return actor~=nil and actor.isSittingOnFurniture~=nil and actor:isSittingOnFurniture()==true
end
function M.seatedReachable(actor,obj)
 if not M.isSeated(actor) or not actor.getSitOnFurnitureObject then return false end
 local seat=actor:getSitOnFurnitureObject();local sq=obj and obj:getSquare()
 local here=actor:getCurrentSquare();local sitting=seat and seat:getSquare()
 if not here or not sq or not sitting or here:getZ()~=sq:getZ() or sitting:getZ()~=sq:getZ() then return false end
 if getCell():getGridSquare(sitting:getX(),sitting:getY(),sitting:getZ())~=sitting then return false end
 local index=seat:getObjectIndex()
 if index<0 or sitting:getObjects():get(index)~=seat then return false end
 if not SeatingManager or not SeatingManager.getInstance then return false end
 local manager=SeatingManager.getInstance()
 if not manager or manager:getTilePositionCount(seat)<=0 then return false end
 local sprite=obj:getSprite();local facing=sprite and nativeFacing[sprite.name]
 if not facing and sprite then
  local properties=sprite.getProperties and sprite:getProperties()
  facing=properties and properties:has('Facing') and properties:get('Facing')
 end
 local direction=front[facing];if not direction then return false end
 if sitting:getX()~=sq:getX()+direction[1] or sitting:getY()~=sq:getY()+direction[2] then return false end
 -- Native seating animation may offset the player's square from the furniture.
 -- Both short segments retain the existing wall/door/window reach test.
 if math.max(math.abs(here:getX()-sitting:getX()),math.abs(here:getY()-sitting:getY()))>1 then return false end
 return (here==sitting or here:canReachTo(sitting)) and sitting:canReachTo(sq)
end
function M.reachable(actor,obj)
 local sq=obj and obj:getSquare();local here=actor:getCurrentSquare()
 if not sq or not here or here:getZ()~=sq:getZ() then return false end
 if math.max(math.abs(here:getX()-sq:getX()),math.abs(here:getY()-sq:getY()))<=1 and (here==sq or here:canReachTo(sq)) then return true end
 return M.seatedReachable(actor,obj)
end
function M.object(d)
 if type(d)~='table' then return end
 for _,k in ipairs({'x','y','z','index'}) do local n=d[k];if type(n)~='number' or n~=math.floor(n) or math.abs(n)>10000000 then return end end
 local sq=getCell():getGridSquare(d.x,d.y,d.z)
 if sq and d.index>=0 and d.index<sq:getObjects():size() then return sq:getObjects():get(d.index) end
end
function M.computer(actor,obj,near)
 if not actor or actor:isDead() or not M.enabled() then return false end
 local sq=obj and obj:getSquare();local sprite=obj and obj:getSprite()
 if not sq or not M.isComputerSprite(sprite) or getCell():getGridSquare(sq:getX(),sq:getY(),sq:getZ())~=sq then return false end
 local index=obj:getObjectIndex();if index<0 or sq:getObjects():get(index)~=obj then return false end
 if near and not M.reachable(actor,obj) then return false end
 if (isServer() or isClient()) and (not SafeHouse or not SafeHouse.isSafehouseAllowLoot(sq,actor) or not SafeHouse.isSafehouseAllowInteract(sq,actor)) then return false end
 return sq:haveElectricity() or sq:hasGridPower() and sq:getRoom()~=nil
end
return M
