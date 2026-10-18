local PC=require 'B47ANCEDPCFramework/API';local f=PC_FIXTURE;local N=PC.Notifications
assert(PC.supports('notifications') and PC.getAPIInfo().notificationVersion==1)
local allowed=true
PC.registerApp({id='fixture.notifications',titleKey='UI_Test_Notifications',canUse=function() return allowed end,create=function(ctx) return ctx.window() end})
local host=assert(PC.open(0,f.computer,'fixture.notifications'));host:openProgram()
local callback=0;local row={id='stock',title='Low stock',message='Nails: 2 / 20',severity='warning',onOpen=function() callback=callback+1 end}
assert(N.post(host,row) and #N.list(host)==1)
assert(N.post(host,row) and #N.list(host)==1,'upsert duplicated a notification')
local copy=N.list(host);copy[1].message='forged';assert(N.list(host)[1].message==row.message)
host:prerender();local d=host.desktopHost;local box=d.notificationPanel
assert(box:isVisible() and d.noticeButton.enable)
local untilAt=d.noticeToastUntil;f.advance(10);row.message='Nails: 1 / 20';row.silent=true;assert(N.post(host,row) and d.noticeToastUntil==untilAt,'silent update restarted the toast')
assert(not N.post(host,{id='bad',title='bad',message='bad',severity='invalid'}))
for n=1,15 do assert(N.post(host,{id='n'..n,title='Notice',message='Bounded notice'})) end
assert(not N.post(host,{id='overflow',title='Notice',message='Bounded notice'}),'unbounded notice queue')
assert(N.dismiss(host,'stock') and #N.list(host)==15)
allowed=false;host:prerender();assert(not PC.ComputerUI.isLive(host) and next(d.notices)==nil,'privacy loss retained notification payloads')
d:close();allowed=true
local measure,width,height=getTextManager,getPlayerScreenWidth,getPlayerScreenHeight
getPlayerScreenWidth=function() return 3840 end;getPlayerScreenHeight=function() return 2160 end
for _,font in ipairs({14,24,32,42}) do
 getTextManager=function() return {getFontHeight=function() return font end,MeasureStringX=function(_,_,s) return #s*font/2 end} end
 host=assert(PC.open(0,f.computer,'fixture.notifications'));host:openProgram();assert(N.post(host,row))
 host:setWidth(host.minimumWidth);host:setHeight(host.minimumHeight);host:prerender();d=host.desktopHost;box=d.notificationPanel
 assert(box.x>=0 and box.y>=0 and box.x+box.width<=d.geometry.width and box.y+box.height<=d.geometry.desktopHeight,'notification escaped CRT')
 for _,s in ipairs(d.order) do if s.task:isVisible() then assert(s.task.x+s.task.width<=d.noticeButton.x,'notice tray overlaps task buttons') end end
 host:close();assert(not N.post(host,row) and #N.list(host)==0,'closed host accepted notification')
end
getTextManager,getPlayerScreenWidth,getPlayerScreenHeight=measure,width,height
print('PASS OFFLINE notification API: upsert/defensive copies, silent update, bounded queue, invalid input, permission/close cleanup and four-font CRT/taskbar bounds')
