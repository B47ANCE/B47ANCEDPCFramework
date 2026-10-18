-- One local desktop per player/PC. App sessions keep independent callbacks,
-- media and content. Nothing in this window manager grants gameplay access.
local UI=require 'B47ANCEDPCFramework/UI'
local A=require 'B47ANCEDPCFramework/Assets'
local Device=require 'B47ANCEDPCFramework/Device'
local CRT=require 'B47ANCEDPCFramework/CRT'
local U=B47ANCEDPCUI;local D={}
local function tr(k,...) return getText('UI_B47PC_'..k,...) end
local function panel(parent)
 local p=ISPanelJoypad:new(0,0,1,1);p.playerNum=parent.playerNum;p:initialise();p:instantiate();parent:addChild(p);return p
end
local function attempt(state,fn)
 local ok,err=pcall(fn);if not ok and not state.error then state.error=err end
end
function D.new(C,num,computer)
 local m=UI.metrics();local actor=getSpecificPlayer(num)
 local minW,minH=math.max(700,m.font*28),math.max(680,m.font*19+400)
 if getPlayerScreenWidth(num)<minW+20 or getPlayerScreenHeight(num)<minH+20 then actor:setHaloNote(tr('ScreenSmall'));return end
 local root=ISCollapsableWindowJoypad:new(0,0,math.max(minW,math.min(920,getPlayerScreenWidth(num)-20)),math.max(minH,math.min(780,getPlayerScreenHeight(num)-20)))
 root.playerNum=num;root.minimumWidth=minW;root.minimumHeight=minH;root.resizable=true;root.pin=true;root.drawFrame=false;root.clearStentil=false;root.title="Windows '93"
 root.titleBarHeight=function() return math.max(24,root:getHeight()*.065) end
 root:initialise();root:instantiate()
 local d={root=root,sessions={},order={},entries={},icons={},menuButtons={},page=1,taskPage=1,playerNum=num,actor=actor,computer=computer,homeKey={}}
 root.b47Desktop=d;C.desktops[num]=d
 local desktop=panel(root);local menu=panel(desktop);menu:setVisible(false);d.surface=desktop;d.menu=menu
 desktop.prerender=function(self) A.panel(self,0,0,self:getWidth(),self:getHeight(),'teal') end
 menu.prerender=function(self) A.panel(self,0,0,self:getWidth(),self:getHeight(),'grey');A.bevel(self,0,0,self:getWidth(),self:getHeight()) end
 local function button(parent,text,fn) return UI.button(parent,{text=text,onClick=fn}) end
 d.start=button(root,tr('ComputerStart'),function()
  if d.closed then return end
  menu:setVisible(not menu:isVisible());if menu:isVisible() then menu:bringToTop() end;d:refreshFocus()
  setJoypadFocus(num,not menu:isVisible() and d.current and not d.current.minimized and d.current.content or root)
 end)
 d.homeButton=button(root,'',function() d:showDesktop() end)
 d.homeButton.render=function(self) A.drawIcon(self,'computer',5,5,18) end
 d.off=button(root,'',function() d:close() end);d.off.tooltip=tr('ComputerPowerOff')
 d.off.prerender=function(self) A.panel(self,0,0,self:getWidth(),self:getHeight(),'grey');A.bevel(self,0,0,self:getWidth(),self:getHeight(),self.pressed) end
 d.off.render=function(self)
  local x,y=self:getWidth()/2,self:getHeight()/2;A.panel(self,x-1,y-7,2,8,'shadow')
  A.panel(self,x-6,y-2,2,7,'shadow');A.panel(self,x+4,y-2,2,7,'shadow');A.panel(self,x-4,y+5,8,2,'shadow')
 end
 d.menuOff=button(menu,tr('ComputerPowerOff'),function() d:close() end)
 local function turn(delta) d.page=d.page+delta;d:layout();d:refreshFocus() end
 d.previous=button(desktop,tr('ComputerPreviousApps'),function() turn(-1) end)
 d.next=button(desktop,tr('ComputerNextApps'),function() turn(1) end)
 d.menuPrevious=button(menu,tr('ComputerPreviousApps'),function() turn(-1) end)
 d.menuNext=button(menu,tr('ComputerNextApps'),function() turn(1) end)
 d.taskPrevious=button(root,'<',function() d.taskPage=d.taskPage-1;d:layout();d:refreshFocus() end)
 d.taskNext=button(root,'>',function() d.taskPage=d.taskPage+1;d:layout();d:refreshFocus() end)
 d.taskPrevious.tooltip=tr('ComputerPreviousWindows');d.taskNext.tooltip=tr('ComputerNextWindows')
 function d:live(s) return not self.closed and not s.closed and self.sessions[s.sessionKey]==s end
 function d:activate(s)
  if not self:live(s) then return end
  self.current=s;self.focusTask=s;C.active[num]=s;menu:setVisible(false)
  if s.content then s.minimized=false;s.frame:setVisible(true);s.frame:bringToTop() end
  self:layout();self:refreshFocus();setJoypadFocus(num,s.content or root)
 end
 function d:showDesktop()
  for _,s in ipairs(self.order) do s.minimized=true;s.frame:setVisible(false) end
  menu:setVisible(false);self.current=self.home;C.active[num]=self.home;self:refreshFocus();setJoypadFocus(num,root)
 end
 function d:refreshFocus()
  local rows={{self.start,self.homeButton}}
  if menu:isVisible() then
   for _,b in ipairs(self.menuButtons) do rows[#rows+1]={b} end
   rows[#rows+1]={self.menuPrevious,self.menuNext};rows[#rows+1]={self.menuOff}
  elseif self.current and self.current.content and not self.current.minimized then
   rows[#rows+1]={self.current.frame.minimize,self.current.frame.exit}
  else
   local grouped,ys={},{}
   for _,b in ipairs(self.icons) do if b:isVisible() then if not grouped[b.y] then grouped[b.y]={};ys[#ys+1]=b.y end;grouped[b.y][#grouped[b.y]+1]=b end end
   table.sort(ys);for _,y in ipairs(ys) do table.sort(grouped[y],function(a,b) return a.x<b.x end);rows[#rows+1]=grouped[y] end
   rows[#rows+1]={self.previous,self.next}
  end
  local tasks={self.taskPrevious};for _,s in ipairs(self.order) do tasks[#tasks+1]=s.task end;tasks[#tasks+1]=self.taskNext
  rows[#rows+1]=tasks;rows[#rows+1]={self.off};UI.focus(root,rows)
 end
 function d:addSession(hooks)
  local s={application=hooks.id,sessionKey=hooks.sessionKey or hooks.id,playerNum=num,computer=computer,hooks=hooks,desktopHost=self,root=root,minimized=true,closed=false}
  -- Existing API-1 host geometry/input methods delegate to the single native root.
  setmetatable(s,{__index=function(_,key)
   local value=root[key];if type(value)=='function' then return function(_,...) return value(root,...) end end;return value
  end})
  self.sessions[s.sessionKey]=s;self.order[#self.order+1]=s
  local frame=panel(desktop);frame:setVisible(false);s.frame=frame
  s.task=button(root,'',function() if self.current==s and not s.minimized then s:desktop() else self:activate(s) end end);s.task:setVisible(false)
  s.task.render=function(w)
   A.drawIcon(w,hooks.icon or 'application',6,(w:getHeight()-16)/2,16)
   A.text(w,w.title or '',28,(w:getHeight()-UI.metrics().font)/2,w:getWidth()-34,'black')
  end
  s.start=self.start;s.off=self.off
  frame.minimize=button(frame,'_',function() s:desktop() end);frame.exit=button(frame,'X',function() s:closeApp() end)
  frame.prerender=function(w)
   A.panel(w,0,0,w:getWidth(),w:getHeight(),'grey');A.bevel(w,0,0,w:getWidth(),w:getHeight())
   A.panel(w,4,4,w:getWidth()-8,UI.metrics().button,'blue')
   A.text(w,s.appTitle or '',10,7,w:getWidth()-2*UI.metrics().button-26,'white')
  end
  function s:refreshFocus() self.desktopHost:refreshFocus() end
  function s:layoutComputer() self.desktopHost:layout() end
  function s:release(content)
   frame:removeChild(content)
   if self.content==content then self.content=nil;frame:setVisible(false);self.task:setVisible(false);self.task.title=tr('ComputerDesktop') end
   self:refreshFocus();if self.desktopHost.current==self and not self.closed and not self.desktopHost.closed then setJoypadFocus(num,root) end
  end
  function s:closeApp()
   local content=self.content;if not content then return end
   local ok,err=pcall(function() if content.close then content:close() else self:release(content) end end)
   if self.content==content then self:release(content) end
   if not ok then error(err) end
  end
  function s:showApp(content,title)
   local foreground=self.desktopHost.current==self
   self:closeApp();self.content=content;self.appTitle=title;self.task.title=title
   frame:addChild(content)
   if foreground then self.desktopHost:activate(self)
   else frame:setVisible(not self.minimized);self.desktopHost:layout();self:refreshFocus() end
  end
  function s:desktop() self.minimized=true;frame:setVisible(false);self.desktopHost:showDesktop() end
  function s:close() self.desktopHost:close() end
  function s:prerender() root:prerender() end
  function s:render() if root.render then root:render() end end
  function s:onJoypadDown(key) root:onJoypadDown(key) end
  -- Aliases used by API-1 consumers; the global catalog owns visible launchers.
  s.writerIcon=button(desktop,hooks.programTitle or hooks.toolTitle or tr('ComputerApplications'),function() s:openProgram() end)
  s.driveIcon=button(desktop,tr('ComputerDrive'),function() s:openDrive() end)
  s.writerIcon:setVisible(false);s.driveIcon:setVisible(false)
  return s
 end
 function d:retire(s)
  if s.closed then return end;s.closed=true;self.sessions[s.sessionKey]=nil;self.catalogAt=nil
  local state={};attempt(state,function() s:closeApp() end);attempt(state,s.hooks.close)
  desktop:removeChild(s.frame);root:removeChild(s.task);desktop:removeChild(s.writerIcon);desktop:removeChild(s.driveIcon)
  s.mounted=nil;s.removed=true
  for i,item in ipairs(self.order) do if item==s then table.remove(self.order,i);break end end
  if self.current==s then self.current=self.home;if not self.closed then C.active[num]=self.home;setJoypadFocus(num,root) end end
  if state.error then error(state.error) end
 end
 function d:close()
  if self.closed then return end;self.closed=true;root.closed=true;C.active[num]=nil;C.desktops[num]=nil
  local state={};local order={};for _,s in ipairs(self.order) do order[#order+1]=s end
  for _,s in ipairs(order) do attempt(state,function() self:retire(s) end) end
  U.Tooltip.dispose(root);root:removeFromUIManager();U.Focus.restore(num)
  if state.error then error(state.error) end
 end
 function d:launch(entry)
  if self.closed then return end
  menu:setVisible(false)
  local s
  if entry.kind=='tool' then s=C.launcher.openTool(num,computer,entry.id) else s=C.launcher.open(num,computer,entry.id) end
  if not s then self:refreshCatalog();return end
  if entry.kind=='drive' then return s:openDrive() end
  if entry.kind=='tool' then return s:openProgram() end
  if s.content then return self:activate(s) end
  if s.hooks.launch then return s:openProgram() end
  return s:openDrive()
 end
 function d:refreshCatalog()
  local rows=C.launcher and C.launcher.list(num,computer) or {};local signature='';local entries={};local provider;local allowed={}
  for _,row in ipairs(rows) do
   allowed[row.id]=true
   signature=signature..'|'..row.id..':'..row.title..':'..row.icon..':'..tostring(row.hasDrive)..':'..tostring(row.toolTitle)
   if row.hasDrive and not provider then provider=row end
   entries[#entries+1]={id=row.id,key=row.id..':app',title=row.title,icon=row.icon,kind='app'}
   if row.toolTitle then entries[#entries+1]={id=row.id,key=row.id..':tool',title=row.toolTitle,icon='writer',kind='tool'} end
  end
  local stale={};for _,s in ipairs(self.order) do if s~=self.home and not allowed[s.application] then stale[#stale+1]=s end end
  for _,s in ipairs(stale) do self:retire(s) end
  if provider then table.insert(entries,1,{id=provider.id,key='drive',title=tr('ComputerDrive'),icon='disc',kind='drive'}) end
  if signature==self.signature then return end;self.signature=signature;self.entries=entries
  for _,b in ipairs(self.icons) do U.Tooltip.dispose(b);desktop:removeChild(b) end
  for _,b in ipairs(self.menuButtons) do U.Tooltip.dispose(b);menu:removeChild(b) end
  self.icons={};self.menuButtons={}
  for _,entry in ipairs(entries) do
   local item=entry
   local b=UI.iconButton(desktop,{text=item.title,icon=item.icon,onClick=function() return self:launch(item) end})
   b.render=function(w)
    A.drawIcon(w,item.icon,(w:getWidth()-56)/2,2,56)
    A.text(w,w.title,4,68,w:getWidth()-8,'white');U.Renderer.focus(w)
   end
   self.icons[#self.icons+1]=b;b.entry=item
   b.tooltip=item.title
   self.menuButtons[#self.menuButtons+1]=button(menu,item.title,function() return self:launch(item) end)
   self.menuButtons[#self.menuButtons].tooltip=item.title
  end
  menu:bringToTop();self:layout();self:refreshFocus()
 end
 function d:layout()
  root:setWidth(math.max(root.minimumWidth,root:getWidth()));root:setHeight(math.max(root.minimumHeight,root:getHeight()))
  local m=UI.metrics();local g=CRT.geometry(root:getWidth(),root:getHeight(),m);self.geometry=g
  UI.place(desktop,g.x,g.y,g.width,g.desktopHeight)
  local y=g.y+g.height-g.bar
  UI.place(self.start,g.x+4,y+4,math.max(90,m.font*5),m.button)
  UI.place(self.homeButton,self.start.x+self.start:getWidth()+8,y+4,m.button,m.button)
  UI.place(self.off,g.powerX,g.powerY,g.powerWidth,g.powerHeight)
  local iconW=math.max(140,m.font*9);local iconH=m.font+80
  self.columns=math.max(1,math.floor((g.width-16)/iconW))
  local iconRows=math.max(1,math.floor((g.desktopHeight-m.button-28)/iconH))
  local menuRows=math.max(1,math.floor((g.desktopHeight-3*m.button-40)/(m.button+4)))
  self.pageSize=math.min(self.columns*iconRows,menuRows);self.pages=math.max(1,math.ceil(#self.entries/self.pageSize))
  self.page=math.max(1,math.min(self.page,self.pages));local start=(self.page-1)*self.pageSize
  for i,b in ipairs(self.icons) do
   local n=i-start-1;local show=n>=0 and n<self.pageSize;b:setVisible(show)
   if show then UI.place(b,12+math.floor(n/iconRows)*iconW,20+(n%iconRows)*iconH,iconW-4,iconH-4) end
  end
  local paged=self.pages>1
  UI.place(self.previous,8,g.desktopHeight-m.button-8,(g.width-24)/2,m.button);UI.place(self.next,16+(g.width-24)/2,g.desktopHeight-m.button-8,(g.width-24)/2,m.button)
  for _,pair in ipairs({{self.previous,self.page>1},{self.next,self.page<self.pages},{self.menuPrevious,self.page>1},{self.menuNext,self.page<self.pages}}) do pair[1]:setVisible(paged);pair[1]:setEnable(pair[2]) end
  local count=math.min(self.pageSize,math.max(0,#self.entries-start));local menuW=math.min(g.width-8,math.max(250,m.font*18))
  local menuH=16+(count+1)*(m.button+4)+(paged and m.button+4 or 0)
  UI.place(menu,4,math.max(0,g.desktopHeight-menuH-4),menuW,menuH)
  for i,b in ipairs(self.menuButtons) do local n=i-start-1;local show=n>=0 and n<self.pageSize;b:setVisible(show);if show then UI.place(b,8,8+n*(m.button+4),menuW-16,m.button) end end
  local bottom=8+count*(m.button+4)
  UI.place(self.menuPrevious,8,bottom,(menuW-20)/2,m.button);UI.place(self.menuNext,12+(menuW-20)/2,bottom,(menuW-20)/2,m.button)
  UI.place(self.menuOff,8,bottom+(paged and m.button+4 or 0),menuW-16,m.button)
  local tasks={};for _,s in ipairs(self.order) do
   if s.content then tasks[#tasks+1]=s end;s.task:setVisible(false)
   UI.place(s.frame,10,10,g.width-20,g.desktopHeight-20)
   UI.place(s.frame.minimize,s.frame:getWidth()-2*m.button-8,4,m.button,m.button);UI.place(s.frame.exit,s.frame:getWidth()-m.button-4,4,m.button,m.button)
   if s.content then UI.place(s.content,4,m.button+8,s.frame:getWidth()-8,s.frame:getHeight()-m.button-12) end
  end
  local taskX=self.homeButton.x+m.button+8;local space=g.x+g.width-taskX-4
  local capacity=math.max(1,math.floor((space-2*m.button-8)/math.max(100,m.font*6)))
  if self.focusTask then for i,s in ipairs(tasks) do if s==self.focusTask then self.taskPage=math.ceil(i/capacity);break end end;self.focusTask=nil end
  local taskPages=math.max(1,math.ceil(#tasks/capacity));self.taskPage=math.max(1,math.min(self.taskPage,taskPages))
  local taskPaged=taskPages>1;self.taskPrevious:setVisible(taskPaged);self.taskNext:setVisible(taskPaged)
  self.taskPrevious:setEnable(self.taskPage>1);self.taskNext:setEnable(self.taskPage<taskPages)
  if taskPaged then UI.place(self.taskPrevious,taskX,y+4,m.button,m.button);taskX=taskX+m.button+4 end
  local taskWidth=math.min(190,math.max(1,(g.x+g.width-taskX-4-(taskPaged and m.button+4 or 0))/capacity-4))
  for i,s in ipairs(tasks) do local n=i-(self.taskPage-1)*capacity-1;if n>=0 and n<capacity then s.task:setVisible(true);s.task.b47PCSelected=self.current==s and not s.minimized;UI.place(s.task,taskX+n*(taskWidth+4),y+4,taskWidth,m.button) end end
  if taskPaged then UI.place(self.taskNext,g.x+g.width-m.button-4,y+4,m.button,m.button) end
  for _,key in ipairs({'closeButton','pinButton','collapseButton','infoButton'}) do if root[key] then root[key]:setVisible(false) end end
 end
 root.prerender=function()
  if d.closed then return end
  if getSpecificPlayer(num)~=actor or not Device.computer(actor,computer,true) then d:close();return end
  local state={};local order={};for _,s in ipairs(d.order) do order[#order+1]=s end
  for _,s in ipairs(order) do if not s.hooks.enabled() or not s.hooks.canUse(actor,computer,true) then attempt(state,function() d:retire(s) end) end end
  if state.error then error(state.error) end
  if not d.catalogAt or getTimestampMs()-d.catalogAt>=2000 then d.catalogAt=getTimestampMs();d:refreshCatalog() end
  d:layout();CRT.draw(root,root:getWidth(),root:getHeight());local g=d.geometry
  A.panel(root,g.x,g.y+g.desktopHeight,g.width,g.status,'teal');A.panel(root,g.x,g.y+g.height-g.bar,g.width,g.bar,'grey')
  A.bevel(root,g.x,g.y+g.height-g.bar,g.width,g.bar)
  A.text(root,d.current and d.current.status or '',g.x+6,g.y+g.desktopHeight+4,g.width-12,'white')
  for _,s in ipairs(d.order) do
   if s.updateSession then s:updateSession() end
   if s.content and s.content.updateComputer then s.content:updateComputer() end
  end
 end
 root.onJoypadDown=function(_,key)
  if key==Joypad.BButton then
   if menu:isVisible() then menu:setVisible(false);d:refreshFocus()
   elseif d.current and d.current.content and not d.current.minimized then d.current:desktop() else d:close() end
  else ISPanelJoypad.onJoypadDown(root,key) end
 end
 root:setWantKeyEvents(true);root.isKeyConsumed=function(_,key) return num==0 and key==Keyboard.KEY_ESCAPE end
 root.onKeyRelease=function(_,key)
  if not root:isKeyConsumed(key) then return end
  if menu:isVisible() then root:onJoypadDown(Joypad.BButton)
  elseif d.current and d.current.content then d.current:closeApp() else root:onJoypadDown(Joypad.BButton) end
 end
 U.bounds(root,num);root:addToUIManager();d:layout();return d
end
return D
