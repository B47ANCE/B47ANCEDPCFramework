-- Geometry/input host double only. No game launch and no Quartermaster imports.
local W={}
function W:new(x,y,w,h,title,target,callback)
 local o={x=x,y=y,width=w,height=h,title=title,target=target,onclick=callback,children={},options={},selected=1,visible=true}
 setmetatable(o,{__index=self});return o
end
for _,name in ipairs({'initialise','instantiate','setWantKeyEvents','setAnchorsTBLR','bringToTop','drawRect','drawRectBorder','drawText','drawTextCentre','onJoypadDown'}) do W[name]=function() end end
for _,name in ipairs({'X','Y','Width','Height'}) do
 local field=name:lower();W['set'..name]=function(self,v) self[field]=v end;W['get'..name]=function(self) return self[field] end
end
function W:addChild(c) self.children[#self.children+1]=c;c.parent=self end
function W:removeChild(c) for i,v in ipairs(self.children) do if v==c then table.remove(self.children,i);c.parent=nil;return end end end
function W:setVisible(v) self.visible=v end;function W:isVisible() return self.visible end
function W:setEnable(v) self.enable=v end
function W:addToUIManager() self.added=true end;function W:removeFromUIManager() self.removed=true end
function W:insertNewLineOfButtons(...) self.joypadButtonsY[#self.joypadButtonsY+1]={...} end
function W:clear() self.options={};self.items={};self.selected=1 end
function W:addOptionWithData(text,data) self.options[#self.options+1]={text=text,data=data} end
function W:setTitle(text) self.title=text end
function W:setText(text) self.text=text end;function W:getInternalText() return self.text or '' end
function W:setTextRGBA(r,g,b,a) self.glyphColor={r=r,g=g,b=b,a=a} end
function W:addItem(text,item) self.items=self.items or {};self.items[#self.items+1]={text=text,item=item,height=self.itemheight,itemindex=#self.items+1};return self.items[#self.items] end
for _,name in ipairs({'ISPanel','ISPanelJoypad','ISCollapsableWindowJoypad','ISButton','ISScrollingListBox','ISTextEntryBox','ISComboBox'}) do _G[name]=W;package.loaded['ISUI/'..name]=W end
local Entry=setmetatable({},{__index=W})
function Entry:new(text,x,y,w,h) local entry=W.new(self,x,y,w,h);entry.text=text;return entry end
ISTextEntryBox=Entry;package.loaded['ISUI/ISTextEntryBox']=Entry
local Combo=setmetatable({},{__index=W})
function Combo:new(x,y,w,h,target,onChange) local combo=W.new(self,x,y,w,h);combo.target=target;combo.onChange=onChange;return combo end
ISComboBox=Combo;package.loaded['ISUI/ISComboBox']=Combo
UIFont={Small=1,Medium=2};Keyboard={KEY_ESCAPE=1};Joypad={BButton=2}
getTextManager=function() return {getFontHeight=function() return 14 end,MeasureStringX=function(_,_,s) return #s*7 end} end
getText=function(k) return k end;setJoypadFocus=function() end
getPlayerScreenWidth=function() return 1280 end;getPlayerScreenHeight=function() return 900 end
getPlayerScreenLeft=function() return 0 end;getPlayerScreenTop=function() return 0 end
getSpecificPlayer=function() return PC_FIXTURE.actor end
local P=require 'B47ANCEDPCFramework/API';local C=P.ComputerUI;local computer=PC_FIXTURE.computer
assert(B47ANCEDQuartermaster==nil and B47ANCEDUI==nil,'standalone loaded Quartermaster')
local bare=assert(P.open(0,computer));assert(bare.application=='desktop' and not bare.content and not bare.writerIcon:isVisible())
bare:prerender();for _,row in ipairs(bare.joypadButtonsY) do for _,button in ipairs(row) do assert(button:isVisible(),'hidden tool in controller focus') end end
bare:openDrive();assert(not bare.mounted and not bare.content.run.enable);bare:runDisc();bare:close()
local reads,closes=0,0;local available=true;local pending
P.registerApplication('fixture',function()
 if not available then return end
 return {file='FIXTURE.EXE',canRun=function(i) return i:getFullType()=='Fixture.Media' end,
 drive=function(command,args,reply)
  if command=='list' then pending=reply else reply({status='ok'}) end
 end,read=function() reads=reads+1 end,close=function() closes=closes+1 end}
end)
assert(not pcall(P.registerApplication,'fixture',function() end),'duplicate registration silently replaced app')
assert(not P.open(0,computer,'missing'))
local screen=assert(P.open(0,computer,'fixture'));assert(screen~=bare and not screen.content)
screen:openDrive();local old=pending
pending({status='ok',mounted={id=41,name='Fixture',fullType='Fixture.Media',drive='drive'}})
assert(reads==0,'mount auto-ran app');screen:runDisc();assert(reads==1)
screen:applyDrive({status='ok',mounted={id=41,name='Other',fullType='Wrong.Media',drive='drive'}})
screen:runDisc();assert(reads==1,'wrong media ran registered app')
screen:close();old({status='ok',mounted={id=41,name='Late',fullType='Fixture.Media',drive='drive'}})
assert(not C.active[0] and closes==1,'late response revived closed screen')
available=false;assert(not P.open(0,computer,'fixture'))
local standalone=assert(P.open(0,computer));assert(standalone.application=='desktop')
SandboxVars.B47ANCEDPCFramework.Enabled=false;standalone:prerender();assert(not C.active[0])
assert(not P.open(0,computer));SandboxVars.B47ANCEDPCFramework.Enabled=true
local registered={};Events={OnTick={Add=function(fn) registered.tick=fn end},OnFillWorldObjectContextMenu={Add=function(fn) registered.menu=fn end}}
local queue={};ISTimedActionQueue={getTimedActionQueue=function() return {queue=queue} end}
package.loaded['TimedActions/ISTimedActionQueue']=true;package.loaded['TimedActions/WalkToTimedAction']=true
local Startup=require 'B47ANCEDPCFramework/Startup';assert(registered.tick and registered.menu)
local entries={};local menu={addOption=function(_,label,_,fn) entries[#entries+1]={label=label,fn=fn} end}
Startup.menu(0,menu,{computer},false);assert(#entries==1,'disabled app exposed context action')
entries[1].fn();assert(C.active[0] and C.active[0].application=='desktop' and not C.active[0].content);C.active[0]:close()
available=true;P.registerApplication('second',function() return {} end,'Second')
entries={};Startup.menu(0,menu,{computer},false);assert(#entries==1,'world menu should open the shared desktop once')
entries[1].fn();assert(C.active[0].application=='desktop')
local catalog={};for _,entry in ipairs(C.desktops[0].entries) do catalog[entry.id]=true end
assert(catalog.second and catalog.fixture and catalog['b47pc.minesweeper'],'shared desktop omitted an available app');C.active[0]:close()
SandboxVars.B47ANCEDPCFramework.Enabled=false;entries={};Startup.menu(0,menu,{computer},false);assert(#entries==0)
SandboxVars.B47ANCEDPCFramework.Enabled=true
print('PASS OFFLINE standalone desktop: zero Quartermaster imports, empty host, registered app, no auto-run, wrong-media refusal, disabled app fallback, late replies, singleton cleanup and sandbox disable')
