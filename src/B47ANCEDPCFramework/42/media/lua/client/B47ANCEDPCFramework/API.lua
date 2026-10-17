local P=require 'B47ANCEDPCFramework/Identity'
local Device=require 'B47ANCEDPCFramework/Device'
local C=require 'B47ANCEDPCFramework/ComputerUI'
local apps={};local titles={}
function P.registerApplication(id,factory,title)
 assert(type(id)=='string' and #id<=80 and id:match('^[%w_.-]+$') and type(factory)=='function','invalid PC application')
 assert(not apps[id] or apps[id]==factory,'duplicate PC application')
 apps[id]=factory
 titles[id]=title or id
end
function P.applicationTitle(id) return titles[id] end
function P.applications()
 local ids={};for id in pairs(apps) do ids[#ids+1]=id end;table.sort(ids);return ids
end
local function available(num,computer,id,near)
 local actor=getSpecificPlayer(num);if not actor or not Device.computer(actor,computer,near) then return end
 local hooks=apps[id] and apps[id](num,computer)
 if not hooks or hooks.enabled and not hooks.enabled() or hooks.canUse and not hooks.canUse(actor,computer,near) then return end
 return hooks
end
function P.availableApplications(num,computer)
 local ids={};for _,id in ipairs(P.applications()) do if available(num,computer,id,false) then ids[#ids+1]=id end end;return ids
end
function P.open(num,computer,id)
 local hooks
 if id then hooks=available(num,computer,id,true);if not hooks then return end
 else for _,key in ipairs(P.applications()) do hooks=available(num,computer,key,true);if hooks then id=key;break end end end
 hooks=hooks or {};hooks.id=id or 'desktop'
 hooks.enabled=hooks.enabled or Device.enabled;hooks.canUse=hooks.canUse or Device.computer
 hooks.busy=hooks.busy or function() return false end;hooks.close=hooks.close or function() end
 hooks.text=hooks.text or function(k,...) return getText('UI_B47PC_'..k,...) end
 hooks.canRun=hooks.canRun or function() return false end
 hooks.drive=hooks.drive or function(_,_,reply) reply({status='ok',choices={}}) end
 hooks.read=hooks.read or function() end
 return C.open(num,computer,hooks)
end
return P
