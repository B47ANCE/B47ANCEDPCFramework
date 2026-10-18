-- Real shared desktop/session implementation; native-shaped disposable UI only.
local PC=require 'B47ANCEDPCFramework/API';local C=PC.ComputerUI;local f=PC_FIXTURE
assert(PC.supports('unified-desktop') and PC.supports('retained-app-windows') and PC.supports('crt-frame'))
local builds,closes,updates={a=0,b=0},{a=0,b=0},{a=0,b=0};local contexts={};local allow=true
for _,id in ipairs({'a','b'}) do
 local key=id
 PC.registerApp({id='unified.'..key,titleKey='UI_Test_'..key,canUse=function() return key~='a' or allow end,
  create=function(ctx)
   builds[key]=builds[key]+1;contexts[key]=ctx
   local w=ctx.window({onUpdate=function() updates[key]=updates[key]+1 end});w.value=0
   w.reply=ctx.guard(function() w.value=w.value+1 end);return w
  end,onClose=function() closes[key]=closes[key]+1 end})
end
local desktop=assert(PC.open(0,f.computer));local d=C.desktops[0];local root=d.root
assert(desktop.application=='desktop' and builds.a==0 and builds.b==0)
local function entry(id,kind)
 for _,item in ipairs(d.entries) do if item.id==id and item.kind==(kind or 'app') then return item end end
