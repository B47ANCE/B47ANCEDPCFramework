require 'B47ANCEDPCFramework/Identity'
local M={}
-- Verified vanilla orientations; metadata also supports other computer tiles.
local nativeComputers={appliances_com_01_72=true,appliances_com_01_73=true,appliances_com_01_74=true,appliances_com_01_75=true}
function M.isComputerSprite(sprite)
 if not sprite then return false end
 if nativeComputers[sprite.name] then return true end
 local props=sprite.getProperties and sprite:getProperties()
 return props~=nil and props:has('CustomName') and props:get('CustomName')=='Computer' or false
end
function M.enabled() return not SandboxVars or not SandboxVars.B47ANCEDPCFramework or SandboxVars.B47ANCEDPCFramework.Enabled~=false end
function M.reachable(actor,obj)
 local sq=obj and obj:getSquare();local here=actor:getCurrentSquare()
 if not sq or not here or here:getZ()~=sq:getZ() then return false end
 if math.max(math.abs(here:getX()-sq:getX()),math.abs(here:getY()-sq:getY()))>1 then return false end
 return here==sq or here:canReachTo(sq)
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
