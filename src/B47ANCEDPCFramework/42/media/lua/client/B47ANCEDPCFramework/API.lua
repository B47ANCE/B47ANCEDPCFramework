local P=require 'B47ANCEDPCFramework/Identity'
local Device=require 'B47ANCEDPCFramework/Device'
local C=require 'B47ANCEDPCFramework/ComputerUI'
local UI=require 'B47ANCEDPCFramework/UI'
local Assets=require 'B47ANCEDPCFramework/Assets'
P.UI=UI;P.Assets=Assets
local features={['installed-apps']=true,['ui-controls']=true,['hosted-windows']=true,['drawing-assets']=true,['custom-icons']=true,['media-adapters']=true}
function P.supports(name) return features[name]==true end
function P.getAPIInfo()
 local copy={};for k,v in pairs(features) do copy[k]=v end
 return {frameworkVersion=P.version,applicationVersion=P.apiVersion,uiVersion=UI.version,assetsVersion=Assets.version,features=copy}
end
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
-- Additive installed-app descriptor API; legacy media factories remain API 1.
function P.registerApp(definition)
 assert(type(definition)=='table' and type(definition.create)=='function','PC app requires a create callback')
 assert(type(definition.titleKey)=='string' and #definition.titleKey>0,'PC app requires a localized titleKey')
 local d={};for _,key in ipairs({'id','titleKey','icon','create','enabled','canUse','onClose'}) do d[key]=definition[key] end
 for _,key in ipairs({'enabled','canUse','onClose'}) do assert(d[key]==nil or type(d[key])=='function','invalid PC app callback: '..key) end
 d.icon=d.icon or 'application';assert(Assets.hasIcon(d.icon),'unknown PC app icon')
 local function context(num,computer,host)
  return {playerNum=num,player=getSpecificPlayer(num),computer=computer,host=host,ui=UI,assets=Assets}
 end
 P.registerApplication(d.id,function(num,computer)
  local probe=context(num,computer)
  if d.enabled and not d.enabled(probe) then return end
  return {hasDrive=false,programTitle=getText(d.titleKey),icon=d.icon,
   enabled=function() return not d.enabled or d.enabled(probe) end,
   canUse=function(_,_,near) return not d.canUse or d.canUse(probe,near) end,
   launch=function(host)
    host:closeApp()
    local ctx=context(num,computer,host);local panel;local alive=true
    function ctx.isActive()
     return alive and not host.closed and C.active[num]==host and getSpecificPlayer(num)==ctx.player
      and Device.computer(ctx.player,computer,true) and (not d.enabled or d.enabled(ctx))
      and (not d.canUse or d.canUse(ctx,true)) and (not panel or not panel.closed and host.content==panel)
    end
    function ctx.guard(callback)
     assert(type(callback)=='function','PC guard requires a callback')
     return function(...) if ctx.isActive() then return callback(...) end end
    end
    function ctx.window(options)
     assert(not panel,'PC installed app owns one hosted window')
     local o={};for k,v in pairs(options or {}) do o[k]=v end
     o.titleKey=o.titleKey or d.titleKey
     local onClose=o.onClose
     o.onClose=function(reason)
      alive=false
      local ok,err=pcall(function() if onClose then onClose(reason) end end)
      local done,issue=pcall(function() if d.onClose then d.onClose(ctx,reason) end end)
      if not ok then error(err) end;if not done then error(issue) end
     end
     panel=UI.window(host,o);return panel
    end
    local ok,result=pcall(d.create,ctx)
    if not ok or not panel or result~=nil and result~=panel then
     alive=false;if panel and not panel.closed then pcall(panel.close,panel,'error') end
     error(not ok and result or 'PC app create must construct ctx.window and return that window or nil')
    end
    return panel
   end}
 end,getText(d.titleKey))
 return d.id
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
