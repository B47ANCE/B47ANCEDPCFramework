-- Lua-drawn desktop. Server-returned media proxies never authorize gameplay.
require 'B47ANCEDPCUI/Controls'
require 'ISUI/ISComboBox'
local U=B47ANCEDPCUI
local Media=require 'B47ANCEDPCFramework/Device'
local C={active={}};B47ANCEDPCFramework.ComputerUI=C
local UI=require 'B47ANCEDPCFramework/UI'
local Assets=require 'B47ANCEDPCFramework/Assets'
C.colors=Assets.palette()
local P=C.colors;local R=U.Renderer
local function tr(k,...) return getText('UI_B47PC_'..k,...) end
local function rect(w,x,y,a,b,c) R.rect(w,x,y,a,b,c) end
local bevel=Assets.bevel
local function text(w,s,x,y,width,c) R.text(w,R.fit(s,width),x,y,c or P.black) end
C.decorate=UI.style
local function button(owner,label,fn)
 return UI.button(owner,{text=label,onClick=function(control) return fn(owner,control) end})
end
local function icon(w,kind,x,y) Assets.drawIcon(w,kind,x,y,40) end
local function box(owner,x,y,w,h)
 local p=ISPanelJoypad:new(x,y,w,h);p.playerNum=owner.playerNum;p:initialise();p:instantiate();owner:addChild(p);return p
end
local function initFocus(p)
 p.joypadButtonsY={};p.joypadButtons={};p.allJoypadButtons={};p.joypadIndexY=1;p.joypadIndex=1