end
assert(entry('unified.a') and entry('unified.b') and #d.icons==#d.menuButtons,'desktop/Start catalogs differ')
d:launch(entry('unified.a'));local a=C.active[0];local wa=a.content
wa.reply();assert(builds.a==1 and wa.value==1)
d:launch(entry('unified.b'));local b=C.active[0];local wb=b.content
assert(b~=a and b.root==root and a.root==root and a.content==wa,'switch replaced the desktop or old app')
wa.reply();assert(wa.value==2 and contexts.a.isActive(),'background app callback lost its own live window')
root:prerender();assert(updates.a>0 and updates.b>0,'retained apps stopped local updates')
d:launch(entry('unified.a'));assert(C.active[0]==a and a.content==wa and builds.a==1,'relaunch duplicated/reset the app')
a:desktop();assert(a.content==wa and a.minimized and C.active[0]==d.home)
a.task.onclick(nil,a.task);assert(C.active[0]==a and not a.minimized and a.content==wa)
local oldReply=wa.reply;a:closeApp();oldReply();assert(closes.a==1 and wa.value==2 and b.content==wb,'close invalidated the wrong session')
d:launch(entry('unified.a'));assert(builds.a==2);local wa2=a.content
allow=false;wa2.reply();assert(wa2.value==0);root:prerender()
assert(not C.isLive(a) and C.isLive(b) and b.content==wb and closes.a==2,'one privacy loss logged off other apps')
assert(not entry('unified.a'),'unavailable app remained in the catalog');allow=true;f.advance(2100);root:prerender();assert(entry('unified.a'))
-- The browser and late replies belong to their app, not the foreground app.
local replies={};local closeDrives={}
for _,id in ipairs({'drive-a','drive-b'}) do
 local key=id
 PC.registerApplication('unified.'..key,function() return {file='TEST.EXE',canRun=function() return true end,
  drive=function(command,args,reply) replies[key..':'..command]=reply end,close=function() closeDrives[key]=(closeDrives[key] or 0)+1 end}
 end,key)
end
local da=PC.open(0,f.computer,'unified.drive-a');da:openDrive()
local db=PC.open(0,f.computer,'unified.drive-b');db:openDrive()
replies['drive-a:list']({status='ok',choices={{id=101,name='A',fullType='A.Media',token='offer-a'}}})
replies['drive-b:list']({status='ok',mounted={id=202,name='B',fullType='B.Media',drive='binding-b'}})
da.content:prerender();assert(db.mounted:getID()==202 and not da.mounted and C.active[0]==db,'drive reply crossed sessions')
local browser=da.content;browser.insert.onclick(nil,browser.insert)
local focusNative=setJoypadFocus;local focusMoves=0;setJoypadFocus=function() focusMoves=focusMoves+1 end
local replacement=da:view('replacement');assert(C.active[0]==db and focusMoves==0,'background window replacement stole focus');setJoypadFocus=focusNative
replies['drive-a:mount']({status='ok',mounted={id=101,name='A',fullType='A.Media',drive='binding-a'}})
assert(da.content==replacement and not da.mounted,'late mount replaced another window')
assert(browser.providers and #browser.providers.options>=2,'multiple CD providers cannot be selected')
-- Paging keeps every app accessible on desktop and Start, including large fonts.
for n=1,30 do PC.registerApplication('unified.extra.'..n,function() return {hasDrive=false} end,'Example '..n) end
d:refreshCatalog()
local fontManager=getTextManager
for _,font in ipairs({14,24,32,42}) do
 getTextManager=function() return {getFontHeight=function() return font end,MeasureStringX=function(_,_,text) return #text*font/2 end} end
 root:setWidth(math.max(1000,font*30));root:setHeight(math.max(850,font*30));root:prerender()
 local found={}
 for page=1,d.pages do
  d.page=page;d:layout()
  for i,icon in ipairs(d.icons) do
   assert(icon:isVisible()==d.menuButtons[i]:isVisible(),'Start/desktop pages disagree')
   if icon:isVisible() then
    found[icon.entry.key]=true
    assert(icon.x>=0 and icon.y>=0 and icon.x+icon.width<=d.surface.width and icon.y+icon.height<=d.surface.height,'icon outside CRT')
    local button=d.menuButtons[i];assert(button.y+button.height<=d.menu.height,'menu entry outside Start menu')
   end
  end
 end
 for _,item in ipairs(d.entries) do assert(found[item.key],'paging lost '..item.key) end
 assert(d.geometry.y+d.geometry.height<root:getHeight() and d.off.y+d.off.height<=root:getHeight(),'CRT chrome outside root')
end
getTextManager=fontManager
-- Root power/access loss invalidates all retained sessions and all callbacks.
local stale=wb.reply;f.home.power=false;root:prerender();f.home.power=true;stale()
assert(not C.desktops[0] and not C.active[0] and not C.isLive(b) and closes.b==1 and wb.value==0)
assert(closeDrives['drive-a']==1 and closeDrives['drive-b']==1,'per-app teardown did not run exactly once')
d:launch({id='unified.b',kind='app'});assert(not C.desktops[0],'stale launcher revived a closed desktop')
-- Another app's cleanup failure cannot orphan the native root or healthy apps.
local healthy=PC.open(0,f.computer,'unified.b');healthy:openProgram()
local broken=PC.open(0,f.computer,'sdk.cleanup');broken:openProgram()
assert(not pcall(broken.close,broken));assert(not C.desktops[0] and healthy.closed and closes.b==2,'cleanup error skipped other retained apps')
local old=PC.open(0,f.computer,'unified.b');old:openProgram();local oldContext=contexts.b
local specific=getSpecificPlayer;local replacement=setmetatable({},{__index=f.actor})
getSpecificPlayer=function() return replacement end
local renewed=PC.open(0,f.computer)
assert(renewed and renewed.root~=old.root and old.closed and not oldContext.isActive(),'actor replacement reused another actor\'s desktop')
renewed:close();getSpecificPlayer=specific
PC.registerApp({id='desktop',titleKey='UI_Test_DesktopID',create=function(ctx) return ctx.window() end})
local named=PC.open(0,f.computer,'desktop');named:openProgram();local home=PC.open(0,f.computer)
assert(named~=home and C.isLive(named) and named.content,'public app ID collided with the private home session')
local other=getCell():getGridSquare(1,0,0):getObjects():get(0)
local switched=PC.open(0,other);assert(switched and switched.root~=home.root and named.closed,'switching PCs reused the old device context');switched:close()
print('PASS OFFLINE unified CRT desktop: shared app/Start catalog, retained app/task state, explicit launch, isolated media/late replies, app-only privacy teardown, all-font pagination/focus bounds and global power cleanup')
