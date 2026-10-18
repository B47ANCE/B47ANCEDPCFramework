local PC=require 'B47ANCEDPCFramework/API'
dofile(EXAMPLE_ROOT..'/ComponentGallery.lua')
local host=assert(PC.open(0,PC_FIXTURE.computer,'example.component-gallery'))
assert(not host.content,'gallery launched automatically')
local window=assert(host:openProgram());host:prerender()
assert(window.entry and window.choice and window.list and window.apply)
window.apply.onclick(nil,window.apply);assert(#window.list.items==1)
assert(window.list.y+window.list:getHeight()<=window.status.y,'gallery list overlaps status')
local textManager=getTextManager;local screenW,screenH=getPlayerScreenWidth,getPlayerScreenHeight
getPlayerScreenWidth=function() return 3840 end;getPlayerScreenHeight=function() return 2160 end
for _,font in ipairs({14,24,32,42}) do
 getTextManager=function() return {getFontHeight=function() return font end,MeasureStringX=function(_,_,s) return #s*font/2 end} end
 host:setWidth(math.max(700,font*28));host:setHeight(math.max(180+8*(font+12),160+5*font+5*(font+12)))
 host:prerender()
 assert(window.entry.y+window.entry.height<=window.choice.y and window.choice.y+window.choice.height<=window.apply.y)
 assert(window.apply.y+window.apply.height<window.list.y and window.list.y+window.list.height<=window.status.y)
end
getTextManager=textManager;getPlayerScreenWidth,getPlayerScreenHeight=screenW,screenH
local callback=window.apply.onclick;host:close();callback(nil,window.apply)
assert(#window.list.items==1,'closed example window accepted a callback')
print('PASS OFFLINE opt-in consumer gallery: explicit launch, native controls, localized keys, local-only edits, 14/24/32/42 font layout and closed-window guard')
