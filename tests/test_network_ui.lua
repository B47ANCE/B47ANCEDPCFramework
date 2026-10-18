local PC=require 'B47ANCEDPCFramework/API';local f=PC_FIXTURE
local time=getGameTime;getGameTime=function() return {getWorldAgeHours=function() return 300 end} end
if not PC.applicationTitle('b47pc.network') then require('B47ANCEDPCFramework/Apps/NetworkSetup')(PC) end
local measure,width,height=getTextManager,getPlayerScreenWidth,getPlayerScreenHeight
getPlayerScreenWidth=function() return 3840 end;getPlayerScreenHeight=function() return 2160 end
for _,font in ipairs({14,24,32,42}) do
 getTextManager=function() return {getFontHeight=function() return font end,MeasureStringX=function(_,_,s) return #s*font/2 end} end
 local host=assert(PC.open(0,f.computer,'b47pc.network'));host:openProgram();host:setWidth(host.minimumWidth);host:setHeight(host.minimumHeight);host:prerender()
 local panel=host.content;local c=panel.networkControls;assert(c and #c.list.items>=1)
 assert(not c.peer:isVisible() and not c.public:isVisible(),'status screen exposes pairing controls')
 for _,row in ipairs(panel.joypadButtonsY) do for _,w in ipairs(row) do assert(w:isVisible(),'hidden pairing control in status focus') end end
 local count=#c.list.items;f.advance(5100);host:prerender();assert(#c.list.items==count,'status refresh duplicated nodes')
 c.mode.onclick(nil,c.mode);assert(c.peer:isVisible() and c.public:isVisible(),'mode toggle did not lay out pairing immediately')
 for _,w in pairs(c) do assert(w.x>=0 and w.y>=0 and w.x+w.width<=panel.width and w.y+w.height<=panel.height,'network control escaped at font '..font) end
 assert(c.list.y+c.list.height<=c.disconnect.y-8,'network list overlaps disconnect')
 f.advance(1100);c.pair.onclick(nil,c.pair);assert(c.code:getInternalText()~='' and c.status.captionText~='','pairing code/status missing')
 local request=PC.Connections.request;PC.Connections.request=function(_,_,_,_,reply) reply({status='unavailable'}) end
 f.advance(5100);host:prerender();assert(#c.list.items==0,'failed refresh retained stale online status')
 PC.Connections.request=request
 host:close()
end
getTextManager,getPlayerScreenWidth,getPlayerScreenHeight=measure,width,height;getGameTime=time
print('PASS OFFLINE Network Setup/status UI: explicit app launch, online/offline rows, copyable address, repeated refresh, immediate pairing toggle, hidden-control focus and four-font bounds')
