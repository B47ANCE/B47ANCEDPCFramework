-- API-1 app sessions hosted by one native CRT desktop per player/PC.
require 'B47ANCEDPCUI/Controls'
require 'ISUI/ISComboBox'
local U=B47ANCEDPCUI
local Media=require 'B47ANCEDPCFramework/Device'
local UI=require 'B47ANCEDPCFramework/UI'
local Assets=require 'B47ANCEDPCFramework/Assets'
local Desktop=require 'B47ANCEDPCFramework/Desktop'
local C={active={},desktops={}};B47ANCEDPCFramework.ComputerUI=C
C.colors=Assets.palette()
local P=C.colors;local R=U.Renderer
local function tr(k,...) return getText('UI_B47PC_'..k,...) end
local function text(w,s,x,y,width,c) R.text(w,R.fit(s,width),x,y,c or P.black) end
C.decorate=UI.style
local function button(owner,label,fn)
 return UI.button(owner,{text=label,onClick=function(control) return fn(owner,control) end})
end
function C.keyboard(panel,back)
 panel:setWantKeyEvents(true)
 panel.isKeyConsumed=function(self,key) return self.playerNum==0 and key==Keyboard.KEY_ESCAPE end
 panel.onKeyRelease=function(self,key) if self:isKeyConsumed(key) then back() end end
end
function C.isLive(host)
 local d=host and host.desktopHost
 return d~=nil and C.desktops[host.playerNum]==d and d:live(host)
end
local function defaults(hooks)
 hooks.id=hooks.id or 'desktop';hooks.enabled=hooks.enabled or Media.enabled;hooks.canUse=hooks.canUse or Media.computer
 hooks.busy=hooks.busy or function() return false end;hooks.close=hooks.close or function() end
 hooks.text=hooks.text or function(k,...) return tr(k,...) end;hooks.canRun=hooks.canRun or function() return false end
 hooks.drive=hooks.drive or function(_,_,reply) reply({status='ok',choices={}}) end;hooks.read=hooks.read or function() end
 return hooks
end
local function choice(owner)
 local b=ISComboBox:new(12,12,300,U.Theme.metrics().button,owner,function() end)
 b:initialise();b:instantiate();C.decorate(b,'input');owner:addChild(b);return b
end
local function picked(combo) local o=combo.options[combo.selected];return o and o.data end
local function options(combo,items,empty)
 local old=picked(combo);local signature=''
 for _,item in ipairs(items) do signature=signature..':'..item:getID()..':'..item:getDisplayName() end
 if signature==combo.mediaSignature then for i,item in ipairs(items) do if combo.options[i] then combo.options[i].data=item end end;return end
 combo.mediaSignature=signature;combo:clear()
 if #items==0 then combo:addOptionWithData(tr(empty),false) else
  for i,item in ipairs(items) do combo:addOptionWithData(item:getDisplayName()..' #'..item:getID(),item);if old and old.getID and item:getID()==old:getID() then combo.selected=i end end
 end
