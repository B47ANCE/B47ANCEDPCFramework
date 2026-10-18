local PC=require 'B47ANCEDPCFramework/API'
dofile(EXAMPLE_ROOT..'/ComponentGallery.lua')
local host=assert(PC.open(0,PC_FIXTURE.computer,'example.component-gallery'))
assert(not host.content,'gallery launched automatically')
local window=assert(host:openProgram());host:prerender()
assert(window.entry and window.choice and window.list and window.apply)
window.apply.onclick(nil,window.apply);assert(#window.list.items==1)
assert(window.tabs.y+window.tabs:getHeight()<=window.status.y,'gallery tabs overlap status')
window.tabs:select('about');assert(#window.joypadButtonsY==#window.tabs.headerRows,'hidden editor remained in root focus')
window.tabs:select('editor');assert(window.joypadButtonsY[#window.joypadButtonsY][1]==window.list)
local textManager=getTextManager;local screenW,screenH=getPlayerScreenWidth,getPlayerScreenHeight
getPlayerScreenWidth=function() return 3840 end;getPlayerScreenHeight=function() return 2160 end
for _,font in ipairs({14,24,32,42}) do
 getTextManager=function() return {getFontHeight=function() return font end,MeasureStringX=function(_,_,s) return #s*font/2 end} end
 -- Reserve room for the hardware surrounding the same native controls.
 host:setWidth(math.max(800,font*28));host:setHeight(math.max(900,font*28))
 host:prerender()
  assert(window.entry.y+window.entry.height<=window.choice.y and window.choice.y+window.choice.height<=window.toolbar.y)
 assert(window.toolbar.y+window.toolbar.height<window.list.y and window.list.y+window.list.height<=window.tabs:page('editor').height, 'gallery font='..font..' root='..host.root.width..'x'..host.root.height..' list='..window.list.y..'+'..window.list.height..' page='..window.tabs:page('editor').height)
 assert(window.tabs.y+window.tabs.height<=window.status.y)
end
getTextManager=textManager;getPlayerScreenWidth,getPlayerScreenHeight=screenW,screenH
local callback=window.apply.onclick;host:close();callback(nil,window.apply)
assert(#window.list.items==1,'closed example window accepted a callback')
print('PASS OFFLINE opt-in consumer gallery: explicit launch, native controls, localized keys, local-only edits, 14/24/32/42 font layout and closed-window guard')