end
function C.keyboard(panel,back)
 panel:setWantKeyEvents(true)
 panel.isKeyConsumed=function(self,key) return self.playerNum==0 and key==Keyboard.KEY_ESCAPE end
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
 local m=U.Theme.metrics();local minW=math.max(700,m.font*28);local minH=math.max(180+8*m.button,160+5*m.font+5*m.button)
 if getPlayerScreenWidth(num)<minW+20 or getPlayerScreenHeight(num)<minH+20 then actor:setHaloNote(tr('ScreenSmall'));return end
 local screen=ISCollapsableWindowJoypad:new(0,0,math.min(1120,getPlayerScreenWidth(num)-20),math.min(780,getPlayerScreenHeight(num)-20))
 screen.application=hooks.id;screen.playerNum=num;screen.computer=computer;screen.minimumWidth=minW;screen.minimumHeight=minH;screen.resizable=true;screen.pin=true
 screen.drawFrame=false;screen.clearStentil=false;screen.title='Windows \'93';screen.titleBarHeight=function() return m.font+20 end
 screen:initialise();screen:instantiate();C.active[num]=screen;initFocus(screen)
 local desktop=box(screen,18,34,screen:getWidth()-36,screen:getHeight()-100)
 local frame=box(desktop,12,12,desktop:getWidth()-24,desktop:getHeight()-24);frame:setVisible(false)
 local menu=box(desktop,4,4,math.max(230,m.font*15),4*m.button+16);menu:setVisible(false)
 local status=''
 local driveAt=-10000;local available={};screen.drivePending=false;screen.driveReady=false
 local function media(row)
  return {token=row.token,drive=row.drive,getID=function() return row.id end,getDisplayName=function() return row.name end,getFullType=function() return row.fullType end}
 end
 function screen:applyDrive(result)
  local old=self.mounted;local current=result.mounted and media(result.mounted)
  if old and (not current or old.drive~=current.drive or old:getID()~=current:getID()) then self:closeApp();status=tr('ComputerMediaLost') end
  self.mounted=current;self.slot=result.slot or current and current.drive;self.occupied=result.occupied==true;available={}
  for _,row in ipairs(result.choices or {}) do available[#available+1]=media(row) end
 end
 function screen:refreshDrive()
  if hooks.hasDrive==false or screen.drivePending or getTimestampMs()-driveAt<2000 then return end
  screen.drivePending=true;driveAt=getTimestampMs()
  hooks.drive('list',{},function(r)
   if self.closed or getSpecificPlayer(num)~=actor then return end
   screen.drivePending=false;screen.driveReady=r.status=='ok'
   if screen.driveReady then self:applyDrive(r) else self.mounted=nil;self:closeApp();status=hooks.text(r.status) end
  end)
 end
 function screen:message(key) status=hooks.text(key) end
 function screen:refreshFocus()
  initFocus(self)
  if menu:isVisible() then self:insertNewLineOfButtons(self.start);self:insertNewLineOfButtons(menu.drive);self:insertNewLineOfButtons(menu.writer);self:insertNewLineOfButtons(menu.off)
  elseif frame:isVisible() then self:insertNewLineOfButtons(frame.minimize,frame.exit);self:insertNewLineOfButtons(self.start,self.task,self.off)
  else self:insertNewLineOfButtons(self.driveIcon,self.writerIcon);self:insertNewLineOfButtons(self.start,self.task,self.off) end
  local rows={}
  for _,row in ipairs(self.joypadButtonsY) do
   local visible={};for _,control in ipairs(row) do if control:isVisible() then visible[#visible+1]=control end end
   if #visible>0 then rows[#rows+1]=visible end
  end
  self.joypadButtonsY=rows
 end
 function screen:release(content)
  frame:removeChild(content)
  if self.content==content then self.content=nil;frame:setVisible(false);self.task.title=tr('ComputerDesktop') end
  self:refreshFocus();if not self.closed then setJoypadFocus(num,self) end
 end
 function screen:closeApp()
  local content=self.content
  if content then
   local ok,err=pcall(function() if content.close then content:close() else self:release(content) end end)
   if self.content==content then self:release(content) end
   if not ok then error(err) end
  end
 end
 function screen:showApp(content,title)
  self:closeApp();menu:setVisible(false);self.content=content;self.appTitle=title;self.task.title=title
  frame:addChild(content);frame:setVisible(true);frame:bringToTop();self:layoutComputer();self:refreshFocus();setJoypadFocus(num,content)
 end
 function screen:desktop()
  frame:setVisible(false);menu:setVisible(false);self:refreshFocus();setJoypadFocus(num,self)
 end
 function screen:close()
  if self.closed then return end;self.closed=true
  local ok,err=pcall(self.closeApp,self);C.active[num]=nil;self.mounted=nil
  U.Tooltip.dispose(self);self:removeFromUIManager()
  local done,issue=pcall(hooks.close);U.Focus.restore(num)
  if not ok then error(err) end;if not done then error(issue) end
 end
 function screen:eject()
  hooks.drive('eject',{drive=self.slot},function(r)
   if self.closed then return end
   if r.status=='ok' then self:closeApp();self.mounted=nil;self.occupied=false;status=tr('ComputerEjected');driveAt=-10000;self:openDrive() else status=hooks.text(r.status) end
  end)
 end
 function screen:runDisc()
  if self.closed or C.active[num]~=self then return end
  if hooks.busy() then status=tr('busy');return end
  local disc=self.mounted
  if not disc or not screen.driveReady or screen.drivePending or not disc.drive or not hooks.canRun(disc) then status=tr('ComputerNoApplication');return end
  if not Media.computer(actor,computer,true) or not hooks.canUse(actor,computer,true) then self:close();return end
  hooks.read(disc,self)
 end
 local function view(title)
  local v=ISPanelJoypad:new(0,0,frame:getWidth()-8,frame:getHeight()-m.button-12);v.playerNum=num;v:initialise();v:instantiate();initFocus(v)
  v.close=function(self) U.Tooltip.dispose(self);screen:release(self) end
  C.keyboard(v,function() v:close() end)
  v.onJoypadDown=function(self,key) if key==Joypad.BButton then self:close() else ISPanelJoypad.onJoypadDown(self,key) end end
  screen:showApp(v,title);return v
 end
 function screen:openDrive()
  self:refreshDrive();local v=view(tr('ComputerDrive'));v.media=choice(v)
  v.insert=button(v,tr('ComputerInsert'),function()
   if hooks.busy() then return end
   local disc=picked(v.media);if not disc or not disc.token or screen.drivePending then return end
   hooks.drive('mount',{token=disc.token},function(r)
    if screen.closed then return end
    if r.status=='ok' then screen:closeApp();screen:applyDrive(r);status=tr('ComputerInserted',disc:getDisplayName());driveAt=-10000;screen:openDrive() else status=hooks.text(r.status);driveAt=-10000 end
   end)
  end)
  v.run=button(v,tr('ComputerRun'),function() screen:runDisc() end)
  v.eject=button(v,tr('ComputerEject'),function() screen:eject() end)
  v.file=button(v,hooks.file or tr('ComputerNoApplication'),function() status=tr('ComputerRunHint') end)
  v.file.onMouseDoubleClick=function() screen:runDisc();return true end
  v.prerender=function(self)
   screen:refreshDrive()
   options(self.media,available,'ComputerNoCD');local w,h=self:getWidth(),self:getHeight()
   U.Layout.place(self.media,12,12,w-24,m.button);U.Layout.place(self.insert,12,20+m.button,w-24,m.button)
   local runnable=screen.driveReady and screen.mounted and hooks.canRun(screen.mounted)
   U.Layout.place(self.file,12,40+2*m.button,w-24,2*m.button);self.file:setVisible(runnable==true)
   U.Layout.place(self.run,12,h-m.button-12,(w-36)/2,m.button);U.Layout.place(self.eject,24+(w-36)/2,h-m.button-12,(w-36)/2,m.button)
   self.run:setEnable(runnable==true and not hooks.busy() and not screen.drivePending);self.eject:setEnable(screen.mounted~=nil or screen.occupied);self.insert:setEnable(screen.driveReady and not screen.drivePending and not screen.mounted and not screen.occupied and not hooks.busy() and picked(self.media)~=false and picked(self.media)~=nil)
   if not runnable then text(self,screen.mounted and tr('ComputerBlankCD') or tr('ComputerInsertHint'),12,40+2*m.button,w-24) end
  end
  v:insertNewLineOfButtons(v.media);v:insertNewLineOfButtons(v.insert)
  if screen.mounted and hooks.canRun(screen.mounted) then v:insertNewLineOfButtons(v.file) end
  v:insertNewLineOfButtons(v.run,v.eject)
  v:prerender();self:refreshFocus();return v
 end
 function screen:view(title) return view(title) end
 function screen:openWriter() if hooks.writer then return hooks.writer(self,hooks) end end
 function screen:openProgram()
  if self.closed or C.active[num]~=self or getSpecificPlayer(num)~=actor then return end
  if not Media.computer(actor,computer,true) or not hooks.enabled() or not hooks.canUse(actor,computer,true) then self:close();return end
  if hooks.busy() then status=tr('busy');return end
  if hooks.launch then return hooks.launch(self) end
  return self:openWriter()
 end
 screen.driveIcon=button(desktop,tr('ComputerDrive'),function() screen:openDrive() end)
 screen.writerIcon=button(desktop,hooks.programTitle or hooks.toolTitle or tr('ComputerApplications'),function() screen:openProgram() end)
 for _,entry in ipairs({{screen.driveIcon,'disc'},{screen.writerIcon,hooks.icon or 'writer'}}) do
  local b,kind=entry[1],entry[2]
  b.prerender=function(self) if self.mouseOver or self.joypadFocused then R.border(self,0,0,self:getWidth(),self:getHeight(),P.light) end end
  b.render=function(self) icon(self,kind,math.floor((self:getWidth()-38)/2),8);text(self,self.title,4,48,self:getWidth()-8,P.white);R.focus(self) end
 end
 screen.start=button(screen,tr('ComputerStart'),function() menu:setVisible(not menu:isVisible());if menu:isVisible() then menu:bringToTop() end;screen:refreshFocus();setJoypadFocus(num,screen) end)
 screen.task=button(screen,tr('ComputerDesktop'),function() if screen.content then frame:setVisible(not frame:isVisible()) end;menu:setVisible(false);screen:refreshFocus();setJoypadFocus(num,frame:isVisible() and screen.content or screen) end)
 screen.off=button(screen,tr('ComputerPowerOff'),function() screen:close() end)
 frame.minimize=button(frame,'_',function() screen:desktop() end);frame.exit=button(frame,'X',function() screen:closeApp() end)
 menu.drive=button(menu,tr('ComputerDrive'),function() screen:openDrive() end)
 menu.writer=button(menu,hooks.programTitle or hooks.toolTitle or tr('ComputerApplications'),function() screen:openProgram() end)
 menu.off=button(menu,tr('ComputerPowerOff'),function() screen:close() end)
 screen.writerIcon:setVisible(hooks.writer~=nil or hooks.launch~=nil);menu.writer:setVisible(hooks.writer~=nil or hooks.launch~=nil)
 screen.driveIcon:setVisible(hooks.hasDrive~=false);menu.drive:setVisible(hooks.hasDrive~=false)
 function screen:layoutComputer()
  local w,h=self:getWidth(),self:getHeight();local top=m.font+20;local bottom=m.button+m.font+44
  U.Layout.place(desktop,18,top,w-36,h-top-bottom)
  local dw,dh=desktop:getWidth(),desktop:getHeight();U.Layout.place(frame,10,10,dw-20,dh-20)
  U.Layout.place(frame.minimize,frame:getWidth()-2*m.button-8,4,m.button,m.button);U.Layout.place(frame.exit,frame:getWidth()-m.button-4,4,m.button,m.button)
  if self.content then U.Layout.place(self.content,4,m.button+8,frame:getWidth()-8,frame:getHeight()-m.button-12) end
  U.Layout.place(self.driveIcon,12,14,math.max(180,m.font*12),m.font+64);U.Layout.place(self.writerIcon,12,hooks.hasDrive==false and 14 or m.font+94,math.max(180,m.font*12),m.font+64)
  local taskY=h-m.button-m.font-24
  U.Layout.place(self.start,18,taskY,math.max(90,m.font*5),m.button);U.Layout.place(self.off,w-math.max(180,m.font*11)-18,taskY,math.max(180,m.font*11),m.button)
  U.Layout.place(self.task,self.start.x+self.start:getWidth()+8,taskY,self.off.x-self.start.x-self.start:getWidth()-16,m.button)
  U.Layout.place(menu,4,dh-menu:getHeight()-4,menu:getWidth(),menu:getHeight())
  for i,b in ipairs({menu.drive,menu.writer,menu.off}) do U.Layout.place(b,8,8+(i-1)*(m.button+4),menu:getWidth()-16,m.button) end
  for _,key in ipairs({'closeButton','pinButton','collapseButton','infoButton'}) do if self[key] then self[key]:setVisible(false) end end
 end
 desktop.prerender=function(self) rect(self,0,0,self:getWidth(),self:getHeight(),P.teal) end
 frame.prerender=function(self)
  rect(self,0,0,self:getWidth(),self:getHeight(),P.grey);bevel(self,0,0,self:getWidth(),self:getHeight())
  rect(self,4,4,self:getWidth()-8,m.button,P.blue);text(self,screen.appTitle or '',10,7,self:getWidth()-2*m.button-26,P.white)
 end
 menu.prerender=function(self) rect(self,0,0,self:getWidth(),self:getHeight(),P.grey);bevel(self,0,0,self:getWidth(),self:getHeight()) end
 screen.prerender=function(self)
  if not Media.enabled() or not hooks.enabled() then self:close();return end
  if getSpecificPlayer(num)~=actor or actor:isDead() or not Media.computer(actor,computer,true) or not hooks.canUse(actor,computer,true) then self:close();return end
  if screen.driveReady then self:refreshDrive() end
  self:layoutComputer();local w,h=self:getWidth(),self:getHeight()
  rect(self,0,0,w,h,P.case);bevel(self,0,0,w,h);rect(self,10,m.font+12,w-20,desktop:getHeight()+16,P.black)
  text(self,"Windows '93",20,7,w-40,P.light);rect(self,18,self.start.y-4,w-36,m.button+8,P.grey)
  rect(self,w-35,h-20,6,6,P.teal);text(self,status,20,h-m.font-10,w-70,P.light)
  if self.content and self.content.updateComputer then self.content:updateComputer() end
 end
 screen.render=function(self) if self.resizeWidget then bevel(self,self:getWidth()-14,self:getHeight()-14,12,12) end end
 screen.onJoypadDown=function(self,key) if key==Joypad.BButton then if menu:isVisible() then menu:setVisible(false);self:refreshFocus() elseif frame:isVisible() then self:desktop() else self:close() end else ISPanelJoypad.onJoypadDown(self,key) end end
 C.keyboard(screen,function() if screen.content then screen:closeApp() else screen:onJoypadDown(Joypad.BButton) end end)
 U.bounds(screen,num);screen:addToUIManager();screen:layoutComputer();screen:refreshFocus();setJoypadFocus(num,screen)
 return screen
end
C.button=button;C.choice=choice;C.picked=picked;C.options=options;C.text=text
return C
