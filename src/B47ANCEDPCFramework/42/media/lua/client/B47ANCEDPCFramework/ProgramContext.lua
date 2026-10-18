-- Private hosted lifecycle shared by installed and CD program descriptors.
local Device=require 'B47ANCEDPCFramework/Device'
local C=require 'B47ANCEDPCFramework/ComputerUI'
local UI=require 'B47ANCEDPCFramework/UI'
local Assets=require 'B47ANCEDPCFramework/Assets'
local Context={}
function Context.probe(num,computer,host)
 return {playerNum=num,player=getSpecificPlayer(num),computer=computer,host=host,ui=UI,assets=Assets}
end
function Context.launch(d,num,computer,host,extra,valid)
 host:closeApp()
 local ctx=Context.probe(num,computer,host);local panel;local alive=true
 for k,v in pairs(extra or {}) do ctx[k]=v end
 function ctx.isActive()
  return alive and not host.closed and C.active[num]==host and getSpecificPlayer(num)==ctx.player
   and Device.computer(ctx.player,computer,true) and (not d.enabled or d.enabled(ctx))
   and (not d.canUse or d.canUse(ctx,true)) and (not valid or valid())
   and (not panel or not panel.closed and host.content==panel)
 end
 function ctx.guard(callback)
  assert(type(callback)=='function','PC guard requires a callback')
  return function(...) if ctx.isActive() then return callback(...) end end
 end
 function ctx.window(options)
  assert(not panel,'PC app owns one hosted window')
  local o={};for k,v in pairs(options or {}) do o[k]=v end;o.titleKey=o.titleKey or d.titleKey
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
end
return Context
