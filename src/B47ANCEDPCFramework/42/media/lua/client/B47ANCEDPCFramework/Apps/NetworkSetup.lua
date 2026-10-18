return function(PC)
 local Network=PC.Connections;local UI=PC.UI
 local function tr(key,...) return getText('UI_B47PC_'..key,...) end
 PC.registerApp({id='b47pc.network',titleKey='UI_B47PC_NetworkTitle',icon='computer',
  enabled=function() return require('B47ANCEDPCFramework/Connections').enabled() end,
  create=function(ctx)
   local state={peers={},revision=0};local pending=false;local statusMode=true;local last=-10000;local status='';local controls={};local send
   local function layout(self,w,h)
    local m=UI.metrics();local b=m.button
    UI.place(controls.mode,8,8,(w-24)/2,b);UI.place(controls.code,16+(w-24)/2,8,(w-24)/2,b)
    UI.place(controls.status,8,16+b,w-16,2*m.font+4)
    UI.place(controls.pair,8,24+b+2*m.font,(w-24)/2,b);UI.place(controls.public,16+(w-24)/2,24+b+2*m.font,(w-24)/2,b)
    UI.place(controls.peer,8,32+2*b+2*m.font,w-144,b);UI.place(controls.connect,w-128,32+2*b+2*m.font,120,b)
    for _,key in ipairs({'pair','public','peer','connect','disconnect'}) do controls[key]:setVisible(not statusMode) end
    local y=statusMode and 24+b+2*m.font or 40+3*b+2*m.font;UI.place(controls.list,8,y,w-16,math.max(b,h-y-b-16));UI.place(controls.disconnect,8,h-b-8,w-16,b)
    UI.focus(self,statusMode and {{controls.mode,controls.code},{controls.list}} or {{controls.mode,controls.code},{controls.pair,controls.public},{controls.peer,controls.connect},{controls.list},{controls.disconnect}})
   end
   local window=ctx.window({onResize=layout,onUpdate=function()
    if not pending and getTimestampMs()-last>=5000 then send('list') end
   end})
   local function update(r)
    pending=false;last=getTimestampMs()
    if r.status~='ok' then status=tr('NetworkUnavailable');controls.status:setText(status);controls.list:clear();return end
    state=r;controls.code:setText(r.id);controls.code.tooltip=r.id
    controls.status:setText(tr(r.public and 'NetworkPublicHelp' or r.pairing and 'NetworkPairingHelp' or 'NetworkPrivateHelp'))
    controls.public:setTitle(tr(r.public and 'NetworkMakePrivate' or 'NetworkMakePublic'))
    local online=0;for _,peer in ipairs(r.network or {}) do if peer.online then online=online+1 end end
    if statusMode then controls.status:setText(r.truncated and tr('NetworkLimit') or tr('NetworkStatusSummary',online,#(r.network or {})-online)) end
    controls.list:clear();for _,peer in ipairs(statusMode and (r.network or {}) or (r.peers or {})) do controls.list:addItem(peer.id..' — '..tr(peer.online and 'NetworkOnline' or 'NetworkOffline'),peer) end
   end
   send=function(command,args)
    if pending or not ctx.isActive() then return end;pending=true
    args=args or {};args.revision=state.revision
    Network.request(ctx.playerNum,ctx.computer,command,args,ctx.guard(update))
   end
   controls.mode=UI.button(window,{textKey='UI_B47PC_NetworkPairing',onClick=function() statusMode=not statusMode;controls.mode:setTitle(tr(statusMode and 'NetworkPairing' or 'NetworkStatus'));last=-10000;layout(window,window:getWidth(),window:getHeight());window:updateComputer() end})
   controls.code=UI.textEntry(window,{value=tr('NetworkLoading'),tooltipKey='UI_B47PC_NetworkAddressHelp'});controls.status=UI.label(window,{text=''})
   controls.pair=UI.button(window,{textKey='UI_B47PC_NetworkStartPairing',onClick=function() send('pair') end})
   controls.public=UI.button(window,{textKey='UI_B47PC_NetworkMakePublic',onClick=function() send('public',{public=not state.public}) end})
   controls.peer=UI.textEntry(window,{value='',tooltipKey='UI_B47PC_NetworkPeerHelp'})
   controls.connect=UI.button(window,{textKey='UI_B47PC_NetworkConnect',onClick=function() send('connect',{peer=controls.peer:getInternalText()}) end})
   controls.list=UI.list(window,{})
   controls.disconnect=UI.button(window,{textKey='UI_B47PC_NetworkDisconnect',onClick=function()
    local row=controls.list.items[controls.list.selected];if row then send('disconnect',{peer=row.item.id}) end
   end})
   UI.focus(window,{{controls.mode,controls.code},{controls.pair,controls.public},{controls.peer,controls.connect},{controls.list},{controls.disconnect}})
   window.networkControls=controls;send('list');window:updateComputer();return window
  end})
end
