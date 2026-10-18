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
function UI.place(...) return U.Layout.place(...) end
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
  Assets.bevel(self,0,0,self:getWidth(),self:getHeight(),self.pressed)
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
 w.isKeyConsumed=function(self,key) return self.playerNum==0 and key==Keyboard.KEY_ESCAPE end
 w.onKeyRelease=function(self,key) if self:isKeyConsumed(key) then self:close() end end
 w.onJoypadDown=function(self,key) if key==Joypad.BButton then self:close() else ISPanelJoypad.onJoypadDown(self,key) end end
 host:showApp(w,title);return w
end
return UI
