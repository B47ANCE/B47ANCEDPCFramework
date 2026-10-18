-- Reuse only the independent framework world fixture; no app source.
local f=PC_FIXTURE;local computer,actor,sq=f.computer,f.actor,f.home
local Device=require 'B47ANCEDPCFramework/Device'
local sprite=computer.getSprite
for n=72,75 do
 computer.getSprite=function() return {name='appliances_com_01_'..n} end
 sq.power=true;assert(Device.computer(actor,computer,true),'powered orientation rejected: '..n)
 sq.power=false;assert(not Device.computer(actor,computer,true),'unpowered orientation accepted: '..n)
end
sq.power=true
local function metadata(name,custom)
 return {name=name,getProperties=function() return {has=function(_,key) return key=='CustomName' and custom~=nil end,get=function(_,key) if key=='CustomName' then return custom end end} end}
end
computer.getSprite=function() return metadata('other_computer_tile','Computer') end
assert(Device.computer(actor,computer,true),'computer metadata required a vanilla sprite name')
sq.power=false;assert(not Device.computer(actor,computer,true),'metadata bypassed electricity');sq.power=true
for _,custom in ipairs({'Television','Microwave','Computer desk','not a Computer'}) do
 computer.getSprite=function() return metadata('computer_in_name_only',custom) end
 assert(not Device.computer(actor,computer,true),'unrelated powered object accepted: '..custom)
end
assert(not Device.isComputerSprite(nil));assert(not Device.isComputerSprite({name='mod_pc_without_metadata'}))
assert(not Device.isComputerSprite({name='unknown',getProperties=function() end}))
computer.getSprite=function() return metadata('other_computer_tile','Computer') end
local oldSafeHouse=SafeHouse;local oldServer=isServer
isServer=function() return true end
SafeHouse={isSafehouseAllowLoot=function() return false end,isSafehouseAllowInteract=function() return true end}
assert(not Device.computer(actor,computer,true),'metadata bypassed safehouse permission')
SafeHouse=oldSafeHouse;isServer=oldServer
local oldIndex=computer.getObjectIndex;computer.getObjectIndex=function() return 99 end
assert(not Device.computer(actor,computer,true),'metadata bypassed loaded object identity');computer.getObjectIndex=oldIndex
local current=actor.getCurrentSquare
actor.getCurrentSquare=function() return {getX=function() return 20 end,getY=function() return 20 end,getZ=function() return 0 end} end
assert(not Device.computer(actor,computer,true),'metadata bypassed adjacent access')
assert(Device.computer(actor,computer,false),'distant context discovery lost')
actor.getCurrentSquare=current
actor.getCurrentSquare=function() return {getZ=function() return 1 end} end
assert(not Device.computer(actor,computer,true),'metadata bypassed floor check')
actor.getCurrentSquare=current
SandboxVars.B47ANCEDPCFramework.Enabled=false;assert(not Device.computer(actor,computer,true));SandboxVars.B47ANCEDPCFramework.Enabled=true
computer.getSprite=sprite
print('PASS OFFLINE powered PCs: all four native orientations and Computer-tagged tiles; power, safehouse, loaded identity, distance, floor and sandbox checks retained; unrelated devices refused')
