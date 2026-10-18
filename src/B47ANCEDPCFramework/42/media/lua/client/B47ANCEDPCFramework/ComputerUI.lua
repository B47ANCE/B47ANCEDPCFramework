-- Original Lua-drawn computer presentation. Mounts are local references, never
-- physical item moves or authority to read a snapshot / complete a CD write.
require 'B47ANCEDPCUI/Controls'
require 'ISUI/ISComboBox'
local U=B47ANCEDPCUI
local Media=require 'B47ANCEDPCFramework/Device'
local Art=require 'B47ANCEDPCFramework/ComputerArt'
local Assets=require 'B47ANCEDPCFramework/Assets'
local C={active={}};B47ANCEDPCFramework.ComputerUI=C
local function color(r,g,b) return {r=r,g=g,b=b,a=1} end
C.colors={case=color(.25,.24,.21),grey=color(.75,.75,.72),light=color(.96,.96,.91),shadow=color(.36,.36,.34),
 black=color(.04,.05,.05),white=color(1,1,.97),blue=color(.03,.07,.38),teal=color(0,.37,.36),muted=color(.3,.32,.32)}
local P=C.colors;local R=U.Renderer
local function tr(k,...) return getText('UI_B47PC_'..k,...) end
local function rect(w,x,y,a,b,c) R.rect(w,x,y,a,b,c) end
local function bevel(w,x,y,a,b,down)
 rect(w,x,y,a,2,down and P.shadow or P.light);rect(w,x,y,2,b,down and P.shadow or P.light)
 rect(w,x,y+b-2,a,2,down and P.light or P.shadow);rect(w,x+a-2,y,2,b,down and P.light or P.shadow)
end
local function text(w,s,x,y,width,c) R.text(w,R.fit(s,width),x,y,c or P.black) end
function C.decorate(w,kind)
 w.backgroundColor=U.Theme.copy(kind=='input' and P.white or P.grey)
 w.backgroundColorMouseOver=U.Theme.copy(P.light);w.borderColor=U.Theme.copy(P.shadow)
 w.textColor=U.Theme.copy(P.black);w.textColorDisabled=U.Theme.copy(P.muted)
 -- Native text entries paint their glyphs in UITextBox2, not Lua textColor.
 if kind=='input' and w.setTextRGBA then w:setTextRGBA(P.black.r,P.black.g,P.black.b,1) end
 if kind=='list' then w.selectionColor=U.Theme.copy(P.blue) end
 return w
end
local function button(owner,label,fn)
 local b=ISButton:new(0,0,120,U.Theme.metrics().button,label,owner,fn)
 b:initialise();b:instantiate();owner:addChild(b);C.decorate(b,'button');b.font=U.Theme.fonts.body
 b.prerender=function(self)
  rect(self,0,0,self:getWidth(),self:getHeight(),self.mouseOver and P.light or P.grey)
  bevel(self,0,0,self:getWidth(),self:getHeight(),self.pressed or self.osActive)
 end
 -- Use native input/controller handling, with original, clipped OS captions.
 b.render=function(self)
  if self.osIcon then
   local scale=U.Theme.metrics().button>=40 and 2 or 1;local size=16*scale
   Art.miniIcon(self,self.osIcon,6,math.floor((self:getHeight()-size)/2),scale)
   text(self,self.title,12+size,math.floor((self:getHeight()-U.Theme.metrics().font)/2),self:getWidth()-18-size)
   R.focus(self);return
  end
  local full=self.title or '';local caption=R.fit(full,self:getWidth()-12)
  self:drawTextCentre(caption,self:getWidth()/2,(self:getHeight()-U.Theme.metrics().font)/2,
   self.enable==false and P.muted.r or P.black.r,self.enable==false and P.muted.g or P.black.g,
   self.enable==false and P.muted.b or P.black.b,1,U.Theme.fonts.body)
  U.Renderer.focus(self)
 end
 b.tooltip=label
 local update=b.update
 b.update=function(self,...)
  if self.isReallyVisible and not self:isReallyVisible() then U.Tooltip.hide(self);return end
  if update then update(self,...) end
  if self.updateTooltip then self:updateTooltip() end
  if self.tooltipUI and self.tooltipUI.getIsVisible and self.tooltipUI:getIsVisible() then U.Tooltip.prepare(self.tooltipUI,self.tooltip,owner.playerNum) end
 end
 U.Tooltip.attach(b,owner.playerNum);return b
