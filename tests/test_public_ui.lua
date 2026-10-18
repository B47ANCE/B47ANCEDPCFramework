-- Public consumer boundary, using only the independent native-shaped host double.
local PC=require 'B47ANCEDPCFramework/API';local UI=PC.UI;local A=PC.Assets
local computer=PC_FIXTURE.computer;local actor=PC_FIXTURE.actor;local C=PC.ComputerUI
assert(UI==require('B47ANCEDPCFramework/UI') and A==require('B47ANCEDPCFramework/Assets'))
local info=PC.getAPIInfo();assert(info.applicationVersion==1 and info.uiVersion==1 and info.assetsVersion==1)
info.features['installed-apps']=false;assert(PC.supports('installed-apps') and not PC.supports('missing'))
local palette=A.palette();palette.grey.r=0;assert(A.color('grey').r>.7)
local metrics=UI.metrics();metrics.button=0;assert(UI.metrics().button>0)
A.registerIcon('sdk.example',function(rect) rect(2,2,36,36,'blue');rect(8,8,24,24,'light') end)
assert(A.hasIcon('sdk.example') and not pcall(A.registerIcon,'computer',function() end))
local draws={};local canvas={drawRect=function(_,x,y,w,h,a,r,g,b)
 assert(x==x and y==y and w>0 and h>0 and a==1 and r>=0 and r<=1);draws[#draws+1]={x=x,y=y,w=w,h=h}
end}
for _,id in ipairs(A.icons()) do
 for _,size in ipairs({20,40,80}) do
  draws={};A.drawIcon(canvas,id,10,20,size);assert(#draws>0)
  for _,d in ipairs(draws) do assert(d.x>=10 and d.y>=20 and d.x+d.w<=10+size and d.y+d.h<=20+size) end
 end
end
assert(not pcall(A.drawIcon,canvas,'unknown',0,0,40));assert(not pcall(A.drawIcon,canvas,'computer',0,0,0))
A.registerIcon('sdk.invalid',function(rect) rect(39,0,2,2,'blue') end)
assert(not pcall(A.drawIcon,canvas,'sdk.invalid',0,0,40),'custom icon drew outside its bounds')
local opens,closed,resizes,received=0,0,0,0;local last;local enabled=true;local allowed=true
PC.registerApp({id='sdk.consumer',titleKey='UI_Test_Title',icon='document',
 enabled=function() return enabled end,canUse=function() return allowed end,
 create=function(ctx)
  opens=opens+1;last=ctx
  local panel=ctx.window({onResize=function(view,w,h) resizes=resizes+1;assert(w>0 and h>0) end})
  panel.label=UI.label(panel,{textKey='UI_Test_Label',width=200})
  panel.entry=UI.textEntry(panel,{value='fixture',x=12,y=30,width=200})
  assert(panel.entry:getInternalText()=='fixture' and panel.entry.glyphColor.r<.1,'native entry glyph color not set')
  panel.combo=UI.combo(panel,{options={{textKey='UI_Test_Choice',value=7}},onChange=function(value) assert(value==7) end})
  panel.combo.onChange(nil,panel.combo)
  panel.list=UI.list(panel,{rowHeight=30});panel.list:addItem('test',1);assert(panel.list:doDrawItem(0,panel.list.items[1])==30)
  panel.action=UI.button(panel,{textKey='UI_Test_Action',onClick=function() received=received+1 end})
  panel.icon=UI.iconButton(panel,{icon='document',textKey='UI_Test_Icon',width=100,height=80});panel.icon:render()
  local defaultIcon=UI.iconButton(panel,{icon='folder'});assert(defaultIcon:getHeight()>=UI.metrics().font+64)
  UI.place(panel.action,12,70,220,28);assert(panel.action.x==12 and panel.action:getWidth()==220)
  panel.label:setVisible(false);UI.focus(panel,{{panel.label},{panel.entry,panel.combo},{panel.action}})
  assert(#panel.joypadButtonsY==2 and panel.joypadButtonsY[1][1]==panel.entry)
  panel.combo.disabled=true;UI.focus(panel,{{panel.entry,panel.combo}});assert(#panel.joypadButtonsY[1]==1);panel.combo.disabled=false
  last.reply=ctx.guard(function() received=received+1 end);last.reply();assert(ctx.isActive(),'synchronous response dropped')
  return panel
 end,onClose=function(ctx) assert(not ctx.isActive());closed=closed+1 end})
assert(not pcall(PC.registerApp,{id='invalid',titleKey='Title',icon='missing',create=function() end}))
local host=assert(PC.open(0,computer,'sdk.consumer'));assert(opens==0 and not host.content,'installed app auto-launched')
assert(host.writerIcon:isVisible() and not host.driveIcon:isVisible(),'installed app inherited irrelevant drive controls')
host.writerIcon.onclick();assert(opens==1 and host.content and host.content.b47PCSDKWindow)
local window=host.content;host:prerender();local first=resizes
host:setWidth(1050);host:prerender();assert(resizes>first)
local count=received;host:desktop();host.apps.ledger.task.onclick();assert(host.content==window and last.isActive(),'minimize invalidated app')
window:onKeyRelease(Keyboard.KEY_ESCAPE);assert(closed==1 and not host.content);last.reply();assert(received==count,'closed window accepted stale reply')
host:openProgram();assert(opens==2);local stale=last.reply
allowed=false;stale();assert(received==count+1,'permission-denied reply ran')
host:prerender();assert(not C.active[0] and closed==2 and host.removed)
allowed=true
host=assert(PC.open(0,computer,'sdk.consumer'));host:openProgram();local before=received
PC_FIXTURE.home.power=false;last.reply();assert(received==before,'unpowered response ran');host:prerender();PC_FIXTURE.home.power=true
assert(not C.active[0] and closed==3)
enabled=false;assert(not PC.open(0,computer,'sdk.consumer'));enabled=true
host=assert(PC.open(0,computer,'sdk.consumer'));host:openProgram();local observed=received
local specific=getSpecificPlayer;getSpecificPlayer=function() return {} end
last.reply();assert(received==observed,'replaced actor accepted a stale callback');host:prerender()
getSpecificPlayer=specific;assert(not C.active[0] and closed==4)
PC.registerApp({id='sdk.failure',titleKey='UI_Test_Fail',create=function(ctx) ctx.window();error('fixture create failure') end})
host=assert(PC.open(0,computer,'sdk.failure'));assert(not pcall(host.openProgram,host) and not host.content,'failed builder leaked a panel');host:close()
PC.registerApp({id='sdk.cleanup',titleKey='UI_Test_Cleanup',create=function(ctx) return ctx.window() end,onClose=function() error('fixture cleanup failure') end})
host=assert(PC.open(0,computer,'sdk.cleanup'));host:openProgram();assert(not pcall(host.close,host))
assert(host.removed and not C.active[0] and not host.content,'callback error left desktop orphaned')
assert(B47ANCEDQuartermaster==nil and B47ANCEDUI==nil,'SDK introduced a reverse dependency')
print('PASS OFFLINE public SDK consumer: palette/metric isolation, all scalable icons, native controls, explicit app launch, focus/resize, lifecycle guards, permission/power loss, builder/cleanup errors and legacy API preserved')
