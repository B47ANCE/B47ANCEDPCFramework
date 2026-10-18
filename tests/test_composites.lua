local PC=require 'B47ANCEDPCFramework/API';local UI=PC.UI
assert(PC.supports('tabs') and PC.supports('toolbars') and PC.supports('status-bars'))
local parent=UI.panel({addChild=function() end},{width=700,height=700})
local changes=0
local tabs;tabs=UI.tabView(parent,{width=600,height=500,tabs={{id='edit',text='Editor'},{id='about',text='About'}},
 onChange=function(id,page,previous) changes=changes+1;assert(id=='about' and previous=='edit' and page==tabs:page(id)) end})
-- Callback closes over the completed native control, never a construction event.
local entry=UI.textEntry(tabs:page('edit'),{})
local about=UI.button(tabs:page('about'),{text='About action'})
tabs:setPageFocus('edit',{{entry}});tabs:setPageFocus('about',{{about}})
assert(tabs:selectedID()=='edit' and tabs:page('edit'):isVisible() and not tabs:page('about'):isVisible())
assert(tabs:focusRows()[#tabs:focusRows()][1]==entry)
assert(not tabs:select('missing') and changes==0)
assert(tabs:select('about') and changes==1 and not tabs:page('edit'):isVisible())
assert(tabs:select('about') and changes==1 and tabs:focusRows()[#tabs:focusRows()][1]==about)
tabs.joypadIndex=2;tabs:prerender();tabs:prerender();assert(tabs.joypadIndex==2,'painting reset controller selection')
assert(entry:getInternalText()=='','page switch changed local entry state')
local calls=0;local actions={{id='add',text='Add preview',onClick=function(_,id) assert(id=='add');calls=calls+1 end},
 {id='disabled',text='Unavailable action',enabled=false,onClick=function() error('disabled action ran') end}}
local bar=UI.toolbar(parent,{width=600,actions=actions});actions[1].onClick=function() error('mutated descriptor ran') end
bar:button('add').onclick(nil,bar:button('add'));bar:button('disabled').onclick(nil,bar:button('disabled'));assert(calls==1)
assert(#bar.joypadButtonsY==1 and #bar.joypadButtonsY[1]==1)
local status=UI.statusBar(parent,{textKey='UI_Test_Status'});status:setText('Updated');status:setTextKey('UI_Test_Status');status:prerender()
local manager=getTextManager
for _,font in ipairs({14,24,32,42}) do
 getTextManager=function() return {getFontHeight=function() return font end,MeasureStringX=function(_,_,s) return #s*font/2 end} end
 for _,width in ipairs({100,300,700}) do
  UI.place(tabs,0,0,width,900);UI.place(bar,0,0,width,1);UI.place(status,0,0,width,1)
  assert(status:getHeight()==font+12)
  for _,row in ipairs(bar:focusRows()) do for _,b in ipairs(row) do
   assert(b.x>=0 and b.x+b.width<=width and b.y+b.height<=bar.height)
  end end
  local p=tabs:page('about');assert(p.y>=tabs.headerHeight and p.y+p.height<=tabs.height)
 end
end
getTextManager=manager
local before=#parent.children
assert(not pcall(UI.tabView,parent,{tabs={{id='same'},{id='same'}}}))
assert(not pcall(UI.tabView,parent,{tabs={}}))
assert(not pcall(UI.tabView,parent,{tabs={{id='valid'}},selected='missing'}))
assert(not pcall(UI.toolbar,parent,{actions={{id='same'},{id='same'}}}))
assert(#parent.children==before,'invalid descriptors attached partial controls')
print('PASS OFFLINE composites: page selection/visibility/focus, invalid IDs, action isolation/disable and wrapped font/width layouts')
