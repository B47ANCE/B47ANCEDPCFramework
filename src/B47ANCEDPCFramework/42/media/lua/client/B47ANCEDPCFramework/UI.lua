-- Public client presentation API 1. Gameplay and transport remain app-owned.
require 'B47ANCEDPCUI/Controls'
require 'ISUI/ISPanelJoypad'
require 'ISUI/ISComboBox'
local U=B47ANCEDPCUI
local Assets=require 'B47ANCEDPCFramework/Assets'
local UI={version=1,assets=Assets}
local function caption(o) return o.textKey and getText(o.textKey) or o.text or '' end
function UI.metrics()
 local copy={};for k,v in pairs(U.Theme.metrics()) do copy[k]=v end;return copy
end
function UI.place(w,...)
 U.Layout.place(w,...);if w.b47PCComposite then w:layout() end;return w
end
function UI.style(w,kind)
 w.backgroundColor=Assets.color(kind=='input' and 'white' or 'grey')
 w.backgroundColorMouseOver=Assets.color('light');w.borderColor=Assets.color('shadow')
 w.textColor=Assets.color('black');w.textColorDisabled=Assets.color('muted')
 if kind=='input' and w.setTextRGBA then local c=Assets.color('black');w:setTextRGBA(c.r,c.g,c.b,1) end
 if kind=='list' then w.selectionColor=Assets.color('blue') end
 return w
end
local function attach(parent,w,o,kind)
 assert(parent and parent.addChild,'PC control requires a parent')
 w.playerNum=parent.playerNum or 0;w:initialise();w:instantiate();parent:addChild(w)
 UI.style(w,kind);if o.tooltipKey then w.tooltip=getText(o.tooltipKey) end
 return w
end
local function managed(w) U.Tooltip.attach(w,w.playerNum);return w end
function UI.panel(parent,o)
 o=o or {};local w=attach(parent,ISPanelJoypad:new(o.x or 0,o.y or 0,o.width or 200,o.height or 120),o,'panel')
 w.prerender=function(self) Assets.panel(self,0,0,self:getWidth(),self:getHeight(),o.color or 'grey') end
 return managed(w)
end
local function makeButton(parent,o)
 o=o or {};local m=UI.metrics()
 local b=attach(parent,ISButton:new(o.x or 0,o.y or 0,o.width or 120,o.height or m.button,caption(o),parent,function(_,control)
  if o.onClick then o.onClick(control) end
 end),o,'button')
 b.font=U.Theme.fonts.body
 b.prerender=function(self)
  Assets.panel(self,0,0,self:getWidth(),self:getHeight(),self.mouseOver and 'light' or 'grey')
  Assets.bevel(self,0,0,self:getWidth(),self:getHeight(),self.pressed or self.b47PCSelected)
 end
 b.render=function(self)
  local c=Assets.color(self.enable==false and 'muted' or 'black')
  self:drawTextCentre(U.Renderer.fit(self.title or '',self:getWidth()-12),self:getWidth()/2,
   (self:getHeight()-UI.metrics().font)/2,c.r,c.g,c.b,1,U.Theme.fonts.body);U.Renderer.focus(self)
 end
 return b
end
function UI.button(parent,o) return managed(makeButton(parent,o)) end
function UI.textEntry(parent,o)
 o=o or {};return managed(attach(parent,ISTextEntryBox:new(o.value or '',o.x or 0,o.y or 0,o.width or 200,o.height or UI.metrics().button),o,'input'))
end
function UI.combo(parent,o)
 o=o or {};local w=attach(parent,ISComboBox:new(o.x or 0,o.y or 0,o.width or 200,o.height or UI.metrics().button,parent,function(_,combo)
  local row=combo.options[combo.selected];if o.onChange then o.onChange(row and row.data,combo) end
 end),o,'input')
 for _,row in ipairs(o.options or {}) do w:addOptionWithData(caption(row),row.value) end
 return managed(w)
end
function UI.list(parent,o)
 o=o or {};local w=attach(parent,ISScrollingListBox:new(o.x or 0,o.y or 0,o.width or 240,o.height or 160),o,'list')
 w.itemheight=o.rowHeight or UI.metrics().row
 w.doDrawItem=function(self,y,row)
  local selected=self.selected==(row.index or row.itemindex)
  Assets.panel(self,0,y,self:getWidth(),row.height or self.itemheight,selected and 'blue' or 'white')
  Assets.text(self,row.text,6,y+4,self:getWidth()-UI.metrics().scrollbar-12,selected and 'white' or 'black')
  return y+(row.height or self.itemheight)
 end
 return managed(w)