end
local function session(d,hooks)
 local num,computer,actor=d.playerNum,d.computer,d.actor
 local m=U.Theme.metrics();local screen=d:addSession(hooks)
 local driveAt=-10000;local available={};screen.drivePending=false;screen.driveReady=false
 local function permitted()
  if not C.isLive(screen) then return false end
  if getSpecificPlayer(num)~=actor or not Media.computer(actor,computer,true) then screen:close();return false end
  if not hooks.enabled() or not hooks.canUse(actor,computer,true) then d:retire(screen);d:refreshCatalog();return false end
  return true
 end
 local function media(row)
  return {token=row.token,drive=row.drive,getID=function() return row.id end,getDisplayName=function() return row.name end,getFullType=function() return row.fullType end}
 end
 function screen:applyDrive(result)
  if not C.isLive(self) then return end
  local old=self.mounted;local current=result.mounted and media(result.mounted)
  if old and (not current or old.drive~=current.drive or old:getID()~=current:getID()) then self:closeApp();self.status=tr('ComputerMediaLost') end
  self.mounted=current;self.slot=result.slot or current and current.drive;self.occupied=result.occupied==true;available={}
  for _,row in ipairs(result.choices or {}) do available[#available+1]=media(row) end
 end
 function screen:refreshDrive()
  if hooks.hasDrive==false or screen.drivePending or getTimestampMs()-driveAt<2000 then return end
  screen.drivePending=true;driveAt=getTimestampMs()
  hooks.drive('list',{},function(r)
   if not C.isLive(self) or getSpecificPlayer(num)~=actor or not Media.computer(actor,computer,true) or not hooks.enabled() or not hooks.canUse(actor,computer,true) then return end
   screen.drivePending=false;screen.driveReady=r.status=='ok'
   if screen.driveReady then self:applyDrive(r) else self.mounted=nil;self:closeApp();self.status=hooks.text(r.status) end
  end)
 end
 function screen:message(key) self.status=hooks.text(key) end
 function screen:eject()
  if not permitted() then return end
  hooks.drive('eject',{drive=self.slot},function(r)
   if not C.isLive(self) then return end
   if r.status=='ok' then self:closeApp();self.mounted=nil;self.occupied=false;screen.status=tr('ComputerEjected');driveAt=-10000;self:openDrive() else screen.status=hooks.text(r.status) end
  end)
 end
 function screen:runDisc()
  if not permitted() then return end
  if hooks.busy() then screen.status=tr('busy');return end
  local disc=self.mounted
  if not disc or not screen.driveReady or screen.drivePending or not disc.drive or not hooks.canRun(disc) then screen.status=tr('ComputerNoApplication');return end
  hooks.read(disc,self)
 end
 local function view(title)
  local frame=screen.frame;local v=ISPanelJoypad:new(0,0,frame:getWidth()-8,frame:getHeight()-m.button-12);v.playerNum=num;v:initialise();v:instantiate();UI.focus(v,{})
  v.close=function(self) if self.closed then return end;self.closed=true;U.Tooltip.dispose(self);screen:release(self) end
  C.keyboard(v,function() v:close() end)
  v.onJoypadDown=function(self,key) if key==Joypad.BButton then self:close() else ISPanelJoypad.onJoypadDown(self,key) end end
  screen:showApp(v,title);return v
 end
 function screen:openDrive()
  if not permitted() then return end
  self:refreshDrive();local v=view(tr('ComputerDrive'));v.media=choice(v)
  local providers={}
  if C.launcher then for _,row in ipairs(C.launcher.list(num,computer)) do if row.hasDrive then providers[#providers+1]=row end end end
  if #providers>1 then
   v.providers=UI.combo(v,{options={},onChange=function(id)
    if not C.isLive(screen) then return end
    local target=C.launcher.open(num,computer,id);if target then target:openDrive() end
   end})
   for i,row in ipairs(providers) do v.providers:addOptionWithData(row.title,row.id);if row.id==self.application then v.providers.selected=i end end
  end
  v.insert=button(v,tr('ComputerInsert'),function()
   if not C.isLive(screen) or screen.content~=v then return end
   if hooks.busy() then return end
   local disc=picked(v.media);if not disc or not disc.token or screen.drivePending then return end
   hooks.drive('mount',{token=disc.token},function(r)
    if not C.isLive(screen) or screen.content~=v then return end
    if r.status=='ok' then screen:closeApp();screen:applyDrive(r);screen.status=tr('ComputerInserted',disc:getDisplayName());driveAt=-10000;screen:openDrive() else screen.status=hooks.text(r.status);driveAt=-10000 end
   end)
  end)
  v.run=button(v,tr('ComputerRun'),function() if screen.content==v then screen:runDisc() end end)
  v.eject=button(v,tr('ComputerEject'),function() if screen.content==v then screen:eject() end end)
  v.file=button(v,hooks.file or tr('ComputerNoApplication'),function() screen.status=tr('ComputerRunHint') end)
  v.file.b47PCSelected=true
  v.file.render=function(self)
   Assets.drawIcon(self,hooks.icon or 'application',12,(self:getHeight()-28)/2,28)
   text(self,self.title,52,(self:getHeight()-m.font)/2,self:getWidth()-64);R.focus(self)
  end
  v.file.onMouseDoubleClick=function() if screen.content==v then screen:runDisc() end;return true end
  v.prerender=function(self)
   screen:refreshDrive()
   options(self.media,available,'ComputerNoCD');local w,h=self:getWidth(),self:getHeight()
   local offset=self.providers and m.button+8 or 0
   if self.providers then U.Layout.place(self.providers,12,12,w-24,m.button) end
   U.Layout.place(self.media,12,12+offset,w-24,m.button);U.Layout.place(self.insert,12,20+m.button+offset,w-24,m.button)
   local runnable=screen.driveReady and screen.mounted and hooks.canRun(screen.mounted)
   U.Layout.place(self.file,12,40+2*m.button+offset,w-24,2*m.button);self.file:setVisible(runnable==true)
   U.Layout.place(self.run,12,h-m.button-12,(w-36)/2,m.button);U.Layout.place(self.eject,24+(w-36)/2,h-m.button-12,(w-36)/2,m.button)
   self.run:setEnable(runnable==true and not hooks.busy() and not screen.drivePending);self.eject:setEnable(screen.mounted~=nil or screen.occupied);self.insert:setEnable(screen.driveReady and not screen.drivePending and not screen.mounted and not screen.occupied and not hooks.busy() and picked(self.media)~=false and picked(self.media)~=nil)
   if not runnable then text(self,screen.mounted and tr('ComputerBlankCD') or tr('ComputerInsertHint'),12,40+2*m.button+offset,w-24) end
  end
  if v.providers then v:insertNewLineOfButtons(v.providers) end
  v:insertNewLineOfButtons(v.media);v:insertNewLineOfButtons(v.insert)
  if screen.mounted and hooks.canRun(screen.mounted) then v:insertNewLineOfButtons(v.file) end
  v:insertNewLineOfButtons(v.run,v.eject)
  v:prerender();self:refreshFocus();return v
 end
 function screen:view(title) return view(title) end
 function screen:openWriter() if permitted() and hooks.writer then return hooks.writer(self,hooks) end end
 function screen:openProgram()
  if not permitted() then return end
  if hooks.busy() then screen.status=tr('busy');return end
  if hooks.launch then return hooks.launch(self) end
  return self:openWriter()
 end
 function screen:updateSession()
  if self.driveReady then self:refreshDrive() end
 end
 return screen
end
function C.open(num,computer,hooks)
 hooks=defaults(hooks or {})
 local actor=getSpecificPlayer(num)
 if not actor or not Media.computer(actor,computer,true) or not hooks.enabled() or not hooks.canUse(actor,computer,true) then return end
 local d=C.desktops[num]
 if d and (d.computer~=computer or d.actor~=actor) then d:close();d=nil end
 if not d then
  d=Desktop.new(C,num,computer);if not d then return end
  d.home=session(d,defaults({id='desktop',hasDrive=false,sessionKey=d.homeKey}));d.current=d.home
 end
 local host=hooks.isDesktop and d.home or d.sessions[hooks.sessionKey or hooks.id]
 if not host then host=session(d,hooks) end
 d:refreshCatalog()
 if hooks.isDesktop then d:showDesktop() else d:activate(host) end
 return host
end
C.button=button;C.choice=choice;C.picked=picked;C.options=options;C.text=text
return C
