local P=require 'B47ANCEDPCFramework/Identity'
local Device=require 'B47ANCEDPCFramework/Device'
local C=require 'B47ANCEDPCFramework/ComputerUI'
local UI=require 'B47ANCEDPCFramework/UI'
local Assets=require 'B47ANCEDPCFramework/Assets'
local Context=require 'B47ANCEDPCFramework/ProgramContext'
local CD=require 'B47ANCEDPCFramework/CDPrograms'
P.UI=UI;P.Assets=Assets
P.Notifications=require 'B47ANCEDPCFramework/Notifications'
P.Connections=require 'B47ANCEDPCFramework/ConnectionsClient'
local features={['pc-connections']=true,['notifications']=true,['installed-apps']=true,['ui-controls']=true,['hosted-windows']=true,['drawing-assets']=true,['custom-icons']=true,['media-adapters']=true,['tabs']=true,['toolbars']=true,['status-bars']=true,['cd-programs']=true,['unified-desktop']=true,['retained-app-windows']=true,['crt-frame']=true}
function P.supports(name) return features[name]==true end
function P.getAPIInfo()
 local copy={};for k,v in pairs(features) do copy[k]=v end
 return {frameworkVersion=P.version,applicationVersion=P.apiVersion,uiVersion=UI.version,assetsVersion=Assets.version,notificationVersion=P.Notifications.version,connectionsVersion=P.Connections.version,cdProgramVersion=CD.version,features=copy}
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
 P.registerApplication(d.id,function(num,computer)
  local probe=Context.probe(num,computer)
  if d.enabled and not d.enabled(probe) then return end
  return {hasDrive=false,programTitle=getText(d.titleKey),icon=d.icon,
   enabled=function() return not d.enabled or d.enabled(probe) end,
   canUse=function(_,_,near) return not d.canUse or d.canUse(probe,near) end,
   launch=function(host) return Context.launch(d,num,computer,host) end}
 end,getText(d.titleKey))
 return d.id
end
-- CD descriptors reuse authenticated real-media bindings; there is no autorun.
function P.registerCDProgram(definition)
 local d=CD.describe(definition)
 for _,key in ipairs({'titleKey','file','create','drive','requestRun','enabled','canUse','onClose','onDenied'}) do d[key]=definition[key] end
 assert(type(d.titleKey)=='string' and #d.titleKey>0,'CD program requires titleKey')
 assert(type(d.file)=='string' and #d.file<=80 and d.file:match('^[%w_.-]+%.[Ee][Xx][Ee]$'),'CD program requires an EXE display filename')
 for _,key in ipairs({'create','drive','requestRun'}) do assert(type(d[key])=='function','CD program requires '..key) end
 for _,key in ipairs({'enabled','canUse','onClose','onDenied'}) do assert(d[key]==nil or type(d[key])=='function','invalid CD program callback: '..key) end
 P.registerApplication(d.id,function(num,computer)
  local probe=Context.probe(num,computer);local pending
  if d.enabled and not d.enabled(probe) then return end
  local function usable(host)
   return C.isLive(host) and getSpecificPlayer(num)==probe.player
    and Device.computer(probe.player,computer,true) and (not d.enabled or d.enabled(probe))
    and (not d.canUse or d.canUse(probe,true))
  end
  local function matches(host,id,drive,fullType)
   local current=host.mounted
   return usable(host) and host.driveReady and current and current.drive==drive
    and current:getID()==id and current:getFullType()==fullType
  end
  return {file=d.file,hasDrive=true,
   enabled=function() return not d.enabled or d.enabled(probe) end,
   canUse=function(_,_,near) return not d.canUse or d.canUse(probe,near) end,
   busy=function()
    if pending and getTimestampMs()-pending.at>15000 then
     local expired=pending;pending=nil
     if usable(expired.host) and expired.host.content==expired.source then expired.host:message('ComputerRunTimedOut') end
    end
    return pending~=nil
   end,
   close=function() pending=nil end,
   canRun=function(media) return CD.acceptsType(d,media:getFullType()) end,
   drive=function(command,args,reply) return d.drive(probe,command,args,reply) end,
   read=function(media,host)
    if pending then return end
    local id,drive,fullType=media:getID(),media.drive,media:getFullType()
    if not matches(host,id,drive,fullType) then return end
    local ticket={at=getTimestampMs(),source=host.content,host=host};pending=ticket;host:message('ComputerCheckingCD')
    local request={program=d.id,media=id,drive=drive}
    local ok,err=pcall(d.requestRun,probe,request,function(result)
     if pending~=ticket then return end;pending=nil
     if host.content~=ticket.source or not matches(host,id,drive,fullType) then return end
     if getTimestampMs()-ticket.at>15000 then host:message('ComputerRunTimedOut');return end
     local valid=type(result)=='table' and result.status=='ok' and type(result.program)=='table' and type(result.media)=='table'
      and result.program.id==d.id and result.program.version==d.version and result.media.id==id
      and result.media.drive==drive and result.media.fullType==fullType
     if not valid then
      host:message('ComputerNoApplication')
      local status=type(result)=='table' and type(result.status)=='string' and result.status or 'invalid'
      if d.onDenied then d.onDenied(probe,status=='ok' and 'incompatible' or status) end;return
     end
     Context.launch(d,num,computer,host,{program={id=d.id,version=d.version},media={id=id,drive=drive,fullType=fullType}},
      function() return matches(host,id,drive,fullType) end)
    end)
    if not ok then if pending==ticket then pending=nil end;error(err) end
   end}
 end,getText(d.titleKey))
 return d.id
end
function P.open(num,computer,id)
 local hooks
 if id then hooks=available(num,computer,id,true);if not hooks then return end
 end
 hooks=hooks or {};hooks.id=id or 'desktop';hooks.isDesktop=id==nil
 hooks.enabled=hooks.enabled or Device.enabled;hooks.canUse=hooks.canUse or Device.computer
 hooks.busy=hooks.busy or function() return false end;hooks.close=hooks.close or function() end
 hooks.text=hooks.text or function(k,...) return getText('UI_B47PC_'..k,...) end
 hooks.canRun=hooks.canRun or function() return false end
 hooks.drive=hooks.drive or function(_,_,reply) reply({status='ok',choices={}}) end
 hooks.read=hooks.read or function() end
 return C.open(num,computer,hooks)
end
C.launcher={open=P.open,openTool=function(num,computer,id)
 local hooks=available(num,computer,id,true);if not hooks or not hooks.writer then return end
 hooks.id=id;hooks.sessionKey='\0tool:'..id
 return C.open(num,computer,hooks)
end,list=function(num,computer)
 local rows={}
 for _,id in ipairs(P.applications()) do
  local h=available(num,computer,id,true)
  if h then rows[#rows+1]={id=id,title=h.launcherTitle or P.applicationTitle(id),icon=h.icon or 'application',hasDrive=h.hasDrive~=false,
   toolTitle=h.writer and (h.toolTitle or getText('UI_B47PC_ComputerApplications')) or nil} end
 end
 return rows
end}
return P