end
function UI.label(parent,o)
 o=o or {};local w=attach(parent,ISPanelJoypad:new(o.x or 0,o.y or 0,o.width or 200,o.height or UI.metrics().font+4),o,'panel')
 w.captionText=o.text or '';w.captionKey=o.textKey
 function w:setText(value) self.captionText=tostring(value or '');self.captionKey=nil end
 function w:setTextKey(key) assert(type(key)=='string' and #key>0,'invalid PC label translation key');self.captionKey=key end
 w.prerender=function(self) Assets.text(self,self.captionKey and getText(self.captionKey) or self.captionText,0,0,self:getWidth(),o.textColor or 'black') end
 return managed(w)
end
function UI.iconButton(parent,o)
 local options={};for k,v in pairs(o or {}) do options[k]=v end;o=options
 o.width=o.width or math.max(100,UI.metrics().font*8);o.height=o.height or UI.metrics().font+64
 assert(Assets.hasIcon(o.icon or 'application'),'unknown PC icon')
 local b=makeButton(parent,o)
 b.prerender=function(self)
  if self.mouseOver or self.joypadFocused then U.Renderer.border(self,0,0,self:getWidth(),self:getHeight(),Assets.color('light')) end
 end
 b.render=function(self)
  Assets.drawIcon(self,o.icon or 'application',(self:getWidth()-40)/2,6,40)
  Assets.text(self,self.title or '',4,48,self:getWidth()-8,o.textColor or 'white');U.Renderer.focus(self)
 end
 return managed(b)
end
function UI.focus(panel,rows)
 panel.joypadButtonsY={};panel.joypadButtons={};panel.allJoypadButtons={};panel.joypadIndexY=1;panel.joypadIndex=1
 for _,row in ipairs(rows) do
  local visible={};for _,w in ipairs(row) do if w:isVisible() and w.enable~=false and w.disabled~=true then visible[#visible+1]=w end end
  if #visible>0 then panel:insertNewLineOfButtons(unpack(visible)) end
 end
end
-- Composite controls use only the same native panels/buttons as the core kit.
local function descriptors(rows)
 local copy,seen={},{}
 for _,row in ipairs(rows or {}) do
  assert(type(row.id)=='string' and #row.id>0 and not seen[row.id],'duplicate or invalid PC control ID')
  seen[row.id]=true;local item={};for k,v in pairs(row) do item[k]=v end;copy[#copy+1]=item
 end
 return copy
end
local function wrapButtons(panel,buttons)
 local m=UI.metrics();local gap=4;local usable=math.max(1,panel:getWidth()-8)
 local x,y=4,4;local rows={{}}
 for _,b in ipairs(buttons) do
  local width=math.min(usable,math.max(m.button,getTextManager():MeasureStringX(U.Theme.fonts.body,b.title or '')+24))
  if x>4 and x+width>4+usable then x=4;y=y+m.button+gap;rows[#rows+1]={} end
  UI.place(b,x,y,width,m.button);rows[#rows][#rows[#rows]+1]=b;x=x+width+gap
 end
 return rows,#buttons>0 and y+m.button+4 or 8
end
local function composite(w,afterPaint)
 local paint=w.prerender;local width,height,font
 w.prerender=function(self)
  if width~=self:getWidth() or height~=self:getHeight() or font~=UI.metrics().font then
   self:layout();width,height,font=self:getWidth(),self:getHeight(),UI.metrics().font
  end
  paint(self);if afterPaint then afterPaint(self) end
 end
 w:layout();width,height,font=w:getWidth(),w:getHeight(),UI.metrics().font;return w
end
function UI.toolbar(parent,o)
 o=o or {};local actions=descriptors(o.actions);local w=UI.panel(parent,o);w.b47PCComposite=true;local buttons,byID={},{}
 for _,action in ipairs(actions) do
  local item=action
  local b=UI.button(w,{textKey=item.textKey,text=item.text,tooltipKey=item.tooltipKey,onClick=function(control)
   if control.enable~=false and item.onClick then item.onClick(control,item.id) end
  end})
  b:setEnable(item.enabled~=false);buttons[#buttons+1]=b;byID[item.id]=b
 end
 function w:button(id) return byID[id] end
 function w:focusRows() return self.rows end
 function w:layout() self.rows,self.contentHeight=wrapButtons(self,buttons);self:setHeight(self.contentHeight);UI.focus(self,self.rows) end
 return composite(w)
end
function UI.statusBar(parent,o)
 o=o or {};local w=UI.panel(parent,o);w.b47PCComposite=true
 local label=UI.label(w,{textKey=o.textKey,text=o.text,textColor=o.textColor})
 function w:setText(value) label:setText(value) end
 function w:setTextKey(key) label:setTextKey(key) end
 function w:layout()
  self:setHeight(UI.metrics().font+12);UI.place(label,6,6,math.max(1,self:getWidth()-12),UI.metrics().font+4)
 end
 return composite(w,function(self) Assets.bevel(self,0,0,self:getWidth(),self:getHeight(),true) end)
end
function UI.tabView(parent,o)
 o=o or {};local definitions=descriptors(o.tabs);assert(#definitions>0,'PC tabs require a page')
 local validInitial=not o.selected;for _,item in ipairs(definitions) do if item.id==o.selected then validInitial=true end end
 assert(validInitial,'unknown initial PC tab')
 local w=UI.panel(parent,o);w.b47PCComposite=true;local buttons,pages,byID,focus={},{},{},{}
 local selected
 function w:page(id) return pages[id] end
 function w:selectedID() return selected end
 function w:setPageFocus(id,rows) assert(pages[id],'unknown PC tab');focus[id]=rows;self:layout() end
 function w:focusRows()
  local rows={};for _,row in ipairs(self.headerRows or {}) do rows[#rows+1]=row end
  for _,row in ipairs(focus[selected] or {}) do rows[#rows+1]=row end
  return rows
 end
 function w:select(id)
  if not pages[id] then return false end
  if selected==id then return true end
  local previous=selected;selected=id
  for key,page in pairs(pages) do page:setVisible(key==id);byID[key].b47PCSelected=key==id end
  self:layout();if o.onChange then o.onChange(id,pages[id],previous) end;return true
 end
 function w:layout()
  self.headerRows,self.headerHeight=wrapButtons(self,buttons)
  for _,page in pairs(pages) do UI.place(page,4,self.headerHeight,math.max(1,self:getWidth()-8),math.max(1,self:getHeight()-self.headerHeight-4)) end
  UI.focus(self,self:focusRows())
 end
 for _,definition in ipairs(definitions) do
  local item=definition;pages[item.id]=UI.panel(w,{})
  local b=UI.button(w,{textKey=item.textKey,text=item.text,tooltipKey=item.tooltipKey,onClick=function() w:select(item.id) end})
  buttons[#buttons+1]=b;byID[item.id]=b
 end
 selected=o.selected or definitions[1].id
 for id,page in pairs(pages) do page:setVisible(id==selected);byID[id].b47PCSelected=id==selected end
 return composite(w)
end
function UI.window(host,o)
 o=o or {};assert(host and host.showApp and not host.closed,'PC window requires an open desktop host')
 local title=o.titleKey and getText(o.titleKey) or o.title or ''
 local w=ISPanelJoypad:new(0,0,math.max(1,host:getWidth()-64),math.max(1,host:getHeight()-200))
 w.playerNum=host.playerNum;w.b47PCSDKWindow=true;w.b47PCHost=host;w:initialise();w:instantiate();UI.style(w,'panel');UI.focus(w,{})
 function w:close(reason)
  if self.closed then return end;self.closed=true
  local ok,err=pcall(function() if o.onClose then o.onClose(reason or 'closed') end end)
  U.Tooltip.dispose(self);host:release(self)
  if not ok then error(err) end
 end
 local width,height,font
 function w:updateComputer()
  local a,b=self:getWidth(),self:getHeight()
  local size=UI.metrics().font
  if width~=a or height~=b or font~=size then width,height,font=a,b,size;if o.onResize then o.onResize(self,a,b) end end
  if o.onUpdate then o.onUpdate(self) end
 end
 w.prerender=function(self) Assets.panel(self,0,0,self:getWidth(),self:getHeight(),'grey') end
 w:setWantKeyEvents(true)
 w.isKeyConsumed=function(self,key) return not self.closed and self:isVisible() and not host.menuOpen and self.playerNum==0 and key==Keyboard.KEY_ESCAPE end
 w.onKeyRelease=function(self,key) if self:isKeyConsumed(key) then self:close() end end
 w.onJoypadDown=function(self,key) if key==Joypad.BButton then self:close() else ISPanelJoypad.onJoypadDown(self,key) end end
 host:showApp(w,title);return w
end
return UI