end
local function box(owner,x,y,w,h)
 local p=ISPanelJoypad:new(x,y,w,h);p.playerNum=owner.playerNum;p:initialise();p:instantiate();owner:addChild(p);return p
end
local function initFocus(p)
 p.joypadButtonsY={};p.joypadButtons={};p.allJoypadButtons={};p.joypadIndexY=1;p.joypadIndex=1
end
function C.keyboard(panel,back)
 panel:setWantKeyEvents(true)
 panel.isKeyConsumed=function(self,key)
  local host=C.active[self.playerNum]
  if host and host~=self and host.menuOpen then return false end
  return not self.closed and self:isVisible() and self.playerNum==0 and key==Keyboard.KEY_ESCAPE
 end
 panel.onKeyRelease=function(self,key) if self:isKeyConsumed(key) then back() end end
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
function C.open(num,computer,hooks)
 if not Media.enabled() or not hooks.enabled() then return end
 local actor=getSpecificPlayer(num);if not actor or not Media.computer(actor,computer,true) or not hooks.canUse(actor,computer,true) then return end
 local current=C.active[num];if current and not current.closed then if current.computer==computer and current.application==hooks.id then setJoypadFocus(num,current);return current end;current:close() end
 local m=U.Theme.metrics();local minW=math.max(840,m.font*28+172)
 -- Reserve hosted table/tool content plus the fixed CRT chrome.
 local minH=math.max(math.max(180+8*m.button,160+5*m.font+5*m.button)+260,6*m.font+5*m.button+429)+math.max(0,m.font-28)
 if getPlayerScreenWidth(num)<minW+20 or getPlayerScreenHeight(num)<minH+20 then actor:setHaloNote(tr('ScreenSmall'));return end
 local screen=ISCollapsableWindowJoypad:new(0,0,math.max(minW,math.min(920,getPlayerScreenWidth(num)-20)),math.max(minH,math.min(800,getPlayerScreenHeight(num)-20)))
 screen.application=hooks.id;screen.playerNum=num;screen.computer=computer;screen.minimumWidth=minW;screen.minimumHeight=minH;screen.resizable=true;screen.pin=true
 screen.drawFrame=false;screen.clearStentil=false;screen.title='Windows \'93';screen.titleBarHeight=function() return 32 end
 screen:initialise();screen:instantiate();C.active[num]=screen;initFocus(screen)
 screen.apps={};screen.taskOrder={};screen.appSerial=0
 local desktop=box(screen,18,34,screen:getWidth()-36,screen:getHeight()-100)
 local frame=box(desktop,12,12,desktop:getWidth()-24,desktop:getHeight()-24);frame:setVisible(false)
 local menu=box(desktop,4,4,math.max(230,m.font*15),4*m.button+16);menu:setVisible(false)
 local status=''
 local driveAt=-10000;local drivePending=false;local available={};local driveReady=false;screen.drivePending=false;screen.driveReady=false
 local function media(row)
  return {token=row.token,drive=row.drive,getID=function() return row.id end,getDisplayName=function() return row.name end,getFullType=function() return row.fullType end}
 end
 function screen:applyDrive(result)
  local old=self.mounted;local current=result.mounted and media(result.mounted)
  if old and (not current or old.drive~=current.drive or old:getID()~=current:getID()) then self:closeApp('ledger');status=tr('ComputerMediaLost') end
  self.mounted=current;self.slot=result.slot or current and current.drive;self.occupied=result.occupied==true;available={}
  for _,row in ipairs(result.choices or {}) do available[#available+1]=media(row) end
 end
 function screen:refreshDrive()
  if hooks.hasDrive==false or drivePending or getTimestampMs()-driveAt<2000 then return end
  drivePending=true;self.drivePending=true;driveAt=getTimestampMs()
  hooks.drive('list',{},function(r)
   if self.closed or getSpecificPlayer(num)~=actor then return end
   drivePending=false;driveReady=r.status=='ok';self.drivePending=false;self.driveReady=driveReady
   if driveReady then self:applyDrive(r) else self.mounted=nil;self:closeApp('ledger');status=hooks.text(r.status) end
  end)
 end
 function screen:message(key) status=hooks.text(key) end
 function screen:refreshFocus()
  initFocus(self);self.menuOpen=menu:isVisible();self.start.osActive=self.menuOpen
  if menu:isVisible() then
   self:insertNewLineOfButtons(self.start);self:insertNewLineOfButtons(menu.drive);self:insertNewLineOfButtons(menu.writer);self:insertNewLineOfButtons(menu.off)
  else
   if frame:isVisible() then self:insertNewLineOfButtons(frame.minimize,frame.exit)
   else self:insertNewLineOfButtons(self.driveIcon,self.writerIcon) end
   local bar={self.start,self.showDesktop};for _,key in ipairs(self.taskOrder) do bar[#bar+1]=self.apps[key].task end
   self:insertNewLineOfButtons(unpack(bar))
  end
  self:insertNewLineOfButtons(self.power)
  local rows={};self.allJoypadButtons={}
  for _,row in ipairs(self.joypadButtonsY) do local visible={};for _,w in ipairs(row) do if w:isVisible() then visible[#visible+1]=w;self.allJoypadButtons[#self.allJoypadButtons+1]=w end end;if #visible>0 then rows[#rows+1]=visible end end
  self.joypadButtonsY=rows
 end
 function screen:activateApp(key,resume)
  local app=self.apps[key];if self.closed or not app then return end
  local changed=self.activeKey~=key or app.minimized
  self.desktopRestore=nil;menu:setVisible(false);app.minimized=false
  self.appSerial=self.appSerial+1;app.order=self.appSerial
  self.activeKey=key;self.content=app.content;self.appTitle=app.title
  for name,entry in pairs(self.apps) do if name~=key then U.Tooltip.dispose(entry.content) end;entry.content:setVisible(name==key);entry.task.osActive=name==key end
  frame:setVisible(true);frame:bringToTop();self:layoutComputer();self:refreshFocus()
  if changed and resume~=false and app.content.onComputerResume then app.content:onComputerResume() end
  if self.apps[key]==app then setJoypadFocus(num,app.content) end
  return app.content
 end
 function screen:nextApp()
  local best
  for key,app in pairs(self.apps) do if not app.minimized and (not best or app.order>self.apps[best].order) then best=key end end
  if best then return self:activateApp(best) end
  self.activeKey=nil;self.content=nil;self.appTitle=nil;frame:setVisible(false)
  self:layoutComputer();self:refreshFocus();if not self.closed then setJoypadFocus(num,self) end
 end
 function screen:minimizeApp(key)
  local app=self.apps[key or self.activeKey];if not app then return end
  app.minimized=true;U.Tooltip.dispose(app.content);app.content:setVisible(false);app.task.osActive=false
  if self.activeKey==app.key then self.activeKey=nil;self.content=nil;self:nextApp() end
 end
 function screen:release(content)
  local app
  for _,entry in pairs(self.apps) do if entry.content==content then app=entry;break end end
  if not app then return end
  frame:removeChild(content);U.Tooltip.dispose(app.task);self:removeChild(app.task);self.apps[app.key]=nil
  for i,key in ipairs(self.taskOrder) do if key==app.key then table.remove(self.taskOrder,i);break end end
  if self.activeKey==app.key then self.activeKey=nil;self.content=nil end
  if not self.closed then self:nextApp() end
 end
 function screen:closeApp(key)
  local app=self.apps[key or self.activeKey];if not app then return end
  local ok,err=pcall(function() if app.content.close then app.content:close() else self:release(app.content) end end)
  if self.apps[app.key]==app then self:release(app.content) end
  if not ok then error(err) end
 end
 function screen:showApp(content,title,key)
  key=key or 'ledger'
  if self.closed or (key~='drive' and key~='writer' and key~='ledger') then return end
  if self.apps[key] then self:closeApp(key) end
  local app={key=key,title=title,content=content,minimized=false};self.apps[key]=app;self.taskOrder[#self.taskOrder+1]=key
  app.task=button(self,title,function()
   if self.closed or self.apps[key]~=app then return end
   menu:setVisible(false)
   if self.activeKey==key then self:minimizeApp(key) else self:activateApp(key) end
  end)
  app.task.osIcon=key;frame:addChild(content)
  if key=='ledger' and self.mounted then app.mediaID=self.mounted:getID();app.mediaDrive=self.mounted.drive end
  self:activateApp(key,false);return content
 end
 function screen:desktop()
  if self.closed then return end
  local restore={active=self.activeKey,keys={}}
  for key,app in pairs(self.apps) do
   if not app.minimized then restore.keys[#restore.keys+1]=key end
   app.minimized=true;U.Tooltip.dispose(app.content);app.content:setVisible(false);app.task.osActive=false
  end
  self.desktopRestore=restore;self.activeKey=nil;self.content=nil;frame:setVisible(false);menu:setVisible(false)
  self:layoutComputer();self:refreshFocus();setJoypadFocus(num,self)
 end
 function screen:toggleDesktop()
  if self.activeKey then return self:desktop() end
  local restore=self.desktopRestore;if not restore then return end;self.desktopRestore=nil
  for _,key in ipairs(restore.keys) do if self.apps[key] then self.apps[key].minimized=false end end
  if self.apps[restore.active] then self:activateApp(restore.active) else self:nextApp() end
 end
 function screen:close()
  if self.closed then return end;self.closed=true
  local keys={};for _,key in ipairs(self.taskOrder) do keys[#keys+1]=key end
  local issue
  for _,key in ipairs(keys) do local ok,err=pcall(self.closeApp,self,key);if not ok then issue=issue or err end end
  C.active[num]=nil;self.mounted=nil;self.content=nil;self.desktopRestore=nil
  U.Tooltip.dispose(self);self:removeFromUIManager();local ok,err=pcall(hooks.close);U.Focus.restore(num)
  if issue then error(issue) end;if not ok then error(err) end
 end
 function screen:eject()
  if self.closed then return end
  hooks.drive('eject',{drive=self.slot},function(r)
   if self.closed then return end
   if r.status=='ok' then self:closeApp('ledger');self.mounted=nil;self.occupied=false;status=tr('ComputerEjected');driveAt=-10000;self:openDrive() else status=hooks.text(r.status) end
  end)
 end
 function screen:runDisc()
  if self.closed or C.active[num]~=self then return end
  if hooks.busy() then status=tr('busy');return end
  local disc=self.mounted
  if not disc or not driveReady or drivePending or not disc.drive or not hooks.canRun(disc) then status=tr('ComputerNoApplication');return end
  if not Media.computer(actor,computer,true) or not hooks.canUse(actor,computer,true) then self:close();return end
  local app=self.apps.ledger
  if app and app.mediaID==disc:getID() and app.mediaDrive==disc.drive then return self:activateApp('ledger') end
  hooks.read(disc,self)
 end
 local function view(title,key)
  local v=ISPanelJoypad:new(0,0,frame:getWidth()-8,frame:getHeight()-m.button-12);v.playerNum=num;v:initialise();v:instantiate();initFocus(v)
  v.close=function(self) if self.closed then return end;self.closed=true;U.Tooltip.dispose(self);screen:release(self) end
  C.keyboard(v,function() v:close() end)
  v.onJoypadDown=function(self,pressed) if pressed==Joypad.BButton then screen:minimizeApp(key);setJoypadFocus(num,screen) else ISPanelJoypad.onJoypadDown(self,pressed) end end
  screen:showApp(v,title,key);return v
 end
 function screen:openDrive()
  self:refreshDrive();if self.apps.drive then return self:activateApp('drive') end
  local v=view(tr('ComputerDrive'),'drive');v.media=choice(v)
  v.insert=button(v,tr('ComputerInsert'),function()
   if v.closed or hooks.busy() then return end
   local disc=picked(v.media);if not disc or not disc.token or drivePending then return end
   hooks.drive('mount',{token=disc.token},function(r)
    if screen.closed then return end
    if r.status=='ok' then screen:applyDrive(r);status=tr('ComputerInserted',disc:getDisplayName());driveAt=-10000 else status=hooks.text(r.status);driveAt=-10000 end
   end)
  end)
  v.run=button(v,tr('ComputerRun'),function() screen:runDisc() end)
  v.eject=button(v,tr('ComputerEject'),function() screen:eject() end)
  v.file=button(v,hooks.file or tr('ComputerNoApplication'),function() status=tr('ComputerRunHint') end)
  v.file.onMouseDoubleClick=function() if not v.closed then screen:runDisc() end;return true end
  v.file.render=function(self)
   local scale=m.button>=40 and 2 or 1;local size=32*scale
   Art.icon(self,'application',12,math.floor((self:getHeight()-size)/2),scale)
   text(self,self.title,24+size,math.floor((self:getHeight()-m.font)/2),self:getWidth()-36-size)
   R.focus(self)
  end
  v.prerender=function(self)
   screen:refreshDrive()
   options(self.media,available,'ComputerNoCD');local w,h=self:getWidth(),self:getHeight()
   U.Layout.place(self.media,12,12,w-24,m.button);U.Layout.place(self.insert,12,20+m.button,w-24,m.button)
   local runnable=driveReady and screen.mounted and hooks.canRun(screen.mounted)
   if self.runnable~=(runnable==true) then
    self.runnable=runnable==true;initFocus(self)
    self:insertNewLineOfButtons(self.media);self:insertNewLineOfButtons(self.insert)
    if self.runnable then self:insertNewLineOfButtons(self.file) end
    self:insertNewLineOfButtons(self.run,self.eject)
   end
   U.Layout.place(self.file,12,40+2*m.button,w-24,2*m.button);self.file:setVisible(runnable==true)
   U.Layout.place(self.run,12,h-m.button-12,(w-36)/2,m.button);U.Layout.place(self.eject,24+(w-36)/2,h-m.button-12,(w-36)/2,m.button)
   self.run:setEnable(runnable==true and not hooks.busy() and not drivePending);self.eject:setEnable(screen.mounted~=nil or screen.occupied);self.insert:setEnable(driveReady and not drivePending and not screen.mounted and not screen.occupied and not hooks.busy() and picked(self.media)~=false and picked(self.media)~=nil)
   if not runnable then text(self,screen.mounted and tr('ComputerBlankCD') or tr('ComputerInsertHint'),12,40+2*m.button,w-24) end
  end
  v:prerender();self:refreshFocus();return v
 end
 function screen:view(title,key) return view(title,key or 'writer') end
 function screen:openWriter()
  if not hooks.writer then return end
  self:refreshDrive();if self.apps.writer then return self:activateApp('writer') end
  return hooks.writer(self,hooks)
 end
 function screen:openProgram()
  if self.closed or C.active[num]~=self or getSpecificPlayer(num)~=actor then return end
  if not Media.computer(actor,computer,true) or not hooks.enabled() or not hooks.canUse(actor,computer,true) then self:close();return end
  if hooks.busy() then status=tr('busy');return end
  if hooks.launch then return hooks.launch(self) end
  return self:openWriter()
 end
 screen.driveIcon=button(desktop,tr('ComputerDrive'),function() screen:openDrive() end)
 screen.writerIcon=button(desktop,hooks.programTitle or hooks.toolTitle or tr('ComputerApplications'),function() screen:openProgram() end)
 for _,entry in ipairs({{screen.driveIcon,'disc'},{screen.writerIcon,'writer'}}) do
  local b,kind=entry[1],entry[2]
  b.prerender=function(self) if self.mouseOver or self.joypadFocused then R.border(self,0,0,self:getWidth(),self:getHeight(),P.light) end end
  b.render=function(self)
   if kind=='writer' and hooks.icon then Assets.drawIcon(self,hooks.icon,math.floor((self:getWidth()-64)/2),8,64)
   else Art.icon(self,kind,math.floor((self:getWidth()-64)/2),8,2) end
   local caption=R.fit(self.title,self:getWidth()-12);local x=math.floor((self:getWidth()-getTextManager():MeasureStringX(U.Theme.fonts.body,caption))/2)
   text(self,caption,x+1,81,self:getWidth()-12,P.black);text(self,caption,x,80,self:getWidth()-12,P.white);R.focus(self)
  end
 end
 screen.start=button(screen,tr('ComputerStart'),function() menu:setVisible(not menu:isVisible());if menu:isVisible() then menu:bringToTop() end;screen:refreshFocus();setJoypadFocus(num,screen) end)
 screen.showDesktop=button(screen,tr('ComputerShowDesktop'),function() screen:toggleDesktop() end)
 screen.showDesktop.osIcon='desktop'
 screen.showDesktop.render=function(self)
  local scale=m.button>=40 and 2 or 1;Art.miniIcon(self,'desktop',math.floor((self:getWidth()-16*scale)/2),math.floor((self:getHeight()-16*scale)/2),scale);R.focus(self)
 end
 screen.power=button(screen,tr('ComputerPowerOff'),function() screen:close() end)
 screen.power.tooltip=tr('ComputerPowerOff');screen.power.prerender=Art.power;screen.power.render=function(self) R.focus(self) end
 frame.minimize=button(frame,'_',function() screen:minimizeApp() end);frame.exit=button(frame,'X',function() screen:closeApp() end)
 menu.drive=button(menu,tr('ComputerDrive'),function() screen:openDrive() end)
 menu.writer=button(menu,hooks.programTitle or hooks.toolTitle or tr('ComputerApplications'),function() screen:openProgram() end)
 menu.off=button(menu,tr('ComputerPowerOff'),function() screen:close() end)
 screen.writerIcon:setVisible(hooks.writer~=nil or hooks.launch~=nil);menu.writer:setVisible(hooks.writer~=nil or hooks.launch~=nil)
 screen.driveIcon:setVisible(hooks.hasDrive~=false);menu.drive:setVisible(hooks.hasDrive~=false)
 function screen:layoutComputer()
  local w,h=self:getWidth(),self:getHeight()
  if not self.crt or self.crt.windowWidth~=w or self.crt.windowHeight~=h then
   self.crt=Art.geometry(w,h,m.font,m.button);self.crt.windowWidth=w;self.crt.windowHeight=h
  end
  local g=self.crt
  U.Layout.place(desktop,g.x,g.y,g.width,g.desktopHeight)
  local dw,dh=desktop:getWidth(),desktop:getHeight();U.Layout.place(frame,10,10,dw-20,dh-20)
  U.Layout.place(frame.minimize,frame:getWidth()-2*m.button-8,4,m.button,m.button);U.Layout.place(frame.exit,frame:getWidth()-m.button-4,4,m.button,m.button)
  if self.content then U.Layout.place(self.content,4,m.button+8,frame:getWidth()-8,frame:getHeight()-m.button-12) end
  U.Layout.place(self.driveIcon,12,14,math.max(180,m.font*12),m.font+96);U.Layout.place(self.writerIcon,12,hooks.hasDrive==false and 14 or m.font+126,math.max(180,m.font*12),m.font+96)
  U.Layout.place(self.start,g.x+4,g.taskY,math.max(90,m.font*5),m.button)
  U.Layout.place(self.showDesktop,self.start.x+self.start:getWidth()+8,g.taskY,m.button,m.button)
  self.showDesktop:setEnable(#self.taskOrder>0);self.showDesktop.osActive=not self.activeKey and self.desktopRestore~=nil
  local left=self.showDesktop.x+m.button+10;local count=#self.taskOrder
  local taskWidth=math.min(math.max(170,m.font*10),math.floor((g.x+g.width-8-left)/math.max(1,count))-4)
  for i,key in ipairs(self.taskOrder) do U.Layout.place(self.apps[key].task,left+(i-1)*(taskWidth+4),g.taskY,taskWidth,m.button) end
  U.Layout.place(self.power,g.powerX,g.powerY,36,34)
  U.Layout.place(menu,4,dh-menu:getHeight()-4,menu:getWidth(),menu:getHeight())
  for i,b in ipairs({menu.drive,menu.writer,menu.off}) do U.Layout.place(b,8,8+(i-1)*(m.button+4),menu:getWidth()-16,m.button) end
  for _,key in ipairs({'closeButton','pinButton','collapseButton','infoButton'}) do if self[key] then self[key]:setVisible(false) end end
 end
 desktop.prerender=Art.desktop
 frame.prerender=function(self)
  rect(self,0,0,self:getWidth(),self:getHeight(),P.grey);bevel(self,0,0,self:getWidth(),self:getHeight())
  rect(self,4,4,self:getWidth()-8,m.button,P.blue);text(self,screen.appTitle or '',10,7,self:getWidth()-2*m.button-26,P.white)
 end
 menu.prerender=function(self) rect(self,0,0,self:getWidth(),self:getHeight(),P.grey);bevel(self,0,0,self:getWidth(),self:getHeight()) end
 screen.prerender=function(self)
  if not Media.enabled() or not hooks.enabled() then self:close();return end
  if getSpecificPlayer(num)~=actor or actor:isDead() or not Media.computer(actor,computer,true) or not hooks.canUse(actor,computer,true) then self:close();return end
  if driveReady then self:refreshDrive() end
  self:layoutComputer();local w,h=self:getWidth(),self:getHeight()
  local g=self.crt;Art.monitor(self,g)
  Art.glass(self,g)
  rect(self,g.x,g.taskY-4,g.width,m.button+8,P.grey)
  rect(self,g.x,g.taskY-4,g.width,2,P.light)
  text(self,status,g.x+6,g.statusY,g.width-12,P.white)
  if self.content and self.content.updateComputer then self.content:updateComputer() end
 end
 screen.render=function(self) if self.resizeWidget then bevel(self,self:getWidth()-24,self:getHeight()-38,10,10) end end
 screen.onJoypadDown=function(self,key) if key==Joypad.BButton then if menu:isVisible() then menu:setVisible(false);self:refreshFocus() elseif frame:isVisible() then self:minimizeApp();setJoypadFocus(num,self) else self:close() end else ISPanelJoypad.onJoypadDown(self,key) end end
 C.keyboard(screen,function() if menu:isVisible() then menu:setVisible(false);screen:refreshFocus() elseif screen.content then screen:closeApp() else screen:onJoypadDown(Joypad.BButton) end end)
 U.bounds(screen,num);screen:addToUIManager();screen:layoutComputer();screen:refreshFocus();setJoypadFocus(num,screen)
 return screen
end
C.button=button;C.choice=choice;C.picked=picked;C.options=options;C.text=text
return C
